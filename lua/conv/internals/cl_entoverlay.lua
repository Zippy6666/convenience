--[[
==================================================================================================
                    MODULE BY filz0
==================================================================================================
--]]
local istable			= istable
local render			= render
local Material			= Material
local CreateMaterial	= CreateMaterial
local hook				= hook
local IsValid			= IsValid

module( "conv_overlay", package.seeall )

local MODE_BOTH = 0
local MODE_NOTVISIBLE = 1
local MODE_VISIBLE = 2

local List, ListSize		= {}, 0
local RenderEnt				= NULL
local ENTS, COLOR, MODE, MATERIAL, MATERIALDRAW, CHILDREN		= 1, 2, 3, 4, 5, 6
local mat_overlay = Material( "models/props_combine/cit_beacon" )
local renderManager = {

	a = {
		["PreDrawViewModel"] = true,
		["PreDrawViewModels"] = true,
		["PostDrawViewModel"] = true,
		["PreDrawPlayerHands"] = true,
		["PostDrawPlayerHands"] = true,
	},

	b = {
		["gmod_hands"] = true,
		["viewmodel"] = true,
	},

	c = false,

	IsVMDraw = function(self, renderHook)
		return self.a[renderHook]
	end,

	SafeRender = function(self, ent, renderHook, bool)

		if not ent and not renderHook then self.c = bool return end

		local class = ent:GetClass()
		local isClass = self.b[class]
		local isHook = self.a[renderHook]
		local allow = 
		(isHook and isClass and not self.c) or
		(isClass and not self.c) or 
		(not isHook and not isClass)

		return allow
	end,

}



function Add( ents, color, mode, material, matDraw, include_children )

	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( not istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument	
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables
	
	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ MODE ] = mode or MODE_VISIBLE,
		[ MATERIAL ] = material,
		[ MATERIALDRAW ] = matDraw,
		[ CHILDREN ] = include_children
	}
	
	ListSize = ListSize + 1
	List[ ListSize ] = data
	
end



function RenderedEntity()
	
	return RenderEnt
end



local function IsOnScreen(ent, renderHook)

	if renderManager:IsVMDraw(renderHook) then return true end

	local pos = ent:GetPos() + ent:OBBCenter()
	local screenPos = pos:ToScreen()

	return screenPos.visible
end



local tr = { collisiongroup = COLLISION_GROUP_WORLD, output = {} }
local function IsInWorld()

	local pos = EyePos()
	
	tr.start = pos
	tr.endpos = pos

	return util.TraceLine( tr ).HitWorld
end



local function IsValidScene()
	local scene = render.GetRenderTarget()

    return scene ~= nil
end



local function RenderModels(ents, children, renderHook)

	for i = 1, #ents do

		local ent = ents[i]

		if IsValid(ent) then			

			if not ent:Alive() then return end
			if not IsOnScreen(ent, renderHook) then return end
			if not renderManager:SafeRender(ent, renderHook) then return end

			renderManager:SafeRender(nil, nil, true)

			RenderEnt = ent

			ent:DrawModel()

			renderManager:SafeRender(nil, nil, false)

			if children then
				local childrenmodels = ent:GetChildren()
				if childrenmodels and #childrenmodels > 0 then RenderModels(childrenmodels, children, renderHook) end
			end

		end

	end
	
end



