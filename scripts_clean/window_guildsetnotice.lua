--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local guildsetnotice = {
    rootNode = nil,
    rootItems = nil,
}

function guildsetnotice.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui/gonghui_tc_gonggao", nil, true, "notice")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function guildsetnotice.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guildsetnotice")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.noLab,nil,19)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("guildsetnotice")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)


    local inputcontent = ""
    local beginFunc = function()
        inputcontent = ""
    end

    local endFunc = function(text)
        inputcontent = text
    end

    self.input = ui.creatInputEditBoxByNode(self.rootItems.inputnode, kEditBoxInputModeAny, beginFunc, endFunc,
        {
            fontSize = 40,
            -- PlaceHolder = "点击输入公告",
            PlaceHolder = gameConfig.strings:string_common("popups","putaccount"),
            length = 50
        })
    self.input:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.yesLab,nil,19)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        if inputcontent == "" then
            -- runGamePrompt({msg = "请输入公告"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","entAccount")})
        else
            gameWindows:closeWindowDirect("guildsetnotice")
            UIRequest({type = 2211, announcement = inputcontent})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

end

function guildsetnotice.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return guildsetnotice

