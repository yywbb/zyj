--
-- Author: songyibo
-- Date: 2018-06-30 18:27:05
--

local TestThreadScene = class("TestThreadScene", function ()
    return cc.Layer:create()
end)


local scheduler = cc.Director:getInstance():getScheduler()
function TestThreadScene:ctor()

    local index = 0
    local function menuCallback(sender)
	    index = index + 1
	    print("menuCallback",index)
    	
        UIRequest({type = index,param = index,param2 = "我是中文啊啊啊啊",param3 = true, param4 = 1.223,param5 = {a = 1,b = 2}})
    end
    local  item = cc.MenuItemImage:create("HelloWorld.png", "HelloWorld.png")
    item:registerScriptTapHandler(menuCallback)

    local  menu = cc.Menu:create()
    menu:setPosition(cc.p(display.cx,display.cy))
    menu:addChild(item)
    self:addChild(menu)


    local action1 = CCMoveTo:create(2, cc.p(0, 0))
    local action2 = CCCallFunc:create(function (  )
        print("移动完成")
    end)
    
    menu:runAction(CCSpawn:create(action1,action2))
    -- local index = 0
    -- scheduler:scheduleScriptFunc(function (  )
    -- 	index = index + 1
    -- 	UIRequest({type = index,param = index,param2 = "我是中文啊啊啊",param3 = true, param4 = 1.223,param5 = {a = 1,b = 2}})
    -- end, 0, false)

    


end


function TestThreadMain()
    print("TestThreadScene")
    local scene = cc.Scene:create()
    scene:addChild(TestThreadScene.new())
    scene:addChild(CreateBackMenuItem())
    return scene
end