local f = CreateFrame("Frame", "QueueTimeFrame", UIParent)
f:SetSize(300, 60)
f:SetPoint("TOP", UIParent, "TOP", 0, -50)
local LINE_HEIGHT = 58
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

local function UpdateQueueInfo()
    local queues = {}

    for i = 1, 3 do
        local status, mapName = GetBattlefieldStatus(i)
        if status == "queued" or status == "confirm" then
            local estimatedTime = GetBattlefieldEstimatedWaitTime(i)
            local avgWait = (estimatedTime and estimatedTime > 0) and math.floor(estimatedTime / 60000) or nil
            local waitTime = math.floor(GetBattlefieldTimeWaited(i) / 1000)
            table.insert(queues, { name = mapName, avgWait = avgWait, waitTime = waitTime })
        end
    end

    if #queues > 0 then
        local lines = {}
        for _, q in ipairs(queues) do
            local mins = math.floor(q.waitTime / 60)
            local secs = math.floor(q.waitTime % 60)
            local entry = q.name
            if q.avgWait and q.avgWait > 0 then
                entry = entry .. string.format("\nAverage Wait Time: %dm", q.avgWait)
            end
            if mins > 0 then
                entry = entry .. string.format("\nTime In Queue: %dm %ds", mins, secs)
            else
                entry = entry .. string.format("\nTime In Queue: %ds", secs)
            end
            table.insert(lines, entry)
        end
        f:SetHeight(LINE_HEIGHT * #queues)
        f.text:SetText(table.concat(lines, "\n\n"))
        f:Show()
    else
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