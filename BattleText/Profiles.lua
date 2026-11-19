local _, BT = ...
local DEFAULT = "Default"
local characterKey
local store

local function compareNames(left, right)
    if strcmputf8i then
        return strcmputf8i(left, right)
    end
    left, right = left:lower(), right:lower()
    if left == right then
        return 0
    end
    return left < right and -1 or 1
end

local function activate(name)
    BT.activeProfile = name
    BT.db = store.profiles[name]
    if characterKey then
        store.characters[characterKey] = name
    end
    if BT.RefreshProfile then
        BT.RefreshProfile()
    end
end

function BT.LoadProfiles()
    local saved = type(BattleTextDB) == "table" and BattleTextDB or {}
    if type(saved.profiles) ~= "table" then
        saved = { profiles = { [DEFAULT] = saved }, characters = {} }
    end
    saved.characters = type(saved.characters) == "table" and saved.characters or {}
    saved.profiles[DEFAULT] = BT.NormalizeProfile(saved.profiles[DEFAULT])
    for name, profile in pairs(saved.profiles) do
        if type(name) ~= "string" or type(profile) ~= "table" then
            saved.profiles[name] = nil
        elseif name ~= DEFAULT then
            BT.NormalizeProfile(profile)
        end
    end
    local name, realm = UnitFullName("player")
    realm = realm and realm ~= "" and realm or GetNormalizedRealmName()
    characterKey = type(name) == "string" and name ~= "" and type(realm) == "string" and (realm .. ":" .. name) or nil
    BattleTextDB, store = saved, saved
    local selected = characterKey and saved.characters[characterKey]
    activate(type(selected) == "string" and saved.profiles[selected] and selected or DEFAULT)
end

