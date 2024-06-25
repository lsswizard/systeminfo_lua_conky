--[[
#########################
# conky-system-lua-V3   #
# by +WillemO @wim66    #
# v1.5 23-dec-17        #
#                       #
#########################
]]

--[[ BARGRAPH WIDGET
	v2.1 by wlourf (07 Jan. 2011)
	this widget draws a bargraph with different effects 
	http://u-scripts.blogspot.com/2010/07/bargraph-widget.html
	
To call the script in a conky, use, before TEXT
	lua_load /path/to/the/script/bargraph.lua
	lua_draw_hook_pre main_rings
and add one line (blank or not) after TEXT

Parameters are :
3 parameters are mandatory
name	- the name of the conky variable to display, for example for {$cpu cpu0}, just write name="cpu"
arg		- the argument of the above variable, for example for {$cpu cpu0}, just write arg="cpu0"
		  arg can be a numerical value if name=""
max		- the maximum value the above variable can reach, for example, for {$cpu cpu0}, just write max=100
	
Optional parameters:
x,y		- coordinates of the starting point of the bar, default = middle of the conky window
cap		- end of cap line, possible values are r,b,s (for round, butt, square), default="b"
		  http://www.cairographics.org/samples/set_line_cap/
angle	- angle of rotation of the bar in degrees, default = 0 (i.e. a vertical bar)
		  set to 90 for a horizontal bar
skew_x	- skew bar around x axis, default = 0
skew_y	- skew bar around y axis, default = 0
blocks  - number of blocks to display for a bar (values >0) , default= 10
height	- height of a block, default=10 pixels
width	- width of a block, default=20 pixels
space	- space between 2 blocks, default=2 pixels
angle_bar	- this angle is used to draw a bar in a circular way (ok, this is no more a bar !) default=0
radius		- for circular bars, internal radius, default=0
			  with radius, parameter width has no more effect.

Colours below are defined into braces {colour in hexadecimal, alpha}
fg_colour	- colour of a block ON, default= {0x00FF00,1}
bg_colour	- colour of a block OFF, default = {0x00FF00,0.5}
alarm		- threshold, values after this threshold will use alarm_colour colour , default=max
alarm_colour - colour of a block greater than alarm, default=fg_colour
smooth		- (true or false), create a gradient from fg_colour to bg_colour, default=false 
mid_colour	- colours to add to gradient, with this syntax {position into the gradient (0 to1), colour hexa, alpha}
			  for example, this table {{0.25,0xff0000,1},{0.5,0x00ff00,1},{0.75,0x0000ff,1}} will add
			  3 colours to gradient created by fg_colour and alarm_colour, default=no mid_colour
led_effect	- add LED effects to each block, default=no led_effect
			  if smooth=true, led_effect is not used
			  possible values : "r","a","e" for radial, parallel, perpendicular to the bar (just try!)
			  led_effect has to be used with these colours :
fg_led		- middle colour of a block ON, default = fg_colour
bg_led		- middle colour of a block OFF, default = bg_colour
alarm_led	- middle colour of a block > ALARM,  default = alarm_colour

reflection parameters, not available for circular bars
reflection_alpha    - add a reflection effect (values from 0 to 1) default = 0 = no reflection
                      other values = starting opacity
reflection_scale    - scale of the reflection (default = 1 = height of text)
reflection_length   - length of reflection, define where the opacity will be set to zero
					  values from 0 to 1, default =1
reflection			- position of reflection, relative to a vertical bar, default="b"
					  possible values are : "b","t","l","r" for bottom, top, left, right
draw_me     - if set to false, text is not drawn (default = true or 1)
              it can be used with a conky string, if the string returns 1, the text is drawn :
              example : "${if_empty ${wireless_essid wlan0}}${else}1$endif",

v1.0 (10 Feb. 2010) original release
v1.1 (13 Feb. 2010) numeric values can be passed instead conky stats with parameters name="", arg = numeric_value	
v1.2 (28 Feb. 2010) just renamed the widget to bargraph
v1.3 (03 Mar. 2010) added parameters radius & angle_bar to draw the bar in a circular way
v2.0 (12 Jul. 2010) rewrite script + add reflection effects and parameters are now set into tables
v2.1 (07 Jan. 2011) Add draw_me parameter and correct memory leaks, thanks to "Creamy Goodness"

--      This program is free software; you can redistribute it and/or modify
--      it under the terms of the GNU General Public License as published by
--      the Free Software Foundation version 3 (GPLv3)
--     
--      This program is distributed in the hope that it will be useful,
--      but WITHOUT ANY WARRANTY; without even the implied warranty of
--      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--      GNU General Public License for more details.
--     
--      You should have received a copy of the GNU General Public License
--      along with this program; if not, write to the Free Software
--      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
--      MA 02110-1301, USA.		
--
--      Modified by Lss 2024-03-01
]]

