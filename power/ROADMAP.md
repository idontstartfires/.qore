# `watt` — power-accounting system for q's fleet · ROADMAP

> **Status:** Planning (v2), no code written yet. This file is the handoff for the implementing
> session. Read top to bottom before writing code.
>
> **Origin:** Idea from `q` — started as a per-program power monitor for one desktop, expanded
> into a fleet-wide power-accounting system: scan each host's hardware, monitor what's
> measurable, attribute draw to programs *and* to real-world "systems" (computer + monitors, a
> mini-PC + TV, an AC unit), and account cost against whole-apartment grid usage. Planned/expanded
> 2026-06-13.

---

## 1. Vision

Account for electrical power and cost across everything q owns, at three levels:

1. **Programs** — on a computer, attribute its draw to programs ("cheap terminal coding" vs.
   "Neovim IDE with LSPs" vs. "modded Minecraft", expected to dominate via GPU). Track *expensive*
   processes (over a threshold) **and** specifically *enumerated* ones (Neovim — cheap but
   interesting). **Never one row per PID.**
2. **Systems** — a host is a *subsystem*, not the whole picture. The **Eagle system** = the box +
   its 3 monitors. **Parotia** = mini-PC + its TV. An **AC unit** is a system with no computer at
   all. Smart plugs meter the non-computer parts.
3. **Locations** — an apartment has a **grid total** (kWh + cost, manually uploaded) so we can see
   **AC vs. Eagle vs. the unmonitored remainder** (`grid − Σ monitored`). Blackbird (laptop) is
   **location-less / transient** but still tracked standalone.

Off-the-shelf tools (`scaphandre`, `powertop`, `nvtop`, TSDB stacks) don't do this combination of
heterogeneous hardware + per-program attribution + real-world system/location accounting + cost.
So we build, designed for a **fleet** from the start.

---

## 2. Decisions locked in (do not re-litigate)

| Decision | Choice | Notes |
|---|---|---|
| Scope | **Fleet-wide, hardware-agnostic** | Scan hardware → capability manifest → built-in source plugins read whatever's present. NOT hardcoded to Eagle. |
| Build vs. buy | **Build in `.qore`**, Rust, binary **`watt`**, crate in top-level `power/` | Symlink built binary into `local/bin/watt`. |
| Architecture | **Central from the start** | Collector/server holds the store; per-host agents push readings to it. Runnable single-host over localhost first (collector on Eagle), grows to remote hosts + a Pi. |
| Transient hosts | **Durable local spool + replay** | Agent buffers readings locally when the collector is unreachable (Blackbird off-LAN), flushes on reconnect. Not a permanent per-host analytical DB. |
| Storage | **SQLite (system of record) + DuckDB (analytics), both now** | SQLite ingests the constant small writes; DuckDB attaches/reads it for columnar rollups & the TUI's heavy group-bys. No TSDB server. |
| Config format | **TOML for machine-generated capability manifests; YAML for hand-authored topology** | Manifests are emitted by `watt scan`; topology (systems/locations) is hand-written where nesting reads nicer. Classifier rules: TOML. |
| Process selection | **threshold ∪ watchlist**, rest → `"other"` | `track_threshold_w` auto-includes expensive procs; `watch=[...]` always includes named ones; everything else collapses into one `other` bucket. |
| Smart plugs / grid | **Optional, addable later** | Plugs (Tasmota/Shelly/Kasa, HTTP) bought in weeks-maybe. Grid total is a manual/CSV import — National Grid smart meter assumed to have **no public API** (supplier-locked). |
| Whole-system accuracy | **On-board estimate, plug-ready** | Desktops: CPU(RAPL)+GPU+`baseline_w`. Laptops: true via battery discharge. Plugs override with metered truth when present. |

---

## 3. The fleet (hosts inventory)

`watt scan` fills in the unknowns per host; this is the starting picture.

| Host | Role | Power-relevant hardware | What it contributes | Location |
|---|---|---|---|---|
| **eagle** | Home workstation | 5800X + RTX 3070, desktop/AC. RAPL(root)+NVML. **Probed — see §6.** | CPU+GPU+baseline estimate; per-program attribution. Worst-case accuracy (estimate). | Apartment |
| **rosy-finch** | Work workstation | Unknown — **needs `watt scan`** | TBD by scan (likely RAPL ± GPU) | Workplace (separate location; maybe no grid import) |
| **blackbird** | Laptop | **Battery-powered** | **Whole-system via battery discharge — most accurate host, no baseline guessing.** Transient. | None (transient) |
| **parotia** *(rename TBD)* | Mini-PC at the TV, entertainment | Decade-old; may have old/no RAPL. **Needs Wayland + `.qore` conversion, or replacement.** | Possibly **smart-plug-only** host (plug meters PC+TV) | Apartment (entertainment) |
| **pi / server** *(maybe)* | Always-on service host | Tiny draw; likely no RAPL | Runs the **collector** + **smart-plug pollers** (the always-on thing that polls plugs & ingests). | Apartment |
| *(AC unit)* | Appliance, **no computer** | Smart plug only | Pure smart-plug device under its own system | Apartment |

