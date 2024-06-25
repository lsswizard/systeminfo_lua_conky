--[[Lss Conky]]--

require "cairo"
require "cairo_xlib"
require 'imlib2'
require 'functions'

-- Function to execute a command and return the result
local function exec_command(command)
    local f = io.popen(command)
    local result = f:read("*a")
    f:close()
    return result
end

-- Function to determine CPU temperature color based on thresholds
local function cpu_temp()
    local temp = tonumber(exec_command("sensors | awk '/AMD TSI/ {print $5}' | cut -c 2-3"))
    if temp <= 55 then
        return colors.cyan
    elseif temp < 76 then
        return colors.yellow
    else
        return colors.red
    end
end

-- Function to create an info section with specified parameters
local function create_info_section(text, font, size, color, x, y, align, twidth)
    return {
        text = text,
        font = font,
        size = size,
        color = color,
        x = x,
        y = y,
        align = align,
        twidth = twidth
    }
end

-- Function to gather different sections of system information
local function gather_info_sections(h_offset)

    -- Define shared styles
    local font = "URW Gothic"
    local font_size = 18
    local title_color = colors.white
    local info_color = colors.cyan
    local right_align = "right"
    local temp_color = cpu_temp()
    
    local sections = {
        system = {
            create_info_section(cached_conky_parse("${execi 36000 lsb_release -d | awk '/Description:/ {print $2,$3,$4}'}"), font, 22, colors.green, 0, 42, "center"),
            create_info_section("Kernel:", font, font_size, title_color, 20, 60),
            create_info_section(cached_conky_parse("${execi 43200 uname -r | sed -e 's/-generic//'}"), font, font_size, info_color, 82, 60),
        },
        packages = {
            create_info_section("Packages:", font, font_size, title_color, 20, 80),
            create_info_section(cached_conky_parse("${execi 3600 pacman -Qq | wc -l}"), font, font_size, info_color, 115, 80),
            create_info_section("Packages(AUR):", font, font_size, title_color, 20, 100),
            create_info_section(cached_conky_parse("${execi 3600 paru -Qm | wc -l}"), font, font_size, info_color, 163, 100)
        },
        updates = {
            create_info_section("Updates(Arch):", font, font_size, title_color, 50, 80, right_align, 47),
            create_info_section(cached_conky_parse("${execi 3600 checkupdates | wc -l}"), font, font_size, info_color, 50, 80, right_align, 20),
            create_info_section("Updates(Aur):", font, font_size, title_color, 50, 100, right_align, 47),
            create_info_section(cached_conky_parse("${execi 3600 paru -Qua | wc -l}"), font, font_size, info_color, 50, 100, right_align, 20),
        },
        cpu = {
            create_info_section(exec_command("lscpu | awk '/Model name/ {print $3,$4,$5,$6}'"), font, 20, colors.green, 0, 140, "center"),
            create_info_section("Temp:", font, font_size, title_color, 20, h_offset + 34),
            create_info_section(exec_command("sensors | awk '/AMD TSI/ {print $5}' | sed 's/+//'"), font, 16, temp_color, 80, h_offset + 34),
            create_info_section("Voltage:", font, font_size, title_color, 0, h_offset + 34, right_align, 100),
            create_info_section(exec_command("sensors | awk '/VIN4/ {printf \"%.2f\", $2} /VIN4/ {printf $3}'"), font, 16, info_color, 58, h_offset + 34, right_align, 20),
            create_info_section("Pump:", font, font_size, title_color, 20, h_offset + 52),
            create_info_section(exec_command("sensors | awk '/fan2/ {print $2,$3; exit}'"), font, 16, info_color, 80, h_offset + 52),
            create_info_section("System:", font, font_size, title_color, 5, h_offset + 52, right_align, 100),
            create_info_section(exec_command("sensors | awk '/fan1/ {print $2,$3; exit}'"), font, 16, info_color, 68, h_offset + 52, right_align, 20),
            create_info_section("Governor:", font, font_size, title_color, 20, h_offset + 70),
            create_info_section(exec_command("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"), font, 16, info_color, 110, h_offset + 70),
            create_info_section("Power:", font, font_size, title_color, 20, h_offset + 70, right_align, 100),
            create_info_section(exec_command("sensors | awk '/SVI2_P_Core/ {print $2,$3}' | sed 's/+//g'"), font, 16, info_color, 120, h_offset + 70, right_align, 20),
        },
        gpu = {
            create_info_section(exec_command("glxinfo | awk '/Device/ {print $3,$4,$5}'"), font, 20, colors.green, 0, h_offset + 117, "center"),
            create_info_section("Vram:", font, font_size, title_color, 20, h_offset + 139),
            create_info_section(exec_command("awk '/wlan0/ {print $2}' /proc/net/dev | numfmt --to=iec"), font, 16, info_color, 72, h_offset + 139),
            create_info_section("Driver:", font, font_size, title_color, 0, h_offset + 139, right_align, 118),
            create_info_section(exec_command("glxinfo | grep 'OpenGL version' |cut -c52-62"), font, 16, info_color, 0, h_offset + 139, right_align, 20),
            create_info_section("Usage:", font, font_size, title_color, 20, h_offset + 159),
            create_info_section(exec_command("cat /sys/class/drm/card1/device/gpu_busy_percent") .. "%", font, 16, info_color, 64, h_offset + 159, right_align, 20),
            create_info_section("Temp Edge:", font, font_size, title_color, 20, h_offset + 179),
            create_info_section(exec_command("sensors | awk '/edge/ {print substr($0, 16, 8)}'"), font, 16, info_color, 128, h_offset + 179),
            create_info_section("Temp Junction:", font, font_size, title_color, 20, h_offset + 179, right_align, 76),
            create_info_section(exec_command("sensors | awk '/junction/ {print substr($0, 16, 8)}'"), font, 16, info_color, 132, h_offset + 179, right_align, 20),
            create_info_section("Power Used:", font, font_size, title_color, 20, h_offset + 199),
            create_info_section(exec_command("amdgpu_top -d | awk '/Power/ {print $4,$5}' | sed '2,4d'"), font, 16, info_color, 131, h_offset + 199),
            create_info_section("Fan Speed:", font, font_size, title_color, 20, h_offset + 199, right_align, 95),
            create_info_section(exec_command("amdgpu_top -gm | awk '/fan_speed/ {print $2}' | cut -d, -f1") .. " rpm", font, 16, info_color, 90, h_offset + 199, right_align, 20),
        },
        memory = {
            create_info_section("Used:", font, font_size, title_color, 20, h_offset + 246),
            create_info_section(exec_command("free  -h | awk '/Mem/ {print $3}' | cut -c 1-4") .. "/" .. exec_command("free -h | awk '/Mem/ {print $2}' | cut -c 1-3") .. " (" .. exec_command("free | awk '/Mem/ {printf \"%.1f\", $3/$2 * 100}'") .. "%)", font, 16, info_color, 20, h_offset + 246, right_align, 20),
        },
        disk = {
            create_info_section("Root:", font, font_size, title_color, 20, h_offset + 295),
            create_info_section(exec_command("df -h / | awk 'NR==2 {print $4}'") .. "/" .. exec_command("df -h / | awk 'NR==2 {print $2}'"), font, 16, info_color, 20, h_offset + 295, right_align, 20),
            create_info_section("Home:", font, font_size, title_color, 20, h_offset + 314),
            create_info_section(exec_command("df -h /home | awk 'NR==2 {print $4}'") .. "/" .. exec_command("df -h /home | awk 'NR==2 {print $2}'"), font, 16, info_color, 20, h_offset + 314, right_align, 20),
        },
        network = {
            create_info_section("Wifi:", font, 16, title_color, 20, h_offset + 356),
            create_info_section("Wlan0", font, 16, info_color, 58, h_offset + 356),
            create_info_section("IP :", font, 16, title_color, 58, h_offset + 356, right_align, 115),
            create_info_section(exec_command("ifconfig wlan0 | awk '/wlan0/ { iface=$1 } /inet / { print $2 }'"), font, 16, info_color, 58, h_offset + 356, right_align, 20),
            create_info_section("Download:", font, font_size, title_color, 20, h_offset + 455),
            create_info_section("Upload:", font, font_size, title_color, 20, h_offset + 455, right_align, 67),
            create_info_section(cached_conky_parse("${upspeed wlan0}"), font, 16, info_color, 58, h_offset + 455, right_align, 20),
            create_info_section(cached_conky_parse("${downspeed wlan0}"), font, 16, info_color, 120, h_offset + 455),
            create_info_section("Signal Strength:", font, font_size, title_color, 20, h_offset + 475),
            create_info_section(cached_conky_parse("${wireless_link_qual_perc wlan0}%"), font, 16, info_color, 157, h_offset + 475),
        },
        processes = {
            create_info_section("CPU", font, font_size, colors.green, 65, h_offset + 525),
            create_info_section("Memory", font, font_size, colors.green, 255, h_offset + 525),
            -- Uncomment the lines below if 'Total' sections are needed
            -- create_info_section("Total:", font, font_size, title_color, 20, h_offset + 650),
            -- create_info_section(cached_conky_parse("${processes}"), font, 16, info_color, 68, h_offset + 650),
        }
    }

    return sections
