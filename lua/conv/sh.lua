local developer = GetConVar("developer")
local ENT = FindMetaTable("Entity")
local NPC = FindMetaTable("NPC")

--[[
==================================================================================================
                    TIMER / TICK STUFF
==================================================================================================
--]]


-- Do something next tick/frame
function conv.callNextTick( func, ... )

    local argtbl = table.Pack(...)

    timer.Simple(0, function()
        func(unpack(argtbl))
    end)

end


-- Do something after a certain amount of ticks/frames
function conv.callAfterTicks( ticknum, func, ... )

    conv.callNextTick( function( ... )

        if ticknum <= 0 then
            func(...)
        else
            conv.callAfterTicks( ticknum-1, func, ... )
        end


    end, ... )

end


-- An ipairs for loop that runs the code every tick
-- 'func' sends key and value as arguments
-- Example:
-- conv.tickForEach( tbl, function(k, v)
--     print(k, v)
-- end)
-- Slow and useless maybe idk lol
function conv.tickForEach( tbl, func )
    for k, v in ipairs(tbl) do
        conv.callAfterTicks( k, func, k, v )
    end
end


-- Similiar to CONV_TempVar
-- Set a global to true for some duration before removing it
-- Calling it again will cause the lifetime of the global to reset
function conv.tempCond( global_name, lifetime )
    _G[global_name] = true
    timer.Create("conv.tempCond_"..global_name, lifetime, 1, function()
        _G[global_name] = nil
    end)
end


--[[
==================================================================================================
                    WRAPPER FUNCTIONS
==================================================================================================
--]]


-- Create a wrapper function around the desired function
-- 'preFunc' - Function to run before running the target function, passes the same arguments
-- 'postFunc' - Code to run AFTER running the function, passes a table of return values followed by the function arguments,
--  You can override the return values by returning something else in either of the functions
function conv.wrapFunc( uniqueID, func, preFunc, postFunc )
    if not isfunction(func) then
        error("The function does not exist!")
    end


    -- Store original func
    conv.wrapFunc_OriginalFuncs = conv.wrapFunc_OriginalFuncs or {}
    if not conv.wrapFunc_OriginalFuncs[uniqueID] then
        conv.wrapFunc_OriginalFuncs[uniqueID] = func
    end


    local ogfunc = conv.wrapFunc_OriginalFuncs[uniqueID]
    if not isfunction(ogfunc) then
        return -- Func was removed?
    end


    local wrappedFunc = function(...)
        if isfunction(preFunc) then
            local returnValuesPre = table.Pack( preFunc( ... ) )

            if istable(returnValuesPre) and not table.IsEmpty(returnValuesPre) then
                return unpack(returnValuesPre)
            end
        end

        local returnValues = table.Pack( ogfunc(...) )


        if isfunction(postFunc) then
            local returnValuesPost = table.Pack( postFunc( returnValues, ... ) )

            if not table.IsEmpty(returnValuesPost) then
                return unpack(returnValuesPost)
            end
        end


        return unpack(returnValues)
    end

    return wrappedFunc
end


-- Same as above, but the original function is lost
function conv.wrapFunc2( func, preFunc, postFunc )
    if not isfunction(func) then
        error("The function does not exist!")
    end

    local wrappedFunc = function(...)
        if isfunction(preFunc) then
            preFunc( ... )
        end

        local returnValues = table.Pack( func(...) )


        if isfunction(postFunc) then
            local returnValues = table.Pack( postFunc( returnValues, ... ) )

            if not table.IsEmpty(returnValues) then
                return unpack(returnValues)
            end
        end


        return unpack(returnValues)
    end

    return wrappedFunc
end


--[[
==================================================================================================
                    FILES / INCLUDE
==================================================================================================
--]]


function conv.addFile( File, directory )
	local prefix = string.lower( string.Left( File, 3 ) )
    local isServerFile = (prefix == "sv_" or File=="sv.lua" or File=="init.lua")
    local isClientFile = (prefix == "cl_" or File=="cl.lua")
    local isSharedFile = (!isClientFile and not isServerFile)

	if isServerFile and SERVER then
		include( directory .. File )
        return
    end

    if isClientFile then
		if SERVER then
			AddCSLuaFile( directory .. File )
		elseif CLIENT then
			include( directory .. File )
		end

        return
    end

	if isSharedFile then
		AddCSLuaFile( directory .. File )
		include( directory .. File )
	end