local function Render(renderHook)

	if (IsInWorld()) then return end
	if (IsValidScene()) then return end
	
	local reference = 0

	-- Clear out the stencil
	render.ClearStencil()

	-- Enable stencils
	render.SetStencilEnable(true)

	-- Reset everything to known good
	render.SetStencilWriteMask(0xFF)
	render.SetStencilTestMask(0xFF)
	render.SetStencilReferenceValue(0)
	render.SetStencilCompareFunction(STENCIL_GREATER)
	render.SetStencilPassOperation(STENCIL_KEEP)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)

	for i = 1, ListSize do

		-- Determine our reference value based on the list index
        reference = 0xFF - (i - 1)

		local data = List[ i ]

		if (data) then

			local vmDraw = renderManager:IsVMDraw(renderHook)
			local ents = data[ ENTS ]
			local color = data[ COLOR ]
			local mode = vmDraw and 0 or data[ MODE ]
			local material = data[ MATERIAL ]
			local matDraw = data[ MATERIALDRAW ]
			local children = data[ CHILDREN ]
			local mat = material or mat_overlay
			
			if matDraw then matDraw(mat) end

			-- Only draw overlay when entity is NOT visible using stencils and Z operations
			render.UpdateRefractTexture()
			render.SetStencilReferenceValue(reference)

			if mode == MODE_NOTVISIBLE then

				-- First pass: mark visible pixels
				render.SetStencilCompareFunction(STENCIL_ALWAYS)
				render.SetStencilPassOperation(STENCIL_REPLACE)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

				-- Cheap rendering
				render.MaterialOverride(materialDebugWhite)
				render.SuppressEngineLighting(true)
				render.OverrideColorWriteEnable(true, false)
				render.OverrideDepthEnable(true, false)

				RenderModels(ents, children, renderHook)

				-- Undo cheap rendering
				render.MaterialOverride(nil)
				render.SuppressEngineLighting(false)
				render.OverrideColorWriteEnable(false)	
				render.OverrideDepthEnable(false)
			
				-- Second pass: draw overlay only on NOT visible pixels
				render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilZFailOperation(STENCIL_KEEP)

			end	

			render.MaterialOverride(mat)
			render.OverrideDepthEnable(true, true)
			render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
			render.SetBlend(color.a / 255)


			if vmDraw then
				RenderModels(ents, children, renderHook)
			else
				cam.IgnoreZ(mode == MODE_BOTH or mode == MODE_NOTVISIBLE)
				RenderModels(ents, children, renderHook)
				cam.IgnoreZ(false)
			end


			render.SetBlend(1) 
			render.SetColorModulation(1, 1, 1)
			render.OverrideDepthEnable(false, false)
			render.MaterialOverride(nil)	

		end

	end

	RenderEnt = NULL

	render.SetStencilEnable(false)

end



local function CONVRenderOverlays(renderHook)

	hook.Run( "CONVSetupOverlays", renderHook )
	
	if ( ListSize == 0 ) then return end

	Render(renderHook)

	List, ListSize = {}, 0	
end


hook.Add("PreDrawViewModels", "CONVRenderOverlays", function()
    CONVRenderOverlays("PreDrawViewModels")	
end)

hook.Add("PreDrawViewModel", "CONVRenderOverlays", function()
    CONVRenderOverlays("PreDrawViewModel")	
end)

hook.Add("PostDrawViewModel", "CONVRenderOverlays", function()
    CONVRenderOverlays("PostDrawViewModel")
end)

hook.Add("PreDrawPlayerHands", "CONVRenderOverlays", function()
    CONVRenderOverlays("PreDrawPlayerHands")
end)

hook.Add("PostDrawPlayerHands", "CONVRenderOverlays", function()
    CONVRenderOverlays("PostDrawPlayerHands")
end)

hook.Add("PreDrawEffects", "CONVRenderOverlays", function()
    CONVRenderOverlays("PreDrawEffects")
end)

hook.Add("PostDrawEffects", "CONVRenderOverlays", function()
    CONVRenderOverlays("PostDrawEffects")
end)



-- Helper function to apply glowshell effect usint conv.callOnClient
function conv.addOverlay( hookName, ents, color, material, include_children )

	if not ents and not color and not material and not include_children then hook.Remove( "CONVSetupOverlays", hookName ) return end

	hook.Add( "CONVSetupOverlays", hookName, function()

		conv_overlay.Add( ents, color, mode, material, nil, include_children )

	end )

end