function BT.ProfileNames()
    local names = {}
    for name in pairs(store.profiles) do
        names[#names + 1] = name
    end
    table.sort(names, function(left, right) return compareNames(left, right) < 0 end)
    return names
end

function BT.SelectProfile(name)
    if store.profiles[name] and name ~= BT.activeProfile then
        activate(name)
    end
end

local function validName(input, except)
    local name = input:match("^%s*(.-)%s*$")
    if name == "" or #name > 40 or name:find("[%c|]") then
        return nil, "Enter a name of 1 to 40 bytes without control characters or |."
    end
    for existing in pairs(store.profiles) do
        if existing ~= except and compareNames(existing, name) == 0 then
            return nil, "A profile with that name already exists."
        end
    end
    return name
end

local function copyProfile(profile)
    local copy = {}
    for key, value in pairs(profile) do
        copy[key] = type(value) == "table" and copyProfile(value) or value
    end
    return copy
end

function BT.CreateProfile(input, copyActive)
    local name, errorMessage = validName(input)
    if not name then
        return errorMessage
    end
    store.profiles[name] = copyActive and copyProfile(BT.db) or BT.NormalizeProfile()
    activate(name)
end

function BT.RenameProfile(input)
    local oldName = BT.activeProfile
    if oldName == DEFAULT then
        return "Default is the reserve profile and keeps its name."
    end
    local name, errorMessage = validName(input, oldName)
    if not name then
        return errorMessage
    end
    if name == oldName then
        return
    end
    store.profiles[name], store.profiles[oldName] = BT.db, nil
    for character, profile in pairs(store.characters) do
        if profile == oldName then
            store.characters[character] = name
        end
    end
    activate(name)
end

function BT.DeleteProfile(name)
    if name == DEFAULT or not store.profiles[name] then
        return
    end
    store.profiles[name] = nil
    for character, profile in pairs(store.characters) do
        if profile == name then
            store.characters[character] = DEFAULT
        end
    end
    if BT.activeProfile == name then
        activate(DEFAULT)
    elseif BT.RefreshProfile then
        BT.RefreshProfile()
    end
end

function BT.InitializeProfilePage(page, label, button)
    local ROWS = 5
    local first = 1
    local names, rows = {}, {}
    local refreshList
    local profileHint = "Characters can share the same profile."
    local feedback = label(page, profileHint, "GameFontHighlightSmall", 16, -276)
    feedback:SetWidth(318)
    feedback:SetJustifyH("LEFT")
    local input = CreateFrame("EditBox", nil, page)
    input:SetSize(318, 24)
    input:SetPoint("TOPLEFT", 16, -200)
    input:SetFontObject(GameFontHighlight)
    input:SetTextInsets(8, 8, 0, 0)
    local inputSurface = input:CreateTexture(nil, "BACKGROUND")
    inputSurface:SetAllPoints()
    inputSurface:SetColorTexture(0.10, 0.10, 0.10)
    input:SetScript("OnEditFocusGained", function() inputSurface:SetColorTexture(0.23, 0.18, 0.14) end)
    input:SetScript("OnEditFocusLost", function() inputSurface:SetColorTexture(0.10, 0.10, 0.10) end)
    input:SetAutoFocus(false)
    input:SetMaxBytes(40)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    for index = 1, ROWS do
        local offset = index - 1
        rows[index] = button(page, "", 318, 16, -12 - offset * 29, function()
            input:SetText("")
            input:ClearFocus()
            BT.SelectProfile(names[first + offset])
        end)
    end
    local previous = button(page, "Previous", 84, 16, -158, function()
        first = first - ROWS
        refreshList()
    end)
    local nextPage = button(page, "Next", 84, 250, -158, function()
        first = first + ROWS
        refreshList()
    end)
    local range = label(page, "", "GameFontHighlightSmall", 114, -165)
    range:SetWidth(122)
    range:SetJustifyH("CENTER")

    refreshList = function()
        for index, row in ipairs(rows) do
            local name = names[first + index - 1]
            row:SetShown(name ~= nil)
            if name then
                row:SetText(name == BT.activeProfile and (name .. " (active)") or name)
                row:SetSelected(name == BT.activeProfile)
            end
        end
        previous:SetEnabled(first > 1)
        nextPage:SetEnabled(first + ROWS <= #names)
        range:SetFormattedText("%d–%d of %d", first, math.min(first + ROWS - 1, #names), #names)
    end

    local function submit(operation)
        local errorMessage = operation(input:GetText())
        feedback:SetText(errorMessage or profileHint)
        if not errorMessage then
            input:SetText("")
            input:ClearFocus()
        end
    end
    label(page, "Profile name", "GameFontHighlightSmall", 16, -186)
    local function create()
        submit(function(name) return BT.CreateProfile(name, false) end)
    end
    input:SetScript("OnEnterPressed", create)
    button(page, "New", 72, 16, -234, create)
    button(page, "Copy active", 85, 92, -234, function()
        submit(function(name) return BT.CreateProfile(name, true) end)
    end)
    local rename = button(page, "Rename", 75, 181, -234, function() submit(BT.RenameProfile) end)
    local delete = button(page, "Delete", 74, 260, -234, function()
        input:ClearFocus()
        StaticPopup_Show("BATTLETEXT_DELETE_PROFILE", BT.activeProfile, nil, BT.activeProfile)
    end)
    StaticPopupDialogs.BATTLETEXT_DELETE_PROFILE = {
        text = "Delete the BattleText profile '%s'? Characters using it will switch to Default.",
        button1 = DELETE,
        button2 = CANCEL,
        OnAccept = function(_, name) BT.DeleteProfile(name) end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    return function()
        names = BT.ProfileNames()
        for index, name in ipairs(names) do
            if name == BT.activeProfile then
                first = math.floor((index - 1) / ROWS) * ROWS + 1
                break
            end
        end
        rename:SetEnabled(BT.activeProfile ~= DEFAULT)
        delete:SetEnabled(BT.activeProfile ~= DEFAULT)
        feedback:SetText(profileHint)
        refreshList()
    end
end