end


function conv.includeDir( directory, skipSubstrs )
    skipSubstrs = skipSubstrs or {}

	directory = directory .. "/"

	local files, directories = file.Find( directory .. "*", "LUA" )
    local bSkip = false

	for _, v in ipairs( files ) do
        for _, skipSubstr in ipairs(skipSubstrs) do
            local res = string.find(v, skipSubstr)
            if res then
                bSkip = true
                break
            end
        end
        if bSkip then
            bSkip = false
            continue
        end

		if string.EndsWith( v, ".lua" ) then
			conv.addFile( v, directory )
		end
	end

	for _, v in ipairs( directories ) do
        for _, skipSubstr in ipairs(skipSubstrs) do
            local res = string.find(v, skipSubstr)
            if res then
                bSkip = true
                break
            end
        end
        if bSkip then
            bSkip = false
            continue
        end
		conv.includeDir( directory .. v, skipSubstrs )
	end
end

--[[
==================================================================================================
                    DEBUG
==================================================================================================
--]]


-- Prints but only if "developer" is more than 1
-- Also prints to all SuperAdmins on dedicated servers
function conv.devPrint(...)
    if developer:GetInt() < 1 && !(SERVER && game.IsDedicated()) then return end

    if SERVER and game.IsDedicated() then
        for _, superadmin in player.Iterator() do
            if superadmin:IsSuperAdmin() then
                local clprintStr = "[SERVER] "
                local clColStr = ""

                for _, v in ipairs(table.Pack(...)) do
                    if IsColor(v) then
                        clColStr = "Color("..v.r..", "..v.g..", "..v.b.."), "
                        continue
                    end

                    clprintStr = clprintStr..tostring(v)
                end

                local LuaSend = 'MsgC( '..clColStr..'"'..clprintStr..'" ) MsgN()'

                superadmin:SendLua( LuaSend )
            end
        end
    end

    local args = table.Pack(...)
    local foundCol = false
    for _, arg in ipairs(args) do
        if IsColor(arg) then
            MsgC(arg, SERVER and "[SERVER] " or "[CLIENT] ")
            foundCol = true
            break
        end
    end

    if not foundCol then
        MsgC(SERVER and "[SERVER] " or "[CLIENT] ")
    end

    MsgC(...)
    MsgN()
end


-- Debug Overlay QOL
-- https://wiki.facepunch.com/gmod/debugoverlay
-- conv.overlay("Something", function()
--     return {}
-- end)
function conv.overlay( funcname, argsFunc )
    if !developer:GetBool() then return end
    local args = argsFunc()
    debugoverlay[funcname](unpack(args))
end


-- Prints out information about what a function does
function conv.help(func)
    if not isfunction(func) then
        error("conv.help took an argument that is not a function!")
    end

    local funcinfo = debug.getinfo(func)
    local LineDefined = funcinfo.linedefined
    local shortSrc = funcinfo.short_src
    local pathShouldStartIdx = string.find(shortSrc, "/lua/")

    if not pathShouldStartIdx then
        MsgC(Color(155, 0, 0), "No information about this function could be found.\n")
        return
    end

    local luaPath = string.sub(shortSrc, pathShouldStartIdx + 5)

    -- Open the Lua file
    local f = file.Open(luaPath, "r", "LUA")
    if not f then
        error("Failed to open Lua file: " .. luaPath)
    end

    -- Read the entire file into memory
    local lines = {}
    while true do
        local line = f:ReadLine()
        if not line then break end
        table.insert(lines, line)
    end
    f:Close()

    -- Start looking upwards from the line above the function definition
    local comments = {}
    for i = LineDefined - 1, 1, -1 do
        local line = lines[i]
        -- Check if the line is a comment
        if string.match(line, "^%s*%-%-") then
            table.insert(comments, 1, line) -- Insert at the beginning for correct order
        else
            break -- Stop if we encounter a non-comment line
        end
    end

    -- Print the comments found
    if #comments > 0 then
        MsgC(Color(0, 155, 0), "'", func, "' help:\n")
        for _, comment in ipairs(comments) do
            MsgC(Color(0, 155, 0), comment)
        end
    else
        MsgC(Color(155, 0, 0), "No information about this function could be found.\n")
    end
