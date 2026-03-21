-- =========================================================
-- 玩家框体锚点解析
-- =========================================================

local VFlow = _G.VFlow
if not VFlow then return end

local PLAYER_FRAME_CANDIDATES = {
    "ElvUF_Player",
    "SUFUnitplayer",
    "UUF_Player",
    "MSUF_player",
    "EQOLUFPlayerFrame",
    "oUF_Player",
}

local INVERTED_ANCHORS = {
    TOPLEFT = "BOTTOMLEFT",
    TOPRIGHT = "BOTTOMRIGHT",
    BOTTOMLEFT = "TOPLEFT",
    BOTTOMRIGHT = "TOPRIGHT",
}

local anchorCacheVersion = 0
local cachedPlayerFrame = nil
local cachedVersion = -1
local playerFrameSettled = false

local function bumpAnchorCacheVersion()
    anchorCacheVersion = anchorCacheVersion + 1
end

local function resolvePlayerFrame()
    if cachedVersion == anchorCacheVersion and playerFrameSettled then
        if cachedPlayerFrame and cachedPlayerFrame.IsShown and cachedPlayerFrame:IsShown() then
            return cachedPlayerFrame
        end
        playerFrameSettled = false
    end

    for _, name in ipairs(PLAYER_FRAME_CANDIDATES) do
        local frame = _G[name]
        if frame and frame.IsShown and frame:IsShown() then
            cachedPlayerFrame = frame
            cachedVersion = anchorCacheVersion
            playerFrameSettled = true
            return cachedPlayerFrame
        end
    end

    local blizzFrame = _G.PlayerFrame
    if blizzFrame and blizzFrame.IsShown and blizzFrame:IsShown() then
        cachedPlayerFrame = blizzFrame
        cachedVersion = anchorCacheVersion
        local addonFramePending = false
        for _, name in ipairs(PLAYER_FRAME_CANDIDATES) do
            if _G[name] then
                addonFramePending = true
                break
            end
        end
        playerFrameSettled = not addonFramePending
        return cachedPlayerFrame
    end

    cachedPlayerFrame = nil
    cachedVersion = anchorCacheVersion
    return nil
end

local function getCorner(frame, point)
    if not frame then return nil, nil end
    local l, r, t, b = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
    if not (l and r and t and b) then return nil, nil end
    if point == "TOPLEFT" then
        return l, t
    elseif point == "TOPRIGHT" then
        return r, t
    elseif point == "BOTTOMLEFT" then
        return l, b
    elseif point == "BOTTOMRIGHT" then
        return r, b
    end
    return nil, nil
end

VFlow.PlayerAnchor = {
    GetContainerAnchorForPlayerPoint = function(playerPoint)
        return INVERTED_ANCHORS[playerPoint] or "BOTTOMLEFT"
    end,

    ResolvePlayerFrame = resolvePlayerFrame,

    InvalidateCache = function()
        bumpAnchorCacheVersion()
    end,

    ApplyContainerToPlayer = function(container, playerPoint, offsetX, offsetY)
        if not container then return false end
        local target = resolvePlayerFrame()
        if not target then
            return false
        end
        local cap = INVERTED_ANCHORS[playerPoint] or "BOTTOMLEFT"
        container:ClearAllPoints()
        container:SetPoint(cap, target, playerPoint, offsetX or 0, offsetY or 0)
        return true
    end,

    --- 根据当前帧在屏幕上的位置，反算相对玩家锚点的 offset（与 SetPoint 一致）
    ComputePlayerAnchorOffsets = function(container, targetFrame, playerPoint)
        if not container or not targetFrame then return 0, 0 end
        local cap = INVERTED_ANCHORS[playerPoint] or "BOTTOMLEFT"
        local cx, cy = getCorner(container, cap)
        local tx, ty = getCorner(targetFrame, playerPoint)
        if not (cx and cy and tx and ty) then return 0, 0 end
        return cx - tx, cy - ty
    end,
}

VFlow.on("PLAYER_ENTERING_WORLD", "PlayerAnchor", function()
    bumpAnchorCacheVersion()
end)

VFlow.on("LOADING_SCREEN_DISABLED", "PlayerAnchor", function()
    bumpAnchorCacheVersion()
end)
