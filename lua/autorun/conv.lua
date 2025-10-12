--[[=========================== CONV MESSAGE START ===========================]]--
-- MissingConvMsg2 = CLIENT and function()

--     Derma_Query(
--         "This server does not have Zippy's Library installed, addons will function incorrectly!",

--         "ZIPPY'S LIBRARY MISSING!",
        
--         "Get Zippy's Library",

--         function()
--             gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3146473253")
--         end,

--         "Close"
--     )

-- end or nil

-- hook.Add("PlayerInitialSpawn", "MissingConvMsg2", function( ply )

--     if file.Exists("autorun/conv.lua", "LUA") then return end

--     local sendstr = 'MissingConvMsg2()'
--     ply:SendLua(sendstr)

-- end)
--[[============================ CONV MESSAGE END ============================]]--

if not conv then
    conv = conv or {}


    AddCSLuaFile("conv/cl.lua")
    AddCSLuaFile("conv/sh.lua")

    color_hl2hud_text = Color( 255, 220, 0, 255 )
    color_hl2hud_box = Color( 0, 0, 0, 80 )


    if SERVER then
        include("conv/sv.lua")
        include("conv/sh.lua")

        CONV_LUA_RUN_ENT = CONV_LUA_RUN_ENT or nil
    end

    if CLIENT then
        include("conv/cl.lua")
        include("conv/sh.lua")

        CONVScrnMSGTab = CONVScrnMSGTab or {}
        CONVHUDElementsTab = CONVHUDElementsTab or {}
        CONV_HUDCurTime = 0
    end


    conv.includeDir("conv/internals")
    conv.includeDir("convenience")


    MsgN("Zippy's library loaded!")
end
