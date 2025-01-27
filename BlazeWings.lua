local ffi = require("ffi")
local vector = require("vector")

-- FFI definitions
ffi.cdef[[
typedef void*(__thiscall* GetClientEntity_t)(void*, int);
]]

local native_GetClientEntity = vtable_bind('client.dll', 'VClientEntityList003', 3, 'void*(__thiscall*)(void*, int)')
local nullptr = ffi.new('void*')
local char_ptr = ffi.typeof('char*')
local class_ptr = ffi.typeof('void***')
local animation_layer_offset = 0x2990
local animation_layer_t = ffi.typeof([[
struct {
    char pad0[0x18];
    uint32_t sequence;
    float prev_cycle;
    float weight;
    float weight_delta_rate;
    float playback_rate;
    float cycle;
    void *entity;
    char pad1[0x4];
} **
]])

local COLORS = {
    RED = "\\adc143c",
    PINK = "\\afff0f5",
    WHITE = "\\aFFFFFF"
}

local MARKER_CONFIG = {
    bullet_count = 5,
    initial_size = 8,
    max_size = 25,
    duration = 2.0,
    fade_time = 0.3
}

local screen_width, screen_height = client.screen_size()
local watermark_alpha = 255
local hit_logs = {}
local screen_size = {client.screen_size()}
local center_x = screen_size[1] / 2
local center_y = screen_size[2] / 2 + 100

local menu = {
    menu_structure = ui.new_label("AA", "Anti-aimbot angles", COLORS.RED .. "BlazeWings"),
    
    tab = ui.new_combobox("AA", "Anti-aimbot angles", "\\nBlazeWings", {
        "SOCIAL",
        "AA-BUILDER",
        "VISUALS",
        "MISC"
    }),

    social = {
        community = ui.new_label("AA", "Anti-aimbot angles", "Community: BlazeWings"),
        discord_copy = ui.new_button("AA", "Anti-aimbot angles", "Copy Discord", function()
            clipboard.set("your_discord_link_here")
        end),
        build_version = ui.new_label("AA", "Anti-aimbot angles", "Build: v1.0")
    },

    aa_builder = {
        category = ui.new_combobox("AA", "Anti-aimbot angles", "\\nAA Category", {
            "Main Category",
            "Anti-Aim Category",
            "Defensive Category"
        }),

        main = {
            force_break_lc = ui.new_checkbox("AA", "Anti-aimbot angles", "Force Break LC"),
            safe_head = ui.new_checkbox("AA", "Anti-aimbot angles", "Safe Head"),
            safe_head_distance = ui.new_slider("AA", "Anti-aimbot angles", "└─ Distance", 0, 100, 50),
            anti_backstab = ui.new_checkbox("AA", "Anti-aimbot angles", "Anti Backstab"),
        },

        antiaim = {
            state = ui.new_combobox("AA", "Anti-aimbot angles", "State", {
                "Global",
                "Standing",
                "Moving",
                "Slow Motion",
                "Crouching",
                "Air",
                "Air-Crouching",
                "FakeLag"
            }),

            enable_condition = ui.new_checkbox("AA", "Anti-aimbot angles", "Enable Condition"),
            
            pitch = ui.new_combobox("AA", "Anti-aimbot angles", "Pitch", {
                "Off",
                "Up",
                "Down",
                "Random",
                "Custom"
            }),
            pitch_custom = ui.new_slider("AA", "Anti-aimbot angles", "\\n Custom Pitch", -89, 89, 0),

            yaw_base = ui.new_combobox("AA", "Anti-aimbot angles", "Yaw Base", {
                "Local View",
                "At targets"
            }),

            yaw = ui.new_combobox("AA", "Anti-aimbot angles", "Yaw", {
                "Off",
                "180",
                "Spin",
                "L & R",
                "Jitter"  -- Добавлен jitter
            }),
            yaw_static = ui.new_slider("AA", "Anti-aimbot angles", "\\n Static Yaw", -180, 180, 0),
            yaw_jitter = ui.new_slider("AA", "Anti-aimbot angles", "\\n Jitter Yaw", -180, 180, 0), -- Добавлен слайдер для jitter
            yaw_jitter_speed = ui.new_slider("AA", "Anti-aimbot angles", "Jitter Speed", 1, 100, 50), -- Добавлен слайдер скорости

            yaw_lr = {
                left = ui.new_slider("AA", "Anti-aimbot angles", "Left Yaw", -180, 180, -90),
                right = ui.new_slider("AA", "Anti-aimbot angles", "Right Yaw", -180, 180, 90)
            },

            body_yaw = ui.new_combobox("AA", "Anti-aimbot angles", "Body Yaw", {
                "Off",
                "Opposite",
                "Jitter",
                "Static"
            }),
            body_yaw_static = ui.new_slider("AA", "Anti-aimbot angles", "\\n Static Body Yaw", -180, 180, 0),
            body_yaw_jitter = ui.new_slider("AA", "Anti-aimbot angles", "\\n Jitter Body Yaw", -180, 180, 0)
        },

        defensive = {
            state = ui.new_combobox("AA", "Anti-aimbot angles", "State", {
                "Global",
                "Standing",
                "Moving",
                "Slow Motion",
                "Crouching",
                "Air",
                "Air-Crouching"
            }),
            enabled = ui.new_checkbox("AA", "Anti-aimbot angles", "Enable Defensive"),
            pitch = ui.new_combobox("AA", "Anti-aimbot angles", "Pitch", {
                "Off",
                "Default",
                "Up",
                "Down",
                "Random",
                "Custom"
            }),
            yaw = ui.new_combobox("AA", "Anti-aimbot angles", "Yaw", {
                "Off",
                "180",
                "Spin",
                "Static",
                "180 Z",
                "Crosshair"
            }),
            yaw_jitter = ui.new_combobox("AA", "Anti-aimbot angles", "Yaw Jitter", {
                "Off",
                "Offset",
                "Center",
                "Random",
                "Skitter",
                "3-way",
                "5-way"
            }),
            yaw_jitter_3way = ui.new_slider("AA", "Anti-aimbot angles", "\\n3-Way Jitter", -180, 180, 0),
            yaw_jitter_5way = ui.new_slider("AA", "Anti-aimbot angles", "\\n5-Way Jitter", -180, 180, 0)

        }
    },

    visuals = {
        indicators = ui.new_checkbox("AA", "Anti-aimbot angles", "Indicators"),
        indicators_color = ui.new_color_picker("AA", "Anti-aimbot angles", "Indicators Color", 255, 255, 255, 255),
        arrows = ui.new_checkbox("AA", "Anti-aimbot angles", "Arrows"),
        arrows_color = ui.new_color_picker("AA", "Anti-aimbot angles", "Arrows Color", 255, 255, 255, 255),
        hit_marker = ui.new_checkbox("AA", "Anti-aimbot angles", "Hit Marker"),
        hit_marker_color = ui.new_color_picker("AA", "Anti-aimbot angles", "Hit Marker Color", 255, 255, 255, 255)
    },

    misc = {
        thirdperson = ui.new_checkbox("AA", "Anti-aimbot angles", "Thirdperson"),
        thirdperson_distance = ui.new_slider("AA", "Anti-aimbot angles", "Thirdperson Distance", 0, 200, 100),
        aspect_ratio = ui.new_checkbox("AA", "Anti-aimbot angles", "Aspect Ratio"),
        aspect_ratio_value = ui.new_slider("AA", "Anti-aimbot angles", "Aspect Ratio Value", 0, 200, 100),
        hit_logs = ui.new_checkbox("AA", "Anti-aimbot angles", "Hit Logs"),
        animation_breaker = ui.new_checkbox("AA", "Anti-aimbot angles", "Animation Breaker")
    }
}

-- Anti-Aim состояния и настройки для каждого состояния
local aa_states = {
    ["Global"] = {},
    ["Standing"] = {},
    ["Moving"] = {},
    ["Slow Motion"] = {},
    ["Crouching"] = {},
    ["Air"] = {},
    ["Air-Crouching"] = {},
    ["FakeLag"] = {}
}





-- Функция выбора режима и силы в зависимости от состояния
local function get_break_settings(state, speed)
    local settings = {
        shooting = {mode = "Maximum", strength = 100},
        air = {mode = "Dynamic", strength = 80},
        duck = {mode = "Adaptive", strength = 90},
        move = {mode = "Random", strength = 70},
        stand = {mode = "Adaptive", strength = 60}
    }

    return settings[state] or settings.stand