-- Set colors
colors = {
    dark_red = {0.545, 0, 0, 1},
    blue = {0, 0, 1, 1},
    white = {1, 1, 1, 1},
    cyan = {0, 1, 1, 1},
    green = {0, 1, 0, 1},
    light_red = {1, 0.5, 0.5, 1},
    dark_blue = {0, 0, 0.545, 1},
    light_blue = {0.5, 0.5, 1, 0.9},
    light_cyan = {0.5, 1, 1, 1},
    dark_green = {0, 0.545, 0, 1},
    light_green = {0.5, 1, 0.5, 1},
    grey = {0.5, 0.5, 0.5, 1},
    dark_grey = {0.25, 0.25, 0.25, 1},
    transparent_grey = {0.5, 0.5, 0.5, 0.5},
    semi_transparent_black = {0, 0, 0, 0.91},
    light_grey = {0.75, 0.75, 0.75, 1},
    medium_blue = {0, 0, 0.803, 1},
    sky_blue = {0.529, 0.808, 0.922, 1},
    steel_blue = {0.275, 0.51, 0.706, 1},
    deep_sky_blue = {0, 0.749, 1, 1},
    dodger_blue = {0.118, 0.565, 1, 0.9},
    yellow = {1, 1, 0, 1},
    red = {1, 0, 0, 1}
}

function createBar(name, arg, x,y,height, blocks)
    -- name: The name of the bar
    -- arg: The argument of the bar
    -- y: The y-coordinate of the bar
    -- blocks: The number of blocks in the bar
    return {
        name = name,
        arg = arg,
        max = 100, -- The maximum value of the bar
        alarm = 80, -- The alarm value of the bar
        bg_colour = {0x848E84, 0.25}, -- The background color of the bar
        fg_colour = {0x00ff00, 1}, -- The foreground color of the bar
        --fg_colour = {0x0000FF, 1}, -- blue
        alarm_colour = {0xff0000, 1}, -- The alarm color of the bar
        x = x, -- The x-coordinate of the bar
        y = y, -- The y-coordinate of the bar
        blocks = blocks, -- The number of blocks in the bar
        height = height, -- The height of the bar
        width = 15, -- The width of the bar
        angle = 90, -- The angle of the bar
        smooth = true, -- Whether the bar is smooth or not
        cap = "e", -- The cap of the bar
        skew_y = 0, -- The skew in the y-axis of the bar
        mid_colour = {{0.5, 0xffff00, 1}} -- The middle color of the bar
    }
end

-- Table to cache the results of conky_parse commands
local conky_parse_cache = {}
-- Cache timeout in seconds
local cache_timeout = 2

-- Function to parse conky commands with caching
function cached_conky_parse(command)
    -- Get the current time
    local current_time = os.time()
    -- Check if the command is in the cache and if the cache is still valid
    if conky_parse_cache[command] and (current_time - conky_parse_cache[command].time < cache_timeout) then
        -- Return the cached value
        return conky_parse_cache[command].value
    else
        -- Parse the command and store the result in the cache
        local value = conky_parse(command)
        conky_parse_cache[command] = {value = value, time = current_time}
        -- Return the parsed value
        return value
    end
end

function conky_background(cr)
    if not conky_window then return end
    -- Set up Cairo drawing context
    local cs =
        cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )
    local cr = cairo_create(cs)
    
    -- Draw the rounded rectangle background
    drawRoundedcorners(cr, 0, 0, conky_window.width, conky_window.height, 17)
    cairo_set_source_rgba(cr, 0, 0, 0, 0.99)  -- semi-transparent black
    cairo_fill(cr)
    
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

