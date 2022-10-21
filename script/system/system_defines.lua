---@meta

---Sets the color for follow-up draw calls
---@param r number
---@param g number
---@param b number
---@param a number
function set_color(r, g, b, a) end

---Default function to draw disks or circles
---@param pos_x number Center X position for drawing
---@param pos_y number Center Y position for drawing
---@param inner number Pixel offset from center to start the drawing from
---@param outer number Pixel offset from center to end the drawing at
---@param slices integer Number of slices for the drawn disk (higher amount = smoother edge)
---@param loops integer
---@param start number Start angle for the drawing
---@param sweep number Disk length in degrees
---@param blend integer
function draw_disk(pos_x, pos_y, inner, outer, slices, loops, start, sweep, blend) end

---Enables keyboard / touch camera movement
function enable_camera_movement() end

---Disables keyboard / touch camera movement
function disable_camera_movement() end

---Enables mouse / touch camera movement
function enable_mouse_camera_movement() end

---Disables mouse / touch camera movement
function disable_mouse_camera_movement() end
