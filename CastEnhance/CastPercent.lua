local castInfo = {}
local CHANNEL_COMPLETE_THRESHOLD = 0.25

local displayFrame = CreateFrame("Frame", "AlgeCastPercentFrame", UIParent)
displayFrame:SetSize(60, 30)
displayFrame:SetFrameStrata("HIGH")
displayFrame:SetAlpha(0)

local displayText = displayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
displayText:SetAllPoints(displayFrame)
displayText:SetJustifyH("LEFT")

local animGroup = displayFrame:CreateAnimationGroup()
local hold = animGroup:CreateAnimation("Alpha")
hold:SetFromAlpha(1)
hold:SetToAlpha(1)
hold:SetDuration(1.5)
hold:SetOrder(1)
local fadeOut = animGroup:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetDuration(0.5)
fadeOut:SetOrder(2)
animGroup:SetScript("OnFinished", function()
    displayFrame:SetAlpha(0)
end)

local function ShowPercent(pct, interrupted)
    if interrupted then
        displayText:SetTextColor(1, 0.3, 0.3)
    else
        displayText:SetTextColor(1, 1, 0)
    end
    displayText:SetFormattedText("%.0f%%", pct)
    displayFrame:SetAlpha(1)
    animGroup:Stop()
    animGroup:Play()
end

local function CalcPercent()
    if not castInfo.startTime or not castInfo.duration or castInfo.duration <= 0 then
        return nil
    end
    local _, _, _, worldLatencyMS = GetNetStats()
    local rawElapsed = GetTime() - castInfo.startTime
    return math.min((rawElapsed + worldLatencyMS / 1000) / castInfo.duration * 100, 100)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
events:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")

events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if PlayerCastingBarFrame then
            displayFrame:SetPoint("LEFT", PlayerCastingBarFrame, "RIGHT", 8, 0)
        end
    elseif event == "UNIT_SPELLCAST_START" then
        local name, _, _, startTimeMS, endTimeMS = UnitCastingInfo("player")
        if name then
            castInfo = {
                startTime = startTimeMS / 1000,
                endTime = endTimeMS / 1000,
                duration = (endTimeMS - startTimeMS) / 1000,
                isChanneling = false,
            }
        end
    elseif event == "UNIT_SPELLCAST_STOP" then
        castInfo = {}
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local name, _, _, startTimeMS, endTimeMS = UnitChannelInfo("player")
        if name then
            castInfo = {
                startTime = startTimeMS / 1000,
                endTime = endTimeMS / 1000,
                duration = (endTimeMS - startTimeMS) / 1000,
                isChanneling = true,
            }
        end
    elseif event == "UNIT_SPELLCAST_FAILED" then
        local pct = CalcPercent()
        if pct then ShowPercent(pct, false) end
        castInfo = {}
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        local pct = CalcPercent()
        if pct then ShowPercent(pct, true) end
        castInfo = {}
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if castInfo.endTime and GetTime() < castInfo.endTime - CHANNEL_COMPLETE_THRESHOLD then
            local pct = CalcPercent()
            if pct then ShowPercent(pct, false) end
        end
        castInfo = {}
    end
end)
