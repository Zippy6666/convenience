local draw = draw 

-- Draw text with a shadow effect
-- 'text' <string>: The text to draw
-- 'font' <string>: The font to use
-- 'x' <number>: The x position
-- 'y' <number>: The y position
-- 'tColor' <Color>: The text color
-- 'xAlign' <number>: The x alignment
-- 'yAlign' <number>: The y alignment
-- 'sStrenght' <number>: The shadow strength
-- 'sColor' <Color>: The shadow color
function draw.CONV_SimpleTextShadow( text, font, x, y, tColor, xAlign, yAlign, sStrenght, sColor )

    if !text then return end

    local font = font or "DermaDefault"

    local x, y = x or 0, y or 0
    local tColor = tColor or color_white
    local xAlign = xAlign or TEXT_ALIGN_LEFT
    local yAlign = yAlign or TEXT_ALIGN_TOP
    local sStrenght = sStrenght or 1
    local sColor = sColor or color_black

    draw.SimpleText( text, font, x + sStrenght, y + sStrenght, sColor, xAlign, yAlign )
    local tW, tH = draw.SimpleText( text, font, x, y, tColor, xAlign, yAlign )

    return tW + sStrenght, tH + sStrenght
end

-- Draw text with a scrolling effect related to the mouse position
-- 'panel' <Panel>: The panel to draw on
-- 'text' <string>: The text to draw
-- 'font' <string>: The font to use
-- 'x' <number>: The x position
-- 'y' <number>: The y position
-- 'tColor' <Color>: The text color
-- 'xAlign' <number>: The x alignment
-- 'yAlign' <number>: The y alignment
-- 'buffere' <number>: The buffer around the text
function draw.CONV_DermaSimpleTextScrollMouse( panel, text, font, x, y, tColor, xAlign, yAlign, buffere )

    if not panel then return end
    if not text then return end

    surface.SetFont( font )

    local tW, tH = surface.GetTextSize( text )
    local px, py = panel:LocalToScreen( buffere, 0 )
    local pw, ph = panel:LocalToScreen( x - buffere, y + tH )
    local x, y = x or 0, y or 0
    local tColor = tColor or color_white
    local buffere = buffere or 5
    local scrollSpeed = scrollSpeed or 50
    local scrollDelay = scrollDelay or 0
    local bounce = bounce or false

    render.SetScissorRect( px, py, pw, ph, true )

    local x1, y1 = x / 2 - tW / 2, y / 2 - tH / 2

    if ( tW > ( x - buffere * 2 ) ) then
        local mx, my = panel:ScreenToLocal( input.GetCursorPos() )
        local diff = tW - x + buffere * 2

        x1 = buffere + math.Remap( math.Clamp( mx, 0, x ), 0, x, 0, -diff )
    end

    draw.SimpleText( text, font, x1, y1, tColor )

    render.SetScissorRect( 0, 0, 0, 0, false )

    return tW, tH
end

-- Draw text with a scrolling effect
-- 'panel' <Panel>: The panel to draw on
-- 'text' <string>: The text to draw
-- 'font' <string>: The font to use
-- 'x' <number>: The x position
-- 'y' <number>: The y position
-- 'tColor' <Color>: The text color
-- 'xAlign' <number>: The x alignment
-- 'yAlign' <number>: The y alignment
-- 'buffere' <number>: The buffer around the text
-- 'scrollSpeed' <number>: The speed of the scrolling
-- 'scrollDelay' <number>: The delay before scrolling starts
-- 'bounce' <boolean>: Whether the text should bounce back when it reaches the end
function draw.CONV_DermaSimpleTextScroll(panel, text, font, x, y, tColor, xAlign, yAlign, buffere, scrollSpeed, scrollDelay, bounce)
    
    if not panel then return end
    if not text then return end

    surface.SetFont( font )

    local tW, tH = surface.GetTextSize( text )
    local px, py = panel:LocalToScreen( buffere, 0 )
    local pw, ph = panel:LocalToScreen( x - buffere, y + tH )
    local x, y = x or 0, y or 0
    local tColor = tColor or color_white
    local buffere = buffere or 5
    local scrollSpeed = scrollSpeed or 50
    local scrollDelay = scrollDelay or 0
    local bounce = bounce or false

    render.SetScissorRect( px, py, pw, ph, true )

    local x1, y1 = x / 2 - tW / 2, y / 2 - tH / 2

    if ( tW > ( x - buffere * 2 ) ) then
        local diff = tW - ( x - buffere * 2 )
        local time = CurTime()
        local delay = scrollDelay or 0
        local scrollRange = diff
        local scrollSpeedVal = scrollSpeed or 50
        
        if bounce then
            -- Bounce effect with delay at both ends
            local bounceDuration = scrollRange / scrollSpeedVal
            local totalBounceTime = bounceDuration * 2 + delay * 2
            local bounceTime = time % totalBounceTime
            
            if bounceTime < delay then
                x1 = buffere
            elseif bounceTime < (delay + bounceDuration) then
                -- Scroll left
                local progress = (bounceTime - delay) / bounceDuration
                x1 = buffere - (progress * scrollRange)
            elseif bounceTime < (delay + bounceDuration + delay) then
                x1 = buffere - scrollRange
            else
                -- Scroll right
                local progress = (bounceTime - (delay + bounceDuration + delay)) / bounceDuration
                x1 = buffere - scrollRange + (progress * scrollRange)
            end
        else
            -- Scroll to the left, with delay before and after scrolling
            local totalScrollTime = scrollRange / scrollSpeedVal
            local cycleTime = delay * 2 + totalScrollTime
            local scrollTime = time % cycleTime

            if scrollTime < delay then
                x1 = buffere
            elseif scrollTime > (delay + totalScrollTime) then
                x1 = buffere - scrollRange
            else
                local progress = scrollTime - delay
                local scrollPos = progress * scrollSpeedVal
                x1 = buffere - scrollPos
            end
        end
    end

    draw.SimpleText( text, font, x1, y1, tColor )

    render.SetScissorRect( 0, 0, 0, 0, false )

    return tW, tH
end
