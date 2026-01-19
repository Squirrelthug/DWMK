local ADDON_NAME, Addon = ...
local OutcomeRouter = {}

Addon.OutcomeRouter = OutcomeRouter

-- localize api for performance
local Dismount = Dismount
local CancelPendingSpell = CancelPendingSpell
local InCombatLockdown = InCombatLockdown
local IsMounted = IsMounted

local function EnforceDismount()
    if IsMounted() and not InCombatLockdown() then
        Dismount()
    end
end

local function EnforceSpellCancel()
    if not InCombatLockdown() then
        CancelPendingSpell()
    end
end

local function EmitFeedback(feedback)
    if not feedback then
        return
    end

    local MessageBus = Addon.MessageBus
    if not MessageBus then
        return
    end

    MessageBus:Dispatch(feedback)
end

local function RecordOutcome(eventType, verdict, context)
    if not context or not context.campaign or not context.campaign.active then
        return
    end

    local campaignID = context.campaign.id
    if not campaignID then
        return
    end

    local MountHistory = Addon.MountHistory
    if not MountHistory or not MountHistory.Add then
        return
    end

    local payload = {
        verdict = verdict and verdict.type or nil,
        reason = verdict and verdict.reason or nil,

        snapshotID = context.meta and context.meta.snapshotID or nil,
        triggerType = context.meta and context.meta.evaluationReason or nil,

        mapID = context.location and context.location.mapID or nil,
        x = context.location and context.location.x or nil,
        y = context.location and context.location.y or nil,

        meta = verdict and verdict.feedback and { feedback = verdict.feedback.key or verdict.feedback.id } or nil,
    }

    MountHistory:Add(campaignID, eventType, payload)
end

function OutcomeRouter:ApplyVerdict(verdict, context)
    if not verdict or not verdict.type then
        return
    end

    if verdict.type == "ALLOW" then
        return
    end

    if verdict.type == "BLOCK_MOUNT" then
        EnforceSpellCancel()
        EmitFeedback(verdict.feedback)
        return
    end

    if verdict.type == "BLOCK_AND_DISMOUNT" then
        EnforceSpellCancel()
        EnforceDismount()
        EmitFeedback(verdict.feedback)
        return
    end

    if verdict.type == "BLOCK_AND_RELOCATE" then
        EnforceSpellCancel()
        EnforceDismount()

        if verdict.relocation then
            Addon.RelocationEngine:Execute(
                verdict.relocation,
                context
            )
        end

        EmitFeedback(verdict.feedback)
        return
    end
end
