// INTERNAL, DO NOT USE

CONVScrnMSGTab = {}

local function CONVScrnMSG()
	for id, data in pairs( CONVScrnMSGTab ) do

		local text = data['Text']
		local font = data['Font']
		local x = data['X'] * conv.ScrWScale()
		local y = data['Y'] * conv.ScrHScale()
		local tColor = data['Color']
		local xAlign = data['XAlign']
		local yAlign = data['YAlign']
		local OWidth = data['OWidth']
		local OColor = data['OColor']
		local del = data['Delay']
		local fadeIn = data['FadeIn']
		local fadeOut = data['FadeOut']
		local dur = data['Duration']
		local startTime = data['StartTime'] + del


		local curTime = CurTime()
		local alpha = 255

		if curTime < startTime + fadeIn then

			alpha = fadeIn > 0 && math.Clamp( ( curTime - startTime ) / fadeIn, 0, 1 ) * 255 || 255

		elseif curTime >= startTime + fadeIn + dur then

			alpha = fadeOut > 0 && math.Clamp( 1 - ( curTime - ( startTime + fadeIn + dur ) ) / fadeOut, 0, 1 ) * 255 || 0

			if alpha <= 0 then CONVScrnMSGTab[ id ] = nil end

		end
		
		local fTColor = Color( tColor.r, tColor.g, tColor.b, alpha )
		local fOColor = Color( OColor.r, OColor.g, OColor.b, alpha )

		if startTime <= curTime then draw.SimpleTextOutlined( text, font, x, y, fTColor, xAlign, yAlign, OWidth, fOColor ) end

	end
end

hook.Add( "HUDPaint", "CONV", function()
	CONVScrnMSG()
end )