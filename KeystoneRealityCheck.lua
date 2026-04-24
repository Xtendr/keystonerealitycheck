-- KeystoneRealityCheck.lua
-- LFG companion: injects Raider.IO spec-success data into applicant tooltips.
-- Author : Xtendr
-- License: MIT

local ADDON_NAME = "KeystoneRealityCheck"

-- ─── Saved-variable defaults ──────────────────────────────────────────────────
local DB_DEFAULTS = {
    dataRegion    = "auto",   -- "auto" | "eu" | "us" | "kr" | "tw"
    showUtility   = true,
    showVisualCue = true,
    minimap       = { hide = false },
}

-- ─── Colour palette ──────────────────────────────────────────────────────────
local C = {
    header = "|cFFFF9900",   -- orange-gold (spec: distinct KRC brand colour)
    green  = "|cFF00FF00",   -- spec: #00FF00
    yellow = "|cFFFFFF00",   -- spec: #FFFF00
    grey   = "|cFFA9A9A9",   -- spec: #A9A9A9
    white  = "|cFFFFFFFF",
    blue   = "|cFF99CCFF",
    red    = "|cFFFF0000",   -- spec: #FF0000
    reset  = "|r",
}

-- ─── Multiplier thresholds (adjustable) ─────────────────────────────────────
local MULT_GREEN  = 1.0  -- >= 1.0x expected = at or above average (green)
local MULT_YELLOW = 0.5  -- >= 0.5x expected = below avg but present (yellow)
                         -- < 0.5x          = rare in timed runs (grey)

local TANK_SPECS = {250, 581, 104, 268, 66, 73}

local SPECS_PER_ROLE = {
    tank = 6,
    healer = 7,
    melee = 13,
    ranged = 13,
}

local function col(colour, text)
    return colour .. tostring(text) .. C.reset
end

-- ─── Forward declarations ────────────────────────────────────────────────────
local ToggleSettingsWindow
local UpdateMinimapButton

-- ─── Number formatting ───────────────────────────────────────────────────────
local function fmtCount(n)
    if type(n) ~= "number" then return "0" end
    if n >= 1000 then
        return string.format("%s,%03d", math.floor(n / 1000), n % 1000)
    end
    return tostring(n)
end

-- ─── Region detection (same pattern as KeystoneCutoffs) ──────────────────────
local function GetRegion()
    local regionMap = { [1]="us", [2]="kr", [3]="eu", [4]="tw", [5]="us" }
    local id = GetCurrentRegionName and GetCurrentRegionName()
    if id then return string.lower(id) end
    return regionMap[GetCurrentRegion() or 3] or "eu"
end

local function GetDataRegion()
    local db = KeystoneRealityCheckDB or {}
    local setting = db.dataRegion
    if setting and setting ~= "auto" then return setting end
    return GetRegion()
end

-- ─── Key bracket mapping ─────────────────────────────────────────────────────
local BRACKET_DEFS = {
    { key = "low",   min = 2,  max = 7,  label = "Low (+2 to +7)" },
    { key = "mid",   min = 8,  max = 11, label = "Mid (+8 to +11)" },
    { key = "high",  min = 12, max = 15, label = "High (+12 to +15)" },
    { key = "elite", min = 16, max = 99, label = "Elite (+16 and above)" },
}

local function keyLevelToBracket(level)
    if type(level) ~= "number" or level < 2 then return "low" end
    for _, b in ipairs(BRACKET_DEFS) do
        if level >= b.min and level <= b.max then return b.key end
    end
    return "elite"
end

local function bracketLabel(bracketKey)
    for _, b in ipairs(BRACKET_DEFS) do
        if b.key == bracketKey then return b.label end
    end
    return bracketKey
end

-- ─── Data lookup ─────────────────────────────────────────────────────────────
local function lookupSpecData(region, dungeonMapID, keyLevel, specID)
    local data = KeystoneRealityCheckData
    if not data or not data.regions then return nil end
    local rg = data.regions[region]
    if not rg then return nil end
    local dungeon = rg[dungeonMapID]
    if not dungeon then return nil end

    local bracket = keyLevelToBracket(keyLevel)
    local bData = dungeon[bracket]
    if bData and bData[specID] then
        return bData[specID], bracket, false, computeTotalRuns(bData)
    end

    local totalR, totalP, count, totalRuns = 0, 0, 0, 0
    for _, bKey in ipairs({"low", "mid", "high", "elite"}) do
        local bd = dungeon[bKey]
        if bd then
            totalRuns = totalRuns + computeTotalRuns(bd)
            if bd[specID] then
                totalR = totalR + bd[specID].r
                totalP = totalP + bd[specID].p
                count = count + 1
            end
        end
    end
    if count > 0 then
        return { r = totalR, p = math.floor(totalP / count) }, bracket, true, totalRuns
    end
    return nil, bracket, false, 0
