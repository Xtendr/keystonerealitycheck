-- KeystoneSynergyCheck.lua
-- LFG companion: evaluates applicant synergy with your current group composition.
-- Author : Xtendr
-- License: MIT

local ADDON_NAME = "KeystoneSynergyCheck"

-- Saved-variable defaults
local DB_DEFAULTS = {
    showHighlight = true,
    showFills     = true,
    minimap       = { hide = false },
}

-- Colour palette
local C = {
    header = "|cFFFF9900",
    green  = "|cFF00FF00",
    yellow = "|cFFFFFF00",
    grey   = "|cFFA9A9A9",
    white  = "|cFFFFFFFF",
    blue   = "|cFF99CCFF",
    red    = "|cFFFF0000",
    reset  = "|r",
}

local LABEL_RGB = {0.66, 0.66, 0.66}
local WHITE_RGB = {1, 1, 1}
local GREEN_RGB = {0, 1, 0}

local function col(colour, text)
    return colour .. tostring(text) .. C.reset
end

-- Forward declarations
local ToggleSettingsWindow
local UpdateMinimapButton

local function fmtCount(n)
    if type(n) ~= "number" then return "0" end
    if n >= 1000 then
        return string.format("%s,%03d", math.floor(n / 1000), n % 1000)
    end
    return tostring(n)
end

-- =========================================================================
-- Party Scanner
-- =========================================================================

local function GetPlayerSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    local id = GetSpecializationInfo(specIndex)
    return id
end