end


--[[
==================================================================================================
                    PLAYER VISIBILITY
==================================================================================================
--]]


-- Checks if any player on the server can see this position right now
function conv.playersSeePos( pos )
    for _, ply in player.Iterator() do
        if conv.plyCanSeePos( ply, pos ) then
            return true
        end
    end
end



-- Checks if a player on the server can see this position right now
function conv.plyCanSeePos( ply, pos )
    local eyePos = ply:GetShootPos()
    local eyeAngles = ply:EyeAngles()
    local direction = (pos - eyePos):GetNormalized() -- Get the direction from player's eye to the position
    local angleDifference = math.deg(math.acos(eyeAngles:Forward():Dot(direction))) -- Calculate angle difference

    local tr = util.TraceLine({
        start = eyePos,
        endpos = pos,
        mask = MASK_VISIBLE,
    })

    return angleDifference <= ply:GetFOV() and not tr.Hit
end


--[[
==================================================================================================
                    COMMUNICATION / INFO / TEXT / HINT / HELP UTILITIES
==================================================================================================
--]]


-- "strID"      -   Unique identifier for this text,
--                  if another text with this ID is created, the old one will simply be updated
--                  with the new attributes. ID:s are not synced between client and server.
-- "pos"        -   The position to display the text at
-- 'fDuration'  -   Display duration
-- The following parameters should not be updated excessively:
-- "strText"    -   The text to show
-- "col"        -   The color to use
-- "fSize"      -   The size of the text
function conv.display3DText( strID, pos, fDuration, strText, col, fSize )
    if not isstring(strID) then
        error("Invalid ID for text!")
    end

    local text = conv._3dTexts[strID]

    if IsValid(text) then
        -- Update old text

        text:SetPos(pos)

        if isstring(strText) and strText     != text:GetstrText() then   text:SetstrText(strText) end
        if isnumber(fSize) and fSize         != text:GetfSize() then     text:SetfSize(fSize) end

        -- Don't update color every microsecond pls it will be unoptimized
        if IsColor(col) then text:SetvecColor(col:ToVector()) end

        text:resetRemoveTimer(fDuration)
    else
        -- Create new text
        text = (SERVER && ents.Create("conv_text")) or (CLIENT && ents.CreateClientside("conv_text"))

        if !IsValid(text) then
            error("Failed to create text entity!")
        end

        text:CONV_MapInTable(conv._3dTexts, text, strID)

        text:SetPos(pos)
        text:SetstrText(strText)
        text:SetfSize(fSize)
        text:SetvecColor(col:ToVector())
        text:Spawn()
        text:resetRemoveTimer(fDuration)
    end
end

-- Removes a 3D text created with display3DText
-- "strID"      -   Unique identifier for the text
function conv.remove3DText(strID)
    if not isstring(strID) then
        error("Invalid ID for text!")
    end
    SafeRemoveEntity(conv._3dTexts[strID])
end


-- Send a hint to the player's hud
-- 'ply'        - The player
-- 'strMsg'     - The message
-- 'iType'      - Type: https://wiki.facepunch.com/gmod/Enums/NOTIFY
-- 'fDuration'  - Display duration
function conv.sendGModHint( ply, strMsg, iType, fDuration )
    if CLIENT then
        notification.AddLegacy(strMsg, iType, fDuration)
    elseif SERVER then
        net.Start("CONV_SendGModHint")
        net.WriteString(strMsg)
        net.WriteUInt(iType, 3)
        net.WriteFloat(fDuration)
        net.Send(ply)
    end
end

--[[
==================================================================================================
                    MATH
==================================================================================================
--]]

-- Runs a check based on a percentage chance
function conv.pctChance(percent)
    return math.random() * 100 <= percent
end

-- Helper to check if a number is a float (has decimals)
function conv.isFloat(n)
    return n % 1 != 0