end

-- Вспомогательная функция для получения расстояния до ближайшего противника
local function get_closest_enemy_distance(local_player)
    local local_origin = vector(entity.get_prop(local_player, "m_vecOrigin"))
    local closest_distance = 1000

    local players = entity.get_players(true)
    for i=1, #players do
        local player = players[i]
        if entity.is_alive(player) then
            local origin = vector(entity.get_prop(player, "m_vecOrigin"))
            local distance = (local_origin - origin):length()
            if distance < closest_distance then
                closest_distance = distance
            end
        end
    end

    return closest_distance
end

-- Функция для обработки Force Break LC
local function handle_force_break_lc(cmd)
    if not ui.get(menu.aa_builder.main.force_break_lc) then return end

    local state, speed = get_player_state()
    local settings = get_break_settings(state, speed)

    -- Логика Force Break LC
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local current_tick = globals.tickcount()
    local choke_limit = 14
    local break_ticks = 0

    if settings.mode == "Maximum" then
        break_ticks = choke_limit
        cmd.force_choke = true
        cmd.allow_send_packet = current_tick % (choke_limit + 1) == 0
    elseif settings.mode == "Dynamic" then
        break_ticks = math.floor(speed * 0.1)
        break_ticks = math.min(break_ticks, choke_limit)
        cmd.force_choke = true
        cmd.allow_send_packet = current_tick % (break_ticks + 1) == 0
    elseif settings.mode == "Adaptive" then
        local enemies_distance = get_closest_enemy_distance(local_player)
        break_ticks = math.floor(math.min(enemies_distance * 0.1, choke_limit))
        cmd.force_choke = true
        cmd.allow_send_packet = current_tick % (break_ticks + 1) == 0
    elseif settings.mode == "Random" then
        break_ticks = math.random(4, choke_limit)
        cmd.force_choke = true
        cmd.allow_send_packet = current_tick % (break_ticks + 1) == 0
    end

    if not cmd.allow_send_packet then
        local rotation = math.sin(globals.realtime() * 5) * 180
        cmd.forwardmove = cmd.forwardmove * math.cos(math.rad(rotation))
        cmd.sidemove = cmd.sidemove * math.sin(math.rad(rotation))
        
        local pitch = cmd.pitch
        local yaw = cmd.yaw
        
        if settings.mode == "Maximum" then
            cmd.pitch = 89 * (current_tick % 2 == 0 and 1 or -1)
            cmd.yaw = yaw + rotation
        elseif settings.mode == "Dynamic" then
            cmd.pitch = pitch + math.sin(globals.realtime() * 3) * 30
            cmd.yaw = yaw + math.cos(globals.realtime() * 3) * 60
        elseif settings.mode == "Random" then
            cmd.pitch = pitch + math.random(-45, 45)
            cmd.yaw = yaw + math.random(-90, 90)
        end
    end
end

-- Часть 2: Функции для Force Break LC и определения состояния игрока

	
-- Функция выбора режима и силы в зависимости от состояния
local function get_break_settings(state, speed)
    local settings = {
        shooting = {mode = "Maximum", strength = 100},
        air = {mode = "Dynamic", strength = 80},
        duck = {mode = "Adaptive", strength = 90},
        move = {mode = "Random", strength = 70},
        stand = {mode = "Adaptive", strength = 60}
    }
    return settings[state] or settings.stand
end

-- Вспомогательная функция для получения расстояния до ближайшего противника
local function get_closest_enemy_distance(local_player)
    local local_origin = vector(entity.get_prop(local_player, "m_vecOrigin"))
    local closest_distance = 1000
    local players = entity.get_players(true)
    
    for i=1, #players do
        local player = players[i]
        if entity.is_alive(player) then
            local origin = vector(entity.get_prop(player, "m_vecOrigin"))
            local distance = (local_origin - origin):length()
            if distance < closest_distance then
                closest_distance = distance
            end
        end
    end
    return closest_distance
end

local function handle_force_break_lc(cmd)
    if not ui.get(menu.aa_builder.main.force_break_lc) then return end
    
    local state, speed = get_player_state()
    local settings = get_break_settings(state, speed)
    local local_player = entity.get_local_player()
    
    if not local_player or not entity.is_alive(local_player) then return end
    
    local current_tick = globals.tickcount()
    local choke_limit = 14
    local break_ticks = 0

    if settings.mode == "Maximum" then
        break_ticks = choke_limit
        cmd.force_choke = true
        cmd.allow_send_packet = current_tick % (choke_limit + 1) == 0
    elseif settings.mode == "Dynamic" then
        break_ticks = math.floor(speed * 0.1)
        break_ticks = math.min(break_ticks, choke_limit)
        cmd.force_choke = true
        cmd.allow_send_packet = current_tick % (break_ticks + 1) == 0
    elseif settings.mode == "Adaptive" then
        local enemies_distance = get_closest_enemy_distance(local_player)
        break_ticks = math.floor(math.min(enemies_distance * 0.1, choke_limit))
        cmd.force_choke = true
        cmd.allow_send_packet = current_tick % (break_ticks + 1) == 0
    elseif settings.mode == "Random" then
        break_ticks = math.random(4, choke_limit)
        cmd.force_choke = true
        cmd.allow_send_packet = current_tick % (break_ticks + 1) == 0
    end

    if not cmd.allow_send_packet then
        local rotation = math.sin(globals.realtime() * 5) * 180
        cmd.forwardmove = cmd.forwardmove * math.cos(math.rad(rotation))
        cmd.sidemove = cmd.sidemove * math.sin(math.rad(rotation))
        local pitch = cmd.pitch
        local yaw = cmd.yaw

        if settings.mode == "Maximum" then
            cmd.pitch = 89 * (current_tick % 2 == 0 and 1 or -1)
            cmd.yaw = yaw + rotation
        elseif settings.mode == "Dynamic" then
            cmd.pitch = pitch + math.sin(globals.realtime() * 3) * 30
            cmd.yaw = yaw + math.cos(globals.realtime() * 3) * 60
        elseif settings.mode == "Random" then
            cmd.pitch = pitch + math.random(-45, 45)
            cmd.yaw = yaw + math.random(-90, 90)
        end
    end
end


local function handle_safe_head(cmd)
    if not ui.get(menu.aa_builder.main.safe_head) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local local_pos = vector(entity.get_prop(local_player, "m_vecOrigin"))
    local closest_distance = ui.get(menu.aa_builder.main.safe_head_distance)
    local enemies = entity.get_players(true)
    
    for i=1, #enemies do
        local enemy = enemies[i]
        if entity.is_alive(enemy) then
            local enemy_pos = vector(entity.get_prop(enemy, "m_vecOrigin"))
            local distance = (local_pos - enemy_pos):length()
            
            if distance <= closest_distance then
                cmd.yaw = cmd.yaw + 180
                break
            end
        end
    end
end

local animation_offset = 0
local last_update_time = 0

-- Функция для создания градиента текста
local function gradient_text(x, y, r1, g1, b1, r2, g2, b2, a, text, font)
    local length = #text
    local char_x = x
    
    for i = 1, length do
        local fraction = (i - 1) / (length - 1)
        local r = r1 + (r2 - r1) * fraction
        local g = g1 + (g2 - g1) * fraction
        local b = b1 + (b2 - b1) * fraction
        
        renderer.text(
            char_x,
            y,
            r,
            g,
            b,
            a,
            font,
            0,
            text:sub(i, i)
        )
        
        char_x = char_x + renderer.measure_text(font, text:sub(i, i))
    end
end

-- Функция для анимации текста
local function animate_text(text, r1, g1, b1, r2, g2, b2, a)
    local time = globals.realtime() * 2
    local wave = math.sin(time + animation_offset)
    local wave_offset = math.abs(wave)
    
    -- Интерполяция цветов
    local r = r1 + (r2 - r1) * wave_offset
    local g = g1 + (g2 - g1) * wave_offset
    local b = b1 + (b2 - b1) * wave_offset
    
    return r, g, b, a
end

