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

local spellLockDuration = 24

local function UpdatePosition()
    local bar = FocusFrameSpellBar
    if not bar then return end
    container:ClearAllPoints()
    container:SetPoint("RIGHT", bar, "LEFT", -40, -4)
end

local FADE_OUT_TIME = 1

local fadeTimer

local function IsFocusCasting()
    return UnitCastingInfo("focus") or UnitChannelInfo("focus")
end

local function UpdateVisibility()
    if IsFocusCasting() then
        if fadeTimer then
            fadeTimer:Cancel()
            fadeTimer = nil
        end
        UpdatePosition()
        container:Show()
    else
        if not container:IsShown() then return end
        if fadeTimer then return end
        fadeTimer = C_Timer.NewTimer(FADE_OUT_TIME, function()
            container:Hide()
            fadeTimer = nil
        end)
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_FOCUS_CHANGED")
events:RegisterUnitEvent("UNIT_SPELLCAST_START", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "pet")

events:SetScript("OnEvent", function(_, event, _, _, spellId)
    if event == "PLAYER_LOGIN" then
        local base = GetSpellBaseCooldown(SPELL_LOCK_ID)
        if base and base > 0 then
            spellLockDuration = base / 1000
        end
        icon:SetTexture(C_Spell.GetSpellTexture(SPELL_LOCK_ID))
        UpdateVisibility()
    elseif event == "PLAYER_FOCUS_CHANGED"
        or event == "UNIT_SPELLCAST_START"
        or event == "UNIT_SPELLCAST_CHANNEL_START"
        or event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_CHANNEL_STOP"
        or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_INTERRUPTED"
    then
        UpdateVisibility()
    elseif spellId == SPELL_LOCK_ID then
        cooldown:SetCooldown(GetTime(), spellLockDuration)
    end
end)
