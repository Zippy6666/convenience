// INTERNAL, DO NOT USE

hook.Add("InitPostEntity", "CONV", function()
    -- Store spawn menu NPCs
    conv._SpawnMenuNPCs = list.Get("NPC")

    if ZBaseInstalled and istable(conv._SpawnMenuNPCs) and istable(ZBaseNPCs) then
        table.Merge(conv._SpawnMenuNPCs, table.Copy(ZBaseNPCs))
    end

    ents._SpawnMenuNPCs = conv._SpawnMenuNPCs -- Backwards compatability
end)

hook.Add("InitPostEntity", "CONV", function()
    if SERVER then

        conv.createLuaRun()

        CONV_DEFAULT_SKYBOX = GetConVar("sv_skyname"):GetString()
        CONV_SKYPAINT = ents.FindByClass( "env_skypaint" )[1]

        if CONV_SKYPAINT then
            CONV_SKYPAINT.TopColor = CONV_SKYPAINT:GetTopColor()
            CONV_SKYPAINT.BottomColor = CONV_SKYPAINT:GetBottomColor()
            CONV_SKYPAINT.FadeBias = CONV_SKYPAINT:GetFadeBias()
            CONV_SKYPAINT.HDRScale = CONV_SKYPAINT:GetHDRScale()

            CONV_SKYPAINT.StarLayers = CONV_SKYPAINT:GetStarLayers()
            CONV_SKYPAINT.DrawStars = CONV_SKYPAINT:GetDrawStars()
            CONV_SKYPAINT.StarTexture = CONV_SKYPAINT:GetStarTexture()
            CONV_SKYPAINT.StarSpeed = CONV_SKYPAINT:GetStarSpeed()
            CONV_SKYPAINT.StarFade = CONV_SKYPAINT:GetStarFade()
            CONV_SKYPAINT.StarScale = CONV_SKYPAINT:GetStarScale()

            CONV_SKYPAINT.DuskIntensity = CONV_SKYPAINT:GetDuskIntensity()
            CONV_SKYPAINT.DuskScale = CONV_SKYPAINT:GetDuskScale()
            CONV_SKYPAINT.DuskColor = CONV_SKYPAINT:GetDuskColor()

            CONV_SKYPAINT.SunSize = CONV_SKYPAINT:GetSunSize()
            CONV_SKYPAINT.SunColor = CONV_SKYPAINT:GetSunColor()
        end

    end

    CONV_ENV_SUN = ents.FindByClass( "env_sun" )[1]

    if IsValid( CONV_ENV_SUN ) then
        local data = CONV_ENV_SUN:GetKeyValues()
        CONV_ENV_SUN.SunSize = data.size
        CONV_ENV_SUN.OverlaySize = data.overlaysize
        CONV_ENV_SUN.SunColor = data.suncolor
        CONV_ENV_SUN.OverlayColor = data.overlaycolor
    end

    conv.parseNodeFile()

    if CLIENT then
        net.Start("CONV_ScreenRes")
        net.WriteFloat(ScrW())
        net.WriteFloat(ScrH())
        net.SendToServer()
    end
end)


hook.Add("PostCleanupMap", "CONV", function()
    if SERVER then
        conv.createLuaRun()
    end
end )

--[[
==================================================================================================
					ENTITY FUNCTION EXPANSION
==================================================================================================
--]]

hook.Add("OnEntityCreated", "CONV_COMPATIBILITY", function( ent )
    ent:CONV_CallNextTick( function()
        local owner = ent:GetOwner()
        if IsValid(owner) then hook.Run( "OnCreatedEntity", owner, ent ) end
    end )
end)