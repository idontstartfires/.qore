
hl.bind("SUPER + SHIFT + end", hl.dsp.exec_cmd("uwsm stop"))

hl.bind("SUPER + SHIFT + Q", hl.dsp.window.close())
--hl.bind("SUPER + SHIFT + Q", hl.dsp.window.kill())

hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode="maximized" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode="fullscreen" }))
hl.bind("SUPER + Y", hl.dsp.window.float())

hl.bind("SUPER + H", hl.dsp.focus({ direction="left" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction="down" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction="up" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction="right" }))

hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction="left" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction="down" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction="up" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction="right" }))

hl.bind("SUPER + CTRL + H", hl.dsp.window.resize({ x=0.5, y=0 }))
hl.bind("SUPER + CTRL + J", hl.dsp.window.resize({ x=0.5, y=0 }))
hl.bind("SUPER + CTRL + K", hl.dsp.window.resize({ x=0.5, y=0 }))
hl.bind("SUPER + CTRL + L", hl.dsp.window.resize({ x=5, y=0 }))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("SUPER + return", hl.dsp.exec_cmd('$TERM_PROGRAM'))
hl.bind("SUPER + slash", hl.dsp.exec_cmd('$TERM_PROGRAM -e $FILE_MANAGER'))

hl.bind("SUPER + minus", hl.dsp.exec_cmd('$TERM_PROGRAM -e $AUDIO_CONTROL'))
hl.bind("SUPER + equal", hl.dsp.exec_cmd('$TERM_PROGRAM -e $PROCESS_CONTROL'))

hl.bind("SUPER + space", hl.dsp.exec_cmd('$LAUNCHER -show run'))

hl.bind("SUPER + backspace", hl.dsp.exec_cmd('$BROWSER'))

hl.bind("SUPER + o", hl.dsp.exec_cmd('xdg-open "obsidian://open?vault=$(ls $HOME/.vaults | wofi --dmenu)"'))

hl.bind("SUPER + left", hl.dsp.exec_cmd('pactl set-sink-volume @DEFAULT_SINK@ -2%'))
hl.bind("SUPER + right", hl.dsp.exec_cmd('pactl set-sink-volume @DEFAULT_SINK@ +2%'))

hl.bind("SUPER + B", hl.dsp.submap("blue"))
hl.define_submap("blue", "reset", function()
    hl.bind("C", hl.dsp.exec_cmd('blue connect $(blue devices | wofi --dmenu | cut -d " " -f 1) && notify-send "$(blue name) 󰂱"'))
    hl.bind("R", hl.dsp.exec_cmd('blue reconnect $(blue devices | wofi --dmenu | cut -d " " -f 1)'))
    hl.bind("D", hl.dsp.exec_cmd('notify-send "󰂲" && blue disconnect'))
    hl.bind("B", hl.dsp.exec_cmd('notify-send "$(blue name): $(blue battery)%󰥉"'))
end)

hl.bind("SUPER + tab", hl.dsp.submap("project"))
hl.define_submap("project", "reset", function()
    hl.bind("tab", hl.dsp.exec_cmd('$TERM_PROGRAM -e project -A ide'))
    hl.bind("e", hl.dsp.exec_cmd('$TERM_PROGRAM -e project -E'))
    hl.bind("escape", hl.dsp.exec_cmd('project -Sm $LAUNCHER'))
    hl.bind("slash", hl.dsp.exec_cmd('$TERM_PROGRAM -e project -A nav'))
    hl.bind("return", hl.dsp.exec_cmd('cd $(project -A root) && $TERM_PROGRAM'))
end)


hl.bind("SUPER + Z", hl.dsp.dpms())