end

local function getDungeonName(mapID)
    local data = KeystoneRealityCheckData
    if data and data.dungeonNames and data.dungeonNames[mapID] then
        return data.dungeonNames[mapID]
    end
    return "Unknown Dungeon"
end

-- ─── Resolve mapID from WoW activity ID via data table ──────────────────────
local function activityToMapID(activityID)
    local data = KeystoneRealityCheckData
    if data and data.activityToMapID then
        return data.activityToMapID[activityID]
    end
    return nil
end

-- ─── Resolve mapID by matching dungeon name against our known dungeons ───────
local function matchDungeonByName(name)
    if not name then return nil end
    local data = KeystoneRealityCheckData
    if not data or not data.dungeonNames then return nil end
    local lower = name:lower()
    for mapID, dname in pairs(data.dungeonNames) do
        if lower:find(dname:lower(), 1, true) then return mapID end
    end
    return nil
end

-- ─── Detect the group's dungeon and key level ────────────────────────────────
local function GetListedKeyInfo()
    local mapID, keyLevel

    -- 1. C_MythicPlus (your own keystone)
    if C_MythicPlus then
        if C_MythicPlus.GetOwnedKeystoneChallengeMapID then
            mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
        end
        if C_MythicPlus.GetOwnedKeystoneLevel then
            keyLevel = C_MythicPlus.GetOwnedKeystoneLevel()
        end
    end

    -- 2. LFG listing info
    local entryInfo
    if C_LFGList and C_LFGList.GetActiveEntryInfo then
        entryInfo = C_LFGList.GetActiveEntryInfo()
    end

    if entryInfo then
        -- 2a. activityIDs (12.0.x uses plural table, not singular)
        local actIDs = entryInfo.activityIDs or {}
        if entryInfo.activityID then
            actIDs = { entryInfo.activityID }
        end

        for _, aid in ipairs(actIDs) do
            -- Activity ID → mapID via Raider.IO data
            if not mapID then
                mapID = activityToMapID(aid)
            end
            -- Activity info table (WoW API) — try name matching + key level
            if C_LFGList.GetActivityInfoTable then
                local actInfo = C_LFGList.GetActivityInfoTable(aid)
                if actInfo then
                    if not mapID then
                        mapID = actInfo.mapID
                    end
                    if not mapID and actInfo.fullName then
                        mapID = matchDungeonByName(actInfo.fullName)
                    end
                end
            end
            if mapID then break end
        end

        -- 2b. Key level from entryInfo fields
        if not keyLevel then
            keyLevel = entryInfo.keystoneLevel or entryInfo.mythicPlusLevel
        end
    end

    -- 3. If still no key level, try requesting keystone info
    if not keyLevel and C_MythicPlus then
        if C_MythicPlus.RequestCurrentKeystoneLevel then
            C_MythicPlus.RequestCurrentKeystoneLevel()
        end
        if C_MythicPlus.GetOwnedKeystoneLevel then
            keyLevel = C_MythicPlus.GetOwnedKeystoneLevel()
        end
    end

    return mapID, keyLevel
end

-- ─── Tooltip injection logic ─────────────────────────────────────────────────
local KRC_HEADER = "Keystone Reality Check"

local function TooltipAlreadyHasKRC(tooltip)
    local name = tooltip:GetName()
    for i = 1, tooltip:NumLines() do
        local line = _G[name .. "TextLeft" .. i]
        if line and line:GetText() and line:GetText():find(KRC_HEADER, 1, true) then
            return true
        end
    end
    return false
end

local function GetMultColor(mult)
    if mult >= MULT_GREEN  then return C.green  end
    if mult >= MULT_YELLOW then return C.yellow end
    return C.grey
end

local function GetMultColorRGB(mult)
    if mult >= MULT_GREEN  then return 0, 1, 0 end
    if mult >= MULT_YELLOW then return 1, 1, 0 end
    return 0.66, 0.66, 0.66
end

local function computeTotalRuns(bracketData)
    if not bracketData then return 0 end
    if bracketData._runs then return bracketData._runs end
    local total = 0
    for _, sid in ipairs(TANK_SPECS) do
        if bracketData[sid] then
            total = total + bracketData[sid].r
        end
    end
    return total
