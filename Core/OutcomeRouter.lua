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

function OutcomeRouter:ApplyVerdict(verdict, context)
    if not verdict or not verdict.type then
        return
    end

    if verdict.type == "ALLOW" then
        return
    end

    if verdict.type == "BLOCK" then
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
