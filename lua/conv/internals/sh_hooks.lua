// INTERNAL, DO NOT USE

hook.Add("InitPostEntity", "CONV", function()
    -- Store spawn menu NPCs
    conv._SpawnMenuNPCs = list.Get("NPC")

    if ZBaseInstalled && istable(conv._SpawnMenuNPCs) && istable(ZBaseNPCs) then
        table.Merge(conv._SpawnMenuNPCs, table.Copy(ZBaseNPCs))
    end

    ents._SpawnMenuNPCs = conv._SpawnMenuNPCs -- Backwards compatability
end)

hook.Add( "InitPostEntity", "CONV", function()
    if SERVER then
        conv.createLuaRun()
    end

    if CLIENT then
        net.Start("CONV_ScreenRes")
        net.WriteFloat(ScrW())
        net.WriteFloat(ScrH())
        net.SendToServer()
    end
end)


hook.Add( "PostCleanupMap", "CONV", function()
    if SERVER then
        conv.createLuaRun()
    end
end)