end

local function computeMultiplier(pct, role)
    local specsInRole = SPECS_PER_ROLE[role] or 13
    local fairShare = 100 / specsInRole
    if fairShare <= 0 then return 0 end
    return pct / fairShare
end

local function InjectTooltipData(tooltip, applicantID, memberIndex)
    if not tooltip or not applicantID or not memberIndex then return end
    if TooltipAlreadyHasKRC(tooltip) then return end

    local db = KeystoneRealityCheckDB or {}
    local fullName, class, localizedClass, level, itemLevel, honorLevel,
          tank, healer, damage, assignedRole, relationship, dungeonScore,
          pvpItemLevel, factionGroup, raceID, specID
          = C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex)

    if not specID or specID == 0 then return end

    local specInfo = KRC_SpecUtility and KRC_SpecUtility[specID]
    if not specInfo then return end

    local mapID, keyLevel = GetListedKeyInfo()
    if not mapID then return end

    local region = GetDataRegion()
    local specData, bracket, isAggregated, totalRuns = lookupSpecData(region, mapID, keyLevel or 16, specID)

    local dungeonName = getDungeonName(mapID)
    local specLabel = specInfo.spec .. " " .. specInfo.class

    tooltip:AddLine(" ")
    tooltip:AddLine(col(C.header, KRC_HEADER))

    if keyLevel then
        tooltip:AddLine(col(C.white, specLabel .. " performance in +" .. keyLevel .. " " .. dungeonName .. ":"))
    else
        tooltip:AddLine(col(C.white, specLabel .. " performance in " .. dungeonName .. ":"))
    end

    if specData and specData.r and specData.r > 0 then
        local pct = (specData.p or 0) / 10
        local mult = computeMultiplier(pct, specInfo.role)
        local multCol = GetMultColor(mult)

        local groupStr = ""
        if totalRuns and totalRuns > 0 then
            local oneInN = math.max(1, math.floor(totalRuns / specData.r + 0.5))
            if oneInN <= 1 then
                groupStr = " — found in most timed groups"
            else
                groupStr = " — 1 in every " .. oneInN .. " timed groups"
            end
        end

        tooltip:AddLine(col(multCol, string.format("%.1fx expected", mult)) .. col(C.white, groupStr))
        tooltip:AddLine(col(C.white, "Based on " .. fmtCount(specData.r) .. " timed runs this season"))
    else
        tooltip:AddLine(col(C.grey, "No ranked run data for this spec."))
    end

    if db.showUtility ~= false and specInfo.util and #specInfo.util > 0 then
        local utilStr = table.concat(specInfo.util, ", ")
        tooltip:AddLine(col(C.blue, "Brings: ") .. col(C.white, utilStr), nil, nil, nil, true)
    end

    tooltip:Show()
end

-- ─── At-a-Glance cue: bracketed multiplier on applicant rows ─────────────────
local overlayCache = {}

local function EnsureCueLabel(frame)
    if overlayCache[frame] then return overlayCache[frame] end

    local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    fs:SetJustifyH("RIGHT")
    fs:Hide()

    overlayCache[frame] = fs
    return fs
end

local function UpdateVisualCue(frame, applicantID, memberIndex)
    local db = KeystoneRealityCheckDB or {}
    local label = EnsureCueLabel(frame)

    if db.showVisualCue == false then
        label:Hide()
        return
    end

    local fullName, class, localizedClass, level, itemLevel, honorLevel,
          tank, healer, damage, assignedRole, relationship, dungeonScore,
          pvpItemLevel, factionGroup, raceID, specID
          = C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex)

    if not specID or specID == 0 then
        label:Hide()
        return
    end

    local specInfo = KRC_SpecUtility and KRC_SpecUtility[specID]
    if not specInfo then
        label:Hide()
        return
    end

    local mapID, keyLevel = GetListedKeyInfo()
    if not mapID then
        label:Hide()
        return
    end

    local region = GetDataRegion()
    local specData = lookupSpecData(region, mapID, keyLevel or 16, specID)

    if specData and specData.p then
        local pct = specData.p / 10
        local mult = computeMultiplier(pct, specInfo.role)
        local r, g, b = GetMultColorRGB(mult)
        label:SetText(string.format("[%.1fx]", mult))
        label:SetTextColor(r, g, b)
        label:Show()
    else
        label:Hide()
    end
end

-- ─── LFG frame hooking ──────────────────────────────────────────────────────
local hookedFrames = {}

