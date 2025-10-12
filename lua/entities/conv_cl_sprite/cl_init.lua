include("shared.lua")

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.m_tabRenderFX ={
    -- No effect, just returns the original color
    none = function(t, baseCol, pos) return baseCol end,

    -- Pulse effect, varies alpha based on sine wave
    -- 'speed' controls the frequency of the pulse
    pulse = function(t, baseCol, pos, speed, strength)
        local speed = speed or 4
        local strength = strength or 1
        local alpha = baseCol.a + math.sin(t * speed) * baseCol.a * strength
        return Color(baseCol.r, baseCol.g, baseCol.b, math.Clamp(alpha, 0, baseCol.a))
    end,

    -- Blink effects, toggles alpha based on time
    -- 'delay' controls the blink duration
    -- 'speed' controls the blink frequency
    blinkfadein = function(t, baseCol, pos, delay, speed)
        local delay = delay or 4
        local speed = speed or 1
        local alpha = math.min(baseCol.a, ((t % (delay * 2)) * baseCol.a) * speed)
        return Color(baseCol.r, baseCol.g, baseCol.b, alpha)
    end,

    -- Blink fade out effect, fades out alpha over time
    -- 'delay' controls the fade duration
    -- 'speed' controls the fade speed
    blinkfadeout = function(t, baseCol, pos, delay, speed)
        local delay = delay or 4
        local speed = speed or 1
        local alpha = math.max(0, baseCol.a - ((t % (delay * 2) * baseCol.a) * speed))
        return Color(baseCol.r, baseCol.g, baseCol.b, alpha)
    end,

    -- Strobe effect, toggles alpha on and off
    -- 'delay' controls the strobe duration
    -- 'speed' controls the strobe frequency
    strobe = function(t, baseCol, pos, delay, speed)
        local delay = delay or 8
        local speed = speed or 8
        local on = math.floor(t * speed) % delay == 0
        return Color(baseCol.r, baseCol.g, baseCol.b, on and baseCol.a or 0)
    end,

    -- Flicker effect, varies alpha randomly
    flicker = function(t, baseCol, pos)
        local alpha = baseCol.a * (0.5 + math.Rand(0.3, 1))
        return Color(baseCol.r, baseCol.g, baseCol.b, math.Clamp(alpha, 0, baseCol.a))
    end,

    -- Color cycle effect, smoothly transitions between multiple colors
    -- 'delay' controls the time between color changes
    -- 'speed' controls the speed of the color transition
    -- 'colTab' is a table of colors to cycle through
    colorcycle = function(t, baseCol, pos, delay, speed, colTab)
        -- If the first argument is a table, use it as the color list
        if #colTab == 1 and istable(colTab[1]) then
            colTab = colTab[1]
        end
        if #colTab == 0 then
            colTab = {baseCol, Color(255,255,255,baseCol.a)}
        end
        delay = delay or 1
        speed = speed or 1
        local total = #colTab   
        local cycleTime = delay * total / speed
        local cur = (t % cycleTime) / delay * speed
        local idx1 = math.floor(cur) % total + 1
        local idx2 = (idx1 % total) + 1
        local frac = cur - math.floor(cur)
        local c1, c2 = colTab[idx1], colTab[idx2]
        local r = Lerp(frac, c1.r, c2.r)
        local g = Lerp(frac, c1.g, c2.g)
        local b = Lerp(frac, c1.b, c2.b)
        local a = Lerp(frac, c1.a, c2.a)
        return Color(r, g, b, a)
    end,

    -- Blink effect, toggles alpha on and off
    -- 'speed' controls the blink frequency
    blink = function(t, baseCol, pos, speed)
        local speed = speed or 2
        local on = math.floor(t * speed) % 2 == 0
        return Color(baseCol.r, baseCol.g, baseCol.b, on and baseCol.a or 0)
    end,

    -- Fade in effect, smoothly increases alpha based on distance from player
    -- 'fadeDist' controls the distance at which the sprite is fully faded in
    fadein = function(t, baseCol, pos, fadeDist)
        local ply = LocalPlayer()
        if not IsValid(ply) or not pos then return baseCol end
        local dist = ply:GetPos():Distance(pos)
        local fadeDist = fadeDist or 256 -- distance at which sprite is fully faded in
        if dist > fadeDist then return Color(baseCol.r, baseCol.g, baseCol.b, 0) end
        local alpha = math.Clamp(baseCol.a * (1 - math.Clamp(dist / fadeDist, 0, 1)), 0, baseCol.a)
        return Color(baseCol.r, baseCol.g, baseCol.b, alpha)
    end,

    -- Fade out effect, smoothly decreases alpha based on distance from player
    -- 'fadeDist' controls the distance at which the sprite is fully faded out
    fadeout = function(t, baseCol, pos, fadeDist)
        local ply = LocalPlayer()
        if not IsValid(ply) or not pos then return baseCol end
        local dist = ply:GetPos():Distance(pos)
        local fadeDist = fadeDist or 256 -- distance at which sprite is fully faded out
        if dist > fadeDist then return Color(baseCol.r, baseCol.g, baseCol.b, 0) end
        local alpha = math.Clamp(baseCol.a * (1 - (dist / fadeDist)), 0, baseCol.a)
        return Color(baseCol.r, baseCol.g, baseCol.b, alpha)
    end,
}

