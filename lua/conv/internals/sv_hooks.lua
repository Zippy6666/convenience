--[[
==================================================================================================
					HOOK EXPANSION
==================================================================================================
--]]

hook.Add("OnNPCKilled", "CONV_COMPATIBILITY", function(npc, attacker, inflictor)    
    hook.Run( "OnKilledNPC", attacker, npc, inflictor )
    --hook.Run( "OnKilledNPC", inflictor, npc, attacker )
end)

hook.Add("EntityTakeDamage", "CONV_COMPATIBILITY", function(ent, dmginfo) 
    if conv.dmgInfoGetDamager(dmginfo) then hook.Run( "EntityDealDamage", conv.dmgInfoGetDamager(dmginfo), ent, dmginfo ) end
end)

hook.Add("ScaleNPCDamage", "CONV_COMPATIBILITY", function(npc, hitgroup, dmginfo) 
    if conv.dmgInfoGetDamager(dmginfo) then hook.Run( "NPCDamageScale", conv.dmgInfoGetDamager(dmginfo), npc, hitgroup, dmginfo ) end
end)

hook.Add("PlayerDeath", "CONV_COMPATIBILITY", function(ply, inflictor, attacker) 
    if IsValid(attacker) then hook.Run( "PlayerKilled", attacker, ply, inflictor ) end
    if IsValid(inflictor) then hook.Run( "PlayerKilled", inflictor, ply, attacker ) end
end)