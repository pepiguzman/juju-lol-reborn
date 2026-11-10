    ["mvsd"] = {
        ["skip_attribute"] = true,
        ["prediction"] = true,
        ["ammo_free"] = true,
        ["tool_part"] = {"RightHandle", "Muzzle"},
        ["no_anti_stomp"] = true,
        ["no_teleport_bullets"] = true,
        ["no_magic_bullet"] = true,
        ["fire_cooldown"] = 0.01,
        ["do_reload"] = function()
        end,
        ["init"] = function()
            local replicated = cloneref(game:GetService("ReplicatedStorage"))
            local path_service = cloneref(game:GetService("PathfindingService"))
            local chat_service = cloneref(game:GetService("TextChatService"))
            local input_service = cloneref(game:GetService("UserInputService"))
            local teams_service = cloneref(game:GetService("Teams"))
            local hop_service = cloneref(game:GetService("TeleportService"))

            local remotes = wait_for_child(replicated, "Remotes", 15)
            local modules = wait_for_child(replicated, "Modules", 15)
            local gun_remote = remotes and wait_for_child(remotes, "ShootGun", 10)
            local stab_remote = remotes and wait_for_child(remotes, "Stab", 10)
            local throw_start = remotes and wait_for_child(remotes, "ThrowStart", 10)
            local throw_hit = remotes and wait_for_child(remotes, "ThrowHit", 10)

            if not gun_remote or not stab_remote then
                warn("juju: mvsd remotes not found")
                return
            end

            local function load_module(name)
                local source = modules and find_first_child(modules, name)
                local ok, result = pcall(require, source)

                return ok and result or nil
            end

            local bullet_renderer = load_module("BulletRenderer")
            local knife_flight = load_module("KnifeProjectileController")
            local weapon_ray = load_module("WeaponRaycast")
            local ray_groups = load_module("CollisionGroups")

            local mouse = local_player:GetMouse()
            local kinds = setmetatable({}, {["__mode"] = "k"})
            local gun_time = 0
            local stab_time = 0
            local throw_time = 0
            local equip_time = 0

            local function kind_of(tool)
                if not tool then
                    return nil
                end

                local kind = kinds[tool]

                if not kind then
                    if find_first_child(tool, "Fire", true) then
                        kind = "gun"
                    elseif find_first_child(tool, "ThrowSound", true) then
                        kind = "knife"
                    end

                    kinds[tool] = kind
                end

                return kind
            end

            local function head_origin()
                local head = local_parts["Head"]

                if head and head["Parent"] then
                    return (head["CFrame"] * cframe_new(0, head["Size"]["Y"] / 2, head["Size"]["Z"] / 2))["Position"]
                end
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

            local function data_near(aim)
                local best = nil
                local closest = 9

                for _, data in player_data do
                    if data[1] ~= 2 and data[3] then
                        local part = nearest_part(data, aim)

                        if part then
                            local gap = (part["Position"] - aim)["Magnitude"]

                            if gap < closest then
                                closest = gap
                                best = data
                            end
                        end
                    end
                end

                return best
            end

            local function part_for(data)
                return data[4][flags["mvsd_part"][1]] or data[4]["Head"] or data[4][r6_part]
            end

            local function in_round(data)
                local mine = local_player:GetAttribute("Match")

                return mine ~= nil and data[2]:GetAttribute("Match") == mine
            end

            local function alive(data)
                return data[3] and not data[7] and data[9] > 0
            end

            local function enemies()
                local list = {}

                for _, data in player_data do
                    if data[1] ~= 2 and in_round(data) and alive(data) and data[4]["HumanoidRootPart"] then
                        list[#list + 1] = data
                    end
                end

                return list
            end

            local function ray_params(...)
                local filter = {local_character, ...}
                local params = RaycastParams["new"]()

                params["FilterType"] = Enum["RaycastFilterType"]["Exclude"]
                params["FilterDescendantsInstances"] = filter

                return params
            end

            local function in_view(data)
                local body = data[3]
                local head = data[4]["Head"]
                local mine = local_parts["Head"]

                if not body or not head or not mine then
                    return false
                end

                local mode = flags["mvsd_detect"][1]
                local params = ray_params(body)

                if mode ~= "raycast" then
                    local _, visible = camera:WorldToScreenPoint(head["Position"])

                    if visible then
                        local from = camera["CFrame"]["Position"]

                        if not workspace:Raycast(from, head["Position"] - from, params) then
                            return true
                        end
                    end
                end

                if mode ~= "camera" then
                    if not workspace:Raycast(mine["Position"], head["Position"] - mine["Position"], params) then
                        return true
                    end
                end

                return false
            end

            local function confirm(data, health, wait_time)
                delay(wait_time or 0.3, function()
                    local now = data[9]

                    if data[3] and now < health then
                        signals["on_local_bullet_confirmed"]:Fire(data[2], data[4]["Head"] or data[4][r6_part], tostring(floor(now - health)), shot_count, "")
                    end
                end)
            end

            local function show_shot(tool, aim)
                local muzzle = find_first_child(tool, "Muzzle", true)
                local sound = find_first_child(tool, "Fire")

                if muzzle and bullet_renderer then
                    pcall(bullet_renderer, muzzle["WorldPosition"], aim, tool:GetAttribute("BulletType"))
                end

                if sound then
                    sound:Play()
                end
            end

            local function shoot_gun(tool, data, part, aim, miss)
                local origin = head_origin()

                if not origin or not aim then
                    return false
                end

                show_shot(tool, aim)
                gun_remote:FireServer(origin, aim, not miss and part or nil, aim)
                shot_count = shot_count + 1

                if data and not miss then
                    confirm(data, data[9])
                end

                return true
            end

            local function stab(data, part)
                stab_remote:FireServer(part)

                if data then
                    confirm(data, data[9])
                end
            end

            local function throw(tool, data, aim, through)
                local handle = find_first_child(tool, "RightHandle")
                local origin = head_origin()

                if not handle or not origin or not throw_start or not throw_hit or not knife_flight then
                    return false
                end

                local direction = (aim - origin)["Unit"]
                local start = through and aim or origin

                throw_start:FireServer(start, direction)

                knife_flight({
                    ["Speed"] = tool:GetAttribute("ThrowSpeed") or 100,
                    ["KnifeProjectile"] = handle:Clone(),
                    ["Direction"] = direction,
                    ["Origin"] = start
                }, function(result)
                    throw_hit:FireServer(result and result["Instance"] or nil, result and result["Position"] or nil)
                end)

                if data then
                    confirm(data, data[9], 0.7)
                end

                return true
            end

            local function tool_gap(tool, fallback)
                if flags["mvsd_ignore_cooldown"] then
                    return 0
                end

                return tool:GetAttribute("Cooldown") or fallback
            end

            local function equip(kind)
                local backpack = find_first_child(local_player, "Backpack")
                local humanoid = local_parts["Humanoid"]

                if not backpack or not humanoid or clock() - equip_time < 0.25 then
                    return false
                end

                for _, tool in get_children(backpack) do
                    if tool["ClassName"] == "Tool" and kind_of(tool) == kind then
                        equip_time = clock()
                        humanoid:EquipTool(tool)

                        return true
                    end
                end

                return false
            end

            local function ensure(kind)
                if kind_of(local_tool) == kind then
                    return local_tool
                end

                equip(kind)
            end

            local function miss_aim(aim)
                local chance = flags["mvsd_hit_chance"]

                if chance >= 100 or math_random(1, 100) <= chance then
                    return aim, false
                end

                local spread = flags["mvsd_miss_offset"]

                return aim + vector3_new((math_random() * 2 - 1) * spread, (math_random() * 2 - 1) * spread, (math_random() * 2 - 1) * spread), true
            end

            game_data["shoot"] = function(tool, position)
                local data = ragebot_target

                if not data or not data[3] or typeof(position) ~= "Vector3" then
                    return
                end

                local kind = kind_of(tool)
                local part = nearest_part(data, position)
                local now = clock()

                if not part then
                    return
                end

                if kind == "gun" then
                    if tool["Enabled"] == false or now - gun_time < tool_gap(tool, 0.3) then
                        return
                    end

                    gun_time = now

                    local aim, miss = miss_aim(position)

                    shoot_gun(tool, data, part, aim, miss)
                elseif kind == "knife" then
                    local mine = local_parts["HumanoidRootPart"]
                    local theirs = data[4]["HumanoidRootPart"]

                    if not mine or not theirs then
                        return
                    end

                    if (mine["Position"] - theirs["Position"])["Magnitude"] <= flags["mvsd_stab_range"] then
                        if now - stab_time >= 0.3 then
                            stab_time = now
                            stab(data, part)
                        end
                    elseif flags["mvsd_throw"] and now - throw_time >= tool_gap(tool, 0.5) then
                        throw_time = now
                        throw(tool, data, position, flags["wallbang"])
                    end
                end
            end

            local controls = nil
            local controls_off = false

            local function set_controls(on)
                if controls == nil then
                    controls = false

                    local scripts = find_first_child(local_player, "PlayerScripts")
                    local module = scripts and find_first_child(scripts, "PlayerModule")
                    local ok, result = pcall(require, module)

                    if ok and result then
                        local got, handler = pcall(function()
                            return result:GetControls()
                        end)

                        controls = got and handler or false
                    end
                end

                if not controls then
                    return
                end

                if on and controls_off then
                    controls_off = false
                    pcall(controls["Enable"], controls)
                elseif not on and not controls_off then
                    controls_off = true
                    pcall(controls["Disable"], controls)
                end
            end

            local function drive(position)
                local humanoid = local_parts["Humanoid"]
                local root = local_parts["HumanoidRootPart"]

                if not humanoid or not root then
                    return
                end

                humanoid:MoveTo(position)

                if not controls then
                    local gap = position - root["Position"]

                    if gap["Magnitude"] > 0.5 then
                        humanoid:Move(gap["Unit"], false)
                    end
                end
            end

            local function make_path(from, to)
                local path = path_service:CreatePath({
                    ["AgentRadius"] = 2,
                    ["AgentHeight"] = 5,
                    ["AgentCanJump"] = true,
                    ["AgentCanClimb"] = false,
                    ["WaypointSpacing"] = 4
                })

                local ok = pcall(path["ComputeAsync"], path, from, to)

                if ok and path["Status"] == Enum["PathStatus"]["Success"] then
                    return path:GetWaypoints()
                end
            end

            do
                local kill_time = 0

                create_connection(run_service["Heartbeat"], function()
                    if not flags["mvsd_kill_all"] then
                        return
                    end

                    local now = clock()

                    if now - kill_time < flags["mvsd_kill_delay"] / 1000 then
                        return
                    end

                    for _, data in player_data do
                        local part = part_for(data)

                        if data[1] ~= 2 and in_round(data) and alive(data) and part then
                            local kind = kind_of(local_tool)

                            kill_time = now

                            if kind == "gun" then
                                shoot_gun(local_tool, data, part, part["Position"])
                            elseif kind == "knife" then
                                stab(data, part)
                            elseif not equip("gun") then
                                equip("knife")
                            end

                            return
                        end
                    end
                end)
            end

            do
                local auto_time = 0

                create_connection(run_service["Heartbeat"], function()
                    local want = flags["mvsd_weapon"][1]

                    if ragebot_target and want ~= "current" and kind_of(local_tool) ~= want then
                        equip(want)
                    end

                    if not flags["mvsd_auto_stab"] then
                        return
                    end

                    local now = clock()
                    local mine = local_parts["HumanoidRootPart"]

                    if not mine or now - auto_time < flags["mvsd_stab_delay"] / 1000 then
                        return
                    end

                    local best, closest = nil, flags["mvsd_stab_range"]

                    for _, data in enemies() do
                        local gap = (data[4]["HumanoidRootPart"]["Position"] - mine["Position"])["Magnitude"]

                        if gap < closest then
                            best, closest = data, gap
                        end
                    end

                    if best then
                        if kind_of(local_tool) ~= "knife" then
                            equip("knife")
                        else
                            auto_time = now
                            stab(best, part_for(best))
                        end
                    end
                end)
            end

            do
                local function sync()
                    local mine = local_player["Team"]
                    local free = teams_service:FindFirstChild("FFA_Team")

                    for player, data in player_data do
                        local status = 2

                        if in_round(data) and not (mine and mine ~= free and player["Team"] == mine) then
                            status = 1
                        end

                        if data[1] ~= status then
                            data[1] = status
                            signals["on_player_status_changed"]:Fire(data, status)
                        end
                    end
                end

                spawn(function()
                    while true do
                        wait(0.5)

                        if flags["mvsd_teams"] then
                            pcall(sync)
                        end
                    end
                end)
            end

            do
                local sizes = {["1v1"] = 1, ["2v2"] = 2, ["3v3"] = 3, ["4v4"] = 4}
                local busy = false
                local last = 0

                local function pad_part(pad)
                    return find_first_child(pad, "Pad") or find_first_child(pad, "TriggerPart") or find_first_child(pad, "Trigger") or pad:FindFirstChildWhichIsA("BasePart")
                end

                local function is_pad(model)
                    if not model:IsA("Model") then
                        return false
                    end

                    if model:GetAttribute("CharacterCount") ~= nil or find_first_child(model, "CharacterCount") then
                        return true
                    end

                    return model["Name"]:lower():find("pad", 1, true) ~= nil and pad_part(model) ~= nil
                end

                local function occupants(pad)
                    local count = pad:GetAttribute("CharacterCount")

                    if type(count) == "number" then
                        return count
                    end

                    count = 0

                    for _, child in get_children(pad) do
                        if child:IsA("Model") and find_first_child_of_class(child, "Humanoid") then
                            count = count + 1
                        end
                    end

                    return count
                end

                local function gather(container, list, depth)
                    if depth > 4 then
                        return
                    end

                    for _, child in get_children(container) do
                        if is_pad(child) then
                            list[#list + 1] = child
                        else
                            gather(child, list, depth + 1)
                        end
                    end
                end

                local function best_pad(kind)
                    local best, fewest = nil, 9e9
                    local limit = sizes[kind] or 1

                    local function visit(parent, depth)
                        if depth > 7 then
                            return
                        end

                        for _, child in get_children(parent) do
                            if child:IsA("Folder") and child["Name"]:lower():find(kind, 1, true) then
                                local list = {}
                                gather(child, list, 0)

                                for _, pad in list do
                                    local count = occupants(pad)

                                    if count < limit and count < fewest then
                                        best, fewest = pad, count
                                    end
                                end
                            end

                            visit(child, depth + 1)
                        end
                    end

                    visit(workspace, 0)

                    return best
                end

                local function walk_to(goal, timeout, stop)
                    local humanoid = local_parts["Humanoid"]
                    local root = local_parts["HumanoidRootPart"]

                    if not humanoid or not root then
                        return false
                    end

                    local function flat(from)
                        local gap = goal - from

                        return vector3_new(gap["X"], 0, gap["Z"])["Magnitude"]
                    end

                    if flat(root["Position"]) <= stop then
                        return true
                    end

                    set_controls(false)

                    local deadline = clock() + timeout
                    local points, index, tries = nil, 2, 0
                    local checked, before = clock(), root["Position"]
                    local arrived = false

                    while clock() < deadline and flags["mvsd_queue"] and local_player:GetAttribute("Match") == nil do
                        root = local_parts["HumanoidRootPart"]

                        if not root then
                            break
                        end

                        if flat(root["Position"]) <= stop then
                            arrived = true
                            break
                        end

                        local now = clock()
                        local moved = (root["Position"] - before)["Magnitude"]

                        if now - checked > 2 then
                            if (moved < 2 or not points or index > #points) and tries < 3 then
                                tries = tries + 1
                                points = make_path(root["Position"], goal)
                                index = 2
                            end

                            checked = now
                            before = root["Position"]
                        end

                        if not points then
                            points = make_path(root["Position"], goal)
                            index = 2
                        end

                        if points and index <= #points then
                            local point = points[index]

                            if (root["Position"] - point["Position"])["Magnitude"] < 4 then
                                index = index + 1
                            else
                                if point["Action"] == Enum["PathWaypointAction"]["Jump"] then
                                    humanoid["Jump"] = true
                                end

                                drive(point["Position"])
                            end
                        else
                            drive(goal)

                            if humanoid["FloorMaterial"] ~= Enum["Material"]["Air"] and moved < 2 and now - checked > 0.4 then
                                humanoid["Jump"] = true
                            end
                        end

                        wait(0.1)
                    end

                    set_controls(true)

                    return arrived
                end

                local function reach(pad)
                    local part = pad_part(pad)
                    local root = local_parts["HumanoidRootPart"]

                    if not part or not root then
                        return false
                    end

                    local gap = part["Position"] - root["Position"]

                    if vector3_new(gap["X"], 0, gap["Z"])["Magnitude"] <= 1.5 then
                        return true
                    end

                    return walk_to(part["Position"], 20, 2) or walk_to(part["Position"] + vector3_new(0, 3, 0), 10, 2) or walk_to(part["Position"], 6, 1.2)
                end

                local function join(kind)
                    local matchmaking = find_first_child(replicated, "GlobalMatchmaking")
                    local library = find_first_child(matchmaking, "Modules")
                    local join_remote = find_first_child(find_first_child(matchmaking, "Remotes"), "JoinQueue")
                    local info = require(find_first_child(library, "GamemodeInfo"))
                    local enum = require(find_first_child(library, "GamemodeEnum"))
                    local helper = require(find_first_child(library, "Util"))
                    local mode = ({["1v1"] = enum["Solo"], ["2v2"] = enum["Duo"], ["3v3"] = enum["Trio"], ["4v4"] = enum["Squad"]})[kind]

                    if join_remote and info[mode] and helper["CheckIfPlayerCanQueue"](local_player) then
                        join_remote:InvokeServer(mode)
                    end
                end

                local function step()
                    if busy or local_player:GetAttribute("Match") ~= nil or clock() - last < flags["mvsd_retry"] + 3 then
                        return
                    end

                    busy = true

                    pcall(function()
                        local kind = flags["mvsd_ring"][1]
                        local pad = best_pad(kind)

                        if not pad then
                            return
                        end

                        if not reach(pad) then
                            last = clock()
                            return
                        end

                        wait(0.8)
                        last = clock() + 25
                        join(kind)
                    end)

                    busy = false
                end

                spawn(function()
                    while true do
                        wait(1)

                        if flags["mvsd_queue"] then
                            pcall(step)
                        end
                    end
                end)
            end

            local function fire_manual(tool, tap)
                local now = clock()

                if tool["Enabled"] == false or now - gun_time < tool_gap(tool, 0) then
                    return
                end

                local origin = head_origin()

                if not origin or not find_first_child(tool, "Muzzle", true) then
                    return
                end

                local aim = tap
                local get_silent = getgenv()["__juju_get_silent"]
                local silent = flags["silent_aim"] and get_silent and get_silent()

                if typeof(silent) == "Vector3" then
                    aim = silent
                elseif not aim then
                    if weapon_ray then
                        aim = weapon_ray["convertScreenPointToVector3"](input_service:GetMouseLocation())
                    else
                        aim = mouse["Hit"]["Position"] + 100 * mouse["UnitRay"]["Direction"]
                    end
                end

                gun_time = now

                if typeof(silent) == "Vector3" and flags["wallbang"] then
                    local data = data_near(silent)
                    local part = data and nearest_part(data, silent)

                    if part then
                        shoot_gun(tool, data, part, silent)
                        return
                    end
                end

                local camera_position = camera["CFrame"]["Position"]
                local group = ray_groups and ray_groups["SCREEN_RAYCAST"]
                local first = weapon_ray and weapon_ray(camera_position, aim, nil, group)
                local finish = first and first["Position"] or aim
                local second = weapon_ray and weapon_ray(origin, finish)
                local result = second or first
                local hit = result and result["Instance"]
                local where = result and result["Position"]

                show_shot(tool, where or aim)
                gun_remote:FireServer(origin, aim, hit, where)
                shot_count = shot_count + 1

                local data = hit and data_near(where)

                if data then
                    confirm(data, data[9])
                end
            end

            do
                local active = false
                local links = {}

                local function set_manual(on)
                    if on == active then
                        return
                    end

                    active = on

                    local stock = local_character and find_first_child(local_character, "GunController")

                    if stock then
                        stock["Enabled"] = not on
                    end

                    for _, link in links do
                        link:Disconnect()
                    end

                    links = {}

                    if on then
                        links[1] = input_service["InputBegan"]:Connect(function(input, processed)
                            if processed then
                                return
                            end

                            if input["UserInputType"] == Enum["UserInputType"]["MouseButton1"] or input["KeyCode"] == Enum["KeyCode"]["ButtonR2"] then
                                if kind_of(local_tool) == "gun" then
                                    fire_manual(local_tool)
                                end
                            end
                        end)

                        links[2] = input_service["TouchTapInWorld"]:Connect(function(position, processed)
                            if not processed and kind_of(local_tool) == "gun" and weapon_ray then
                                fire_manual(local_tool, weapon_ray["convertScreenPointToVector3"](position))
                            end
                        end)
                    end
                end

                spawn(function()
                    while true do
                        wait(0.5)
                        pcall(set_manual, flags["mvsd_manual"] or flags["silent_aim"] or false)

                        local stock = local_character and find_first_child(local_character, "GunController")

                        if active and stock and stock["Enabled"] then
                            stock["Enabled"] = false
                        end
                    end
                end)
            end

            do
                local tracks = setmetatable({}, {["__mode"] = "k"})
                local scheduled = setmetatable({}, {["__mode"] = "k"})
                local step_time = 0
                local last_sample = 0

                local function sample(data)
                    local root = data[4]["HumanoidRootPart"]

                    if not root then
                        return
                    end

                    local state = tracks[data]
                    local now = clock()

                    if not state then
                        tracks[data] = {["list"] = {}, ["velocity"] = vector3_zero, ["average"] = vector3_zero, ["moving"] = false, ["time"] = now, ["position"] = root["Position"]}
                        return
                    end

                    local elapsed = now - state["time"]

                    if elapsed < 0.05 then
                        return
                    end

                    local position = root["Position"]
                    local velocity = (position - state["position"]) / elapsed
                    local list = state["list"]

                    list[#list + 1] = {["time"] = now, ["velocity"] = velocity}

                    if #list > 10 then
                        table.remove(list, 1)
                    end

                    state["velocity"] = velocity
                    state["position"] = position
                    state["time"] = now

                    if #list >= 3 then
                        local total = vector3_zero

                        for index = 1, #list do
                            total = total + list[index]["velocity"]
                        end

                        state["average"] = total / #list
                        state["moving"] = state["average"]["Magnitude"] > flags["mvsd_pred_speed"]
                    end
                end

                local function future(state, seconds)
                    local list = state["list"]

                    if #list < 2 then
                        return nil
                    end

                    if #list >= 3 then
                        local last = list[#list]
                        local before = list[#list - 1]
                        local span = last["time"] - before["time"]

                        if span > 0 then
                            local acceleration = (state["velocity"] - before["velocity"]) / span

                            return state["position"] + state["velocity"] * seconds + 0.5 * acceleration * seconds * seconds
                        end
                    end

                    return state["position"] + state["average"] * seconds
                end

                local function confidence(data, state)
                    local list = state["list"]

                    if #list < 3 then
                        return 0
                    end

                    local sum = 0

                    for index = 1, #list do
                        sum = sum + list[index]["velocity"]["Magnitude"]
                    end

                    local mean = sum / #list
                    local variance = 0

                    for index = 1, #list do
                        variance = variance + (list[index]["velocity"]["Magnitude"] - mean) ^ 2
                    end

                    variance = variance / #list

                    local steady = math["max"](0, 1 - variance / 100)
                    local directions = {}

                    for index = 1, #list do
                        local velocity = list[index]["velocity"]

                        if velocity["Magnitude"] > 0.1 then
                            directions[#directions + 1] = velocity["Unit"]
                        end
                    end

                    local straight = 0

                    if #directions >= 2 then
                        local dots = 0

                        for index = 1, #directions - 1 do
                            dots = dots + directions[index]:Dot(directions[index + 1])
                        end

                        straight = math["max"](0, dots / (#directions - 1))
                    end

                    local fresh = math["min"]((clock() - list[1]["time"]) / flags["mvsd_pred_track"], 1)
                    local mine = local_parts["HumanoidRootPart"]
                    local theirs = data[4]["HumanoidRootPart"]
                    local gap = (mine and theirs) and (mine["Position"] - theirs["Position"])["Magnitude"] or 100
                    local near = 1 - math["min"](gap / 100, 1)

                    return (steady * 0.4 + straight * 0.3 + fresh * 0.2 + near * 0.1) * 100
                end

                local function clear_at(position, body)
                    local from = camera["CFrame"]["Position"]

                    return not workspace:Raycast(from, position - from, ray_params(body))
                end

                local function timing(data)
                    local state = tracks[data]

                    if not state or not state["moving"] or in_view(data) then
                        return nil
                    end

                    if confidence(data, state) < flags["mvsd_pred_confidence"] then
                        return nil
                    end

                    local seconds = 0.05

                    while seconds <= flags["mvsd_pred_time"] do
                        local position = future(state, seconds)

                        if position and clear_at(position, data[3]) then
                            local lead = seconds - flags["mvsd_pred_bullet"]

                            if lead > 0 and lead < 1.5 then
                                return lead
                            end

                            return nil
                        end

                        seconds = seconds + 0.05
                    end
                end

                local function pre_fire(data, lead)
                    if scheduled[data] then
                        return
                    end

                    scheduled[data] = true

                    delay(lead, function()
                        scheduled[data] = nil

                        if not flags["mvsd_pred"] or not alive(data) then
                            return
                        end

                        if flags["mvsd_pred_equip"] and kind_of(local_tool) ~= "gun" then
                            equip("gun")
                            wait(0.15)
                        end

                        local head = data[4]["Head"]

                        if kind_of(local_tool) == "gun" and head and in_view(data) then
                            shoot_gun(local_tool, data, head, head["Position"])
                        end
                    end)
                end

                create_connection(run_service["Heartbeat"], function()
                    if not flags["mvsd_pred"] then
                        return
                    end

                    local now = clock()

                    if now - step_time < 0.05 then
                        return
                    end

                    step_time = now

                    local best, soonest = nil, 9e9

                    for _, data in enemies() do
                        sample(data)

                        local lead = timing(data)

                        if lead and lead < soonest then
                            best, soonest = data, lead
                        end
                    end

                    if best then
                        pre_fire(best, soonest)
                    end
                end)
            end

            do
                local ai = {
                    ["state"] = "idle",
                    ["target"] = nil,
                    ["checked"] = 0,
                    ["path"] = nil,
                    ["waypoint"] = 1,
                    ["path_data"] = nil,
                    ["path_time"] = 0,
                    ["cache"] = {},
                    ["cover"] = nil,
                    ["cover_time"] = 0,
                    ["cover_safety"] = 0,
                    ["last_position"] = nil,
                    ["last_move"] = 0,
                    ["stuck"] = 0,
                    ["dodge_time"] = 0,
                    ["dodge_side"] = 1,
                    ["phase"] = 0,
                    ["repath"] = 0,
                    ["fired"] = 0,
                    ["threats"] = {},
                    ["patrol"] = nil,
                    ["patrol_time"] = 0,
                    ["running"] = false
                }

                local function flat_direction(from, to)
                    local offset = vector3_new(to["X"] - from["X"], 0, to["Z"] - from["Z"])

                    if offset["Magnitude"] <= 0.001 then
                        return vector3_zero
                    end

                    return offset["Unit"]
                end

                local function side_direction(from, to)
                    local direction = flat_direction(from, to)

                    if direction == vector3_zero then
                        return vector3_new(0, 0, 1)
                    end

                    return direction:Cross(vector3_new(0, 1, 0))
                end

                local function has_weapon()
                    for _, holder in {find_first_child(local_player, "Backpack"), local_character} do
                        if holder then
                            for _, child in get_children(holder) do
                                if child["ClassName"] == "Tool" and kind_of(child) then
                                    return true
                                end
                            end
                        end
                    end

                    return false
                end

                local function exposure(data)
                    local mine = local_parts["Head"]

                    if not mine or not data[3] then
                        return 0
                    end

                    local params = ray_params(data[3])
                    local total, seen = 0, 0

                    for _, part in data[4] do
                        if typeof(part) == "Instance" and part:IsA("BasePart") then
                            total = total + 1

                            if not workspace:Raycast(mine["Position"], part["Position"] - mine["Position"], params) then
                                seen = seen + 1
                            end
                        end
                    end

                    return total > 0 and seen / total or 0
                end

                local function find_cover(origin, destination)
                    local now = clock()

                    if now - ai["cover_time"] < 2 then
                        return ai["cover"], ai["cover_safety"]
                    end

                    ai["cover_time"] = now
                    ai["cover"] = nil
                    ai["cover_safety"] = 0

                    local hit = workspace:Raycast(origin, destination - origin, ray_params())

                    if not hit then
                        return nil, 0
                    end

                    local overlap = OverlapParams["new"]()

                    overlap["FilterType"] = Enum["RaycastFilterType"]["Exclude"]
                    overlap["FilterDescendantsInstances"] = {local_character}

                    local tallest = 0

                    for _, part in workspace:GetPartBoundsInBox(cframe_new(hit["Position"]), vector3_new(10, 10, 10), overlap) do
                        if part ~= hit["Instance"] and tallest < part["Size"]["Y"] then
                            tallest = part["Size"]["Y"]
                        end
                    end

                    ai["cover"] = hit["Position"]
                    ai["cover_safety"] = tallest >= 4 and math["min"](tallest / 10, 1) or 0

                    return ai["cover"], ai["cover_safety"]
                end

                local function focus_bonus(data)
                    if not flags["mvsd_ai_focus"] then
                        return 0
                    end

                    local theirs = data[4]["HumanoidRootPart"]

                    for _, mate in player_data do
                        local root = mate[4]["HumanoidRootPart"]

                        if mate[1] == 2 and alive(mate) and root and theirs and (root["Position"] - theirs["Position"])["Magnitude"] < 40 then
                            return 25
                        end
                    end

                    return 0
                end

                local function score_target(data, seen)
                    local mine = local_parts["HumanoidRootPart"]
                    local theirs = data[4]["HumanoidRootPart"]

                    if not mine or not theirs then
                        return -9e9
                    end

                    local offset = theirs["Position"] - mine["Position"]
                    local score = math["max"](0, 120 - offset["Magnitude"]) + seen * 80

                    if data[10] > 0 then
                        score = score + (1 - data[9] / data[10]) * 50
                    end

                    if flags["mvsd_ai_vertical"] then
                        if offset["Y"] > 12 then
                            score = score - math["min"]((offset["Y"] - 12) * 3, 80)
                        elseif offset["Y"] < -12 then
                            score = score + math["min"]((-offset["Y"] - 12) * 2, 30)
                        end
                    end

                    return score + focus_bonus(data)
                end

                local function threats(limit)
                    local mine = local_parts["HumanoidRootPart"]
                    local list = {}

                    if not mine then
                        return list
                    end

                    for _, data in enemies() do
                        local root = data[4]["HumanoidRootPart"]
                        local offset = root["Position"] - mine["Position"]
                        local distance = offset["Magnitude"]

                        if distance <= limit then
                            local facing = 0

                            if distance > 0.001 then
                                facing = math["max"](0, root["CFrame"]["LookVector"]:Dot((-offset)["Unit"]))
                            end

                            list[#list + 1] = {["data"] = data, ["root"] = root, ["distance"] = distance, ["threat"] = (1 - distance / limit) * 60 + facing * 40}
                        end
                    end

                    table.sort(list, function(first, second)
                        return first["threat"] > second["threat"]
                    end)

                    while #list > 6 do
                        table.remove(list)
                    end

                    return list
                end

                local function best_target()
                    local now = clock()

                    if now - ai["checked"] < 0.5 and ai["target"] and alive(ai["target"]) then
                        return ai["target"]
                    end

                    ai["checked"] = now

                    local mine = local_parts["HumanoidRootPart"]
                    local ranked = {}

                    for _, data in enemies() do
                        if mine then
                            ranked[#ranked + 1] = {["data"] = data, ["distance"] = (data[4]["HumanoidRootPart"]["Position"] - mine["Position"])["Magnitude"]}
                        end
                    end

                    table.sort(ranked, function(first, second)
                        return first["distance"] < second["distance"]
                    end)

                    local best, top = nil, -9e9

                    for index = 1, math["min"](#ranked, 5) do
                        local entry = ranked[index]

                        if entry["distance"] <= flags["mvsd_ai_engage"] then
                            local seen = exposure(entry["data"])
                            local score = flags["mvsd_ai_smart"] and score_target(entry["data"], seen) or seen

                            if score > top then
                                best, top = entry["data"], score
                            end
                        end
                    end

                    ai["target"] = best

                    return best
                end

                local function obstacle_ahead(direction, distance)
                    local root = local_parts["HumanoidRootPart"]

                    if not root then
                        return false
                    end

                    local origin = root["Position"] + vector3_new(0, 1, 0)
                    local hit = workspace:Raycast(origin, direction * distance, ray_params())

                    if not hit then
                        return false
                    end

                    local height = hit["Position"]["Y"] - origin["Y"]

                    return height > 2 and height < 8
                end

                local function face(data, snap)
                    local root = local_parts["HumanoidRootPart"]
                    local theirs = data[4]["HumanoidRootPart"]

                    if not root or not theirs then
                        return
                    end

                    local direction = flat_direction(root["Position"], theirs["Position"])

                    if direction == vector3_zero then
                        return
                    end

                    local facing = root["CFrame"]["LookVector"]:Dot(direction)

                    if facing > 0.98 then
                        return
                    end

                    local alpha = 0.5

                    if snap then
                        alpha = facing < 0 and 1 or 0.7
                    end

                    root["CFrame"] = root["CFrame"]:Lerp(CFrame["lookAt"](root["Position"], root["Position"] + direction), alpha)
                end

                local function dodge(theirs, root)
                    local side = side_direction(root["Position"], theirs["Position"])
                    local style = flags["mvsd_ai_dodge"][1]
                    local now = clock()
                    local offset = vector3_zero
                    local jump = false

                    if style == "serpentine" then
                        ai["phase"] = ai["phase"] + 0.1
                        offset = side * (math["sin"](ai["phase"] * 3) * 3)
                    elseif style == "jump spam" then
                        if now - ai["dodge_time"] > 0.15 then
                            ai["dodge_side"] = ai["dodge_side"] * -1
                            ai["dodge_time"] = now
                        end

                        offset = side * ai["dodge_side"] * 8
                        jump = true
                    elseif style == "random" then
                        if now - ai["dodge_time"] > 0.2 + math_random() * 0.4 then
                            local turn = CFrame["Angles"](0, (math_random() * 2 - 1) * math["pi"], 0)

                            offset = turn:VectorToWorldSpace(side) * (math_random() > 0.5 and 1 or -1) * (2 + math_random() * 3)
                            ai["dodge_time"] = now
                        end
                    else
                        if now - ai["dodge_time"] > 0.5 then
                            ai["dodge_side"] = ai["dodge_side"] * -1
                            ai["dodge_time"] = now
                        end

                        offset = side * ai["dodge_side"] * 3
                    end

                    return offset, jump
                end

                local function pathfind(data, mode)
                    local root = local_parts["HumanoidRootPart"]
                    local theirs = data[4]["HumanoidRootPart"]

                    if not root or not theirs then
                        return nil
                    end

                    local now = clock()
                    local cache = ai["cache"]

                    if not flags["mvsd_ai_random"] and ai["path_data"] == data and now - ai["path_time"] < 0.5 and cache["target"] then
                        local moved = (theirs["Position"] - cache["target"])["Magnitude"]
                        local self_moved = cache["self"] and (root["Position"] - cache["self"])["Magnitude"] or 9e9

                        if moved < 10 and self_moved < 5 then
                            return cache["path"]
                        end
                    end

                    local points = make_path(root["Position"], theirs["Position"])

                    if not points then
                        return nil
                    end

                    local list = {}

                    for index, point in points do
                        local position = point["Position"]

                        if mode == "push" and index > 1 and index < #points and index % 2 == 0 then
                            position = position + vector3_new(math_random(-3, 3), 0, math_random(-3, 3))
                        end

                        list[#list + 1] = {["Position"] = position, ["Action"] = point["Action"]}
                    end

                    ai["cache"] = {["path"] = list, ["target"] = theirs["Position"], ["self"] = root["Position"]}
                    ai["path_data"] = data
                    ai["path_time"] = now

                    return list
                end

                local function update_state()
                    local target = ai["target"]

                    if not target or not alive(target) then
                        ai["state"] = "idle"
                        return
                    end

                    local root = local_parts["HumanoidRootPart"]
                    local humanoid = local_parts["Humanoid"]
                    local theirs = target[4]["HumanoidRootPart"]

                    if not root or not theirs then
                        ai["state"] = "idle"
                        return
                    end

                    local offset = theirs["Position"] - root["Position"]
                    local distance = offset["Magnitude"]
                    local seen = in_view(target)
                    local range = flags["mvsd_ai_range"]

                    if flags["mvsd_ai_retreat"] > 0 and humanoid and humanoid["Health"] <= flags["mvsd_ai_retreat"] then
                        ai["state"] = "retreat"
                    elseif flags["mvsd_ai_vertical"] and math["abs"](offset["Y"]) > 20 and not seen then
                        ai["state"] = "reposition"
                    elseif distance < range * 0.6 then
                        ai["state"] = seen and "strafe" or "reposition"
                    elseif distance >= flags["mvsd_ai_engage"] then
                        ai["state"] = "approach"
                    elseif not seen then
                        ai["state"] = distance < range * 2 and "peek" or "approach"
                    else
                        ai["state"] = "engage"
                    end
                end

                local function weapon()
                    local tool = local_tool

                    if tool and kind_of(tool) then
                        return tool
                    end

                    if flags["mvsd_ai_equip"] then
                        if not equip("gun") then
                            equip("knife")
                        end
                    end
                end

                local function fire_at(data)
                    if not in_view(data) then
                        return false
                    end

                    local tool = weapon()
                    local kind = kind_of(tool)

                    if not kind then
                        return false
                    end

                    local mine = local_parts["HumanoidRootPart"]
                    local theirs = data[4]["HumanoidRootPart"]
                    local head = data[4]["Head"] or part_for(data)

                    if not mine or not theirs or not head then
                        return false
                    end

                    local now = clock()

                    if kind == "knife" then
                        if (theirs["Position"] - mine["Position"])["Magnitude"] <= flags["mvsd_stab_range"] then
                            if flags["mvsd_ai_face"] then
                                face(data, true)
                            end

                            stab(data, head)

                            return true
                        end

                        if now - ai["fired"] < tool_gap(tool, 0.5) then
                            return false
                        end

                        if flags["mvsd_ai_face"] then
                            face(data, true)
                        end

                        ai["fired"] = now

                        return throw(tool, data, head["Position"], flags["wallbang"])
                    end

                    if now - ai["fired"] < math["max"](tool_gap(tool, 0), 0.05) then
                        return false
                    end

                    local aim = head["Position"]

                    if flags["mvsd_ai_lead"] then
                        local velocity = theirs["AssemblyLinearVelocity"]

                        if velocity["Magnitude"] > 1 then
                            aim = aim + velocity * flags["mvsd_ai_lead_time"]
                        end
                    end

                    if flags["mvsd_ai_face"] then
                        face(data, true)
                    end

                    ai["fired"] = now

                    return shoot_gun(tool, data, head, aim)
                end

                local function combat_move(data)
                    local humanoid = local_parts["Humanoid"]
                    local root = local_parts["HumanoidRootPart"]
                    local theirs = data[4]["HumanoidRootPart"]

                    if not humanoid or not root or not theirs then
                        return
                    end

                    local offset = theirs["Position"] - root["Position"]
                    local distance = offset["Magnitude"]
                    local direction = flat_direction(root["Position"], theirs["Position"])
                    local shift, jump = dodge(theirs, root)
                    local destination = root["Position"]

                    if flags["mvsd_ai_keep"] then
                        local best = math["clamp"](flags["mvsd_ai_range"], 8, math["max"](8, flags["mvsd_ai_engage"] * 0.6))

                        if distance > best * 1.2 then
                            destination = root["Position"] + direction * math["min"](distance - best, 12)
                        elseif distance < best * 0.75 then
                            destination = root["Position"] - direction * math["min"](best - distance, 10)
                        end
                    end

                    if obstacle_ahead(direction, 4) and clock() - ai["repath"] > 0.35 then
                        jump = true
                    end

                    if jump or (flags["mvsd_ai_vertical"] and offset["Y"] > 6 and humanoid["FloorMaterial"] ~= Enum["Material"]["Air"]) then
                        humanoid["Jump"] = true
                    end

                    drive(destination + shift)
                end

                local function follow(data)
                    local humanoid = local_parts["Humanoid"]
                    local root = local_parts["HumanoidRootPart"]
                    local theirs = data[4]["HumanoidRootPart"]

                    if not humanoid or not root or not theirs then
                        return
                    end

                    if not ai["path"] or ai["waypoint"] > #ai["path"] then
                        local mode = (ai["state"] == "reposition" or ai["state"] == "retreat") and "flank" or "push"
                        local path = pathfind(data, mode)

                        if path and #path > 0 then
                            ai["path"] = path
                            ai["waypoint"] = 1
                            ai["repath"] = clock()
                        end
                    end

                    if not ai["path"] or ai["waypoint"] > #ai["path"] then
                        drive(theirs["Position"])
                        return
                    end

                    local point = ai["path"][ai["waypoint"]]
                    local now = clock()

                    if (root["Position"] - point["Position"])["Magnitude"] < 4 or now - ai["repath"] > 4 then
                        ai["waypoint"] = ai["waypoint"] + 1
                        ai["repath"] = now
                    end

                    if ai["waypoint"] > #ai["path"] then
                        drive(theirs["Position"])
                        return
                    end

                    point = ai["path"][ai["waypoint"]]

                    if point["Action"] == Enum["PathWaypointAction"]["Jump"] then
                        humanoid["Jump"] = true
                    end

                    local direction = (point["Position"] - root["Position"])["Unit"]

                    if obstacle_ahead(direction, 3) then
                        humanoid["Jump"] = true
                    end

                    local shift = vector3_zero

                    if ai["state"] == "engage" or ai["state"] == "peek" then
                        shift = dodge(theirs, root)
                    end

                    if flags["mvsd_ai_bhop"] and ai["state"] == "approach" and humanoid["FloorMaterial"] ~= Enum["Material"]["Air"] then
                        humanoid["Jump"] = true
                    end

                    drive(point["Position"] + shift)
                end

                local function retreat()
                    local root = local_parts["Humanoid"] and local_parts["HumanoidRootPart"]
                    local threat = ai["threats"][1]

                    if not root then
                        return
                    end

                    if not threat then
                        drive(root["Position"])
                        return
                    end

                    local away = flat_direction(threat["root"]["Position"], root["Position"])

                    if away == vector3_zero then
                        away = -root["CFrame"]["LookVector"]
                    end

                    local destination = root["Position"] + away * 25
                    local cover, safety = find_cover(root["Position"], destination)

                    if cover and safety > 0.3 then
                        destination = cover
                    end

                    drive(destination + dodge(threat["root"], root))
                end

                local function peek(data)
                    local root = local_parts["HumanoidRootPart"]
                    local theirs = data[4]["HumanoidRootPart"]

                    if root and theirs then
                        drive(root["Position"] + dodge(theirs, root) * 2)
                    end
                end

                local function tick_ai()
                    local humanoid = local_parts["Humanoid"]
                    local root = local_parts["HumanoidRootPart"]

                    if not humanoid or not root or not has_weapon() then
                        wait(1)
                        return
                    end

                    ai["threats"] = threats(flags["mvsd_ai_engage"])

                    local target = best_target()
                    local now = clock()

                    if not ai["last_position"] then
                        ai["last_position"] = root["Position"]
                        ai["last_move"] = now
                    elseif now - ai["last_move"] > 2 then
                        if (root["Position"] - ai["last_position"])["Magnitude"] < 2 then
                            ai["stuck"] = ai["stuck"] + 1

                            if ai["stuck"] >= 2 then
                                humanoid["Jump"] = true
                                ai["stuck"] = 0
                                ai["path"] = nil
                                ai["waypoint"] = 1
                                ai["path_data"] = nil
                            end
                        else
                            ai["stuck"] = 0
                        end

                        ai["last_position"] = root["Position"]
                        ai["last_move"] = now
                    end

                    update_state()

                    if not target then
                        if not ai["patrol"] or (root["Position"] - ai["patrol"])["Magnitude"] < 3 or now - ai["patrol_time"] > 6 then
                            ai["patrol_time"] = now
                            ai["patrol"] = root["Position"] + vector3_new(math_random(-25, 25), 0, math_random(-25, 25))
                        end

                        drive(ai["patrol"])

                        if flags["mvsd_ai_bhop"] and humanoid["FloorMaterial"] ~= Enum["Material"]["Air"] then
                            humanoid["Jump"] = true
                        end

                        return
                    end

                    local state = ai["state"]

                    if state == "retreat" then
                        retreat()
                        fire_at(target)
                    elseif state == "reposition" or state == "approach" then
                        follow(target)
                        fire_at(target)
                    elseif state == "peek" then
                        peek(target)
                    else
                        if state == "strafe" then
                            local theirs = target[4]["HumanoidRootPart"]

                            if theirs then
                                local shift = dodge(theirs, root)

                                humanoid:Move(root["CFrame"]["LookVector"] + shift)
                            end
                        else
                            combat_move(target)
                        end

                        fire_at(target)
                    end
                end

                local function track_camera(data)
                    local head = data[4]["Head"]

                    if not head then
                        return
                    end

                    local from = camera["CFrame"]["Position"]
                    local _, visible = camera:WorldToScreenPoint(head["Position"])
                    local smooth = flags["mvsd_ai_smooth"]
                    local desired = cframe_new(from, head["Position"])

                    if smooth <= 0 then
                        camera["CFrame"] = desired
                    else
                        camera["CFrame"] = camera["CFrame"]:Lerp(desired, 1 / (visible and smooth or smooth * 2))
                    end
                end

                local function stop()
                    ai["running"] = false
                    ai["target"] = nil
                    ai["path"] = nil
                    ai["path_data"] = nil

                    local humanoid = local_parts["Humanoid"]
                    local root = local_parts["HumanoidRootPart"]

                    if humanoid and root then
                        humanoid:MoveTo(root["Position"])
                    end

                    set_controls(true)
                end

                local function start()
                    if ai["running"] then
                        return
                    end

                    ai["running"] = true
                    set_controls(false)

                    spawn(function()
                        while flags["mvsd_ai"] do
                            pcall(tick_ai)
                            wait(flags["mvsd_ai_rate"])
                        end

                        stop()
                    end)
                end

                create_connection(run_service["RenderStepped"], function()
                    if flags["mvsd_ai"] and ai["target"] and alive(ai["target"]) then
                        track_camera(ai["target"])
                    end
                end)

                game_data["ai_toggle"] = function(on)
                    if on then
                        start()
                    end
                end
            end

            do
                local last_size = nil
                local last_box = nil
                local original = vector3_new(2, 1, 1)

                local function restore_heads()
                    for _, data in player_data do
                        local part = data[4]["Head"]

                        if part and part["Size"]["X"] > 2.5 and part["Transparency"] == 0.7 then
                            part["Size"] = original
                            part["Transparency"] = 0
                        end
                    end
                end

                create_connection(run_service["Heartbeat"], function()
                    if flags["mvsd_bhop"] then
                        local humanoid = local_parts["Humanoid"]

                        if humanoid and humanoid["MoveDirection"]["Magnitude"] > 0 and humanoid["FloorMaterial"] ~= Enum["Material"]["Air"] then
                            humanoid:ChangeState(Enum["HumanoidStateType"]["Jumping"])
                        end
                    end

                    local knife = kind_of(local_tool) == "knife" and find_first_child(local_tool, "RightHandle")

                    if flags["mvsd_hitbox"] and knife then
                        local size = flags["mvsd_hitbox_size"]

                        if last_box ~= knife then
                            last_box = knife
                            last_size = knife["Size"]
                        end

                        if knife["Size"]["X"] ~= size then
                            knife["Size"] = vector3_new(size, size, size)
                            knife["Transparency"] = 0.8
                        end
                    elseif last_box then
                        if last_box["Parent"] then
                            last_box["Size"] = last_size
                            last_box["Transparency"] = 0
                        end

                        last_box = nil
                    end

                    if flags["mvsd_head"] then
                        local size = flags["mvsd_head_size"]

                        for _, data in player_data do
                            local part = data[4]["Head"]

                            if part and data[1] ~= 2 and part["Size"]["X"] ~= size then
                                part["Size"] = vector3_new(size, size, size)
                                part["Transparency"] = 0.7
                            end
                        end
                    end
                end)

                spawn(function()
                    while true do
                        wait(1)

                        if not flags["mvsd_head"] then
                            restore_heads()
                        end
                    end
                end)

                create_connection(run_service["RenderStepped"], function()
                    if flags["mvsd_fov"] then
                        camera["FieldOfView"] = flags["mvsd_fov_value"]
                    end
                end)

                create_connection(local_player["Idled"], function()
                    if flags["mvsd_afk"] then
                        local idle = game:GetService("VirtualUser")

                        idle:CaptureController()
                        idle:ClickButton2(Vector2["new"]())
                    end
                end)
            end

            do
                local phrases = {
                    "gg", "ggs", "ez", "ez kid", "gg ez", "w", "l", "w game", "alo", "ez clap", "mid", "nah", "fr", "ok",
                    "bro", "nice", "trash", "ggg", "ezpz", "w bro", "nah ggs", "no diff", "bad", "ez win", "ok bro",
                    "get good", "skill issue", "we up", "ez dub", "too easy", "u tried", "bro lost", "try again",
                    "keep crying", "ez game", "so free", "gg newgen", "light work", "free win", "get better", "so mid",
                    "no way", "lost lol", "nah bro", "good game", "gg ez bro", "ez w", "ok ggs"
                }

                local finished = remotes and find_first_child(remotes, "OnMatchFinished")

                if finished then
                    create_connection(finished["OnClientEvent"], function()
                        if flags["mvsd_ending"] and math_random(1, 100) <= flags["mvsd_chance"] then
                            delay(math_random(2, 5), function()
                                local text = flags["mvsd_message"]

                                if not text or text == "" then
                                    text = phrases[math_random(1, #phrases)]
                                end

                                pcall(function()
                                    chat_service["TextChannels"]["RBXGeneral"]:SendAsync(text)
                                end)
                            end)
                        end
                    end)
                end
            end

            do
                local main = menu["groups"]["main"]

                main:create_tab("mvsd")

                local weapons = main:create_section("mvsd", "weapons", 1, 0.62, 0)
                local predictive = main:create_section("mvsd", "predictive", 1, 0.38, 0.62)
                local automation = main:create_section("mvsd", "automation", 2, 0.4, 0)
                local players_box = main:create_section("mvsd", "players", 2, 0.3, 0.4)
                local extras = main:create_section("mvsd", "extras", 2, 0.3, 0.7)

                local kill = weapons:create_element({["name"] = "kill all"}, {["toggle"] = {["flag"] = "mvsd_kill_all"}})
                local kill_settings = kill:create_settings()

                kill_settings:create_element({["name"] = "delay"}, {["slider"] = {["flag"] = "mvsd_kill_delay", ["min"] = 10, ["max"] = 2000, ["default"] = 50, ["suffix"] = " ms"}})
                kill_settings:create_element({["name"] = "target part"}, {["dropdown"] = {["flag"] = "mvsd_part", ["options"] = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}, ["default"] = {"Head"}, ["multi"] = false, ["requires_one"] = true}})

                weapons:create_element({["name"] = "weapon"}, {["dropdown"] = {["flag"] = "mvsd_weapon", ["options"] = {"current", "gun", "knife"}, ["default"] = {"current"}, ["multi"] = false, ["requires_one"] = true}})

                local chance = weapons:create_element({["name"] = "hit chance"}, {["slider"] = {["flag"] = "mvsd_hit_chance", ["min"] = 0, ["max"] = 100, ["default"] = 100, ["suffix"] = "%"}})
                local chance_settings = chance:create_settings()

                chance_settings:create_element({["name"] = "miss offset"}, {["slider"] = {["flag"] = "mvsd_miss_offset", ["min"] = 1, ["max"] = 10, ["default"] = 4, ["suffix"] = " studs"}})

                weapons:create_element({["name"] = "throw knives"}, {["toggle"] = {["flag"] = "mvsd_throw", ["default"] = true}})

                local stab_toggle = weapons:create_element({["name"] = "auto stab"}, {["toggle"] = {["flag"] = "mvsd_auto_stab"}})
                local stab_settings = stab_toggle:create_settings()

                stab_settings:create_element({["name"] = "range"}, {["slider"] = {["flag"] = "mvsd_stab_range", ["min"] = 3, ["max"] = 30, ["default"] = 7, ["suffix"] = " studs"}})
                stab_settings:create_element({["name"] = "delay"}, {["slider"] = {["flag"] = "mvsd_stab_delay", ["min"] = 100, ["max"] = 2000, ["default"] = 300, ["suffix"] = " ms"}})

                weapons:create_element({["name"] = "no cooldown"}, {["toggle"] = {["flag"] = "mvsd_ignore_cooldown"}})

                local box = weapons:create_element({["name"] = "knife hitbox"}, {["toggle"] = {["flag"] = "mvsd_hitbox"}})
                local box_settings = box:create_settings()

                box_settings:create_element({["name"] = "size"}, {["slider"] = {["flag"] = "mvsd_hitbox_size", ["min"] = 2, ["max"] = 20, ["default"] = 10}})

                local controller = weapons:create_element({["name"] = "gun controller"}, {["toggle"] = {["flag"] = "mvsd_manual"}})
                local controller_settings = controller:create_settings()

                controller_settings:create_element({["name"] = "detection"}, {["dropdown"] = {["flag"] = "mvsd_detect", ["options"] = {"camera", "raycast", "both"}, ["default"] = {"both"}, ["multi"] = false, ["requires_one"] = true}})

                local pred = predictive:create_element({["name"] = "predictive shooting"}, {["toggle"] = {["flag"] = "mvsd_pred"}})
                local pred_settings = pred:create_settings()

                pred_settings:create_element({["name"] = "max time"}, {["slider"] = {["flag"] = "mvsd_pred_time", ["min"] = 0.1, ["max"] = 2, ["default"] = 1, ["decimals"] = 2, ["suffix"] = " s"}})
                pred_settings:create_element({["name"] = "bullet time"}, {["slider"] = {["flag"] = "mvsd_pred_bullet", ["min"] = 0.05, ["max"] = 0.15, ["default"] = 0.1, ["decimals"] = 3, ["suffix"] = " s"}})
                pred_settings:create_element({["name"] = "min speed"}, {["slider"] = {["flag"] = "mvsd_pred_speed", ["min"] = 1, ["max"] = 20, ["default"] = 5}})
                pred_settings:create_element({["name"] = "tracking"}, {["slider"] = {["flag"] = "mvsd_pred_track", ["min"] = 0.1, ["max"] = 2, ["default"] = 0.5, ["decimals"] = 2, ["suffix"] = " s"}})
                pred_settings:create_element({["name"] = "confidence"}, {["slider"] = {["flag"] = "mvsd_pred_confidence", ["min"] = 0, ["max"] = 100, ["default"] = 70, ["suffix"] = "%"}})
                pred_settings:create_element({["name"] = "auto equip gun"}, {["toggle"] = {["flag"] = "mvsd_pred_equip", ["default"] = true}})

                local queue = automation:create_element({["name"] = "auto queue"}, {["toggle"] = {["flag"] = "mvsd_queue"}})
                local queue_settings = queue:create_settings()

                queue_settings:create_element({["name"] = "gamemode"}, {["dropdown"] = {["flag"] = "mvsd_ring", ["options"] = {"1v1", "2v2", "3v3", "4v4"}, ["default"] = {"1v1"}, ["multi"] = false, ["requires_one"] = true}})
                queue_settings:create_element({["name"] = "retry"}, {["slider"] = {["flag"] = "mvsd_retry", ["min"] = 1, ["max"] = 10, ["default"] = 2, ["suffix"] = " s"}})

                automation:create_element({["name"] = "anti afk"}, {["toggle"] = {["flag"] = "mvsd_afk"}})

                local ending = automation:create_element({["name"] = "message at end"}, {["toggle"] = {["flag"] = "mvsd_ending"}})
                local ending_settings = ending:create_settings()

                ending_settings:create_element({["name"] = "message"}, {["textbox"] = {["flag"] = "mvsd_message"}})
                ending_settings:create_element({["name"] = "chance"}, {["slider"] = {["flag"] = "mvsd_chance", ["min"] = 1, ["max"] = 100, ["default"] = 100, ["suffix"] = "%"}})

                players_box:create_element({["name"] = "round filter"}, {["toggle"] = {["flag"] = "mvsd_teams", ["default"] = true}})

                local head = players_box:create_element({["name"] = "big head"}, {["toggle"] = {["flag"] = "mvsd_head"}})
                local head_settings = head:create_settings()

                head_settings:create_element({["name"] = "size"}, {["slider"] = {["flag"] = "mvsd_head_size", ["min"] = 2, ["max"] = 20, ["default"] = 5}})

                extras:create_element({["name"] = "bunny hop"}, {["toggle"] = {["flag"] = "mvsd_bhop"}})

                local view = extras:create_element({["name"] = "field of view"}, {["toggle"] = {["flag"] = "mvsd_fov"}})
                local view_settings = view:create_settings()

                view_settings:create_element({["name"] = "value"}, {["slider"] = {["flag"] = "mvsd_fov_value", ["min"] = 30, ["max"] = 120, ["default"] = 70}})

                extras:create_element({["name"] = "job id"}, {["textbox"] = {["flag"] = "mvsd_job"}})

                local join = extras:create_element({["name"] = "join server"}, {["button"] = {}})

                create_connection(join["on_clicked"], function()
                    local id = flags["mvsd_job"]

                    if id and id ~= "" then
                        hop_service:TeleportToPlaceInstance(game["PlaceId"], id, local_player)
                    end
                end)

                main:create_tab("ai")

                local bot = main:create_section("ai", "bot", 1, 0.5, 0)
                local targeting = main:create_section("ai", "targeting", 1, 0.5, 0.5)
                local moving = main:create_section("ai", "movement", 2, 0.45, 0)
                local fighting = main:create_section("ai", "combat", 2, 0.55, 0.45)

                local power = bot:create_element({["name"] = "ai bot"}, {["toggle"] = {["flag"] = "mvsd_ai"}})
                local power_settings = power:create_settings()

                power_settings:create_element({["name"] = "update rate"}, {["slider"] = {["flag"] = "mvsd_ai_rate", ["min"] = 0.05, ["max"] = 0.5, ["default"] = 0.1, ["decimals"] = 2, ["suffix"] = " s"}})
                power_settings:create_element({["name"] = "random paths"}, {["toggle"] = {["flag"] = "mvsd_ai_random"}})

                bot:create_element({["name"] = "dodge pattern"}, {["dropdown"] = {["flag"] = "mvsd_ai_dodge", ["options"] = {"zigzag", "serpentine", "jump spam", "random"}, ["default"] = {"zigzag"}, ["multi"] = false, ["requires_one"] = true}})
                bot:create_element({["name"] = "engage distance"}, {["slider"] = {["flag"] = "mvsd_ai_engage", ["min"] = 50, ["max"] = 300, ["default"] = 200, ["suffix"] = " studs"}})
                bot:create_element({["name"] = "optimal range"}, {["slider"] = {["flag"] = "mvsd_ai_range", ["min"] = 10, ["max"] = 50, ["default"] = 20, ["suffix"] = " studs"}})

                targeting:create_element({["name"] = "smart targeting"}, {["toggle"] = {["flag"] = "mvsd_ai_smart", ["default"] = true}})
                targeting:create_element({["name"] = "vertical control"}, {["toggle"] = {["flag"] = "mvsd_ai_vertical", ["default"] = true}})
                targeting:create_element({["name"] = "focus teammates"}, {["toggle"] = {["flag"] = "mvsd_ai_focus", ["default"] = true}})
                targeting:create_element({["name"] = "retreat below"}, {["slider"] = {["flag"] = "mvsd_ai_retreat", ["min"] = 0, ["max"] = 100, ["default"] = 25, ["suffix"] = " hp"}})

                moving:create_element({["name"] = "keep range"}, {["toggle"] = {["flag"] = "mvsd_ai_keep", ["default"] = true}})
                moving:create_element({["name"] = "bunny hop"}, {["toggle"] = {["flag"] = "mvsd_ai_bhop", ["default"] = true}})
                moving:create_element({["name"] = "auto equip"}, {["toggle"] = {["flag"] = "mvsd_ai_equip", ["default"] = true}})

                fighting:create_element({["name"] = "face target"}, {["toggle"] = {["flag"] = "mvsd_ai_face", ["default"] = true}})

                local lead = fighting:create_element({["name"] = "lead targets"}, {["toggle"] = {["flag"] = "mvsd_ai_lead", ["default"] = true}})
                local lead_settings = lead:create_settings()

                lead_settings:create_element({["name"] = "lead time"}, {["slider"] = {["flag"] = "mvsd_ai_lead_time", ["min"] = 0, ["max"] = 0.25, ["default"] = 0.06, ["decimals"] = 3, ["suffix"] = " s"}})

                fighting:create_element({["name"] = "camera smoothing"}, {["slider"] = {["flag"] = "mvsd_ai_smooth", ["min"] = 0, ["max"] = 20, ["default"] = 1}})

                create_connection(power["on_toggle_change"], function(value)
                    game_data["ai_toggle"](value)
                end)
            end
        end
    },
