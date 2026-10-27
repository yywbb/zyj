--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local shiming = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    page = "",

    pageconfig = {
        renzheng2 = "MainScene/tc_shimingrenzheng2",
        tishi = "MainScene/tc_fangchenmitishi5",
        tishi3 = "MainScene/tc_fangchenmitishi4",
    },
}

function shiming.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority


    self:reload(data,callback)
    return self.root
end

function shiming.reload( self,data,callback )
    self.callback = callback
    self:shiftpage(data,callback)
end

function shiming.shiftpage( self,data,callback )
    if data.page ~= self.page then
        self.root:removeAllChildrenWithCleanup(true)
        self.rootNode, self.rootItems = CCBReaderLoad(self.pageconfig[data.page], nil, true, "shiming")
        self.root:addChild(self.rootNode)
    end

    self.page = data.page
    self:reloaddata(data,callback)
end

function shiming.reloaddata( self,data,callback )
    self.data = data.data or self.data

    if self.page == "renzheng2" then
        self:reloadrenzhneg2(data,callback)
    elseif self.page == "tishi3" then
        self:reloadtishi3(data,callback)
    elseif self.page == "tishi" then
        self:reloadtishi(data,callback)
    end

end

function shiming.reloadrenzhneg2( self,data,callback )
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindowslogin:closeWindow("shiming")
         loading:exit()
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.passlab,"下次再说",19)
    self.rootItems.passbutton:setSwallowsTouch(true)
    self.rootItems.passbutton:setTouchPriority(self.touchPriority)
    self.rootItems.passbutton:addHandleOfControlEvent(function()
        gameWindowslogin:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.renzhenglab,"前往认证",19)
    self.rootItems.renzhengbutton:setSwallowsTouch(true)
    self.rootItems.renzhengbutton:setTouchPriority(self.touchPriority)
    self.rootItems.renzhengbutton:addHandleOfControlEvent(function()
        gameWindowslogin:closeWindow("shiming")
        if gamedata.sdk:isValid() and gamedata.sdk.toIDCard then
            gamedata.sdk:toIDCard()
        end
    end, CCControlEventTouchUpInside)

    -- self.rootItems.timedes:setString("您的账号当天已经超出所规定的游玩时间，还请您第二天早上8点后登陆游戏")
end

function shiming.reloadtishi3( self,data,callback )

    ui.setLabelString(self.rootItems.tipconfirmlab,"确定",19)
    self.rootItems.tipconfirmbutton:setSwallowsTouch(true)
    self.rootItems.tipconfirmbutton:setTouchPriority(self.touchPriority)
    self.rootItems.tipconfirmbutton:addHandleOfControlEvent(function()
        gameWindowslogin:closeWindow("shiming")
         loading:exit()
    end, CCControlEventTouchUpInside)

    -- self.rootItems.des:setString(data.des)
end

function shiming.reloadtishi( self,data,callback )

    ui.setLabelString(self.rootItems.tipconfirmlab,"确定",19)
    self.rootItems.tipconfirmbutton:setSwallowsTouch(true)
    self.rootItems.tipconfirmbutton:setTouchPriority(self.touchPriority)
    self.rootItems.tipconfirmbutton:addHandleOfControlEvent(function()
        gameWindowslogin:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindowslogin:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    self.rootItems.des:setString(data.des)
end


function shiming.close(self)
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

return shiming