function drawRoundedcorners(cr, x, y, width, height, radius)
    cairo_new_path(cr)
    cairo_arc(cr, x + width - radius, y + radius, radius, -math.pi / 2, 0)
    cairo_arc(cr, x + width - radius, y + height - radius, radius, 0, math.pi / 2)
    cairo_arc(cr, x + radius, y + height - radius, radius, math.pi / 2, math.pi)
    cairo_arc(cr, x + radius, y + radius, radius, math.pi, 3 * math.pi / 2)
    cairo_close_path(cr)
end

-- Function to create a bar configuration table

-- This function draws text information on the screen using the Cairo graphics library.
-- Parameters:
--   cr: The Cairo context to draw on.
--   info: A table containing the text information to be drawn, including:
--     - font: The font to use for the text.
--     - size: The font size.
--     - color: The color of the text in RGBA format.
--     - x: The x-coordinate where the text should start.
--     - y: The y-coordinate where the text should start.
--     - align: The alignment of the text ("left", "center", or "right").
--     - text: The actual text to be drawn.
--     - twidth: The width of the text (used for right alignment).

function draw_info(cr, info)
    -- Set the font face and size
    cairo_select_font_face(cr, info.font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, info.size)
    
    -- Set the color for the text
    cairo_set_source_rgba(cr, table.unpack(info.color))
    
    -- Determine the x-coordinate based on the alignment
    local x = info.x
    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, info.text, extents)
    
    if info.align == "center" then
        -- Center alignment: calculate the text extents and adjust x to center the text
        x = (conky_window.width - extents.width) / 2
    elseif info.align == "right" then
        -- Right alignment: calculate the text extents and adjust x to right-align the text
        x = conky_window.width - info.twidth - extents.width
    end
    
    -- Move to the calculated position and draw the text
    cairo_move_to(cr, x, info.y)
    cairo_show_text(cr, info.text)
    cairo_stroke(cr)
end

-- Define function to text with a line
function draw_text_with_line(cr, text, font, size, text_color, line_color, line_thickness, x, y)
    -- Set font and size
    cairo_select_font_face(cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    
    -- Set text color and draw text
    cairo_set_source_rgba(cr, table.unpack(text_color))
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, text)
    cairo_stroke(cr)
    
    -- Get the width of the text
    local extents = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, extents)
    
    -- Draw the line
    cairo_set_source_rgba(cr, table.unpack(line_color))
    cairo_set_line_width(cr, line_thickness)
    cairo_move_to(cr, x + extents.width + 5, y - 6)
    cairo_line_to(cr, conky_window.width - 10, y - 6)
    cairo_stroke(cr)
end

function draw_bars(cr, bar, core_number, x_offset, xr_offset)
    -- Font settings
    cairo_select_font_face(cr, "URW Gothic", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 16)

    -- Define colors
    local core_color = {1, 1, 1, 1}  -- White color for core number (RGBA format)
    local freq_color = {0, 1, 1, 1}  -- Cyan color for frequency

    -- Text for core number and frequency
    local core_text = string.format("Core %s", core_number)
    local freq_text = string.format(conky_parse("${freq_g .. %s} Ghz"), core_number)
    
    -- Function to set color and draw text
    local function draw_text_with_color(text, color, x, y)
        cairo_set_source_rgba(cr, table.unpack(color))
        cairo_move_to(cr, x, y)
        cairo_show_text(cr, text)
    end

    -- Draw core number and frequency
    draw_text_with_color(core_text, core_color, bar.x - x_offset, bar.y + 12)
    draw_text_with_color(freq_text, freq_color, bar.x + xr_offset, bar.y + 12)


    -- Draw bars with core and freq info
    draw_multi_bar_graph(cr, bar)
end

function get_cpu_count()
    local cpu_count = - 1
    local cpuinfo_file = io.open("/proc/cpuinfo", "r")

    if cpuinfo_file then
        for line in cpuinfo_file:lines() do
            if line:match("^processor") then
                cpu_count = cpu_count + 1
            end
        end
        cpuinfo_file:close()
    else
        print("Error: Unable to open /proc/cpuinfo")
        return 0
    end

    -- Return the actual CPU count
    return cpu_count
end

