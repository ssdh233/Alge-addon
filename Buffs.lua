
ICON_SIZE = 36
local auras = {}
local icons = {}
local function createOrUpdateIcon(index, texture, startTime, duration)
    local frame = icons[index]
    if not frame then
        frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(ICON_SIZE, ICON_SIZE)

        frame.texture = frame:CreateTexture(nil, "ARTWORK")
        frame.texture:SetAllPoints()

        icons[index] = frame
    end

    frame:SetSize(ICON_SIZE, ICON_SIZE)
    frame:SetPoint("CENTER", UIParent, "CENTER", ICON_SIZE * index , 0)

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints()
    frame.cooldown:SetCooldown(startTime, duration)

    frame.texture:SetTexture(texture)
    frame:Show()
end

local function dumpTable(tbl, indent)
    indent = indent or 0
    local formatting = string.rep("  ", indent)

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(formatting .. k .. " = {")
            dumpTable(v, indent + 1)
            print(formatting .. "}")
        else
            print(formatting .. k .. " = " .. tostring(v))
        end
    end
end

local function renderAuras()
    auras = {}
    local j = 0;
    for i = 1, 40 do
		local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "IMPORTANT")
		-- local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")

		if not auraData then
			break
		end
		local durationInfo = C_UnitAuras.GetAuraDuration("player", auraData.auraInstanceID)
		local start = durationInfo and durationInfo:GetStartTime()
		local duration = durationInfo and durationInfo:GetTotalDuration()
        dumpTable(auraData)
        table.insert(auras, {
            icon = auraData.icon,
            start = start,
            duration = duration
        })
	end

    for i, iconFrame in ipairs(icons) do
        iconFrame.cooldown:SetCooldown(0, 0);
        iconFrame:Hide()
    end

    for i, value in ipairs(auras) do
        createOrUpdateIcon(i, value.icon, value.start, value.duration)
    end
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:SetScript("OnEvent", function(self, event, unit, updateInfo)
    if unit ~= "player" then return end

    renderAuras()
end)
