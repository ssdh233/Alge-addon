
ICON_SIZE = 36
local ANCHOR_X = 30
local ANCHOR_Y = 100
local ICON_SPACING = 4

local debuffIcons = {}

-- Show only these debuffs by spell name. Empty = show all debuffs.
local debuffFilter = {}

local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

local function createOrUpdateIcon(index, texture, durationObject)
    local frame = debuffIcons[index]
    if not frame then
        frame = CreateFrame("Frame", nil, UIParent)
        frame:SetIgnoreParentScale(true)
        frame:SetSize(ICON_SIZE, ICON_SIZE)

        frame.texture = frame:CreateTexture(nil, "ARTWORK")
        frame.texture:SetAllPoints()

        frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
        frame.cooldown:SetAllPoints()

        debuffIcons[index] = frame
    end

    frame:SetSize(ICON_SIZE, ICON_SIZE)
    frame:SetPoint("LEFT", UIParent, "CENTER", ANCHOR_X + (index - 1) * (ICON_SIZE + ICON_SPACING), ANCHOR_Y)

    if durationObject then
        frame.cooldown:SetCooldownFromDurationObject(durationObject)
    else
        frame.cooldown:Clear()
    end

    frame.texture:SetTexture(texture)
    frame:Show()

    if LCG then
        LCG.ProcGlow_Start(frame, { startAnim = false })
    end
end

local function renderDebuffs()
    local auras = C_UnitAuras.GetUnitAuras("player", "HARMFUL | IMPORTANT")

    for i, iconFrame in ipairs(debuffIcons) do
        iconFrame.cooldown:Clear()
        if LCG then LCG.ProcGlow_Stop(iconFrame) end
        iconFrame:Hide()
    end

    local index = 0
    for _, auraData in ipairs(auras) do
        if #debuffFilter == 0 or debuffFilter[auraData.name] then
            local durationObject = C_UnitAuras.GetAuraDuration("player", auraData.auraInstanceID)
            index = index + 1
            createOrUpdateIcon(index, auraData.icon, durationObject)
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Alge" then
        if AlgeDebuffsDB and AlgeDebuffsDB.anchorX then
            ANCHOR_X = AlgeDebuffsDB.anchorX
            ANCHOR_Y = AlgeDebuffsDB.anchorY
        end
    elseif event == "UNIT_AURA" then
        if arg1 ~= "player" then return end
        renderDebuffs()
    end
end)

-- Test icon for positioning
local testIcon = CreateFrame("Frame", nil, UIParent)
testIcon:SetIgnoreParentScale(true)
testIcon:SetSize(ICON_SIZE, ICON_SIZE)
testIcon:SetMovable(true)
testIcon:EnableMouse(true)
testIcon:RegisterForDrag("LeftButton")
testIcon:SetClampedToScreen(true)
testIcon:Hide()

local testTexture = testIcon:CreateTexture(nil, "ARTWORK")
testTexture:SetAllPoints()
testTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

local testBorder = testIcon:CreateTexture(nil, "OVERLAY")
testBorder:SetAllPoints()
testBorder:SetColorTexture(1, 1, 0, 0.6)
testBorder:SetBlendMode("ADD")

testIcon:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

testIcon:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()

    local screenW = GetScreenWidth()
    local screenH = GetScreenHeight()
    local uiScale = UIParent:GetEffectiveScale()

    local physLeft = self:GetLeft()
    local physBottom = self:GetBottom()

    ANCHOR_X = physLeft - screenW / 2 * uiScale
    ANCHOR_Y = physBottom + ICON_SIZE / 2 - screenH / 2 * uiScale

    AlgeDebuffsDB = AlgeDebuffsDB or {}
    AlgeDebuffsDB.anchorX = ANCHOR_X
    AlgeDebuffsDB.anchorY = ANCHOR_Y

    print(string.format("|cff00ff00Alge Debuffs:|r anchor saved (%.0f, %.0f)", ANCHOR_X, ANCHOR_Y))
end)

local function showTestIcon()
    testIcon:SetSize(ICON_SIZE, ICON_SIZE)
    testIcon:ClearAllPoints()
    testIcon:SetPoint("LEFT", UIParent, "CENTER", ANCHOR_X, ANCHOR_Y - ICON_SIZE / 2)
    testIcon:Show()
end

SLASH_ALGE1 = "/alge"
SlashCmdList["ALGE"] = function(msg)
    local cmd = msg:lower():match("^%s*(.-)%s*$")
    if cmd == "debuffs test" then
        if testIcon:IsShown() then
            testIcon:Hide()
        else
            showTestIcon()
        end
    end
end