ENT.m_sModel = Material("sprites/glow04")
ENT.m_pPixelVisHandle = nil
ENT.m_flWidth = 32
ENT.m_flHeight = 32
ENT.m_fGlowProxy = math.max(32, 32) * 0.5 -- Default glow proxy size
ENT.m_fRenderMode = 3 -- Default render mode
ENT.m_funcRenderFX = ENT.m_tabRenderFX.none -- Default render effect function
ENT.m_tabRenderFXValues = {}


-- Initialize the entity
-- Sets the model and initializes pixel visibility handle
function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self.m_pPixelVisHandle = util.GetPixelVisibleHandle()
end


-- Set the sprite model
-- Accepts a material name or a Material object
-- Optionally accepts PNG parameters for the material
-- If a string is provided, it will be converted to a Material object
-- If a Material object is provided, it will be used directly
-- If no material is provided, it defaults to "sprites/glow04"
function ENT:SetSpriteModel(materialName, pngParameters)
    local matPath = materialName or self.m_sModel
    if isstring(matPath) then
        self.m_sModel = Material(matPath, pngParameters or "")
    else
        self.m_sModel = matPath
    end
end


-- Get the sprite model
-- Returns the Material object used for the sprite
-- If no model is set, it defaults to "sprites/glow04"
function ENT:GetSpriteModel()
    return self.m_sModel
end


-- Set the sprite render mode
-- Accepts a render mode value
-- If no value is provided, it defaults to 3 (glow)
-- https://developer.valvesoftware.com/wiki/Render_modes
function ENT:SetSpriteRenderMode(mode)
    self.m_fRenderMode = mode or 3
end


-- Get the sprite render mode
-- Returns the current render mode value
function ENT:GetSpriteRenderMode()
    return self.m_fRenderMode
end


-- Set the sprite render effect
-- Accepts a name of the effect and optional parameters
-- The name should match one of the keys in m_tabRenderFX
-- If the name is not found, it defaults to "none"
function ENT:SetSpriteRenderFX(name, ...)
    self.m_tabRenderFXValues = {...}
    self.m_funcRenderFX = self.m_tabRenderFX[name] or self.m_tabRenderFX.none   
end


-- Get the sprite render effect
-- Returns the color based on the current render effect and parameters
-- Uses the current time, base color, position, and any additional parameters
function ENT:GetSpriteRenderFX()
    local t = CurTime()
    local baseCol = self:GetColor()
    local pos = self:GetPos()
    return self.m_funcRenderFX(t, baseCol, pos, unpack(self.m_tabRenderFXValues))
end


-- Set the sprite size
-- Accepts width and height parameters
-- If no parameters are provided, defaults to 32x32
function ENT:SetSpriteSize(width, height)
    self.m_flWidth = width or 32
    self.m_flHeight = height or 32
    self:SetSpriteGlowProxy()
end