local function get_player_state(local_player)
    if not local_player then return "Global" end

    local flags = entity.get_prop(local_player, "m_fFlags")
    if not flags then return "Global" end

    local vel_x = entity.get_prop(local_player, "m_vecVelocity[0]") or 0
    local vel_y = entity.get_prop(local_player, "m_vecVelocity[1]") or 0
    local velocity = vector(vel_x, vel_y, 0)
    local speed = velocity:length()

    local on_ground = bit.band(flags, 1) ~= 0
    local ducking = bit.band(flags, 4) ~= 0

    -- Определение текущего состояния
    if not on_ground then
        return ducking and "Air-Crouching" or "Air"
    elseif ducking then
        return "Crouching"
    elseif speed < 5 then
        return "Standing"
    elseif speed < 100 then
        return "Slow Motion"
    else
        return "Moving"
    end
end

local function draw_indicators()
    if not ui.get(menu.visuals.indicators) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local screen_size = {client.screen_size()}
    local center_x = screen_size[1] / 2
    local center_y = screen_size[2] / 2 + 40
    local spacing = 15
    local current_y = center_y
    
    -- BlazeWings title
    local title_r, title_g, title_b, title_a = animate_text("BLAZEWINGS", 220, 20, 60, 255, 255, 255, 255)
    local title_width = renderer.measure_text("", "BLAZEWINGS")
    
    gradient_text(
        center_x - title_width/2,
        current_y,
        title_r, title_g, title_b,
        255, 255, 255,
        255,
        "BLAZEWINGS",
        ""
    )
    
    current_y = current_y + spacing
    
    -- Получаем референсы для Double Tap и Hide Shots
    local ref = {
        dt = {ui.reference("RAGE", "Aimbot", "Double tap")},
        hs = {ui.reference("AA", "Other", "On shot anti-aim")}
    }
    
    -- Check if DT and HS are active
    local dt_active = ui.get(ref.dt[1]) and ui.get(ref.dt[2])
    local hs_active = ui.get(ref.hs[1]) and ui.get(ref.hs[2])
    
    -- Display DT indicator
    if dt_active then
        local dt_r, dt_g, dt_b, dt_a = animate_text("DT", 255, 255, 255, 220, 20, 60, 255)
        gradient_text(
            center_x - renderer.measure_text("", "DT")/2,
            current_y,
            dt_r, dt_g, dt_b,
            255, 255, 255,
            255,
            "DT",
            ""
        )
        current_y = current_y + spacing
    end
    
    if hs_active then
        local hs_r, hs_g, hs_b, hs_a = animate_text("HS", 255, 255, 255, 220, 20, 60, 255)
        gradient_text(
            center_x - renderer.measure_text("", "HS")/2,
            current_y,
            hs_r, hs_g, hs_b,
            255, 255, 255,
            255,
            "HS",
            ""
        )
        current_y = current_y + spacing
    end
    
    local player_state = get_player_state(local_player)
    local state_r, state_g, state_b, state_a = animate_text(player_state, 255, 255, 255, 220, 20, 60, 255)
    
    gradient_text(
        center_x - renderer.measure_text("", player_state)/2,
        current_y,
        state_r, state_g, state_b,
        255, 255, 255,
        255,
        player_state,
        ""
    )
    
    animation_offset = animation_offset + globals.frametime() * 0.5
end



local function is_jumping(player)
    local flags = entity.get_prop(player, "m_fFlags")
    return bit.band(flags, 1) == 0
end

local function is_ducking(player)
    local flags = entity.get_prop(player, "m_fFlags")
    return bit.band(flags, 4) == 4
end

local function handle_safe_head(cmd)
    if not ui.get(menu.aa_builder.main.safe_head) then return end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local is_player_jumping = is_jumping(local_player)
    local is_player_ducking = is_ducking(local_player)
    local is_jump_ducking = is_player_jumping and is_player_ducking

    -- Активируем Safe Head только при прыжке или прыжке с приседанием
    if is_player_jumping or is_jump_ducking then
        -- Настраиваем anti-aim для защиты головы
        ui.set(ref.enabled, true)
        ui.set(ref.pitch[1], "Minimal")
        ui.set(ref.yaw_base, "At targets")
        
        -- Настройка в зависимости от типа прыжка
        if is_jump_ducking then
            -- Настройки для прыжка с приседанием
            ui.set(ref.body_yaw[1], "Jitter")
            cmd.yaw = cmd.yaw + 180
        else
            -- Настройки для обычного прыжка
            ui.set(ref.body_yaw[1], "Static")
            cmd.yaw = cmd.yaw + 90
        end
        
        -- Форсируем наклон тела
        entity.set_prop(local_player, "m_flPoseParameter", 1, 11)
        cmd.force_defensive = true
    end
end

local DANGER_DISTANCE = 400 -- 40 метров
local CRITICAL_DISTANCE = 350 -- 35 метров

-- Получаем референсы anti-aim
local ref = {
    enabled = ui.reference("AA", "Anti-aimbot angles", "Enabled"),
    pitch = {ui.reference("AA", "Anti-aimbot angles", "Pitch")},
    yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw base"),
    yaw = {ui.reference("AA", "Anti-aimbot angles", "Yaw")},
    body_yaw = {ui.reference("AA", "Anti-aimbot angles", "Body yaw")}
}

-- Сохраняем последнюю позицию противника для отслеживания движения
local last_enemy_pos = nil
local last_update_time = 0

-- Функция для расчета угла между игроками
local function calc_angle(local_pos, enemy_pos)
    local delta = vector(enemy_pos.x - local_pos.x, enemy_pos.y - local_pos.y, enemy_pos.z - local_pos.z)
    return math.deg(math.atan2(delta.y, delta.x))
end

-- Функция для предсказания позиции противника
local function predict_enemy_position(current_pos, last_pos, time_delta)
    if not last_pos then return current_pos end
    
    local velocity = (current_pos - last_pos) / time_delta
    return current_pos + velocity * 0.2 -- Предсказываем на 0.2 секунды вперед
end

-- Основная функция Anti-Backstab
local function handle_anti_backstab(cmd)
    if not ui.get(menu.aa_builder.main.anti_backstab) then 
        last_enemy_pos = nil
        return 
    end

    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then 
        last_enemy_pos = nil
        return 
    end

    local local_pos = vector(entity.get_prop(local_player, "m_vecOrigin"))
    local enemies = entity.get_players(true)
    local closest_knife_enemy = nil
    local closest_distance = math.huge
    local current_time = globals.curtime()

    -- Поиск ближайшего противника с ножом
    for _, enemy in ipairs(enemies) do
        if entity.is_alive(enemy) then
            local weapon = entity.get_player_weapon(enemy)
            if weapon and entity.get_classname(weapon) == "CKnife" then
                local enemy_pos = vector(entity.get_prop(enemy, "m_vecOrigin"))
                local distance = (local_pos - enemy_pos):length()
                
                if distance <= DANGER_DISTANCE and distance < closest_distance then
                    closest_distance = distance
                    closest_knife_enemy = enemy
                end
            end
        end
    end

    -- Если найден противник с ножом в опасной зоне
    if closest_knife_enemy then
        local enemy_pos = vector(entity.get_prop(closest_knife_enemy, "m_vecOrigin"))
        local time_delta = current_time - last_update_time

        -- Предсказываем позицию противника
        local predicted_pos = predict_enemy_position(enemy_pos, last_enemy_pos, time_delta)
        local target_yaw = calc_angle(local_pos, predicted_pos)

        -- Получаем скорость противника
        local enemy_velocity = vector(entity.get_prop(closest_knife_enemy, "m_vecVelocity"))
        local is_enemy_moving = enemy_velocity:length() > 100

        if closest_distance <= CRITICAL_DISTANCE then
            -- Отключаем anti-aim
            ui.set(ref.enabled, false)
            ui.set(ref.pitch[1], "Minimal") -- Используем "Minimal" вместо "Off"
            ui.set(ref.yaw_base, "Local view")
            
            -- Настраиваем поворот в зависимости от движения противника
            if is_enemy_moving then
                -- Если противник движется, предсказываем его позицию
                cmd.yaw = target_yaw
            else
                -- Если противник стоит, смотрим прямо на него
                cmd.yaw = calc_angle(local_pos, enemy_pos)
            end

            -- Сбрасываем параметры поворота тела
            entity.set_prop(local_player, "m_flPoseParameter", 0, 11)
            
            -- Форсируем обновление анимации
            cmd.force_defensive = true
        end

        -- Обновляем последнюю позицию противника
        last_enemy_pos = enemy_pos
        last_update_time = current_time
    else
        -- Возвращаем стандартные настройки anti-aim
        ui.set(ref.enabled, true)
        last_enemy_pos = nil
    end