local function RefreshVisualCue(memberFrame)
    local applicantID = memberFrame.applicantID
        or (memberFrame:GetParent() and memberFrame:GetParent().applicantID)
    local memberIndex = memberFrame.memberIndex or 1
    if applicantID then
        UpdateVisualCue(memberFrame, applicantID, memberIndex)
    end
end

local function HookApplicantMember(memberFrame)
    if hookedFrames[memberFrame] then
        RefreshVisualCue(memberFrame)
        return
    end
    hookedFrames[memberFrame] = true

    memberFrame:HookScript("OnEnter", function(self)
        local applicantID = self.applicantID or (self:GetParent() and self:GetParent().applicantID)
        local memberIndex = self.memberIndex or 1
        if not applicantID then return end

        C_Timer.After(0, function()
            if GameTooltip:IsShown() then
                InjectTooltipData(GameTooltip, applicantID, memberIndex)
            end
        end)

        UpdateVisualCue(self, applicantID, memberIndex)
    end)

    RefreshVisualCue(memberFrame)
end

local function HookApplicationViewer()
    local viewer = LFGListFrame and LFGListFrame.ApplicationViewer
    if not viewer then return end

    local function ProcessFrames(scrollBox)
        scrollBox:ForEachFrame(function(frame)
            if frame.Members then
                for _, memberFrame in ipairs(frame.Members) do
                    HookApplicantMember(memberFrame)
                end
            elseif frame.applicantID then
                HookApplicantMember(frame)
            end
        end)
    end

    if viewer.ScrollBox then
        hooksecurefunc(viewer.ScrollBox, "Update", function(scrollBox)
            ProcessFrames(scrollBox)
        end)
    end

    if viewer.UpdateResults then
        hooksecurefunc(viewer, "UpdateResults", function()
            if viewer.ScrollBox then
                ProcessFrames(viewer.ScrollBox)
            end
        end)
    end
end

-- ─── Settings window ─────────────────────────────────────────────────────────
local ST = {
    bg      = { 0.08, 0.08, 0.08, 0.95 },
    surface = { 0.12, 0.12, 0.12, 1.00 },
    element = { 0.17, 0.17, 0.17, 1.00 },
    hover   = { 0.24, 0.24, 0.24, 0.90 },
    border  = { 0.25, 0.25, 0.25, 1.00 },
    accent  = { 1.00, 0.82, 0.00 },
    text    = { 0.88, 0.88, 0.88, 1.00 },
    muted   = { 0.55, 0.55, 0.55, 1.00 },
}

local BD_EDGE = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}
local BD_PLAIN = { bgFile = "Interface\\Buttons\\WHITE8x8" }

local function mixBD(f)
    if not f.SetBackdrop then Mixin(f, BackdropTemplateMixin) end
end

local settingsWin
local settingsRefreshFns = {}