local function ScanParty()
    local groupHas = {
        lust = false, brez = false, shroud = false,
        buffs = {},
        kicks = {},
        armorTypes = {},
        aoeStops = 0,
        purge = false, soothe = false, massDispel = false,
        groupDR = {},
        dmgProfiles = {},
        specs = {},
        memberCount = 0,
    }

    local specIDs = {}

    local playerSpec = GetPlayerSpecID()
    if playerSpec then
        specIDs[#specIDs + 1] = playerSpec
    end

    for i = 1, 4 do
        if UnitExists("party" .. i) then
            local specID = GetInspectSpecialization("party" .. i)
            if specID and specID > 0 then
                specIDs[#specIDs + 1] = specID
            end
        end
    end

    for _, specID in ipairs(specIDs) do
        local info = KSC_SpecDB and KSC_SpecDB[specID]
        if info then
            groupHas.specs[specID] = true
            groupHas.memberCount = groupHas.memberCount + 1

            if info.lust then groupHas.lust = true end
            if info.brez then groupHas.brez = true end
            if info.shroud then groupHas.shroud = true end
            if info.purge then groupHas.purge = true end
            if info.soothe then groupHas.soothe = true end
            if info.massDispel then groupHas.massDispel = true end

            if info.raidBuff then
                groupHas.buffs[info.raidBuff] = true
            end

            if info.kickCD then
                groupHas.kicks[#groupHas.kicks + 1] = {
                    specID = specID,
                    cd = info.kickCD,
                    range = info.kickRange,
                }
            end

            if info.armor then
                groupHas.armorTypes[info.armor] = true
            end

            groupHas.aoeStops = groupHas.aoeStops + (info.aoeStops or 0)

            if info.groupDR then
                groupHas.groupDR[#groupHas.groupDR + 1] = info.groupDR
            end

            if info.dmgProfile then
                groupHas.dmgProfiles[info.dmgProfile] = true
            end
        end
    end

    return groupHas
end

-- =========================================================================
-- Applicant Scorer
-- =========================================================================

local SCORE_LUST       = 25
local SCORE_BREZ       = 20
local SCORE_SHROUD     = 10
local SCORE_BUFF       = 10
local SCORE_KICK_NEED  = 5
local SCORE_KICK_RANGE = 3
local SCORE_AOE_STOP   = 5
local SCORE_PURGE      = 5
local SCORE_SOOTHE     = 5
local SCORE_ARMOR      = 3
local SCORE_GROUP_DR   = 5

local function ScoreApplicant(specID, groupHas)
    local info = KSC_SpecDB and KSC_SpecDB[specID]
    if not info then
        return 0, {}, "No spec data"
    end

    local score = 0
    local fills = {}

    if info.lust and not groupHas.lust then
        score = score + SCORE_LUST
        fills[#fills + 1] = "Lust"
    end

    if info.brez and not groupHas.brez then
        score = score + SCORE_BREZ
        fills[#fills + 1] = "Brez"
    end

    if info.shroud and not groupHas.shroud then
        score = score + SCORE_SHROUD
        fills[#fills + 1] = "Shroud"
    end

    if info.raidBuff and not groupHas.buffs[info.raidBuff] then
        score = score + SCORE_BUFF
        local buffName = KSC_RAID_BUFFS and KSC_RAID_BUFFS[info.raidBuff]
        if buffName then
            local short = buffName:match("^(.-)%s*%(") or buffName
            fills[#fills + 1] = short
        else
            fills[#fills + 1] = info.raidBuff
        end
    end

    if info.kickCD then
        if #groupHas.kicks <= 1 then
            score = score + SCORE_KICK_NEED
        end
        local hasRangedKick = false
        for _, k in ipairs(groupHas.kicks) do
            if k.range == "ranged" then hasRangedKick = true; break end
        end
        if info.kickRange == "ranged" and not hasRangedKick then
            score = score + SCORE_KICK_RANGE
        end
    end

    if (info.aoeStops or 0) > 0 and groupHas.aoeStops < 3 then
        score = score + SCORE_AOE_STOP
    end

    if info.purge and not groupHas.purge then
        score = score + SCORE_PURGE
        fills[#fills + 1] = "Purge"
    end

    if info.soothe and not groupHas.soothe then
        score = score + SCORE_SOOTHE
        fills[#fills + 1] = "Soothe"
    end

    if info.armor and groupHas.armorTypes[info.armor] then
        score = score + SCORE_ARMOR
    end

    if info.groupDR and #groupHas.groupDR == 0 then
        score = score + SCORE_GROUP_DR
    end

    score = math.min(score, 100)

    local label
    if score >= 70 then
        label = "Great Fit!"
    elseif score >= 40 then
        label = "Good Fit"
    elseif score >= 20 then
        label = "OK"
    else
        label = "Low Synergy"
    end

    return score, fills, label
end

local function GetScoreColorRGB(score)
    if score >= 70 then return 0, 1, 0 end
    if score >= 40 then return 1, 1, 0 end
    if score >= 20 then return 1, 1, 1 end
    return 0.66, 0.66, 0.66
end

-- =========================================================================
-- Tooltip injection
-- =========================================================================

local KSC_HEADER = "Keystone Synergy Check"

local function TooltipAlreadyHasKSC(tooltip)
    local name = tooltip:GetName()
    for i = 1, tooltip:NumLines() do
        local line = _G[name .. "TextLeft" .. i]
        if line and line:GetText() and line:GetText():find(KSC_HEADER, 1, true) then
            return true
        end
    end
    return false
end

local function InjectTooltipData(tooltip, applicantID, memberIndex)
    if not tooltip or not applicantID or not memberIndex then return end
    if TooltipAlreadyHasKSC(tooltip) then return end

    local db = KeystoneSynergyCheckDB or {}

    local fullName, class, localizedClass, level, itemLevel, honorLevel,
          tank, healer, damage, assignedRole, relationship, dungeonScore,
          pvpItemLevel, factionGroup, raceID, specID
          = C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex)

    if not specID or specID == 0 then return end

    local info = KSC_SpecDB and KSC_SpecDB[specID]
    if not info then return end

    local groupHas = ScanParty()
    local score, fills, label = ScoreApplicant(specID, groupHas)

    tooltip:AddLine(" ")
    tooltip:AddLine(col(C.header, KSC_HEADER))

    -- Synergy Score line
    local sR, sG, sB = GetScoreColorRGB(score)
    tooltip:AddDoubleLine(
        "Synergy Score",
        score .. " \226\128\148 " .. label,
        LABEL_RGB[1], LABEL_RGB[2], LABEL_RGB[3],
        sR, sG, sB
    )

    -- Fills line
    if db.showFills ~= false then
        if #fills > 0 then
            local fillStr = table.concat(fills, ", ")
            if #fillStr > 50 then
                tooltip:AddLine(
                    col(C.grey, "Fills: ") .. col(C.green, fillStr),
                    nil, nil, nil, true
                )
            else
                tooltip:AddDoubleLine(
                    "Fills",
                    fillStr,
                    LABEL_RGB[1], LABEL_RGB[2], LABEL_RGB[3],
                    GREEN_RGB[1], GREEN_RGB[2], GREEN_RGB[3]
                )
            end
        else
            tooltip:AddDoubleLine(
                "Fills",
                "Well-rounded",
                LABEL_RGB[1], LABEL_RGB[2], LABEL_RGB[3],
                WHITE_RGB[1], WHITE_RGB[2], WHITE_RGB[3]
            )
        end
    end

    -- Kick line
    if info.kickCD then
        local kickStr = info.kickCD .. "s (" .. (info.kickRange or "melee") .. ")"
        tooltip:AddDoubleLine(
            "Kick",
            kickStr,
            LABEL_RGB[1], LABEL_RGB[2], LABEL_RGB[3],
            WHITE_RGB[1], WHITE_RGB[2], WHITE_RGB[3]
        )
    else
        tooltip:AddDoubleLine(
            "Kick",
            "None",
            LABEL_RGB[1], LABEL_RGB[2], LABEL_RGB[3],
            LABEL_RGB[1], LABEL_RGB[2], LABEL_RGB[3]
        )
    end

    -- Damage profile line (DPS/tanks only)
    if info.dmgProfile then
        tooltip:AddDoubleLine(
            "Damage",
            info.dmgProfile,
            LABEL_RGB[1], LABEL_RGB[2], LABEL_RGB[3],
            WHITE_RGB[1], WHITE_RGB[2], WHITE_RGB[3]
        )
    end

    -- Group DR line (if spec has one)
    if info.groupDR then
        tooltip:AddDoubleLine(
            "Group DR",
            info.groupDR,
            LABEL_RGB[1], LABEL_RGB[2], LABEL_RGB[3],
            WHITE_RGB[1], WHITE_RGB[2], WHITE_RGB[3]
        )
    end

    tooltip:Show()
end

-- =========================================================================
-- Row highlight system
-- =========================================================================

local HIGHLIGHT_THRESHOLD = 50

local function UpdateRowHighlight(frame, applicantID, memberIndex)
    local db = KeystoneSynergyCheckDB or {}

    if db.showHighlight == false then
        if frame._kscHighlight then frame._kscHighlight:Hide() end
        return
    end

    local fullName, class, localizedClass, level, itemLevel, honorLevel,
          tank, healer, damage, assignedRole, relationship, dungeonScore,
          pvpItemLevel, factionGroup, raceID, specID
          = C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex)

    if not specID or specID == 0 then
        if frame._kscHighlight then frame._kscHighlight:Hide() end
        return
    end

    local groupHas = ScanParty()
    local score = ScoreApplicant(specID, groupHas)

    if score >= HIGHLIGHT_THRESHOLD then
        if not frame._kscHighlight then
            local tex = frame:CreateTexture(nil, "BACKGROUND")
            tex:SetColorTexture(1, 0.82, 0, 0.15)
            tex:SetAllPoints(frame)
            frame._kscHighlight = tex
        end
        frame._kscHighlight:Show()
    else
        if frame._kscHighlight then frame._kscHighlight:Hide() end
    end
end

-- =========================================================================
-- LFG frame hooking
-- =========================================================================

local hookedFrames = {}

local function RefreshFrame(memberFrame)
    local applicantID = memberFrame.applicantID
        or (memberFrame:GetParent() and memberFrame:GetParent().applicantID)
    local memberIndex = memberFrame.memberIndex or memberFrame._kscMemberIndex or 1
    if applicantID then
        UpdateRowHighlight(memberFrame, applicantID, memberIndex)
    end
end

local function HookApplicantMember(memberFrame, memberIndex)
    if memberIndex then
        memberFrame._kscMemberIndex = memberIndex
    end

    if hookedFrames[memberFrame] then
        RefreshFrame(memberFrame)
        return
    end
    hookedFrames[memberFrame] = true

    memberFrame:HookScript("OnEnter", function(self)
        local applicantID = self.applicantID or (self:GetParent() and self:GetParent().applicantID)
        local mi = self.memberIndex or self._kscMemberIndex or 1
        if not applicantID then return end

        C_Timer.After(0, function()
            if GameTooltip:IsShown() then
                InjectTooltipData(GameTooltip, applicantID, mi)
            end
        end)
    end)

    RefreshFrame(memberFrame)
end

local function HookApplicationViewer()
    local viewer = LFGListFrame and LFGListFrame.ApplicationViewer
    if not viewer then return end

    local function ProcessFrames(scrollBox)
        scrollBox:ForEachFrame(function(frame)
            if frame.Members then
                for i, memberFrame in ipairs(frame.Members) do
                    HookApplicantMember(memberFrame, i)
                end
            elseif frame.applicantID then
                HookApplicantMember(frame, 1)
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

-- =========================================================================
-- Settings window
-- =========================================================================

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

local function makeKSCCheckbox(parent, yOff, dbKey, labelText, onToggle)
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
        check:SetShown(KeystoneSynergyCheckDB and KeystoneSynergyCheckDB[dbKey] ~= false)
    end

    row:SetScript("OnClick", function()
        if KeystoneSynergyCheckDB then
            KeystoneSynergyCheckDB[dbKey] = not (KeystoneSynergyCheckDB[dbKey] ~= false)
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

local function CreateSettingsWindow()
    local WIN_W = 320
    local WIN_H = 220
    local HEADER_H = 36

    local win = CreateFrame("Frame", "KSCSettingsWindow", UIParent, "BackdropTemplate")
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
    tinsert(UISpecialFrames, "KSCSettingsWindow")

    local drag = CreateFrame("Frame", nil, win)
    drag:SetPoint("TOPLEFT")
    drag:SetPoint("TOPRIGHT")
    drag:SetHeight(HEADER_H)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() win:StartMoving() end)
    drag:SetScript("OnDragStop",  function() win:StopMovingOrSizing() end)

    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -10)
    title:SetText(col(C.header, "Keystone Synergy Check"))

    local closeBtn = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() win:Hide() end)

    local y = -46
    local GAP = 8

    -- Section header
    local sectionLbl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sectionLbl:SetPoint("TOPLEFT", 14, y)
    sectionLbl:SetText(col(C.header, "Display"))
    y = y - 22

    local _, h1 = makeKSCCheckbox(win, y, "showHighlight", "Highlight synergy fits on applicant rows")
    y = y - h1 - 4
    local _, h2 = makeKSCCheckbox(win, y, "showFills", "Show fills detail in tooltip")
    y = y - h2 - 12

    -- Divider
    local div = win:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1)
    div:SetPoint("LEFT", 14, 0)
    div:SetPoint("RIGHT", -14, 0)
    div:SetPoint("TOP", 0, y)
    div:SetColorTexture(ST.border[1], ST.border[2], ST.border[3], 0.5)
    y = y - 12

    -- Minimap button toggle (inverted hide key)
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
            local db = KeystoneSynergyCheckDB or {}
            local shown = not (db.minimap and db.minimap.hide)
            checkTex:SetShown(shown)
        end

        row:SetScript("OnClick", function()
            local db = KeystoneSynergyCheckDB
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

-- =========================================================================
-- Minimap button
-- =========================================================================

local minimapInitialized = false

local function InitializeMinimapButton()
    if minimapInitialized then return end

    local LDB  = LibStub and LibStub("LibDataBroker-1.1", true)
    local Icon = LibStub and LibStub("LibDBIcon-1.0",     true)
    if not LDB or not Icon then return end

    local dataObj = LDB:NewDataObject("KeystoneSynergyCheck", {
        type  = "launcher",
        text  = "Keystone Synergy Check",
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
            tt:AddLine(col(C.header, "Keystone Synergy Check"))
            tt:AddLine("|cFFFFFFFFLeft-click:|r Open settings", 0.85, 0.85, 0.85)
            tt:AddLine("|cFFFFFFFFRight-click:|r Toggle Group Finder", 0.85, 0.85, 0.85)
        end,
    })

    KeystoneSynergyCheckDB.minimap = KeystoneSynergyCheckDB.minimap or { hide = false }
    Icon:Register("KeystoneSynergyCheck", dataObj, KeystoneSynergyCheckDB.minimap)
    minimapInitialized = true
end

UpdateMinimapButton = function()
    local Icon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not Icon then return end
    if not minimapInitialized then InitializeMinimapButton() end
    if KeystoneSynergyCheckDB.minimap and KeystoneSynergyCheckDB.minimap.hide then
        Icon:Hide("KeystoneSynergyCheck")
    else
        Icon:Show("KeystoneSynergyCheck")
    end
end

-- =========================================================================
-- Initialization
-- =========================================================================

local lfgHooked = false

local function TryHookLFG()
    if lfgHooked then return true end
    if not LFGListFrame or not LFGListFrame.ApplicationViewer then return false end
    HookApplicationViewer()
    lfgHooked = true
    return true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)

    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")

        if type(KeystoneSynergyCheckDB) ~= "table" then
            KeystoneSynergyCheckDB = {}
        end
        for k, v in pairs(DB_DEFAULTS) do
            if KeystoneSynergyCheckDB[k] == nil then
                if type(v) == "table" then
                    local copy = {}
                    for kk, vv in pairs(v) do copy[kk] = vv end
                    KeystoneSynergyCheckDB[k] = copy
                else
                    KeystoneSynergyCheckDB[k] = v
                end
            end
        end

        InitializeMinimapButton()
        UpdateMinimapButton()

        if TryHookLFG() then
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "ADDON_LOADED" then
        if TryHookLFG() then
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end)

if PVEFrame then
    PVEFrame:HookScript("OnShow", function() C_Timer.After(0, TryHookLFG) end)
elseif PVEFrame_ToggleFrame then
    hooksecurefunc("PVEFrame_ToggleFrame", function() C_Timer.After(0, TryHookLFG) end)
end

-- =========================================================================
-- Slash commands
-- =========================================================================

SLASH_KSC1 = "/ksc"
SLASH_KSC2 = "/keystonesynergycheck"
SlashCmdList["KSC"] = function(msg)
    msg = (msg or ""):lower():trim()
    if msg == "debug" then
        local groupHas = ScanParty()
        print(col(C.header, "[KSC] Party Scan:"))
        print("  Members: " .. groupHas.memberCount)
        print("  Lust: " .. tostring(groupHas.lust))
        print("  Brez: " .. tostring(groupHas.brez))
        print("  Shroud: " .. tostring(groupHas.shroud))
        print("  Purge: " .. tostring(groupHas.purge))
        print("  Soothe: " .. tostring(groupHas.soothe))
        print("  Mass Dispel: " .. tostring(groupHas.massDispel))
        print("  AoE Stops: " .. groupHas.aoeStops)
        print("  Kicks: " .. #groupHas.kicks)

        local buffList = {}
        for k in pairs(groupHas.buffs) do buffList[#buffList + 1] = k end
        print("  Buffs: " .. (#buffList > 0 and table.concat(buffList, ", ") or "none"))

        local armorList = {}
        for k in pairs(groupHas.armorTypes) do armorList[#armorList + 1] = k end
        print("  Armor: " .. (#armorList > 0 and table.concat(armorList, ", ") or "none"))

        local drList = {}
        for _, v in ipairs(groupHas.groupDR) do drList[#drList + 1] = v end
        print("  Group DR: " .. (#drList > 0 and table.concat(drList, ", ") or "none"))

        print("  LFG hooked: " .. tostring(lfgHooked))
        return
    end
    ToggleSettingsWindow()
end