-- Initialize tables and previous values
download_data, upload_data = {}, {}
previous_download_bytes, previous_upload_bytes = nil, nil

-- Function to get network speed in bytes
local function get_network_speed(interface, direction)
    local file_path = string.format("/sys/class/net/%s/statistics/%s_bytes", interface, direction)
    local file = io.open(file_path, "r")
    if not file then
        print(string.format("Error: Unable to open %s", file_path))
        return 0
    end
    local speed = tonumber(file:read("*all")) or 0
    file:close()
    return speed
end

-- Function to update network data
function update_network_data(interface)
    -- Retrieve current bytes
    local current_download_bytes = get_network_speed(interface, "rx")
    local current_upload_bytes = get_network_speed(interface, "tx")

    -- Initialize previous values if nil
    previous_download_bytes = previous_download_bytes or current_download_bytes
    previous_upload_bytes = previous_upload_bytes or current_upload_bytes

    -- Calculate speeds in KB per second
    local download_speed = (current_download_bytes - previous_download_bytes) / 1024
    local upload_speed = (current_upload_bytes - previous_upload_bytes) / 1024

    -- Update previous values
    previous_download_bytes, previous_upload_bytes = current_download_bytes, current_upload_bytes

    -- Maintain a fixed size for the data tables (max 100 entries)
    if #download_data >= 100 then table.remove(download_data, 1) end
    if #upload_data >= 100 then table.remove(upload_data, 1) end

    -- Insert new speeds
    table.insert(download_data, download_speed)
    table.insert(upload_data, upload_speed)
end

