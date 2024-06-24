conv = {}


    -- Do something next tick/frame
function conv.callNextTick( func, ... )

    local argtbl = table.Pack(...)

    timer.Simple(0, function()
        func(unpack(argtbl))
    end)

end


    -- Do something after a certain amount of ticks/frames
function conv.callAfterTicks( ticknum, func, ... )

    conv.callNextTick( function( ... )

        if ticknum <= 0 then
            func(...)
        else
            conv.callAfterTicks( ticknum-1, func, ... )
        end
        

    end, ... )

end



    -- Create a simple derma frame
function conv.dermaFrame( title, width, height )
    local frame = vgui.Create("DFrame")
    frame:SetPos( (ScrW()*0.5)-width*0.5, (ScrH()*0.5)-height*0.5 )
    frame:SetSize(width, height)
    frame:SetTitle(title)
    frame:MakePopup()
    return frame
end


    -- Checks if any player on the server can see this position right now
function conv.playersSeePos( pos )
    for _, ply in player.Iterator() do
        if ply:PosInView(pos) then
            return true
        end
    end
end


    -- Debug Overlay QOL
    -- https://wiki.facepunch.com/gmod/debugoverlay
    -- conv.overlay("Something", function()
    --     return {}
    -- end)
function conv.overlay( funcname, argsFunc )
    if !Developer:GetBool() then return end
    local args = argsFunc()
    debugoverlay[funcname](unpack(args))
end


    -- DEPRECATED
function conv.getSpawnMenuNPCs()
    return table.Copy(ents._SpawnMenuNPCs)
end