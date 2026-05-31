-- Shows a sound + center-screen icon when a healer ally uses their PvP trinket in arena.

local NOTIFICATION_DURATION = 3
local FALLBACK_ICON = "Interface\\Icons\\inv_jewelry_trinketpvp_01"

local notifFrame = CreateFrame("Frame", "AlgeHealerTrinketFrame", UIParent)
notifFrame:SetSize(64, 64)
notifFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
notifFrame:SetFrameStrata("HIGH")
notifFrame:Hide()

local tex = notifFrame:CreateTexture(nil, "ARTWORK")
tex:SetAllPoints()

local label = notifFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
label:SetPoint("TOP", notifFrame, "BOTTOM", 0, -4)

local hideTimer

local function ShowAlert(unit)
    local name = UnitName(unit) or unit
    local _, class = UnitClass(unit)
    local color = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
    if color then
        name = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
    end
    label:SetText(name .. " trinket!")

    tex:SetTexture(GetInventoryItemTexture(unit, 14) or FALLBACK_ICON)

    notifFrame:SetAlpha(1)
    notifFrame:Show()

    PlaySound(SOUNDKIT.RAID_WARNING, "Master")

    if hideTimer then
        hideTimer:Cancel()
    end
    hideTimer = C_Timer.NewTimer(NOTIFICATION_DURATION, function()
        UIFrameFadeOut(notifFrame, 0.5, 1, 0)
        C_Timer.After(0.5, function() notifFrame:Hide() end)
    end)
end

local lastTrinketStart = {}

local function CheckUnit(unit)
    if not UnitExists(unit) then
        lastTrinketStart[unit] = nil
        return
    end
    local data = C_PvP.GetArenaCrowdControlDuration(unit)
    if not data or not data.startTime or data.startTime == 0 then
        lastTrinketStart[unit] = nil
        return
    end

    local prev = lastTrinketStart[unit]
    lastTrinketStart[unit] = data.startTime

    if prev ~= nil and data.startTime ~= prev and GetTime() - data.startTime < 2 then
        if UnitGroupRolesAssigned(unit) == "HEALER" then
            ShowAlert(unit)
        end
    end
end

local function CheckAllFriendly()
    CheckUnit("player")
    for i = 1, 4 do
        CheckUnit("party" .. i)
    end
end

function AlgeHealerTrinket_Test()
    ShowAlert("player")
end

local evtFrame = CreateFrame("Frame")
evtFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "ARENA_COOLDOWNS_UPDATE" then
        if unit and unit ~= "" then
            CheckUnit(unit)
        else
            CheckAllFriendly()
        end
    else
        wipe(lastTrinketStart)
    end
end)
evtFrame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
evtFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")
evtFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
evtFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
