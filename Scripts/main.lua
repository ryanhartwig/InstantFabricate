-- BulkCrafting Probe v0.4.0
-- TEST: Can we modify recipe.CraftingTime and have the server respect it?
-- Press F7 to apply instant craft times, then craft an item and check the log.

local VERSION = "0.4.0"
local MOD_NAME = "BulkCrafting"
print(string.format("[%s] v%s CRAFT TIME MODIFICATION TEST\n", MOD_NAME, VERSION))

-------------------
-- Hook Utility  --
-------------------

local function tryHook(path, label, callback)
    local ok, err = pcall(function()
        RegisterHook(path, callback)
    end)
    if ok then
        print(string.format("[%s] HOOK OK: %s\n", MOD_NAME, label))
    else
        print(string.format("[%s] HOOK FAIL: %s -- %s\n", MOD_NAME, label, tostring(err)))
    end
end

-------------------
-- State
-------------------

local originalCraftTimes = {}  -- name -> original time
local speedApplied = false
local craftCount = 0

-------------------
-- Hooks: Log crafting time to confirm server respects our changes
-------------------

tryHook("/Script/UWECrafting.UWECraftingComponent:ServerCraftItemFromRecipe", "ServerCraftItemFromRecipe", function(self, recipe, crafter, outputInventory, bForceImmediate)
    local recipeName = "?"
    pcall(function() recipeName = recipe:get():GetFName():ToString() end)
    print(string.format("[%s] >>> ServerCraftItemFromRecipe | recipe=%s\n", MOD_NAME, recipeName))
end)

tryHook("/Script/UWECrafting.UWECrafterComponent:NotifyCraftingStarted", "NotifyCraftingStarted", function(self, recipeOutput, craftingTime, recipientActor, outputInventory)
    craftCount = craftCount + 1
    local timeVal = "?"
    pcall(function() timeVal = tostring(craftingTime:get()) end)
    print(string.format("[%s] >>> NotifyCraftingStarted #%d | craftingTime=%s %s\n",
        MOD_NAME, craftCount, timeVal, speedApplied and "(MODDED)" or "(VANILLA)"))
end)

tryHook("/Script/UWECrafting.UWECrafterComponent:NotifyCraftingCompleted", "NotifyCraftingCompleted", function(self, recipeOutput, result, recipientActor, outputInventory)
    local resultVal = "?"
    pcall(function() resultVal = tostring(result:get()) end)
    print(string.format("[%s] >>> NotifyCraftingCompleted | result=%s\n", MOD_NAME, resultVal))
end)

-------------------
-- F7: Apply instant craft times to ALL recipes
-------------------

RegisterKeyBind(Key.F7, function()
    ExecuteInGameThread(function()
        if speedApplied then
            -- Restore original times
            local recipes = FindAllOf("UWECraftingRecipe")
            if recipes then
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
                print(string.format("[%s] RESTORED %d recipes to original times\n", MOD_NAME, count))
            end
            speedApplied = false
        else
            -- Apply instant times
            local recipes = FindAllOf("UWECraftingRecipe")
            if not recipes then
                print(string.format("[%s] No recipes found!\n", MOD_NAME))
                return
            end

            local count = 0
            for _, recipe in ipairs(recipes) do
                if recipe:IsValid() then
                    pcall(function()
                        local name = recipe:GetFName():ToString()
                        local origTime = recipe.CraftingTime
                        -- Store original
                        if not originalCraftTimes[name] then
                            originalCraftTimes[name] = origTime
                        end
                        -- Set to near-instant
                        recipe.CraftingTime = 0.01
                        count = count + 1
                    end)
                end
            end
            print(string.format("[%s] APPLIED instant craft (0.01s) to %d recipes\n", MOD_NAME, count))
            speedApplied = true
        end
    end)
end)

-------------------
-- F5: Show a few recipes and their current CraftingTime
-------------------

RegisterKeyBind(Key.F5, function()
    ExecuteInGameThread(function()
        local recipes = FindAllOf("UWECraftingRecipe")
        if not recipes then
            print(string.format("[%s] No recipes found\n", MOD_NAME))
            return
        end

        print(string.format("[%s] === RECIPE TIMES (first 10) ===\n", MOD_NAME))
        local shown = 0
        for _, recipe in ipairs(recipes) do
            if recipe:IsValid() and shown < 10 then
                pcall(function()
                    local name = recipe:GetFName():ToString()
                    local time = recipe.CraftingTime
                    local orig = originalCraftTimes[name]
                    if orig then
                        print(string.format("[%s]   %s: %.2f (was %.2f)\n", MOD_NAME, name, time, orig))
                    else
                        print(string.format("[%s]   %s: %.2f\n", MOD_NAME, name, time))
                    end
                end)
                shown = shown + 1
            end
        end
        print(string.format("[%s] === END (speedApplied=%s) ===\n", MOD_NAME, tostring(speedApplied)))
    end)
end)

print(string.format("[%s] INSTRUCTIONS:\n", MOD_NAME))
print(string.format("[%s]   1. Press F5 to see current recipe times (should be 1.5-2.0)\n", MOD_NAME))
print(string.format("[%s]   2. Craft one item normally — confirm craftingTime in log\n", MOD_NAME))
print(string.format("[%s]   3. Press F7 to apply instant craft times\n", MOD_NAME))
print(string.format("[%s]   4. Press F5 again to confirm times changed to 0.01\n", MOD_NAME))
print(string.format("[%s]   5. Craft another item — does NotifyCraftingStarted show 0.01?\n", MOD_NAME))
print(string.format("[%s]   6. Click rapidly — do items appear instantly?\n", MOD_NAME))
print(string.format("[%s]   F7 again = restore original times\n", MOD_NAME))