Irony to remember: **the laptop is the most accurate host** (battery = true whole-system draw),
while the powerful desktop is the least (estimate + baseline). Don't treat Eagle as the template.

---

## 4. Architecture

### 4.1 Components (one `watt` binary, subcommands)
- `watt scan` — probe the local host, emit/update its **capability manifest** TOML
  (`config/watt/hosts/<host>.toml`). Hand-editable after.
- `watt sample` — single sampling pass to stdout (manual testing).
- `watt sample --daemon` — **agent**: loop at `interval_s`, read enabled sources, select processes,
  push readings to the collector; spool locally + replay if the collector is down.
- `watt serve` — **collector**: HTTP ingest API → central SQLite; loads topology; runs smart-plug
  pollers; serves aggregated queries. Runs on the always-on host (Eagle now, Pi later); single-host
  setups run it on localhost.
- `watt cost [--since 24h] [--system ...|--location ...]` — non-TUI energy/cost summary (DuckDB).
- `watt tui` — dashboard: live + history graphs + per-program + per-system + per-location + cost.

### 4.2 Capability detection & source plugins
A `Source` trait; built-in implementations each answer *"am I available on this host, and what do I
measure?"*. `watt scan` runs detection and records enabled sources + params into the host manifest.

| Plugin | Mechanism | Measures | Privilege |
|---|---|---|---|
| `rapl` | `/sys/class/powercap/intel-rapl:*/energy_uj` (+`max_energy_range_uj` wraparound) | CPU package energy → watts | **root** (Eagle confirms root-only) |
| `nvml` | `nvml-wrapper` → `power_usage()`; fallback `nvidia-smi` | NVIDIA GPU watts (+per-proc util) | user |
| `amdgpu` | `/sys/class/drm/card*/device/hwmon/hwmon*/power1_average` | AMD GPU watts | user |
| `battery` | `power_supply/*/power_now` (or `current_now`×`voltage_now`) | **whole-system** discharge watts | user |
| `hwmon` | generic hwmon `powerN_*` rails | misc rails where present | user |
| `smartplug` | HTTP poll (Tasmota/Shelly/Kasa) | external device/system watts | network |

Graceful degradation: no RAPL → skip CPU; no NVIDIA → skip GPU; battery present → prefer it as the
whole-system truth.

### 4.3 Process selection (never all PIDs)
Per sample: read `/proc/[pid]/stat` utime+stime deltas (ticks; `_SC_CLK_TCK`). Compute each pid's
share of CPU watts, GPU watts via NVML per-proc util share. Then **select**:
- include any process whose attributed watts ≥ `track_threshold_w`;
- include any process matching the `watch` list (by `comm`/`cmdline`) regardless of cost;
- a **classifier** maps matches → friendly labels (`java`+minecraft → `Minecraft`; `nvim`+LSPs →
  `Neovim IDE`);
- **everything else is summed into a single `"other"` label.** The DB stores per-label rows only.