end



local bullet_impacts = {}

local function create_star_points(x, y, inner_radius, outer_radius, points)
    local star = {}
    for i = 1, points * 2 do
        local angle = (i - 1) * math.pi / points
        local radius = i % 2 == 0 and outer_radius or inner_radius
        table.insert(star, {
            x = x + math.cos(angle) * radius,
            y = y + math.sin(angle) * radius
        })
    end
    return star
end

local function on_bullet_fire(e)
    if not ui.get(menu.visuals.hit_marker) then return end
    
    local shooter = client.userid_to_entindex(e.userid)
    if shooter == entity.get_local_player() then
        local impact = {
            x = e.x,
            y = e.y,
            z = e.z,
            time = globals.realtime(),
            rotation = 0,
            inner_radius = 3,
            outer_radius = 8
        }
        table.insert(bullet_impacts, impact)
    end
end

local function draw_impacts()
    if not ui.get(menu.visuals.hit_marker) then return end
    
    local current_time = globals.realtime()
    
    for i = #bullet_impacts, 1, -1 do
        local impact = bullet_impacts[i]
        local age = current_time - impact.time
        
        if age > 2.0 then
            table.remove(bullet_impacts, i)
        else
            local screen_x, screen_y = renderer.world_to_screen(impact.x, impact.y, impact.z)
            
            if screen_x and screen_y then
                -- Dynamic sizing
                local size_multiplier = 1 + (age * 2)
                local inner = impact.inner_radius * size_multiplier
                local outer = impact.outer_radius * size_multiplier
                
                -- Rotation animation
                impact.rotation = impact.rotation + globals.frametime() * 90
                
                -- Color transition with sparkle effect
                local base_transition = math.abs(math.sin(current_time * 2))
                local sparkle = math.abs(math.sin(current_time * 8 + age * 5)) * 0.3
                local transition = math.min(1, base_transition + sparkle)
                
                local r = 220 + (255 - 220) * transition
                local g = 20 + (255 - 20) * transition
                local b = 60 + (255 - 60) * transition
                local alpha = 255 * (1 - age/2)
                
                -- Create and draw star
                local points = create_star_points(screen_x, screen_y, inner, outer, 5)
                for j = 1, #points do
                    local next_j = (j % #points) + 1
                    local p1 = points[j]
                    local p2 = points[next_j]
                    
                    -- Rotate points
                    local rot = math.rad(impact.rotation)
                    local rx1 = screen_x + (p1.x - screen_x) * math.cos(rot) - (p1.y - screen_y) * math.sin(rot)
                    local ry1 = screen_y + (p1.x - screen_x) * math.sin(rot) + (p1.y - screen_y) * math.cos(rot)
                    local rx2 = screen_x + (p2.x - screen_x) * math.cos(rot) - (p2.y - screen_y) * math.sin(rot)
                    local ry2 = screen_y + (p2.x - screen_x) * math.sin(rot) + (p2.y - screen_y) * math.cos(rot)
                    
                    -- Draw star lines
                    renderer.line(rx1, ry1, rx2, ry2, r, g, b, alpha)
                    
                    -- Draw glow points at vertices
                    renderer.circle(rx1, ry1, r, g, b, alpha * 0.5, 3, 0, 1)
                end
            end
        end
    end
end


-- Часть 3: Функции для визуальных элементов и обработки меню

local function draw_watermark()
    screen_width, screen_height = client.screen_size()
    local text = "BLAZEWINGS"
    local font = ""
    local letters = {}
    local time = globals.realtime()

    for i = 1, #text do
        local letter = text:sub(i, i)
        if letter == " " then
            letters[i] = {
                letter = letter,
                r = 220,
                g = 20,
                b = 60,
                offset_y = 0
            }
        else
            local transition = math.abs(math.sin(time + i * 0.2))
            local r = 220
            local g = 20
            local b = 60
            letters[i] = {
                letter = letter,
                r = r,
                g = g + (255 - g) * transition,
                b = b + (255 - b) * transition,
                offset_y = 0,
                alpha = 255
            }
        end
    end

    local measure_w, measure_h = renderer.measure_text(font, text)
    local x = screen_width / 2 - measure_w / 2
    local y = screen_height - 15
    local current_x = x

    for i, letter_data in ipairs(letters) do
        local letter_w = renderer.measure_text(font, letter_data.letter)
        renderer.text(
            current_x,
            y + letter_data.offset_y,
            letter_data.r,
            letter_data.g,
            letter_data.b,
            letter_data.alpha,
            font,
            0,
            letter_data.letter
        )
        current_x = current_x + letter_w + 3
    end
end

local function animate_text()
    local realtime = globals.realtime() * 2
    local text = "BlazeWings"
    local result = ""
    
    for i = 1, #text do
        local char = text:sub(i, i)
        local factor = math.sin(realtime + i * 0.5)
        local color = factor > 0 and COLORS.RED or COLORS.PINK
        result = result .. color .. char
    end
    
    return result
end

local function set_menu_item_visible(item, visible)
    if type(item) == "userdata" then
        ui.set_visible(item, visible)
    end
end

local function handle_menu()
    local current_tab = ui.get(menu.tab)
    local current_category = ui.get(menu.aa_builder.category)
    local enable_condition = ui.get(menu.aa_builder.antiaim.enable_condition)
    local defensive_enabled = ui.get(menu.aa_builder.defensive.enabled)
    
    -- Скрываем все элементы меню
    local function hide_all()
        -- Social
        ui.set_visible(menu.social.community, false)
        ui.set_visible(menu.social.discord_copy, false)
        ui.set_visible(menu.social.build_version, false)

        -- AA Builder
        ui.set_visible(menu.aa_builder.category, false)
        
        -- Main
        ui.set_visible(menu.aa_builder.main.force_break_lc, false)
        ui.set_visible(menu.aa_builder.main.safe_head, false)
        ui.set_visible(menu.aa_builder.main.safe_head_distance, false)
        ui.set_visible(menu.aa_builder.main.anti_backstab, false)

        -- Anti-aim
        ui.set_visible(menu.aa_builder.antiaim.state, false)
        ui.set_visible(menu.aa_builder.antiaim.enable_condition, false)
        ui.set_visible(menu.aa_builder.antiaim.pitch, false)
        ui.set_visible(menu.aa_builder.antiaim.pitch_custom, false)
        ui.set_visible(menu.aa_builder.antiaim.yaw_base, false)
        ui.set_visible(menu.aa_builder.antiaim.yaw, false)
        ui.set_visible(menu.aa_builder.antiaim.yaw_static, false)
        ui.set_visible(menu.aa_builder.antiaim.yaw_jitter, false)
        ui.set_visible(menu.aa_builder.antiaim.yaw_jitter_speed, false)
        ui.set_visible(menu.aa_builder.antiaim.yaw_lr.left, false)
        ui.set_visible(menu.aa_builder.antiaim.yaw_lr.right, false)
        ui.set_visible(menu.aa_builder.antiaim.body_yaw, false)
        ui.set_visible(menu.aa_builder.antiaim.body_yaw_static, false)
        ui.set_visible(menu.aa_builder.antiaim.body_yaw_jitter, false)

        -- Defensive
        ui.set_visible(menu.aa_builder.defensive.enabled, false)
        ui.set_visible(menu.aa_builder.defensive.state, false)
        ui.set_visible(menu.aa_builder.defensive.pitch, false)
        ui.set_visible(menu.aa_builder.defensive.yaw, false)
        ui.set_visible(menu.aa_builder.defensive.yaw_jitter, false)
        ui.set_visible(menu.aa_builder.defensive.yaw_jitter_3way, false)
        ui.set_visible(menu.aa_builder.defensive.yaw_jitter_5way, false)

        -- Visuals
        ui.set_visible(menu.visuals.indicators, false)
        ui.set_visible(menu.visuals.indicators_color, false)
        ui.set_visible(menu.visuals.arrows, false)
        ui.set_visible(menu.visuals.arrows_color, false)
        ui.set_visible(menu.visuals.hit_marker, false)
        ui.set_visible(menu.visuals.hit_marker_color, false)

        -- Misc
        ui.set_visible(menu.misc.thirdperson, false)
        ui.set_visible(menu.misc.thirdperson_distance, false)
        ui.set_visible(menu.misc.aspect_ratio, false)
        ui.set_visible(menu.misc.aspect_ratio_value, false)
        ui.set_visible(menu.misc.hit_logs, false)
        ui.set_visible(menu.misc.animation_breaker, false)
    end

    hide_all()

    if current_tab == "SOCIAL" then
        ui.set_visible(menu.social.community, true)
        ui.set_visible(menu.social.discord_copy, true)
        ui.set_visible(menu.social.build_version, true)
    
    elseif current_tab == "AA-BUILDER" then
        ui.set_visible(menu.aa_builder.category, true)

        if current_category == "Main Category" then
            ui.set_visible(menu.aa_builder.main.force_break_lc, true)
            ui.set_visible(menu.aa_builder.main.safe_head, true)
            ui.set_visible(menu.aa_builder.main.safe_head_distance, ui.get(menu.aa_builder.main.safe_head))
            ui.set_visible(menu.aa_builder.main.anti_backstab, true)

        elseif current_category == "Anti-Aim Category" then
            ui.set_visible(menu.aa_builder.antiaim.enable_condition, true)
            
            if enable_condition then
                ui.set_visible(menu.aa_builder.antiaim.state, true)
                ui.set_visible(menu.aa_builder.antiaim.pitch, true)
                
                local pitch_mode = ui.get(menu.aa_builder.antiaim.pitch)
                ui.set_visible(menu.aa_builder.antiaim.pitch_custom, pitch_mode == "Custom")

                ui.set_visible(menu.aa_builder.antiaim.yaw_base, true)
                ui.set_visible(menu.aa_builder.antiaim.yaw, true)

                local yaw_mode = ui.get(menu.aa_builder.antiaim.yaw)
                ui.set_visible(menu.aa_builder.antiaim.yaw_static, yaw_mode == "Static")
                ui.set_visible(menu.aa_builder.antiaim.yaw_jitter, yaw_mode == "Jitter")
                ui.set_visible(menu.aa_builder.antiaim.yaw_jitter_speed, yaw_mode == "Jitter")
                
                if yaw_mode == "L & R" then
                    ui.set_visible(menu.aa_builder.antiaim.yaw_lr.left, true)
                    ui.set_visible(menu.aa_builder.antiaim.yaw_lr.right, true)
                end

                ui.set_visible(menu.aa_builder.antiaim.body_yaw, true)
                local body_yaw_mode = ui.get(menu.aa_builder.antiaim.body_yaw)
                ui.set_visible(menu.aa_builder.antiaim.body_yaw_static, body_yaw_mode == "Static")
                ui.set_visible(menu.aa_builder.antiaim.body_yaw_jitter, body_yaw_mode == "Jitter")
            end

        elseif current_category == "Defensive Category" then
            ui.set_visible(menu.aa_builder.defensive.enabled, true)
            
            if defensive_enabled then
                ui.set_visible(menu.aa_builder.defensive.state, true)
                ui.set_visible(menu.aa_builder.defensive.pitch, true)
                ui.set_visible(menu.aa_builder.defensive.yaw, true)
                ui.set_visible(menu.aa_builder.defensive.yaw_jitter, true)
                
                local jitter_mode = ui.get(menu.aa_builder.defensive.yaw_jitter)
                ui.set_visible(menu.aa_builder.defensive.yaw_jitter_3way, jitter_mode == "3-way")
                ui.set_visible(menu.aa_builder.defensive.yaw_jitter_5way, jitter_mode == "5-way")
            end
        end

    elseif current_tab == "VISUALS" then
        ui.set_visible(menu.visuals.indicators, true)
        ui.set_visible(menu.visuals.indicators_color, true)
        ui.set_visible(menu.visuals.arrows, true)
        ui.set_visible(menu.visuals.arrows_color, true)
        ui.set_visible(menu.visuals.hit_marker, true)
        ui.set_visible(menu.visuals.hit_marker_color, true)

    elseif current_tab == "MISC" then
        ui.set_visible(menu.misc.thirdperson, true)
        ui.set_visible(menu.misc.thirdperson_distance, true)
        ui.set_visible(menu.misc.aspect_ratio, true)
        ui.set_visible(menu.misc.aspect_ratio_value, true)
        ui.set_visible(menu.misc.hit_logs, true)
        ui.set_visible(menu.misc.animation_breaker, true)
    end
end

ui.set(menu.aa_builder.defensive.enabled, false)








	


local function handle_thirdperson()
    if ui.get(menu.misc.thirdperson) then
        local distance = ui.get(menu.misc.thirdperson_distance)
        client.set_cvar("c_mindistance", distance)
        client.set_cvar("c_maxdistance", distance)
    else
        client.set_cvar("c_mindistance", 30)
        client.set_cvar("c_maxdistance", 30)
    end
end


local function set_aspect_ratio(value)
    if not ui.get(menu.misc.aspect_ratio) then
        client.set_cvar("r_aspectratio", 0)
        return
    end
    local aspect = value * 0.01
    aspect = 2 - aspect
    local screen_width, screen_height = client.screen_size()
    local aspectratio_value = (screen_width * aspect) / screen_height
    if aspect == 1 then aspectratio_value = 0 end
    client.set_cvar("r_aspectratio", tonumber(aspectratio_value))
end

local function handle_fast_ladder(cmd)
    if not ui.get(menu.misc.fast_ladder) then return end
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    if entity.get_prop(local_player, "m_MoveType") ~= 9 then return end
    if cmd.forwardmove > 0 then
        cmd.pitch = 89
        cmd.in_moveright = 1
        cmd.in_moveleft = 0
        cmd.in_forward = 0
        cmd.in_back = 1
    end
end



local function handle_animation_breaker()
    if not ui.get(menu.misc.animation_breaker) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    -- Auto preset logic
    entity.set_prop(local_player, "m_flPoseParameter", math.random(0, 10)/10, 3)
    entity.set_prop(local_player, "m_flPoseParameter", math.random(0, 10)/10, 7)
    entity.set_prop(local_player, "m_flPoseParameter", math.random(0, 10)/10, 6)
end





local function draw_arrows()
    if not ui.get(menu.visuals.arrows) then return end
    
    local screen_size = {client.screen_size()}
    local center_x = screen_size[1] / 2
    local center_y = screen_size[2] / 2
    
    -- Get arrow color
    local r, g, b, a = ui.get(menu.visuals.arrows_color)
    
    -- Draw arrows
    local arrow_size = 20
    local margin = 40
    
    -- Left arrow
    renderer.triangle(
        center_x - margin - arrow_size, center_y,
        center_x - margin, center_y - arrow_size/2,
        center_x - margin, center_y + arrow_size/2,
        r, g, b, a
    )
    
    -- Right arrow
    renderer.triangle(
        center_x + margin + arrow_size, center_y,
        center_x + margin, center_y - arrow_size/2,
        center_x + margin, center_y + arrow_size/2,
        r, g, b, a
    )
end





local function on_player_hurt(e)
    if not ui.get(menu.misc.hit_logs) then return end
    
    local attacker = client.userid_to_entindex(e.attacker)
    local victim = client.userid_to_entindex(e.userid)
    
    if attacker == entity.get_local_player() then
        local hitgroup_names = {
            [0] = "generic",
            [1] = "head",
            [2] = "chest",
            [3] = "stomach",
            [4] = "left arm",
            [5] = "right arm",
            [6] = "left leg",
            [7] = "right leg",
            [8] = "neck"
        }
        
        local new_hit = {
            damage = e.dmg_health,
            hitgroup = hitgroup_names[e.hitgroup] or "generic",
            backtrack_ticks = 0,
            time = globals.realtime(),
            alpha = 0,
            y_offset = 0,
            type = "hit", -- добавляем тип события
            spread = entity.get_prop(victim, "m_flPoseParameter", 11) or 0 -- spread prediction
        }
        
        table.insert(hit_logs, 1, new_hit)
        if #hit_logs > 5 then
            table.remove(hit_logs)
        end
    end
end

local function on_aim_miss(e)
    if not ui.get(menu.misc.hit_logs) then return end
    
    local new_miss = {
        damage = 0,
        hitgroup = e.aim_hitgroup and hitgroup_names[e.aim_hitgroup] or "unknown",
        backtrack_ticks = 0,
        time = globals.realtime(),
        alpha = 0,
        y_offset = 0,
        type = "miss", -- отмечаем как промах
        reason = e.reason or "spread", -- причина промаха
        spread = e.aim_hitchance or 0
    }
    
    table.insert(hit_logs, 1, new_miss)
    if #hit_logs > 5 then
        table.remove(hit_logs)
    end
end

local function on_paint()
    if not ui.get(menu.misc.hit_logs) then return end
    
    local time = globals.realtime()
    local screen_center_x = screen_width / 2
    local screen_base_y = screen_height / 2 + 100
    
    local r, g, b, a = ui.get(menu.misc.hitlogs_color)
    
    for i, log in ipairs(hit_logs) do
        log.alpha = math.min(255, log.alpha + 15)
        log.y_offset = log.y_offset * 0.95
        
        local age = time - log.time
        local fade_alpha = math.max(0, math.min(255, 255 * (1 - (age / 3))))
        local final_alpha = math.min(log.alpha, fade_alpha)
        
        if final_alpha > 0 then
            local text
            if log.type == "hit" then
                text = string.format(
                    "HIT %s for %d damage (spread: %.1f%%)",
                    log.hitgroup,
                    log.damage,
                    log.spread * 100
                )
            else
                text = string.format(
                    "MISSED %s (reason: %s, spread: %.1f%%)",
                    log.hitgroup,
                    log.reason,
                    log.spread
                )
            end
            
            local text_size = {renderer.measure_text("", text)}
            local y_pos = screen_base_y + (i * 20) + log.y_offset
            
            -- Цвет в зависимости от типа события
            local text_r, text_g, text_b
            if log.type == "hit" then
                text_r, text_g, text_b = 0, 255, 0 -- зеленый для попаданий
            else
                text_r, text_g, text_b = 255, 0, 0 -- красный для промахов
            end
            
            -- Тень
            renderer.text(
                screen_center_x - text_size[1] / 2 + 1,
                y_pos + 1,
                0, 0, 0,
                final_alpha * 0.5,
                "",
                0,
                text
            )
            
            -- Основной текст
            renderer.text(
                screen_center_x - text_size[1] / 2,
                y_pos,
                text_r, text_g, text_b,
                final_alpha,
                "",
                0,
                text
            )
        end
    end
end

local function on_paint()
     if not ui.get(menu.misc.hit_logs) then return end
    
    local time = globals.realtime()
    local screen_center_x = screen_width / 2
    local screen_base_y = screen_height / 2 + 100
    
    for i, hit in ipairs(hit_logs) do
        hit.alpha = math.min(255, hit.alpha + 15)
        hit.y_offset = hit.y_offset * 0.95
        
        local age = time - hit.time
        local fade_alpha = math.max(0, math.min(255, 255 * (1 - (age / 3))))
        local final_alpha = math.min(hit.alpha, fade_alpha)
        
        if final_alpha > 0 then
            local text = string.format(
                "DMG: %d | %s | ticks: %d",
                hit.damage,
                hit.hitgroup,
                hit.backtrack_ticks
            )
            local text_size = {renderer.measure_text("", text)}
            local y_pos = screen_base_y + (i * 20) + hit.y_offset
            
            local transition = math.abs(math.sin(time + i * 0.2))
            local r = 220 + (255 - 220) * (1 - transition)
            local g = 20 + (255 - 20) * (1 - transition)
            local b = 60 + (255 - 60) * (1 - transition)
            
            renderer.text(
                screen_center_x - text_size[1] / 2 + 1,
                y_pos + 1,
                0, 0, 0,
                final_alpha * 0.5,
                "",
                0,
                text
            )
            
            renderer.text(
                screen_center_x - text_size[1] / 2,
                y_pos,
                r, g, b,
                final_alpha,
                "",
                0,
                text
            )
        end
    end
end






local ref = {
    enabled = ui.reference("AA", "Anti-aimbot angles", "Enabled"),
    pitch = {ui.reference("AA", "Anti-aimbot angles", "Pitch")},
    yaw = {ui.reference("AA", "Anti-aimbot angles", "Yaw")},
    yaw_jitter = {ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")},
    body_yaw = {ui.reference("AA", "Anti-aimbot angles", "Body yaw")},
    freestanding_body_yaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw"),
    edge_yaw = ui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
    freestanding = {ui.reference("AA", "Anti-aimbot angles", "Freestanding")},
    roll = ui.reference("AA", "Anti-aimbot angles", "Roll"),
    doubletap = {ui.reference("RAGE", "Aimbot", "Double tap")}
}


local configured_states = {
    ["Global"] = false,
    ["Standing"] = false,
    ["Moving"] = false,
    ["Slow Motion"] = false,
    ["Crouching"] = false,
    ["Air"] = false,
    ["Air-Crouching"] = false
}

local defensive_states = {
    ["Global"] = {},
    ["Standing"] = {},
    ["Moving"] = {},
    ["Slow Motion"] = {},
    ["Crouching"] = {},
    ["Air"] = {},
    ["Air-Crouching"] = {}
}

-- Инициализация состояний с настройками по умолчанию
for state, _ in pairs(defensive_states) do
    defensive_states[state] = {
        pitch = "Off",
        yaw = "Off",
        yaw_jitter = "Off",
        yaw_jitter_3way = 0,
        yaw_jitter_5way = 0
    }
end

local function get_current_state()
    local local_player = entity.get_local_player()
    
    if not local_player or not entity.is_alive(local_player) then
        return "none"
    end

    local flags = entity.get_prop(local_player, "m_fFlags")
    local velocity = vector(entity.get_prop(local_player, "m_vecVelocity"))
    local speed = velocity:length2d()
    local on_ground = bit.band(flags, 1) == 1
    local duck_amount = entity.get_prop(local_player, "m_flDuckAmount")

    -- В воздухе
    if not on_ground then
        if duck_amount > 0.8 then
            return "Air-Crouching"
        else
            return "Air"
        end
    end

    -- Присед
    if duck_amount > 0.8 then
        return "Crouching"
    end

    -- Медленное передвижение
    if speed > 1.0 and speed < 85 then
        return "Slow Motion"
    end

    -- Движение
    if speed > 1.0 then
        return "Moving"
    end

    -- Стоим на месте
    return "Standing"
end

local function get_state_settings(state)
    -- Проверяем настройки для текущего состояния
    if defensive_states[state] and configured_states[state] then
        return defensive_states[state]
    end

    -- Проверяем глобальные настройки
    if defensive_states["Global"] and configured_states["Global"] then
        return defensive_states["Global"]
    end

    -- Возвращаем текущие настройки UI если ничего не найдено
    return {
        pitch = ui.get(menu.aa_builder.defensive.pitch),
        yaw = ui.get(menu.aa_builder.defensive.yaw),
        yaw_jitter = ui.get(menu.aa_builder.defensive.yaw_jitter),
        yaw_jitter_3way = ui.get(menu.aa_builder.defensive.yaw_jitter_3way),
        yaw_jitter_5way = ui.get(menu.aa_builder.defensive.yaw_jitter_5way)
    }
end

local function apply_defensive_aa(cmd)
    if not ui.get(menu.aa_builder.defensive.enabled) then
        return
    end

    local current_state = get_current_state()
    if current_state == "none" then
        return
    end

    -- Проверяем, настроено ли текущее состояние или глобальное
    if not (configured_states[current_state] or configured_states["Global"]) then
        return
    end

    -- Получаем настройки для текущего состояния
    local settings = get_state_settings(current_state)

    -- Применяем pitch
    if settings.pitch ~= "Off" then
        if settings.pitch == "Up" then
            cmd.pitch = -89
        elseif settings.pitch == "Down" then
            cmd.pitch = 89
        elseif settings.pitch == "Random" then
            cmd.pitch = math.random(-89, 89)
        elseif settings.pitch == "Default" then
            cmd.pitch = 0
        end
    end

    -- Базовый yaw
    local base_yaw = cmd.yaw or 0

    -- Применяем yaw
    if settings.yaw ~= "Off" then
        if settings.yaw == "180" then
            base_yaw = 180
        elseif settings.yaw == "Spin" then
            base_yaw = (globals.tickcount() * 10) % 360
        elseif settings.yaw == "Static" then
            base_yaw = 90
        elseif settings.yaw == "180 Z" then
            base_yaw = (globals.tickcount() % 2 == 0) and 180 or -180
        elseif settings.yaw == "Crosshair" then
            local view_angles = vector(client.camera_angles())
            base_yaw = view_angles.y + 180
        end
    end

    -- Применяем jitter
    if settings.yaw_jitter ~= "Off" then
        local jitter_value = 0
        
        if settings.yaw_jitter == "Offset" then
            jitter_value = (globals.tickcount() % 2 == 0) and 30 or -30
        elseif settings.yaw_jitter == "Center" then
            jitter_value = (globals.tickcount() % 2 == 0) and 90 or -90
        elseif settings.yaw_jitter == "Random" then
            jitter_value = math.random(-180, 180)
        elseif settings.yaw_jitter == "Skitter" then
            local tick = globals.tickcount() % 4
            if tick == 0 then
                jitter_value = 0
            elseif tick == 1 then
                jitter_value = 90
            elseif tick == 2 then
                jitter_value = 180
            else
                jitter_value = -90
            end
        elseif settings.yaw_jitter == "3-way" then
            local tick = globals.tickcount() % 3
            local range = settings.yaw_jitter_3way
            jitter_value = -range + (tick * (range / 2))
        elseif settings.yaw_jitter == "5-way" then
            local tick = globals.tickcount() % 5
            local range = settings.yaw_jitter_5way
            jitter_value = -range + (tick * (range / 4))
        end

        base_yaw = base_yaw + jitter_value
    end

    cmd.yaw = base_yaw
end


local function save_state_settings(state)
    if state == nil then
        state = ui.get(menu.aa_builder.defensive.state)
    end

    if ui.get(menu.aa_builder.defensive.pitch) ~= "Off" or
       ui.get(menu.aa_builder.defensive.yaw) ~= "Off" or
       ui.get(menu.aa_builder.defensive.yaw_jitter) ~= "Off" then
        defensive_states[state] = {
            pitch = ui.get(menu.aa_builder.defensive.pitch),
            yaw = ui.get(menu.aa_builder.defensive.yaw),
            yaw_jitter = ui.get(menu.aa_builder.defensive.yaw_jitter),
            yaw_jitter_3way = ui.get(menu.aa_builder.defensive.yaw_jitter_3way),
            yaw_jitter_5way = ui.get(menu.aa_builder.defensive.yaw_jitter_5way)
        }
        configured_states[state] = true
    end
end

local function load_state_settings(state)
    local state_settings = defensive_states[state]
    if state_settings then
        ui.set(menu.aa_builder.defensive.pitch, state_settings.pitch)
        ui.set(menu.aa_builder.defensive.yaw, state_settings.yaw)
        ui.set(menu.aa_builder.defensive.yaw_jitter, state_settings.yaw_jitter)
        ui.set(menu.aa_builder.defensive.yaw_jitter_3way, state_settings.yaw_jitter_3way)
        ui.set(menu.aa_builder.defensive.yaw_jitter_5way, state_settings.yaw_jitter_5way)
    end
end

-- Обработчики событий
local function on_state_change()
    local current_state = ui.get(menu.aa_builder.defensive.state)
    load_state_settings(current_state)
end

local function on_setting_change()
    save_state_settings()
end



local state_settings = {
    ["Global"] = {},
    ["Standing"] = {},
    ["Moving"] = {},
    ["Slow Motion"] = {},
    ["Crouching"] = {},
    ["Air"] = {},
    ["Air-Crouching"] = {},
    ["FakeLag"] = {}
}

-- Улучшенная функция определения состояния
local function get_player_state(local_player)
    if not local_player then return "Global" end

    local flags = entity.get_prop(local_player, "m_fFlags")
    if not flags then return "Global" end

    local vel_x = entity.get_prop(local_player, "m_vecVelocity[0]") or 0
    local vel_y = entity.get_prop(local_player, "m_vecVelocity[1]") or 0
    local velocity = vector(vel_x, vel_y, 0)
    local speed = velocity:length()

    local on_ground = bit.band(flags, 1) ~= 0
    local ducking = bit.band(flags, 4) ~= 0

    -- Определение текущего состояния
    if not on_ground then
        return ducking and "Air-Crouching" or "Air"
    elseif ducking then
        return "Crouching"
    elseif speed < 5 then
        return "Standing"
    elseif speed < 100 then
        return "Slow Motion"
    else
        return "Moving"
    end
end

local function apply_antiaim(cmd)
    local local_player = entity.get_local_player()
    if not local_player then return end
    if not ui.get(menu.aa_builder.antiaim.enable_condition) then return end

    local current_state = get_player_state(local_player)
    local selected_state = ui.get(menu.aa_builder.antiaim.state)

    if selected_state == "Global" or selected_state == current_state then
        -- Применяем pitch
        local pitch_mode = ui.get(menu.aa_builder.antiaim.pitch)
        if pitch_mode ~= "Off" then
            if pitch_mode == "Up" then
                cmd.pitch = -89 + math.random(-1, 1)
                cmd.yaw = cmd.yaw + 180
            elseif pitch_mode == "Down" then
                cmd.pitch = 89 + math.random(-1, 1)
                cmd.yaw = cmd.yaw + 180
            elseif pitch_mode == "Random" then
                local base_pitch = math.random(-89, 89)
                local micro_jitter = math.sin(globals.curtime() * 4) * 2
                cmd.pitch = base_pitch + micro_jitter
            elseif pitch_mode == "Custom" then
                local custom_pitch = ui.get(menu.aa_builder.antiaim.pitch_custom)
                local micro_movement = math.sin(globals.curtime() * 3) * 1.5
                cmd.pitch = custom_pitch + micro_movement
            end
        end

        -- Применяем yaw base
        local yaw_base = ui.get(menu.aa_builder.antiaim.yaw_base)
        local base_yaw = cmd.yaw

        if yaw_base == "At targets" then
            local closest_enemy = nil
            local min_fov = math.huge
            local view_angles = vector(client.camera_angles())
            local local_pos = vector(entity.get_origin(local_player))
            
            local enemies = entity.get_players(true)
            for i=1, #enemies do
                local enemy = enemies[i]
                if enemy ~= nil then
                    local enemy_pos = vector(entity.get_origin(enemy))
                    local to_enemy = enemy_pos - local_pos
                    
                    local enemy_yaw = math.deg(math.atan2(to_enemy.y, to_enemy.x))
                    local fov = math.abs(normalize_yaw(enemy_yaw - view_angles.y))
                    
                    if fov < min_fov then
                        min_fov = fov
                        closest_enemy = enemy
                    end
                end
            end
            
            if closest_enemy then
                local enemy_pos = vector(entity.get_origin(closest_enemy))
                local to_enemy = enemy_pos - local_pos
                local yaw = math.deg(math.atan2(to_enemy.y, to_enemy.x))
                base_yaw = normalize_yaw(yaw + 180)
            end
        end

        -- Применяем yaw
        local yaw_mode = ui.get(menu.aa_builder.antiaim.yaw)
        if yaw_mode ~= "Off" then
            if yaw_mode == "180" then
                local micro_move = math.sin(globals.curtime() * 2) * 5
                cmd.yaw = base_yaw + 180 + micro_move
            elseif yaw_mode == "Spin" then
                local spin_speed = 5 + math.sin(globals.curtime() * 1.5) * 2
                cmd.yaw = base_yaw + (globals.tickcount() * spin_speed) % 360
            elseif yaw_mode == "L & R" then
                local left_value = ui.get(menu.aa_builder.antiaim.yaw_lr.left)
                local right_value = ui.get(menu.aa_builder.antiaim.yaw_lr.right)
                local should_switch = globals.tickcount() % 2 == 0
                local micro_offset = math.sin(globals.curtime() * 3) * 3
                cmd.yaw = base_yaw + (should_switch and left_value or right_value) + micro_offset
            elseif yaw_mode == "Jitter" then
                local jitter_value = ui.get(menu.aa_builder.antiaim.yaw_jitter)
                local jitter_speed = ui.get(menu.aa_builder.antiaim.yaw_jitter_speed)
                local time_based_switch = math.floor(globals.curtime() * jitter_speed) % 2 == 0
                local micro_movement = math.sin(globals.curtime() * 2) * 3
                cmd.yaw = base_yaw + (time_based_switch and jitter_value or -jitter_value) + micro_movement
            end
        end

        -- Применяем body yaw
        local body_yaw_mode = ui.get(menu.aa_builder.antiaim.body_yaw)
        if body_yaw_mode ~= "Off" then
            if body_yaw_mode == "Opposite" then
                local micro_opposite = math.sin(globals.curtime() * 2.5) * 4
                cmd.yaw = cmd.yaw + 180 + micro_opposite
            elseif body_yaw_mode == "Jitter" then
                local jitter_value = ui.get(menu.aa_builder.antiaim.body_yaw_jitter)
                local dynamic_jitter = jitter_value * (0.8 + math.sin(globals.curtime() * 3) * 0.2)
                cmd.yaw = cmd.yaw + (globals.tickcount() % 2 == 0 and dynamic_jitter or -dynamic_jitter)
            elseif body_yaw_mode == "Static" then
                local static_value = ui.get(menu.aa_builder.antiaim.body_yaw_static)
                local micro_static = math.sin(globals.curtime() * 2) * 2
                cmd.yaw = cmd.yaw + static_value + micro_static
            end
        end
    end
end











local function setup_callbacks()
    local elements = {
        menu.aa_builder.defensive.pitch,
        menu.aa_builder.defensive.yaw,
        menu.aa_builder.defensive.yaw_jitter,
        menu.aa_builder.defensive.yaw_jitter_3way,
        menu.aa_builder.defensive.yaw_jitter_5way
    }

    for _, element in ipairs(elements) do
        ui.set_callback(element, function()
            local current_state = ui.get(menu.aa_builder.defensive.state)
            save_state_settings(current_state)
        end)
    end
end


-- Обработчик изменения состояния
local function on_state_change()
    local current_state = ui.get(menu.aa_builder.defensive.state)
    load_state_settings(current_state)
end

-- Обработчик создания движения
local function on_create_move(cmd)
    if not ui.get(menu.aa_builder.defensive.enabled) then return end
    apply_defensive_aa()
end


local function register_state_callbacks()
    local items = {
        menu.aa_builder.defensive.pitch,
        menu.aa_builder.defensive.yaw,
        menu.aa_builder.defensive.yaw_jitter,
        menu.aa_builder.defensive.yaw_jitter_3way,
        menu.aa_builder.defensive.yaw_jitter_5way
    }
    
    for _, item in ipairs(items) do
        ui.set_callback(item, function()
            local current_state = ui.get(menu.aa_builder.defensive.state)
            save_state_settings(current_state)
        end)
    end
end








-- Регистрация всех колбэков
ui.set_callback(menu.tab, handle_menu)
ui.set_callback(menu.aa_builder.category, handle_menu)
ui.set_callback(menu.aa_builder.defensive.state, on_state_change)
ui.set_callback(menu.aa_builder.main.force_break_lc, handle_menu)
ui.set_callback(menu.aa_builder.defensive.state, on_state_change)
ui.set_callback(menu.aa_builder.defensive.yaw_jitter, handle_menu)


ui.set_callback(menu.misc.thirdperson, function()
    handle_menu()
    handle_thirdperson()
end)

ui.set_callback(menu.misc.thirdperson_distance, handle_thirdperson)

ui.set_callback(menu.misc.aspect_ratio, function()
    handle_menu()
    set_aspect_ratio(ui.get(menu.misc.aspect_ratio_value))
end)

ui.set_callback(menu.misc.aspect_ratio_value, function()
    if ui.get(menu.misc.aspect_ratio) then
        set_aspect_ratio(ui.get(menu.misc.aspect_ratio_value))
    end
end)

client.set_event_callback("paint", draw_watermark)
client.set_event_callback("paint_ui", draw_watermark)
client.set_event_callback("create_move", on_create_move)
client.set_event_callback('pre_render', handle_animation_breaker)
client.set_event_callback("create_move", handle_fast_ladder)
client.set_event_callback('player_hurt', on_player_hurt)
client.set_event_callback("setup_command", apply_antiaim)
client.set_event_callback("setup_command", handle_force_break_lc)
client.set_event_callback('aim_miss', on_aim_miss)
client.set_event_callback("paint_ui", handle_menu)
client.set_event_callback('paint', on_paint)
client.set_event_callback('setup_command', handle_safe_head)
client.set_event_callback('paint', draw_indicators)
client.set_event_callback("bullet_impact", on_bullet_fire)
client.set_event_callback("paint", draw_impacts)
client.set_event_callback("paint", draw_arrows)
client.set_event_callback("setup_command", apply_defensive_aa)

handle_menu()
handle_thirdperson()

client.set_event_callback("shutdown", function()
    client.set_cvar("r_aspectratio", 0)
    client.set_cvar("cam_collision", 1)
    client.set_cvar("c_mindistance", 30)
    client.set_cvar("c_maxdistance", 30)
end)

client.set_event_callback("setup_command", function(cmd)
    handle_force_break_lc(cmd)
    handle_safe_head(cmd)
    handle_anti_backstab(cmd)
end)

register_state_callbacks()

client.set_event_callback("setup_command", function(cmd)
    if ui.get(menu.aa_builder.defensive.enabled) then
        apply_defensive_aa(cmd)
    end
end)

client.set_event_callback("setup_command", function(cmd)
    local local_player = entity.get_local_player()
    if not local_player then return end
    
    local current_state = get_player_state(local_player)
    -- Используйте current_state
end)




ui.set_callback(menu.aa_builder.defensive.enabled, function()
    local enabled = ui.get(menu.aa_builder.defensive.enabled)
    ui.set_visible(menu.aa_builder.defensive.state, enabled)
    ui.set_visible(menu.aa_builder.defensive.pitch, enabled)
    ui.set_visible(menu.aa_builder.defensive.yaw, enabled)
    ui.set_visible(menu.aa_builder.defensive.yaw_jitter, enabled)
    
    local jitter_mode = ui.get(menu.aa_builder.defensive.yaw_jitter)
    ui.set_visible(menu.aa_builder.defensive.yaw_jitter_3way, enabled and jitter_mode == "3-way")
    ui.set_visible(menu.aa_builder.defensive.yaw_jitter_5way, enabled and jitter_mode == "5-way")
end)

-- Обработчик включения/выключения defensive AA
ui.set_callback(menu.aa_builder.defensive.enabled, function()
    local enabled = ui.get(menu.aa_builder.defensive.enabled)
    ui.set_visible(menu.aa_builder.defensive.state, enabled)
    ui.set_visible(menu.aa_builder.defensive.pitch, enabled)
    ui.set_visible(menu.aa_builder.defensive.yaw, enabled)
    ui.set_visible(menu.aa_builder.defensive.yaw_jitter, enabled)
	ui.set_callback(menu.aa_builder.defensive.pitch, on_setting_change)
    ui.set_callback(menu.aa_builder.defensive.yaw, on_setting_change)
    ui.set_callback(menu.aa_builder.defensive.yaw_jitter, on_setting_change)
    ui.set_callback(menu.aa_builder.defensive.yaw_jitter_3way, on_setting_change)
    ui.set_callback(menu.aa_builder.defensive.yaw_jitter_5way, on_setting_change)
    
    local jitter_mode = ui.get(menu.aa_builder.defensive.yaw_jitter)
    ui.set_visible(menu.aa_builder.defensive.yaw_jitter_3way, enabled and jitter_mode == "3-way")
    ui.set_visible(menu.aa_builder.defensive.yaw_jitter_5way, enabled and jitter_mode == "5-way")
end)

ui.set_callback(menu.aa_builder.defensive.yaw_jitter, function()
    if not ui.get(menu.aa_builder.defensive.enabled) then return end
    
    local jitter_mode = ui.get(menu.aa_builder.defensive.yaw_jitter)
    ui.set_visible(menu.aa_builder.defensive.yaw_jitter_3way, jitter_mode == "3-way")
    ui.set_visible(menu.aa_builder.defensive.yaw_jitter_5way, jitter_mode == "5-way")
end)






setup_callbacks()