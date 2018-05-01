local head = load_texture("../../custom/sir/head.tga")
local rotz = 0
function draw_vp()
    set_viewport(0, 0, 550, 550)
    set_color(0.05,0.05,0.05,1)
    draw_sphere(0, 0, 9.45, 0.35, 0, 0, rotz)
    set_color(1,1,1,1)
    draw_sphere(0, 0, 10, 0.7, 0, 0, rotz, head)
    rotz = rotz + 0.5
end
add_hook("draw_viewport", "blurbg", draw_vp)