### 4.4 Topology model (device → system → location)
Hand-authored YAML, loaded by the collector. Stable string IDs.
- **device** — one power source: a *computer* (powered by its host's plugins) or a *plug device*
  (monitor, AC, the Parotia bundle) powered by a `smartplug` source.
- **system** — named group of devices (*Eagle system* = `eagle` computer + `eagle-monitors` plug;
  *Parotia* = mini-PC + TV plug; *AC* = single plug device).
- **location** — apartment; optional `grid_import` (manual kWh+cost). `unmonitored = grid − Σ
  monitored devices`. Blackbird belongs to **no** location.

### 4.5 Storage
**SQLite = system of record** (durable ingest of many small writes from all hosts). **DuckDB =
analytics** (attaches the SQLite file via its `sqlite` extension, or maintains downsampled rollup
tables, for fast window group-bys / the TUI / `watt cost`). **Per-host agents keep only a small
durable spool** (e.g. a local SQLite/WAL or append file) for offline buffering — not a full DB.

Central DB lives on the collector host (XDG data dir, or `/var/lib/watt/` if collector runs as
root). **All timestamps UTC epoch.** Topology/config live in the repo, **not** the DB.

```sql
-- SQLite (collector). Append-only ingest; one row per (ts, entity).
CREATE TABLE IF NOT EXISTS device_reading (    -- whole-device power
  ts        INTEGER NOT NULL,      -- UTC epoch seconds
  device_id TEXT    NOT NULL,      -- stable id from topology YAML
  watts     REAL    NOT NULL,
  source    TEXT    NOT NULL,      -- 'rapl+nvml+baseline' | 'battery' | 'smartplug'
  PRIMARY KEY (ts, device_id)
);
CREATE TABLE IF NOT EXISTS component_reading (  -- breakdown for computer hosts
  ts        INTEGER NOT NULL,
  host      TEXT    NOT NULL,
  component TEXT    NOT NULL,      -- 'cpu' | 'gpu' | 'baseline'
  watts     REAL    NOT NULL,
  PRIMARY KEY (ts, host, component)
);
CREATE TABLE IF NOT EXISTS proc_reading (       -- per-program attribution (selected labels only)
  ts    INTEGER NOT NULL,
  host  TEXT    NOT NULL,
  label TEXT    NOT NULL,          -- 'Minecraft' | 'Neovim IDE' | 'other' | comm
  cpu_w REAL    NOT NULL,
  gpu_w REAL    NOT NULL,
  PRIMARY KEY (ts, host, label)
);
CREATE TABLE IF NOT EXISTS grid_import (         -- manual apartment uploads
  location     TEXT NOT NULL,
  period_start INTEGER NOT NULL,
  period_end   INTEGER NOT NULL,
  kwh          REAL NOT NULL,
  cost         REAL NOT NULL,
  currency     TEXT NOT NULL,
  PRIMARY KEY (location, period_start)
);
CREATE INDEX IF NOT EXISTS idx_dev_ts  ON device_reading(device_id, ts);
CREATE INDEX IF NOT EXISTS idx_proc_ts ON proc_reading(host, label, ts);
```
- Energy: `kWh = Σ(watts × interval_s) / 3.6e6`. Cost: `kWh × kwh_cost`.
- DuckDB analytics, e.g.: `INSTALL sqlite; LOAD sqlite; ATTACH 'watt.db' AS src (TYPE sqlite);`
  then group-by over windows; optionally materialize 1-min / 1-hour rollups into a native DuckDB
  file for long history.
- Volume is tiny (one reading per ~10s per device) — SQLite handles ingest indefinitely; revisit
  retention/rollup only if it ever grows annoying.

### 4.6 Config files (in repo, under `config/watt/`)
- `config/watt/hosts/<host>.toml` — **machine-generated** capability manifest (committed,
  hand-editable): enabled sources + params (RAPL domain paths, NVML index, battery path),
  `interval_s`, `baseline_w`, `track_threshold_w`, `watch`, classifier rules, collector URL.
- `config/watt/topology.yaml` — **hand-authored** devices → systems → locations, grid settings,
  `kwh_cost` + `currency` per location.
- Collector reads topology; agents read their own host manifest. (Repo installs via `stow` into
  `~/.config/watt/`; see §7.)

Sketch — `config/watt/hosts/eagle.toml`:
```toml
interval_s        = 10
collector         = "http://localhost:9469"   # later: pi.lan
baseline_w        = 60.0      # MEASURE with a wall meter; placeholder
track_threshold_w = 2.0       # auto-track procs over this
watch             = ["nvim", "Minecraft"]     # always track, even if cheap

[sources.rapl]   ; domain = "intel-rapl:0"
[sources.nvml]   ; index  = 0

[[classify]]
match = "cmdline"; pattern = "(?i)minecraft|fabric|forge"; label = "Minecraft"
[[classify]]
match = "comm";    pattern = "^nvim$";                     label = "Neovim IDE"
```

Sketch — `config/watt/topology.yaml`:
```yaml
locations:
  apartment:
    currency: "€"          # q @ untill.ag → confirm EUR
    kwh_cost: 0.30         # placeholder — set real rate
    grid_import: manual    # National Grid: no API; CSV/manual entry
    systems:
      eagle:
        devices:
          - { id: eagle,           kind: computer,  host: eagle }
          - { id: eagle-monitors,  kind: plug,      plug: tasmota://… }   # future
      parotia:
        devices:
          - { id: parotia-bundle,  kind: plug,      plug: shelly://… }    # future
      ac:
        devices:
          - { id: ac-unit,         kind: plug,      plug: kasa://… }       # future
# blackbird: location-less, tracked standalone (no entry here)
```

### 4.7 TUI (`ratatui` + `crossterm`)
Live header (per-host CPU/GPU/baseline/total) · braille history chart with window selector
(1h/6h/24h/7d) · per-program breakdown · per-system and per-location rollups with kWh + cost ·
"unmonitored remainder" vs. grid. Keys: `q` quit, `[`/`]` window, `tab` switch view.

### 4.8 Intended crates
`clap`, `rusqlite` (bundled), `duckdb`, `nvml-wrapper`, a small HTTP server+client (`axum`+`reqwest`
or `tiny_http`+`ureq`), `serde` + `toml` + `serde_yaml`, `ratatui`, `crossterm`, `anyhow`, `chrono`,
`regex`, and optionally `procfs`, `directories`.

---

## 5. Build phases (checklist — incremental, central-shaped, single-host first)

- [ ] **P1 — Scaffold.** `cargo init` in `power/` (crate `watt`). `.gitignore` += `/power/target/`.
      `clap` subcommands: `scan`, `sample`, `serve`, `cost`, `tui`. Compiles + `--help`.
- [ ] **P2 — Capability detection.** `Source` trait + `rapl`/`nvml`/`amdgpu`/`battery` detection.
      `watt scan` emits `config/watt/hosts/eagle.toml`.
- [ ] **P3 — Sampling core.** Read enabled sources; `/proc` per-pid CPU deltas; GPU per-proc util;
      process selection (threshold ∪ watchlist ∪ `other`); classifier. `watt sample` prints real
      numbers.
- [ ] **P4 — Collector + store.** `watt serve`: HTTP ingest API → central SQLite (schema §4.5).
      Run on localhost.
- [ ] **P5 — Agent push + spool.** `watt sample --daemon` pushes to collector; durable local spool
      + replay on reconnect. Verify end-to-end on Eagle over localhost.
- [ ] **P6 — Topology + cost.** Load `topology.yaml`; system/location rollups; `grid_import`;
      `watt cost` (+ `--system`/`--location`).
- [ ] **P7 — DuckDB analytics.** Attach SQLite (or rollup tables); back `watt cost`/queries with it.
- [ ] **P8 — TUI.** Live + history + per-program + per-system/location + cost.
- [ ] **P9 — Multi-host + plugs.** Deploy agent to **Blackbird** (battery source, off-LAN spool
      replay) pointing at the collector. `smartplug` poller plugin (Tasmota/Shelly/Kasa) running on
      the collector. Then Rosy-finch / Parotia / Pi as they come online.
- [ ] **P10 — Integrate.** systemd units (§6), permissions (§8), `stow` wiring, `power/README.md`
      (incl. the honest-measurement model from §6), graceful degradation verified per host.

---

## 6. Hardware facts — host `eagle`, probed 2026-06-13

**Eagle is the first target; other hosts get filled in by `watt scan`.**

- **Form factor:** Desktop, **always on AC**. Only `/sys/class/power_supply/` entry is
  `hidpp_battery_3` — a **Logitech wireless peripheral** (`046D`), *not* a system battery ⇒ no
  battery-discharge signal here (unlike Blackbird).
- **CPU:** `AMD Ryzen 7 5800X` (Zen 3), `AuthenticAMD`.
- **GPU:** `NVIDIA GeForce RTX 3070` (GA104), 220 W limit. `nvidia-smi` user-readable; **46.57 W**
  idle during probe.
- **RAPL** (via `powercap`, works on AMD):
  - `/sys/class/powercap/intel-rapl:0/` → `package-0`; `intel-rapl:0:0/` → `core`.
  - `energy_uj` is **root-only** here → agent runs as a root system service on RAPL hosts.
  - `max_energy_range_uj` = **65532610987** → wraparound modulus.
  - `package-0` = CPU package only (cores+uncore), NOT RAM/board/drives/PSU.
- **Tools present:** `cargo`, `rustc`, `go`, `python3`, `uv`, `upower`, `sensors`, `nvidia-smi`.
  **Missing:** `powertop`, `turbostat`, `acpi`, `scaphandre`. `sensors`/k10temp = temps only, no
  power rails.

### Honest measurement model (put in README)
1. **CPU+GPU ≠ whole PC** on desktops. RAPL=package, NVML=GPU; RAM/board/drives/fans/PSU loss
   (~15–25%) uncounted → captured by a fixed `baseline_w` (measure once with a wall meter) or
   replaced by a smart plug. CPU+GPU *is* the part that swings between coding and gaming, so trends
   hold. **Laptops sidestep this** via battery discharge = true whole-system.
2. **Per-process power is always an estimate.** Hardware reports totals; we apportion by CPU-time /
   GPU-util share. Good for *ranking* programs, not billing per app.

### RAPL/NVML/battery specifics
- CPU watts: `((now − prev) mod max_energy_range_uj) / Δt_s / 1e6`; keep prev reading + monotonic ts.
- GPU watts: NVML `power_usage()` (mW); per-proc via `process_utilization_stats()` /
  `running_*_processes`. Consumer NVIDIA gives **no** per-process watts.
- Battery watts (Blackbird): prefer `power_now` (µW); else `current_now`×`voltage_now`. Sign/units
  vary by driver — verify on the host. This is whole-system, user-readable.

---

## 7. Repo integration

- `.qore` is a cross-machine dotfiles repo installed via `stow` (`./sync`): `shell/`→`$HOME`,
  `config/`→`~/.config`, plus per-host overlay `config.$(hostname -s)` (hosts: `blackbird`,
  `eagle`, `rosy-finch`; `parotia` to be added). `config/watt/` stows to `~/.config/watt/`.
- **No build artifacts committed.** Source in `power/`, `power/target/` gitignored, binary built
  with cargo and **symlinked** into `local/bin/` (on PATH). Add `/power/target/` to `.gitignore`.
- Host manifests `config/watt/hosts/<host>.toml` **are** committed (per-host capability + tuning).
  Topology `config/watt/topology.yaml` committed. The DB and local spool are **not** in the repo.

---

## 8. Permissions

- **RAPL hosts (eagle, likely rosy-finch):** agent runs as a **root systemd system service**
  (`energy_uj` root-only). Pushes to collector over HTTP.
- **Battery / GPU:** user-readable — no privilege needed; on a battery-only laptop the agent could
  run as a **user service**.
- **Collector:** runs on the always-on host; DB world/group-readable for the TUI. Ingest API bound
  to localhost (single-host) or LAN (fleet) — add a shared token if exposed beyond localhost.
- Alternative to root for RAPL: udev/`tmpfiles` chmod of `energy_uj` (fragile, driver-reload
  sensitive) — fallback only.

### systemd (drafts)
```ini
# /etc/systemd/system/watt-agent.service   (RAPL host → root)
[Service]
ExecStart=/home/q/.qore/local/bin/watt sample --daemon
Restart=always
RestartSec=5
Nice=10
[Install]
WantedBy=multi-user.target
```
```ini
# /etc/systemd/system/watt-collector.service   (always-on host: eagle now, pi later)
[Service]
ExecStart=/home/q/.qore/local/bin/watt serve
Restart=always
[Install]
WantedBy=multi-user.target
```
Use long-running daemons, not `.timer`s (sub-minute intervals).

---

## 9. Open questions / to confirm with q

1. **`kwh_cost` + currency** per location (likely EUR). Placeholder `0.30 €`.
2. **`baseline_w` for Eagle** — needs a one-time wall-meter idle reading; placeholder `60 W`. Until
   then, absolute cost is ballpark; trends valid. Blackbird needs none (battery).
3. **`track_threshold_w`** starting value — placeholder `2 W`; tune after seeing real data.
4. **Collector home** — Eagle (always-on home box) until a Pi exists? Confirm intent.
5. **Ingest auth** — token/mTLS once the collector is exposed beyond localhost (Blackbird over VPN?
   Rosy-finch on a separate network → separate location, maybe separate collector?).
6. **Parotia** — convert (Wayland + `.qore`) or replace? If smart-plug-only, no agent there.
7. **Smart plug ecosystem** — Tasmota / Shelly / Kasa / Zigbee? Shapes the `smartplug` poller.
8. **Rosy-finch hardware** — run `watt scan` once accessible.

---

## 10. Quick reference (probe commands)
```sh
# RAPL
cat /sys/class/powercap/intel-rapl:0/{name,energy_uj,max_energy_range_uj}   # energy_uj root-only
# GPU
nvidia-smi --query-gpu=name,power.draw,power.limit --format=csv
# Battery (laptops): whole-system draw
cat /sys/class/power_supply/BAT*/power_now   # µW; else current_now × voltage_now
# Per-process CPU: /proc/[pid]/stat fields 14 (utime) + 15 (stime); _SC_CLK_TCK ticks/s
```