-- Get the sprite size
-- Returns the width and height of the sprite
-- If no size is set, defaults to 32x32
function ENT:GetSpriteSize()
    return self.m_flWidth, self.m_flHeight
end


-- Set the sprite glow proxy size
-- Accepts a value for the glow proxy size
function ENT:SetSpriteGlowProxy(val)
    local val = val or math.max(self.m_flWidth, self.m_flHeight) * 0.5
    self.m_fGlowProxy = val 
end


-- Get the sprite glow proxy size
-- Returns the current glow proxy size
-- If no size is set, defaults to half the maximum of width and height
function ENT:GetSpriteGlowProxy()
    return self.m_fGlowProxy
end


-- Set the sprite parent attachment
-- Accepts an entity, attachment name, and an optional offset vector
-- The attachment name should be a valid attachment on the entity
-- The offset vector is applied to the position of the sprite
-- Offset should be based on the sprite entity, not parent attachment
function ENT:SetSpriteParentAttachment(ent, att, offset)
    if not IsValid(ent) then return end
    local att = ent:LookupAttachment(att)
    if not att then return end

    local offset = offset or Vector(0, 0, 0)

    self.m_vecOffset = offset
    self.m_fParent = ent
    self.m_sParentAttachment = att
end


-- Set the sprite parent entity
-- Accepts an entity and an optional offset vector
-- The offset vector is applied to the position of the sprite
function ENT:SetSpriteParent(ent, offset)
    if not IsValid(ent) then return end

    local offset = offset or Vector(0, 0, 0)

    self.m_vecOffset = offset
    self.m_fParent = ent
end


-- Think function to update the sprite position and angles
-- Checks if the parent entity is valid
-- If valid, updates the position and angles based on the parent attachment or entity position
-- If the parent entity is no longer valid, removes the sprite entity
-- If an offset is set, applies it to the position before setting
function ENT:Think()

    local parent = self.m_fParent

    if IsValid(parent) then

        if self.m_sParentAttachment then

            local attData = parent:GetAttachment(self.m_sParentAttachment)

            if attData then

                local pos = attData.Pos

                if self.m_vecOffset then

                    local offset = Vector( self.m_vecOffset.x, self.m_vecOffset.y, self.m_vecOffset.z )
                    offset:Rotate(self:GetAngles())
                    pos = pos + offset

                end

                self:SetPos(pos)
                self:SetAngles(attData.Ang)

            end

        else
            
            local pos = parent:GetPos()

            if self.m_vecOffset then

                local offset = Vector( self.m_vecOffset.x, self.m_vecOffset.y, self.m_vecOffset.z )
                offset:Rotate(self:GetAngles())
                pos = pos + offset

            end

            self:SetPos(pos)
            self:SetAngles(parent:GetAngles())

        end

    elseif not IsValid(parent) and self.m_fParent then

        self:Remove()

    end

end


-- Draw function to render the sprite
-- Uses util.PixelVisible to determine visibility
-- If the sprite is not visible, it returns early
-- Otherwise, it sets the sprite model and draws it with the specified color and size
-- The color is adjusted based on the visibility fraction
-- The sprite model's render mode is set based on the current render mode or defaults to 1
function ENT:DrawTranslucent()

    local pos = self:GetPos()
    local col = self:GetSpriteRenderFX()
    local w, h = self:GetSpriteSize()

    -- Use util.PixelVisible to determine visibility
    if not self.m_pPixelVisHandle then
        self.m_pPixelVisHandle = util.GetPixelVisibleHandle()
    end

    local eyePos = EyePos()
    local visFrac = util.PixelVisible(pos, self:GetSpriteGlowProxy() * self:GetModelScale(), self.m_pPixelVisHandle) or 0

    if visFrac <= 0 then return end

    col = Color(col.r, col.g, col.b, col.a * visFrac)

    self:GetSpriteModel():SetInt( "$spriterendermode", self:GetSpriteRenderMode() or self:GetSpriteModel():GetInt( "$spriterendermode" ) or 3 )

    render.SetMaterial(self:GetSpriteModel())
    render.DrawSprite(
        pos,
        w,
        h,
        col
    )
end