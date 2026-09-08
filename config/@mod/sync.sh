# Helpers for per-package @sync scripts.
#
# A config package is a directory under config/ whose contents mirror its deploy
# target one-to-one. Files at the package root apply to every machine; a
# `@<hostname>` directory overlays that machine alone, and wins. Entries named
# `@*` are infrastructure and are never deployed.
#
# Source this from a package's @sync script, then call qore_link or qore_install.

qore_pkg_dir=$(cd "$(dirname "$0")" && pwd)
qore_machine=$(cat /etc/hostname 2>/dev/null || uname -n)
qore_machine=${qore_machine%%.*}

qore_assume_yes=0
for _arg in "$@"; do
    case "$_arg" in
        -y|--yes) qore_assume_yes=1 ;;
    esac
done

_qore_tab=$(printf '\t')

# Emit "<source path><TAB><path relative to the layer root>" for one layer.
_qore_emit_layer() {
    _root=$1
    if [ "$_root" = "$qore_pkg_dir" ]; then
        # shared layer: package root, skipping infrastructure entries
        for _e in "$_root"/* "$_root"/.[!.]*; do
            [ -e "$_e" ] || continue
            case "${_e##*/}" in @*) continue ;; esac
            find "$_e" -type f 2>/dev/null
        done
    else
        find "$_root" -type f 2>/dev/null
    fi | while read -r _f; do
        printf "%s%s%s\n" "$_f" "$_qore_tab" "${_f#"$_root"/}"
    done
}

# Every file this package deploys: shared layer first, machine layer last.
qore_sources() {
    _qore_emit_layer "$qore_pkg_dir"
    [ -d "$qore_pkg_dir/@$qore_machine" ] && _qore_emit_layer "$qore_pkg_dir/@$qore_machine"
    return 0
}

# Symlink every layer into <target> with stow: shared layer first, then the
# machine layer, which overrides it.
qore_link() {
    _target=$1
    mkdir -p "$_target"

    # Shared layer: the package itself, skipping @sync and @<hostname>.
    stow -R --no-folding --override='.*' --ignore='^@.*' \
        -d "$(dirname "$qore_pkg_dir")" -t "$_target" "$(basename "$qore_pkg_dir")"

    # Machine layer, if this host has one.
    if [ -d "$qore_pkg_dir/@$qore_machine" ]; then
        stow -R --no-folding --override='.*' \
            -d "$qore_pkg_dir" -t "$_target" "@$qore_machine"
    fi
    return 0
}

_qore_as_root() {
    if [ "$(id -u)" = 0 ]; then
        "$@"
    elif command -v doas >/dev/null 2>&1; then
        doas "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "@sync: need doas or sudo to write outside \$HOME" >&2
        return 1
    fi
}

# Copy every layer file into <target> as root:root, after showing a diff.
# Copied rather than linked: doas rejects a config a non-root user can write,
# and some of these are read before /home is mounted.
qore_install() {
    _target=$1
    _pending=""

    while IFS="$_qore_tab" read -r _src _rel; do
        _dst="$_target/$_rel"
        [ -e "$_dst" ] && cmp -s "$_src" "$_dst" && continue
        _pending="$_pending $_src:$_dst"
        echo "--- $_dst"
        if [ -e "$_dst" ]; then
            diff -u "$_dst" "$_src" || true
        else
            echo "(new file)"
        fi
    done <<EOF
$(qore_sources)
EOF

    [ -n "$_pending" ] || return 0

    if [ "$qore_assume_yes" != 1 ]; then
        [ -t 0 ] || { echo "@sync: changes pending, re-run with --yes to write them"; return 0; }
        printf 'Write these to %s? [y/N] ' "$_target"
        read -r _reply
        case "$_reply" in [Yy]*) ;; *) echo "skipped."; return 0 ;; esac
    fi

    for _pair in $_pending; do
        _qore_as_root install -D -o root -g root -m 644 "${_pair%%:*}" "${_pair#*:}"
        echo "wrote ${_pair#*:}"
    done
}