end

-- Checks if pos1 is at or closer distance to pos2
function conv.inDistVector(pos1, pos2, dist)

    if not isvector(pos1) then
        error("Pos1 is invalid or no Vector!")
    end

    if not isvector(pos2) then
        error("Pos2 is invalid or no Vector!")
    end

    if not isnumber(dist) then
        error("No distance provided!")
    end

	local distSqr = dist * dist
	local distTSqr = pos1:DistToSqr( pos2 ) <= distSqr
	return distTSqr
end

-- Checks the distance between pos1 and pos2 and returns square distance or root of it
function conv.getDistVector(pos1, pos2, root)

    if not isvector(pos1) then
        error("Pos1 is invalid or no Vector!")
    end

    if not isvector(pos2) then
        error("Pos2 is invalid or no Vector!")
    end

	local distTSqr = pos1:DistToSqr( pos2 )
	local dist = root and math.sqrt( distTSqr ) or distTSqr
	return dist
end

--[[
==================================================================================================
                    ENTITY TIMER / TICK FUNCTIONS
==================================================================================================
--]]


-- Call a method or function for this ent next tick
-- If the ent is invalid next tick, this does nothing
-- Same goes if you passed a string method name and the ent does not have it
function ENT:CONV_CallNextTick( methodnameorfunc, ... )
    local function func( me, ... )
        if !IsValid(me) then return end

        if isstring(methodnameorfunc) then
            
            if isfunction(me[methodnameorfunc]) then
                me[methodnameorfunc](me, ...)
            end

        elseif isfunction(methodnameorfunc) then
            methodnameorfunc(...)
        else
            error("Invalid type in CONV_CallNextTick.")
        end
    end

    conv.callNextTick( func, self, ... )
end


-- Temporarily set a variable on an entity
-- This assumes the variable does not exist currently, so it will be nil after 'duration'
function ENT:CONV_TempVar( name, value, duration )

    self[name] = value

    timer.Create("TempVar"..name..self:EntIndex(), duration, 1, function()
        if IsValid(self) then
            self[name] = nil
        end
    end)

end


-- Remove a temporary variable
function ENT:CONV_RemoveTempVar( name )
    timer.Remove("TempVar"..name..self:EntIndex())
    self[name] = nil
end


-- Temporarily sets variables created by ENT:NetworkVar()
function ENT:CONV_TempNetVar( funcName, value, duration )

    local setFuncName = "Set"..funcName
    local getFuncName = "Get"..funcName

    if not self[setFuncName.."NetValBefore"] then
        self[setFuncName](name, value)
    end

    self[setFuncName.."NetValBefore"] = self[setFuncName.."NetValBefore"] or self[getFuncName]()

    timer.Create("TempNetVar"..setFuncName..self:EntIndex(), duration, 1, function()
        if IsValid(self) then
            self[setFuncName](value)
            self[setFuncName.."NetValBefore"] = nil
        end
    end)

end


-- Like timer.Simple but with a built in valid check and varargs
function ENT:CONV_TimerSimple(dur, func, ...)

    local args = table.Pack(...)

    timer.Simple(dur, function()
        if IsValid(self) then
            func(unpack(args))
        end
    end)
end


-- Like timer.Create but with a built in valid check and varargs
-- Also automatically concatinates the name with the entity's entity index
function ENT:CONV_TimerCreate(name, dur, reps, func, ...)
    local timerName = name..self:EntIndex()
    local args = table.Pack(...)

    timer.Create(timerName, dur, reps, function()
        if not IsValid(self) then
            timer.Remove(timerName)
            return
        end

        func(unpack(args))
    end)

    return timerName
end


-- Like timer.Remove but automatically concatinates the name with the entity's entity index
function ENT:CONV_TimerRemove(name)
    timer.Remove(name..self:EntIndex())
end


--[[
==================================================================================================
                    ENTITY UTILITIES
==================================================================================================
--]]

-- Try get a human-readable name of an entity
function ENT:CONV_GetName()
    -- Player name
    if self:IsPlayer() then
        return self:GetName()
    end

    return string.NiceName(
                string.TrimLeft(self.PrintName || (SERVER && hook.Run("GetDeathNoticeEntityName", self)) || self:GetClass() 
                    , "#"))
