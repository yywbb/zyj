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
        renzheng = "MainScene/tc_shimingrenzheng",
        jiangli = "MainScene/tc_shimingjiangli",
        shuoming = "MainScene/tc_fangchenmishuoming",
        tishi = "MainScene/tc_fangchenmitishi",

        renzheng2 = "MainScene/tc_shimingrenzheng2",
        tishi2 = "MainScene/tc_fangchenmitishi2",
        tishi3 = "MainScene/tc_fangchenmitishi3",
        tishi5 = "MainScene/tc_fangchenmitishi5",
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

    if self.page == "renzheng" then
        self:reloadrenzhneg(data,callback)
    elseif self.page == "jiangli" then
        self:reloadjiangli(data,callback)
    elseif self.page == "shuoming" then
        self:reloadshuoming(data,callback)
    elseif self.page == "tishi" then
        self:reloadtishi(data,callback)
    elseif self.page == "renzheng2" then
        self:reloadrenzhneg2(data,callback)
    elseif self.page == "tishi2" then
        self:reloadtishi2(data,callback)
    elseif self.page == "tishi3" then
        self:reloadtishi3(data,callback)
    elseif self.page == "tishi5" then
        self:reloadtishi5(data,callback)
    end

end

function shiming.reloadrenzhneg( self,data,callback )

    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    self.rootItems.tipbutton:setSwallowsTouch(true)
    self.rootItems.tipbutton:setTouchPriority(self.touchPriority)
    self.rootItems.tipbutton:addHandleOfControlEvent(function()
        self:shiftpage({page="shuoming"})
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.passlab,"下次再说",19)
    self.rootItems.passbutton:setSwallowsTouch(true)
    self.rootItems.passbutton:setTouchPriority(self.touchPriority)
    self.rootItems.passbutton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.renzhenglab,"前往认证",19)
    self.rootItems.renzhengbutton:setSwallowsTouch(true)
    self.rootItems.renzhengbutton:setTouchPriority(self.touchPriority)
    self.rootItems.renzhengbutton:addHandleOfControlEvent(function()
        if gamedata.sdk:isValid() and gamedata.sdk.toIDCard then
            gamedata.sdk:toIDCard()
        end
    end, CCControlEventTouchUpInside)

    local reward = gamedata.config.global_kv.authentication_reward.value
    local rewardt = ui.getIDandNUMs(reward)
    for i=1,4 do
        if rewardt[i] then
            ui.setNewIcon(self.rootItems,rewardt[i],i-1)
            local key_Ex = (i-1>0 and "_"..(i-1) or "")
            self.rootItems["i_button"..key_Ex]:setSwallowsTouch(true)            
            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority)
            self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(rewardt[i].cid)
            end, CCControlEventTouchUpInside)
        end
    end
end

function shiming.reloadjiangli( self,data,callback )

    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.dolab,"领取",19)
    self.rootItems.dobutton:setSwallowsTouch(true)
    self.rootItems.dobutton:setTouchPriority(self.touchPriority)
    self.rootItems.dobutton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("shiming")
        UIRequest({type = 5342})
    end, CCControlEventTouchUpInside)

    local reward = gamedata.config.global_kv.authentication_reward.value
    local rewardt = ui.getIDandNUMs(reward)
    for i=1,4 do
        if rewardt[i] then
            ui.setNewIcon(self.rootItems,rewardt[i],i-1)
            local key_Ex = (i-1>0 and "_"..(i-1) or "")
            self.rootItems["i_button"..key_Ex]:setSwallowsTouch(true)            
            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority)
            self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(rewardt[i].cid)
            end, CCControlEventTouchUpInside)
        end
    end
end

function shiming.reloadshuoming( self,data,callback )
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self:shiftpage({page="renzheng"})
    end, CCControlEventTouchUpInside)
end

function shiming.reloadtishi( self,data,callback )
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.tipconfirmlab,"确定",19)
    self.rootItems.tipconfirmbutton:setSwallowsTouch(true)
    self.rootItems.tipconfirmbutton:setTouchPriority(self.touchPriority)
    self.rootItems.tipconfirmbutton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
    end, CCControlEventTouchUpInside)


    if data.des then
        self.rootItems.des:setString(data.des)
    end
end

function shiming.reloadrenzhneg2( self,data,callback )
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.passlab,"下次再说",19)
    self.rootItems.passbutton:setSwallowsTouch(true)
    self.rootItems.passbutton:setTouchPriority(self.touchPriority)
    self.rootItems.passbutton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.renzhenglab,"前往认证",19)
    self.rootItems.renzhengbutton:setSwallowsTouch(true)
    self.rootItems.renzhengbutton:setTouchPriority(self.touchPriority)
    self.rootItems.renzhengbutton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
        if gamedata.sdk:isValid() and gamedata.sdk.toIDCard then
            gamedata.sdk:toIDCard()
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.timedes:setString(self.data or "")
end

function shiming.reloadtishi2( self,data,callback )
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.tipconfirmlab,"确定",19)
    self.rootItems.tipconfirmbutton:setSwallowsTouch(true)
    self.rootItems.tipconfirmbutton:setTouchPriority(self.touchPriority)
    self.rootItems.tipconfirmbutton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
    end, CCControlEventTouchUpInside)
end

function shiming.reloadtishi3( self,data,callback )

    ui.setLabelString(self.rootItems.tipconfirmlab,"确定",19)
    self.rootItems.tipconfirmbutton:setSwallowsTouch(true)
    self.rootItems.tipconfirmbutton:setTouchPriority(self.touchPriority)
    self.rootItems.tipconfirmbutton:addHandleOfControlEvent(function()
        if not data.time then 
            gameWindows:closeWindow("shiming")
        else
            loading:exit()
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.des:setString(data.des)

    if data.time then
        self.rootItems.time:setString("倒计时："..data.time.."s")
        gameTimer:rigistTime("exitbytime",data.time)
        gameTimer:rigistTimeFunc("exitbytime",function()
            self.rootItems.time:setString("倒计时："..gameTimer.times["exitbytime"].."s")
            if gameTimer.times["exitbytime"] <= 0 then
                loading:exit()
            end
        end)
    end
end


function shiming.reloadtishi5( self,data,callback )

    ui.setLabelString(self.rootItems.tipconfirmlab,"确定",19)
    self.rootItems.tipconfirmbutton:setSwallowsTouch(true)
    self.rootItems.tipconfirmbutton:setTouchPriority(self.touchPriority)
    self.rootItems.tipconfirmbutton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
    end, CCControlEventTouchUpInside)

    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("shiming")
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

return shimingh)  