end

function create_cpu_bars(cpu_count, h_offset)
    local bars_settings = {}
    local bar_height = 16
    local bar_spacing = 3
    local initial_y = 138

    -- Create CPU bars and insert them into the settings table
    for i = 1, cpu_count + 1 do
        local y = initial_y + i * bar_height -- Calculate y-coordinate for the bar
        -- createBar parameters: name, argument, x position, y position, height, spacing, number of blocks
        table.insert(bars_settings, createBar("cpu", "cpu" .. i, 95, y, bar_spacing, 43))
        
    end
    return bars_settings
end


function draw_section_headers(cr, h_offset)
    local sections = {
        {title = "System Information", y = 20},
        {title = "CPU", y = 125},
        {title = "GPU", y = h_offset + 101},
        {title = "Memory", y = h_offset + 225},
        {title = "Disk", y = h_offset + 270},
        {title = "NETWORK", y = h_offset + 335},
        {title = "Processes", y = h_offset + 500}
    }

    for _, section in ipairs(sections) do
        draw_text_with_line(cr, section.title, "Vampire Wars", 20, colors.dark_red, colors.white, 2, 5, section.y)
    end
end

function draw_network_section(cr, h_offset)
    local grid_color = {1, 1, 1, 0.3}
    draw_line_grid(cr, 20, h_offset + 360, 170, 77, 8, grid_color)
    draw_line_grid(cr, 212, h_offset + 360, 170, 77, 8, grid_color)
    
    draw_graph(cr, 20, h_offset + 435, 170, 37, download_data, colors.dark_red, 10700)
    draw_graph(cr, 212, h_offset + 435, 170, 37, upload_data, colors.dark_green, 10700)
