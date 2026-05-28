hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = 0xFFFFFFFF,
            inactive_border = 0x00000000,
        },
        layout = "dwindle"
    },
    cursor = {
        no_hardware_cursors = true
    },
    decoration = {
        rounding = 8,
        blur = {
            enabled = true,
            size = 8,
            ignore_opacity = false
        }
    },
    dwindle = {
        preserve_split = true
    },
    input = {
        kb_layout = "us",
        kb_options = "ctrl:nocaps",
        repeat_delay = 400,
        follow_mouse = 2,
        float_switch_override_focus = 0,
        sensitivity = 0.2
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = false,
        mouse_move_focuses_monitor = false
    }
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})
hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

require("monitors")
require("map")
require("style")
