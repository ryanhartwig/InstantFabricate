-- InstantFabricate for Subnautica 2
-- Host-only mod: instantly (or near-instantly) fabricate items.
-- Toggle with configurable keybind (default F7).
-- Clients benefit automatically when the host has this enabled.

local UEHelpers = require("UEHelpers")

local VERSION = "1.0.0"
local MOD_NAME = "InstantFabricate"

-------------------
-- Configuration --
-------------------

local config = {
    Keybind = "F7",
    CraftTime = 0.01,
    Notify = true,
}

local keyMap = {
    A = Key.A, B = Key.B, C = Key.C, D = Key.D, E = Key.E,
    F = Key.F, G = Key.G, H = Key.H, I = Key.I, J = Key.J,
    K = Key.K, L = Key.L, M = Key.M, N = Key.N, O = Key.O,
    P = Key.P, Q = Key.Q, R = Key.R, S = Key.S, T = Key.T,
    U = Key.U, V = Key.V, W = Key.W, X = Key.X, Y = Key.Y,
    Z = Key.Z,
    F1 = Key.F1, F2 = Key.F2, F3 = Key.F3, F4 = Key.F4,
    F5 = Key.F5, F6 = Key.F6, F7 = Key.F7, F8 = Key.F8,
}

local function loadConfig()
    local modDir = debug.getinfo(1, "S").source:match("@(.*/)")
    local configPath = modDir .. "../config.txt"

    local file = io.open(configPath, "r")
    if not file then
        print(string.format("[%s] config.txt not found, using defaults\n", MOD_NAME))
        return
    end

    for line in file:lines() do
        if line ~= "" and not line:match("^#") then
            local key, value = line:match("^([%w_]+)%s*=%s*(.*)$")
            if key and value then
                value = value:match("^%s*(.-)%s*$")
                if key == "keybind" then
                    config.Keybind = value:upper()
                elseif key == "craft_time" then
                    config.CraftTime = tonumber(value) or 0.01
                elseif key == "notify" then
                    config.Notify = (value == "true")
                end
            end
        end
    end

    file:close()
end

loadConfig()

local bindKey = keyMap[config.Keybind]
if not bindKey then
    print(string.format("[%s] Unknown keybind '%s', defaulting to F7\n", MOD_NAME, config.Keybind))
    bindKey = Key.F7
end

print(string.format("[%s] v%s loaded | keybind=%s, craft_time=%.2f, notify=%s\n",
    MOD_NAME, VERSION, config.Keybind, config.CraftTime, tostring(config.Notify)))

-------------------
-- Core Logic    --
-------------------

local originalCraftTimes = {}  -- recipe FName -> original CraftingTime
local enabled = false

--- Apply modded craft times to all loaded recipes
local function applySpeed()
    local recipes = FindAllOf("UWECraftingRecipe")
    if not recipes then return 0 end

    local count = 0
    for _, recipe in ipairs(recipes) do
        if recipe:IsValid() then
            local ok = pcall(function()
                local name = recipe:GetFName():ToString()
                if not originalCraftTimes[name] then
                    originalCraftTimes[name] = recipe.CraftingTime
                end
                recipe.CraftingTime = config.CraftTime
            end)
            if ok then count = count + 1 end
        end
    end
    return count
end

--- Restore vanilla craft times
local function restoreSpeed()
    local recipes = FindAllOf("UWECraftingRecipe")
    if not recipes then return 0 end

    local count = 0
    for _, recipe in ipairs(recipes) do
        if recipe:IsValid() then
            pcall(function()
                local name = recipe:GetFName():ToString()
                if originalCraftTimes[name] then
                    recipe.CraftingTime = originalCraftTimes[name]
                    count = count + 1
                end
            end)
        end
    end
    return count
end

--- Send in-game toast notification
local function notify(message)
    if not config.Notify then return end
    pcall(function()
        local pawn = UEHelpers:GetPlayerController().Pawn
        local msgLib = StaticFindObject("/Script/UWEGameplayMessageRuntime.Default__UWEGameplayMessageBPLibrary")
        msgLib:NotifyLocalPlayerSimple(pawn, { TagName = FName("Notification.Info") }, FText(message))
    end)
end

-------------------
-- Toggle Keybind
-------------------

RegisterKeyBind(bindKey, function()
    ExecuteInGameThread(function()
        if enabled then
            local count = restoreSpeed()
            enabled = false
            print(string.format("[%s] DISABLED — %d recipes restored to vanilla\n", MOD_NAME, count))
            notify("Instant Fabricate: OFF")
        else
            local count = applySpeed()
            enabled = true
            print(string.format("[%s] ENABLED — %d recipes set to %.2fs\n", MOD_NAME, count, config.CraftTime))
            notify("Instant Fabricate: ON")
        end
    end)
end)

print(string.format("[%s] Press %s to toggle instant fabrication\n", MOD_NAME, config.Keybind))
