

--overwrite ui functions


function myGetupvalue( func,name )
	local i = 1
	while true do
       local n, v = debug.getupvalue(func, i)
       if not n then break end
       if n == name then return v end
       i = i + 1
    end
end

local uiExtFunc = {}

local strokeparams = myGetupvalue(ui.setStringWithStroke, "strokeparams")
local shadowparams = myGetupvalue(ui.setStringWithShadow, "shadowparams")

-- 描边方法重写
function uiExtFunc.setStringWithShadow(label,str,paramindex)
    if str then
        label:setString(str)
    end
    paramindex = paramindex or 1
     -- Color4B , offset = Size(2,-2), blurRadius   颜色默认是黑色
    label:enableShadow(cc.c4b(0,0,0,shadowparams[paramindex].o),cc.size(0,0),shadowparams[paramindex].blur)
end
ui.setStringWithShadow = uiExtFunc.setStringWithShadow


function uiExtFunc.setStringWithStroke(label,str,paramindex)
    paramindex = paramindex or 1
    if paramindex > table.getTableLength(strokeparams) then
        paramindex = 1
    end
    local string = str or label:getString()
    label:setString(string)
    local c4b = cc.c4b(strokeparams[paramindex].color.r,strokeparams[paramindex].color.g,strokeparams[paramindex].color.b,255)
    label:enableOutline(c4b,strokeparams[paramindex].size)
end
ui.setStringWithStroke = uiExtFunc.setStringWithStroke


function uiExtFunc.setStringWithStrokeAndShadow(label,str,strockparam,shadowparam)
    ui.setStringWithStroke(label,str,strockparam,shadowparam)
    ui.setStringWithShadow(label,str,shadowparam)
end
ui.setStringWithStrokeAndShadow = uiExtFunc.setStringWithStrokeAndShadow


-- 精灵切割重写
function uiExtFunc.setSpriteTextureRect(sprite,originX,originY,width,height)
    local isrotated = sprite:isTextureRectRotated()

    local originx = sprite:getTextureRect().x + originX
    local originy = sprite:getTextureRect().y + originY
    local w = math.min(width,sprite:getTextureRect().width)
    local h = math.min(height,sprite:getTextureRect().height)

    sprite:setTextureRect(CCRectMake(originx,originy,w,h),isrotated,CCSizeMake(w,h))
end
ui.setSpriteTextureRect = uiExtFunc.setSpriteTextureRect


function uiExtFunc.setSpriteTextureRect2(sprite,originX,originY,width,height)
    local isrotated = sprite:isTextureRectRotated()

    local originx = sprite:getTextureRect().x + originX
    local originy = sprite:getTextureRect().y + originY

    sprite:setTextureRect(CCRectMake(originx,originy,width,height),isrotated,CCSizeMake(width,height))
end
ui.setSpriteTextureRect2 = uiExtFunc.setSpriteTextureRect2


--文本创建方法重写
function uiExtFunc.createLabel(args)
    args = args or {
        text = "",
        color = ui.whiteColor,
        fontsize = 30,
        font = "Helvetica-Bold",
        x = 0,
        y = 0,
        ax = 0.5,
        ay = 0.5,
        dw = 0,
        dh = 0,
        hAlignment = kCCTextAlignmentLeft,
        vAlignment = kCCVerticalTextAlignmentTop
    }

    local label = cc.Label:createWithTTF(args.text or "",gamedata.gameconfig.sysFontName, args.fontsize or 30
        , CCSizeMake(args.dw or 0, args.dh or 0), args.hAlignment or kCCTextAlignmentLeft, args.vAlignment or kCCVerticalTextAlignmentTop)
    label:setFontName(gamedata.gameconfig.sysFontName)
    label:setFontSize(args.fontsize or 30)

    label:setColor(args.color or ui.whiteColor)
    label:setAnchorPoint(ccp(args.ax or 0.5, args.ay or 0.5))
    label:setPosition(ccp(args.x or 0, args.y or 0))
    label:setScale(1)
    return label
end

ui.createLabel = uiExtFunc.createLabel