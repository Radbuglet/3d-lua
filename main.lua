local Sector = require('Sector')

local mainsec = Sector(0, 0, 4, 10, 0, 300)
local othersec = Sector(4, 0, 4, 10, -100, 280)
othersec.sfloortexture = love.graphics.newImage("textures/tracks.png")

mainsec.walls.A.portal = othersec
othersec.walls.B.portal = mainsec

local px = 1
local py = 1
local pz = 15
local pr = 0

local fov = 0.5235988
local sw = 130
local sh = 100
local pixel_mult = 10

function love.load()
    love.window.setTitle("Rad's Game")
    love.window.setMode(sw * pixel_mult, sh * pixel_mult)
end

function love.draw()
    if love.keyboard.isDown("a") then
        pr = pr - 0.05
    end

    if love.keyboard.isDown("d") then
        pr = pr + 0.05
    end

    if love.keyboard.isDown("w") then
        px = px + math.cos(pr) / 20
        py = py + math.sin(pr) / 20
    end

    if love.keyboard.isDown("s") then
        px = px - math.cos(pr) / 20
        py = py - math.sin(pr) / 20
    end

    if love.keyboard.isDown("space") then
        pz = pz + 5
    end

    if love.keyboard.isDown("lshift") then
        pz = pz - 5
    end

    local rot = pr - fov / 2
    for x = 0, sw, 1 do
        local y = 0
        for _, pixel_color in pairs(mainsec:render_row(px, py, pz, rot, sh, fov, x)) do
            love.graphics.setColor(pixel_color)
            love.graphics.rectangle("fill", x * pixel_mult, y * pixel_mult, pixel_mult, pixel_mult)
            y = y + 1
        end

        rot = rot + fov / sw
    end

    love.graphics.print("FPS = "..love.timer.getFPS(), 0, 0)
end