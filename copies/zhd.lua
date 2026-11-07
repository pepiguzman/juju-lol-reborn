    ["zhd"] = {
        ["values"] = {
            ["folder"] = "BodyEffects",
            ["dead"] = "Dead",
            ["armor"] = "Armor",
            ["knocked"] = "K.O",
            ["grabbed"] = "Grabbed",
            ["reload"] = "Reload",
        },
        ["armor_name"] = "full armor",
        ["shop_folder"] = {"Ignored", "Shop"},
        ["bullet_folder"] = {"Ignored"},
        ["event"] = {"ReplicatedStorage", "MainRemotes", "MainRemoteEvent"},
        ["ignored_folders"] = {{"Ignored"}},
        ["ammo_value"] = "Ammo",
        ["bullet_name"] = "BULLET_RAYS",
        ["prediction"] = true,
        ["aim_frame"] = {"MainScreenGui", "Aim"},
        ["shoot_packet"] = {name = "ShootGun", handle = 2, origin = 3, position = 5, part = 6, normal = 7},
        ["aav_event"] = function(position)
        end,
        ["init"] = function()
            local getnamecallmethod = getnamecallmethod
            local checkcaller = checkcaller
            local counts = {}
            local mouse_arg = nil
            local learned = {}
            local direct_ok = true
            local direct_fails = 0
            local direct_wins = 0

            local old = getrawmetatable(event)
            local old_namecall = old["__namecall"]

            local new = {
                ["__namecall"] = LPH_JIT_MAX(function(self, ...)
                    if getnamecallmethod() == "FireServer" and not checkcaller() then
                        local name, handle, origin, pellets, _, _, _, range, cooldown = ...

                        if name == "ShootGun" and pellets == nil and typeof(handle) == "Instance" and typeof(origin) == "Vector3" and handle["Parent"] and (origin - handle["Position"])["Magnitude"] < 8 then
                            local info = learned[handle["Parent"]] or {}
                            info["rel"] = handle["CFrame"]:PointToObjectSpace(origin)
                            info["range"] = range
                            info["cooldown"] = cooldown
                            learned[handle["Parent"]] = info
                        end
                    end

                    if not mouse_arg and getnamecallmethod() == "FireServer" and not checkcaller() then
                        local name, position = ...

                        if type(name) == "string" and typeof(position) == "Vector3" then
                            local count = (counts[name] or 0) + 1
                            counts[name] = count

                            if count >= 15 then
                                mouse_arg = name
                            end
                        end
                    end
                    return old_namecall(self, ...)
                end)
            }

            for _, v in old do
                if not new[_] then
                    new[_] = v
                end
            end

            setrawmetatable(event, new)

            game_data["shoot"] = function(tool, position)
                local info = learned[tool]
                local handle = find_first_child(tool, "Handle")
                local ammo = find_first_child(tool, "Ammo")
                local target = ragebot_target
                local cooldown_value = find_first_child(tool, "ShootingCooldown")

                if direct_ok and info and handle and ammo and target and typeof(position) == "Vector3" then
                    local now = clock()

                    if ammo["Value"] < 1 or now - (info["last"] or 0) < (cooldown_value and cooldown_value["Value"] or 0.1) + 0.005 then
                        return
                    end

                    if (flags["hit_chance"] or 100) < 100 and math_random(1, 100) > flags["hit_chance"] then
                        return
                    end

                    local part = nil
                    local nearest = 9e9

                    for _, candidate in target[4] do
                        if typeof(candidate) == "Instance" and (candidate["ClassName"] == "Part" or candidate["ClassName"] == "MeshPart") then
                            local distance = (candidate["Position"] - position)["Magnitude"]

                            if distance < nearest then
                                nearest = distance
                                part = candidate
                            end
                        end
                    end

                    local origin = handle["CFrame"]:PointToWorldSpace(info["rel"])
                    local shift = local_server_position["p"] - local_client_position["p"]

                    if shift["Magnitude"] > 0.5 then
                        origin = origin + shift
                    end

                    local back = origin - position
                    local normal = back["Magnitude"] > 0 and back["Unit"] or vector3_new(0, 1, 0)
                    local wall = getgenv()["__juju_wallbang"]

                    if (flags["teleport_bullets"] or flags["wallbang"]) and not wall.blocked() then
                        origin = position + normal * 3
                    end

                    local range = info["range"] or 200
                    local aim_direction = position - origin
                    local aim_point = origin + (aim_direction["Magnitude"] > 0 and aim_direction["Unit"] or normal) * range
                    local before = ammo["Value"]

                    info["last"] = now
                    event:FireServer("ShootGun", handle, origin, nil, position, part, normal, range, info["cooldown"], aim_point, nil)

                    delay(0.4, function()
                        if not ammo["Parent"] then
                            return
                        end

                        if ammo["Value"] < before then
                            direct_wins = direct_wins + 1
                            direct_fails = 0
                        else
                            direct_fails = direct_fails + 1

                            if direct_wins == 0 and direct_fails >= 6 then
                                direct_ok = false
                            end
                        end
                    end)

                    return
                end

                tool:Activate()
                delay(0.03, function()
                    tool:Deactivate()
                end)
            end

            game_data["aav_event"] = function(position)
                if mouse_arg then
                    event:FireServer(mouse_arg, position)
                end
            end
        end,
        ["map_folder"] = {"MAP"},
        ["do_reload"] = function(tool)
            event:FireServer("Reload", tool)
        end
    },
