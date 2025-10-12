if SERVER then
	util.AddNetworkString("CONV_SendGModHint") 
	util.AddNetworkString("CONV_CallOnClient")
end

if CLIENT then
    net.Receive("CONV_SendGModHint", function()
        local strMsg    = net.ReadString()
        local iType     = net.ReadUInt(3)
        local fDuration = net.ReadFloat()
        conv.sendGModHint(NULL, strMsg, iType, fDuration)
    end)
	
	-- Receives data from the server for the client about a function to call globaly --
	net.Receive("CONV_CallOnClient", function()
		local ent = net.ReadString()
		local funcN = net.ReadString()
		local data = net.ReadString()
		
		ent = _G[ ent ] or ent != "" and Entity( tonumber(ent) ) 
		
		funcN = _G[ funcN ] or funcN
		
		if isfunction( funcN ) or ent and ent[ funcN ] then
			
			CONV_INTERNAL_COCTranslate( ent, funcN, data )

		end
	end) 
end