local classColors = {
    WARRIOR = "C79C6E",
    PALADIN = "F58CBA",
    HUNTER = "ABD473",
    ROGUE = "FFFF69",
    PRIEST = "FFFFFF",
    DEATHKNIGHT = "C41F3B",
    SHAMAN = "0070DE",
    MAGE = "69CCF0",
    WARLOCK = "9482C9",
    MONK = "00FF96",
    DRUID = "FF7D0A",
    DEMONHUNTER = "A330C9"
}

local characterList = {"Alge", "Algev", "Algee", "Algebolt"}

local ratingFrame
local function RenderPvPRating()
    if not ratingFrame then
        ratingFrame = CreateFrame("Frame", nil, UIParent)
        ratingFrame:SetSize(300, 100)
        ratingFrame:SetPoint("BOTTOMLEFT", 40, 320)

        ratingFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        ratingFrame:SetScript("OnEvent", function()
            inInstance = IsInInstance()
            if inInstance then
                ratingFrame:Hide()
            else 
                ratingFrame:Show()
            end
        end)

        ratingFrame.rows = {}

        -- headers
        local h1 = ratingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        h1:SetPoint("TOPLEFT", 0, 0)
        h1:SetText("")

        local h2 = ratingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        h2:SetPoint("TOPLEFT", 80, 0)
        h2:SetText("Solo")

        local h3 = ratingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        h3:SetPoint("TOPLEFT", 200, 0)
        h3:SetText("3v3")

        for i, name in ipairs(characterList) do
            local row = {}

            row.name = ratingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            row.name:SetPoint("TOPLEFT", 0, -25 * i)

            row.solo = ratingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            row.solo:SetPoint("TOPLEFT", 80, -25 * i)

            row.solow = ratingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.solow:SetPoint("TOPLEFT", 130, -25 * i - 3)

            row.threes = ratingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            row.threes:SetPoint("TOPLEFT", 200, -25 * i)

            row.threesw = ratingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.threesw:SetPoint("TOPLEFT", 250, -25 * i - 3)

            ratingFrame.rows[name] = row
        end
    end

    -- Update text only
    for _, name in ipairs(characterList) do
        local data = pvpRatings[name]
        local row = ratingFrame.rows[name]

        if data and row then
            local color = classColors[data.class] or "FFFFFF"
            row.name:SetText("|cFF" .. color .. name .. "|r")
            if name == "Algebolt" then
                row.name:SetText("|cFF" .. color .. "Algeb" .. "|r")
            end
            row.solo:SetText(data.solo or "-")
            row.solow:SetText(data.solow or "")
            row.threes:SetText(data["3v3"] or "-")
            row.threesw:SetText(data["3v3w"] or "")
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PVP_RATED_STATS_UPDATE")
f:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")

f:SetScript("OnEvent", function()
    local inInstance = IsInInstance()

    pvpRatings = pvpRatings or {}  -- initialize SavedVariable

    local playerName = UnitName("player") or "Unknown"
    local _, playerClass = UnitClass("player")
    local ratingSolo, _, _, _, _, _, _, _, _, _, _, seasonPlayedSolo, seasonWonSolo = GetPersonalRatedInfo(CONQUEST_BRACKET_INDEXES[1]);
    local rating3s, _, _, seasonPlayed3s, seasonWon3s = GetPersonalRatedInfo(CONQUEST_BRACKET_INDEXES[4])

    pvpRatings[playerName] = {
        ["class"] = playerClass,
        ["solo"] = ratingSolo ~= 0 and ratingSolo or "-",
        ["solow"] = seasonWonSolo ~= 0 and (seasonWonSolo.."-"..(seasonPlayedSolo - seasonWonSolo)) or "",
        ["3v3"] = rating3s ~= 0 and rating3s or "-",
        ["3v3w"] = seasonWon3s ~= 0 and (seasonWon3s.."-"..(seasonPlayed3s - seasonWon3s)) or "",
    }

    RenderPvPRating()
end)