end


-- Stores the entity in a table, and removes it from said table when the entity is no longer valid
function ENT:CONV_StoreInTable( tbl )
    if not istable(tbl) then return end

    table.insert(tbl, self)

    self:CallOnRemove("RemoveFrom"..tostring(tbl), function()
        if istable(tbl) then
            table.RemoveByValue(tbl, self)
        end
    end)
end


-- Maps the entity to a table where itself is used as a key
-- Removes value by key from said table when entity is no longer valid
-- 'value' -    is optional and is 'true' by default
-- 'key' -      is optional and is the entity by default
function ENT:CONV_MapInTable( tbl, value, key )
    if not istable(tbl) then
        error("Table is invalid!")
    end

    value = value or true
    key = key or self

    tbl[key] = value

    self:CallOnRemove("RemoveMappedFrom"..tostring(tbl), function()
        if istable(tbl) then
            tbl[key] = nil
        end
    end)
end


-- Adds a hook for this entity that terminates once it is no longer valid
-- 'Type' is the type of hook, such as "Think"
-- 'func' is the function to run in the hook. First argument is 'self'.
-- 'name' is optional and allows multiple hooks of the same type to be added to the ent (if they have different names)

function ENT:CONV_AddHook( Type, func, name )
    local id = "CONV_EntityHook_"..self:EntIndex().."_"..Type
    if name then id = id .. name end

    --self[id] = func

    hook.Add(Type, id, function(...)
        if not IsValid(self) then
            return
        end

        --local tab = {...}

        --if addHookFilter[Type] and addHookFilter[Type](self, tab) then return end

        --local tabID = table.Flip( tab )[self]
        --if tabID then table.remove( tab, tabID ) end

        return func(self, ...)
    end)

    self:CallOnRemove("CONV_RemoveHook_"..id, function()
        hook.Remove(Type, id)
    end)
end

-- Checks if a hook of the given type and name exists for this entity
function ENT:CONV_HookExists( Type, name )
    local id = "CONV_EntityHook_"..self:EntIndex().."_"..Type
    if name then id = id .. name end

    return hook.GetTable()[Type] and hook.GetTable()[Type][id] != nil
end

-- Remove a entity bound hook
function ENT:CONV_RemoveHook( Type, name )
    local id = "CONV_EntityHook_"..self:EntIndex().."_"..Type
    if name then id = id .. name end
    hook.Remove(Type, id)
end

-- Translates a sequence name or number to an activity
-- 'anim' - The sequence name or number, can be obtained with ENT:LookupSequence()
function ENT:CONV_TranslateSequence(anim)
	if isstring( anim ) then
		local result = self:GetSequenceActivity( self:LookupSequence( anim ) )	
		if result == nil || result == -1 then	
			return false			
		else		
			return result			
		end		
	elseif isnumber( anim ) then 	
		return anim		
	else	
		return false		
	end	
end

-- Returns the number of frames in the given sequence
-- 'seqID' - The sequence ID, can be obtained with ENT:LookupSequence()
-- 'animID' - The animation ID, can be obtained with ENT:GetSequenceInfo( seqID )
-- If animID is not provided, it defaults to the first animation in the sequence
-- Returns -1 if the sequence or animation does not exist
function ENT:CONV_SequenceGetFrames( seqID, animID )
    local seqInfo = self:GetSequenceInfo( seqID )
    if not seqInfo then return end
	local animID = seqInfo.anims[ animID or 1 ]
	return seqInfo.numframes or animID or -1
end

-- Checks if the provided sequence is valid
-- 'seq' - The sequence ID or name, can be obtained with ENT:LookupSequence()
-- Returns true if the sequence is valid, false otherwise
function ENT:CONV_IsValidSequence( seq )
    if !isnumber(seq) then
        seq = self:LookupSequence( seq )
    end

    return isnumber(seq) and seq > -1 and self:GetSequenceName(seq) != "Unknown"
end

