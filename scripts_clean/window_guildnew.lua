--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local guildnew = {
    rootNode = nil,
    rootItems = nil,
}

function guildnew.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui/gonghui_tc_chuangjian", nil, true, "create")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function guildnew.reload(self,data,callback)
    self.callback = callback

    ui.setLabelString(self.rootItems.des,nil,12)
    ui.setLabelString(self.rootItems.gold,nil,21)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("guildnew")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

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
            -- PlaceHolder = "点击输入公会名字",
            PlaceHolder = gameConfig.strings:string_common("popups","enterGuid"),
            length = 12
        })
    self.input:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.createLab,nil,19)
    self.rootItems.createButton:addHandleOfControlEvent(function()
        if inputcontent == "" then
            -- runGamePrompt({msg = "输入公会名字"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","guidName")})
        else
            gameWindows:closeWindowDirect("guildnew")
            UIRequest({type = 2201, name = inputcontent})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.createButton:setSwallowsTouch(true)
    self.rootItems.createButton:setTouchPriority(self.touchPriority)
end

function guildnew.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return guildnew

