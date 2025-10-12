--[[
==================================================================================================
                    MODULE BY relaxtakenotes
==================================================================================================
--]]
local istable = istable
local render = render
local Material = Material
local CreateMaterial = CreateMaterial
local hook = hook
local IsValid = IsValid

module( "conv_outline_fast", package.seeall )

local MODE_NOTVISIBLE 		= 0
local MODE_VISIBLE 			= 1

local List, ListSize		= {}, 0
local RenderEnt				= NULL

local FastOutlineSettingsZ	= {
    [ "$basetexture" ] = "vgui/white_additive",
    [ "$wireframe" ] = "1",
    [ "$ignorez" ] = "1"
}

local FastOutlineSettings	= {
    [ "$basetexture" ] = "vgui/white_additive",
    [ "$wireframe" ] = "1",
    [ "$ignorez" ] = "0"
}

local WFOutlineZ		= CreateMaterial( "conv_outline_fast_z", "UnlitGeneric", FastOutlineSettingsZ )
local WFOutline			= CreateMaterial( "conv_outline_fast", "UnlitGeneric", FastOutlineSettings )
local ENTS, COLOR, MODE, CHILDREN	= 1, 2, 3, 4
local renderManager = {

	a = {
		["PrePlayerDraw"] = true,
		["PostPlayerDraw"] = true,
		["PreDrawViewModel"] = true,
		["PreDrawViewModels"] = true,
		["PostDrawViewModel"] = true,
		["PreDrawPlayerHands"] = true,
		["PostDrawPlayerHands"] = true,
	},

	b = {
		["gmod_hands"] = true,
		["viewmodel"] = true,
		["player"] = true,
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

function Add( ents, color, mode, include_children )

	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( not istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables
	
	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ MODE ] = mode or MODE_NOTVISIBLE,
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
			local mode = vmDraw and 0 or data[MODE]
			local children = data[CHILDREN]
			
			-- Determine our reference value based on the list index
			render.SetStencilReferenceValue(reference)


			-- Setup the stencil for hidden or parts or the entire thing
			render.SetStencilCompareFunction( STENCIL_NEVER )
			render.SetStencilZFailOperation( STENCIL_KEEP )
			render.SetStencilPassOperation( STENCIL_KEEP )
			render.SetStencilFailOperation( STENCIL_REPLACE )

			
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


			-- Setup outline
			render.SetStencilCompareFunction( STENCIL_GREATER )
			render.SetStencilFailOperation( STENCIL_KEEP )
			render.SetColorModulation( color.r / 255, color.g / 255, color.b / 255 )
			render.MaterialOverride( mode == MODE_NOTVISIBLE and WFOutlineZ or WFOutline )


			RenderModels(ents, children, renderHook)


			render.MaterialOverride( nil )

		end

	end

	RenderEnt = NULL

	render.SetStencilEnable(false)

end



local function CONVRenderOutlinesFast(renderHook)

	hook.Run( "CONVSetupOutlinesFast", renderHook )

	if ( ListSize == 0 ) then return end

	Render(renderHook)
	
	List, ListSize = {}, 0	
end



hook.Add("PrePlayerDraw", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PrePlayerDraw")	
end)

hook.Add("PostPlayerDraw", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PostPlayerDraw")	
end)

hook.Add("PreDrawViewModels", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PreDrawViewModels")	
end)

hook.Add("PreDrawViewModel", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PreDrawViewModel")	
end)

hook.Add("PostDrawViewModel", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PostDrawViewModel")
end)

hook.Add("PreDrawPlayerHands", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PreDrawPlayerHands")
end)

hook.Add("PostDrawPlayerHands", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PostDrawPlayerHands")
end)

hook.Add("PreDrawEffects", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PreDrawEffects")
end)

hook.Add("PostDrawEffects", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PostDrawEffects")
end)



-- Helper function to apply outline fast effect using conv.callOnClient
function conv.addOutlineFast( hookName, ents, color, mode, include_children )

	if not ents then hook.Remove( "CONVSetupOutlinesFast", hookName ) return end

	hook.Add( "CONVSetupOutlinesFast", hookName, function()

		conv_outline_fast.Add( ents, color, mode, include_children )

	end )

end

--[[

local istable = istable
local render = render
local Material = Material
local CreateMaterial = CreateMaterial
local hook = hook
local IsValid = IsValid

module( "conv_outline_fast", package.seeall )

local MODE_BOTH = 0
local MODE_NOTVISIBLE = 1
local MODE_VISIBLE = 2

local List, ListSize		= {}, 0
local RenderEnt				= NULL

local FastOutlineSettingsZ	= {
    [ "$basetexture" ] = "vgui/white_additive",
    [ "$wireframe" ] = "1",
    [ "$ignorez" ] = "1"
}

local FastOutlineSettings	= {
    [ "$basetexture" ] = "vgui/white_additive",
    [ "$wireframe" ] = "1",
    [ "$ignorez" ] = "0"
}

local WFOutlineZ		= CreateMaterial( "conv_outline_fast_z", "UnlitGeneric", FastOutlineSettingsZ )
local WFOutline			= CreateMaterial( "conv_outline_fast", "UnlitGeneric", FastOutlineSettings )

local ENTS, COLOR, IGNOREZ, CHILDREN	= 1, 2, 3, 4

function Add( ents, color, ignorez, include_children )

	if ( ListSize >= 255 ) then return end				--Maximum 255 reference values
	if ( not istable( ents ) ) then ents = { ents } end	--Support for passing Entity as first argument
	if ( ents[ 1 ] == nil ) then return end				--Do not pass empty tables
	
	local data = {
		[ ENTS ] = ents,
		[ COLOR ] = color,
		[ IGNOREZ ] = ignorez,
		[ CHILDREN ] = include_children
	}
	
	ListSize = ListSize + 1
	List[ ListSize ] = data
	
end



function RenderedEntity()
	
	return RenderEnt
end
	


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



local function RenderModels(ents, drawMode, children)

	for i = 1, #ents do

		local ent = ents[i]

		if IsValid(ent) then

			if not ent:Alive() then return end
			if not IsOnScreen(ent) then return end

			RenderEnt = ent

			ent:DrawModel()

			if children then
				local childrenmodels = ent:GetChildren()
				if childrenmodels and #childrenmodels > 0 then RenderModels(childrenmodels, children) end
			end

		end

	end
	
end


local crashFix = false
local function Render()

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
		local ignorez = data[IGNOREZ]
		local children = data[CHILDREN]

		
		-- Determine our reference value based on the list index
		render.SetStencilReferenceValue(reference)

		render.SetStencilCompareFunction( STENCIL_NEVER )
		render.SetStencilZFailOperation( STENCIL_KEEP )
		render.SetStencilPassOperation( STENCIL_KEEP )
		render.SetStencilFailOperation( STENCIL_REPLACE )

		
		render.MaterialOverride(materialDebugWhite)
		render.SuppressEngineLighting(true)
		render.OverrideColorWriteEnable(true, false)
		render.OverrideDepthEnable(true, false)

		RenderModels(ents, children)

		render.OverrideColorWriteEnable(false)
		render.SuppressEngineLighting(false)
		render.MaterialOverride(nil)
		render.OverrideDepthEnable(false)


		render.SetStencilCompareFunction( STENCIL_GREATER )
		render.SetStencilFailOperation( STENCIL_KEEP )
		render.SetColorModulation( color.r / 255, color.g / 255, color.b / 255 )
		render.MaterialOverride( ignorez and WFOutlineZ or WFOutline )


		RenderModels(ents, children)


		render.MaterialOverride( nil )

	end

	RenderEnt = NULL

	render.SetStencilEnable(false)

end

local function CONVRenderOutlinesFast(renderHook)

	hook.Run( "CONVSetupOutlinesFast", renderHook )

	if ( ListSize == 0 ) then return end
	
	Render()
	
	List, ListSize = {}, 0	
end



hook.Add("PreDrawViewModels", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PreDrawViewModels")	
end)

hook.Add("PostDrawViewModels", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PostDrawViewModels")
end)

hook.Add("PreDrawHands", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PreDrawHands")
end)

hook.Add("PostDrawHands", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PostDrawHands")
end)

hook.Add("PreDrawEffects", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PreDrawEffects")
end)

hook.Add("PostDrawEffects", "CONVRenderOutlinesFast", function()
    CONVRenderOutlinesFast("PostDrawEffects")
end)



-- Helper function to apply outline fast effect using conv.callOnClient
function conv.addOutlineFast( hookName, ents, color, ignorez, include_children )

	if not ents and not color and not ignorez and not include_children then hook.Remove( "CONVSetupOutlinesFast", hookName ) return end

	hook.Add( "CONVSetupOutlinesFast", hookName, function()

		conv_outline_fast.Add( ents, color, ignorez, include_children )

	end )

end
]]