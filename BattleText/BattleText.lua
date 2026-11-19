local addonName, BT = ...

BT.areas = {
    { key = "incoming", label = "Incoming damage", x = -245, y = 45, rgb = { 1, 0.48, 0.45 }, format = "-%d" },
    { key = "outgoing", label = "Outgoing damage", x = 245, y = 45, rgb = { 1, 0.79, 0.43 }, format = "%d" },
    { key = "healing", label = "Healing received", x = 0, y = -165, rgb = { 0.38, 0.93, 0.72 }, format = "+%d" },
    { key = "experience", label = "XP gained", x = 0, y = 135, rgb = { 0.77, 0.62, 1 } },
    { key = "loot", label = "Loot received", x = 0, y = 225, rgb = { 1, 0.88, 0.56 } },
    { key = "combat", label = "Combat status", x = 0, y = 55, rgb = { 0.57, 0.83, 1 } },
}

BT.combatMessages = {
    PLAYER_REGEN_DISABLED = "Combat started",
    PLAYER_REGEN_ENABLED = "Combat ended",
}

local MAX_LINES = 12
local FONT = STANDARD_TEXT_FONT
local function secret(value)
    return issecretvalue and issecretvalue(value)
end

BT.secret = secret

local function number(value, fallback, low, high)
    if type(value) ~= "number" or value ~= value then
        return fallback
    end
    return math.max(low, math.min(high, value))
end

local function tableOrEmpty(value)
    return type(value) == "table" and value or {}
end

local function loadSettings()
    local db = tableOrEmpty(BattleTextDB)
    db.size = number(db.size, 26, 16, 40)
    db.speed = number(db.speed, 1, 0.5, 2)
    db.minimumAmount = number(db.minimumAmount, 0, 0, 1000)
    local defaultMotion = db.scrollDown == true and "arc" or "up"
    db.areas = tableOrEmpty(db.areas)
    for _, area in ipairs(BT.areas) do
        local saved = tableOrEmpty(db.areas[area.key])
        local rgb = tableOrEmpty(saved.rgb)
        saved.rgb = {}
        for i = 1, 3 do
            saved.rgb[i] = number(rgb[i], area.rgb[i], 0, 1)
        end
        saved.x = number(saved.x, area.x, -10000, 10000)
        saved.y = number(saved.y, area.y, -10000, 10000)
        saved.enabled = saved.enabled ~= false
        if saved.motion ~= "up" and saved.motion ~= "down" and saved.motion ~= "arc" then
            saved.motion = defaultMotion
        end
        db.areas[area.key] = saved
    end
    db.scrollDown = nil
    BattleTextDB = db
    BT.db = db
end

local function style(line, saved, scale)
    local size = BT.db.size * scale * (line.critical and 1.28 or 1)
    line.text:SetFont(FONT, math.floor(size + 0.5), "OUTLINE")
    line.text:SetTextColor(unpack(saved.rgb))
end

