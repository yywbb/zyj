--
-- Author: songyibo
-- Date: 2018-08-08 16:40:22
--
local TestTouch = class("TestTouch", function ()
    return cc.Layer:create()
end)

function TestTouch:ctor()
    local size = cc.Director:getInstance():getWinSize()

	self.rootNode,self.rootItems = CCBReaderLoad("ccb/touch", nil, true, "touch")
    self:addChild(self.rootNode,10)


    self.rootItems.click1:setSwallowsTouch(true)
    self.rootItems.click1:setTouchPriority(-160)
    self.rootItems.click1:addHandleOfControlEvent(function()
    	print("click -> 1")
    end, CCControlEventTouchUpInside)

    -- local cb = function ( )
    -- 	print("回调")
    -- end
    ui.addProflayer(self.rootItems.snode,-150,0,ccc4(0,0,0,100),nil,nil,nil,cb,"gameWindowsprof")


    self.rootItems.click2:setSwallowsTouch(false)
    self.rootItems.click2:setTouchPriority(-200)
    self.rootItems.click2:addHandleOfControlEvent(function()
    	print("click -> 2")
    end, CCControlEventTouchUpInside)




end


function TestTouchMain()
    print("TestTouchMain")
    local scene = cc.Scene:create()
    scene:addChild(TestTouch.new())
    scene:addChild(CreateBackMenuItem())
    return scene
end