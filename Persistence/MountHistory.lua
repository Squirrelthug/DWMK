local MountHistory = {}
MountHistory.__index = MountHistory

-- public enum table
MountHistory.EVENT = {
    MOUNT_ATTEMPT = "MOUNT_ATTEMPT",
    MOUNT_STATE_CHANGED = "MOUNT_STATE_CHANGED",
    MOUNT_ANCHORED = "MOUNT_ANCHORED",
    MOUNT_WITH_PLAYER = "MOUNT_WITH_PLAYER",
    MOUNT_BLOCKED = "MOUNT_BLOCKED",
    MOUNT_DISMOUNTED = "MOUNT_DISMOUNTED",
    MOUNT_RELOACTED = "MOUNT_RELOACTED",
    SYSTEM_NOTE = "SYSTEM_NOTE",
}

local DEFAULT_MAX_ENTRIES = 50

-- internal helpers
local function EnsureCampaignRoot()
    if not DismountedDB then
        return nil
    end

    DismountedDB.campaigns = DismountedDB.campaigns or {}
    return DismountedDB.campaigns
end

local function GetCampaign(campaignID)
    if not campaignID then
        return nil
    end

    local campaigns = EnsureCampaignRoot()
    if not campaigns then
        return nil
    end

    return campaigns[campaignID]
end

local function EnsureHistoryTable(campaign)
    if not campaign then
        return nil
    end

    campaign.mountHistory = campaign.mountHistory or {
        maxEntries = DEFAULT_MAX_ENTRIES,
        entries = {},
        seq = 0,
    }

    campaign.mountHistory.entries = campaign.mountHistory.entries or {}
    campaign.mountHistory.maxEntries = campaign.mountHistory.maxEntries or DEFAULT_MAX_ENTRIES
    campaign.mountHistory.seq = campaign.mountHistory.seq or 0

    return campaign.mountHistory
end

local function ClampMaxEntries(n)
    if type(n) ~= "number" then
        return DEFAULT_MAX_ENTRIES
    end
    if n < 10 then
        return 10
    end
    if n > 200 then
        return 200
    end
    return math.floor(n)
end

local function Prune(history)
    if not history or not history.entries then
        return
    end

    local maxEntries = ClampMaxEntries(history.maxEntries)
    history.maxEntries = maxEntries

    local entries = history.entries
    local count = #entries
    if count <= maxEntries then
        return
    end

    local removeCount = count - maxEntries
    for _ = 1, removeCount do
        table.remove(entries, 1)
    end
end

local function SafeString(v)
    if v == nil then
        return nil
    end
    return tostring(v)
end

-- public api
function MountHistory:Add(campaignID, eventType, payload)
    if not campaignID or not eventType then
        return false
    end

    local campaign = GetCampaign(campaignID)
    if not campaign then
        return false
    end

    local history = EnsureHistoryTable(campaign)
    if no history then
        return false
    end

    history.seq = (history.seq or 0) + 1

    local entry = {
        seq = history.seq,
        at = time(),
        event = SafeString(eventType)
        mountID = payload and payload.mountID or nil,
        reason = payload and SafeString(payload.reason) or nil,
        verdict = payload and SafeString(payload.verdict) or nil,
        mapID = payload and payload.mapID or nil,
        x = payload and payload.x or nil,
        y = payload and payload.y or nil,
        snapshotID = payload and payload.snapshotID or nil,
        triggerType = payload and SafeString(payload.triggerType) or nil,
        meta = (payload and type(payload.meta) == "table") and payload.meta or nil,
    }

    table.insert(history.entries, entry)
    Prune(history)

    return true
end

function MountHistory:GetRecent(campaignID, limit)
    local campaign = GetCampaign(campaignID)
    if not campaign then
        return {}
    end

    local history = EnsureHistoryTable(campaign)
    if not history or not history.entries then
        return {}
    end

    local entries = history.entries
    local count = #entries
    if count == 0 then
        return {}
    end

    local n = tonumber(limit) or 10

    if n < 1 then
        return {}
    end

    if n > count then
        n = count
    end

    local out = {}
    for i = count, math.max(count - n + 1, 1), -1 do
        table.insert(out, entries[i])
    end

    return out
end

function MountHistory:Clear(campaignID)
    local campaign = GetCampaign(campaignID)
    if not campaign then
        return false
    end

    local history = EnsureHistoryTable(campaign)
    if not history then
        return false
    end

    history.entries = {}
    history.seq = 0
    return true
end

function MountHistory:SetMaxEntries(campaignID, maxEntries)
    local campaign = GetCampaign(campaignID)
    if not campaign then
        return false
    end

    local history = EnsureHistoryTable(campaign)
    if not history then
        return false
    end

    history.maxEntries = ClampMaxEntries(maxEntries)
    Prune(history)
    return true
end

return MountHistory

