    ["nyan flame trainer"] = {
        ["values"] = {
            ["folder"] = "BodyEffects",
            ["armor"] = "Armor",
            ["knocked"] = "K.O",
            ["dead"] = "Dead"
        },
        ["skip_attribute"] = true,
        ["bullet_folder"] = {"Ignored"},
        ["event"] = {"ReplicatedStorage", "MainEvent"},
        ["ignored_folders"] = {{"Ignored"}},
        ["map_folder"] = {"MAP"},
        ["prediction"] = true,
        ["forcefield_prediction"] = true,
        ["wallbang"] = false,
        ["fire_cooldown"] = 0.12,
        ["init"] = function()
            local pending_aim = nil
            local pending_target = nil
            local pending_time = 0
            local last_shot = 0

            game_data["shoot"] = function(tool, position)
                local now = clock()
                local cooldown = (tool:GetAttribute("Cooldown") or 0.12) + 0.02

                if now - last_shot < cooldown then
                    return
                end

                last_shot = now
                pending_aim = position
                pending_target = ragebot_target
                pending_time = now

                tool:Activate()
                delay(0.05, function()
                    tool:Deactivate()
                end)
            end

            local old = getrawmetatable(event)
            local old_namecall = old["__namecall"]

            local new = {
                ["__namecall"] = LPH_JIT_MAX(function(self, ...)
                    if getnamecallmethod() == "InvokeServer" and not checkcaller() and self["Name"] == "Shoot" and pending_aim and clock() - pending_time < 0.6 then
                        local wrapper = ...
                        local data = type(wrapper) == "table" and wrapper["Table"]

                        if type(data) == "table" and typeof(data[1]) == "Instance" then
                            local aim = pending_aim
                            local part = nil
                            local nearest = 9e9

                            if pending_target then
                                for _, candidate in pending_target[4] do
                                    if typeof(candidate) == "Instance" and candidate:IsA("BasePart") then
                                        local distance = (candidate["Position"] - aim)["Magnitude"]

                                        if distance < nearest then
                                            nearest = distance
                                            part = candidate
                                        end
                                    end
                                end
                            end

                            if part then
                                local origin = typeof(data[5]) == "Vector3" and data[5] or local_server_position["p"]
                                local normal = origin - aim

                                data[2] = part
                                data[3] = aim
                                data[4] = normal["Magnitude"] > 0 and normal["Unit"] or vector3_new(0, 1, 0)
                                data[7] = part["Size"]

                                setnamecallmethod("InvokeServer")
                                return old_namecall(self, wrapper)
                            end
                        end
                    end

                    return old_namecall(self, ...)
                end)
            }

            for key, value in old do
                if not new[key] then
                    new[key] = value
                end
            end

            setrawmetatable(event, new)
            game_data["teleport_bullet_hook"] = true
        end,
        ["stomp"] = function()
            local character = local_character
            local lower = character and find_first_child(character, "LowerTorso")
            local upper = character and find_first_child(character, "UpperTorso")

            if not lower or not upper then
                return
            end

            local params = RaycastParams["new"]()
            params["FilterType"] = Enum["RaycastFilterType"]["Exclude"]
            params["FilterDescendantsInstances"] = {character, find_first_child(workspace, "Ignored")}

            local result = workspace:Raycast(lower["Position"], vector3_new(0, -upper["Size"]["Y"] * 4.5, 0), params)

            if not result then
                return
            end

            local model = result["Instance"]:FindFirstAncestorOfClass("Model")

            if not model or not find_first_child(model, "Humanoid") then
                return
            end

            local stomp_started = getgenv()["__juju_stomp_started"]

            if not stomp_started then
                stomp_started = setmetatable({}, {["__mode"] = "k"})
                getgenv()["__juju_stomp_started"] = stomp_started
            end

            local started = stomp_started[model]

            if not started then
                stomp_started[model] = clock()
                return
            end

            if clock() - started < 0.75 then
                return
            end

            stomp_started[model] = nil
            event:FireServer("Stomp", nil, nil, find_first_child(character, "BodyEffects"), result["Instance"])
        end,
        ["do_reload"] = function(tool)
            event:FireServer("Reload", tool)
        end
    },