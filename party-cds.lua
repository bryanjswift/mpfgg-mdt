--CHANGE HERE--
aura_env.maxAuraCount = 7
aura_env.xOffset = 0
aura_env.yOffset = -1
aura_env.spacing = 2
-- TOPLEFT,TOP,TOPRIGHT,RIGHT,BOTTOMRIGHT,BOTTOM,BOTTOMLEFT,LEFT,CENTER
aura_env.positionFromArr = {
  ["default"] = "TOPRIGHT",
  [1] = "TOPRIGHT",
  [2] = "TOPRIGHT",
  [3] = "TOPRIGHT",
  [4] = "TOPLEFT",
  [5] = "TOPLEFT",
}
-- TOPLEFT,TOP,TOPRIGHT,RIGHT,BOTTOMRIGHT,BOTTOM,BOTTOMLEFT,LEFT,CENTER
aura_env.positionToArr = {
  ["default"] = "TOPLEFT",
  [1] = "TOPLEFT",
  [2] = "TOPLEFT",
  [3] = "TOPLEFT",
  [4] = "TOPRIGHT",
  [5] = "TOPRIGHT"
}
-- LEFT,TOP,RIGHT,BOTTOM,HORIZONTAL,VERTICAL (use last 2 with CENTER)
aura_env.growDirectionArr = {
  ["default"] = "LEFT",
  [1] = "LEFT",
  [2] = "LEFT",
  [3] = "LEFT",
  [4] = "RIGHT",
  [5] = "RIGHT",
}
aura_env.ignorePlayer = false


aura_env.rows = {
    [1] = {
        [1] = "DAMAGE",
        [2] = "HEALING",
        [3] = "EXTERNAL",
    },
    [2] = {
        [1] = "IMMUNITY",
        [2] = "PERSONAL",
    },
}

---------------
---------------

aura_env.types = {}
for rowIdx,row in ipairs(aura_env.rows) do
    for priority,type in ipairs(row) do
        aura_env.types[type] = true
    end
end

aura_env.auraCount = {}

--credit to buds
--https://wago.io/BFADungeonTargetedSpells
local frame_priority = {
    -- raid frames
    [1] = "^Vd1", -- vuhdo
    [2] = "^Healbot", -- healbot
    [3] = "^GridLayout", -- grid
    [4] = "^Grid2Layout", -- grid2
    [5] = "^ElvUF_RaidGroup", -- elv
    [6] = "^oUF_bdGrid", -- bdgrid
    [7] = "^oUF.*raid", -- generic oUF
    [8] = "^LimeGroup", -- lime
    [9] = "^SUFHeaderraid", -- suf
    [10] = "^CompactRaid", -- blizz
    -- party frames
    [11] = "^SUFHeaderparty", --suf
    [12] = "^ElvUF_PartyGroup", -- elv
    [13] = "^oUF.*party", -- generic oUF
    [14] = "^PitBull4_Groups_Party", -- pitbull4
    [15] = "^CompactParty", -- blizz
    -- player frame
    [16] = "^SUFUnitplayer",
    [17] = "^PitBull4_Frames_Player",
    [18] = "^ElvUF_Player",
    [19] = "^oUF.*player",
    [20] = "^PlayerFrame",
}

WA_GetFramesCache = WA_GetFramesCache or {}
if not WA_GetFramesCacheListener then
    WA_GetFramesCacheListener = CreateFrame("Frame")
    local f = WA_GetFramesCacheListener
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("PLAYER_REGEN_ENABLED")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:SetScript("OnEvent", function(self, event, ...)
            WA_GetFramesCache = {}
    end)
end

local ignoredFrames = {
    ["SUFUnitplayer"]=true,
    ["PitBull4_Frames_Player"]=true,
    ["PitBull4_Frames_Target"]=true,
    ["PitBull4_Frames_TargetTarget"]=true,
    ["ElvUF_Player"]=true,
    ["ElvUF_Target"]=true,
    ["ElvUF_TargetTarget"]=true,
    ["oUF_TukuiPlayer"]=true,
    ["oUF_TukuiTarget"]=true,
    ["oUF_TukuiTargetTarget"]=true,
    ["PlayerFrame"]=true,
    ["TargetFrame"]=true,
    ["TargetTargetFrame"]=true,
}

