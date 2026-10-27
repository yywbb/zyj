--
-- Author: songyibo
-- Date: 2018-07-19 14:25:18
--
local TestSpine = class("TestSpine", function ()
    return cc.Layer:create()
end)

function TestSpine:ctor()

    local size = cc.Director:getInstance():getWinSize()
    self.rootNode = cc.Node:create()
    self.rootNode:setPosition(size.width/2,size.height/2)

    self.g1 = CCSkeletonAnimation:create("spine/pangshifu/pangshifu0719.json","spine/pangshifu/pangshifu0719.atlas",1)
    self.g1:setAnimation(0, "stand", true)
    self.rootNode:addChild(self.g1,2) 

    -- self.cl = CCSkeletonAnimation:create("spine/chibang014/chibang014.json","spine/chibang014/chibang014.atlas",1)
    -- self.g1:changeBone(self.cl,"L","L")
    -- self.g1:changeBone(self.cl,"R","R")
    -- self.rootNode:addChild(self.cl,1)

    self:addChild(self.rootNode)
end


function TestSpineMain()
    print("TestSpineMain")
    local scene = cc.Scene:create()
    scene:addChild(TestSpine.new())
    scene:addChild(CreateBackMenuItem())
    return scene
end