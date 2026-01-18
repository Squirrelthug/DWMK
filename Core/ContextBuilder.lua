local ADDON_NAME, Addon = ...
local ContextBuilder = {}

Addon.ContextBuilder = ContextBuilder

-- localize global functions
local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitLevel = UnitLevel
local UnitClass = UnitClass
local UnitRace = UnitRace
local UnitFactionGroup = UnitFactionGroup
local IsMounted = IsMounted
local IsIndoors = IsIndoors
local IsFlying = IsFlying
local IsSwimming = IsSwimming

-- snapshotting for race conditions
local snapshotCounter = 0

local function NextSnapshotID()
    snapshotCounter = snapshotCounter + 1
    return snapshotCounter
end

local function BuildMeta(triggerType)
    return {
        snapshotID = NextSnapshotID(),
        timestamp = GetTime(),
        addonVersion = Addon.version or "dev",
        evaluationReason = triggerType,
    }
end

local function BuildTrigger(trigger)
    return {
        type = trigger.type,
        unit = trigger.unit or "player",
        reactive = trigger.reactive or false,
        rawHint = trigger.rawHint,
    }
end

local function BuildCampaign()
    local Campaigns = Addon.Campaigns

    if not Campaigns or not Campaigns.IsActive() then
        return {
            active = false,
        }
    end

    local campaign = Campaigns.GetActiveCampaign()

    return {
        active = true,
        id = campaign.id,
        ruleProfile = campaign.ruleProfile,
        severity = campaign.severity,
        overrides = campaign.overrides,
    }
end

-- player section
local function BuildPlayer()
    local className, classFile = UnitClass("player"),
    local raceName, raceFile = Unitrace("player"),
    local faction = UnitFactionGroup("player")

    return {
        guid = UnitGUID("player"),
        level = UnitLevel("player"),
        class = classFile,
        race = raceFile,
        faction = faction,
        mounted = IsMounted(),
    }
end

-- environments
local funciton BuildEnvironment