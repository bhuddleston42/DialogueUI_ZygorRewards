-- Run from the addon directory with Lua 5.1.
local source = "Bridge.lua"
local tests = 0
local function fixture()
    local env = setmetatable({}, {__index = _G})
    env._G = env
    local state = {quest = 101, count = 2, index = 2, reason = "upgrade", calls = 0, frames = {}, messages = {}}
    local function frame(parent)
        local f = {parent = parent, scripts = {}, shown = true, level = 1}
        function f:SetScript(k, v) self.scripts[k] = v end
        function f:RegisterEvent() end
        function f:SetSize() end
        function f:SetPoint() end
        function f:SetAllPoints() end
        function f:SetFrameLevel(n) self.level = n end
        function f:GetFrameLevel() return self.level end
        function f:EnableMouse() end
        function f:IsShown() return self.shown end
        function f:Show() self.shown = true end
        function f:Hide()
            local wasShown = self.shown
            self.shown = false
            if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
        end
        function f:CreateTexture()
            return {SetAllPoints = function() end, SetTexture = function() end, SetTexCoord = function() end}
        end
        return f
    end
    env.CreateFrame = function(_, _, parent)
        local f = frame(parent)
        table.insert(state.frames, f)
        return f
    end
    local dialog = frame()
    dialog.choosing = true
    function dialog:IsChoosingReward() return self.choosing end
    state.buttons = {frame(dialog), frame(dialog)}
    for i, b in ipairs(state.buttons) do b.index, b.type, b.objectType = i, "choice", "item" end
    dialog.itemButtonPool = {ProcessActiveObjects = function(_, fn)
        for _, b in ipairs(state.buttons) do fn(b) end
    end}
    env.DUIQuestFrame = dialog
    env.GetQuestID = function() return state.quest end
    env.GetNumQuestChoices = function() return state.count end
    env.ZygorGuidesViewer = {db = {profile = {questitemselector = true}}, ItemScore = {QuestItem = {
        GetQuestRewardIndex = function()
            state.calls = state.calls + 1
            if state.fail then error("test provider failure") end
            return state.index, state.reason
        end
    }}}
    env.GameTooltip = {IsOwned = function() return false end}
    env.SlashCmdList = {}
    env.C_AddOns = {GetAddOnMetadata = function() return "test" end}
    env.print = function(message) table.insert(state.messages, message) end
    local chunk = assert(loadfile(source))
    setfenv(chunk, env)()
    function state:tick(n)
        for _ = 1, n or 1 do self.frames[1].scripts.OnUpdate(self.frames[1], 0.25) end
    end
    function state:event(event) self.frames[1].scripts.OnEvent(self.frames[1], event) end
    function state:marked()
        local count, index = 0, nil
        for i = 2, #self.frames do
            if self.frames[i].shown then count, index = count + 1, self.frames[i].parent.index end
        end
        return count, index
    end
    return state, env
end
local function test(name, fn)
    fn()
    tests = tests + 1
    print("PASS " .. name)
end
test("exactly one recommendation and cached scoring", function()
    local s = fixture(); s:tick(8)
    local n, i = s:marked(); assert(n == 1 and i == 2 and s.calls == 1)
end)
test("delayed item information", function()
    local s = fixture(); s.index = -5; s:tick(); assert(s:marked() == 0)
    s.index = 1; s:tick(); local n, i = s:marked(); assert(n == 1 and i == 1)
end)
test("no recommendation is cached", function()
    local s = fixture(); s.index = nil; s.reason = "Context token"; s:tick(8)
    assert(s.calls == 1 and s:marked() == 0)
end)
test("next quest replaces marker", function()
    local s = fixture(); s:tick(); s.quest = 102; s.index = 1; s.reason = "money"; s:tick()
    local n, i = s:marked(); assert(n == 1 and i == 1 and s.calls == 2)
end)
test("equipment and specialization invalidate result", function()
    local s = fixture(); s:tick()
    for _, e in ipairs({"PLAYER_EQUIPMENT_CHANGED", "PLAYER_SPECIALIZATION_CHANGED"}) do s:event(e); s:tick() end
    assert(s.calls == 3)
end)
test("quest close clears marker", function()
    local s, e = fixture(); s:tick(); s:event("QUEST_FINISHED")
    e.DUIQuestFrame.choosing = false; s:tick(); assert(s:marked() == 0)
end)
test("disabled Zygor suggestions clear marker", function()
    local s, e = fixture(); s:tick(); e.ZygorGuidesViewer.db.profile.questitemselector = false
    s:tick(); assert(s:marked() == 0)
end)
test("recycled button does not keep stale marker", function()
    local s = fixture(); s:tick(); s.buttons[2].type = "reward"; s:tick(); assert(s:marked() == 0)
end)
test("invalid index does not mark anything", function()
    local s = fixture(); s.index = 3; s:tick(); assert(s:marked() == 0)
end)
test("timeout bounds scoring and item event allows recovery", function()
    local s = fixture(); s.index = -5; s:tick(100); assert(s.calls == 40)
    s.index = 2; s:event("GET_ITEM_INFO_RECEIVED"); s:tick(); assert(s:marked() == 1)
end)
test("provider error pauses once and remains diagnosable", function()
    local s, e = fixture(); s.fail = true; s:tick(20)
    assert(s.calls == 1 and #s.messages == 1 and s:marked() == 0)
    e.SlashCmdList.DUIZYGOR()
    assert(s.messages[#s.messages]:find("test provider failure", 1, true))
end)
test("missing button API clears marker and reports once", function()
    local s, e = fixture(); s:tick(); e.DUIQuestFrame.itemButtonPool = nil; s:tick(10)
    assert(s:marked() == 0 and #s.messages == 1)
end)
print(tests .. " tests passed")
