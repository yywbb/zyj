--
-- Author: songyibo
-- Date: 2018-08-02 10:48:43
--

local TestShader = class("TestShader", function ()
    return cc.Layer:create()
end)


function TestShader:ctor()
    -- self.rootNode,self.rootItems = CCBReaderLoad("ccb/test", nil, true, "test")
    -- self:addChild(self.rootNode)

    -- dump(self.rootItems,"rootItems")


    --self.rootItems.click:setSwallowsTouch(true)
    --self.rootItems.click:setTouchPriority(-100)
    -- self.isgray = false
    -- self.rootItems.click:addHandleOfControlEvent(function()
    -- 	print("click")
    -- 	if self.isgray then
    -- 		self:removegray()
    -- 	else
    -- 		self:addgray()
    -- 	end

    --     for i=1,2 do
    --         if self.rounditem["damagelabel"..i] then
    --             self.rounditem["damagelabel"..i]:setString(math.abs("1223432423"))
    --         end
    --     end

    --     self.rounditem["mAnimationManager"]:runAnimationsForSequenceNamed("tianwangshualong_screen")
    -- end, CCControlEventTouchUpInside)

    -- self.rootItems.helloLabel:setString("abcdefg")
    -- self.rootItems.helloLabel:setFontName("JCuYuan.ttf")

    self.roundccb,self.rounditem = CCBReaderLoad("MainScene/main", nil, true, "main")
    self:addChild(self.roundccb)
    --self.roundccb:setPosition(ccp(540,540))
end


function TestShader:addgray()
	self.isgray = true

	ui.addGray("CCSprite",self.rootItems.sp)
    ui.addGray("CCLabelTTF",self.rootItems.helloLabel)
    ui.addGray("CCLabelBMFont",self.rootItems.bmlabel)
	ui.addGray("CCControlButton",self.rootItems.click)
end

function TestShader:removegray()
	self.isgray = false
	ui.removeGray("CCSprite",self.rootItems.sp)
    ui.addGray("CCLabelTTF",self.rootItems.helloLabel)
    ui.removeGray("CCLabelBMFont",self.rootItems.bmlabel)
	ui.removeGray("CCControlButton",self.rootItems.click)
	
end


function TestShaderMain()
    print("TestShader")
    local scene = cc.Scene:create()
    scene:addChild(TestShader.new())
    scene:addChild(CreateBackMenuItem())
    return scene
end
