-- Add network strings
util.AddNetworkString("ConvStrip")
util.AddNetworkString("ConvGiveAmmo")


-- Strip the players weapons and ammo on server from client
net.Receive("ConvStrip", function(len, ply)
    ply:StripWeapons()
    ply:RemoveAllAmmo()
end)


-- Strip the players weapons and ammo on server from client
net.Receive("ConvGiveAmmo", function(len, ply)
    for ammoid, ammoname in pairs(game.GetAmmoTypes()) do
        ply:GiveAmmo(game.GetCurrentAmmoMax(ammoid), ammoname)
    end
end)