--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local kefu = {
    rootNode = nil,
    rootItems = nil,
    input_kefu = nil,
    inputcontent = "",
}

function kefu.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("set/kefu", nil, true, "kefu")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function kefu.reload(self,data,callback)
    self.callback = callback
    --
    self.rootItems.qqLab:setString("")
    self.rootItems.mailLab:setString("")
    if gamedata.device.channel and gamedata.device.channel ~= "" then
        for k,v in pairs(gamedata.config.customer_service) do
             if v.channel == gamedata.device.channel then
                 self.rootItems.qqLab:setString(v.qq)
                 self.rootItems.mailLab:setString(v.email)
             end
        end
    end

    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local Gneral3 = CCSkeletonAnimation:create("hexiangu/hexiangu.json","hexiangu/hexiangu.atlas",1)
    Gneral3:setAnimation("stand",true,0)
    Gneral3:setScale(1.5)
    Gneral3:setScaleX(-1.5)
    Gneral3:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(Gneral3)

    local beginfunc = function(label,box)
        box:setText(label:getString())
        label:setString("")
    end

    local endfunc = function(label,text,box)
        label:setString(text)
        box:setText(" ")
    end

    self.input_kefu = ui.creatInputEditBoxBylable(self.rootItems.inputnode,kEditBoxInputModeAny,beginfunc,endfunc,
        {
            fontSize = 34,
            -- PlaceHolder = "点击输入内容",
            PlaceHolder = gameConfig.strings:string_common("popups","touchPut"),
            length = 100,
            fontColor = ccc3(255,255,255),
            PlaceholderFontColor = ccc3(100,100,100),
        })
    self.input_kefu:setTouchPriority(self.touchPriority)
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("kefu")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.sendLab,nil,19)
    self.rootItems.sendButton:addHandleOfControlEvent(function()
        local text = self.rootItems.inputnode:getString()
        if text and text ~= "" then
            print(text)
            UIRequest({type = 1030, s = text})
        else
            print("input is nil")
            -- runGamePrompt({msg = "请输入内容"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","touchPut")})
        end
        self.rootItems.inputnode:setString("")
    end, CCControlEventTouchUpInside)
    self.rootItems.sendButton:setSwallowsTouch(true)
    self.rootItems.sendButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.cleanLab,nil,19)
    self.rootItems.cleanButton:addHandleOfControlEvent(function()
        self.rootItems.inputnode:setString("")
    end, CCControlEventTouchUpInside)
    self.rootItems.cleanButton:setSwallowsTouch(true)
    self.rootItems.cleanButton:setTouchPriority(self.touchPriority)
end

function kefu.close(self)
    self.input_kefu = nil
    self.inputcontent = ""
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return kefu

