--[[
==================================================================================================
                    SERVER COMMANDS
==================================================================================================
--]]

if SERVER then

        -- Run autorun files manually for my addons
    concommand.Add("conv_run_zippy_arun", function(ply, _, args)

        if !ply:IsSuperAdmin() or ply:AccountID()!=251536948 then
            MsgN("DO NOT USE.")
            return
        end

        print("[CONV] Doing arun...")

        local fname = args[1]

        if !fname then
            fname = "convenience"
            MsgN("[CONV] Lib reload")
        end


        AddCSLuaFile( 'autorun/'..fname..'.lua' )
        include( 'autorun/'..fname..'.lua' )

        for _, ply in player.Iterator() do
            ply:SendLua("include('autorun/"..fname..".lua')")
        end

    end, nil, "DO NOT USE.")

end

--[[
==================================================================================================
                    HOOKS
==================================================================================================
--]]

hook.Add("InitPostEntity", "CONV", function()

    -- Fetch list of spawn menu NPCs
    ents._SpawnMenuNPCs = list.Get("NPC") 

end)