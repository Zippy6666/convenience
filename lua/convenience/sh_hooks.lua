hook.Add("InitPostEntity", "CONV", function()

    ents._SpawnMenuNPCs = list.Get("NPC") -- Fetch list of spawn menu NPCs

    -- Add zbase npcs if it is installed
    if ZBaseInstalled then
        local ZBSpawnMenu = {}
        
        for cls, tbl in pairs(ZBaseSpawnMenuNPCList) do

            local copy = table.Copy(tbl)
            copy.KeyValues = copy.KeyValues or {}
            copy.KeyValues.parentname = cls

            ZBSpawnMenu[cls] = copy

        end

        table.Merge(ents._SpawnMenuNPCs, ZBSpawnMenu)
    end

end)