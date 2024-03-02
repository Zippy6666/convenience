--[[
=======================================================================================================================
                                            CONVENIENCE LIB
=======================================================================================================================
--]]
-- -- Missing conv message
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
-- end


-- if file.Exists("convenience/adam.lua", "LUA") then

--     -- Include conv library
--     AddCSLuaFile("convenience/adam.lua")
--     include("convenience/adam.lua")

-- elseif SERVER then

--     -- Conv lib not on on server, send message to clients
--     hook.Add("PlayerInitialSpawn", "convenienceerrormsg", function( ply )
--         local sendstr = 'MissingConvMsg()'
--         ply:SendLua(sendstr)
--     end)

-- end


-- Add client lua files
AddCSLuaFile("sh_conv.lua")
AddCSLuaFile("sh_misc.lua")
AddCSLuaFile("sh_ent.lua")
AddCSLuaFile("sh_hooks.lua")


-- Shared
include("sh_conv.lua")
include("sh_misc.lua")
include("sh_ent.lua")
include("sh_hooks.lua")


-- Server
if SERVER then
    include("sv_ents.lua")
end