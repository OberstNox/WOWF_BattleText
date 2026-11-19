local addonName, BT = ...

local ICON = "Interface\\AddOns\\BattleText\\Icon"

function BT.InitializeMinimapButton()
    if not Minimap then
        return
    end

    local control = CreateFrame("Button", "BattleTextMinimapButton", Minimap)
    control:SetSize(28, 28)
    control:SetFrameStrata("MEDIUM")
    control:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    control:SetNormalTexture(ICON)
    control:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    control:RegisterForClicks("LeftButtonUp")
    control:RegisterForDrag("LeftButton")

    local angle = BattleTextDB.minimapAngle
    if type(angle) ~= "number" or not (angle >= -math.pi and angle <= math.pi) then
        angle = math.rad(135)
    end
    local function placeButton()
        control:ClearAllPoints()
        control:SetPoint("CENTER", Minimap, "CENTER",
            (Minimap:GetWidth() / 2 + 2) * math.cos(angle),
            (Minimap:GetHeight() / 2 + 2) * math.sin(angle))
    end
    local function dragButton()
        local x, y = GetCursorPosition()
        local centerX, centerY = Minimap:GetCenter()
        if centerX and centerY then
            local scale = Minimap:GetEffectiveScale()
            angle = math.atan2(y / scale - centerY, x / scale - centerX)
            placeButton()
        end
    end
    control:SetScript("OnClick", BT.ToggleSettings)
    control:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", dragButton)
    end)
    control:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        BattleTextDB.minimapAngle = angle
    end)
    control:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("BattleText")
        GameTooltip:AddLine("Click to open settings. Drag to move.", 1, 1, 1)
        GameTooltip:Show()
    end)
    control:SetScript("OnLeave", function() GameTooltip:Hide() end)
    placeButton()
end

local motionLabels = { up = "Up", down = "Down", arc = "Arc", circleDown = "Circle Down" }
local nextMotion = { up = "down", down = "arc", arc = "up", circleDown = "up" }

local previewAmounts = {
    incoming = { 162, 486 },
    outgoing = { 304, 912 },
    healing = { 214, 642 },
}

local function showAreaSample(renderer, area, critical)
    local amounts = previewAmounts[area.key]
    if amounts then
        renderer:ShowAmount(amounts[critical and 2 or 1], critical)
    elseif area.key == "experience" then
        renderer:ShowMessage("+135 XP")
    elseif area.key == "loot" then
        renderer:ShowMessage("Linen Cloth x2")
    else
        renderer:ShowMessage(critical and BT.combatMessages.PLAYER_REGEN_ENABLED
            or BT.combatMessages.PLAYER_REGEN_DISABLED)
    end
end

local function showSamples(renderers, sequence)
    local critical = sequence % 3 == 0
    if sequence % 4 == 0 then
        renderers.incoming:ShowOutcome("Dodge")
    else
        renderers.incoming:ShowAmount(critical and 486 or 162, critical)
    end
    if sequence % 4 == 2 then
        renderers.outgoing:ShowOutcome("Parry")
    else
        renderers.outgoing:ShowAmount(critical and 912 or 304, critical)
    end
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

local function button(parent, name, width, x, y, onClick, font)
    local control = CreateFrame("Button", nil, parent)
    control:SetSize(width, 25)
    control:SetPoint("TOPLEFT", x, y)
    local surface = fill(control, 0.13, 0.17, 0.22)
    local hover = control:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(0.25, 0.78, 0.70, 0.13)
    local marker = control:CreateTexture(nil, "ARTWORK")
    marker:SetPoint("TOPLEFT", 0, -3)
    marker:SetPoint("BOTTOMLEFT", 0, 3)
    marker:SetWidth(2)
    marker:SetColorTexture(0.36, 0.86, 0.77)
    local caption = control:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    caption:SetPoint("LEFT", 8, 0)
    caption:SetPoint("RIGHT", -8, 0)
    caption:SetWordWrap(false)
    control:SetFontString(caption)
    control:SetText(name)
    control:SetScript("OnClick", onClick)
    local function update(self)
        marker:SetShown(self.selected == true)
        if self.selected then
            surface:SetColorTexture(0.13, 0.27, 0.29)
            caption:SetTextColor(0.80, 1, 0.96)
        elseif self:IsEnabled() then
            surface:SetColorTexture(0.13, 0.17, 0.22)
            caption:SetTextColor(0.90, 0.93, 0.97)
        else
            surface:SetColorTexture(0.095, 0.12, 0.16)
            caption:SetTextColor(0.50, 0.55, 0.62)
        end
    end
    control:SetScript("OnEnable", update)
    control:SetScript("OnDisable", update)
    function control:SetSelected(selected)
        self.selected = selected
        self:SetEnabled(not selected)
        update(self)
    end
    update(control)
    return control
