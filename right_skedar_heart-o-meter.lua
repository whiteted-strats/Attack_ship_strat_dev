-- Adapted from a script adapted from Henrik's Lag-O-Meter (https://www.dropbox.com/s/5nd9eh5jvpthzd0/Lag-O-Meter.lua?dl=0)
-- Tracks the frequency with which the right skedar on attack ship updates
-- (both movement & running his script in most cases)

require "Utilities\\PD\\GuardDataReader"
require "Data\\PD\\GuardData"

-- Classic address finder
function getSkedarAddr()
    local skedar_addr = nil
	function markIfSkedar(gdr)
		local id = gdr:get_value("id")

        if id == 0x31 then
            skedar_addr = gdr.current_address
        end
    end

	GuardDataReader.for_each(markIfSkedar)
	
    return skedar_addr
end

-- Find skedar once
local skedar_addr = getSkedarAddr()


-- ===============================================================
-- Essentially copied from Lag-O-Meter

function make_color(_r, _g, _b, _a)
	local a_hex = bit.band(math.floor((_a * 255) + 0.5), 0xFF)
	local r_hex = bit.band(math.floor((_r * 255) + 0.5), 0xFF)
	local g_hex = bit.band(math.floor((_g * 255) + 0.5), 0xFF)
	local b_hex = bit.band(math.floor((_b * 255) + 0.5), 0xFF)
	
	a_hex = bit.lshift(a_hex, (8 * 3))
	r_hex = bit.lshift(r_hex, (8 * 2))
	g_hex = bit.lshift(g_hex, (8 * 1))
	b_hex = bit.lshift(b_hex, (8 * 0))
	
	return (a_hex + r_hex + g_hex + b_hex)
end

function make_rgb(_r, _g, _b)
	return make_color(_r, _g, _b, 1.0)
end

local screen = {}
-- This doesn't work for window sizes that are larger than the monitor size, because
-- BizHawk silently rejects such cases. So window size may be set to e.g. 4x, while 
-- the actual size remains 2x.
screen.width = (client.bufferwidth() / client.getwindowsize())
screen.height = (client.bufferheight() / client.getwindowsize())

local meter = {}
meter.width = 20
meter.height = screen.height
meter.min_x = screen.width
meter.min_y = 0
meter.max_x = (meter.min_x + meter.width)
meter.max_y = (meter.min_y + meter.height)
meter.max_value = 60

local text = {}
text.width = 7.5
text.height = 15

local label = {}
label.horizontal_spacing = 2.5

client.SetGameExtraPadding(0, 0, (meter.width + math.ceil((2 * text.width) + (2 * label.horizontal_spacing))), 0)

function clamp(value, min_, max_)
	return math.min(math.max(value, min_), max_)
end

function calculate_factor(value)
	return math.min((value / meter.max_value), 1.0)
end


local threshold_color = 0xFFFFFFFF
function draw_thresholds(game_value)
	value = 1
	while value < meter.max_value do
		local factor = calculate_factor(value)		
		local y = (meter.min_y + ((1.0 - factor) * meter.height))		
    
		gui.drawLine(meter.min_x, y, meter.max_x, y, threshold_color)	
		gui.drawText((meter.max_x + label.horizontal_spacing), (y - (text.height / 2.0)), string.format("%d", value), threshold_color)
	
		incr = (value >= 10) and 2 or 1
		value = value + incr
	end
end

function draw_meter(calc_value)
	local calc_factor = calculate_factor(calc_value)
	local calc_height = (calc_factor * meter.height)	
	local calc_red = clamp((2.0 * calc_factor), 0.0, 1.0)
	local calc_green = clamp((2.0 * (1.0 - calc_factor)), 0.0, 1.0)
	local calc_blue = 0.0	
	local calc_color = make_rgb(calc_red, calc_green, calc_blue)

	gui.drawRectangle(meter.min_x, (meter.min_y + (meter.height - calc_height)), meter.width, calc_height, calc_color, calc_color)
end



-- ===========================================================================


local prevTimer = 0
local diff = 0
function on_update()
    local timer = GuardData:get_value(skedar_addr, "timer")

    -- Update diff if we increase
    -- If we decrease (reset), then the only sensible option is to keep the previous diff
    if timer > prevTimer then
        diff = timer - prevTimer
    end
    
	draw_meter(diff)
	draw_thresholds(diff)
    
    -- Update follower
    prevTimer = timer
end

-- Only register if we found the pres
if skedar_addr ~= nil then
	event.onframeend(on_update)
else
	console.log("Skedar (guard #0x31) not found, terminating.")
end