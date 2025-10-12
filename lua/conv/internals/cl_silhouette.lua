--[[
==================================================================================================
                    MODULE BY filz0
==================================================================================================
--]]
local istable			= istable
local render			= render
local hook				= hook
local IsValid			= IsValid

module( "conv_silhouette", package.seeall )

local MODE_BOTH = 0
local MODE_NOTVISIBLE = 1
local MODE_VISIBLE = 2

local List, ListSize		= {}, 0
local RenderEnt				= NULL
local cheapRender			= Material("models/debug/debugwhite")
local defTexture			= "models/debug/debugwhite"

local mat_settings = {
    ["$basetexture"] = defTexture,
    ["$ignorez"] = 1,
    ["$alphatest"] = 1,
    ["$smooth"] = 0,
}

local mat = CreateMaterial("conv_silhouette", "UnlitGeneric", mat_settings)
local ENTS, COLOR, MODE, TEXTURE, MATERIALDRAW, CHILDREN = 1, 2, 3, 4, 5, 6
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



function Add( ents, color, mode, texture, matDraw, include_children )

	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	
	if ( not istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables
	
	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ MODE ] = mode or MODE_BOTH,
		[ TEXTURE ] = texture,
		[ MATERIALDRAW ] = matDraw,
		[ CHILDREN ] = include_children,
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

	-- Render the models onto the stencil
	render.SetBlend(1)
	
	for i = 1, ListSize do

		-- Determine our reference value based on the list index
        reference = 0xFF - (i - 1)

		local data = List[i]

		if (data) then

			local vmDraw = renderManager:IsVMDraw(renderHook)
			local ents = data[ENTS]
			local color = data[COLOR]
			local mode = vmDraw and 2 or data[MODE]
			local texture = data[TEXTURE]
			local children = data[CHILDREN]		

			
			-- Determine our reference value based on the list index
			render.SetStencilReferenceValue(reference)

			if mode == MODE_BOTH or mode == MODE_VISIBLE then
				-- Setup the stencil for hidden or parts or the entire thing
				render.SetStencilCompareFunction(STENCIL_GREATER)
				render.SetStencilZFailOperation(mode == MODE_BOTH and STENCIL_REPLACE or STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilPassOperation(STENCIL_REPLACE)

				-- Draw our entities. They will draw as normal
				RenderModels(ents, children, renderHook)
				
			elseif mode == MODE_NOTVISIBLE then
				-- Setup the stencil for 2-pass rendering where we first determine what is hidden and then what is shown to prevent self z-fail
				
				render.SetStencilCompareFunction(STENCIL_NEVER)
				render.SetStencilZFailOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_REPLACE)
				render.SetStencilPassOperation(STENCIL_KEEP)

				-- Draw our entities. They will draw as normal
				RenderModels(ents, children, renderHook)
	
				-- Setup the stencil for the second pass
				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.SetStencilZFailOperation(STENCIL_KEEP)
				render.SetStencilFailOperation(STENCIL_KEEP)
				render.SetStencilPassOperation(STENCIL_ZERO)

				RenderModels(ents, children, renderHook)
			end

		end

	end

	RenderEnt = NULL

	-- Setup the stencil to override the color of values equal to reference
	-- this makes sure we can only touch pixels that the previous rendering operations have touched
	render.SetStencilCompareFunction(STENCIL_EQUAL)
	render.SetStencilZFailOperation(STENCIL_KEEP)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilPassOperation(STENCIL_KEEP)
	
	for i = 1, ListSize do

		-- Determine our reference value based on the list index
        reference = 0xFF - (i - 1)

		local data = List[i]

		if (data) then

			local color = data[COLOR]
			local texture = data[TEXTURE]
			local matDraw = data[MATERIALDRAW]

			-- Determine our reference value based on the list index
			render.SetStencilReferenceValue(reference)

			if texture then

				if texture.Recompute then
					mat = texture
				else
					mat:SetTexture("$basetexture", texture)
				end

				mat:SetVector("$color", Vector(color.r / 255, color.g / 255, color.b / 255))
				
				if matDraw then matDraw(mat) end

				cam.Start2D()
					surface.SetDrawColor(255, 255, 0, 255)

					surface.SetMaterial(mat)
					surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
				cam.End2D()
			else
				render.ClearBuffersObeyStencil( color.r, color.g, color.b, color.a, true)
			end

		end

	end

	render.SetStencilEnable(false)

end



local function CONVRenderSilhouettes(renderHook)

	hook.Run( "CONVSetupSilhouettes", renderHook )
	
	if ( ListSize == 0 ) then return end
	
	Render(renderHook)

	List, ListSize = {}, 0	
end



hook.Add("PreDrawViewModels", "CONVRenderSilhouettes", function()
    CONVRenderSilhouettes("PreDrawViewModels")	
end)

hook.Add("PreDrawViewModel", "CONVRenderSilhouettes", function()
    CONVRenderSilhouettes("PreDrawViewModel")	
end)

hook.Add("PostDrawViewModel", "CONVRenderSilhouettes", function()
    CONVRenderSilhouettes("PostDrawViewModel")
end)

hook.Add("PreDrawPlayerHands", "CONVRenderSilhouettes", function()
    CONVRenderSilhouettes("PreDrawPlayerHands")
end)

hook.Add("PostDrawPlayerHands", "CONVRenderSilhouettes", function()
    CONVRenderSilhouettes("PostDrawPlayerHands")
end)

