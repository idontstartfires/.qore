local function bind_workspace(index, monitor)
    hl.workspace_rule({ workspace = tostring(index), monitor = monitor })
    hl.bind("SUPER + " .. index, hl.dsp.focus({ workspace = tostring(index) }))
    hl.bind("SUPER + SHIFT + " .. index, hl.dsp.window.move({ workspace = tostring(index), follow=false }))

end

hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@60.0",
    position = "0x600",
})
for i = 1, 3 do
    bind_workspace(i, "HDMI-A-1")
end

hl.monitor({
    output = "DP-2",
    mode = "2560x1440@60.0",
    position = "1920x240",
})
for i = 4, 6 do
    bind_workspace(i, "DP-2")
end

hl.monitor({
    output = "DP-1",
    mode = "1920x1080@60.0",
    position = "4480x0",
    transform = 1,
})
for i = 7, 9 do
    bind_workspace(i, "DP-1")
end
