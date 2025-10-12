AddCSLuaFile()
AddCSLuaFile("cl_init.lua")

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.Author = "Zippy"
ENT.Spawnable = false
ENT.PrintName = "Floating Text"
ENT.AutomaticFrameAdvance = false

conv._3dTexts = conv._3dTexts or {}

function ENT:Initialize()
    self:DrawShadow(false)
end

function ENT:SetupDataTables()
    self:NetworkVar("String", 0,    "strText")
    self:NetworkVar("Float", 0,     "fSize")
    self:NetworkVar("Vector", 0,    "vecColor")
end

function ENT:resetRemoveTimer(fDuration)
    --[[ 
        Set or reset remove timer 
    ]]--

    if not isnumber(fDuration) then
        error("No duration set for text!")
    end

    self:CONV_TimerCreate("RemoveFloatingText", fDuration, 1, function()
        self:Remove()
    end)
end