end

local function slider(parent, name, y, minimum, maximum, step, change, x, width)
    x = x or 16
    local caption = label(parent, name, "GameFontHighlight", x, y)
    local control = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    control:SetOrientation("HORIZONTAL")
    control:SetSize(width or 233, 18)
    control:SetPoint("TOPLEFT", x, y - 22)
    control:EnableMouse(true)
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
    local function setValue(value)
        refreshing = true
        control:SetValue(value)
        update(control, value)
        refreshing = false
    end
    return setValue
end

local function checkbox(parent, text, x, y, labelWidth, change)
    local check = CreateFrame("CheckButton", nil, parent)
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", x, y)
    check:SetHitRectInsets(0, -labelWidth, 0, 0)
    local outline = check:CreateTexture(nil, "BACKGROUND")
    outline:SetSize(16, 16)
    outline:SetPoint("CENTER")
    outline:SetColorTexture(0.21, 0.29, 0.36)
    local mark = check:CreateTexture(nil, "ARTWORK")
    mark:SetSize(10, 10)
    mark:SetPoint("CENTER")
    mark:SetColorTexture(0.36, 0.86, 0.77)
    check:SetCheckedTexture(mark)
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
    anchor:SetPoint("CENTER", UIParent, "CENTER", x, y)
    if preview then
        local frame = preview.frame
        frame:ClearAllPoints()
        local previewX = math.max(-95, math.min(95, x / 2.6))
        local previewY = math.max(-58, math.min(58, y / 3.6))
        frame:SetPoint("CENTER", frame:GetParent(), "CENTER",
            previewX, previewY - 22)
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
    panel:SetSize(858, 420)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    fill(panel, 0.048, 0.064, 0.091, 0.98)
    local border = CreateFrame("Frame", nil, panel)
    border:SetAllPoints(panel)
    border:SetFrameLevel(panel:GetFrameLevel() + 5)
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local edge = border:CreateTexture(nil, "OVERLAY")
        if side == "TOP" or side == "BOTTOM" then
            edge:SetPoint(side .. "LEFT", border)
            edge:SetPoint(side .. "RIGHT", border)
            edge:SetHeight(2)
        else
            edge:SetPoint("TOP" .. side, border)
            edge:SetPoint("BOTTOM" .. side, border)
            edge:SetWidth(2)
        end
        edge:SetColorTexture(0.24, 0.43, 0.45)
    end
    local header = CreateFrame("Frame", nil, panel)
    header:SetSize(858, 54)
    header:SetPoint("TOPLEFT")
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    fill(header, 0.075, 0.10, 0.14)
    label(header, "BattleText", "GameFontNormalLarge", 18, -11):SetTextColor(0.74, 0.98, 0.92)
    local metadata = C_AddOns and C_AddOns.GetAddOnMetadata
    local author = metadata and metadata(addonName, "Author") or "OberstNox"
    local version = metadata and metadata(addonName, "Version")
    label(header, "by " .. author, "GameFontHighlightSmall", 18, -32):SetTextColor(0.66, 0.72, 0.79)
    if version then
        label(header, "v" .. version, "GameFontHighlightSmall", 708, -22):SetTextColor(0.66, 0.72, 0.79)
    end
    local active = label(header, "", "GameFontHighlight", 152, -21)
    active:SetTextColor(0.78, 0.83, 0.90)
    button(header, CLOSE or "Close", 62, 780, -14, function() panel:Hide() end)
    tinsert(UISpecialFrames, panel:GetName())

    local draggingDashboard
    local function stopDashboardDrag()
        if not draggingDashboard then
            return
        end
        draggingDashboard = nil
        panel:StopMovingOrSizing()
        panel:SetUserPlaced(false)
        local x, y = panel:GetCenter()
        local centerX, centerY = UIParent:GetCenter()
        if x and y and centerX and centerY then
            local scale = panel:GetScale()
            BattleTextDB.dashboardPosition = { x = x * scale - centerX, y = y * scale - centerY }
        end
    end
    header:SetScript("OnDragStart", function()
        draggingDashboard = true
        panel:StartMoving()
    end)
    header:SetScript("OnDragStop", stopDashboardDrag)

    local sidebar = CreateFrame("Frame", nil, panel)
    sidebar:SetPoint("TOPLEFT", 16, -66)
    sidebar:SetSize(120, 310)
    fill(sidebar, 0.068, 0.089, 0.122)

    local preview = CreateFrame("Frame", nil, panel)
    preview:SetPoint("TOPLEFT", 514, -66)
    preview:SetSize(328, 310)
    fill(preview, 0.075, 0.10, 0.14)
    label(preview, "Live preview", "GameFontHighlight", 15, -14)
    local previewCaption = label(preview, "", "GameFontHighlightSmall", 15, -37)
    local reticle = preview:CreateTexture(nil, "ARTWORK")
    reticle:SetSize(7, 7)
    reticle:SetPoint("CENTER", 0, -7)
    reticle:SetColorTexture(0.33, 0.51, 0.57)

    local pages, tabs = {}, {}
    local activePage = 1
    local restartPreview, refreshArea
    for index, title in ipairs({ "General", "Text Areas", "Profiles" }) do
        local page = CreateFrame("Frame", nil, panel)
        page:SetSize(350, 310)
        page:SetPoint("TOPLEFT", 150, -66)
        fill(page, 0.075, 0.10, 0.14)
        pages[index] = page
        tabs[index] = button(sidebar, title, 104, 8, -10 - (index - 1) * 33, function()
            activePage = index
            for i, section in ipairs(pages) do
                section:SetShown(section == page)
                tabs[i]:SetSelected(section == page)
            end
            if index == 2 then
                refreshArea()
            end
            restartPreview()
        end)
        page:SetShown(index == 1)
    end
    tabs[1]:SetSelected(true)
    local general, areasPage, profilesPage = unpack(pages)
    label(general, "Text and motion", "GameFontNormal", 16, -16)
    local setSize = slider(general, "Default text size", -43, 16, 40, 1, function(value) BT.db.size = value end)
    local setSpeed = slider(general, "Scroll speed", -92, 0.5, 2, 0.1, function(value) BT.db.speed = value end)
    local holdCritical = checkbox(general, "Hold critical hits and heals", 14, -136, 163,
        function(checked) BT.db.holdCritical = checked end)
    label(general, "Filtering", "GameFontNormal", 16, -183)
    local setMinimum = slider(general, "Minimum damage and healing", -210, 0, 1000, 10,
        function(value) BT.db.minimumAmount = value end)
    label(general, "0 shows all damage and healing amounts.", "GameFontHighlightSmall", 16, -255)

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

    label(areasPage, "Screen layout", "GameFontNormal", 16, -250)
    local reset = button(areasPage, "Reset positions", 100, 234, -274, nil, "GameFontHighlightSmall")
    button(areasPage, "Move text areas", 107, 16, -274, function()
        panel:Hide()
        moving:Show()
        for _, handle in pairs(handles) do
            handle:Show()
        end
    end, "GameFontHighlightSmall")
    local selectedArea = BT.areas[1]
    local areaButtons = {}
    for index, area in ipairs(BT.areas) do
        areaButtons[area.key] = button(areasPage, area.label, 146, 16, -18 - (index - 1) * 33, function()
            selectedArea = area
            refreshArea()
            restartPreview()
        end)
        local renderer = BT.CreateRenderer(preview, area, 0.72, 0.42)
        renderers[area.key] = renderer
        local handle = makeHandle(area, renderer)
        handles[area.key] = handle
        local sample = BT.CreateRenderer(handle, area, 1)
        sample.frame:SetPoint("CENTER", handle, "CENTER")
        worldPreview[area.key] = sample
    end

    local areaTitle = label(areasPage, "", "GameFontNormal", 181, -24)
    local visible = checkbox(areasPage, "Show this area", 178, -51, 106, function(checked)
        local key = selectedArea.key
        BT.db.areas[key].enabled = checked
        if not checked then
            BT.live[key]:Clear()
        end
        restartPreview()
    end)
    label(areasPage, "Movement", "GameFontHighlight", 181, -93)
    local motion = button(areasPage, "", 106, 181, -111, function()
        local saved = BT.db.areas[selectedArea.key]
        saved.motion = saved.motion == "arc" and selectedArea.circleSide and "circleDown" or nextMotion[saved.motion]
        saved.beforeCircle = nil
        refreshArea()
    end)
    local swatch = button(areasPage, "Text color", 149, 181, -150)
    local color = fill(swatch, 1, 1, 1)
    color:SetSize(12, 12)
    color:ClearAllPoints()
    color:SetPoint("RIGHT", swatch, "RIGHT", -8, 0)
    color:SetDrawLayer("OVERLAY")
    local profileRevision = 0
    local useDefault = button(areasPage, "Use default", 84, 181, -230, function()
        BT.db.areas[selectedArea.key].size = nil
        refreshArea()
    end, "GameFontHighlightSmall")
    local setAreaSize = slider(areasPage, "Text size", -184, 16, 64, 1, function(value)
        BT.db.areas[selectedArea.key].size = value
        useDefault:Enable()
    end, 181, 149)
    local defaultSize = label(areasPage, "", "GameFontHighlightSmall", 270, -238)
    local circleToggle
    local function circleEnabled()
        return BT.db.areas.incoming.motion == "circleDown" or BT.db.areas.outgoing.motion == "circleDown"
    end
    refreshArea = function()
        local saved = BT.db.areas[selectedArea.key]
        areaTitle:SetText(selectedArea.label)
        visible:SetChecked(saved.enabled)
        motion:SetText(motionLabels[saved.motion])
        color:SetColorTexture(unpack(saved.rgb))
        swatch:SetText(selectedArea.criticalRGB and "Normal hit color" or "Text color")
        useDefault:SetEnabled(saved.size ~= nil)
        defaultSize:SetFormattedText("Default: %g", BT.db.size)
        setAreaSize(saved.size or BT.db.size)
        circleToggle:SetText(circleEnabled() and "Circle: On" or "Circle: Off")
        for key, control in pairs(areaButtons) do
            control:SetSelected(key == selectedArea.key)
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

    circleToggle = button(areasPage, "", 103, 127, -274, function()
        local enable = not circleEnabled()
        for _, area in ipairs(BT.areas) do
            if area.circleSide then
                local saved = BT.db.areas[area.key]
                if enable then
                    saved.beforeCircle = { motion = saved.motion, x = saved.x, y = saved.y }
                    saved.motion = "circleDown"
                    saved.x, saved.y = BT.AreaStart(area, saved.motion)
                elseif saved.motion == "circleDown" then
                    local previous = saved.beforeCircle
                    saved.motion = previous and previous.motion or "up"
                    saved.x = previous and previous.x or area.x
                    saved.y = previous and previous.y or area.y
                    saved.beforeCircle = nil
                end
                place(area, handles[area.key], renderers[area.key])
                BT.live[area.key]:Clear()
            end
        end
        refreshArea()
        restartPreview()
    end, "GameFontHighlightSmall")
    reset:SetScript("OnClick", function()
        for _, area in ipairs(BT.areas) do
            local saved = BT.db.areas[area.key]
            saved.x, saved.y = BT.AreaStart(area, saved.motion)
            place(area, handles[area.key], renderers[area.key])
        end
    end)
    local function updateLayout()
        if not draggingDashboard then
            local width, height = UIParent:GetWidth(), UIParent:GetHeight()
            local scale = math.min(1, width / 882, height / 444)
            if scale > 0 then
                panel:SetScale(scale)
                local saved = BattleTextDB.dashboardPosition
                local x, y = 0, 0
                if type(saved) == "table" and type(saved.x) == "number" and type(saved.y) == "number" then
                    local maxX = math.max(0, (width - panel:GetWidth() * scale) / 2)
                    local maxY = math.max(0, (height - panel:GetHeight() * scale) / 2)
                    x = math.max(-maxX, math.min(maxX, saved.x))
                    y = math.max(-maxY, math.min(maxY, saved.y))
                end
                panel:ClearAllPoints()
                panel:SetPoint("CENTER", UIParent, "CENTER", x / scale, y / scale)
            end
        end
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
    local status = label(panel, "", "GameFontHighlightSmall", 18, -391)
    status:SetWidth(820)
    status:SetJustifyH("LEFT")
    status:SetTextColor(0.73, 0.80, 0.84)
    local elapsed, sequence = 0, 0
    local previewRenderer
    restartPreview = function()
        if previewRenderer then
            previewRenderer:Clear()
            previewRenderer = nil
        end
        elapsed, sequence = 1, 0
    end
    panel:SetScript("OnUpdate", function(_, delta)
        if previewRenderer and #previewRenderer.lines > 0 then
            return
        end
        elapsed = elapsed + delta
        if elapsed < 0.22 then
            return
        end
        elapsed = 0
        sequence = sequence + 1
        local area = activePage == 2 and selectedArea or BT.areas[(sequence - 1) % #BT.areas + 1]
        local critical = activePage == 2 and sequence % 2 == 0
            or activePage ~= 2 and math.floor((sequence - 1) / #BT.areas) % 2 == 1
        local sampleCycle = activePage == 2 and sequence or math.floor((sequence - 1) / #BT.areas) + 1
        local showParry = area.key == "outgoing" and sampleCycle % 3 == 0
        local caption = area.label
        local amounts = previewAmounts[area.key]
        if not BT.db.areas[area.key].enabled then
            caption = caption .. " (hidden)"
        elseif not showParry and amounts and amounts[critical and 2 or 1] < BT.db.minimumAmount then
            caption = caption .. " (below minimum)"
        end
        previewCaption:SetText(caption)
        previewRenderer = renderers[area.key]
        if showParry then
            previewRenderer:ShowOutcome("Parry")
        else
            showAreaSample(previewRenderer, area, critical)
        end
        if not BT.hasCombatText and not BT.hasUnitCombat then
            status:SetText("Live damage and healing received are unavailable on this client.")
        elseif not BT.hasTargetDamage then
            status:SetText("NPC target damage is unavailable on this client.")
        elseif BT.restricted.incoming or BT.restricted.healing or BT.restricted.outgoing then
            status:SetText("Forever withheld some live amounts. NPC target text may include hits by others.")
        else
            status:SetText("NPC target damage can include hits from pets and other players.")
        end
    end)
    panel:SetScript("OnShow", restartPreview)
    panel:SetScript("OnHide", function()
        stopDashboardDrag()
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
        restartPreview()
    end
    BT.RefreshProfile()

    function BT.ToggleSettings(forceOpen)
        if moving:IsShown() then
            moving:Hide()
            panel:Show()
        else
            panel:SetShown(forceOpen == true or not panel:IsShown())
        end
    end

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local page = CreateFrame("Frame", nil, UIParent)
        page:Hide()
        local logo = page:CreateTexture(nil, "ARTWORK")
        logo:SetSize(44, 44)
        logo:SetPoint("TOPLEFT", 20, -18)
        logo:SetTexture(ICON)
        label(page, "BattleText", "GameFontNormalLarge", 76, -25)
        label(page, "Customize combat text, screen layout and profiles.", "GameFontHighlightSmall", 76, -47)
        local notice = label(page, "", "GameFontHighlightSmall", 20, -110)
        button(page, "Open BattleText", 148, 20, -76, function()
            if SettingsPanel and SettingsPanel:IsShown() and SettingsPanel.Close then
                if SettingsPanel:HasUnappliedSettings() then
                    notice:SetText("Apply your pending WoW settings first.")
                    return
                end
                SettingsPanel:Close(true)
            end
            notice:SetText("")
            BT.ToggleSettings(true)
        end)
        page:SetScript("OnShow", function() notice:SetText("") end)
        local category = Settings.RegisterCanvasLayoutCategory(page, "BattleText")
        Settings.RegisterAddOnCategory(category)
    end
end
