local userAgreement = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    page = "",

    pageconfig = {},
}

function userAgreement.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.root
end

function userAgreement.reload( self,data,callback )
    self.callback = callback
    self.root:removeAllChildrenWithCleanup(true)
    self.rootNode, self.rootItems = CCBReaderLoad("MainScene/tc_usersaAreementPop", nil, true, "userAgreement")
    local textRootNode,textRootItems = CCBReaderLoad("MainScene/tc_usersagreementtext", nil, true, "userAgreementText")
    print("ccb loading complate",self.rootNode,self.rootItems)
    self.root:addChild(self.rootNode)

    ui.setLabelString(self.rootItems.agreelab,"同意",19)
    self.rootItems.agreebutton:setSwallowsTouch(true)
    self.rootItems.agreebutton:setTouchPriority(self.touchPriority)
    self.rootItems.agreebutton:addHandleOfControlEvent(function()

        if not self.rootItems.yessprite:isVisible() then
            runGamePrompt({msg = "请查看并同意《用户协议》与《隐私政策》"})
            return
        else
            gameWindowslogin:closeWindow("userAgreement")
            CCUserDefault:sharedUserDefault():setStringForKey("userAgreement","true")
            LoginScene:reloadUserAgreement()
            if (string.find(gamedata.device.channel,"qipax7IosZYJFS")~=nil or string.find(gamedata.device.channel,"qipafsx7AndroidZYJFS")~=nil) then
                if gamedata.sdk.channel.loginId ~= nil then
                    return
                end    
            end    
            gamedata.sdk.channel:Login()
        end    
       
    end, CCControlEventTouchUpInside)


    ui.setLabelString(self.rootItems.refuselab,"拒绝",19)
    self.rootItems.refusebutton:setSwallowsTouch(true)
    self.rootItems.refusebutton:setTouchPriority(self.touchPriority)
    self.rootItems.refusebutton:addHandleOfControlEvent(function()

        cclog("refusebutton.exitGame %s ",platform)
        local luaj = require"luaj"
        local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
        local javaMethodName = "exitGame"
        local javaMethodSig = "()V"
        luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig);


    end, CCControlEventTouchUpInside)



    self.rootItems.userAgreementBtn:setSwallowsTouch(true)
    self.rootItems.userAgreementBtn:setTouchPriority(self.touchPriority)
    self.rootItems.userAgreementBtn:addHandleOfControlEvent(function()
        gameWindowslogin:openWindow("userAndPrivacyAgreement",{type = 0},function()end)
    end, CCControlEventTouchUpInside)

    self.rootItems.privacyAgreementBtn:setSwallowsTouch(true)
    self.rootItems.privacyAgreementBtn:setTouchPriority(self.touchPriority)
    self.rootItems.privacyAgreementBtn:addHandleOfControlEvent(function()
        gameWindowslogin:openWindow("userAndPrivacyAgreement",{type = 1},function()end)
    end, CCControlEventTouchUpInside)


    self.rootItems.userAgreementBtn2:setSwallowsTouch(true)
    self.rootItems.userAgreementBtn2:setTouchPriority(self.touchPriority)
    self.rootItems.userAgreementBtn2:addHandleOfControlEvent(function()
        gameWindowslogin:openWindow("userAndPrivacyAgreement",{type = 0},function()end)
    end, CCControlEventTouchUpInside)
    self.rootItems.privacyAgreementBtn2:setSwallowsTouch(true)
    self.rootItems.privacyAgreementBtn2:setTouchPriority(self.touchPriority)
    self.rootItems.privacyAgreementBtn2:addHandleOfControlEvent(function()
        gameWindowslogin:openWindow("userAndPrivacyAgreement",{type = 1},function()end)
    end, CCControlEventTouchUpInside)
    


    local _str = CCUserDefault:sharedUserDefault():getStringForKey("isfirstAgreementUnselect")
    if CCUserDefault:sharedUserDefault():getStringForKey("userAgreement") ~= "true" then
        self.rootItems.yessprite:setVisible(false)
    else
        if _str ~= "true" then
            print("没有勾选之前，都不可见")
            self.rootItems.yessprite:setVisible(false)
        else
            self.rootItems.yessprite:setVisible(true)
        end    
    end
    self.rootItems.yesBtn:setSwallowsTouch(true)
    self.rootItems.yesBtn:setTouchPriority(self.touchPriority)
    self.rootItems.yesBtn:addHandleOfControlEvent(function()
        local _str = CCUserDefault:sharedUserDefault():getStringForKey("isfirstAgreementUnselect")
        if _str ~= "true" then
            print("没有勾选之前，直接选择勾选")
            CCUserDefault:sharedUserDefault():setStringForKey("isfirstAgreementUnselect","true")
            self.rootItems.yessprite:setVisible(true)
            self:reloadUserAgreement()
        else
            print("勾选之后，直接取消勾选")
            CCUserDefault:sharedUserDefault():setStringForKey("isfirstAgreementUnselect","false")
            self.rootItems.yessprite:setVisible(false)
            self:reloadUserAgreement()
        end    

    end, CCControlEventTouchUpInside)



end

function userAgreement.close(self)
    self.page = ""
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return userAgreement