local function makeKRCCheckbox(parent, yOff, dbKey, labelText, onToggle)
    local ROW_H_CB = 22

    local row = CreateFrame("Button", nil, parent)
    row:SetSize(parent:GetWidth() - 28, ROW_H_CB)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, yOff)

    local box = CreateFrame("Frame", nil, row, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    mixBD(box)
    box:SetBackdrop(BD_EDGE)
    box:SetBackdropColor(ST.element[1], ST.element[2], ST.element[3], 1)
    box:SetBackdropBorderColor(ST.border[1], ST.border[2], ST.border[3], 1)

    local check = box:CreateTexture(nil, "OVERLAY")
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetSize(18, 18)
    check:SetPoint("CENTER", 0, 0)
    check:SetVertexColor(ST.accent[1], ST.accent[2], ST.accent[3])

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("LEFT", box, "RIGHT", 8, 0)
    lbl:SetText(labelText)
    lbl:SetTextColor(ST.text[1], ST.text[2], ST.text[3])
    lbl:SetWordWrap(false)

    local function refresh()
        check:SetShown(KeystoneRealityCheckDB and KeystoneRealityCheckDB[dbKey] ~= false)
    end

    row:SetScript("OnClick", function()
        if KeystoneRealityCheckDB then
            KeystoneRealityCheckDB[dbKey] = not (KeystoneRealityCheckDB[dbKey] ~= false)
        end
        refresh()
        if onToggle then onToggle() end
        pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
    end)
    row:SetScript("OnEnter", function()
        box:SetBackdropBorderColor(ST.accent[1], ST.accent[2], ST.accent[3], 1)
    end)
    row:SetScript("OnLeave", function()
        box:SetBackdropBorderColor(ST.border[1], ST.border[2], ST.border[3], 1)
    end)

    settingsRefreshFns[#settingsRefreshFns + 1] = refresh
    refresh()
    return row, ROW_H_CB
end

local function makeKRCDropdown(parent, yOff, dbKey, labelText, opts, extraCb)
    local ITEM_H  = 24
    local BTN_W_D = 140
    local ROW_H_D = 24

    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, yOff - 4)
    lbl:SetText(labelText)
    lbl:SetTextColor(ST.text[1], ST.text[2], ST.text[3])
    lbl:SetWordWrap(false)

    local ddBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    ddBtn:SetSize(BTN_W_D, ROW_H_D)
    ddBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, yOff - 2)
    mixBD(ddBtn)
    ddBtn:SetBackdrop(BD_EDGE)
    ddBtn:SetBackdropColor(ST.element[1], ST.element[2], ST.element[3], 1)
    ddBtn:SetBackdropBorderColor(ST.border[1], ST.border[2], ST.border[3], 0.6)

    local ddLabel = ddBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ddLabel:SetPoint("LEFT", 8, 0)
    ddLabel:SetPoint("RIGHT", -22, 0)
    ddLabel:SetJustifyH("LEFT")
    ddLabel:SetTextColor(ST.text[1], ST.text[2], ST.text[3])
    ddLabel:SetWordWrap(false)

    local ddArrow = ddBtn:CreateTexture(nil, "OVERLAY")
    ddArrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    ddArrow:SetSize(10, 10)
    ddArrow:SetPoint("RIGHT", -6, 0)
    ddArrow:SetVertexColor(ST.muted[1], ST.muted[2], ST.muted[3], 0.95)

    local function getCurrentLabel()
        local cur = KeystoneRealityCheckDB and KeystoneRealityCheckDB[dbKey]
        for _, opt in ipairs(opts) do
            if opt.value == cur then return opt.label end
        end
        return opts[1] and opts[1].label or "?"
    end

    local function refreshDD() ddLabel:SetText(getCurrentLabel()) end

    local menuH = #opts * ITEM_H + 6
    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:SetSize(BTN_W_D, menuH)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(500)
    menu:SetClampedToScreen(true)
    mixBD(menu)
    menu:SetBackdrop(BD_EDGE)
    menu:SetBackdropColor(ST.surface[1], ST.surface[2], ST.surface[3], 1)
    menu:SetBackdropBorderColor(ST.border[1], ST.border[2], ST.border[3], 1)
    menu:Hide()

    for i, opt in ipairs(opts) do
        local item = CreateFrame("Button", nil, menu, "BackdropTemplate")
        item:SetSize(BTN_W_D - 2, ITEM_H)
        item:SetPoint("TOPLEFT", 1, -3 - (i - 1) * ITEM_H)
        mixBD(item)
        item:SetBackdrop(BD_PLAIN)
        item:SetBackdropColor(0, 0, 0, 0)

        local itemLbl = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        itemLbl:SetPoint("LEFT", 8, 0)
        itemLbl:SetText(opt.label)
        itemLbl:SetTextColor(ST.text[1], ST.text[2], ST.text[3])

        item:SetScript("OnEnter", function() item:SetBackdropColor(ST.hover[1], ST.hover[2], ST.hover[3], 0.9) end)
        item:SetScript("OnLeave", function() item:SetBackdropColor(0, 0, 0, 0) end)
        item:SetScript("OnClick", function()
            if KeystoneRealityCheckDB then KeystoneRealityCheckDB[dbKey] = opt.value end
            menu:Hide()
            refreshDD()
            if extraCb then extraCb() end
            pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        end)
    end

    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints()
    catcher:SetFrameStrata("TOOLTIP")
    catcher:SetFrameLevel(499)
    catcher:EnableMouse(true)
    catcher:Hide()
    catcher:SetScript("OnMouseDown", function() menu:Hide() end)
    menu:SetScript("OnShow", function() catcher:Show() end)
    menu:SetScript("OnHide", function() catcher:Hide() end)

    ddBtn:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
        else
            menu:ClearAllPoints()
            menu:SetPoint("TOPLEFT", ddBtn, "BOTTOMLEFT", 0, -2)
            menu:Show()
        end
    end)
    ddBtn:SetScript("OnEnter", function()
        ddBtn:SetBackdropBorderColor(ST.accent[1], ST.accent[2], ST.accent[3], 0.9)
    end)
    ddBtn:SetScript("OnLeave", function()
        ddBtn:SetBackdropBorderColor(ST.border[1], ST.border[2], ST.border[3], 0.6)
    end)

    settingsRefreshFns[#settingsRefreshFns + 1] = refreshDD
    refreshDD()
    return ROW_H_D
end

local function CreateSettingsWindow()
    local WIN_W = 320
    local WIN_H = 290
    local HEADER_H = 36

    local win = CreateFrame("Frame", "KRCSettingsWindow", UIParent, "BackdropTemplate")
    win:SetSize(WIN_W, WIN_H)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetFrameLevel(500)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:SetClampedToScreen(true)
    mixBD(win)
    win:SetBackdrop(BD_EDGE)
    win:SetBackdropColor(ST.bg[1], ST.bg[2], ST.bg[3], ST.bg[4])
    win:SetBackdropBorderColor(ST.border[1], ST.border[2], ST.border[3], 1)
    tinsert(UISpecialFrames, "KRCSettingsWindow")

    -- Drag handle
    local drag = CreateFrame("Frame", nil, win)
    drag:SetPoint("TOPLEFT")
    drag:SetPoint("TOPRIGHT")
    drag:SetHeight(HEADER_H)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() win:StartMoving() end)
    drag:SetScript("OnDragStop",  function() win:StopMovingOrSizing() end)

    -- Title
    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -10)
    title:SetText(col(C.header, "Keystone Reality Check"))

    -- Close button
    local closeBtn = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() win:Hide() end)

    -- Version / data info
    local versionFs = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    versionFs:SetPoint("TOPLEFT", 14, -32)
    local dataInfo = KeystoneRealityCheckData and KeystoneRealityCheckData.updatedAt or "No data"
    versionFs:SetText(col(C.grey, "Data: " .. dataInfo))

    -- Settings content
    local y = -58
    local GAP = 8

    -- Region dropdown
    y = y - makeKRCDropdown(win, y, "dataRegion", "Region", {
        { label = "Auto-detect", value = "auto" },
        { label = "EU",          value = "eu" },
        { label = "US",          value = "us" },
        { label = "KR",          value = "kr" },
        { label = "TW",          value = "tw" },
    }) - GAP

    -- Divider
    local div = win:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1)
    div:SetPoint("LEFT", 14, 0)
    div:SetPoint("RIGHT", -14, 0)
    div:SetPoint("TOP", 0, y)
    div:SetColorTexture(ST.border[1], ST.border[2], ST.border[3], 0.5)
    y = y - 12

    -- Section header
    local sectionLbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sectionLbl:SetPoint("TOPLEFT", 14, y)
    sectionLbl:SetText(col(C.header, "Tooltip Display"))
    y = y - 22

    local _, h3 = makeKRCCheckbox(win, y, "showUtility",   "Show spec utility reminder")
    y = y - h3 - 4
    local _, h4 = makeKRCCheckbox(win, y, "showVisualCue", "Show [x] multiplier on applicant rows")
    y = y - h4 - 12

    -- Divider 2
    local div2 = win:CreateTexture(nil, "ARTWORK")
    div2:SetHeight(1)
    div2:SetPoint("LEFT", 14, 0)
    div2:SetPoint("RIGHT", -14, 0)
    div2:SetPoint("TOP", 0, y)
    div2:SetColorTexture(ST.border[1], ST.border[2], ST.border[3], 0.5)
    y = y - 12

    -- Minimap button: uses db.minimap.hide (inverted), not a simple boolean key
    do
        local ROW_H_CB = 22
        local row = CreateFrame("Button", nil, win)
        row:SetSize(win:GetWidth() - 28, ROW_H_CB)
        row:SetPoint("TOPLEFT", win, "TOPLEFT", 14, y)

        local box = CreateFrame("Frame", nil, row, "BackdropTemplate")
        box:SetSize(16, 16)
        box:SetPoint("LEFT", 0, 0)
        mixBD(box)
        box:SetBackdrop(BD_EDGE)
        box:SetBackdropColor(ST.element[1], ST.element[2], ST.element[3], 1)
        box:SetBackdropBorderColor(ST.border[1], ST.border[2], ST.border[3], 1)

        local checkTex = box:CreateTexture(nil, "OVERLAY")
        checkTex:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        checkTex:SetSize(18, 18)
        checkTex:SetPoint("CENTER", 0, 0)
        checkTex:SetVertexColor(ST.accent[1], ST.accent[2], ST.accent[3])

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("LEFT", box, "RIGHT", 8, 0)
        lbl:SetText("Show minimap button")
        lbl:SetTextColor(ST.text[1], ST.text[2], ST.text[3])
        lbl:SetWordWrap(false)

        local function mmRefresh()
            local db = KeystoneRealityCheckDB or {}
            local shown = not (db.minimap and db.minimap.hide)
            checkTex:SetShown(shown)
        end

        row:SetScript("OnClick", function()
            local db = KeystoneRealityCheckDB
            if db then
                if type(db.minimap) ~= "table" then db.minimap = { hide = false } end
                db.minimap.hide = not db.minimap.hide
            end
            mmRefresh()
            UpdateMinimapButton()
            pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        end)
        row:SetScript("OnEnter", function()
            box:SetBackdropBorderColor(ST.accent[1], ST.accent[2], ST.accent[3], 1)
        end)
        row:SetScript("OnLeave", function()
            box:SetBackdropBorderColor(ST.border[1], ST.border[2], ST.border[3], 1)
        end)

        settingsRefreshFns[#settingsRefreshFns + 1] = mmRefresh
        mmRefresh()
    end

    settingsWin = win
    win:Hide()
end

ToggleSettingsWindow = function()
    if not settingsWin then CreateSettingsWindow() end
    if settingsWin:IsShown() then
        settingsWin:Hide()
    else
        for _, fn in ipairs(settingsRefreshFns) do fn() end
        settingsWin:Show()
    end
end

-- ─── Minimap button ──────────────────────────────────────────────────────────
local minimapInitialized = false

local function InitializeMinimapButton()
    if minimapInitialized then return end

    local LDB  = LibStub and LibStub("LibDataBroker-1.1", true)
    local Icon = LibStub and LibStub("LibDBIcon-1.0",     true)
    if not LDB or not Icon then return end

    local dataObj = LDB:NewDataObject("KeystoneRealityCheck", {
        type  = "launcher",
        text  = "Keystone Reality Check",
        icon  = "Interface\\Icons\\inv_misc_spyglass_03",
        OnClick = function(_, button)
            if button == "RightButton" then
                if PVEFrame_ToggleFrame then
                    PVEFrame_ToggleFrame("GroupFinderFrame")
                end
            else
                ToggleSettingsWindow()
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine(col(C.header, "Keystone Reality Check"))
            tt:AddLine("|cFFFFFFFFLeft-click:|r Open settings", 0.85, 0.85, 0.85)
            tt:AddLine("|cFFFFFFFFRight-click:|r Toggle Group Finder", 0.85, 0.85, 0.85)
        end,
    })

    KeystoneRealityCheckDB.minimap = KeystoneRealityCheckDB.minimap or { hide = false }
    Icon:Register("KeystoneRealityCheck", dataObj, KeystoneRealityCheckDB.minimap)
    minimapInitialized = true
end

UpdateMinimapButton = function()
    local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not Icon then return end
    if not minimapInitialized then InitializeMinimapButton() end
    if KeystoneRealityCheckDB.minimap and KeystoneRealityCheckDB.minimap.hide then
        Icon:Hide("KeystoneRealityCheck")
    else
        Icon:Show("KeystoneRealityCheck")
    end
end

-- ─── Initialization ──────────────────────────────────────────────────────────
local lfgHooked = false

local function TryHookLFG()
    if lfgHooked then return true end
    if not LFGListFrame or not LFGListFrame.ApplicationViewer then return false end
    HookApplicationViewer()
    lfgHooked = true
    return true
end

-- ─── Event frame ─────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)

    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        if type(KeystoneRealityCheckDB) ~= "table" then
            KeystoneRealityCheckDB = {}
        end
        for k, v in pairs(DB_DEFAULTS) do
            if KeystoneRealityCheckDB[k] == nil then
                if type(v) == "table" then
                    local copy = {}
                    for kk, vv in pairs(v) do copy[kk] = vv end
                    KeystoneRealityCheckDB[k] = copy
                else
                    KeystoneRealityCheckDB[k] = v
                end
            end
        end

        if not KeystoneRealityCheckData then
            print("|cFFFF0000[KRC]|r Data.lua not found - did it load correctly?")
            return
        end

        InitializeMinimapButton()
        UpdateMinimapButton()

        -- Try hooking LFG immediately (frames may already exist)
        if TryHookLFG() then
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "ADDON_LOADED" then
        -- Try on every addon load — catches Blizzard_GroupFinder, Blizzard_LFGList, etc.
        if TryHookLFG() then
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end)

