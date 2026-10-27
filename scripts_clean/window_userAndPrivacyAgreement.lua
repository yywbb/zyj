local userAndPrivacyAgreement = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    page = "",

    userAgreementText = "",
    privacyAgreementText = "",

    pageconfig = {},
}

function userAndPrivacyAgreement.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.root
end

function userAndPrivacyAgreement.reload( self,data,callback )
    self.callback = callback
    self.root:removeAllChildrenWithCleanup(true)
    self.rootNode, self.rootItems = CCBReaderLoad("MainScene/tc_usersagreement", nil, true, "userAndPrivacyAgreement")
    self.root:addChild(self.rootNode)

    ui.setLabelString(self.rootItems.exitlab,nil,18)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        if data.window then
            gameWindows:closeWindow("userAndPrivacyAgreement")
        else
            gameWindowslogin:closeWindow("userAndPrivacyAgreement")
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.exitbutton:setSwallowsTouch(true)
    self.rootItems.exitbutton:setTouchPriority(self.touchPriority)
    self.rootItems.exitbutton:addHandleOfControlEvent(function()
        if data.window then
            gameWindows:closeWindow("userAndPrivacyAgreement")
        else
            gameWindowslogin:closeWindow("userAndPrivacyAgreement")
        end
    end, CCControlEventTouchUpInside)
    
    if data.type == 1 then
        self.rootItems.titleTxt:setString("隐私协议")
        if self.privacyAgreementText == "" then
            local TextOfUserAgreement = require"TextOfUserAgreement"
            self.privacyAgreementText = string.split(TextOfUserAgreement.privacyAgreement,"\n")
        end
        self:userAgreementReload(self.privacyAgreementText)
    elseif data.type == 0 then
        self.rootItems.titleTxt:setString("用户注册服务协议")
        if self.userAgreementText == "" then
            local TextOfUserAgreement = require"TextOfUserAgreement"
            self.userAgreementText = string.split(TextOfUserAgreement.userAgreement,"\n")
        end    
        self:userAgreementReload(self.userAgreementText)
    end
end

function userAndPrivacyAgreement.userAgreementReload( self , tb )
    local scrollview = ccui.ScrollView:create()
    scrollview:setAnchorPoint(ccp(0.5,1))
    scrollview:setPosition(542,1053)
    scrollview:setBounceEnabled(true)
    scrollview:setDirection(SCROLLVIEW_DIR_VERTICAL)
    scrollview:setScrollBarWidth(10)
    scrollview:setScrollBarColor(ccc3(0, 0, 0))
    self.rootNode:addChild(scrollview)
    scrollview:setContentSize(cc.size(950,1040))
    scrollview:setTouchPriority(self.touchPriority)
    self.rootItems.tempNode:removeAllChildrenWithCleanup(ture)

    local labelNode = cc.Node:create()
    scrollview:addChild(labelNode)
    local i = 1
    local fixedH = 0
    local posY = 1040
    local str = ""

    timer_ = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        while true do
            i = i + 1
            str = str..tb[i].."\n"
            if i % 20 == 0 or i == #tb then
                local label = ui.createLabel()
                label:setColor(ccc3(178, 115, 59))
                label:setAnchorPoint(ccp(0,1))
                label:setPositionY(posY)
                labelNode:addChild(label)
                label:setFontSize(32)
                label:setString(str)
                label:setWidth(950)
                fixedH = fixedH + label:getContentSize().height + label:getLineSpacing()
                posY = 1040 - fixedH
                str = ""
                break
            end
        end
        if i == #tb then
            print("longlabel",os.clock())
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(timer_)
            scrollview:setInnerContainerSize(cc.size(950,fixedH))
            labelNode:setPositionY(fixedH - 1040)
        end
    end, 0, false)
end

function userAndPrivacyAgreement.close(self)
    self.page = ""
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(timer_)

    if self.callback then
        self.callback()
    end
end

return userAndPrivacyAgreement