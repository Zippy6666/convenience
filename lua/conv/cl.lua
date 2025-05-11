--[[
==================================================================================================
                    LOCALS, NO TOUCHY
==================================================================================================
--]]

-- Function used by CallOnClient to translate sent data --
function conv.cocTranslate( ent, funcN, data )   
	
	data = conv.stringToTable( data )	
	
	if IsValid(ent) || ent == game.GetWorld() then
	
		ent[ funcN ]( ent, unpack( data ) )
	
	elseif istable(ent) then
		
		ent[ funcN ]( unpack( data ) )
		
	else
		
		funcN( unpack( data ) )
		
	end
	
end

--[[
==================================================================================================
                    COMMANDS
==================================================================================================
--]]


-- Strip the players weapons, and gives only essential tools
concommand.Add("conv_strip", function(ply, cmd, args)
    if !ply:IsSuperAdmin() then return end
    net.Start("CONV_StripAndTools")
    net.SendToServer()
end)


-- Give ammo to all weapons for a player, needs admin
concommand.Add("conv_giveammo", function(ply, cmd, args)
    if !ply:IsSuperAdmin() then return end
    net.Start("CONV_GiveAmmo")
    net.SendToServer()
end)

concommand.Add("conv_rmwep", function(ply, cmd, args)
    net.Start("CONV_RmWep")
    net.SendToServer()
end)

-- Show information about the player's weapons, useful when they have fast switch enabled
concommand.Add("conv_checkweapons", function(ply, cmd, args)
    local weps = ply:GetWeapons()

    notification.AddLegacy( "You currently have "..#weps.." weapons in your inventory", NOTIFY_HINT, 5 )

    local weapon_slotmap = {}
    for _, wep in ipairs(weps) do

        weapon_slotmap["SLOT "..wep:GetSlot()] = weapon_slotmap["SLOT "..wep:GetSlot()] or {}
        table.insert(weapon_slotmap["SLOT "..wep:GetSlot()], wep.PrintName && language.GetPhrase(wep.PrintName) or wep:GetClass())

    end

    PrintTable(weapon_slotmap)
end)


--[[
==================================================================================================
                    TOOL MENU
==================================================================================================
--]]

-- A convenient way to add toolmenu options
function conv.addToolMenu(tab, cat, name, func)
    conv.toolMenuFuncs = conv.toolMenuFuncs or {}
    conv.toolMenuFuncs[tab.."_"..cat.."_"..name] = {tab=tab, cat=cat, name=name, func=func}
end


--[[
==================================================================================================
					UI
==================================================================================================
--]]

local scrWidth = 1920
local scrHeight = 1080

-- Used to properly scale position and width of an UI elemet to different screen resolutions.
function conv.ScrWScale()
	return ScrW() / scrWidth
end

-- Used to properly scale position and height of an UI elemet to different screen resolutions.
function conv.ScrHScale()
	return ScrH() / scrHeight
end

-- Returns the central point of the horizontal axis.
function conv.ScrWCenter()
	return scrWidth / 2
end

-- Returns the central point of the vertical axis.
function conv.ScrHCenter()
	return scrHeight / 2
end
 
-- Used to create on screen messages/text similar to "game_text". entity https://developer.valvesoftware.com/wiki/Game_text
function conv.addScreenMSG(id, text, font, x, y, tColor, xAlign, yAlign, OWidth, OColor, del, fadeIn, fadeOut, dur)		
	if ( id && ( !text || text == "" ) ) then CONVScrnMSGTab[ id ] = nil return end

	CONVScrnMSGTab[ id ] = {
		['Text'] 		= text || "",
		['Font'] 		= font || "DermaDefault",
		['X'] 			= x || 0,
		['Y'] 			= y || 0,
		['Color'] 		= tColor || Color( 255, 255, 255, 255 ),
		['XAlign'] 		= xAlign || TEXT_ALIGN_CENTER,
		['YAlign'] 		= yAlign || TEXT_ALIGN_CENTER,
		['OWidth'] 		= OWidth || 0,
		['OColor'] 		= OColor || Color( 0, 0, 0, 255 ),
		['Delay'] 		= del || 0,
		['FadeIn'] 		= fadeIn || 0,
		['FadeOut'] 	= fadeOut || 0,
		['Duration'] 	= dur || 0,
		['StartTime'] 	= CurTime(),
	}
end