local function recycle(renderer, index)
    local line = table.remove(renderer.lines, index)
    line.text:Hide()
    line.text:SetText("")
    renderer.pool[#renderer.pool + 1] = line
end

function BT.CreateRenderer(parent, area, scale)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(1, 1)
    local renderer = { frame = frame, lines = {}, pool = {}, area = area }
    local function position(line, progress)
        local x = (line.lane - 1) * 36
        local y = 66 * progress + line.lane * 20
        local motion = BT.db.areas[area.key].motion
        if motion == "arc" then
            local side = area.key == "incoming" and -1 or (area.key == "outgoing" and 1 or 0)
            x = x + side * 32 * math.sin(progress * math.pi)
        end
        if motion ~= "up" then
            y = -y
        end
        line.text:SetPoint("CENTER", frame, "CENTER", x * scale, y * scale)
    end

    frame:SetScript("OnUpdate", function(self, elapsed)
        local saved = BT.db.areas[area.key]
        for i = #renderer.lines, 1, -1 do
            local line = renderer.lines[i]
            line.age = line.age + elapsed * BT.db.speed
            if line.age >= 1.65 or not saved.enabled then
                recycle(renderer, i)
            else
                style(line, saved, scale)
                local progress = line.age / 1.65
                position(line, progress)
                line.text:SetAlpha(math.min(1, (1 - progress) * 3.5))
            end
        end
        if #renderer.lines == 0 then
            self:Hide()
        end
    end)
    frame:Hide()

    function renderer:Clear()
        for i = #self.lines, 1, -1 do
            recycle(self, i)
        end
        frame:Hide()
    end

    local function showLine(self, pattern, value, critical)
        local saved = BT.db.areas[area.key]
        if not saved.enabled then
            return true
        end
        if #self.lines == MAX_LINES then
            recycle(self, 1)
        end
        local line = table.remove(self.pool)
        if not line then
            line = { text = frame:CreateFontString(nil, "OVERLAY") }
            if not area.format then
                line.text:SetWidth(300 * scale)
                line.text:SetWordWrap(true)
            end
        end
        line.critical = critical
        style(line, saved, scale)
        -- Let the UI format protected amounts directly when the client allows it.
        if not pcall(line.text.SetFormattedText, line.text, pattern, value) then
            line.text:SetText("")
            self.pool[#self.pool + 1] = line
            return false
        end
        self.nextLane = ((self.nextLane or -1) + 1) % 3
        line.lane = self.nextLane
        line.age = 0
        position(line, 0)
        line.text:SetAlpha(1)
        line.text:Show()
        self.lines[#self.lines + 1] = line
        frame:Show()
        return true
    end

    function renderer:ShowAmount(amount, critical)
        if not secret(amount) then
            if type(amount) ~= "number" or amount <= 0 then
                return false
            end
            if amount < BT.db.minimumAmount then
                return true
            end
        end
        local pattern = critical and (area.format .. " !") or area.format
        return showLine(self, pattern, amount, critical)
    end

    function renderer:ShowOutcome(outcome, amount)
        if secret(amount) or (type(amount) == "number" and amount > 0 and amount >= BT.db.minimumAmount) then
            if showLine(self, area.format .. " (" .. outcome .. ")", amount, false) then
                return
            end
        end
        showLine(self, "%s", outcome, false)
    end

    function renderer:ShowMessage(message)
        if secret(message) or (type(message) == "string" and message ~= "") then
            showLine(self, "%s", message, false)
        end
    end

    return renderer
end

local outcomes = {
    MISS = "Miss",
    DODGE = "Dodge",
    PARRY = "Parry",
    BLOCK = "Block",
    ABSORB = "Absorb",
    RESIST = "Resist",
    IMMUNE = "Immune",
    DEFLECT = "Deflect",
    REFLECT = "Reflect",
}

local eventTypes = {
    DAMAGE = { "incoming", 1 },
    SPELL_DAMAGE = { "incoming", 1 },
    DAMAGE_CRIT = { "incoming", 1, true },
    SPELL_DAMAGE_CRIT = { "incoming", 1, true },
    HEAL = { "healing", 2 },
    HEAL_CRIT = { "healing", 2, true },
    PERIODIC_HEAL = { "healing", 2 },
    PERIODIC_HEAL_CRIT = { "healing", 2, true },
}

local lootFormats = {
    "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE",
    "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE",
}
local lootPatterns = {}

local function escapePattern(text)
    return (text:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end

local function loadLootPatterns()
    for _, name in ipairs(lootFormats) do
        local template = _G[name]
        if type(template) == "string" then
            local parts, cursor = { "^" }, 1
            while true do
                local startPos, endPos, kind = template:find("%%[0-9]*%$?([sd])", cursor)
                if not startPos then
                    break
                end
                parts[#parts + 1] = escapePattern(template:sub(cursor, startPos - 1))
                parts[#parts + 1] = kind == "d" and "%d+" or ".+"
                cursor = endPos + 1
            end
            parts[#parts + 1] = escapePattern(template:sub(cursor))
            parts[#parts + 1] = "$"
            lootPatterns[#lootPatterns + 1] = table.concat(parts)
        end
    end
end

local function showLoot(message)
    if secret(message) or type(message) ~= "string" or not message:find("|Hitem:", 1, true) then
        return
    end
    for _, pattern in ipairs(lootPatterns) do
        if message:match(pattern) then
            BT.live.loot:ShowMessage(message)
            return
        end
    end
end

BT.restricted = {}

local function showLive(key, amount, critical)
    if not BT.live[key]:ShowAmount(amount, critical) and secret(amount) then
        BT.restricted[key] = true
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, first, action, descriptor, amount)
    if event == "ADDON_LOADED" then
        if first ~= addonName then
            return
        end
        self:UnregisterEvent(event)
        loadSettings()
        BT.live = {}
        for _, area in ipairs(BT.areas) do
            BT.live[area.key] = BT.CreateRenderer(UIParent, area, 1)
        end
        BT.InitializeSettings()
        loadLootPatterns()
        self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
        self:RegisterEvent("CHAT_MSG_LOOT")
        for combatEvent in pairs(BT.combatMessages) do
            self:RegisterEvent(combatEvent)
        end
        BT.hasCombatText = C_CombatText and C_CombatText.GetCurrentEventInfo
            and pcall(self.RegisterEvent, self, "COMBAT_TEXT_UPDATE")
        if not BT.hasCombatText then
            BT.hasUnitCombat = pcall(self.RegisterUnitEvent, self, "UNIT_COMBAT", "player")
        end
        SLASH_BATTLETEXT1 = "/battletext"
        SlashCmdList.BATTLETEXT = BT.ToggleSettings
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
        BT.live.experience:ShowMessage(first)
    elseif event == "CHAT_MSG_LOOT" then
        showLoot(first)
    elseif BT.combatMessages[event] then
        BT.live.combat:ShowMessage(BT.combatMessages[event])
    elseif event == "COMBAT_TEXT_UPDATE" then
        if secret(first) or type(first) ~= "string" then
            return
        end
        local outcomeType = first:gsub("^SPELL_", "")
        local outcome = outcomes[outcomeType]
        if outcome then
            local amountTaken
            if outcomeType == "BLOCK" or outcomeType == "ABSORB" or outcomeType == "RESIST" then
                local ok, damage, reduction = pcall(C_CombatText.GetCurrentEventInfo)
                if ok and (secret(reduction) or reduction ~= nil) then
                    amountTaken = damage
                end
            end
            BT.live.incoming:ShowOutcome(outcome, amountTaken)
            return
        end
        local info = eventTypes[first]
        if not info then
            return
        end
        local ok, primary, secondary = pcall(C_CombatText.GetCurrentEventInfo)
        if ok then
            local value = primary
            if info[2] == 2 then
                value = secondary
            end
            showLive(info[1], value, info[3])
        end
    elseif event == "UNIT_COMBAT" and not secret(action) then
        local critical = not secret(descriptor) and descriptor == "CRITICAL"
        if action == "WOUND" then
            showLive("incoming", amount, critical)
        elseif action == "HEAL" then
            showLive("healing", amount, critical)
        elseif outcomes[action] then
            BT.live.incoming:ShowOutcome(outcomes[action])
        end
    end
end)
