    ["hypershot"] = {
        ["skip_attribute"] = true,
        ["prediction"] = true,
        ["no_anti_stomp"] = true,
        ["no_wallbang"] = true,
        ["no_wall_shots"] = true,
        ["no_teleport_bullets"] = true,
        ["no_magic_bullet"] = true,
        ["no_body_hooks"] = true,
        ["health_attribute"] = "Health",
        ["alive_attribute"] = "Alive",
        ["fire_cooldown"] = 0.01,
        ["character_of"] = function(player)
            local folder = workspace:FindFirstChild("Entities")

            if not folder then
                return nil
            end

            for _, model in folder:GetChildren() do
                if model:GetAttribute("OwnerUserId") == player["UserId"] then
                    return model
                end
            end

            return nil
        end,
        ["character_signal"] = function(player)
            local store = getgenv()["__hypershot_events"]

            if not store then
                store = {}
                getgenv()["__hypershot_events"] = store
            end

            local event = store[player]

            if not event then
                event = Instance["new"]("BindableEvent")
                store[player] = event
            end

            return event["Event"]
        end,
        ["do_reload"] = function()
        end,
        ["init"] = function()
            do
                local main = menu["groups"]["main"]

                main:create_tab("hypershot")

                local aim = main:create_section("hypershot", "aim", 1, 0.5, 0)
                local shoot = main:create_section("hypershot", "shoot", 1, 0.5, 0.5)
                local see = main:create_section("hypershot", "see", 2, 0.3, 0)
                local weapon = main:create_section("hypershot", "weapon", 2, 0.46, 0.3)
                local extra = main:create_section("hypershot", "extra", 2, 0.24, 0.76)

                aim:create_element({["name"] = "silent aim"}, {["toggle"] = {["flag"] = "hs_silent"}})
                aim:create_element({["name"] = "aim lock (hold right click)"}, {["toggle"] = {["flag"] = "hs_lock"}})
                aim:create_element({["name"] = "rage mode (ignore circle)"}, {["toggle"] = {["flag"] = "hs_rage"}})
                aim:create_element({["name"] = "aim at"}, {["dropdown"] = {["flag"] = "hs_bone", ["options"] = {"head", "chest", "closest", "random"}, ["default"] = {"head"}, ["multi"] = false, ["requires_one"] = true}})
                aim:create_element({["name"] = "aim circle size"}, {["slider"] = {["flag"] = "hs_fov", ["min"] = 40, ["max"] = 600, ["default"] = 200}})
                aim:create_element({["name"] = "show circle"}, {["toggle"] = {["flag"] = "hs_circle", ["default"] = true}})

                shoot:create_element({["name"] = "auto shoot"}, {["toggle"] = {["flag"] = "hs_shoot"}})
                shoot:create_element({["name"] = "auto reload"}, {["toggle"] = {["flag"] = "hs_reload"}})

                see:create_element({["name"] = "see players"}, {["toggle"] = {["flag"] = "hs_esp"}})
                see:create_element({["name"] = "lines to players"}, {["toggle"] = {["flag"] = "hs_lines"}})

                local view = see:create_element({["name"] = "wider view"}, {["toggle"] = {["flag"] = "hs_fov_changer"}})
                local view_settings = view:create_settings()

                view_settings:create_element({["name"] = "amount"}, {["slider"] = {["flag"] = "hs_fov_value", ["min"] = 50, ["max"] = 120, ["default"] = 95}})

                weapon:create_element({["name"] = "no spread"}, {["toggle"] = {["flag"] = "hs_nospread"}})
                weapon:create_element({["name"] = "rapid fire (hold click)"}, {["toggle"] = {["flag"] = "hs_rapid"}})
                weapon:create_element({["name"] = "no shoot delay"}, {["toggle"] = {["flag"] = "hs_instant"}})
                weapon:create_element({["name"] = "no recoil"}, {["toggle"] = {["flag"] = "hypershot_no_recoil"}})
                weapon:create_element({["name"] = "instant scope"}, {["toggle"] = {["flag"] = "hypershot_instant_scope"}})

                local skin = weapon:create_element({["name"] = "skin changer"}, {["toggle"] = {["flag"] = "hypershot_skin"}})
                local skin_settings = skin:create_settings()

                skin_settings:create_element({["name"] = "skin"}, {["dropdown"] = {["flag"] = "hypershot_skin_name", ["options"] = {"Gold", "Chrome", "Hologram", "Rainbow", "Pyrocore Marble", "Pink Pixelated"}, ["default"] = {"Gold"}, ["multi"] = false, ["requires_one"] = true}})

                extra:create_element({["name"] = "auto claim rewards"}, {["toggle"] = {["flag"] = "hs_claim"}})
                extra:create_element({["name"] = "auto play"}, {["toggle"] = {["flag"] = "hs_play"}})
                extra:create_element({["name"] = "anti afk"}, {["toggle"] = {["flag"] = "hs_afk"}})
            end

            spawn(function()
                local tries = 0

                while not (menu_references["auto_reload"] and menu_references["aim_assist_section"] and menu_references["theme_section"]) and tries < 240 do
                    wait(0.25)
                    tries = tries + 1
                end

                wait(2)

                local main = menu["groups"]["main"]

                pcall(main["remove_tab"], main, "ragebot")
                pcall(main["remove_tab"], main, "legitbot")
            end)

            spawn(function()
                local replicated = cloneref(game:GetService("ReplicatedStorage"))
                local input_service = cloneref(game:GetService("UserInputService"))

                local entity_folder = wait_for_child(replicated, "Entity", 15)
                local modules = wait_for_child(replicated, "Modules", 15)
                local gui = wait_for_child(local_player, "PlayerGui", 15)
                local controller_gui = gui and wait_for_child(gui, "ControllerGUI", 9e9)
                local main_local = controller_gui and wait_for_child(controller_gui, "NewMainLocal", 9e9)
                local first_person = gui and wait_for_child(gui, "FirstPersonGUI", 9e9)
                local entities = wait_for_child(workspace, "Entities", 9e9)

                local function load_module(parent, name)
                    local source = parent and find_first_child(parent, name)
                    local ok, result = pcall(require, source)

                    return ok and result or nil
                end

                local shot_client = load_module(entity_folder, "ShotClient")
                local weapon_sim = load_module(entity_folder, "WeaponSim")
                local codec = load_module(entity_folder, "EntityCodec")
                local prediction = load_module(entity_folder, "EntityPrediction")
                local network = load_module(modules, "NetworkModule2")
                local shared = load_module(main_local, "Shared")
                local handler = first_person and load_module(first_person, "ActionHandler")

                if not shot_client or not weapon_sim or not codec or not shared or not entities then
                    warn("juju: hypershot modules not found")
                    return
                end

                local stand_in = Instance["new"]("Tool")

                stand_in["RequiresHandle"] = false
                stand_in["Name"] = "gun"

                local function my_model()
                    for _, model in get_children(entities) do
                        if model:GetAttribute("OwnerUserId") == local_player["UserId"] then
                            return model
                        end
                    end
                end

                local function my_team()
                    local model = my_model()

                    return model and model:GetAttribute("Team") or local_player:GetAttribute("Team")
                end

                local function is_gun(tool)
                    return tool and type(tool["Shoot"]) == "function"
                end

                local function nearest_part(data, aim)
                    local best = nil
                    local closest = 9e9

                    for _, part in data[4] do
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

                local function frozen()
                    local ok, context = pcall(function()
                        return prediction and prediction:GetCtx()
                    end)

                    return ok and context and context["Frozen"] or false
                end

                local function targetable(model, team)
                    if model:GetAttribute("OwnerUserId") == local_player["UserId"] then
                        return false
                    end

                    if model:GetAttribute("Alive") == false or (model:GetAttribute("Health") or 1) <= 0 then
                        return false
                    end

                    local theirs = model:GetAttribute("Team")

                    return not (team ~= nil and theirs == team)
                end

                local function world_params()
                    local params = RaycastParams["new"]()
                    local ignore = find_first_child(workspace, "IgnoreThese")

                    params["FilterType"] = Enum["RaycastFilterType"]["Exclude"]
                    params["FilterDescendantsInstances"] = {entities, ignore, camera}

                    return params
                end

                local function visible(position, origin)
                    return not workspace:Raycast(origin, position - origin, world_params())
                end

                local function aim_part(model, center)
                    local mode = flags["hs_bone"][1]
                    local head = find_first_child(model, "Head")
                    local chest = find_first_child(model, "UpperTorso") or find_first_child(model, "HumanoidRootPart")

                    if mode == "head" then
                        return head
                    elseif mode == "chest" then
                        return chest
                    elseif mode == "random" then
                        return math_random() < 0.5 and head or chest
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

                local function pick(rage)
                    local origin = camera["CFrame"]["Position"]
                    local center = camera["ViewportSize"] / 2
                    local radius = rage and 9e9 or flags["hs_fov"]
                    local team = my_team()
                    local best_part, best_score = nil, 9e9

                    for _, model in get_children(entities) do
                        if model:IsA("Model") and targetable(model, team) then
                            local part = aim_part(model, center)

                            if part then
                                local screen, on = camera:WorldToViewportPoint(part["Position"])
                                local pixels = (Vector2["new"](screen["X"], screen["Y"]) - center)["Magnitude"]

                                if (rage or (on and pixels <= radius)) and visible(part["Position"], origin) then
                                    local score = rage and (part["Position"] - origin)["Magnitude"] or pixels

                                    if score < best_score then
                                        best_part, best_score = part, score
                                    end
                                end
                            end
                        end
                    end

                    return best_part
                end

                local last_spread = 0
                local original_spread = weapon_sim["ConsumeSpread"]

                weapon_sim["ConsumeSpread"] = function(...)
                    local value = original_spread(...)

                    last_spread = value or 0

                    return value
                end

                local forced = nil
                local forced_time = 0
                local original_prepare = shot_client["Prepare"]

                shot_client["Prepare"] = function(self, tool, direction, shot_flags)
                    local packet = original_prepare(self, tool, direction, shot_flags)

                    if not packet then
                        return packet
                    end

                    local aim = nil

                    if forced and clock() - forced_time < 0.4 then
                        aim = forced
                        forced = nil
                    end

                    if not aim and (flags["hs_silent"] or flags["hs_rage"]) then
                        local part = pick(flags["hs_rage"])

                        aim = part and part["Position"]
                    end

                    if not aim and flags["silent_aim"] then
                        local get_silent = getgenv()["__juju_get_silent"]
                        local value = get_silent and get_silent()

                        if typeof(value) == "Vector3" then
                            aim = value
                        end
                    end

                    local origin = shot_client:Origin()
                    local wanted = nil

                    if aim and origin then
                        wanted = (aim - origin)["Unit"]
                    elseif flags["hs_nospread"] and typeof(direction) == "Vector3" and direction["Magnitude"] > 0.5 then
                        wanted = direction["Unit"]
                    end

                    if not wanted then
                        return packet
                    end

                    local result = wanted

                    if last_spread > 0 then
                        local seed = weapon_sim["ShotSeed"](packet["Life"] or 0, packet["ShotSeq"])

                        for _ = 1, 5 do
                            local got = weapon_sim["SpreadDirections"](seed, result, last_spread, 1)[1]

                            result = (result + (wanted - got))["Unit"]
                        end
                    end

                    local unit, raw = codec["QuantizeAim"](result)

                    packet["AimDir"] = unit
                    packet["AimRaw"] = raw

                    return packet
                end

                local firing = false

                local function fire(tool)
                    if firing then
                        return
                    end

                    firing = true

                    spawn(function()
                        pcall(tool["Activate"], tool)
                        firing = false
                    end)
                end

                game_data["shoot"] = function(_, position)
                    local tool = shared["CurrTool"]
                    local data = ragebot_target

                    if not is_gun(tool) or firing or frozen() or typeof(position) ~= "Vector3" then
                        return
                    end

                    if data and not (tool["WSettings"] and tool["WSettings"]["Projectile"]) then
                        local part = nearest_part(data, position)

                        if part then
                            position = part["Position"]
                        end
                    end

                    forced = position
                    forced_time = clock()
                    fire(tool)
                end

                game_data["do_reload"] = function()
                    local tool = shared["CurrTool"]

                    if is_gun(tool) and not shared["Reloading"] then
                        pcall(tool["Reload"], tool)
                    end
                end

                local delays = setmetatable({}, {["__mode"] = "k"})

                spawn(function()
                    while true do
                        wait(0.1)

                        local tool = shared["CurrTool"]
                        local model = my_model()
                        local settings = tool and tool["WSettings"]

                        if settings then
                            if flags["hs_instant"] then
                                if settings["ShootDelay"] then
                                    delays[settings] = settings["ShootDelay"]
                                    settings["ShootDelay"] = nil
                                end
                            elseif delays[settings] then
                                settings["ShootDelay"] = delays[settings]
                                delays[settings] = nil
                            end
                        end

                        if is_gun(tool) and model and local_parts["HumanoidRootPart"] then
                            local distance = flags["auto_fire_fire_distance"]

                            local_tool = stand_in
                            local_gun = distance == 1000 and 9e9 or distance
                            local_ammo = (tool["WSettings"] and tool["WSettings"]["NoAmmo"]) and 999 or (tool["Ammo"] or 0)
                            local_reloading = shared["Reloading"] == true

                            if flags["hs_reload"] and not local_reloading and not shared["Firing"] and (tool["Ammo"] or 1) <= 0 then
                                game_data["do_reload"]()
                            end
                        else
                            local_tool = nil
                            local_gun = nil
                        end
                    end
                end)

                spawn(function()
                    while true do
                        wait(0.5)

                        local mine = my_team()

                        for _, data in player_data do
                            local theirs = data[3] and data[3]:GetAttribute("Team")
                            local status = (mine ~= nil and theirs == mine) and 2 or 1

                            if data[1] ~= status and (data[1] == 1 or data[1] == 2) then
                                data[1] = status
                                signals["on_player_status_changed"]:Fire(data, status)
                            end
                        end
                    end
                end)

                do
                    local store = getgenv()["__hypershot_events"]

                    if not store then
                        store = {}
                        getgenv()["__hypershot_events"] = store
                    end

                    local function announce(model)
                        spawn(function()
                            local owner = nil

                            for _ = 1, 60 do
                                owner = model:GetAttribute("OwnerUserId")

                                if owner then
                                    break
                                end

                                wait(0.05)
                            end

                            local player = owner and players_service:GetPlayerByUserId(owner)

                            if player then
                                game_data["character_signal"](player)
                                store[player]:Fire(model)
                            end
                        end)
                    end

                    create_connection(entities["ChildAdded"], function(model)
                        if model:IsA("Model") then
                            announce(model)
                        end
                    end)
                end

                do
                    local seen_since = 0

                    local function crosshair_hit(team)
                        local origin = camera["CFrame"]["Position"]
                        local look = camera["CFrame"]["LookVector"] * 1000
                        local list = {}

                        for _, model in get_children(entities) do
                            if model:IsA("Model") and targetable(model, team) then
                                list[#list + 1] = model
                            end
                        end

                        if #list == 0 then
                            return false
                        end

                        local params = RaycastParams["new"]()

                        params["FilterType"] = Enum["RaycastFilterType"]["Include"]
                        params["FilterDescendantsInstances"] = list

                        local hit = workspace:Raycast(origin, look, params)

                        if not hit then
                            return false
                        end

                        local wall = workspace:Raycast(origin, look, world_params())

                        return not wall or wall["Distance"] > hit["Distance"]
                    end

                    create_connection(run_service["Heartbeat"], function()
                        local tool = shared["CurrTool"]
                        local model = my_model()

                        if not tool or not model or model:GetAttribute("Alive") == false or shared["Dead"] or shared["Swapping"] or frozen() then
                            return
                        end

                        if is_gun(tool) then
                            if flags["hs_rapid"] and input_service:IsMouseButtonPressed(Enum["UserInputType"]["MouseButton1"]) then
                                fire(tool)
                            end

                            if flags["hs_shoot"] then
                                if flags["hs_rage"] then
                                    if pick(true) then
                                        fire(tool)
                                    end
                                elseif flags["hs_silent"] then
                                    if pick(false) then
                                        fire(tool)
                                    end
                                elseif crosshair_hit(my_team()) then
                                    if seen_since == 0 then
                                        seen_since = clock()
                                    end

                                    if clock() - seen_since >= 0.04 then
                                        fire(tool)
                                    end
                                else
                                    seen_since = 0
                                end
                            end
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

                    run_service:BindToRenderStep("hypershot_aim", Enum["RenderPriority"]["Camera"]["Value"] + 2, function()
                        if circle then
                            circle["Visible"] = flags["hs_circle"] and (flags["hs_silent"] or flags["hs_lock"]) and not flags["hs_rage"] or false

                            if circle["Visible"] then
                                circle["Radius"] = flags["hs_fov"]
                                circle["Position"] = camera["ViewportSize"] / 2
                            end
                        end

                        if flags["hs_fov_changer"] then
                            camera["FieldOfView"] = flags["hs_fov_value"]
                        end

                        local drawn = {}

                        if flags["hs_lines"] then
                            local size = camera["ViewportSize"]
                            local team = my_team()

                            for _, model in get_children(entities) do
                                if model:IsA("Model") and targetable(model, team) then
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
                        end

                        for model, line in lines do
                            if not drawn[model] then
                                pcall(line["Remove"], line)
                                lines[model] = nil
                            end
                        end

                        if not flags["hs_lock"] or not input_service:IsMouseButtonPressed(Enum["UserInputType"]["MouseButton2"]) then
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
                        glow["Adornee"] = model
                        glow["Parent"] = model

                        local board = Instance["new"]("BillboardGui")

                        board["Size"] = UDim2["new"](0, 150, 0, 44)
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
                            wait(0.15)

                            local team = my_team()
                            local origin = camera["CFrame"]["Position"]
                            local seen = {}

                            if flags["hs_esp"] then
                                for _, model in get_children(entities) do
                                    if model:IsA("Model") and targetable(model, team) then
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
                                            local root = find_first_child(model, "HumanoidRootPart")
                                            local clear_view = root and visible(root["Position"], origin)
                                            local color = clear_view and Color3["fromRGB"](90, 255, 120) or Color3["fromRGB"](255, 80, 80)
                                            local health = floor(model:GetAttribute("Health") or 0)
                                            local distance = root and floor((root["Position"] - origin)["Magnitude"]) or 0
                                            local slot = model:GetAttribute("CurrentTool")
                                            local weapon = slot and model:GetAttribute("Weapon" .. slot) or ""

                                            mark[1]["FillColor"] = color
                                            mark[1]["OutlineColor"] = color
                                            mark[3]["Text"] = model["Name"]:gsub("__Bot$", "") .. "\n" .. health .. " hp  " .. distance .. "m  " .. weapon
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
                    if flags["hs_afk"] then
                        local idle = game:GetService("VirtualUser")

                        idle:CaptureController()
                        idle:ClickButton2(Vector2["new"]())
                    end
                end)

                spawn(function()
                    local menu_since = 0

                    while true do
                        wait(5)

                        if network and flags["hs_claim"] then
                            for _, name in {"ClaimDailyReward", "ClaimWelcomeBack"} do
                                pcall(network["FireServer"], network, name)
                            end
                        end

                        if network and flags["hs_play"] then
                            if my_model() then
                                menu_since = 0
                            elseif menu_since == 0 then
                                menu_since = clock()
                            elseif clock() - menu_since > 6 then
                                menu_since = clock()
                                pcall(network["FireServer"], network, "Spawn", shared["IS_MOBILE"] or false, true)
                            end
                        end
                    end
                end)

                if handler and type(handler["WeaponRecoil"]) == "function" then
                    local original = handler["WeaponRecoil"]

                    handler["WeaponRecoil"] = function(...)
                        if flags["hypershot_no_recoil"] then
                            return
                        end

                        return original(...)
                    end
                end

                run_service:BindToRenderStep("hypershot_scope", 2000, function()
                    if not flags["hypershot_instant_scope"] or not is_gun(shared["CurrTool"]) then
                        return
                    end

                    shared["ScopeAlpha"] = shared["Scoping"] and 1 or 0
                    camera["FieldOfView"] = shared["Scoping"] and shared["ScopeFOV"] or shared["TargetFOV"] or camera["FieldOfView"]
                end)

                local skin_applied = nil

                spawn(function()
                    while true do
                        wait(1)

                        local wanted = flags["hypershot_skin"] and flags["hypershot_skin_name"] and flags["hypershot_skin_name"][1]

                        if wanted and wanted ~= skin_applied then
                            for _, tool in shared["Tools"] do
                                if type(tool) == "table" then
                                    tool["SkinData"] = {["SkinName"] = wanted}
                                end
                            end

                            skin_applied = wanted
                            new_notification("skin applied, switch weapons to see it", 1)
                        elseif not wanted then
                            skin_applied = nil
                        end
                    end
                end)

                do
                    local warned = {}

                    local function check(player)
                        if player ~= local_player and player:GetAttribute("CanAccessAdminPanel") and not warned[player] then
                            warned[player] = true

                            new_notification("moderator in server: " .. player["Name"], 3)
                            wait(0.5)
                            local_player:Kick("moderator in server: " .. player["Name"])
                        end
                    end

                    spawn(function()
                        while true do
                            for _, player in players_service:GetPlayers() do
                                check(player)
                            end

                            wait(2)
                        end
                    end)
                end
            end)
        end
    },
