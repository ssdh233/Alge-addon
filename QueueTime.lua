local f = CreateFrame("Frame", "QueueTimeFrame", UIParent)
f:SetSize(300, 60)
f:SetPoint("TOP", UIParent, "TOP", 0, -50)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetClampedToScreen(true)
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)

f.bg = f:CreateTexture(nil, "BACKGROUND")
f.bg:SetAllPoints(f)
f.bg:SetColorTexture(0, 0, 0, 0.5)

f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
f.text:SetText("")

f:Hide()

local startTime = nil

local function UpdateQueueInfo()
    local inQueue = false
    local queueType = ""
    local avgWait = nil
    local waitTime = nil
    
    for i = 1, 3 do
        local status, mapName, teamSize, registeredMatch, suspendedQueue = GetBattlefieldStatus(i)
        if status == "queued" or status == "confirm" then
            inQueue = true
            queueType = mapName
            local estimatedTime = GetBattlefieldEstimatedWaitTime(i)
            if estimatedTime and estimatedTime > 0 then
                avgWait = math.floor(estimatedTime / 60000)
            end
            waitTime = math.floor(GetBattlefieldTimeWaited(i) / 1000)
            break
        end
    end

    
    if inQueue then
        local mins = math.floor(waitTime / 60)
        local secs = math.floor(waitTime % 60)
        
        local displayText = queueType;
        
        if avgWait and avgWait > 0 then
            displayText = displayText .. string.format("\nAverage Wait Time: %dm", avgWait)
        end

        if mins > 0 then
        	displayText = displayText .. string.format("\nTime In Queue: %dm %ds", mins, secs)
        else 
        	displayText = displayText .. string.format("\nTime In Queue: %ds", secs)
        end

        f.text:SetText(displayText)
        f:Show()
    else
        startTime = nil
        f:Hide()
    end
end

local timeSinceLastUpdate = 0
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= 1 then
        UpdateQueueInfo()
        timeSinceLastUpdate = 0
    end
end)

f:RegisterEvent("LFG_UPDATE_RANDOM_INFO")
f:RegisterEvent("LFG_QUEUE_STATUS_UPDATE")
f:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
f:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
f:RegisterEvent("PVPQUEUE_ANYWHERE_SHOW")
f:RegisterEvent("PVPQUEUE_ANYWHERE_UPDATE_AVAILABLE")

f:SetScript("OnEvent", function(self, event, ...)
    UpdateQueueInfo()
end)

UpdateQueueInfo()