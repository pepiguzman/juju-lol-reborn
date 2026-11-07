    ["da uphill"] = {
        ["attributes"] = {
            ["armor"] = "Armor",
            ["dead"] = "Dead",
            ["knocked"] = "Knocked"
        },
        ["bullet_folder"] = {"Head"},
        ["event"] = {"ReplicatedStorage", "MAINEVENT"},
        ["ignored_folders"] = {{"Ignored"}},
        ["ammo_value"] = "AMMO",
        ["bullet_name"] = "Sound",
        ["prediction"] = true,
        ["fire_cooldown"] = 0.2,
        ["map_folder"] = {"Map"},
        ["aim_frame"] = {"gui", "Aim"},
        ["aav_event"] = function(position)
            event:FireServer("MOUSE", position)
        end,
        ["init"] = function()
            local function watch_reload()
                local backpack = wait_for_child(local_player, "Backpack", 10)

                if backpack then
                    local_reloading = backpack:GetAttribute("IsReloading") == true

                    create_connection(backpack:GetAttributeChangedSignal("IsReloading"), function()
                        local_reloading = backpack:GetAttribute("IsReloading") == true
                    end)
                end
            end

            signals["on_local_character_added"]:Connect(watch_reload)

            if local_character then
                spawn(watch_reload)
            end

            local busy = false
            local lock = nil
            local lock_until = 0
            local old_namecall = getrawmetatable(event)["__namecall"]
            local new = {
                ["__namecall"] = LPH_JIT_MAX(function(self, ...)
                    if lock and getnamecallmethod() == "FireServer" and not checkcaller() and clock() < lock_until then
                        local name = ...

                        if name == "MOUSE" then
                            setnamecallmethod("FireServer")
                            return old_namecall(self, "MOUSE", lock)
                        end
                    end

                    return old_namecall(self, ...)
                end)
            }

            for key, value in getrawmetatable(event) do
                if not new[key] then
                    new[key] = value
                end
            end

            setrawmetatable(event, new)

            local assets = find_first_child(game:GetService("ReplicatedStorage"), "Assets")
            local invoke = assets and find_first_child(assets, "Invoke")

            if invoke then
                invoke["OnClientInvoke"] = function(_, kind)
                    if kind == "mouse" then
                        if lock and clock() < lock_until then
                            return lock
                        end

                        return local_player:GetMouse()["Hit"]["Position"]
                    end
                end
            end            game_data["shoot"] = function(tool, position)
                if busy then
                    return
                end

                busy = true
                lock = position
                lock_until = clock() + 0.4
                event:FireServer("MOUSE", position)

                local backpack = find_first_child(local_player, "Backpack")
                local deadline = clock() + 0.25

                while backpack and clock() < deadline do
                    local aim = backpack:GetAttribute("AimPosition")

                    if typeof(aim) == "Vector3" and (aim - position)["Magnitude"] < 1.5 then
                        break
                    end

                    wait()
                end

                tool:Activate()
                delay(0.03, function()
                    tool:Deactivate()
                end)
                busy = false
            end
        end,
        ["stomp"] = function()
            event:FireServer("STOMP")
        end,
        ["do_reload"] = function(tool)
            tool["rl"]:FireServer()
        end
    },
