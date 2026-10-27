--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local guildsetname = {
    rootNode = nil,
    rootItems = nil,
}

function guildsetname.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui2/gonghui_tc_gaiming", nil, true, "name")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function guildsetname.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guildsetname")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.noLab,nil,19)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("guildsetname")
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
            -- PlaceHolder = "点击输入",
            PlaceHolder = gameConfig.strings:string_common("popups","put_wd"),
            length = 12
        })
    self.input:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.yesLab,nil,19)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        if inputcontent == "" then
            -- runGamePrompt({msg = "请输入内容"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","plcontext")})
        else
            gameWindows:closeWindowDirect("guildsetname")
            UIRequest({type = 2259, text = inputcontent})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

end

function guildsetname.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return guildsetname

