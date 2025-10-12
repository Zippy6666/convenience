--[[
==================================================================================================
                    LOCALS / INTERNAS, NO TOUCHY
==================================================================================================
--]]

local scrWidth = 1920
local scrHeight = 1080
local cl_drawhud = GetConVar( "cl_drawhud" )

-- Function used by CallOnClient to translate sent data --
function CONV_INTERNAL_COCTranslate( ent, funcN, data )  
	
	data = conv.stringToTable( data )	
	
	if IsValid(ent) or ent == game.GetWorld() then
			
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
    if not ply:IsSuperAdmin() then return end
    net.Start("CONV_StripAndTools")
    net.SendToServer()
end)


-- Give ammo to all weapons for a player, needs admin
concommand.Add("conv_giveammo", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then return end
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
        table.insert(weapon_slotmap["SLOT "..wep:GetSlot()], wep.PrintName and language.GetPhrase(wep.PrintName) or wep:GetClass())

    end

    PrintTable(weapon_slotmap)
end)
 
-- Show information about the player's frames, frame times, ping, etc. conv_telemetry <1/0> <x> <y>
concommand.Add( "conv_telemetry", function(ply, cmd, args)  
	local enable = args[1] and tonumber(args[1]) > 0

	conv.addHUDElement("conv_telemetry", enable, function() 
		local ply = LocalPlayer()
		local w, h = 200, 100
		local x, y = args and args[2] or conv.ScrWCenter() - ( w / 2 ), args and args[3] or conv.ScrHCenter() - 300
		draw.RoundedBox( 8, x, y, w, h, color_hl2hud_box )

		local x1, y1 = x + 97, y + 15
		local text = "TELEMETRY"
		local textW, textH = draw.SimpleText( text, "HudDefault", x1, y1, color_hl2hud_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		local x, y = x + 15, y + 10 + textH
		local text = "FRAMES/s:"
		local textW, textH = draw.SimpleText( text, "HudHintTextLarge", x, y, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		local x2, y2 = x + 110, y
		local text2 = math.Round( ( 1 / FrameTime() ), 3 )
		local textW2, textH2 = draw.SimpleText( text2, "HudHintTextLarge", x2, y2, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
 
		local x, y = x, y + textH
		local text = "FRAME TIME:"
		local textW, textH = draw.SimpleText( text, "HudHintTextLarge", x, y, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		local x2, y2 = x + 110, y
		local text2 = math.Round( FrameTime(), 5 )
		local textW2, textH2 = draw.SimpleText( text2, "HudHintTextLarge", x2, y2, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

		local x, y = x, y + textH
		local text = "PING:"
		local textW, textH = draw.SimpleText( text, "HudHintTextLarge", x, y, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		local x2, y2 = x + 110, y
		local text2 = ply:Ping()
		local textW2, textH2 = draw.SimpleText( text2, "HudHintTextLarge", x2, y2, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		
		local x, y = x, y + textH
		local text = "PACKET LOSS:"
		local textW, textH = draw.SimpleText( text, "HudHintTextLarge", x, y, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		local x2, y2 = x + 110, y
		local text2 = ply:PacketLoss() .. "%"
		local textW2, textH2 = draw.SimpleText( text2, "HudHintTextLarge", x2, y2, color_hl2hud_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	end)
end) 

--[[
==================================================================================================
                    TOOL MENU
==================================================================================================
--]]

-- A convenient way to add toolmenu options
-- 'tab' <string>: The tab to add the option to
-- 'cat' <string>: The category to add the option to
-- 'name' <string>: The name of the option
-- 'func' <function>: The function to call when the option is selected
function conv.addToolMenu(tab, cat, name, func)
    conv.toolMenuFuncs = conv.toolMenuFuncs or {}
    conv.toolMenuFuncs[tab.."_"..cat.."_"..name] = {tab=tab, cat=cat, name=name, func=func}
end


--[[
==================================================================================================
					UI
==================================================================================================
--]]


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
	return ScrW() / 2
end

-- Returns the central point of the vertical axis.
function conv.ScrHCenter()
	return ScrH() / 2
end
 
-- Used to create hud elements on the go
function conv.addHUDElement(id, enable, func)		
	if ( id and enable == nil and not isfunction(func) ) then CONVHUDElementsTab[ id ] = nil return end
	
	CONVHUDElementsTab[id] = { 
		['Enable']			= not enable and false or enable,
		['Function'] 		= func,
	}
end
 
-- Used to create on screen messages/text similar to "game_text". entity https://developer.valvesoftware.com/wiki/Game_text
function conv.addScreenMSG(id, text, font, x, y, tColor, xAlign, yAlign, OWidth, OColor, del, fadeIn, fadeOut, dur)		
	if ( id and ( not text ) ) then CONVScrnMSGTab[ id ] = nil return end
	
	text = text or ""
	font = font or "DermaDefault"
	x = x or 0
	y = y or 0
	tColor = tColor or Color( 255, 255, 255, 255 )
	xAlign = xAlign or TEXT_ALIGN_CENTER
	yAlign = yAlign or TEXT_ALIGN_CENTER
	OWidth = OWidth or 0
	OColor = OColor or Color( 0, 0, 0, 255 )
	del = del or 0
	fadeIn = fadeIn or 0
	fadeOut = fadeOut or 0
	dur = dur or 0

	local function pp(tbl, k, s, add, ret)
		return add and ( tbl[k] and tbl[k][s] and tbl[k][s] + add or add ) or ( tbl[k] and tbl[k][s] and tbl[k][s] or ret )
	end
	
	CONVScrnMSGTab[id] = { 
		['Text'] 		= text,
		['Font'] 		= font,
		['X'] 			= x,
		['Y'] 			= y,
		['Color'] 		= tColor,
		['XAlign'] 		= xAlign,
		['YAlign'] 		= yAlign,
		['OWidth'] 		= OWidth,
		['OColor'] 		= OColor,
		['Delay'] 		= del,
		['FadeIn'] 		= fadeIn,
		['FadeOut'] 	= fadeOut,
		['Duration'] 	= pp(CONVScrnMSGTab, id, 'Duration', dur),
		['StartTime'] 	= pp(CONVScrnMSGTab, id, 'StartTime', nil, CurTime() + del),
	}
end

-- Used to play UI sounds
-- 'snd' <string>: The sound to play
-- 'pitch' <number>: The pitch of the sound
-- 'vol' <number>: The volume of the sound
-- 'channel' <number>: The channel to play the sound on
-- 'sfs' <number>: The sound filter scale
-- 'dsp' <number>: The DSP level
-- 'filter' <table>: The sound filter
function conv.emitUISound(snd, pitch, vol, channel, sfs, dsp, filter)

	local ply = LocalPlayer()
	vol = vol or 1
	pitch = pitch or 100
	channel = channel or CHAN_AUTO
	sfs = sfs or 0
	dsp = dsp or 0


	ply.m_tCONVClientSounds = ply.m_tCONVClientSounds or {}


	local function stopSND(snd)

		for k, v in ipairs ( ply.m_tCONVClientSounds ) do
			if snd and v == snd then
				ply:StopSound( snd ) 	
				table.remove( ply.m_tCONVClientSounds, k ) 		
			else
				ply:StopSound( v ) 	
				table.remove( ply.m_tCONVClientSounds, k )			
			end			
		end

	end


	if snd then	

		ply:EmitSound( snd, 0, pitch, vol, channel, sfs, dsp, filter )
		table.insert( ply.m_tCONVClientSounds, snd )	

	elseif snd and pitch == true then

		stopSND(snd)		

	elseif not snd and ply.m_tCONVClientSounds and #ply.m_tCONVClientSounds > 0 then	

		stopSND()

	end			

end

-- Used to display text on an entity, useful for debugging or showing information
-- 'name' <string>: The name of the display
-- 'ent' <Entity>: The entity to display the text on
-- 'tab' <table>: The table containing the text to display
-- 'dur' <number>: The duration to display the text
-- 'x' <number>: The x position
-- 'y' <number>: The y position
-- 'xAlign' <number>: The x alignment
-- 'yAlign' <number>: The y alignment
function conv.displayOnEntity( name, ent, tab, dur, x, y, xAlign, yAlign )

	if not ent then return end

	local name = "CONV_DisplayOnEntity" .. name .. ent:EntIndex() or "CONV_DisplayOnEntity" .. ent:EntIndex()

	if not tab then ent:CONV_RemoveHook( "HUDPaint", name ) return end

	local ply = LocalPlayer()
	local font = "ChatFont"
	local x = x or 0
	local y = y or 0
	local dur = dur and dur < 0.1 and 0.1 or dur
	local xAlign = xAlign or TEXT_ALIGN_CENTER
	local yAlign = yAlign or TEXT_ALIGN_TOP

	ent:CONV_AddHook( "HUDPaint", function()

		local pos = ent:GetPos() + ent:OBBCenter() * 2       
		local sPos = pos:ToScreen()
		local i = 0
		
		for k, v in pairs(tab) do

			i = i + 1

			v = tostring(v)

			if not isnumber(k) then v = k .. " = " .. v end

			draw.SimpleText( v, font, sPos.x + x, sPos.y + ( i * 20 ) + y, color_white, xAlign, yAlign )
		end
	end, name )

	if dur then ent:CONV_TimerCreate( name, dur, 1, function() ent:CONV_RemoveHook( "HUDPaint", name ) end ) end
end

-- Allows to create a status icon that moves around in relation to other icons the same table
-- 'x, y, w, h' - x pos, y pos, w width, h height.
-- 'direction' - Sets the direction at which new icons should appear
-- 1 - left, 2 - right, 3 - up, 4 - down
-- 'reverseOrder' - If true, notifications are added in the opposite order
-- 'spacing' - Space between the icons
-- 'lifeTime' - Time in seconds after which icon will dissapear
-- 'iconTab - A global table to which all icons will be added to
-- 'bgPaint' - Icon paint function. It's invisible by default so you should add something here
-- 'condRemove' - A return function that controls if give icon should remove itself 
function conv.createHUDStatusIcon(x, y, w, h, direction, reverseOrder, spacing, lifeTime, iconTab, bgPaint, condRemove)

	if not iconTab then return end

	-- Notification panel
	local panel = vgui.Create( "DNotify" )
	panel:SetSize( w, h )
	panel:ParentToHUD()

	local w, h = panel:GetSize()
	panel:SetLife( lifeTime )
	
	-- Gray background panel
	local panelBG = vgui.Create( "DPanel", panel )
	panelBG:Dock( FILL )

	-- Inset icon to the provided global table
	table.insert( iconTab, panelBG )

	-- Set scaled position
	panel:SetPos( x, y )
	panel:AddItem( panelBG )

	local baseX, baseY = panel:GetPos()
	local spacing = spacing or 0

	function panelBG:Paint(w, h)
		-- Check if we should remove ourselves
		if isfunction(condRemove) and condRemove( self ) then self:Remove() return end
		if not conv.isHUDPainted() then return end

		-- Calculate our position using our position in the global table
		local idx = table.Flip( iconTab )[self] or 1
		local add = idx - 1

		if reverseOrder then
			add = ( #iconTab - idx )
		end

		local px, py = baseX, baseY

		-- Calculate offset based on previous icons' sizes
		local offsetX, offsetY = 0, 0
		if direction == 1 then -- left

			for i = idx - 1, 1, -1 do

				local prev = iconTab[i]

				if IsValid(prev) and prev:GetParent() and prev:GetParent():IsValid() then
					offsetX = offsetX - ( prev:GetParent():GetWide() + spacing )
				else
					offsetX = offsetX - ( w + spacing )
				end

			end

			px = baseX + offsetX
		elseif direction == 2 then -- right

			for i = 1, idx - 1 do

				local prev = iconTab[i]

				if IsValid(prev) and prev:GetParent() and prev:GetParent():IsValid() then
					offsetX = offsetX + ( prev:GetParent():GetWide() + spacing )
				else
					offsetX = offsetX + ( w + spacing )
				end

			end

			px = baseX + offsetX
		elseif direction == 3 then -- up

			for i = idx - 1, 1, -1 do

				local prev = iconTab[i]

				if IsValid(prev) and prev:GetParent() and prev:GetParent():IsValid() then
					offsetY = offsetY - ( prev:GetParent():GetTall() + spacing )
				else
					offsetY = offsetY - ( h + spacing )
				end

			end

			py = baseY + offsetY
		elseif direction == 4 then -- down

			for i = 1, idx - 1 do

				local prev = iconTab[i]

				if IsValid(prev) and prev:GetParent() and prev:GetParent():IsValid() then
					offsetY = offsetY + ( prev:GetParent():GetTall() + spacing )
				else
					offsetY = offsetY + ( h + spacing )
				end

			end

			py = baseY + offsetY
		elseif direction == 5 then -- vertical spread (up/down from center)

			local mid = math.floor( ( #iconTab + 1 ) / 2 )
			local myIdx = idx

			for i = 1, #iconTab do

				if i == myIdx then continue end

				local prev = iconTab[i]
				local sign = ( i < myIdx ) and -1 or 1

				if IsValid(prev) and prev:GetParent() and IsValid(prev:GetParent()) then
					offsetY = offsetY + sign * ( prev:GetParent():GetTall() + spacing ) / 2
				else
					offsetY = offsetY + sign * ( h + spacing ) / 2
				end

			end

			py = baseY + offsetY
		elseif direction == 6 then -- horizontal spread (left/right from center)

			local mid = math.floor( ( #iconTab + 1 ) / 2 )
			local myIdx = idx

			for i = 1, #iconTab do

				if i == myIdx then continue end

				local prev = iconTab[i]
				local sign = ( i < myIdx ) and -1 or 1

				if IsValid(prev) and prev:GetParent() and IsValid(prev:GetParent()) then
					offsetX = offsetX + sign * ( prev:GetParent():GetWide() + spacing ) / 2
				else
					offsetX = offsetX + sign * ( w + spacing ) / 2
				end

			end

			px = baseX + offsetX
		end

		panel:SetPos( px, py )

		-- Call custom paint function
		bgPaint( self, w, h, px, py )
	end

	-- Remove our parent as it doesn't do that on its own (bug?) and remove ourselves from the global table
	function panelBG:OnRemove()		
		panel:Remove()
		table.RemoveByValue( iconTab, self )
	end

	return panel
end

-- Allows to create HUD elements using derma panels
-- 'x, y, w, h' - x pos, y pos, w width, h height.
-- 'bgPaint' - Icon paint function. It's invisible by default so you should add something here
-- 'condRemove' - A return function that controls if give icon should remove itself 
function conv.createHUDElement(x, y, w, h, bgPaint, condRemove)
	
	-- Creatin UI element
	local panel = vgui.Create( "DPanel" )
	panel:ParentToHUD()
	panel:SetPos( x, y )
	panel:SetSize( w, h )
	

	function panel:Paint(w, h)

		-- Check if we should remove ourselves
		if isfunction(condRemove) and condRemove(self) then self:Remove() return end

		-- Check if HUD is being drawn
		if not conv.isHUDPainted() then return end

		-- Call custom paint function
		bgPaint( self, w, h )

	end

	return panel
end

-- Returns true if 'HUDPaint' is being called or false if it's being blocked by (for an example) SWEP Camera
function conv.isHUDPainted()
	return CONV_HUDCurTime >= CurTime() and cl_drawhud:GetBool()
end

--[[
==================================================================================================
					FOG CONTROL
==================================================================================================
--]]

-- Setup world fog, set no values to reset
-- 'fogStart' <number>: The start distance of the fog
-- 'fogEnd' <number>: The end distance of the fog
-- 'fogMaxDensity' <number>: The maximum density of the fog
-- 'fogColor' <Color>: The color of the fog
-- 'fogMode' <number>: The mode of the fog
-- 'fogZ' <number>: The Z distance of the fog
function conv.setupWorldFog(fogStart, fogEnd, fogMaxDensity, fogColor, fogMode, fogZ)

	if not fogStart and not fogEnd and not fogMaxDensity and not fogColor and not fogMode and not fogZ then 
		fogMode = 0 

		conv.callNextTick( function() 
			CONV_FOG_WORLD = nil
		end )
	end

	local s, e, z = render.GetFogDistances()
	local c = { render.GetFogColor() }

	CONV_FOG_WORLD = {}
	CONV_FOG_WORLD.FogStart			= fogStart or s
	CONV_FOG_WORLD.FogEnd 			= fogEnd or e
	CONV_FOG_WORLD.FogMaxDensity 	= fogMaxDensity or 0.5
	CONV_FOG_WORLD.FogColor 		= fogColor or c
	CONV_FOG_WORLD.FogMode			= fogMode or 1
	CONV_FOG_WORLD.FogZ				= fogZ or z

end

-- Setup skybox fog, set no values to reset
-- 'fogStart' <number>: The start distance of the fog
-- 'fogEnd' <number>: The end distance of the fog
-- 'fogMaxDensity' <number>: The maximum density of the fog
-- 'fogColor' <Color>: The color of the fog
-- 'fogMode' <number>: The mode of the fog
-- 'fogZ' <number>: The Z distance of the fog
function conv.setupSkyboxFog(fogStart, fogEnd, fogMaxDensity, fogColor, fogMode, fogZ)

	if not fogStart and not fogEnd and not fogMaxDensity and not fogColor and not fogMode and not fogZ then 
		fogMode = 0 

		conv.callNextTick( function() 
			CONV_FOG_SKYBOX = nil
		end )
	end

	local s, e, z = render.GetFogDistances()
	local c = { render.GetFogColor() }

	CONV_FOG_SKYBOX = {}
	CONV_FOG_SKYBOX.FogStart		= fogStart or 0
	CONV_FOG_SKYBOX.FogEnd 			= fogEnd or 10000
	CONV_FOG_SKYBOX.FogMaxDensity 	= fogMaxDensity or 0.5
	CONV_FOG_SKYBOX.FogColor 		= fogColor or c
	CONV_FOG_SKYBOX.FogMode			= fogMode or 1
	CONV_FOG_SKYBOX.FogZ			= fogZ or z

end

