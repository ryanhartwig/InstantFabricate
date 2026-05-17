-- InstantFabricate for Subnautica 2
-- Host-only mod: instantly (or near-instantly) fabricate items.
-- Toggle with configurable keybind (default F5).
-- Clients benefit automatically when the host has this enabled.

local UEHelpers = require("UEHelpers")
local config = require("config")

local VERSION = "1.0.0"
local MOD_NAME = "InstantFabricate"
print(string.format("[%s] v%s loaded\n", MOD_NAME, VERSION))

-------------------
-- Keybind Setup --
-------------------

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

local bindKey = keyMap[config.Keybind]
if not bindKey then
    print(string.format("[%s] Unknown keybind '%s', defaulting to F5\n", MOD_NAME, config.Keybind))
    bindKey = Key.F5
end

-------------------
-- State Persistence
-------------------

local statePath = config.ModDir .. "state.txt"

local function saveState(isEnabled)
    local file = io.open(statePath, "w")
    if file then
        file:write(isEnabled and "enabled=true" or "enabled=false")
        file:close()
    end
end

local function loadState()
    local file = io.open(statePath, "r")
    if not file then return false end
    local content = file:read("*a")
    file:close()
    return content:match("enabled=true") ~= nil
end

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
            saveState(false)
            print(string.format("[%s] DISABLED — %d recipes restored to vanilla\n", MOD_NAME, count))
            notify("Instant Fabricate: OFF")
        else
            local count = applySpeed()
            enabled = true
            saveState(true)
            print(string.format("[%s] ENABLED — %d recipes set to %.2fs\n", MOD_NAME, count, config.CraftTime))
            notify("Instant Fabricate: ON")
        end
    end)
end)

-------------------
-- Auto-enable from saved state
-------------------

-- Recipes aren't loaded at game startup, so we defer until the player
-- spawns into the world (OnPossessedPawnChangedFunction fires on world load).
local savedState = loadState()

if savedState then
    enabled = true
    print(string.format("[%s] Saved state=ON, will apply when world loads\n", MOD_NAME))
end

RegisterHook("/Script/Subnautica2.SN2PlayerController:OnPossessedPawnChangedFunction", function(self, pawnOld, pawnNew)
    if enabled and next(originalCraftTimes) == nil then
        local count = applySpeed()
        if count > 0 then
            print(string.format("[%s] World loaded — %d recipes set to %.2fs\n", MOD_NAME, count, config.CraftTime))
        end
    end
end)

print(string.format("[%s] Press %s to toggle instant fabrication\n", MOD_NAME, config.Keybind))
