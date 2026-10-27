--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/23
-- Time: 下午5:10
-- To change this template use File | Settings | File Templates.
--

local skeletonShenqi = {

    root = nil,
    g1 = nil,
    cl = nil,
}

skeletonShenqi.__index = skeletonShenqi

function skeletonShenqi:init(config,level)

    local self = {___xxx = 222 }
    setmetatable(self, skeletonShenqi)

    self.root = CCNode:create()
    self.animationnode = CCNode:create()
    self.root:addChild(self.animationnode)

    local name = config.animation

    self.g1 = CCSkeletonAnimation:create(name.."/"..name..".json",name.."/"..name..".atlas",1)
    self.root:addChild(self.g1)

    level = level or 0

    local showlevel = math.floor(level/8)+1
    showlevel = math.min(showlevel,6)

    if config.show and config.show == 1 and showlevel>0 then
        local effname = name.."_"..showlevel
        self.cl = CCSkeletonAnimation:create(effname.."/"..effname..".json",effname.."/"..effname..".atlas",1)
        self.g1:changeBone(self.cl,"l_root","l_root")
        self.root:addChild(self.cl)    
    end

    return self
end

function skeletonShenqi:create() end
function skeletonShenqi:changeBone() end

function skeletonShenqi:setAnimation(animation,isloop,stateIndex)
    self.g1:setAnimation(animation,isloop,stateIndex)
    if not self.cl then return end

    self.cl:setAnimation(animation,isloop,stateIndex)
end

function skeletonShenqi:addAnimation(animation,isloop,stateIndex,delay)
    self.g1:addAnimation(animation,isloop,stateIndex,delay)
    if not self.cl then return end
    self.cl:addAnimation(animation,isloop,stateIndex,delay)
end

function skeletonShenqi:setPosition(x,y)
    self.root:setPosition(x,y)
end

function skeletonShenqi:setScaleX(scalex)
    self.root:setScaleX(scalex)
end

function skeletonShenqi:setScale(scale)
    self.root:setScale(scale)
end

function skeletonShenqi:getScaleX()
    return self.root:getScaleX()
end

function skeletonShenqi:getParent()
    return self.root:getParent()
end

function skeletonShenqi:runAction(action)
    self.root:runAction(action)
end

function skeletonShenqi:retain()
    self.root:retain()
end
function skeletonShenqi:release()
    self.root:release()
end
function skeletonShenqi:removeFromParentAndCleanup(bool)
    self.root:removeFromParentAndCleanup(bool)
end

return skeletonShenqi