local function GetFrames(target)
    local function FindButtonsForUnit(frame, target)
        local results = {}
        if type(frame) == "table" and not frame:IsForbidden() then
            local type = frame:GetObjectType()
            if type == "Frame" or type == "Button" then
                for _,child in ipairs({frame:GetChildren()}) do
                    for _,v in pairs(FindButtonsForUnit(child, target)) do
                        tinsert(results, v)
                    end
                end
            end
            if type == "Button" then
                local unit = frame:GetAttribute('unit')
                if unit and frame:IsVisible() and frame:GetName() then
                    WA_GetFramesCache[frame] = unit
                    if UnitIsUnit(unit, target) then
                        tinsert(results, frame)
                    end
                end
            end
        end
        return results
    end

    if not UnitExists(target) then
        if type(target) == "string" and target:find("Player") then
            target = select(6,GetPlayerInfoByGUID(target))
        else
            target = target:gsub(" .*", "")
            if not UnitExists(target) then
                return {}
            end
        end
    end

    local results = {}
    for frame, unit in pairs(WA_GetFramesCache) do
        --print("from cache:", frame:GetName())
        if UnitIsUnit(unit, target) then
            if frame:GetAttribute('unit') == unit then
                tinsert(results, frame)
            else
                results = {}
                break
            end
        end
    end

    return #results > 0 and results or FindButtonsForUnit(UIParent, target)
end

local isElvUI = IsAddOnLoaded("ElvUI")
local function WhyElvWhy(frame)
    if isElvUI and frame and frame:GetName():find("^ElvUF_") and frame.Health then
        return frame.Health
    else
        return frame
    end
end


function aura_env.GetFrame(target)
    local frames = GetFrames(target)
    if not frames then return nil end
    for i=1,#frame_priority do
        for _,frame in pairs(frames) do
            if (not ignoredFrames[frame:GetName()]) and (frame:GetName()):find(frame_priority[i]) then
                return WhyElvWhy(frame)
            end
        end
    end
    if frames[1] and (not ignoredFrames[frames[1]:GetName()]) then
        return WhyElvWhy(frames[1])
    end
end

local function setIconPosition(v,rowIdx)
    local unit
    local displayIdx = 0
    local children = { CompactRaidFrameContainer:GetChildren() }
    for frameIdx, frame in ipairs(children) do
        local u = frame:GetAttribute('unit')
        if UnitName(u) == v.name then
          unit = u
          displayIdx = frameIdx
        end
    end
    if not unit then
        v.show = false
        v.changed = true
    else
        v.unit = unit
        local region = WeakAuras.GetRegion(aura_env.id, v.ID)
        local positionTo = aura_env.positionToArr[displayIdx]
        if not positionTo then
            positionTo = aura_env.positionToArr["default"]
        end
        local positionFrom = aura_env.positionFromArr[displayIdx]
        if not positionFrom then
            positionFrom = aura_env.positionFromArr["default"]
        end
        local growDirection = aura_env.growDirectionArr[displayIdx]
        if not growDirection then
            growDirection = aura_env.growDirectionArr["default"]
        end
        local f = aura_env.GetFrame(v.unit)
        if f and region --[[and region:IsVisible()]] then
            aura_env.auraCount[v.unit] = aura_env.auraCount[v.unit] or {}
            aura_env.auraCount[v.unit][rowIdx] = aura_env.auraCount[v.unit][rowIdx] or 0

            local order = aura_env.auraCount[v.unit][rowIdx]
            local xoffset, yoffset = 0, 0
            local height,width = region:GetHeight()+aura_env.spacing, region:GetWidth()+aura_env.spacing
            if growDirection == "TOP" then
                yoffset = (order) * height
                xoffset = xoffset + (rowIdx-1)*height
            elseif growDirection == "BOTTOM" then
                yoffset = - (order) * height
                xoffset = xoffset + (rowIdx-1)*height
            elseif growDirection == "RIGHT" then
                xoffset = (order) * width
                yoffset = yoffset - (rowIdx-1)*height
            elseif growDirection == "LEFT" then
                xoffset = - (order) * width
                yoffset = yoffset - (rowIdx-1)*height
            elseif growDirection == "HORIZONTAL" then
                xoffset = (-((order) * width / 2)) + ((order - 1) * width)
            elseif growDirection == "VERTICAL" then
                xoffset = (-((order) * width / 2)) + ((order - 1) * width)
            end
            if aura_env.auraCount[v.unit][rowIdx]+1 > aura_env.maxAuraCount then
                xoffset = -3000
            end
            region:ClearAllPoints()
            region:SetPoint(positionFrom,f,positionTo,xoffset+aura_env.xOffset,yoffset+aura_env.yOffset)
            aura_env.auraCount[v.unit][rowIdx] = aura_env.auraCount[v.unit][rowIdx] + 1
        else
            region:ClearAllPoints()
            region:SetPoint(positionFrom,UIParent,positionTo,-3000,0)
        end
    end
end


function aura_env.updateFrames()
    local allstates = aura_env.allstates
    if not allstates then return end
    table.wipe(aura_env.auraCount)
    for rowIdx,row in ipairs(aura_env.rows) do
        for priority,type in ipairs(row) do
            for _, v in pairs(allstates) do
                if v.type == type then
                    setIconPosition(v,rowIdx)
                end
            end
        end
    end
end
