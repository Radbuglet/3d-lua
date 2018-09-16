local class = require('class')

local Sector = class{}

function Sector:init(sx, sy, sw, sh, sfloor, sceil)
    self.sx = sx
    self.sy = sy
    self.sw = sw
    self.sh = sh
    self.sfloor = sfloor
    self.sceil = sceil

    self.sfloorcol = { math.random() * 50, math.random() * 50, math.random() * 50 }
    self.sceilcol = { 200, 200, 200 }
    self.walls = {
        A = {
            color = { math.random() * 255, math.random() * 255, math.random() * 255 },
            texture = love.graphics.newImage("test_texture.png"),
            portal = nil
        },
        B = {
            color = { math.random() * 255, math.random() * 255, math.random() * 255 },
            texture = love.graphics.newImage("test_texture.png"),
            portal = nil
        },
        C = {
            color = { math.random() * 255, math.random() * 255, math.random() * 255 },
            texture = love.graphics.newImage("test_texture.png"),
            portal = nil
        },
        D = {
            color = { math.random() * 255, math.random() * 255, math.random() * 255 },
            texture = love.graphics.newImage("test_texture.png"),
            portal = nil
        }
    }
end

function Sector:render_row(rx, ry, rz, rot_rad, col_h, fov, scr_x)
    local column_pixels = {}

    -- Raycasting
    -- ##########
    local translated_sector_x = self.sx - rx
    local translated_sector_y = self.sy - ry

    local wall_column = nil -- These 2 variables will be used later for texture mapping
    local wall_column_size = nil

    local slope = math.sin(rot_rad) / math.cos(rot_rad)

    local x_candidate = (math.cos(rot_rad) > 0 and "A") or "B"
    local x_coll_wall = (x_candidate == "A" and translated_sector_x + self.sw) or translated_sector_x
    local collision_y = x_coll_wall * slope

    local hit_wall = nil
    local trav_dist = nil

    if collision_y > translated_sector_y and collision_y < translated_sector_y + self.sh then
        hit_wall = x_candidate
        trav_dist = math.sqrt(collision_y * collision_y + x_coll_wall * x_coll_wall)
        wall_column = collision_y - translated_sector_y
        wall_column_size = self.sh
    else
        local y_candidate = (math.sin(rot_rad) > 0 and "D") or "C"
        local y_coll_wall = (y_candidate == "D" and translated_sector_y + self.sh) or translated_sector_y
        local collision_x = y_coll_wall / slope

        hit_wall = y_candidate
        trav_dist = math.sqrt(collision_x * collision_x + y_coll_wall * y_coll_wall)

        wall_column = collision_x - translated_sector_x
        wall_column_size = self.sw
    end

    -- Sector pixel generation
    -- #######################

    local hit_wall_data = self.walls[hit_wall]

    local function project(z)
        return col_h / 2 + (rz - z) / trav_dist
    end

    local projected_wall_ceiling = project(self.sceil)
    local projected_wall_floor = project(self.sfloor)

    -- Portal fun
    local wall_has_portal = false
    local wall_portaled_sector = hit_wall_data.portal

    local projected_neighbor_ceiling = nil
    local projected_neighbor_floor = nil
    local portal_pixels = nil
    
    if wall_portaled_sector ~= nil then
        wall_has_portal = true
        projected_neighbor_ceiling = project(wall_portaled_sector.sceil)
        projected_neighbor_floor = project(wall_portaled_sector.sfloor)
        portal_pixels = wall_portaled_sector:render_row(
            rx, ry, rz, rot_rad,
            col_h, fov, scr_x)
    end

    -- @TODO optimize all of this junk!!!
    -- (Draw textures directly to the screen using the GPU instead of generating pixel data ON THE CPU!)
    -- (If not that, at least make sure that portal rendering doesn't render the whole screen, only the part used,
    -- and also make the sector rendering accept the pixel data list as an argument and append to that so that way
    -- we wouldn't need a loop to concat the two arrays!)
    local r = fov * 2
    for y = 0, col_h, 1 do
        r = r - fov * 4 / col_h
        local yscan_slope = math.sin(r) / math.cos(r)

        local wall_percent = math.abs(yscan_slope * trav_dist * 80 - rz) / (self.sceil - self.sfloor)

        if scr_x % 2 == 0 then
            table.insert(column_pixels, {0, 0, wall_percent > 0 and wall_percent < 1 and 255 or 0})
        else
            if y < projected_wall_ceiling then
                table.insert(column_pixels, self.sceilcol)
            elseif y < projected_wall_floor then
                if wall_has_portal and y > projected_neighbor_ceiling and y < projected_neighbor_floor then -- Draw portal
                    table.insert(column_pixels, portal_pixels[y])
                else
                    -- Render wall
                    if hit_wall_data.texture == nil then -- Use fallback color
                        table.insert(column_pixels, hit_wall_data.color)
                    else -- Do the amazing texture rendering
                        local pixel_x = hit_wall_data.texture:getWidth() * (wall_column / wall_column_size)
                        local pixel_y = hit_wall_data.texture:getHeight() * ((y - projected_wall_ceiling) / (projected_wall_floor - projected_wall_ceiling))
    
                        if pixel_x > 0 and pixel_x < hit_wall_data.texture:getData():getWidth() and pixel_y > 0 and pixel_y < hit_wall_data.texture:getData():getHeight() then
                            -- If the pixel is valid, render it
                            local r, g, b = hit_wall_data.texture:getData():getPixel(pixel_x, pixel_y)
                            table.insert(column_pixels, { r, g, b })
                        else
                            -- Else, draw a scary pattern!
                            if y % 2 == 0 then
                                table.insert(column_pixels, { 255, 0, 0 })
                            else
                                table.insert(column_pixels, { 0, 0, 0 })
                            end
                        end
                    end
                end
            else
                table.insert(column_pixels, { 100, 0, 0 })
            end
        end
    end


    return column_pixels
end

return Sector