local config = {}

-- Default values
config.Keybind = "F5"
config.CraftTime = 0.01
config.Notify = true

-- Parse config.txt from the mod's root folder
local function loadConfig()
    local modDir = debug.getinfo(1, "S").source:match("@(.*/)")
    local configPath = modDir .. "../config.txt"

    local file = io.open(configPath, "r")
    if not file then
        print("[InstantFabricate] config.txt not found, using defaults\n")
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
    print(string.format("[InstantFabricate] Config: keybind=%s, craft_time=%.2f, notify=%s\n",
        config.Keybind, config.CraftTime, tostring(config.Notify)))
end

loadConfig()

return config