end

function conky_main_bars()
    if conky_window == nil then
        return
    end

    -- Assuming get_cpu_count() is called infrequently, cache its result
    local current_cpu_count = get_cpu_count()
    if current_cpu_count ~= cpu_count then
        cpu_count = current_cpu_count
        -- Recalculate h_offset only when cpu_count changes
        h_offset = 138 + (cpu_count * 16.7)
    end

    local bars = create_cpu_bars(cpu_count, h_offset)
    
    local updates = tonumber(conky_parse("${updates}"))

    -- Create Cairo surface and context only once per call
    local cs = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        conky_window.width,
        conky_window.height
    )
    local cr = cairo_create(cs)

    -- Gather and draw info sections in a single loop to minimize context switching
    

    -- Batch draw operations for section headers, network data, and top processes
    draw_section_headers(cr, h_offset)
    update_network_data("wlan0")
    draw_network_section(cr, h_offset)
    draw_top_processes(cr, h_offset)

    -- Only draw CPU bars after a minimum number of updates to reduce load
    if updates > 2 then
        local sections = gather_info_sections(h_offset)
        for section_name, section_info in pairs(sections) do
            for _, info_section in ipairs(section_info) do
                draw_info(cr, info_section)
            end
        end
        for i, bar in ipairs(bars) do
            --draw_multi_bar_graph(cr, bar)
            draw_bars(cr, bar, i, 75, 225)
            --draw_multi_bar_graph(cr, gpubar)
        end
        --draw gpu bar
         draw_multi_bar_graph(cr, createBar("execi 2 cat /sys/class/drm/card1/device/gpu_busy_percent", "", 87, h_offset + 146, 3, 50))
    end

    cairo_surface_flush(cs)
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