hook.Add("PreDrawEffects", "CONVRenderSilhouettes", function()
    CONVRenderSilhouettes("PreDrawEffects")
end)

hook.Add("PostDrawEffects", "CONVRenderSilhouettes", function()
    CONVRenderSilhouettes("PostDrawEffects")
end)



-- Helper function to apply silhouette effect usint conv.callOnClient
function conv.addSilhouette( hookName, ents, color, mode, texture, include_children )

	if not ents then hook.Remove( "CONVSetupSilhouettes", hookName ) return end

	hook.Add( "CONVSetupSilhouettes", hookName, function()

		conv_silhouette.Add( ents, color, mode, texture, include_children )

	end )

end


--[[
local istable			= istable
local render			= render
local hook				= hook
local IsValid			= IsValid

module( "conv_silhouette", package.seeall )

local List, ListSize		= {}, 0
local RenderEnt				= NULL
local materialDebugWhite 	= Material("models/debug/debugwhite")

local ENTS, COLOR, CHILDREN	= 1, 2, 3


function Add( ents, color, include_children )
	
	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( not istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables


	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ CHILDREN ] = include_children,
	}
	
	ListSize = ListSize + 1
	List[ ListSize ] = data
	
end

function RenderedEntity()
	
	return RenderEnt
end

local vmCrashFix = {

	antiOverflow = false,

	IsVMEnt = function(self, class, renderType)
		local vm = class == "viewmodel"
		local hands = class == "gmod_hands"
		return ( vm and renderType == 1 or hands and renderType == 2 ) and not self.antiOverflow or not vm and not hands and renderType == 0
	end
}
	 
local function IsOnScreen(ent)

	local pos = ent:GetPos()
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

local function RenderModels(ents, renderType, children)

	for i = 1, #ents do

		local ent = ents[i]

		if IsValid(ent) then

			if not ent:Alive() then return end
			if not IsOnScreen(ent) then return end
			if not vmCrashFix:IsVMEnt(ent:GetClass(), renderType) then return end
			
			RenderEnt = ent

			ent:DrawModel()

			if children then
				local childrenmodels = ent:GetChildren()
				if childrenmodels and #childrenmodels > 0 then RenderModels(childrenmodels, renderType, children) end
			end

		end

	end
	
end

local function Render(renderType, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	if (bDrawingSkybox or isDraw3DSkybox) then return end -- Do not render overlays in depth pass or skybox
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

	-- Render the models onto the stencil
	render.SetBlend(1)
	
	for i = 1, ListSize do

		-- Determine our reference value based on the list index
        reference = 0xFF - (i - 1)

		local data = List[i]
		local ents = data[ENTS]
		local color = data[COLOR]
		local children = data[CHILDREN]		
		
		-- Determine our reference value based on the list index
		render.SetStencilReferenceValue(reference)
		-- Always draw everything
		render.SetStencilCompareFunction(STENCIL_GREATER)
		-- If something would draw to the screen but is behind something, set the pixels it draws to 1
		render.SetStencilZFailOperation(STENCIL_REPLACE)

		vmCrashFix.antiOverflow = true -- If missing, game crashes. Guess it doesn't like DrawModel() in post VM or Hands. :(
		
		-- Render using a cheap material
		render.MaterialOverride(materialDebugWhite)
		-- We dont need lighting
		render.SuppressEngineLighting(true)
		-- We dont need color
		render.OverrideColorWriteEnable(true, false)
		-- We dont need depth
		render.OverrideDepthEnable(true, false)

		-- Draw our entities. They will draw as normal
		RenderModels(ents, renderType, children)
		
		render.OverrideColorWriteEnable(false)
		render.SuppressEngineLighting(false)
		render.MaterialOverride(nil)
		render.OverrideDepthEnable(false)

		-- Now, only draw things that have their pixels set to 1. This is the hidden parts of the stencil tests.
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		-- Flush the screen. This will draw teal over all hidden sections of the stencil tests
		render.ClearBuffersObeyStencil(color.r, color.g, color.b, color.a, false)
		-- Let everything render normally again

		-- This fixes ZFail triggering on the entity itself. Or something.
		RenderModels(ents, renderType, children)

		vmCrashFix.antiOverflow = false

	end

	RenderEnt = NULL

	render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilPassOperation(STENCIL_KEEP)

	render.SetStencilEnable(false)

end

local function CONVRenderSilhouettes(renderType, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	hook.Run( "CONVSetupSilhouettes", Add )

	if ( ListSize == 0 ) then return end
	
	Render(renderType, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)
	
	List, ListSize = {}, 0	
end

hook.Add( "PostDrawTranslucentRenderables", "CONVRenderSilhouettes", function(bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)	
	CONVRenderSilhouettes(0, bDrawingDepth, bDrawingSkybox, isDraw3DSkybox)	
end )

hook.Add( "PreDrawViewModels", "CONVRenderSilhouettes", function()
	CONVRenderSilhouettes(1)	
end )

hook.Add( "PostDrawPlayerHands", "CONVRenderSilhouettes", function()
	CONVRenderSilhouettes(2)	
end )

-- Helper function to apply silhouette effect usint conv.callOnClient
function conv.addSilhouette( hookName, ents, color, include_children )

	if not ents and not color and not include_children then hook.Remove( "CONVSetupSilhouettes", hookName ) return end

	hook.Add( "CONVSetupSilhouettes", hookName, function()

		conv_silhouette.Add( ents, color, include_children )

	end )

end

]]--