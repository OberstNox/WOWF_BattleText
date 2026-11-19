local addonName, BT = ...

BT.areas = {
    { key = "incoming", label = "Incoming damage", x = -245, y = 45, rgb = { 1, 0.48, 0.45 }, format = "-%d", circleSide = -1 },
    { key = "outgoing", label = "NPC target damage", x = 245, y = 45, rgb = { 1, 1, 1 },
        criticalRGB = { 1, 0.86, 0.12 }, format = "%d", circleSide = 1 },
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
local CRITICAL_HOLD_SECONDS = 0.6
local FONT = STANDARD_TEXT_FONT
local CIRCLE_RADIUS_X, CIRCLE_RADIUS_Y = 220, 122
local CIRCLE_START = math.rad(35)
local CIRCLE_SWEEP = math.pi - 2 * CIRCLE_START
local CIRCLE_START_X = CIRCLE_RADIUS_X * math.sin(CIRCLE_START)
local CIRCLE_START_Y = CIRCLE_RADIUS_Y * math.cos(CIRCLE_START)

function BT.AreaStart(area, motion)
    if motion == "circleDown" and area.circleSide then
        return area.circleSide * CIRCLE_START_X, CIRCLE_START_Y
    end
    return area.x, area.y
end

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

function BT.NormalizeProfile(profile)
    local db = tableOrEmpty(profile)
    db.size = number(db.size, 26, 16, 40)
    db.speed = number(db.speed, 1, 0.5, 2)
    db.minimumAmount = number(db.minimumAmount, 0, 0, 1000)
    db.holdCritical = db.holdCritical == true
    db.groupTargetDamage = nil
    local defaultMotion = db.scrollDown == true and "arc" or "up"
    db.areas = tableOrEmpty(db.areas)
    for _, area in ipairs(BT.areas) do
        local saved = tableOrEmpty(db.areas[area.key])
        local rgb = tableOrEmpty(saved.rgb)
        if not db.damageColorsUpdated and area.key == "outgoing" and rgb[1] == 1 and rgb[2] == 0.79 and rgb[3] == 0.43 then
            rgb = area.rgb
        end
        saved.rgb = {}
        for i = 1, 3 do
            saved.rgb[i] = number(rgb[i], area.rgb[i], 0, 1)
        end
        saved.x = number(saved.x, area.x, -10000, 10000)
        saved.y = number(saved.y, area.y, -10000, 10000)
        saved.enabled = saved.enabled ~= false
        saved.size = number(saved.size, nil, 16, 64)
        if saved.motion ~= "up" and saved.motion ~= "down" and saved.motion ~= "arc"
            and not (saved.motion == "circleDown" and area.circleSide) then
            saved.motion = defaultMotion
        end
        local previous = saved.beforeCircle
        if saved.motion == "circleDown" and type(previous) == "table"
            and (previous.motion == "up" or previous.motion == "down" or previous.motion == "arc") then
            previous.x = number(previous.x, area.x, -10000, 10000)
            previous.y = number(previous.y, area.y, -10000, 10000)
        else
            saved.beforeCircle = nil
        end
        db.areas[area.key] = saved
    end
    db.scrollDown = nil
    db.damageColorsUpdated = true
    return db
end

local function style(line, saved, scale)
    local size = math.floor((saved.size or BT.db.size) * scale * line.emphasis + 0.5)
    if line.fontSize ~= size then
        line.text:SetFont(FONT, size, "OUTLINE")
        line.fontSize = size
        line.height = nil
    end
    line.text:SetTextColor(unpack(line.criticalColor or saved.rgb))
end

local function recycle(renderer, index)
    local line = table.remove(renderer.lines, index)
    line.text:Hide()
    line.text:SetText("")
    renderer.pool[#renderer.pool + 1] = line
end

function BT.CreateRenderer(parent, area, scale, circleScale)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(1, 1)
    local renderer = { frame = frame, lines = {}, pool = {}, area = area }
    local function position(line, progress, motion)
        local x = (line.lane - 1) * 36
        local y = 66 * progress + line.lane * 20
        if motion == "circleDown" and area.circleSide then
            local angle = CIRCLE_START + CIRCLE_SWEEP * progress
            local pathScale = circleScale or scale
            x = area.circleSide * (CIRCLE_RADIUS_X * math.sin(angle) - CIRCLE_START_X) * pathScale
                + (line.lane - 1) * 12 * scale
            y = (CIRCLE_RADIUS_Y * math.cos(angle) - CIRCLE_START_Y) * pathScale
            return x, y
        end
        if motion == "arc" then
            x = x + (area.circleSide or 0) * 32 * math.sin(progress * math.pi)
        end
        if motion ~= "up" then
            y = -y
        end
        return x * scale, y * scale
    end

    local function arrange(motion)
        local direction = motion == "up" and 1 or -1
        local nextEdge
        for i = #renderer.lines, 1, -1 do
            local line = renderer.lines[i]
            local x, y = position(line, line.age / 1.65, motion)
            if not line.height then
                local height = line.fontSize
                if not line.protected and line.text.GetStringHeight then
                    local ok, measured = pcall(line.text.GetStringHeight, line.text)
                    if ok and not secret(measured) and type(measured) == "number" and measured == measured then
                        height = math.max(height, measured)
                    end
                end
                line.height = height
            end
            local halfHeight = line.height / 2
            local travel = y * direction
            local spaced = nextEdge and math.max(travel, nextEdge + halfHeight) or travel
            if spaced - travel <= 130 * scale then
                line.text:SetPoint("CENTER", frame, "CENTER", x, spaced * direction)
                line.text:Show()
                nextEdge = spaced + halfHeight + 4 * scale
            else
                line.text:Hide()
            end
        end
    end

    frame:SetScript("OnUpdate", function(self, elapsed)
        local saved = BT.db.areas[area.key]
        for i = #renderer.lines, 1, -1 do
            local line = renderer.lines[i]
            local held = math.min(line.hold, elapsed)
            line.hold = line.hold - held
            line.age = line.age + (elapsed - held) * BT.db.speed
            if line.age >= 1.65 or not saved.enabled then
                recycle(renderer, i)
            else
                style(line, saved, scale)
                local progress = line.age / 1.65
                line.text:SetAlpha(math.min(1, (1 - progress) * 3.5))
            end
        end
        if #renderer.lines == 0 then
            self:Hide()
        else
            arrange(saved.motion)
        end
    end)
    frame:Hide()

    function renderer:Clear()
        for i = #self.lines, 1, -1 do
            recycle(self, i)
        end
        frame:Hide()
    end

    local function showLine(self, pattern, value, critical, emphasis)
        local saved = BT.db.areas[area.key]
        if not saved.enabled then
            return true
        end
        local line = table.remove(self.pool)
        if not line then
            line = { text = frame:CreateFontString(nil, "OVERLAY") }
            if not area.format then
                line.text:SetWidth(300 * scale)
                line.text:SetWordWrap(true)
            end
        end
        line.emphasis = emphasis or 1
        line.criticalColor = critical and area.criticalRGB or nil
        line.protected = secret(value)
        line.height = nil
        style(line, saved, scale)
        -- Let the UI format protected amounts directly when the client allows it.
        if not pcall(line.text.SetFormattedText, line.text, pattern, value) then
            line.text:SetText("")
            self.pool[#self.pool + 1] = line
            return false
        end
        if #self.lines == MAX_LINES then
            recycle(self, 1)
        end
        self.nextLane = ((self.nextLane or -1) + 1) % 3
        line.lane = self.nextLane
        line.age = 0
        line.hold = critical and BT.db.holdCritical and CRITICAL_HOLD_SECONDS or 0
        line.text:SetAlpha(1)
        self.lines[#self.lines + 1] = line
        arrange(saved.motion)
        frame:Show()
        return true
    end

    function renderer:ShowAmount(amount, critical)
        local protected = secret(amount)
        if not protected then
            if type(amount) ~= "number" or amount ~= amount or amount <= 0 or amount == math.huge then
                return false
            end
            if amount < BT.db.minimumAmount then
                return true
            end
        end
        local pattern = critical and (area.format .. " !") or area.format
        local emphasis = critical and 1.28 or 1
        if critical and area.circleSide then
            emphasis = protected and 1.42 or 1.28 + math.min(amount / 500, 1) * 0.52
        end
        return showLine(self, pattern, amount, critical, emphasis)
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
    EVADE = "Evade",
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

local targetDamage = { events = 0, wounds = 0, accepted = 0 }

local function register(method, frame, event, ...)
    local ok, registered = pcall(method, frame, event, ...)
    return ok and registered == true
end

local function registerTargetDamage()
    local targetEvents = CreateFrame("Frame")
    BT.hasTargetDamage = register(targetEvents.RegisterUnitEvent, targetEvents, "UNIT_COMBAT", "target")
    if not BT.hasTargetDamage then
        BT.hasTargetDamage = register(targetEvents.RegisterEvent, targetEvents, "UNIT_COMBAT")
    end
    targetEvents:RegisterEvent("PLAYER_TARGET_CHANGED")
    local knownNPC
    local function checkTarget()
        local attackable = UnitCanAttack("player", "target")
        local playerControlled = UnitPlayerControlled("target")
        if (not secret(attackable) and not attackable) or (not secret(playerControlled) and playerControlled) then
            knownNPC = false
        elseif not secret(attackable) and not secret(playerControlled) then
            knownNPC = true
        end
    end
    checkTarget()
    targetEvents:SetScript("OnEvent", function(_, event, unit, action, flag, amount)
        if event == "PLAYER_TARGET_CHANGED" then
            knownNPC = nil
            checkTarget()
            return
        end
        if secret(unit) or unit ~= "target" then
            return
        end
        targetDamage.events = targetDamage.events + 1
        if secret(action) or type(action) ~= "string" then
            return
        end
        local outcome = outcomes[action]
        if action == "WOUND" then
            targetDamage.wounds = targetDamage.wounds + 1
        elseif not outcome then
            return
        end
        checkTarget()
        if not knownNPC then
            return
        end
        if outcome then
            BT.live.outgoing:ShowOutcome(outcome)
        else
            targetDamage.accepted = targetDamage.accepted + 1
            showLive("outgoing", amount, not secret(flag) and flag == "CRITICAL")
        end
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, first, action, descriptor, amount)
    if event == "ADDON_LOADED" then
        if first ~= addonName then
            return
        end
        self:UnregisterEvent(event)
        if not IsLoggedIn() then
            self:RegisterEvent("PLAYER_LOGIN")
            return
        end
    end
    if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        BT.LoadProfiles()
        BT.live = {}
        for _, area in ipairs(BT.areas) do
            local renderer = BT.CreateRenderer(UIParent, area, 1)
            local saved = BT.db.areas[area.key]
            renderer.frame:SetPoint("CENTER", UIParent, "CENTER", saved.x, saved.y)
            BT.live[area.key] = renderer
        end
        registerTargetDamage()
        loadLootPatterns()
        self:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN")
        self:RegisterEvent("CHAT_MSG_LOOT")
        for combatEvent in pairs(BT.combatMessages) do
            self:RegisterEvent(combatEvent)
        end
        BT.hasCombatText = C_CombatText and C_CombatText.GetCurrentEventInfo
            and register(self.RegisterEvent, self, "COMBAT_TEXT_UPDATE")
        if not BT.hasCombatText then
            BT.hasUnitCombat = register(self.RegisterUnitEvent, self, "UNIT_COMBAT", "player")
        end
        SLASH_BATTLETEXT1 = "/battletext"
        SlashCmdList.BATTLETEXT = function(input)
            local command = (input or ""):match("^%s*(.-)%s*$")
            if command == "status" then
                local area = BT.db.areas.outgoing
                print(("BattleText NPC target: %s; area %s; group %s; minimum %g. Events %d, wounds %d, accepted %d. Protected amount rejected: %s."):format(
                    BT.hasTargetDamage and "registered" or "unavailable", area.enabled and "on" or "off",
                    IsInGroup() and "yes" or "no", BT.db.minimumAmount,
                    targetDamage.events, targetDamage.wounds, targetDamage.accepted,
                    BT.restricted.outgoing and "yes" or "no"))
                return
            end
            if command == "test" then
                local count = 0
                for _, area in ipairs(BT.areas) do
                    if BT.db.areas[area.key].enabled then
                        BT.live[area.key]:ShowMessage("Test: " .. area.label)
                        count = count + 1
                    end
                end
                print(("BattleText: testing %d enabled areas in profile %s."):format(count, BT.activeProfile))
                return
            end
            if BT.ToggleSettings then
                BT.ToggleSettings()
            else
                print("BattleText: the settings window could not be initialized.")
            end
        end
        BT.InitializeSettings()
        BT.InitializeMinimapButton()
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
    elseif event == "UNIT_COMBAT" and not secret(action) and type(action) == "string" then
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
