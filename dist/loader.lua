local source = "https://raw.githubusercontent.com/pepiguzman/juju-lol-reborn/main/dist/"

getgenv().JUJU_TRACE = false
getgenv().JUJU_DEBUG = false
getgenv().JUJU_DEV = nil

getgenv().JUJU_ASSET = function(name)
    local ok, body = pcall(game.HttpGet, game, source .. (name:gsub(" ", "%%20")))
    if ok and body and #body > 0 then
        return body
    end
end

local http = game:GetService("HttpService")
local market = game:GetService("MarketplaceService")

local function fetch(name)
    local ok, body = pcall(game.HttpGet, game, source .. name .. "?t=" .. os.time())
    if ok and body and #body > 0 then
        return body
    end
end

local ok, index = pcall(function()
    return http:JSONDecode(fetch("index.json") or "{}")
end)

if not ok then
    index = {}
end

local placeName = ""
pcall(function()
    placeName = market:GetProductInfo(game.PlaceId).Name:lower()
end)

local copy = nil
local copyFile = nil

for id, info in pairs(index) do
    local matched = table.find(info.places or {}, game.PlaceId) or table.find(info.games or {}, game.GameId)
    if not matched then
        for _, name in ipairs(info.names or {}) do
            if placeName:find(name, 1, true) then
                matched = true
                break
            end
        end
    end
    if matched then
        copy = id
        copyFile = info.file
        break
    end
end

getgenv().JUJU_COPY = copy

local body = fetch(copy and (copyFile or "juju.lua") or "universal.lua")

if not body then
    return warn("juju.lol reborn: failed to load, try again")
end

local chunk, err = loadstring(body)
if not chunk then
    return warn("juju.lol reborn: " .. tostring(err))
end

chunk()