-- Plays a sequence on the NPC, sets the playback rate and cycle
-- 'seq' - The sequence ID, can be obtained with ENT:LookupSequence()
-- 'speed' - The playback speed, defaults to 1
-- 'cycle' - The cycle to start at, defaults to 0
-- 'loops' - The number of loops to play, defaults to 0 (no loops), -1 for infinite loops
-- 'animThink' - A function to call on every frame change, receives the number of loops left and the current frame number
-- 'callback' - A function to call when the sequence finishes or loops, receives the number of loops left and a boolean indicating if the sequence was interrupted
function NPC:CONV_PlaySequence( seq, speed, cycle, loops, animThink, callback )

    if not self:CONV_IsValidSequence( seq ) then
        conv.devPrint( "[ERROR] Invalid sequence provided for NPC: " .. self:GetClass() .. " - " .. seq )
        return
    end

    if self:CONV_IsPlayingSequence() then self:CONV_StopSequence() end

    local speed = speed or 1
    local cycle = cycle or 0
    local loops = loops or 0

    self:SetNPCState( NPC_STATE_SCRIPT )
    self:SetSchedule( SCHED_SCENE_GENERIC )
    self:ResetSequenceInfo()
    self:SetSequence( seq )
    self:SetPlaybackRate( speed )
    self:SetCycle( cycle )

    local name = "NPCAnimPlayer" .. self:EntIndex()
    local seqID = isnumber(seq) and seq or self:LookupSequence( seq )
    local frames = self:CONV_SequenceGetFrames( seqID )
    local frameLast = 0
    local lastTick = CurTime()

    self:CONV_AddHook( "Think", function()

        if !IsValid(self) then return end

        self:SetPlaybackRate( speed )

        local seqError = self:GetSequence() != seqID

        if isfunction(animThink) then

            local frameNew = math.floor( self:GetCycle() * frames )

            for frame = frameLast + 1, frameNew do	-- a loop, just in case the think function is too slow to catch all frame changes
                animThink( loops, frame, frames )
            end

            frameLast = frameNew

        end

        if ( ( self:IsSequenceFinished() ) or seqError ) then

            loops = loops > 0 and loops - 1 or loops

            if ( loops > 0 or loops == -1 ) and not seqError then

                self:ResetSequenceInfo()
                self:SetCycle( cycle )

                if isfunction(callback) then callback( loops ) end

            elseif ( not loops or loops == 0 or seqError ) then

                self:CONV_StopSequence()

                if isfunction(callback) then callback( loops, seqError ) end

            end

        end

    end, name )
end

-- Checks if the NPC is currently playing a sequence
function NPC:CONV_IsPlayingSequence()
    local name = "NPCAnimPlayer" .. self:EntIndex()
    return self:CONV_HookExists( "Think", name )
end

-- Stops the currently playing sequence on the NPC
function NPC:CONV_StopSequence()
    self:SetNPCState( NPC_STATE_IDLE )
    self:ResetSequenceInfo()
    self:CONV_RemoveHook( "Think", "NPCAnimPlayer" .. self:EntIndex() )
end

--[[
==================================================================================================
                    NPC UTILITIES
==================================================================================================
--]]


-- Checks if the NPC has a certain capability
function NPC:CONV_HasCapability( cap )
    return bit.band(self:CapabilitiesGet(), cap) == cap
end

-- Checks if the NPC has a certain condition
function NPC:CONV_ListConditions()

	if ( not IsValid(self) ) then return end

    local tab = {}

	for c = 0, table.Count( COND ) do

		if ( self:HasCondition( c ) ) then

            local text = self:ConditionName( c ) .. " (" .. c .. ")"
            table.insert( tab, text )

		end

	end

    return tab

end

