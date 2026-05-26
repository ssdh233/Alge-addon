local SPELL_LOCK_ID = 19647

local container = CreateFrame("Frame", nil, UIParent)
container:SetSize(40, 40)
container:SetFrameStrata("HIGH")
container:Hide()

local icon = container:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints(container)
icon:SetTexture(C_Spell.GetSpellTexture(SPELL_LOCK_ID))

local cooldown = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate")
cooldown:SetAllPoints(container)
cooldown:SetDrawSwipe(true)
cooldown:SetHideCountdownNumbers(false)

local function UpdatePosition()
    local bar = FocusFrameSpellBar
    if not bar then return end
    container:ClearAllPoints()
    container:SetPoint("RIGHT", bar, "LEFT", -40, -4)
end

local function UpdateCooldown()
    local info = C_Spell.GetSpellCooldown(SPELL_LOCK_ID)
    if info and info.startTime and info.startTime > 0 then
        cooldown:SetCooldown(info.startTime, info.duration)
    else
        cooldown:Clear()
    end
end

local function IsFocusCasting()
    return UnitCastingInfo("focus") or UnitChannelInfo("focus")
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_FOCUS_CHANGED")
events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
events:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "focus")

events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        UpdatePosition()
        icon:SetTexture(C_Spell.GetSpellTexture(SPELL_LOCK_ID))
        if IsFocusCasting() then
            UpdateCooldown()
            container:Show()
        end
    elseif event == "PLAYER_FOCUS_CHANGED" then
        if IsFocusCasting() then
            UpdatePosition()
            UpdateCooldown()
            container:Show()
        else
            container:Hide()
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if container:IsShown() then
            UpdateCooldown()
        end
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        UpdatePosition()
        UpdateCooldown()
        container:Show()
    else
        container:Hide()
    end
end)
