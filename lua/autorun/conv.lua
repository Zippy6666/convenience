--[[
==================================================================================================
                    MESSAGE TEMPLATE
==================================================================================================
--]]


-- The message to show when CONV is not installed
-- if CLIENT then
--     function MissingConvMsg()
--         local frame = vgui.Create("DFrame")
--         frame:SetSize(300, 125)
--         frame:SetTitle("Missing Library!")
--         frame:Center()
--         frame:MakePopup()

--         local text = vgui.Create("DLabel", frame)
--         text:SetText("This server does not have the CONV library installed, some addons may function incorrectly. Click the link below to get it:")
--         text:Dock(TOP)
--         text:SetWrap(true)  -- Enable text wrapping for long messages
--         text:SetAutoStretchVertical(true)  -- Allow the text label to stretch vertically
--         text:SetFont("BudgetLabel")

--         local label = vgui.Create("DLabelURL", frame)
--         label:SetText("CONV Library")
--         label:SetURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3146473253")
--         label:Dock(BOTTOM)
--         label:SetContentAlignment(5)  -- 5 corresponds to center alignment
--     end
-- elseif SERVER && !file.Exists("autorun/conv.lua", "LUA") then
--     -- Conv lib not on on server, send message to clients
--     hook.Add("PlayerInitialSpawn", "convenienceerrormsg", function( ply )
--         local sendstr = 'MissingConvMsg()'
--         ply:SendLua(sendstr)
--     end)
-- end


--[[
==================================================================================================
                    ADDON TEMPLATE
==================================================================================================
--]]


conv = conv or {} -- Your addon table here
local addonName = "Zippy's Library" -- Your addon name here
local rootDirectory = "convenience" -- Your directory here


local function AddFile( File, directory )
	local prefix = string.lower( string.Left( File, 3 ) )
	if SERVER and prefix == "sv_" then

		include( directory .. File )

	elseif prefix == "sh_" then

		AddCSLuaFile( directory .. File )
		include( directory .. File )

	elseif prefix == "cl_" then

		if SERVER then
			AddCSLuaFile( directory .. File )
		elseif CLIENT then
			include( directory .. File )
		end

	end
end


local function IncludeDir( directory )
	directory = directory .. "/"

	local files, directories = file.Find( directory .. "*", "LUA" )

	for _, v in ipairs( files ) do
		if string.EndsWith( v, ".lua" ) then
			print("["..addonName.."] Adding file '"..directory..v.."'!")
			AddFile( v, directory )
		end
	end

	for _, v in ipairs( directories ) do
		IncludeDir( directory .. v )
	end
end


IncludeDir( rootDirectory )


--[[
==================================================================================================
                    CONV SPECIFICS
==================================================================================================
--]]


AddCSLuaFile("convenience/adam.lua")
include("convenience/adam.lua")
MsgN("Zippy's library loaded!")