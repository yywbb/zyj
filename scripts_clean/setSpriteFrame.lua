--
-- 设置帧的相关方法
-- User: liliang
-- Date: 13-6-4
-- Time: 下午5:53
-- Todo change global function to ui module.
--

--设置精灵的图片帧
function setSpriteFrameByName(sprite, frameName, dirname)
    --cclog("setSpriteFrameByName %s",frameName);

--    if string.find(frameName,".png") == nil then
--        frameName = frameName..".png"
--    end
--
--    local frameIncache = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(frameName)
--
--    if not frameIncache then
--        local spritetemp = CCSprite:create("public/icons/"..frameName) or CCSprite:create("public/publicsprite/"..frameName)
--        if spritetemp then
--            --cclog("using spritetemp %s ",frameName);
--            frameIncache = spritetemp:displayFrame()
--            frameIncache:retain()
--            CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFrame(frameIncache,frameName)
--        else
--            cclog("no souch frame in setSpriteFrameByName %s ",frameName);
--            frameIncache = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(gameConfig.images.alpha)
--        end
--    end
--    sprite:setDisplayFrame(frameIncache)

    sprite:setDisplayFrame(ui.itemcache:getSpriteFrame(frameName,dirname))
end

--根据状态设置ControlButton的图片帧
--state<CCControlStateNormal,CCControlStateHighlighted,CCControlStateDisabled>
function setControlButtonFrameByName(button, frameName, state)
    if string.find(frameName,".png") == nil then
        frameName = frameName..".png"
    end
	button:setBackgroundSpriteFrameForState(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(frameName), state)
end

function setControlButtonFrame(button, frameName,frameName2,frameName3)

    local framesnames = {}
    local frames  = {}
    if frameName and string.find(frameName,".png") == nil then
        framesnames[1] = frameName..".png"
    end
    if frameName2 and string.find(frameName2,".png") == nil then
        framesnames[2] = frameName2..".png"
    end
    if frameName3 and string.find(frameName3,".png") == nil then
        framesnames[3] = frameName3..".png"
    end

    for k,v in ipairs(framesnames) do
        local frameIncache = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(v)

        if not frameIncache then
            local spritetemp = CCSprite:create("public/icons/"..v) or CCSprite:create("public/publicsprite/"..v) or CCSprite:create("public/language/"..v)
            if spritetemp then
                --cclog("using spritetemp %s ",frameName);
                CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFrame(spritetemp:displayFrame(),v)
                frameIncache = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(v)
            else
                cclog("no souch frame in setSpriteFrameByName %s ",v);
                frameIncache = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(gameConfig.images.alpha)
            end
        end
        frames[k] = frameIncache
    end

	button:setBackgroundSpriteFrameForState(frames[1], CCControlStateNormal)
	button:setBackgroundSpriteFrameForState(frames[2] or frames[1], CCControlStateHighlighted)
	button:setBackgroundSpriteFrameForState(frames[3] or frames[1], CCControlStateDisabled)
end

--
function setControlButtonSpriteByName(button, scaleSprite, state)
	button:setBackgroundSpriteForState(scaleSprite, state)
end

--设置按钮颜色
function setControlButtonTitleColorForState(button, color, state)
    button:setTitleColorForState(color, state)
end

function setControlButtonTitleColor(button, color)
    button:setTitleColorForState(color, CCControlStateNormal)
    button:setTitleColorForState(color, CCControlStateHighlighted)
    button:setTitleColorForState(color, CCControlStateDisabled)
end

--设置按钮标题
function setControlButtonTitleForState(button, title, state)
	button:setTitleForState(CCString:create(title), state)
end

function setControlButtonTitle(button, title)
    button:setTitleForState(CCString:create(title), CCControlStateNormal)
    button:setTitleForState(CCString:create(title), CCControlStateHighlighted)
    button:setTitleForState(CCString:create(title), CCControlStateDisabled)
end

--设置CCMenuItem显示的帧
function setCCMenuItemFrameByName(item, frameName)
    if string.find(frameName,".png") == nil then
        frameName = frameName..".png"
    end
	item:setNormalSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(frameName))
end

--CCScale9Sprite
function setScaleSpriteFrameByName(sprite, frameName)
    if string.find(frameName,".png") == nil then
        frameName = frameName..".png"
    end
	sprite:setSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(frameName))
end