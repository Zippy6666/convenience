--[[
==================================================================================================
                    VARIABLES
==================================================================================================
--]]


-- Cvars
local MaxAmmoCvar = GetConVar("gmod_maxammo")
local DevCvar = GetConVar("developer")


--[[
==================================================================================================
                    TABLE
==================================================================================================
--]]


-- Insert an entity into a table, which is later removed once it is no longer valid
local function TableInsertEntity( tbl, ent )

    if !IsValid(ent) then return end -- Must be ent

    table.insert(tbl, ent)
    ent:CallOnRemove("RemoveFrom_"..tostring(tbl), function()
        table.RemoveByValue(tbl, ent)
    end)

end


--[[
==================================================================================================
                    TIMER STUFF
==================================================================================================
--]]


-- Do something next tick/frame
local function CallNextTick( func, ... )

    local argtbl = table.Pack(...)

    timer.Simple(0, function()
        func(unpack(argtbl))
    end)

end


-- Do something after a certain amount of ticks/frames
local function CallAfterTicks( ticknum, func, ... )

    CallNextTick( function( ... )

        if ticknum <= 0 then
            func(...)
        else
            CallAfterTicks( ticknum-1, func, ... )
        end
        
    end, ... )

end


--[[
==================================================================================================
                    PLAYER
==================================================================================================
--]]


-- Checks if the given player can see this position right now
local function PlyPosInView( ply, pos )

    local eyePos = ply:GetShootPos()
    local eyeAngles = ply:EyeAngles()
    local direction = (pos - eyePos):GetNormalized() -- Get the direction from player's eye to the position
    local angleDifference = math.deg(math.acos(eyeAngles:Forward():Dot(direction))) -- Calculate angle difference

    local tr = util.TraceLine({
        start = eyePos,
        endpos = pos,
        mask = MASK_VISIBLE,
    })

    return angleDifference <= ply:GetFOV() && !tr.Hit

end


-- Checks if any player on the server can see this position right now
local function PlayersSeePos( pos )
    for _, ply in player.Iterator() do
        if ply:PosInView(pos) then
            return true
        end
    end
end


-- Just like https://wiki.facepunch.com/gmod/game.GetAmmoMax
-- But it respects the gmod_maxammo cvar
local function GetCurrentAmmoMax(id)
    local cvarMax = MaxAmmoCvar:GetInt()

    if cvarMax <= 0 then
        return game.GetAmmoMax(id)
    else
        return cvarMax
    end
end


--[[
==================================================================================================
                    DEBUG
==================================================================================================
--]]


-- Debug Overlay QOL
-- https://wiki.facepunch.com/gmod/debugoverlay
local function DebugOverlay( funcname, argsFunc )
    if !DevCvar:GetBool() then return end
    local args = argsFunc()
    debugoverlay[funcname](unpack(args))
end


-- debug.Trace but you can choose which level to start from
local function DebugTraceFrom(level)
    while true do

        local info = debug.getinfo( level, "Sln" )
        if ( !info ) then break end

        if ( info.what ) == "C" then
            MsgN( string.format( "\t%i: C function\t\"%s\"", level, info.name ) )
        else
            MsgN( string.format( "\t%i: Line %d\t\"%s\"\t\t%s", level, info.currentline, info.name, info.short_src ) )
        end

        level = level + 1

    end
end