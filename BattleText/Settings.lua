local _, BT = ...

local motionLabels = { up = "Up", down = "Down", arc = "Arc" }
local nextMotion = { up = "down", down = "arc", arc = "up" }

local function showSamples(renderers, sequence)
    local critical = sequence % 3 == 0
    if sequence % 4 == 0 then
        renderers.incoming:ShowOutcome("Dodge")
    else
        renderers.incoming:ShowAmount(critical and 486 or 162, critical)
    end
    renderers.outgoing:ShowAmount(critical and 912 or 304, critical)
    renderers.healing:ShowAmount(critical and 642 or 214, critical)
    if sequence % 4 == 1 then
        renderers.experience:ShowMessage("+135 XP")
    elseif sequence % 4 == 3 then
        renderers.loot:ShowMessage("Linen Cloth x2")
    elseif sequence % 8 == 2 then
        renderers.combat:ShowMessage(BT.combatMessages.PLAYER_REGEN_DISABLED)
    elseif sequence % 8 == 6 then
        renderers.combat:ShowMessage(BT.combatMessages.PLAYER_REGEN_ENABLED)
    end
end

local function fill(frame, r, g, b, a)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetColorTexture(r, g, b, a or 1)
    return texture
end

local function label(parent, text, font, x, y)
    local region = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    region:SetPoint("TOPLEFT", x, y)
    region:SetText(text)
    return region
end

local function button(parent, name, width, x, y, onClick)
    local control = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    control:SetSize(width, 25)
    control:SetPoint("TOPLEFT", x, y)
    control:SetText(name)
    control:SetScript("OnClick", onClick)
    return control
end

local function slider(parent, name, y, minimum, maximum, step, change)
    local x = 16
    local caption = label(parent, name, "GameFontHighlight", x, y)
    local control = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    control:SetOrientation("HORIZONTAL")
    control:SetSize(233, 18)
    control:SetPoint("TOPLEFT", x, y - 22)
    local track = control:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", 4, 0)
    track:SetPoint("RIGHT", -4, 0)
    track:SetHeight(4)
    track:SetColorTexture(0.23, 0.31, 0.38)
    local thumb = control:CreateTexture(nil, "ARTWORK")
    thumb:SetSize(12, 16)
    thumb:SetColorTexture(0.39, 0.86, 0.81)
    control:SetThumbTexture(thumb)
    control:SetMinMaxValues(minimum, maximum)
    control:SetValueStep(step)
    control:SetObeyStepOnDrag(true)
    control:EnableMouseWheel(true)
    control:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(self:GetValue() + delta * step)
    end)
    local refreshing
    local function update(_, current)
        if not refreshing then
            change(current)
        end
        caption:SetFormattedText("%s   |cff8ce0d7%g|r", name, current)
    end
    control:SetScript("OnValueChanged", update)
    return function(value)
        refreshing = true
        control:SetValue(value)
        update(control, value)
        refreshing = false
    end
end

local function checkbox(parent, text, x, y, change)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", x, y)
    label(check, text, "GameFontHighlight", 27, -6)
    check:SetScript("OnClick", function(self) change(self:GetChecked()) end)
    return check
end

local function place(area, handle, preview)
    local saved = BT.db.areas[area.key]
    local maxX = math.max(0, (UIParent:GetWidth() - handle:GetWidth()) / 2)
    local maxY = math.max(0, (UIParent:GetHeight() - handle:GetHeight()) / 2)
    local x = math.min(maxX, math.max(-maxX, saved.x))
    local y = math.min(maxY, math.max(-maxY, saved.y))
    handle:ClearAllPoints()
    handle:SetPoint("CENTER", UIParent, "CENTER", x, y)
    local anchor = BT.live[area.key].frame
    anchor:ClearAllPoints()
    anchor:SetPoint("CENTER", handle, "CENTER")
    if preview then
        local frame = preview.frame
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", frame:GetParent(), "CENTER",
            x / math.max(1, UIParent:GetWidth()) * 250, y / math.max(1, UIParent:GetHeight()) * 160 - 18)
    end
end

local function makeHandle(area, preview)
    local handle = CreateFrame("Frame", nil, UIParent)
    handle:SetSize(158, 32)
    handle:SetFrameStrata("DIALOG")
    handle:SetClampedToScreen(true)
    handle:SetMovable(true)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    fill(handle, 0.08, 0.16, 0.20, 0.97)
    local caption = handle:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    caption:SetPoint("CENTER")
    caption:SetText(area.label)

    local function endDrag(self)
        if not self.dragging then
            return
        end
        self.dragging = nil
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local centerX, centerY = UIParent:GetCenter()
        if x and centerX then
            local saved = BT.db.areas[area.key]
            saved.x, saved.y = x - centerX, y - centerY
        end
        place(area, self, preview)
    end
    handle:SetScript("OnDragStart", function(self)
        self.dragging = true
        self:StartMoving()
    end)
    handle:SetScript("OnDragStop", endDrag)
    handle:SetScript("OnHide", endDrag)
    place(area, handle, preview)
    handle:Hide()
    return handle
