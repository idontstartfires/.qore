local function bind_workspace(index, monitor)
    hl.workspace_rule({ workspace = tostring(index), monitor = monitor })
    hl.bind("SUPER + " .. index, hl.dsp.focus({ workspace = tostring(index) }))
    hl.bind("SUPER + SHIFT + " .. index, hl.dsp.window.move({ workspace = tostring(index), follow=false }))

end

hl.monitor({
    output = "eDP-1",
    mode = "1920x1200@60.0",
    position = "0x0",
})
for i = 1, 6 do
    bind_workspace(i, "eDP-1")
end
