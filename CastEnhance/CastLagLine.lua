local configs = {
    player = { barName = "PlayerCastingBarFrame" },
    focus  = { barName = "FocusFrameSpellBar" },
}

local function EnsureLagLine(cfg)
    if cfg.lagLine then return end
    local bar = _G[cfg.barName]
    if not bar then return end
    cfg.lagLine = bar:CreateTexture(nil, "OVERLAY", nil, 7)
    cfg.lagLine:SetWidth(2)
    cfg.lagLine:SetColorTexture(1, 1, 1, 0.9)
    cfg.lagLine:Hide()
end

local function ShowLagLine(cfg, unit)
    EnsureLagLine(cfg)
    if not cfg.lagLine then return end

    local bar = _G[cfg.barName]
    if not bar then return end

    local name, _, _, startTimeMS, endTimeMS = UnitCastingInfo(unit)
    if not name then
        cfg.lagLine:Hide()
        return
    end

    local duration = (endTimeMS - startTimeMS) / 1000
    if duration <= 0 then
        cfg.lagLine:Hide()
        return
    end

    local _, _, _, worldLatencyMS = GetNetStats()
    local lagSec = worldLatencyMS / 1000
    local pct = math.max(0, math.min(1, (duration - lagSec) / duration))

    cfg.lagLine:SetHeight(bar:GetHeight())
    cfg.lagLine:ClearAllPoints()
    cfg.lagLine:SetPoint("CENTER", bar, "LEFT", pct * bar:GetWidth(), 0)
    cfg.lagLine:Show()
end

local function HideLagLine(cfg)
    if cfg.lagLine then cfg.lagLine:Hide() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterUnitEvent("UNIT_SPELLCAST_START", "player", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player", "focus")
events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player", "focus")

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        for _, cfg in pairs(configs) do
            EnsureLagLine(cfg)
        end
    else
        local cfg = configs[unit]
        if not cfg then return end
        if event == "UNIT_SPELLCAST_START" then
            ShowLagLine(cfg, unit)
        else
            HideLagLine(cfg)
        end
    end
end)
