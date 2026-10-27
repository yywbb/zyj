--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/18
-- Time: 下午4:29
-- To change this template use File | Settings | File Templates.
--

local useropt = {
    rootNode = nil,
    rootItems = nil,

    input = nil,
}

function useropt.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    if data.type == "rename" then
        self.rootNode, self.rootItems = CCBReaderLoad("windows/rename", nil, true, "rename")
        self:reloadRename(data,callback)
    elseif data.type == "massage" then
        self.rootNode, self.rootItems = CCBReaderLoad("windows/sendmessage", nil, true, "sendmessage")
        self:reloadMessage(data,callback)
    end

    self.root:addChild(self.rootNode)
    return self.root
end

function useropt.reloadRename(self,data,callback)
    self.callback = callback

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
	        -- PlaceHolder = "点击输入新名字名字最多6字",
	        PlaceHolder = gameConfig.strings:string_common("popups","shurumingzi"),
	        length = 12,
	        extSensitiveWord = gameConfig.strings.sensitiveWordForSetName,
	    })
	self.input:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("useropt")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.confirmtext,"确 定",18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        if inputcontent == "" then
            -- runGamePrompt({msg = "请输入新昵称"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","shuruxinni")})
        else
            UIRequest({type = 101, name = inputcontent,isrename = true})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)
end

function useropt.reloadMessage(self,data,callback)

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
            -- PlaceHolder = "点击输入留言，最多20字",
            PlaceHolder = gameConfig.strings:string_common("popups","shuruliuyan"),
            length = 40
        })
    self.input:setTouchPriority(self.touchPriority)


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("useropt")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.confirmtext,"确 定",18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        if inputcontent == "" then
            -- runGamePrompt({msg = "请输入留言"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","shuruly")})
        else
            gameWindows:closeWindow("useropt")
            UIRequest({type = 3103, content = inputcontent,target = data.rid})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.conceltext,"返 回",18)
    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","fanhui"),18)
    self.rootItems.concel:addHandleOfControlEvent(function()
        gameWindows:closeWindow("useropt")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)
end

function useropt.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
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

return useropt
