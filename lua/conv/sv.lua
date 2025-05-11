local ENT = FindMetaTable("Entity")


--[[
==================================================================================================
                    DAMAGE
==================================================================================================
--]]

-- Returns an CTakeDamageInfo object with some basic values set
function conv.damageBasic(damage, dmgtype, pos, attacker)
    local dmginfo = DamageInfo()
    dmginfo:SetAttacker(attacker)
    dmginfo:SetInflictor(attacker)
    dmginfo:SetDamage(damage)
    dmginfo:SetDamageType(dmgtype)
    dmginfo:SetDamagePosition(pos)
    return dmginfo
end

--[[
==================================================================================================
                    NPC SPAWNING
==================================================================================================
--]]

-- Spawn a NPC from the spawn menu
function conv.createSpawnMenuNPC( SpawnMenuClass, pos, wep, beforeSpawnFunc )
    -- Find NPC in spawn menu
    local SpawnMenuTable = ents._SpawnMenuNPCs[SpawnMenuClass]

    -- Check if zbase npc
    local isZBaseNPC = ZBaseInstalled && ZBaseNPCs[SpawnMenuClass]
    
    -- No such NPC
    if !SpawnMenuTable then
        ErrorNoHaltWithStack("No such NPC found: '", SpawnMenuClass, "'\n")
        return
    end

    -- Create NPC
    local NPC = ents.Create( isZBaseNPC && SpawnMenuClass or SpawnMenuTable.Class )

    -- No such NPC
    if !IsValid(NPC) then
        ErrorNoHaltWithStack("No such NPC found: '", SpawnMenuTable.Class, "'\n")
        return
    end

    -- Position
    if isvector(pos) then
        NPC:SetPos(pos)
    end

    -- Default weapons if none if provided
    wep = wep or (SpawnMenuTable.Weapons && table.Random(SpawnMenuTable.Weapons))
    if isstring(wep) then
        NPC:Give( wep )
    end

    -- Key values
    if SpawnMenuTable.KeyValues then
        for key, value in pairs(SpawnMenuTable.KeyValues) do
            NPC:SetKeyValue(key, value)
        end
    end

    -- Set stuff
    if SpawnMenuTable.Model then NPC:SetModel(SpawnMenuTable.Model) end
    if SpawnMenuTable.Skin then NPC:SetSkin(SpawnMenuTable.Skin) end
    if SpawnMenuTable.Health then NPC:SetMaxHealth(SpawnMenuTable.Health) NPC:SetHealth(SpawnMenuTable.Health) end
    if SpawnMenuTable.Material then NPC:SetMaterial(SpawnMenuTable.Material) end
    if SpawnMenuTable.SpawnFlags then NPC:SetKeyValue("spawnflags", SpawnMenuTable.SpawnFlags) end

    if isfunction(beforeSpawnFunc) then
        beforeSpawnFunc( NPC )
    end

    -- Spawn and Activate
    NPC:Spawn()
    NPC:Activate()

    return NPC
end


-- Spawns an entity for a short duration allowing you to obtain info about it
function conv.getEntInfo( cls, func )
    local ent = ents.Create(cls)
    if !IsValid(ent) then
        ErrorNoHaltWithStack("No such ENT found: '", cls, "'\n")
        return
    end

    ent:Spawn()
    ent:Activate()

    conv.callNextTick(function( Ent )
        func(Ent)
        Ent:Remove()
    end, ent)
end


--[[
==================================================================================================
                    Spawnflags
==================================================================================================
--]]

function ENT:CONV_SetSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.bor(...))
end

function ENT:CONV_AddSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.bor(self:GetSpawnFlags(), ...))
end

function ENT:CONV_RemoveSpawnFlags(...)
    self:SetKeyValue("spawnflags", bit.band(self:GetSpawnFlags(), bit.bnot(...)))
end


--[[
==================================================================================================
                                           CALL ON CLIENT
==================================================================================================
--]]

-- Used to call a function on a client from the server -- 
function conv.callOnClient( ply, ent, functionName, ... )
	if !isstring(functionName) || !... then return end

	local data = {...}
    
    data = conv.tableToString( data )
    ent = IsValid(ent) && tostring( ent:EntIndex() ) || ent || ""
    
    net.Start( "CONV_CallOnClient" )
    net.WriteString( ent )
    net.WriteString( functionName )
    net.WriteString( data )
    
    if ply && IsValid(ply) && ply:IsPlayer() then
        net.Send( ply )
    else
        net.Broadcast()
    end
end


--[[
==================================================================================================
                    LUA RUN
==================================================================================================
--]]

-- Creates the lua_run entity to be used with related functions -- 
function conv.createLuaRun()
	CONV_LUA_RUN_ENT = ents.Create( "lua_run" )
	if IsValid(CONV_LUA_RUN_ENT) then
		CONV_LUA_RUN_ENT:SetName( "CONV_LUA_RUN_ENT" )
		CONV_LUA_RUN_ENT:Spawn()
	end
end

-- Creates a hook that runs whenever the set entity fires the specified output. -- 
function ENT:CONV_CreateOutputHook(entOutput, eventName, delay, repetitions)
	if !IsValid(CONV_LUA_RUN_ENT) then conv.createLuaRun() end
	
	delay = delay || 0
	repetitions = repetitions || -1
	
	self:Fire( "AddOutput", entOutput .. " CONV_LUA_RUN_ENT:RunPassedCode:hook.Run( '" .. eventName .. "' ):" .. delay .. ":" .. repetitions .. "" )
end

-- Creates a function that runs whenever the set entity fires the specified output. -- 
function ENT:CONV_CreateOutputFunction(entOutput, func, delay, repetitions)
	if !self || !IsValid(self) then return end
	if !IsValid(CONV_LUA_RUN_ENT) then conv.createLuaRun() end
	
	delay = delay || 0
	repetitions = repetitions || -1

	local hookID = entOutput .. self:GetClass() .. self:EntIndex()

	hook.Add(hookID, self, function() 

		local activator, caller = ACTIVATOR, CALLER
		func(self, activator, caller)

	end)

	self:Fire( "AddOutput", entOutput .. " CONV_LUA_RUN_ENT:RunPassedCode:hook.Run( '" .. hookID .. "' ):" .. delay .. ":" .. repetitions .. "" )
end

--[[
==================================================================================================
					UI
==================================================================================================
--]]

local scrWidth = 1920
local scrHeight = 1080

-- Used to get the width of the player's screen.
function conv.ScrW(ply)
    return ply.CONV_SCRNW
end

-- Used to get the height of the player's screen.
function conv.ScrH(ply)
    return ply.CONV_SCRNH
end

-- Used to properly scale position and width of an UI elemet to different screen resolutions.
function conv.ScrWScale(ply)
	return conv.ScrW(ply) / scrWidth
end

-- Used to properly scale position and height of an UI elemet to different screen resolutions.
function conv.ScrHScale(ply)
	return conv.ScrH(ply) / scrHeight
end

-- Returns the central point of the horizontal axis.
function conv.ScrWCenter()
	return scrWidth / 2
end

-- Returns the central point of the vertical axis.
function conv.ScrHCenter()
	return scrHeight / 2
end