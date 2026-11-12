    ["respect pvp"] = {
        ["skip_attribute"] = true,
        ["prediction"] = true,
        ["ammo_free"] = true,
        ["tool_part"] = {"Handle", "Frame", "Main", "Receiver", "Body 2", "Origin", "Muzzle"},
        ["no_anti_stomp"] = true,
        ["no_wallbang"] = true,
        ["no_wall_shots"] = true,
        ["no_teleport_bullets"] = true,
        ["no_magic_bullet"] = true,
        ["no_body_hooks"] = true,
        ["fire_cooldown"] = 0.01,
        ["shoot"] = function(tool, position)
            local run = getgenv()["__respect_shoot"]

            if run then
                run(tool, position)
            end
        end,
        ["do_reload"] = function()
            local run = getgenv()["__respect_reload"]

            if run then
                run()
            end
        end,
        ["init"] = function()
            do
                local main = menu["groups"]["main"]

                main:create_tab("respect")
                main:create_tab("respect misc")

                local aim = main:create_section("respect", "aim", 1, 0.55, 0)
                local shoot = main:create_section("respect", "shoot", 1, 0.45, 0.55)
                local weapon = main:create_section("respect", "weapon mods", 2, 1, 0)
                local move = main:create_section("respect misc", "move", 1, 0.5, 0)
                local see = main:create_section("respect misc", "see", 1, 0.5, 0.5)
                local extra = main:create_section("respect misc", "extra", 2, 1, 0)

                aim:create_element({["name"] = "silent aim"}, {["toggle"] = {["flag"] = "rp_silent"}})
                aim:create_element({["name"] = "aim lock (hold right click)"}, {["toggle"] = {["flag"] = "rp_lock"}})
                aim:create_element({["name"] = "rage mode (ignore circle)"}, {["toggle"] = {["flag"] = "rp_rage"}})
                aim:create_element({["name"] = "aim at"}, {["dropdown"] = {["flag"] = "rp_bone", ["options"] = {"head", "chest", "closest"}, ["default"] = {"head"}, ["multi"] = false, ["requires_one"] = true}})
                aim:create_element({["name"] = "aim circle size"}, {["slider"] = {["flag"] = "rp_fov", ["min"] = 40, ["max"] = 600, ["default"] = 160}})
                aim:create_element({["name"] = "hit chance"}, {["slider"] = {["flag"] = "rp_hit", ["min"] = 1, ["max"] = 100, ["default"] = 100, ["suffix"] = "%"}})
                aim:create_element({["name"] = "show circle"}, {["toggle"] = {["flag"] = "rp_circle", ["default"] = true}})

                shoot:create_element({["name"] = "auto shoot"}, {["toggle"] = {["flag"] = "rp_shoot"}})
                shoot:create_element({["name"] = "auto reload"}, {["toggle"] = {["flag"] = "rp_reload"}})

                local heal = shoot:create_element({["name"] = "auto bandage"}, {["toggle"] = {["flag"] = "rp_heal"}})
                local heal_settings = heal:create_settings()

                heal_settings:create_element({["name"] = "below health"}, {["slider"] = {["flag"] = "rp_heal_at", ["min"] = 10, ["max"] = 90, ["default"] = 50}})
                shoot:create_element({["name"] = "auto armor"}, {["toggle"] = {["flag"] = "rp_armor"}})

                weapon:create_element({["name"] = "no spread"}, {["toggle"] = {["flag"] = "rp_nospread"}})
                weapon:create_element({["name"] = "no recoil"}, {["toggle"] = {["flag"] = "rp_norecoil"}})
                local wall = weapon:create_element({["name"] = "wallbang"}, {["toggle"] = {["flag"] = "rp_wallbang"}})
                local wall_settings = wall:create_settings()

                wall_settings:create_element({["name"] = "reach"}, {["slider"] = {["flag"] = "rp_wall_reach", ["min"] = 4, ["max"] = 20, ["default"] = 10}})
                weapon:create_element({["name"] = "full auto"}, {["toggle"] = {["flag"] = "rp_auto"}})

                local rapid = weapon:create_element({["name"] = "rapid fire"}, {["toggle"] = {["flag"] = "rp_rapid"}})
                local rapid_settings = rapid:create_settings()

                rapid_settings:create_element({["name"] = "speed"}, {["slider"] = {["flag"] = "rp_rapid_value", ["min"] = 110, ["max"] = 400, ["default"] = 150, ["suffix"] = "%"}})

                local reload = weapon:create_element({["name"] = "fast reload"}, {["toggle"] = {["flag"] = "rp_fast_reload"}})
                local reload_settings = reload:create_settings()

                reload_settings:create_element({["name"] = "time"}, {["slider"] = {["flag"] = "rp_fast_reload_value", ["min"] = 10, ["max"] = 90, ["default"] = 50, ["suffix"] = "%"}})
                weapon:create_element({["name"] = "fast equip"}, {["toggle"] = {["flag"] = "rp_equip"}})

                local tracer = weapon:create_element({["name"] = "tracer changer"}, {["toggle"] = {["flag"] = "rp_tracer"}})
                local tracer_settings = tracer:create_settings()

                tracer_settings:create_element({["name"] = "tracer"}, {["dropdown"] = {["flag"] = "rp_tracer_name", ["options"] = {"Crimson", "Ocean", "Lime", "Ice", "Sunset", "Violet", "Toxic", "Plasma", "Gold", "Inferno", "Rainbow", "Galaxy", "BloodMoon", "Aurora"}, ["default"] = {"Rainbow"}, ["multi"] = false, ["requires_one"] = true}})

                move:create_element({["name"] = "infinite stamina"}, {["toggle"] = {["flag"] = "rp_stamina"}})
                move:create_element({["name"] = "no jump cooldown"}, {["toggle"] = {["flag"] = "rp_jump"}})
                move:create_element({["name"] = "no gun slowdown"}, {["toggle"] = {["flag"] = "rp_noslow"}})

                local speed = move:create_element({["name"] = "walk speed"}, {["toggle"] = {["flag"] = "rp_speed"}})
                local speed_settings = speed:create_settings()

                speed_settings:create_element({["name"] = "speed"}, {["slider"] = {["flag"] = "rp_speed_value", ["min"] = 18, ["max"] = 45, ["default"] = 26}})

                see:create_element({["name"] = "see bots"}, {["toggle"] = {["flag"] = "rp_bots"}})
                see:create_element({["name"] = "lines to players"}, {["toggle"] = {["flag"] = "rp_lines"}})

                local view = see:create_element({["name"] = "wider view"}, {["toggle"] = {["flag"] = "rp_view"}})
                local view_settings = view:create_settings()

                view_settings:create_element({["name"] = "amount"}, {["slider"] = {["flag"] = "rp_view_value", ["min"] = 70, ["max"] = 120, ["default"] = 95}})

                extra:create_element({["name"] = "admin alert"}, {["toggle"] = {["flag"] = "rp_admin", ["default"] = true}})
                extra:create_element({["name"] = "leave when admin joins"}, {["toggle"] = {["flag"] = "rp_admin_leave"}})
                extra:create_element({["name"] = "anti afk"}, {["toggle"] = {["flag"] = "rp_afk"}})
            end

            spawn(function()
                local replicated = cloneref(game:GetService("ReplicatedStorage"))
                local input_service = cloneref(game:GetService("UserInputService"))

                local client = wait_for_child(replicated, "Client", 30)
                local shared = wait_for_child(replicated, "Shared", 30)
                local controllers = client and wait_for_child(client, "Controllers", 30)
                local shared_modules = shared and wait_for_child(shared, "Modules", 30)
                local config = shared and wait_for_child(shared, "Config", 30)
                local between = wait_for_child(replicated, "BetweenSides", 30)
                local remote_folder = between and wait_for_child(between, "Remotes", 30)
                local events = remote_folder and wait_for_child(remote_folder, "Events", 30)

                local function load_module(parent, name)
                    local source = parent and wait_for_child(parent, name, 30)
                    local ok, result = pcall(require, source)

                    return ok and result or nil
                end

                local weapon = load_module(controllers, "WeaponController")
                local state = load_module(client, "ClientState")
                local ballistics = load_module(shared_modules, "Ballistics")
                local weapon_data = load_module(config, "WeaponData")
                local effects = load_module(controllers, "EffectsController")
                local remotes = nil

                do
                    local reader = debug and debug["getupvalues"] or getupvalues
                    local found = {}
                    local budget = 0

                    local scan

                    local function inspect(value, depth, seen)
                        if rawget(value, "SetTrigger") and rawget(value, "SetAim") then
                            found["weapon"] = found["weapon"] or value

                            for _, member in value do
                                if type(member) == "function" then
                                    scan(member, depth + 1, seen)
                                end
                            end
                        elseif rawget(value, "InMenu") and rawget(value, "Stamina") ~= nil then
                            found["state"] = found["state"] or value
                        elseif type(rawget(value, "Spread")) == "function" and rawget(value, "PartMultiplier") then
                            found["ballistics"] = found["ballistics"] or value
                        elseif rawget(value, "Loadout") and rawget(value, "ModeWeapons") then
                            found["data"] = found["data"] or value
                        elseif typeof(rawget(value, "Fire")) == "Instance" and rawget(value, "AimState") then
                            found["remotes"] = found["remotes"] or value
                        elseif type(rawget(value, "Tracer")) == "function" and rawget(value, "MuzzleFlash") then
                            found["effects"] = found["effects"] or value
                        end
                    end

                    scan = function(fn, depth, seen)
                        if seen[fn] or depth > 7 or budget > 6000 then
                            return
                        end

                        seen[fn] = true
                        budget = budget + 1

                        local ok, list = pcall(reader, fn)

                        if not ok or type(list) ~= "table" then
                            return
                        end

                        for _, value in list do
                            if type(value) == "function" then
                                scan(value, depth + 1, seen)
                            elseif type(value) == "table" then
                                pcall(inspect, value, depth, seen)
                            end
                        end
                    end

                    for _ = 1, 60 do
                        local seen = {}

                        budget = 0

                        if getconnections then
                            for _, signal in {input_service["InputBegan"], input_service["InputEnded"]} do
                                local ok, list = pcall(getconnections, signal)

                                if ok and type(list) == "table" then
                                    for _, connection in list do
                                        local ok_fn, fn = pcall(function()
                                            return connection["Function"]
                                        end)

                                        if ok_fn and type(fn) == "function" then
                                            scan(fn, 1, seen)
                                        end
                                    end
                                end
                            end
                        end

                        if weapon then
                            pcall(inspect, weapon, 1, seen)
                        end

                        if found["remotes"] then
                            break
                        end

                        wait(0.5)
                    end

                    weapon = found["weapon"] or weapon
                    state = found["state"] or state
                    ballistics = found["ballistics"] or ballistics
                    weapon_data = found["data"] or weapon_data
                    effects = found["effects"] or effects
                    remotes = found["remotes"]
                end

                if not weapon or not state then
                    warn("juju: respect pvp modules not found")
                    return
                end

                local function my_character()
                    return local_player["Character"]
                end

                local function alive(model)
                    local humanoid = model:FindFirstChildOfClass("Humanoid")

                    return humanoid and humanoid["Health"] > 0
                end

                local function shielded(model)
                    local till = model:GetAttribute("ProtectedUntil")

                    return type(till) == "number" and workspace:GetServerTimeNow() < till
                end

                local function gun_of(model)
                    local tool = model and model:FindFirstChildOfClass("Tool")

                    return tool and tool:GetAttribute("Weapon") ~= nil and tool or nil
                end

                local function enemies()
                    local list = {}
                    local mine = my_character()
                    local team = mine and mine:GetAttribute("Team")
                    local match = local_player:GetAttribute("MatchId")

                    for _, player in players_service:GetPlayers() do
                        local model = player["Character"]

                        if player ~= local_player and model and player:GetAttribute("MatchId") == match then
                            if not (team ~= nil and model:GetAttribute("Team") == team) and alive(model) and not shielded(model) then
                                list[#list + 1] = model
                            end
                        end
                    end

                    local folder = find_first_child(workspace, match == nil and "Targets" or "MatchBots")

                    if folder then
                        for _, model in get_children(folder) do
                            if model:IsA("Model") and model ~= mine and alive(model) then
                                if not (team ~= nil and model:GetAttribute("Team") == team) then
                                    list[#list + 1] = model
                                end
                            end
                        end
                    end

                    return list
                end

                local function visible(part, origin)
                    local params = RaycastParams["new"]()

                    params["FilterType"] = Enum["RaycastFilterType"]["Exclude"]
                    params["FilterDescendantsInstances"] = {my_character(), find_first_child(workspace, "FX"), camera}
                    params["IgnoreWater"] = true

                    local hit = workspace:Raycast(origin, part["Position"] - origin, params)

                    return not hit or hit["Instance"]:IsDescendantOf(part["Parent"])
                end

                local function eye()
                    local mine = my_character()
                    local head = mine and find_first_child(mine, "Head")

                    return head and head["Position"] or camera["CFrame"]["Position"]
                end

                local function aim_part(model, center)
                    local mode = flags["rp_bone"][1]
                    local head = find_first_child(model, "Head")
                    local chest = find_first_child(model, "UpperTorso") or find_first_child(model, "Torso")

                    if mode == "head" then
                        return head
                    elseif mode == "chest" then
                        return chest
                    end

                    if not head or not chest then
                        return head or chest
                    end

                    local a = camera:WorldToViewportPoint(head["Position"])
                    local b = camera:WorldToViewportPoint(chest["Position"])
                    local first = (Vector2["new"](a["X"], a["Y"]) - center)["Magnitude"]
                    local second = (Vector2["new"](b["X"], b["Y"]) - center)["Magnitude"]

                    return first <= second and head or chest
                end

                local function pick(rage, origin, through)
                    origin = origin or eye()
                    through = through or flags["rp_wallbang"]

                    local center = camera["ViewportSize"] / 2
                    local radius = rage and 9e9 or flags["rp_fov"]
                    local best_part, best_score = nil, 9e9

                    for _, model in enemies() do
                        local part = aim_part(model, center)

                        if part then
                            local screen, on = camera:WorldToViewportPoint(part["Position"])
                            local pixels = (Vector2["new"](screen["X"], screen["Y"]) - center)["Magnitude"]

                            if (rage or (on and pixels <= radius)) and (through or visible(part, origin)) then
                                local score = rage and (part["Position"] - origin)["Magnitude"] or pixels

                                if score < best_score then
                                    best_part, best_score = part, score
                                end
                            end
                        end
                    end

                    return best_part
                end

                local function part_near(list, aim, reach)
                    local best = nil
                    local closest = reach or 9e9

                    for _, part in list do
                        if typeof(part) == "Instance" and part:IsA("BasePart") then
                            local gap = (part["Position"] - aim)["Magnitude"]

                            if gap < closest then
                                closest = gap
                                best = part
                            end
                        end
                    end

                    return best
                end

                local function part_at(aim)
                    local best = nil
                    local closest = 8

                    for _, model in enemies() do
                        local part = part_near(get_children(model), aim, closest)

                        if part then
                            closest = (part["Position"] - aim)["Magnitude"]
                            best = part
                        end
                    end

                    return best
                end

                local forced_aim = nil
                local forced_part = nil
                local forced_time = 0
                local pulse_until = 0
                local part_first = true
                local shown_aim = nil
                local shown_part = nil
                local shown_time = 0

                local function force(part, aim)
                    forced_part = part
                    forced_aim = aim or (part and part["Position"])
                    forced_time = clock()
                    pulse_until = clock() + 0.3
                end

                local function rewrite(origin, direction, ...)
                    if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
                        return origin, direction, ...
                    end

                    local first, second = ...

                    if typeof(first) == "Instance" then
                        part_first = true
                    elseif typeof(first) == "Vector3" and typeof(second) == "Instance" then
                        part_first = false
                    end

                    local part, aim = nil, nil

                    shown_aim = nil

                    if forced_aim and clock() - forced_time < 0.6 then
                        aim = forced_aim
                        part = forced_part and forced_part["Parent"] and forced_part or part_at(aim)

                        if part and forced_part == part then
                            aim = part["Position"]
                        end
                    end

                    if not aim and (flags["rp_silent"] or flags["rp_rage"]) then
                        if flags["rp_hit"] >= 100 or math_random(1, 100) <= flags["rp_hit"] then
                            part = pick(flags["rp_rage"], origin)
                            aim = part and part["Position"]
                        end
                    end

                    if not aim and flags["silent_aim"] then
                        local get_silent = getgenv()["__juju_get_silent"]
                        local value = get_silent and get_silent()

                        if typeof(value) == "Vector3" then
                            aim = value
                            part = part_at(aim)
                        end
                    end

                    if not aim then
                        return origin, direction, ...
                    end

                    local gap = aim - origin

                    if gap["Magnitude"] < 0.01 then
                        return origin, direction, ...
                    end

                    local unit = gap["Unit"]

                    shown_aim = aim
                    shown_part = part
                    shown_time = clock()

                    if part and flags["rp_wallbang"] and not visible(part, origin) then
                        local reach = math.min(flags["rp_wall_reach"], 20, gap["Magnitude"] - 2)
                        local flat = vector3_new(0, 1, 0)
                        local side = unit:Cross(flat)

                        side = side["Magnitude"] < 0.05 and vector3_new(1, 0, 0) or side["Unit"]

                        local up = side:Cross(unit)["Unit"]
                        local spots = {up, side, -side, (up + side)["Unit"], (up - side)["Unit"], -up, (side - up)["Unit"], (-side - up)["Unit"]}
                        local found = nil

                        for step = 2, math.min(reach, 8), 2 do
                            for _, spot in spots do
                                local point = origin + spot * step

                                if visible(part, point) then
                                    found = point
                                    break
                                end
                            end

                            if found then
                                break
                            end
                        end

                        if not found then
                            local params = RaycastParams["new"]()

                            params["FilterType"] = Enum["RaycastFilterType"]["Exclude"]
                            params["FilterDescendantsInstances"] = {my_character(), part["Parent"], find_first_child(workspace, "FX"), camera}
                            params["IgnoreWater"] = true

                            local back = workspace:Raycast(aim, origin - aim, params)
                            local point = back and back["Position"] + unit * 0.4

                            if point and (point - origin)["Magnitude"] <= reach then
                                found = point
                            end
                        end

                        if found then
                            origin = found
                            unit = (aim - origin)["Unit"]
                        end
                    end

                    if select("#", ...) == 0 then
                        return origin, unit
                    end

                    if not part then
                        return origin, unit, ...
                    end

                    if part_first then
                        return origin, unit, part, aim, -unit
                    end

                    return origin, unit, aim, part, -unit
                end

                do
                    local mode = "none"

                    if remotes then
                        local real = remotes["Fire"]

                        remotes["Fire"] = {
                            ["FireServer"] = function(_, ...)
                                return real:FireServer(rewrite(...))
                            end
                        }

                        mode = "table"
                    else
                        local fire_remote = events and wait_for_child(events, "WeaponFire", 30)

                        if fire_remote and hookmetamethod and getnamecallmethod then
                            local old = nil
                            local send = fire_remote["FireServer"]

                            old = hookmetamethod(game, "__namecall", function(self, ...)
                                if self == fire_remote and getnamecallmethod() == "FireServer" and not checkcaller() then
                                    return send(self, rewrite(...))
                                end

                                return old(self, ...)
                            end)

                            mode = "namecall"
                        end
                    end

                    if mode == "none" then
                        warn("juju: respect pvp fire hook failed")
                        new_notification("silent aim is not available", 4)
                    end
                end

                if effects and type(effects["Tracer"]) == "function" then
                    local tracer = effects["Tracer"]
                    local impact = effects["Impact"]

                    pcall(function()
                        effects["Tracer"] = function(start, finish, ...)
                            if shown_aim and clock() - shown_time < 0.1 then
                                finish = shown_aim
                            end

                            return tracer(start, finish, ...)
                        end

                        if type(impact) == "function" then
                            effects["Impact"] = function(position, normal, instance, flesh, ...)
                                if shown_aim and shown_part and clock() - shown_time < 0.1 then
                                    return impact(shown_aim, normal, shown_part, true, ...)
                                end

                                return impact(position, normal, instance, flesh, ...)
                            end
                        end
                    end)
                end

                if ballistics and type(ballistics["Spread"]) == "function" then
                    local original = ballistics["Spread"]

                    pcall(function()
                        ballistics["Spread"] = function(direction, ...)
                            if flags["rp_nospread"] then
                                return direction
                            end

                            return original(direction, ...)
                        end
                    end)
                end

                getgenv()["__respect_shoot"] = function(_, position)
                    if typeof(position) ~= "Vector3" then
                        return
                    end

                    local data = ragebot_target
                    local part = data and data[4] and part_near(data[4], position)

                    force(part, part and part["Position"] or position)
                end

                getgenv()["__respect_reload"] = function()
                    if not state["Reloading"] then
                        pcall(weapon["Reload"])
                    end
                end

                spawn(function()
                    while true do
                        wait(0.1)

                        local tool = gun_of(my_character())

                        if tool and state["Equipped"] and local_parts["HumanoidRootPart"] then
                            local distance = flags["auto_fire_fire_distance"]

                            local_tool = tool
                            local_gun = (distance == nil or distance == 1000) and 9e9 or distance
                            local_ammo = 999
                            local_reloading = state["Reloading"] == true
                        else
                            local_gun = nil
                        end
                    end
                end)

                spawn(function()
                    local saved = {}

                    local function set(list, key, on, value)
                        local store = saved[list]

                        if on then
                            if list[key] == nil then
                                return
                            end

                            if not store then
                                store = {}
                                saved[list] = store
                            end

                            if store[key] == nil then
                                store[key] = list[key]
                            end

                            local wanted = type(value) == "function" and value(store[key]) or value

                            if list[key] ~= wanted then
                                pcall(function()
                                    list[key] = wanted
                                end)
                            end
                        elseif store and store[key] ~= nil then
                            pcall(function()
                                list[key] = store[key]
                            end)

                            store[key] = nil
                        end
                    end

                    local function faster(base)
                        return base * flags["rp_rapid_value"] / 100
                    end

                    local function shorter(base)
                        return math.max(0.2, base * flags["rp_fast_reload_value"] / 100)
                    end

                    local old_tracer = nil
                    local tracer_set = false

                    while true do
                        wait(0.5)

                        if weapon_data then
                            for _, data in weapon_data do
                                local recoil = type(data) == "table" and data["Recoil"]
                                local handling = type(data) == "table" and data["Handling"]
                                local fire = type(data) == "table" and data["Fire"]
                                local ammo = type(data) == "table" and data["Ammo"]

                                if type(recoil) == "table" then
                                    set(recoil, "Up", flags["rp_norecoil"], 0)
                                    set(recoil, "Side", flags["rp_norecoil"], 0)
                                end

                                if type(handling) == "table" then
                                    set(handling, "EquipTime", flags["rp_equip"], 0.05)
                                end

                                if type(fire) == "table" and not data["Rocket"] then
                                    set(fire, "Mode", flags["rp_auto"], "Auto")
                                    set(fire, "RPM", flags["rp_rapid"], faster)
                                end

                                if type(ammo) == "table" then
                                    set(ammo, "ReloadTime", flags["rp_fast_reload"], shorter)
                                end
                            end
                        end

                        if flags["rp_tracer"] then
                            local wanted = "Tracer_" .. flags["rp_tracer_name"][1]

                            if not tracer_set then
                                tracer_set = true
                                old_tracer = local_player:GetAttribute("Tracer")
                            end

                            if local_player:GetAttribute("Tracer") ~= wanted then
                                local_player:SetAttribute("Tracer", wanted)
                            end
                        elseif tracer_set then
                            tracer_set = false
                            local_player:SetAttribute("Tracer", old_tracer)
                        end
                    end
                end)

                do
                    local slowed = false
                    local freed = false

                    local function step()
                        if menu["is_menu_open"]() then
                            freed = true
                            state["CursorFree"] = true
                            input_service["MouseBehavior"] = Enum["MouseBehavior"]["Default"]
                        elseif freed then
                            freed = false
                            state["CursorFree"] = false
                        end

                        if flags["rp_stamina"] then
                            state["Stamina"] = 100
                            state["Exhausted"] = false
                        end

                        if flags["rp_jump"] then
                            state["JumpReadyAt"] = 0
                        end

                        if flags["rp_noslow"] then
                            slowed = true
                            state["AimWalkSpeed"] = 18
                            state["ShotRecoverySpeed"] = 18
                        elseif slowed then
                            slowed = false

                            local tool = gun_of(my_character())
                            local data = tool and weapon_data and weapon_data[tool:GetAttribute("Weapon") or ""]
                            local speed = data and data["Handling"] and data["Handling"]["AimWalkSpeed"] or 11

                            state["AimWalkSpeed"] = speed
                            state["ShotRecoverySpeed"] = speed
                        end

                        if flags["rp_speed"] then
                            local mine = my_character()
                            local humanoid = mine and mine:FindFirstChildOfClass("Humanoid")

                            if humanoid and humanoid["WalkSpeed"] > 0 then
                                humanoid["WalkSpeed"] = flags["rp_speed_value"]
                            end
                        end

                        if flags["rp_view"] and not state["Aiming"] then
                            camera["FieldOfView"] = flags["rp_view_value"]
                        end
                    end

                    create_connection(run_service["RenderStepped"], step)
                    create_connection(run_service["Heartbeat"], step)
                end

                do
                    local busy = false

                    local function use(tool, time)
                        busy = true

                        spawn(function()
                            local mine = my_character()
                            local humanoid = mine and mine:FindFirstChildOfClass("Humanoid")
                            local gun = mine and mine:FindFirstChildOfClass("Tool")

                            pcall(function()
                                humanoid:EquipTool(tool)
                                wait(0.25)
                                tool:Activate()
                                wait(time + 0.4)

                                if gun and gun["Parent"] ~= mine and gun:IsDescendantOf(local_player) then
                                    humanoid:EquipTool(gun)
                                end
                            end)

                            wait(1)
                            busy = false
                        end)
                    end

                    spawn(function()
                        while true do
                            wait(0.3)

                            local mine = my_character()
                            local humanoid = mine and mine:FindFirstChildOfClass("Humanoid")
                            local pack = find_first_child(local_player, "Backpack")

                            if not busy and humanoid and pack and humanoid["Health"] > 0 and not state["Reloading"] then
                                local bandage = find_first_child(pack, "Bandage")
                                local kit = find_first_child(pack, "Armor")

                                if flags["rp_heal"] and bandage and humanoid["Health"] <= flags["rp_heal_at"] then
                                    use(bandage, 3)
                                elseif flags["rp_armor"] and kit and (mine:GetAttribute("Armor") or 0) < 20 then
                                    use(kit, 2)
                                end
                            end
                        end
                    end)
                end

                spawn(function()
                    local warned = {}

                    while true do
                        wait(2)

                        if flags["rp_admin"] or flags["rp_admin_leave"] then
                            for _, player in players_service:GetPlayers() do
                                if player ~= local_player and not warned[player] and (player:GetAttribute("Admin") == true or (tonumber(player:GetAttribute("AdminLevel")) or 0) > 0) then
                                    warned[player] = true
                                    new_notification("admin in server: " .. player["Name"], 4)

                                    if flags["rp_admin_leave"] then
                                        wait(0.5)
                                        local_player:Kick("admin in server: " .. player["Name"])
                                    end
                                end
                            end
                        end
                    end
                end)

                spawn(function()
                    while true do
                        wait(0.5)

                        local mine = my_character()
                        local team = mine and mine:GetAttribute("Team")
                        local match = local_player:GetAttribute("MatchId")

                        for player, data in player_data do
                            local theirs = data[3] and data[3]:GetAttribute("Team")
                            local away = typeof(player) == "Instance" and player:GetAttribute("MatchId") ~= match
                            local status = ((team ~= nil and theirs == team) or away) and 2 or 1

                            if data[1] ~= status and (data[1] == 1 or data[1] == 2) then
                                data[1] = status
                                signals["on_player_status_changed"]:Fire(data, status)
                            end
                        end
                    end
                end)

                do
                    local held = false
                    local seen_since = 0
                    local reload_time = 0

                    local function crosshair_hit()
                        local list = enemies()

                        if #list == 0 then
                            return false
                        end

                        local origin = camera["CFrame"]["Position"]
                        local look = camera["CFrame"]["LookVector"] * 700
                        local params = RaycastParams["new"]()

                        params["FilterType"] = Enum["RaycastFilterType"]["Exclude"]
                        params["FilterDescendantsInstances"] = {my_character(), find_first_child(workspace, "FX"), camera}
                        params["IgnoreWater"] = true

                        local hit = workspace:Raycast(origin, look, params)

                        if not hit then
                            return false
                        end

                        for _, model in list do
                            if hit["Instance"]:IsDescendantOf(model) then
                                return true
                            end
                        end

                        return false
                    end

                    local function release()
                        if held then
                            held = false

                            if not input_service:IsMouseButtonPressed(Enum["UserInputType"]["MouseButton1"]) then
                                pcall(weapon["SetTrigger"], false)
                            end
                        end
                    end

                    create_connection(run_service["Heartbeat"], function()
                        local mine = my_character()

                        if not mine or not alive(mine) then
                            release()
                            return
                        end

                        if not state["Equipped"] then
                            release()
                            return
                        end

                        if flags["rp_reload"] and not state["Reloading"] and clock() - reload_time > 1 then
                            local tool = gun_of(mine)
                            local ammo = tool and tool:GetAttribute("Ammo")

                            if type(ammo) == "number" and ammo <= 0 then
                                reload_time = clock()
                                pcall(weapon["Reload"])
                            end
                        end

                        if state["Reloading"] then
                            release()
                            return
                        end

                        local want = clock() < pulse_until

                        if not want and flags["rp_shoot"] then
                            if flags["rp_rage"] then
                                want = pick(true) ~= nil
                            elseif flags["rp_silent"] then
                                want = pick(false) ~= nil
                            elseif crosshair_hit() then
                                if seen_since == 0 then
                                    seen_since = clock()
                                end

                                want = clock() - seen_since >= 0.04
                            else
                                seen_since = 0
                            end
                        end

                        if want then
                            held = true
                            pcall(weapon["SetTrigger"], true)
                        else
                            release()
                        end
                    end)
                end

                do
                    local circle = nil
                    local lines = {}

                    pcall(function()
                        circle = Drawing["new"]("Circle")
                        circle["Thickness"] = 1
                        circle["NumSides"] = 64
                        circle["Filled"] = false
                        circle["Color"] = Color3["fromRGB"](255, 255, 255)
                        circle["Transparency"] = 0.8
                        circle["Visible"] = false
                    end)

                    local function line_for(model)
                        local line = lines[model]

                        if not line then
                            local ok, made = pcall(Drawing["new"], "Line")

                            if not ok then
                                return nil
                            end

                            made["Thickness"] = 1
                            made["Color"] = Color3["fromRGB"](255, 255, 255)
                            made["Transparency"] = 0.8
                            lines[model] = made
                            line = made
                        end

                        return line
                    end

                    run_service:BindToRenderStep("respect_aim", Enum["RenderPriority"]["Camera"]["Value"] + 2, function()
                        if circle then
                            circle["Visible"] = flags["rp_circle"] and (flags["rp_silent"] or flags["rp_lock"]) and not flags["rp_rage"] or false

                            if circle["Visible"] then
                                circle["Radius"] = flags["rp_fov"]
                                circle["Position"] = camera["ViewportSize"] / 2
                            end
                        end

                        local drawn = {}

                        if flags["rp_lines"] then
                            local size = camera["ViewportSize"]

                            for _, model in enemies() do
                                local root = find_first_child(model, "HumanoidRootPart")
                                local line = root and line_for(model)

                                if line then
                                    local screen, on = camera:WorldToViewportPoint(root["Position"])

                                    line["Visible"] = on
                                    line["From"] = Vector2["new"](size["X"] / 2, size["Y"])
                                    line["To"] = Vector2["new"](screen["X"], screen["Y"])
                                    drawn[model] = true
                                end
                            end
                        end

                        for model, line in lines do
                            if not drawn[model] then
                                pcall(line["Remove"], line)
                                lines[model] = nil
                            end
                        end

                        if not flags["rp_lock"] or not input_service:IsMouseButtonPressed(Enum["UserInputType"]["MouseButton2"]) then
                            return
                        end

                        local part = pick(false)

                        if not part then
                            return
                        end

                        local screen = camera:WorldToViewportPoint(part["Position"])
                        local center = camera["ViewportSize"] / 2

                        mousemoverel((screen["X"] - center["X"]) * 0.35, (screen["Y"] - center["Y"]) * 0.35)
                    end)
                end

                do
                    local marks = {}

                    local function clear(model)
                        local mark = marks[model]

                        if mark then
                            for _, item in mark do
                                pcall(item["Destroy"], item)
                            end

                            marks[model] = nil
                        end
                    end

                    local function make(model)
                        local head = find_first_child(model, "Head")

                        if not head then
                            return nil
                        end

                        local glow = Instance["new"]("Highlight")

                        glow["FillTransparency"] = 0.75
                        glow["OutlineTransparency"] = 0
                        glow["DepthMode"] = Enum["HighlightDepthMode"]["AlwaysOnTop"]
                        glow["FillColor"] = Color3["fromRGB"](255, 80, 80)
                        glow["OutlineColor"] = Color3["fromRGB"](255, 80, 80)
                        glow["Adornee"] = model
                        glow["Parent"] = model

                        local board = Instance["new"]("BillboardGui")

                        board["Size"] = UDim2["new"](0, 150, 0, 30)
                        board["StudsOffset"] = vector3_new(0, 2.8, 0)
                        board["AlwaysOnTop"] = true
                        board["Adornee"] = head
                        board["Parent"] = head

                        local label = Instance["new"]("TextLabel")

                        label["Size"] = UDim2["new"](1, 0, 1, 0)
                        label["BackgroundTransparency"] = 1
                        label["TextSize"] = 13
                        label["Font"] = Enum["Font"]["GothamMedium"]
                        label["TextStrokeTransparency"] = 0.4
                        label["TextColor3"] = Color3["fromRGB"](255, 255, 255)
                        label["Parent"] = board

                        return {glow, board, label}
                    end

                    spawn(function()
                        while true do
                            wait(0.2)

                            local seen = {}

                            if flags["rp_bots"] then
                                local origin = camera["CFrame"]["Position"]

                                for _, model in enemies() do
                                    if not players_service:GetPlayerFromCharacter(model) then
                                        seen[model] = true

                                        local mark = marks[model]

                                        if mark and (not mark[1]["Parent"] or not mark[2]["Parent"]) then
                                            clear(model)
                                            mark = nil
                                        end

                                        if not mark then
                                            mark = make(model)
                                            marks[model] = mark
                                        end

                                        if mark then
                                            local humanoid = model:FindFirstChildOfClass("Humanoid")
                                            local root = find_first_child(model, "HumanoidRootPart")
                                            local health = humanoid and floor(humanoid["Health"]) or 0
                                            local distance = root and floor((root["Position"] - origin)["Magnitude"]) or 0

                                            mark[3]["Text"] = model["Name"] .. "\n" .. health .. " hp  " .. distance .. "m"
                                        end
                                    end
                                end
                            end

                            for model in marks do
                                if not seen[model] then
                                    clear(model)
                                end
                            end
                        end
                    end)
                end

                create_connection(local_player["Idled"], function()
                    if flags["rp_afk"] then
                        local idle = game:GetService("VirtualUser")

                        idle:CaptureController()
                        idle:ClickButton2(Vector2["new"]())
                    end
                end)
            end)
        end
    },
