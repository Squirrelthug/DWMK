local frame = CreateFrame("Frame")

local function TestPrint(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff88ccff[Dismounted Test]|r " .. msg)
end

-- Event Registration
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Dismounted_Test" then
            TestPrint("Addon loaded and listening")
        end
    
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, castGUID, spellID = ...
        if unit == "player" then
            TestPrint("Spell cast succeeded. SpellID: " .. tostring(spellID))
        end
    
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        -- ignore flight paths
        if UnitOnTaxi("player") then
            TestPrint("On taxi/flight path - ignoring")
            return
        end

        if IsMounted() then
            TestPrint("Mount detected")
            
            -- Figure out which mount BEFORE dismounting
            local mountID, spellID = nil, nil
            
            -- Try new C_UnitAuras API first (Midnight pre-patch)
            if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                TestPrint("Using new C_UnitAuras API")
                
                for i = 1, 40 do
                    local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
                    
                    if not auraData then
                        TestPrint("No more auras at slot " .. i)
                        break
                    end
                    
                    TestPrint("Slot " .. i .. ": " .. tostring(auraData.name) .. " (spellID: " .. tostring(auraData.spellId) .. ")")
                    
                    if C_MountJournal and C_MountJournal.GetMountFromSpell then
                        local foundMountID = C_MountJournal.GetMountFromSpell(auraData.spellId)
                        
                        if foundMountID then
                            mountID = foundMountID
                            spellID = auraData.spellId
                            TestPrint("SUCCESS: Found mount - " .. auraData.name)
                            break
                        end
                    end
                end
                
            else
                -- Fallback to old UnitAura (shouldn't be needed)
                TestPrint("Using old UnitAura API")
                
                for i = 1, 40 do
                    local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, auraSpellID = UnitAura("player", i, "HELPFUL")
                    
                    if not name then
                        TestPrint("No more auras at slot " .. i)
                        break 
                    end
                    
                    TestPrint("Slot " .. i .. ": " .. name .. " (spellID: " .. tostring(auraSpellID) .. ")")
                    
                    if C_MountJournal and C_MountJournal.GetMountFromSpell then
                        local foundMountID = C_MountJournal.GetMountFromSpell(auraSpellID)
                        
                        if foundMountID then
                            mountID = foundMountID
                            spellID = auraSpellID
                            TestPrint("SUCCESS: Found mount - " .. name)
                            break
                        end
                    end
                end
            end
        
            if not mountID then
                TestPrint("ERROR: Mounted but couldn't detect which mount!")
            end
        
            -- Dismount after we've detected the mount
            Dismount()
            TestPrint("Player dismounted for testing")
        end
    end
end)