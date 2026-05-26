local CASTBAR_WIDTH = 180
local CASTBAR_HEIGHT = 11

local castBar = CreateFrame("StatusBar", "AlgePetCastBarFrame", UIParent)
castBar:SetSize(CASTBAR_WIDTH, CASTBAR_HEIGHT)
castBar:SetFrameStrata("HIGH")
castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
castBar:SetMinMaxValues(0, 1)
castBar:SetValue(0)
castBar:Hide()

castBar.bg = castBar:CreateTexture(nil, "BACKGROUND")
castBar.bg:SetAllPoints(castBar)
castBar.bg:SetColorTexture(0.08, 0.08, 0.08, 0.85)

castBar.border = castBar:CreateTexture(nil, "BORDER")
castBar.border:SetAtlas("ui-castingbar-frame")
castBar.border:SetPoint("TOPLEFT", castBar, "TOPLEFT", -2, 2)
castBar.border:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 2, -2)

castBar.spark = castBar:CreateTexture(nil, "OVERLAY")
castBar.spark:SetAtlas("ui-castingbar-pip")
castBar.spark:SetSize(8, 20)
castBar.spark:Hide()

castBar.text = castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
castBar.text:SetPoint("TOP", castBar, "BOTTOM", 0, -2)
castBar.text:SetText("")

castBar.timeText = castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
castBar.timeText:SetPoint("LEFT", castBar, "RIGHT", 8, 0)
castBar.timeText:SetText("")

local function AnchorCastBar()
    castBar:ClearAllPoints()
    castBar:SetPoint("CENTER", UIParent, "CENTER", 0, -240)
end

local function StopCastBar()
    castBar.casting = nil
    castBar.channeling = nil
    castBar.castID = nil
    castBar:SetValue(0)
    castBar.spark:Hide()
    castBar:Hide()
end

local function StartCast(unit, castGUID)
    local name, _, _, startTimeMS, endTimeMS = UnitCastingInfo(unit)
    if not name then
        return
    end

    castBar.casting = true
    castBar.channeling = nil
    castBar.castID = castGUID
    castBar.startTime = startTimeMS / 1000
    castBar.endTime = endTimeMS / 1000
    castBar.duration = castBar.endTime - castBar.startTime
    castBar.text:SetText(name)
    castBar:SetMinMaxValues(0, castBar.duration)
    castBar:SetStatusBarColor(1.0, 0.72, 0.0)
    castBar:Show()
    castBar.spark:Show()
end

local function StartChannel(unit)
    local name, _, _, startTimeMS, endTimeMS = UnitChannelInfo(unit)
    if not name then
        return
    end

    castBar.casting = nil
    castBar.channeling = true
    castBar.castID = nil
    castBar.startTime = startTimeMS / 1000
    castBar.endTime = endTimeMS / 1000
    castBar.duration = castBar.endTime - castBar.startTime
    castBar.text:SetText(name)
    castBar:SetMinMaxValues(0, castBar.duration)
    castBar:SetStatusBarColor(0.2, 0.65, 1.0)
    castBar:Show()
    castBar.spark:Show()
end

castBar:SetScript("OnUpdate", function(self)
    if not (self.casting or self.channeling) then
        return
    end

    local now = GetTime()
    local elapsed

    if self.casting then
        elapsed = now - self.startTime
        if elapsed >= self.duration then
            StopCastBar()
            return
        end
        self:SetValue(elapsed)
        self.timeText:SetFormattedText("%.1f", self.duration - elapsed)
    else
        elapsed = self.endTime - now
        if elapsed <= 0 then
            StopCastBar()
            return
        end
        self:SetValue(elapsed)
        self.timeText:SetFormattedText("%.1f", elapsed)
    end

    local width = self:GetWidth()
    local minValue, maxValue = self:GetMinMaxValues()
    local value = self:GetValue()
    local pct = (maxValue > minValue) and ((value - minValue) / (maxValue - minValue)) or 0
    local x = pct * width
    self.spark:ClearAllPoints()
    self.spark:SetPoint("CENTER", self, "LEFT", x, 0)
end)

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterUnitEvent("UNIT_SPELLCAST_START", "pet")
events:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "pet")
events:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "pet")
events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "pet")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "pet")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "pet")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "pet")
events:SetScript("OnEvent", function(_, event, unit, castGUID)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        AnchorCastBar()
        if PlayerCastingBarFrame then
            hooksecurefunc(PlayerCastingBarFrame, "Show", AnchorCastBar)
            hooksecurefunc(PlayerCastingBarFrame, "Hide", AnchorCastBar)
        end
        return
    end

    if unit ~= "pet" then
        return
    end

    if event == "UNIT_SPELLCAST_START" then
        StartCast(unit, castGUID)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        StartChannel(unit)
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        StopCastBar()
    end
end)
