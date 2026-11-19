local _, BT = ...

local motionLabels = { up = "Up", down = "Down", arc = "Arc" }
local nextMotion = { up = "down", down = "arc", arc = "up" }

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

local function slider(parent, name, y, minimum, maximum, step, value, change, x)
    x = x or 24
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
    local function update(_, current)
        change(current)
        caption:SetFormattedText("%s   |cff8ce0d7%g|r", name, current)
    end
    control:SetValue(value)
    control:SetScript("OnValueChanged", update)
    update(control, value)
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
    panel:SetSize(650, 488)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    fill(panel, 0.045, 0.07, 0.09, 0.98)
    label(panel, "BattleText", "GameFontNormalHuge", 24, -19):SetTextColor(0.64, 0.96, 0.90)
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    tinsert(UISpecialFrames, panel:GetName())

    local preview = CreateFrame("Frame", nil, panel)
    preview:SetPoint("TOPLEFT", 282, -60)
    preview:SetSize(344, 264)
    fill(preview, 0.075, 0.11, 0.14)
    label(preview, "Live preview", "GameFontHighlight", 15, -14)
    local reticle = preview:CreateTexture(nil, "ARTWORK")
    reticle:SetSize(7, 7)
    reticle:SetPoint("CENTER", 0, -7)
    reticle:SetColorTexture(0.33, 0.51, 0.57)

    slider(panel, "Text size", -67, 16, 40, 1, BT.db.size, function(value) BT.db.size = value end)
    slider(panel, "Scroll speed", -117, 0.5, 2, 0.1, BT.db.speed, function(value) BT.db.speed = value end)
    slider(panel, "Minimum amount", -348, 0, 1000, 10, BT.db.minimumAmount,
        function(value) BT.db.minimumAmount = value end, 282)

    local handles, renderers = {}, {}
    local moving = CreateFrame("Frame", nil, UIParent)
    moving:SetSize(134, 29)
    moving:SetPoint("TOP", 0, -78)
    moving:SetFrameStrata("FULLSCREEN_DIALOG")
    moving:Hide()
    button(moving, "Done moving", 134, 0, 0, function()
        moving:Hide()
        panel:Show()
    end)
    moving:SetScript("OnHide", function()
        for _, handle in pairs(handles) do
            handle:Hide()
        end
    end)

    local reset = button(panel, "Reset positions", 119, 160, -370)
    button(panel, "Move text areas", 128, 24, -370, function()
        panel:Hide()
        moving:Show()
        for _, handle in pairs(handles) do
            handle:Show()
        end
    end)

    for index, area in ipairs(BT.areas) do
        local saved = BT.db.areas[area.key]
        local y = -168 - (index - 1) * 31
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetSize(24, 24)
        check:SetPoint("TOPLEFT", 22, y)
        check:SetChecked(saved.enabled)
        label(check, area.label, "GameFontHighlight", 27, -6)
        check:SetScript("OnClick", function(self)
            saved.enabled = self:GetChecked()
            if not saved.enabled then
                BT.live[area.key]:Clear()
                renderers[area.key]:Clear()
            end
        end)

        button(panel, motionLabels[saved.motion], 62, 164, y, function(self)
            saved.motion = nextMotion[saved.motion]
            self:SetText(motionLabels[saved.motion])
        end)

        local swatch = CreateFrame("Button", nil, panel)
        swatch:SetSize(24, 19)
        swatch:SetPoint("TOPLEFT", 234, y - 2)
        local color = fill(swatch, unpack(saved.rgb))
        swatch:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        swatch:SetScript("OnClick", function()
            local function apply(r, g, b)
                saved.rgb[1], saved.rgb[2], saved.rgb[3] = r, g, b
                color:SetColorTexture(r, g, b)
            end
            ColorPickerFrame:SetupColorPickerAndShow({
                r = saved.rgb[1], g = saved.rgb[2], b = saved.rgb[3],
                swatchFunc = function() apply(ColorPickerFrame:GetColorRGB()) end,
                cancelFunc = function(previous) apply(previous.r, previous.g, previous.b) end,
            })
        end)
        local renderer = BT.CreateRenderer(preview, area, 0.72)
        renderers[area.key] = renderer
        handles[area.key] = makeHandle(area, renderer)
    end

    reset:SetScript("OnClick", function()
        for _, area in ipairs(BT.areas) do
            local saved = BT.db.areas[area.key]
            saved.x, saved.y = area.x, area.y
            place(area, handles[area.key], renderers[area.key])
        end
    end)
    local display = CreateFrame("Frame")
    display:RegisterEvent("DISPLAY_SIZE_CHANGED")
    display:RegisterEvent("UI_SCALE_CHANGED")
    display:SetScript("OnEvent", function()
        for _, area in ipairs(BT.areas) do
            local handle = handles[area.key]
            if not handle.dragging then
                place(area, handle, renderers[area.key])
            end
        end
    end)

    label(panel, "0 shows all damage and healing amounts.", "GameFontHighlightSmall", 282, -408)
    local status = label(panel, "", "GameFontHighlightSmall", 24, -447)
    status:SetWidth(602)
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

    function BT.ToggleSettings()
        if moving:IsShown() then
            moving:Hide()
            panel:Show()
        else
            panel:SetShown(not panel:IsShown())
        end
    end
end
