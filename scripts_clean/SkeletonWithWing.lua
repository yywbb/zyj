--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/23
-- Time: 下午5:10
-- To change this template use File | Settings | File Templates.
--

local skeletonwithwings = {

    root = nil,
    g1 = nil,
    cl = nil,
}

skeletonwithwings.__index = skeletonwithwings

function skeletonwithwings:init(skleton,name,wing)

    local self = {___xxx = 222 }
    setmetatable(self, skeletonwithwings)

    self.root = CCNode:create()
    self.animationnode = CCNode:create()
    self.root:addChild(self.animationnode)
    self.wing = wing or {}

    self.g1 = skleton

    if self.wing.level and self.wing.level>0 then
        local wingname = "chibang0"..(self.wing.level)..((self.wing.color and self.wing.color>=1) and "_0"..self.wing.color or "")
        if wingname.."/"..wingname..".json" ~= CCFileUtils:sharedFileUtils():fullPathForFilename(wingname.."/"..wingname..".json") then
            self.cl = CCSkeletonAnimation:create(wingname.."/"..wingname..".json",wingname.."/"..wingname..".atlas",1)
            self.g1:changeBone(self.cl,"L","L")
            self.g1:changeBone(self.cl,"R","R")
            self.root:addChild(self.cl)
        end
    end

    self.root:addChild(self.g1)

    if not self.json then
        local path = CCFileUtils:sharedFileUtils():fullPathForFilename(name .. "/" .. name .. "_time.json")
        self.json = LoadJsonFileToTable(path)
    end


    return self
end

function skeletonwithwings:create() end
function skeletonwithwings:changeBone() end

function skeletonwithwings:checkwing(wing)
   if not wing or not wing.level then return false end
   if self.wing.level ~= wing.level then return true end

   local s_wingcolor = self.wing.color or 0
   local e_wingcolor = wing.color or 0
   if s_wingcolor ~= e_wingcolor then return true end
   return false
end

function skeletonwithwings:setAnimation(animation,isloop,stateIndex)
    self.g1:setAnimation(animation,isloop,stateIndex)
    if not self.cl then return end

    self.hiding = false
    if animation == "skill01_01" then
        if self.json.skill01.hide then
            self.cl:setAnimation("yin",false,0)
        end
    elseif animation == "skill01_02" then

    elseif animation == "skill01_03" then
        if self.json.skill01.hide then
            self.cl:setAnimation("chu",false,0)
        end
    elseif animation == "skill02" then
        if self.json.skill02.hide then
            self.hiding = true
            self.cl:setAnimation("yin",false,0)
            self.animationnode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(self.json.skill02.actiondelay-0.3), CCCallFunc:create(function()
                self.cl:setAnimation("chu",false,0)
                self.cl:addAnimation("stand",true,0,0)
                self.hiding = false
            end)))
        end
    else

        self.cl:setAnimation("stand",isloop,stateIndex)
       -- self.cr:setAnimation("animation",isloop,stateIndex)
    end

end

function skeletonwithwings:addAnimation(animation,isloop,stateIndex,delay)
    self.g1:addAnimation(animation,isloop,stateIndex,delay)
    if not self.cl then return end
    if not self.hiding then
        self.cl:addAnimation("stand",isloop,stateIndex,delay)
    end
end

function skeletonwithwings:setPosition(x,y)
    self.root:setPosition(x,y)
end

function skeletonwithwings:setScaleX(scalex)
    self.root:setScaleX(scalex)
end

function skeletonwithwings:setScale(scale)
    self.root:setScale(scale)
end

function skeletonwithwings:getScaleX()
    return self.root:getScaleX()
end

function skeletonwithwings:getParent()
    return self.root:getParent()
end

function skeletonwithwings:runAction(action)
    self.root:runAction(action)
end

function skeletonwithwings:retain()
    self.root:retain()
end
function skeletonwithwings:release()
    self.root:release()
end
function skeletonwithwings:removeFromParentAndCleanup(bool)
    self.root:removeFromParentAndCleanup(bool)
end

return skeletonwithwings