-- Used to get the pos, ang and bone of the given hitgroup
-- 'HITGROUP_GENERIC'	0	1:1 damage. Melee weapons and fall damage typically hit this hitgroup. This hitgroup is not present on default player models.
--                          It is unknown how this is generated in GM:ScalePlayerDamage, but it occurs when shot by NPCs ( npc_combine_s ) for example.
-- 'HITGROUP_HEAD'	    1	Head
-- 'HITGROUP_CHEST'	    2	Chest
-- 'HITGROUP_STOMACH'	3	Stomach
-- 'HITGROUP_LEFTARM'	4	Left arm
-- 'HITGROUP_RIGHTARM'	5	Right arm
-- 'HITGROUP_LEFTLEG'	6	Left leg
-- 'HITGROUP_RIGHTLEG'	7	Right leg
-- 'HITGROUP_GEAR'	    10	Gear. Supposed to be belt area.
--                          This hitgroup is not present on default player models.
--                          Alerts NPC, but doesn't do damage or bleed (1/100th damage)
function NPC:CONV_GetHitGroupBone( hg )
	local numHitBoxSets = self:GetHitboxSetCount()
	if numHitBoxSets then
		for hboxset = 0, numHitBoxSets - 1 do
			local numHitBoxes = self:GetHitBoxCount( hboxset )
			for hitbox = 0, numHitBoxes - 1 do
				if self:GetHitBoxHitGroup( hitbox, hboxset ) == hg then
					local bone = self:GetHitBoxBone( hitbox, hboxset )
					if ( !bone || bone < 0 ) then return false end
					local pos, ang = self:GetBonePosition( bone )
					return pos, ang, bone
				end
			end
		end
	end
	return nil, -1
end


--[[
==================================================================================================
                    TABLE UTILITY
==================================================================================================
--]]

-- Turns the table with keys ['1'], ['2'], ['3'] into a table with keys [1], [2], [3]
function conv.tablePairsToIPairs(tbl)
    if not istable(tbl) then return tbl end

    local newtbl = {}
    for k, v in pairs(tbl) do
        local nk = tonumber(k) or k
        if istable(v) then
            newtbl[nk] = conv.tablePairsToIPairs(v)
        else
            newtbl[nk] = v
        end
    end
    return newtbl
end

-- Turns the provided table into a string, respecting all variable types
function conv.tableToString( tbl )
	local str = "{"

	for k, v in pairs(tbl) do

		if isstring(v) then

			str = str .. string.format( "[%q] = %q,", k, v )

		elseif isnumber(v) then

			--str = str .. string.format( "[%q] = %d,", k, v ) -- turns anything below 1 to 0 :(
            str = str .. string.format( "[%q] = " .. tostring(v) .. ",", k, v )

		elseif isbool(v) then

			str = str .. string.format( "[%q] = %s,", k, tostring(v) )

        elseif IsColor(v) then

            str = str .. string.format( "[%q] = Color( %d, %d, %d, %d ),", k, v.r, v.g, v.b, v.a or 255 )

		elseif isvector(v) then

			str = str .. string.format( "[%q] = Vector( %f, %f, %f ),", k, v.x, v.y, v.z )

		elseif isangle(v) then

			str = str .. string.format( "[%q] = Angle( %f, %f, %f ),", k, v.p, v.y, v.r )

		elseif isentity(v) then

			str = str .. string.format( "[%q] = Entity( %d ),", k, v:EntIndex() )

        elseif istable(v) then

            str = str .. string.format( "[%q] = %s,", k, conv.tableToString(v) )

        elseif v.GetTexture then -- Material

            str = str .. string.format( "[%q] = Material( %q ),", k, v:GetName() )

		else

			str = str .. string.format( "[%q] = %s,", k, tostring(v) )

		end

	end

	str = str .. "}"

	return str
end

-- Turns the provided string into a table, recreating all variables
function conv.stringToTable( str )
    local func = CompileString( "return " .. str, "StringToTable", false )
    local tbl = func()

    tbl = conv.tablePairsToIPairs( tbl )

    return tbl
end

--[[
==================================================================================================
                    OTHER CONVENIENT
==================================================================================================
--]]

function conv.getSpawnMenuNPCs()
    return conv._SpawnMenuNPCs
end

function conv.thisEntOrWorld( ent )
    if !IsValid(ent) then return game.GetWorld() end
    return ent
end

-- Check duration of the provided sound file
function conv.getSoundDuration(snd)
    if !snd then
        error("No sound provided!")
    end

    local sounddur = SoundDuration( snd )
	if sounddur then
		sounddur = math.Round( sounddur * 1000 ) / 1000
	end

    return sounddur
end