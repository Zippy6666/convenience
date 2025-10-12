local surface = surface
local draw = draw
local render = render
local Color = Color

local _clearColor = Color(0, 0, 0, 0)

function surface.DrawRoundedOutlinedRect(radius, x, y, w, h, col, thickness)
    thickness = thickness or 1
    if thickness <= 0 or w <= 0 or h <= 0 then return end

    radius = math.max(radius or 0, 0)
    if not col then
        local r, g, b, a = surface.GetDrawColor()
        col = Color(r, g, b, a)
    end

    local innerW = w - thickness * 2
    local innerH = h - thickness * 2
    local innerRadius = math.max(radius - thickness, 0)

    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)

    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    draw.RoundedBox(radius, x, y, w, h, _clearColor)

    if innerW > 0 and innerH > 0 then
        render.SetStencilReferenceValue(0)
        render.SetStencilPassOperation(STENCIL_ZERO)
        draw.RoundedBox(innerRadius, x + thickness, y + thickness, innerW, innerH, _clearColor)
        render.SetStencilReferenceValue(1)
    end

    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)
    draw.RoundedBox(radius, x, y, w, h, col)

    render.SetStencilEnable(false)
end
