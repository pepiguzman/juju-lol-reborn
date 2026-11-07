    ["the arab hood"] = {
        ["values"] = {
            ["folder"] = "BodyEffects",
            ["armor"] = "Armor",
            ["knocked"] = "K.O",
            ["dead"] = "Dead"
        },
        ["skip_attribute"] = true,
        ["bullet_folder"] = {"Ignored"},
        ["event"] = {"ReplicatedStorage", "MainEvent"},
        ["ignored_folders"] = {{"Ignored"}, {"Bush"}},
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
                local cooldown = (tool:GetAttribute("ShootingCooldown") or 0.12) + 0.02

                if now - last_shot < cooldown then
                    return
                end

                last_shot = now
                pending_aim = position
                pending_target = ragebot_target
                pending_time = now

                tool:Activate()
                delay(0.03, function()
                    tool:Deactivate()
                end)
            end

            local old = getrawmetatable(event)
            local old_namecall = old["__namecall"]

            local new = {
                ["__namecall"] = LPH_JIT_MAX(function(self, ...)
                    if getnamecallmethod() == "FireServer" and not checkcaller() then
                        local name, data = ...

                        if name == "V_GS" and type(data) == "table" and data["Position"] ~= nil and pending_aim and clock() - pending_time < 0.5 then
                            local aim = pending_aim
                            local target = pending_target
                            local part = nil
                            local nearest = 9e9

                            if target then
                                for _, candidate in target[4] do
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
                                local origin = data["ForcedOrigin"] or local_server_position["p"]
                                local normal = origin - aim

                                data["Position"] = aim
                                data["Hit"] = part
                                data["HitSize"] = part["Size"]
                                data["Normal"] = normal["Magnitude"] > 0 and normal["Unit"] or vector3_new(0, 1, 0)

                                setnamecallmethod("FireServer")
                                return old_namecall(self, name, data)
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
            event:FireServer('Stomp')
        end,
        ["do_reload"] = function(tool)
            event:FireServer("Reload")
            delay(0.9, function()
                event:FireServer("ReloadEnd")
            end)
        end
    },