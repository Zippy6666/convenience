// INTERNAL, DO NOT USE

local function CONVScrnMSG()
	if !table.IsEmpty( CONVScrnMSGTab ) then

		for id, data in pairs( CONVScrnMSGTab ) do

			local text = data['Text']
			local font = data['Font']
			local x = data['X']
			local y = data['Y']
			local tColor = data['Color']
			local xAlign = data['XAlign']
			local yAlign = data['YAlign']
			local OWidth = data['OWidth']
			local OColor = data['OColor']
			local del = data['Delay']
			local fadeIn = data['FadeIn']
			local fadeOut = data['FadeOut']
			local dur = data['Duration']
			local startTime = data['StartTime']
			local scrnFade = data['ScreenFade']


			local curTime = CurTime()
			local alpha = 255
			local alpha2 = 255

			if curTime < startTime + fadeIn then

				alpha = fadeIn > 0 and math.Clamp( ( curTime - startTime ) / fadeIn, 0, 1 ) * 255 or 255

			elseif curTime >= startTime + fadeIn + dur then

				alpha = fadeOut > 0 && math.Clamp( 1 - ( curTime - ( startTime + fadeIn + dur ) ) / fadeOut, 0, 1 ) * 255 || 0

				if alpha <= 0 then CONVScrnMSGTab[ id ] = nil end

			end

			local fTColor = Color( tColor.r, tColor.g, tColor.b, alpha )
			local fOColor = Color( OColor.r, OColor.g, OColor.b, alpha )

			if startTime <= curTime then

				draw.SimpleTextOutlined( text, font, x, y, fTColor, xAlign, yAlign, OWidth, fOColor )
			end

		end

	end
end

local cl_drawhud = GetConVar( "cl_drawhud" )
local function CONVHUDElements()

	if cl_drawhud:GetBool() then

		for id, data in pairs( CONVHUDElementsTab ) do

			if CONVHUDElementsTab[id]['Enable'] then CONVHUDElementsTab[id]['Function']() end

		end

	end
end

hook.Add("HUDPaint", "CONV", function()
	CONVScrnMSG()
	CONVHUDElements()

	CONV_HUDCurTime = CurTime()
end)

-- Conv tool menu thing
hook.Add("PopulateToolMenu", "CONV", function()
	if istable(conv.toolMenuFuncs) then
		for k, v in pairs(conv.toolMenuFuncs) do
			spawnmenu.AddToolMenuOption(v.tab, v.cat, v.name, v.name, "", "", v.func)
		end
	end
end)

-- This is used to set the fog for the world, which is different from the skybox
hook.Add("SetupWorldFog", "CONV", function()
	if IsValid( CONV_FOG_WORLD ) then

		render.FogStart( CONV_FOG_WORLD.FogStart )
		render.FogEnd( CONV_FOG_WORLD.FogEnd )
		render.FogMaxDensity( CONV_FOG_WORLD.FogMaxDensity )
		render.FogColor( CONV_FOG_WORLD.FogColor[1], CONV_FOG_WORLD.FogColor[2], CONV_FOG_WORLD.FogColor[3] )
		render.FogMode( CONV_FOG_WORLD.FogMode )
		render.SetFogZ( CONV_FOG_WORLD.FogZ )

		return true
	end
end)

-- This is used to set the fog for the skybox, which is different from the world
hook.Add("SetupSkyboxFog", "CONV", function(scale)
	if IsValid( CONV_FOG_SKYBOX ) then

		render.FogStart( CONV_FOG_SKYBOX.FogStart * scale )
		render.FogEnd( CONV_FOG_SKYBOX.FogEnd * scale )
		render.FogMaxDensity( CONV_FOG_SKYBOX.FogMaxDensity )
		render.FogColor( CONV_FOG_SKYBOX.FogColor[1], CONV_FOG_SKYBOX.FogColor[2], CONV_FOG_SKYBOX.FogColor[3] )
		render.FogMode( CONV_FOG_SKYBOX.FogMode )
		render.SetFogZ( CONV_FOG_SKYBOX.FogZ )

		return true
	end
end)