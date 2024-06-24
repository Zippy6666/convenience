-- Strip players weapons
concommand.Add("conv_strip", function(ply, cmd, args)
    net.Start("ConvStrip")
    net.SendToServer()
end)


-- Give ammo of all kinds to the player
concommand.Add("conv_giveammo", function(ply, cmd, args)
    net.Start("ConvGiveAmmo")
    net.SendToServer()
end)
