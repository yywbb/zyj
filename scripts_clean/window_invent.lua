--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午5:16
-- To change this template use File | Settings | File Templates.
--

local invent = {
    rootNode = nil,
    rootItems = nil,
}

function invent.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_yaoqinghaoyou", nil, true, "tc_yaoqinghaoyou")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function invent.reload(self,data,callback)
    self.callback = callback
    self.data = data

    local inputcontent = ""
    local beginFunc = function()
        inputcontent = ""
    end

    local endFunc = function(text)
        inputcontent = text
    end

    self.input = ui.creatInputEditBoxByNode(self.rootItems.inputnode, kEditBoxInputModeAny, beginFunc, endFunc,
        {
            fontSize = 46,
            -- PlaceHolder = "点击输入邀请码",
            PlaceHolder = gameConfig.strings:string_common("popups","enterInvite"),
            length = 20,
            nochecksensitive = true
        })
    self.input:setTouchPriority(self.touchPriority)


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("invent")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.confirmtext,"确 定",18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        if inputcontent == "" or inputcontent == self.data.code then
            -- runGamePrompt({msg = "请输入对方的邀请码"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","otherInvite")})
        else
            gameWindows:closeWindow("invent")
            UIRequest({type = 2081, code = inputcontent})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.conceltext,"返 回",18)
    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","fanhui"),18)
    self.rootItems.concel:addHandleOfControlEvent(function()
        gameWindows:closeWindow("invent")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)
end

function invent.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.input then
        --ui.removeInputEditBox(self.input)
        self.input = nil
    end

    if self.callback then
        self.callback()
    end
end

return invent