function draw_graph(cr, x, y, width, height, data, color, max_value)
    if #data > 1 then
        cairo_save(cr)
        cairo_set_source_rgba(cr, table.unpack(color)) -- Set the color for the data line
        cairo_set_line_width(cr, 2) -- Set the width of the data line
        
        -- Calculate the step size between data points
        local step = width / (#data - 1)
        
        -- Move to the first data point
        cairo_move_to(cr, x, y - (data[1] / max_value) * height)
        
        -- Draw a smooth curve connecting the data points
        for i = 2, #data do
            local ctrl_x = x + (i - 1 - 0.5) * step
            local ctrl_y = y - (data[i-1] / max_value) * height
            local end_x = x + (i - 1) * step
            local end_y = y - (data[i] / max_value) * height
            cairo_curve_to(cr, ctrl_x, ctrl_y, ctrl_x, ctrl_y, end_x, end_y)
        end
        
        cairo_stroke(cr) -- Apply the drawing operation to render the curve
                
        cairo_restore(cr)
    end
end
 -- Function to draw a line grid
function draw_line_grid(cr, x, y, width, height, spacing, color)
    -- Set the color and line width for the grid
    cairo_set_source_rgba(cr, table.unpack(color))
    cairo_set_line_width(cr, 1)
    
    -- Draw vertical lines
    for i = 0, width, spacing do
        cairo_move_to(cr, x + i, y)
        cairo_line_to(cr, x + i, y + height)
    end
    
    -- Draw horizontal lines
    for j = 0, height, spacing do
        cairo_move_to(cr, x, y + j)
        cairo_line_to(cr, x + width, y + j)
    end
    
    -- Apply the drawing operation to render the grid
    cairo_stroke(cr)
end

function draw_top_processes(cr, h_offset)
    -- Cache to store process information to avoid redundant parsing
    local process_info_cache = {}

     -- Common font and size settings
     local default_font = "URW Gothic"
     local font_size = 16

    -- Function to get process information, utilizing cache for speed
    local function get_process_info(index)
        -- Check if the information is already cached
        if not process_info_cache[index] then
            -- Cache the parsed information
            local process_name = cached_conky_parse("${top name " .. index .. "}")
            local cpu_usage = cached_conky_parse("${top cpu " .. index .. "}%")
            local memory_name = cached_conky_parse("${top_mem name " .. index .. "}")
            local memory_usage = cached_conky_parse("${top_mem mem_res " .. index .. "}")

            process_info_cache[index] = {
                {text = process_name, font = default_font, size = font_size, color = colors.white, x = 5},
                {text = cpu_usage, font = default_font, size = font_size, color = colors.cyan, x = 145},
                {text = memory_name, font = default_font, size = font_size, color = colors.white, x = 205},
                {text = memory_usage, font = default_font, size = font_size, color = colors.cyan, x = 347}
            }
        end
        return process_info_cache[index]
    end

    -- Loop through the top 5 processes
    for i = 1, 5 do
        -- Calculate the y offset for the current process
        local y_offset = h_offset + 525 + (i * 20)
        
        -- Get the process information from cache
        local info = get_process_info(i)
        
        -- Draw each piece of information
        for j, item in ipairs(info) do
            -- Update x position based on j to ensure correct placement
            item.x = (j == 1 and 5) or (j == 2 and 145) or (j == 3 and 205) or (j == 4 and 347)
            item.y = y_offset
            draw_info(cr, item)
        end
    end
end

function draw_multi_bar_graph(cr, params)
    cairo_save(cr)

    -- Check values
    if params.draw_me == true then params.draw_me = nil end
    if params.draw_me ~= nil and conky_parse(tostring(params.draw_me)) ~= "1" then return end
    if not params.name and not params.arg then
        print("No input values ... use parameters 'name' with 'arg' or only parameter 'arg'")
        return
    end
    if not params.max then
        print("No maximum value defined, use 'max'")
        return
    end

    -- Set default values
    local defaults = {
        name = "", arg = "", x = conky_window.width / 2, y = conky_window.height / 2,
        blocks = 10, height = 10, angle = 0, cap = "b", width = 20,
        space = 2, radius = 0, angle_bar = 0, bg_colour = {0x00FF00, 0.5},
        fg_colour = {0x0000FF, 1}, alarm_colour = nil, alarm = params.max, smooth = false,
        skew_x = 0, skew_y = 0, reflection_alpha = 0, reflection_length = 1, reflection_scale = 1
    }
    for key, value in pairs(defaults) do
        if params[key] == nil then params[key] = value end
    end

    params.angle = params.angle * math.pi / 180
    params.angle_bar = params.angle_bar * math.pi / 360
    params.skew_x = params.skew_x * math.pi / 180
    params.skew_y = params.skew_y * math.pi / 180
    params.alarm_colour = params.alarm_colour or params.fg_colour

    local cap_styles = {s = CAIRO_LINE_CAP_SQUARE, r = CAIRO_LINE_CAP_ROUND, b = CAIRO_LINE_CAP_BUTT}
    local cap_style = cap_styles[params.cap] or CAIRO_LINE_CAP_BUTT
    local delta = (params.cap == "r" or params.cap == "s") and params.height or 0

    local function rgb_to_r_g_b(colour_alpha)
        return ((colour_alpha[1] / 0x10000) % 0x100) / 255, ((colour_alpha[1] / 0x100) % 0x100) / 255, (colour_alpha[1] % 0x100) / 255, colour_alpha[2]
    end

    local function create_gradient_pattern(pattern_func, ...)
        local pattern = pattern_func(...)
        cairo_pattern_add_color_stop_rgba(pattern, 0, rgb_to_r_g_b(params.fg_colour))
        cairo_pattern_add_color_stop_rgba(pattern, 1, rgb_to_r_g_b(params.alarm_colour))
        if params.mid_colour then
            for _, mid in ipairs(params.mid_colour) do
                cairo_pattern_add_color_stop_rgba(pattern, mid[1], rgb_to_r_g_b({mid[2], mid[3]}))
            end
        end
        return pattern
    end

    local function create_led_gradient_pattern(pattern_func, colour_alpha, colour_led, ...)
        local pattern = pattern_func(...)
        cairo_pattern_add_color_stop_rgba(pattern, 0.0, rgb_to_r_g_b(colour_alpha))
        cairo_pattern_add_color_stop_rgba(pattern, 0.5, rgb_to_r_g_b(colour_led))
        cairo_pattern_add_color_stop_rgba(pattern, 1.0, rgb_to_r_g_b(colour_alpha))
        return pattern
    end

    local function create_pattern(colour_alpha, colour_led, is_background)
        if not params.smooth then
            if params.led_effect == "e" then
                return create_led_gradient_pattern(cairo_pattern_create_linear, colour_alpha, colour_led, -delta, 0, delta + params.width, 0)
            elseif params.led_effect == "a" then
                return create_led_gradient_pattern(cairo_pattern_create_linear, colour_alpha, colour_led, params.width / 2, 0, params.width / 2, -params.height)
            elseif params.led_effect == "r" then
                return create_led_gradient_pattern(cairo_pattern_create_radial, colour_alpha, colour_led, params.width / 2, -params.height / 2, 0, params.width / 2, -params.height / 2, params.height / 1.5)
            else
                return cairo_pattern_create_rgba(rgb_to_r_g_b(colour_alpha))
            end
        else
            return is_background and cairo_pattern_create_rgba(rgb_to_r_g_b(params.bg_colour)) or create_gradient_pattern(cairo_pattern_create_linear, params.width / 2, 0, params.width / 2, -params.height)
        end
    end

    local function draw_bar_section(y1, y2, y3, pattern)
        cairo_rectangle(cr, 0, y2, params.width, -params.height - y3)
        cairo_set_source(cr, pattern)
        cairo_fill(cr)
        cairo_pattern_destroy(pattern)
    end

    local function draw_single_bar(percentage)
        local y1 = -params.height * percentage / 100
        local y2, y3
        if percentage > (100 * params.alarm / params.max) then
            y1 = -params.height * params.alarm / 100
            y2 = -params.height * percentage / 100
            if params.smooth then y1 = y2 end
        end

        if params.angle_bar == 0 then
            local pattern = create_pattern(params.fg_colour, params.fg_led, false)
            draw_bar_section(y1, 0, y1, pattern)

            if not params.smooth and y2 then
                pattern = create_pattern(params.alarm_colour, params.alarm_led, false)
                draw_bar_section(y1, y1, y2, pattern)
                y3 = y2
            else
                y2, y3 = y1, y1
            end

            pattern = create_pattern(params.bg_colour, params.bg_led, true)
            draw_bar_section(y2, y2, y3, pattern)
        end
    end

    local function draw_multi_bar(percentage)
        local percent_per_block = 100 / params.blocks
        for block = 1, params.blocks do
            local y1 = -(block - 1) * (params.height + params.space)
            local is_light_on = percentage >= (percent_per_block * (block - 1))
            local colour_alpha, colour_led = params.bg_colour, params.bg_led
            if is_light_on then
                colour_alpha, colour_led = params.fg_colour, params.fg_led
                if percentage >= (100 * params.alarm / params.max) and (percent_per_block * block) > (100 * params.alarm / params.max) then
                    colour_alpha, colour_led = params.alarm_colour, params.alarm_led
                end
            end

            local pattern
            if not params.smooth then
                if params.angle_bar == 0 then
                    if params.led_effect == "e" then
                        pattern = create_led_gradient_pattern(cairo_pattern_create_linear, colour_alpha, colour_led, -delta, 0, delta + params.width, 0)
                    elseif params.led_effect == "a" then
                        pattern = create_led_gradient_pattern(cairo_pattern_create_linear, colour_alpha, colour_led, params.width / 2, -params.height / 2 + y1, params.width / 2, params.height / 2 + y1)
                    elseif params.led_effect == "r" then
                        pattern = create_led_gradient_pattern(cairo_pattern_create_radial, colour_alpha, colour_led, params.width / 2, y1, 0, params.width / 2, y1, params.width / 1.5)
                    else
                        pattern = cairo_pattern_create_rgba(rgb_to_r_g_b(colour_alpha))
                    end
                    
                else
                    if params.led_effect == "a" then
                        pattern = create_led_gradient_pattern(cairo_pattern_create_radial, colour_alpha, colour_led, 0, 0, params.radius + (params.height + params.space) * (block - 1), 0, 0, params.radius + (params.height + params.space) * block)
                    else
                        pattern = cairo_pattern_create_rgba(rgb_to_r_g_b(colour_alpha))
                    end
                end
            else
                pattern = is_light_on and create_gradient_pattern(cairo_pattern_create_linear, params.width / 2, params.height / 2, params.width / 2, -(params.blocks - 0.5) * (params.height + params.space)) or cairo_pattern_create_rgba(rgb_to_r_g_b(params.bg_colour))
            end
            cairo_set_source(cr, pattern)
            cairo_pattern_destroy(pattern)

            if params.angle_bar == 0 then
                cairo_move_to(cr, 0, y1)
                cairo_line_to(cr, params.width, y1)
            else
                cairo_arc(cr, 0, 0, params.radius + (params.height + params.space) * block - params.height / 2, -params.angle_bar - math.pi / 2, params.angle_bar - math.pi / 2)
            end
            cairo_stroke(cr)
            
        end
    end

    local function draw_reflection()
        if params.reflection_alpha <= 0 then return end

        local matrix_reflection = cairo_matrix_t:create()
        local pattern_reflection = cairo_pattern_create_linear(0, 0, 0, params.height * params.reflection_length)
        cairo_pattern_add_color_stop_rgba(pattern_reflection, 0, 1, 1, 1, params.reflection_alpha)
        cairo_pattern_add_color_stop_rgba(pattern_reflection, 1, 1, 1, 1, 0)

        cairo_matrix_init(matrix_reflection, 1, 0, 0, -1, 0, params.height * (1 + params.reflection_scale))
        cairo_pattern_set_matrix(pattern_reflection, matrix_reflection)

        cairo_mask(cr, pattern_reflection)
        cairo_pattern_destroy(pattern_reflection)
        cairo_matrix_destroy(matrix_reflection)
    end

    -- Parse value
    local value = tonumber(conky_parse(string.format("${%s %s}", params.name, params.arg))) or 0
    if value > params.max then value = params.max end
    local percentage = 100 * value / params.max

    -- Setup Cairo context
    cairo_set_line_cap(cr, cap_style)
    cairo_set_line_width(cr, params.height) -- or params-width / 3
    cairo_translate(cr, params.x, params.y)
    if params.angle_bar == 0 then
        cairo_rotate(cr, params.angle)
    else
        cairo_rotate(cr, params.angle - params.angle_bar)
    end
    cairo_save(cr)
  
    -- Skew
    local matrix_skew = cairo_matrix_t:create()
    cairo_matrix_init(matrix_skew, 1, params.skew_y, params.skew_x, 1, 0, 0)
    cairo_transform(cr, matrix_skew)

    if params.blocks == 1 then 
        draw_single_bar(percentage)
    else
        draw_multi_bar(percentage)
    end

    cairo_restore(cr)

    -- Draw reflection
    draw_reflection()

    cairo_restore(cr)
end





 --[[
 function draw_port_info(cr, x, y)
    local port_info = {
        {title = "PORTS", font = "Vampire Wars", size = 18, color = dark_red, x = 5, y = y},
        {title = "Inbound:", font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x, y = y + 20},
        {title = conky_parse("${tcp_portmon 1 32767 count}"), font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x + 90, y = y + 20},
        {title = "Outbound:", font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x + 180, y = y + 20},
        {title = conky_parse("${tcp_portmon 32768 61000 count}"), font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x + 270, y = y + 20},
        {title = "ALL:", font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x + 320, y = y + 20},
        {title = conky_parse("${tcp_portmon 1 65535 count}"), font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x + 345, y = y + 20},
        {title = "Port", font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x, y = y + 40},
        {title = "Inbound Connection", font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x + 70, y = y + 40}
    }

    for i = 0, 2 do
        table.insert(port_info, {title = conky_parse(string.format("${tcp_portmon 1 32767 rhost %d}", i)), font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x, y = y + 60 + (i * 20)})
        table.insert(port_info, {title = conky_parse(string.format("${tcp_portmon 1 32767 lservice %d}", i)), font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x + 90, y = y + 60 + (i * 20)})
    end

    table.insert(port_info, {title = "Port", font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x, y = y + 120})
    table.insert(port_info, {title = "Outbound Connection", font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x + 70, y = y + 120})

    for i = 0, 2 do
        table.insert(port_info, {title = conky_parse(string.format("${tcp_portmon 32768 61000 rservice %d}", i)), font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x, y = y + 140 + (i * 20)})
        table.insert(port_info, {title = conky_parse(string.format("${tcp_portmon 32768 61000 rhost %d}", i)), font = "URW Gothic", size = 14, color = {1, 1, 1, 1}, x = x + 70, y = y + 140 + (i * 20)})
    end

    for _, item in ipairs(port_info) do
        drawText(cr, item.title, item.font, item.size, item.color, item.x, item.y)
    end
 ]]
