    ["dah aim trainer"] = {
        ["values"] = {
            ["folder"] = "BodyEffects",
            ["armor"] = "Armor",
            ["knocked"] = "K.O",
            ["dead"] = "Dead"
        },
        ["skip_attribute"] = true,
        ["bullet_folder"] = {"Blacklisted"},
        ["bullet_name"] = "BULLET_RAYS",
        ["event"] = {"ReplicatedStorage", "Storage", "Remotes", "Main"},
        ["ignored_folders"] = {{"Blacklisted"}},
        ["map_folder"] = {"Map"},
        ["prediction"] = true,
        ["no_wallbang"] = true,
        ["no_teleport_bullets"] = true,
        ["no_wall_shots"] = true,
        ["forcefield_prediction"] = true,
        ["fire_cooldown"] = 0.18,
        ["init"] = function()
            local lock = nil
            local lock_until = 0
            local busy = false
            local storage = wait_for_child(game:GetService("ReplicatedStorage"), "Storage", 30)
            local remotes = storage and wait_for_child(storage, "Remotes", 30)
            local receive = remotes and find_first_child(remotes, "Receive")

            if receive then
                receive["OnClientInvoke"] = function()
                    if lock and clock() < lock_until then
                        return lock
                    end

                    return local_player:GetMouse()["Hit"]["Position"]
                end
            end

            local real_mouse = local_player:GetMouse()
            local fake_mouse = setmetatable({}, {
                ["__index"] = function(_, key)
                    if key == "Hit" and lock then
                        return cframe_new(lock)
                    end

                    return real_mouse[key]
                end
            })
            local old_namecall = getrawmetatable(event)["__namecall"]
            local new_namecall = {
                ["__namecall"] = LPH_JIT_MAX(function(self, ...)
                    if lock and self == local_player and getnamecallmethod() == "GetMouse" and not checkcaller() and clock() < lock_until then
                        return fake_mouse
                    end

                    return old_namecall(self, ...)
                end)
            }

            for key, value in getrawmetatable(event) do
                if not new_namecall[key] then
                    new_namecall[key] = value
                end
            end

            setrawmetatable(event, new_namecall)

            game_data["shoot"] = function(tool, position)
                if busy then
                    return
                end

                busy = true
                lock = position
                lock_until = clock() + 0.5

                tool:Activate()
                delay(0.03, function()
                    tool:Deactivate()
                end)
                delay(0.1, function()
                    busy = false
                end)
            end
        end,
        ["stomp"] = function()
            local stomp_started = getgenv()["__juju_stomp_started"]

            if not stomp_started then
                stomp_started = setmetatable({}, {["__mode"] = "k"})
                getgenv()["__juju_stomp_started"] = stomp_started
            end

            local character = local_character
            local root = character and find_first_child(character, "LowerTorso")
            local upper = character and find_first_child(character, "UpperTorso")

            if not root or not upper then
                return
            end

            local params = RaycastParams["new"]()
            params["FilterType"] = Enum["RaycastFilterType"]["Exclude"]
            params["FilterDescendantsInstances"] = {character, find_first_child(workspace, "Blacklisted")}

            local result = workspace:Raycast(root["Position"], vector3_new(0, -upper["Size"]["Y"] * 4.5, 0), params)
            local model = result and result["Instance"]["Parent"]

            while model and model ~= workspace and not find_first_child(model, "Humanoid") do
                model = model["Parent"]
            end

            local humanoid = model and find_first_child(model, "Humanoid")

            if not humanoid then
                return
            end

            local started = stomp_started[humanoid]

            if not started then
                stomp_started[humanoid] = clock()
                return
            end

            if clock() - started < 0.75 then
                return
            end

            stomp_started[humanoid] = nil

            local first = game:GetService("ReplicatedFirst")
            local info = require(find_first_child(find_first_child(first, "Handler"), "Info"))
            local animation = find_first_child(find_first_child(find_first_child(game:GetService("ReplicatedStorage"), "Storage"), "Animations"), "Stomp")
            local track = find_first_child(find_first_child(character, "Humanoid"), "Animator"):LoadAnimation(animation)

            event:FireServer("StompRemote", track, find_first_child(character, "BodyEffects"), humanoid, info:CheckCredibility())
        end,
        ["do_reload"] = function(tool)
            event:FireServer("Reload", tool)
        end
    },