end

function BT.InitializeSettings()
    local panel = CreateFrame("Frame", "BattleTextSettings", UIParent)
    panel:SetSize(758, 480)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    fill(panel, 0.045, 0.07, 0.09, 0.98)
    label(panel, "BattleText", "GameFontNormalHuge", 24, -19):SetTextColor(0.64, 0.96, 0.90)
    local active = label(panel, "", "GameFontHighlight", 24, -53)
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    tinsert(UISpecialFrames, panel:GetName())

    local preview = CreateFrame("Frame", nil, panel)
    preview:SetPoint("TOPLEFT", 400, -112)
    preview:SetSize(334, 310)
    fill(preview, 0.075, 0.11, 0.14)
    label(preview, "Live preview", "GameFontHighlight", 15, -14)
    local reticle = preview:CreateTexture(nil, "ARTWORK")
    reticle:SetSize(7, 7)
    reticle:SetPoint("CENTER", 0, -7)
    reticle:SetColorTexture(0.33, 0.51, 0.57)

    local pages, tabs = {}, {}
    for index, title in ipairs({ "General", "Text Areas", "Profiles" }) do
        local page = CreateFrame("Frame", nil, panel)
        page:SetSize(350, 310)
        page:SetPoint("TOPLEFT", 24, -112)
        fill(page, 0.075, 0.11, 0.14)
        pages[index] = page
        tabs[index] = button(panel, title, 104, 24 + (index - 1) * 111, -77, function()
            for i, section in ipairs(pages) do
                section:SetShown(section == page)
                tabs[i]:SetEnabled(section ~= page)
            end
        end)
        page:SetShown(index == 1)
    end
    tabs[1]:Disable()
    local general, areasPage, profilesPage = unpack(pages)
    local setSize = slider(general, "Text size", -20, 16, 40, 1, function(value) BT.db.size = value end)
    local setSpeed = slider(general, "Scroll speed", -75, 0.5, 2, 0.1, function(value) BT.db.speed = value end)
    local setMinimum = slider(general, "Minimum amount", -130, 0, 1000, 10,
        function(value) BT.db.minimumAmount = value end)
    label(general, "0 shows all damage and healing amounts.", "GameFontHighlightSmall", 16, -174)
    local holdCritical = checkbox(general, "Hold critical hits and heals", 14, -202,
        function(checked) BT.db.holdCritical = checked end)

    local handles, renderers, worldPreview = {}, {}, {}
    local moving = CreateFrame("Frame", nil, UIParent)
    moving:SetSize(280, 62)
    moving:SetPoint("TOP", 0, -78)
    moving:SetFrameStrata("FULLSCREEN_DIALOG")
    moving:Hide()
    fill(moving, 0.045, 0.07, 0.09, 0.98)
    label(moving, "Layout preview  |  Drag text areas", "GameFontHighlight", 12, -9)
    button(moving, "Done moving", 134, 73, -29, function()
        moving:Hide()
        panel:Show()
    end)
    local moveElapsed, moveSequence
    moving:SetScript("OnShow", function()
        moveElapsed, moveSequence = 1.25, 0
    end)
    moving:SetScript("OnUpdate", function(_, delta)
        moveElapsed = moveElapsed + delta
        if moveElapsed >= 1.25 then
            moveElapsed = 0
            moveSequence = moveSequence + 1
            showSamples(worldPreview, moveSequence)
        end
    end)
    moving:SetScript("OnHide", function()
        for key, handle in pairs(handles) do
            worldPreview[key]:Clear()
            handle:Hide()
        end
    end)

    local reset = button(areasPage, "Reset positions", 119, 152, -268)
    button(areasPage, "Move text areas", 128, 16, -268, function()
        panel:Hide()
        moving:Show()
        for _, handle in pairs(handles) do
            handle:Show()
        end
    end)
    local selectedArea = BT.areas[1]
    local areaButtons = {}
    local refreshArea
    for index, area in ipairs(BT.areas) do
        areaButtons[area.key] = button(areasPage, area.label, 146, 16, -18 - (index - 1) * 36, function()
            selectedArea = area
            refreshArea()
        end)
        local renderer = BT.CreateRenderer(preview, area, 0.72)
        renderers[area.key] = renderer
        local handle = makeHandle(area, renderer)
        handles[area.key] = handle
        local sample = BT.CreateRenderer(handle, area, 1)
        sample.frame:SetPoint("CENTER", handle, "CENTER")
        worldPreview[area.key] = sample
    end

    local areaTitle = label(areasPage, "", "GameFontNormal", 181, -24)
    local visible = checkbox(areasPage, "Show this area", 178, -51, function(checked)
        local key = selectedArea.key
        BT.db.areas[key].enabled = checked
        if not checked then
            BT.live[key]:Clear()
            renderers[key]:Clear()
        end
    end)
    label(areasPage, "Movement", "GameFontHighlight", 181, -93)
    local motion = button(areasPage, "", 106, 181, -111, function()
        local saved = BT.db.areas[selectedArea.key]
        saved.motion = nextMotion[saved.motion]
        refreshArea()
    end)
    local swatch = button(areasPage, "Text color", 106, 181, -150)
    local color = fill(swatch, 1, 1, 1)
    color:SetSize(12, 12)
    color:ClearAllPoints()
    color:SetPoint("RIGHT", swatch, "RIGHT", -8, 0)
    color:SetDrawLayer("OVERLAY")
    local profileRevision = 0
    refreshArea = function()
        local saved = BT.db.areas[selectedArea.key]
        areaTitle:SetText(selectedArea.label)
        visible:SetChecked(saved.enabled)
        motion:SetText(motionLabels[saved.motion])
        color:SetColorTexture(unpack(saved.rgb))
        for key, control in pairs(areaButtons) do
            control:SetEnabled(key ~= selectedArea.key)
        end
    end
    swatch:SetScript("OnClick", function()
        local key = selectedArea.key
        local saved = BT.db.areas[key]
        local revision = profileRevision
        local function apply(r, g, b)
            if revision ~= profileRevision then
                return
            end
            saved.rgb[1], saved.rgb[2], saved.rgb[3] = r, g, b
            if selectedArea.key == key then
                color:SetColorTexture(r, g, b)
            end
        end
        ColorPickerFrame:SetupColorPickerAndShow({
            r = saved.rgb[1], g = saved.rgb[2], b = saved.rgb[3],
            swatchFunc = function() apply(ColorPickerFrame:GetColorRGB()) end,
            cancelFunc = function(previous) apply(previous.r, previous.g, previous.b) end,
        })
    end)

    reset:SetScript("OnClick", function()
        for _, area in ipairs(BT.areas) do
            local saved = BT.db.areas[area.key]
            saved.x, saved.y = area.x, area.y
            place(area, handles[area.key], renderers[area.key])
        end
    end)
    local function updateLayout()
        panel:SetScale(math.min(1, UIParent:GetWidth() / 782, UIParent:GetHeight() / 504))
        for _, area in ipairs(BT.areas) do
            local handle = handles[area.key]
            if not handle.dragging then
                place(area, handle, renderers[area.key])
            end
        end
    end
    local display = CreateFrame("Frame")
    display:RegisterEvent("DISPLAY_SIZE_CHANGED")
    display:RegisterEvent("UI_SCALE_CHANGED")
    display:SetScript("OnEvent", updateLayout)

    local refreshProfiles = BT.InitializeProfilePage(profilesPage, label, button)
    local status = label(panel, "", "GameFontHighlightSmall", 24, -443)
    status:SetWidth(710)
    status:SetJustifyH("LEFT")
    status:SetTextColor(0.73, 0.80, 0.84)
    local elapsed, sequence = 0, 0
    panel:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < 0.76 then
            return
        end
        elapsed = 0
        sequence = sequence + 1
        showSamples(renderers, sequence)
        if not BT.hasCombatText and not BT.hasUnitCombat then
            status:SetText("Live damage and healing are unavailable on this client.")
        elseif BT.restricted.incoming or BT.restricted.healing then
            status:SetText("Forever withheld some live amounts. Outgoing damage is preview-only.")
        else
            status:SetText("Outgoing damage is preview-only.")
        end
    end)
    panel:SetScript("OnShow", function() elapsed = 1 end)
    panel:SetScript("OnHide", function()
        for _, renderer in pairs(renderers) do
            renderer:Clear()
        end
    end)
    panel:Hide()

    function BT.RefreshProfile()
        profileRevision = profileRevision + 1
        setSize(BT.db.size)
        setSpeed(BT.db.speed)
        setMinimum(BT.db.minimumAmount)
        holdCritical:SetChecked(BT.db.holdCritical)
        active:SetText("Active profile   " .. BT.activeProfile)
        refreshArea()
        refreshProfiles()
        updateLayout()
        for key, renderer in pairs(renderers) do
            renderer:Clear()
            worldPreview[key]:Clear()
            BT.live[key]:Clear()
        end
        elapsed, sequence = 1, 0
    end
    BT.RefreshProfile()

    function BT.ToggleSettings()
        if moving:IsShown() then
            moving:Hide()
            panel:Show()
        else
            panel:SetShown(not panel:IsShown())
        end
    end
end
