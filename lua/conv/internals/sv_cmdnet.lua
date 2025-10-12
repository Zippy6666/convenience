-- INTERNAL, DO NOT USE

util.AddNetworkString("CONV_StripAndTools")
util.AddNetworkString("CONV_GiveAmmo")
util.AddNetworkString("CONV_RmWep")
util.AddNetworkString("CONV_ScreenRes")

net.Receive("CONV_StripAndTools", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    ply:StripWeapons()
    ply:Give("weapon_physgun")
    ply:Give("gmod_camera")
    ply:Give("gmod_tool")
    ply:Give("weapon_physcannon")
end)

net.Receive("CONV_GiveAmmo", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    for ammoid, ammoname in pairs(game.GetAmmoTypes()) do
        ply:GiveAmmo(game.GetCurrentAmmoMax(ammoid), ammoname)
    end
end)

net.Receive("CONV_RmWep", function(len, ply)
    local wep = ply:GetActiveWeapon()
    
    if not IsValid(wep) then 
        ply:PrintMessage(HUD_PRINTTALK, "No weapon to remove.")    
        return 
    end

    ply:DropWeapon(wep)
    wep:Remove()
end)

net.Receive("CONV_ScreenRes", function(len, ply)
    ply.CONV_SCRNW = net.ReadFloat()
    ply.CONV_SCRNH = net.ReadFloat()
end)