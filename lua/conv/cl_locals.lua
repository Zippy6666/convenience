--[[
==================================================================================================
                    DERMA
==================================================================================================
--]]


-- Create a simple derma frame
local function DermaFrame( title, width, height )
    local frame = vgui.Create("DFrame")
    frame:SetPos( (ScrW()*0.5)-width*0.5, (ScrH()*0.5)-height*0.5 )
    frame:SetSize(width, height)
    frame:SetTitle(title)
    frame:MakePopup()
    return frame
end