-- Belt-and-suspenders: hook when PVEFrame first shows (covers all edge cases)
if PVEFrame then
    PVEFrame:HookScript("OnShow", function() C_Timer.After(0, TryHookLFG) end)
elseif PVEFrame_ToggleFrame then
    hooksecurefunc("PVEFrame_ToggleFrame", function() C_Timer.After(0, TryHookLFG) end)
end

-- ─── Slash commands ──────────────────────────────────────────────────────────
SLASH_KRC1 = "/krc"
SLASH_KRC2 = "/keystonerealitycheck"
SlashCmdList["KRC"] = function(msg)
    msg = (msg or ""):lower():trim()
    if msg == "debug" then
        local region = GetDataRegion()
        print(col(C.header, "[KRC] Debug Info:"))
        print("  Region: " .. (region or "nil"))
        print("  Data loaded: " .. tostring(KeystoneRealityCheckData ~= nil))
        if KeystoneRealityCheckData then
            print("  Updated: " .. (KeystoneRealityCheckData.updatedAt or "unknown"))
            print("  Season: " .. (KeystoneRealityCheckData.season or "unknown"))
        end
        print("  LFG hooked: " .. tostring(lfgHooked))
        local mapID, keyLevel = GetListedKeyInfo()
        print("  Listed key: " .. (mapID and ("mapID=" .. mapID .. " +" .. (keyLevel or "?")) or "none"))
        if mapID then
            print("  Dungeon: " .. getDungeonName(mapID) .. " | Bracket: " .. keyLevelToBracket(keyLevel or 2))
        end
        return
    end
    if msg == "dump" then
        print(col(C.header, "[KRC] API Dump:"))
        -- C_MythicPlus
        print(col(C.blue, "-- C_MythicPlus --"))
        if C_MythicPlus then
            for _, fn in ipairs({"GetOwnedKeystoneChallengeMapID", "GetOwnedKeystoneLevel",
                                 "GetRunHistory", "GetOwnedKeystoneMapID"}) do
                if C_MythicPlus[fn] then
                    local ok, val = pcall(C_MythicPlus[fn])
                    print("  " .. fn .. ": " .. tostring(val))
                else
                    print("  " .. fn .. ": (not found)")
                end
            end
        end
        -- C_LFGList entry info
        print(col(C.blue, "-- C_LFGList.GetActiveEntryInfo --"))
        if C_LFGList and C_LFGList.GetActiveEntryInfo then
            local entry = C_LFGList.GetActiveEntryInfo()
            if entry then
                for k, v in pairs(entry) do
                    if type(v) == "table" then
                        local items = {}
                        for kk, vv in pairs(v) do items[#items+1] = tostring(kk) .. "=" .. tostring(vv) end
                        print("  entry." .. tostring(k) .. " = {" .. table.concat(items, ", ") .. "}")
                    else
                        print("  entry." .. tostring(k) .. " = " .. tostring(v))
                    end
                end
                -- Activity info from activityIDs (12.0.x plural)
                local actIDs = entry.activityIDs or {}
                if entry.activityID then actIDs = { entry.activityID } end
                for _, aid in ipairs(actIDs) do
                    print(col(C.blue, "-- GetActivityInfoTable(" .. aid .. ") --"))
                    local resolved = activityToMapID(aid)
                    if resolved then
                        print("  KRC lookup: mapID=" .. resolved .. " (" .. getDungeonName(resolved) .. ")")
                    else
                        print("  KRC lookup: no match")
                    end
                    if C_LFGList.GetActivityInfoTable then
                        local actInfo = C_LFGList.GetActivityInfoTable(aid)
                        if actInfo then
                            for k, v in pairs(actInfo) do
                                print("  act." .. tostring(k) .. " = " .. tostring(v))
                            end
                        end
                    end
                end
            else
                print("  (returned nil)")
            end
        end
        -- C_ChallengeMode
        print(col(C.blue, "-- C_ChallengeMode --"))
        if C_ChallengeMode then
            if C_ChallengeMode.GetActiveChallengeMapID then
                print("  GetActiveChallengeMapID: " .. tostring(C_ChallengeMode.GetActiveChallengeMapID()))
            end
            if C_ChallengeMode.GetMapTable then
                local maps = C_ChallengeMode.GetMapTable()
                if maps then
                    local names = {}
                    for _, id in ipairs(maps) do
                        local name = C_ChallengeMode.GetMapUIInfo(id)
                        names[#names + 1] = id .. "=" .. (name or "?")
                    end
                    print("  Season maps: " .. table.concat(names, ", "))
                end
            end
        end
        return
    end
    ToggleSettingsWindow()
end
