local ADDON_NAME, Addon = ...
local Judgement = {}

Addon.Judgement = Judgement

local function MakeVerdict(type, payload)
    return {
        type = type,
        reason = payload.reason,
        severity = payload.severity,
        relocation = payload.relocation,
        movement = payload.movement,
        metadata = payload.metadata or {},
    }
end

local function EvaluateCampaignGate(context)
    if not context.campaign.active then
        return MakeVerdict("ALLOW", {
            reason = "NO_ACTIVE_CAMPAIGN",
            severity = "OFF",
        })
    end
end

local function EvaluateIntegrity(context)
    if not context.integrity.safeToEnforce then
        return MakeVerdict("ALLOW", {
            reason = "CONTEXT_INTEGRITY_FAILURE",
            severity = "SYSTEM",
            metadata = {
                issues = context.integrity.issues,
            },
        })
    end
end

local function EvaluateMountAttempt(context)
    if context.trigger.type ~= "MOUNT_ATTEMPT" then
        return
    end

    if context.environment.indoors then
        return MakeVerdict("BLOCK_MOUNT", {
            reason = "INDOOR_RESTRICTION",
            severity = context.campaign.severity,
        })
    end
end

local function EvaluateMountedState(context)
    if context.trigger.type ~= "MOUNT_STATE_CHANGED" then
        return
    end

    if not context.mount.mounted then
        return
    end

    if context.environment.flying and context.environment.indoors then
        return MakeVerdict("BLOCK_AND_DISMOUNT", {
            reason = "AIRSPACE_VIOLATION",
            severity = context.campaign.severity,
            relocation = "AIR_DESCENT_CONE",
        })
    end
end

local function EvaluateMovement(context)
    if context.trigger.type ~= "MOVEMENT_STARTED" then
        return
    end

    if context.environment.indoors and context.movement.locomotion == "ground" then
        return
    end
end

local evaluators = {
    EvaluateCampaignGate,
    EvaluateIntegrity,
    EvaluateMountAttempt,
    EvaluateMountedState,
    EvaluateMovement,
}

function Judgement.Evaluate(context)
    for _, evaluator in ipairs(evaluators) do
        local verdict = evaluator(context)
        if verdict then
            return verdict
        end
    end

    return MakeVerdict("ALLOW", {
        reason = "NO_RULE_TRIGGERED",
        severity = context.campaign.severity,
    })
end

