--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local cdkey = {
    rootNode = nil,
    rootItems = nil,
    input_cdk = nil,
    inputcontent = "",
}

function cdkey.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("set/duihuan", nil, true, "cdk")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function cdkey.reload(self,data,callback)
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
        gameWindows:closeWindow("cdkey")
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

                --拇指玩的需要
                local device = require"device"
                if device.channel == "mzw" then
                    --兑换礼包
                    sdk:PostGift(self.input_cdk:getText())
                end

                UIRequest({type = 2089, s = self.input_cdk:getText()})

            else
                runGamePrompt({msg = "请输入有效的兑换码"})
            end
        else
            print("input is nil")
            -- runGamePrompt({msg = "请输入兑换码"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","et_wd")})
        end
        self.inputcontent = ""
        self.input_cdk:setText("")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
end

function cdkey.close(self)
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

return cdkey

