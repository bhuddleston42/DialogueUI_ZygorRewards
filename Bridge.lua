-- Read Zygor's recommendation without changing either addon's reward selection.
local dialog = _G.DUIQuestFrame
local status = "Waiting for a reward choice"
local lastError
local disabled = false
local function Report(message)
    print("|cffffcc66Dialogue UI - Zygor Rewards:|r " .. message)
end
local function Fail(message)
    disabled = true
    lastError = tostring(message)
    status = "Compatibility error; bridge paused until reload"
    Report(status .. ". Use /duizygor for details.")
end
SLASH_DUIZYGOR1 = "/duizygor"
SlashCmdList.DUIZYGOR = function()
    Report("0.1.0-beta.1 — " .. status)
    for _, name in ipairs({"DialogueUI", "ZygorGuidesViewer"}) do
        Report(name .. ": " .. tostring(C_AddOns.GetAddOnMetadata(name, "Version") or "unknown"))
    end
    if lastError then Report(lastError) end
end
if not dialog then Fail("Dialogue UI's DUIQuestFrame was not found."); return end

local driver = CreateFrame("Frame", nil, dialog)
local markers = {}
local cachedQuest, cachedIndex, cachedReason
local elapsedSinceUpdate = 0
local resolved, attempts, cachedCount = false, 0, nil

local function Clear()
    cachedQuest, cachedIndex, cachedReason = nil, nil, nil
    resolved, attempts, cachedCount = false, 0, nil
    for _, marker in pairs(markers) do marker:Hide() end
end

local function GetMarker(button)
    local marker = markers[button]
    if marker then return marker end
    marker = CreateFrame("Frame", nil, button)
    marker:SetSize(22, 22)
    marker:SetPoint("CENTER", button, "TOPRIGHT", -5, -2)
    marker:SetFrameLevel(button:GetFrameLevel() + 5)
    marker.Icon = marker:CreateTexture(nil, "OVERLAY")
    marker.Icon:SetAllPoints()
    -- Zygor's silver gear emblem; the texture contains four vertical states.
    marker.Icon:SetTexture("Interface\\AddOns\\ZygorGuidesViewer\\Skins\\gear-logo-64")
    marker.Icon:SetTexCoord(0, 1, 0, 0.25)
    marker:EnableMouse(true)
    marker:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Zygor recommended", 1, 0.82, 0)
        GameTooltip:AddLine(self.reason == "upgrade" and "Best equipment upgrade" or "Highest vendor value", 1, 1, 1)
        GameTooltip:Show()
    end)
    local function HideTooltip(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end
    marker:SetScript("OnLeave", HideTooltip)
    marker:SetScript("OnHide", HideTooltip)
    markers[button] = marker
    return marker
end

local function Update()
    local zgv = _G.ZygorGuidesViewer
    local questItem = zgv and zgv.ItemScore and zgv.ItemScore.QuestItem
    if type(dialog.IsChoosingReward) ~= "function"
        or not questItem or type(questItem.GetQuestRewardIndex) ~= "function" then
        error("Required Dialogue UI or Zygor reward API is unavailable.")
    end
    if not dialog:IsChoosingReward() then
        Clear()
        status = "Waiting for a reward choice"
        return
    end
    if not (zgv.db and zgv.db.profile) then return end
    if not zgv.db.profile.questitemselector then
        Clear()
        status = "Enable quest reward suggestions in Zygor"
        return
    end
    if not dialog.itemButtonPool or type(dialog.itemButtonPool.ProcessActiveObjects) ~= "function" then
        error("Dialogue UI's reward button pool is unavailable.")
    end
    local questID = GetQuestID()
    local count = GetNumQuestChoices()
    if cachedQuest ~= questID or cachedCount ~= count then
        Clear()
        cachedQuest, cachedCount = questID, count
    end
    if not resolved then
        attempts = attempts + 1
        -- Zygor returns -5 until item information is available. Retry next tick.
        local index, reason = questItem:GetQuestRewardIndex()
        if index == -5 then
            status = "Waiting for reward item information"
            if attempts >= 40 then
                resolved = true
                status = "Item information timed out; reopen the quest to retry"
            end
        else
            resolved = true
            status = "No recommendation: " .. tostring(reason or "none")
        end
        if type(index) == "number" and index >= 1 and index <= count and index == math.floor(index)
            and (reason == "upgrade" or reason == "money") then
            cachedIndex, cachedReason = index, reason
            status = "Reward " .. index .. " recommended (" .. reason .. ")"
        end
    end
    local target
    dialog.itemButtonPool:ProcessActiveObjects(function(button)
        if button:IsShown() and button.type == "choice" and button.objectType == "item"
            and button.index == cachedIndex then target = button end
    end)
    for button, marker in pairs(markers) do
        if button ~= target then marker:Hide() end
    end
    if target then
        local marker = GetMarker(target)
        marker:SetFrameLevel(target:GetFrameLevel() + 5)
        marker.reason = cachedReason
        marker:Show()
    end
end

-- Only ticks while Dialogue UI is visible; scoring is cached for this quest.
driver:SetScript("OnUpdate", function(_, elapsed)
    if disabled then return end
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate < 0.25 then return end
    elapsedSinceUpdate = 0
    local ok, message = pcall(Update)
    if not ok then
        Clear()
        Fail(message)
    end
end)
driver:SetScript("OnHide", function()
    Clear()
    if not disabled then status = "Waiting for a reward choice" end
end)
driver:SetScript("OnEvent", function(_, event)
    -- Item events restart a completed timeout but do not discard a valid result.
    if event == "GET_ITEM_INFO_RECEIVED" then
        if not cachedIndex then resolved, attempts = false, 0 end
    else
        Clear()
    end
end)
for _, event in ipairs({"QUEST_COMPLETE", "QUEST_FINISHED", "QUEST_DETAIL",
    "PLAYER_EQUIPMENT_CHANGED", "PLAYER_SPECIALIZATION_CHANGED", "GET_ITEM_INFO_RECEIVED"}) do
    driver:RegisterEvent(event)
end
