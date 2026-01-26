local Defaults = {}

Defaults.CAMPAIGN_SCHEMA_VERSION = 1

Defaults.DefaultSettings = {
    active = true,
    mountPersistence = true,
    anchorOnDismount = true,
    anchorRadius = 30,
}

Defaults.DefaultCampaign = {
    id = "default_world_campaign",
    name = "Default World Campaign",
    description = "A grounded, persistent travel experience.",
    schemaVersion = Defaults.CAMPAIGN_SCHEMA_VERSION,

    settings = CopyTable(Defaults.DefaultSettings),

    mounts = {
        [mountID] ={
            lastSeen = {mapID, x, y, timestamp },
            state = {anchored = true/false },
            lastDismountReason = "VOLUNTARY" | "FORCED" | "UNKNOWN"
        }
    }
}

Defaults.OffState = {
    activeCampaignID = nil
}

return Defaults

