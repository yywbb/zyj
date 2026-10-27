--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/10/9
-- Time: 10:33
-- To change this template use File | Settings | File Templates.
--

local playerreturncdk = {
    rootNode = nil,
    rootItems = nil,
    input_cdk = nil,
    inputcontent = "",
}

function playerreturncdk.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityplayerreturn/duihuan", nil, true, "playerreturncdk")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function playerreturncdk.reload(self,data,callback)
    self.callback = callback
    --
    local beginFunc = function()
        self.inputcontent = ""
    end

    local endFunc = function(text)
        self.inputcontent = text
    end
    --
    self.input_cdk = ui.creatInputEditBoxByNode(self.rootItems.inputnode, kEditBoxInputModeAny, beginFunc, endFunc,
        {
            fontSize = 34,
            -- PlaceHolder = "点击输入",
            PlaceHolder = gameConfig.strings:string_common("popups","put_wd"),
            length = 20,
            fontColor = ccc3(255,255,255),
            PlaceholderFontColor = ccc3(100,100,100),
            nochecksensitive = true
        }
    )
    self.input_cdk:setTouchPriority(self.touchPriority)

    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("playerreturncdk")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        if self.input_cdk:getText() and self.input_cdk:getText() ~= "" then
            print(self.input_cdk:getText())

            local cdkok = true
            local cdkstr = self.input_cdk:getText()
            for i=1,#cdkstr do
                local curByte = string.byte(cdkstr, i)
                if curByte < 33 or curByte > 127 then
                    cdkok = false
                end
            end

            if cdkok and #cdkstr <= 20 then

                UIRequest({type = 3774, code = self.input_cdk:getText()})

            else
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","playerrecall",8)})
            end
        else
            print("input is nil")
            -- runGamePrompt({msg = "请输入召回码"})
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","playerrecall",7)})
        end
        self.inputcontent = ""
        self.input_cdk:setText("")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
end

function playerreturncdk.close(self)
    self.input_cdk = nil
    self.inputcontent = ""
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return playerreturncdk

