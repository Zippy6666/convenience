-- INTERNAL, DO NOT USE

util.AddNetworkString("ConvStrip")
util.AddNetworkString("ConvGiveAmmo")
util.AddNetworkString("ConvRmWep")

net.Receive("ConvStrip", function(len, ply)
    if !ply:IsSuperAdmin() then return end
    ply:StripWeapons()
    ply:Give("weapon_physgun")
    ply:Give("gmod_camera")
    ply:Give("gmod_tool")
    ply:Give("weapon_physcannon")
end)

net.Receive("ConvGiveAmmo", function(len, ply)
    if !ply:IsSuperAdmin() then return end
    for ammoid, ammoname in pairs(game.GetAmmoTypes()) do
        ply:GiveAmmo(game.GetCurrentAmmoMax(ammoid), ammoname)
    end
end)

net.Receive("ConvRmWep", function(len, ply)
    local wep = ply:GetActiveWeapon()
    
    if !IsValid(wep) then 
        ply:PrintMessage(HUD_PRINTTALK, "No weapon to remove.")    
        return 
    end

    ply:DropWeapon(wep)
    wep:Remove()
end)