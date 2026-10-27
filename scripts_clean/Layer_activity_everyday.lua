--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
-- ui.setLabelString

local activityeveryday = {
    buttontouch = -103,
    data = {},
    showday = 1,
    wday = 1,
    ccbs = nil,
    animationManager = nil,
}


function activityeveryday.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityeveryday/activityeveryday",nil, true, "activityeveryday")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.midnode:setPositionY(self.contentsize.y/2+50)
    --
    ui.setLabelString(self.coveritems.gotoLab,gameConfig.strings:string_common("activityeveryday",1),18)
    self.coveritems.fixlab1:setString(gameConfig.strings:string_common("activityeveryday",2))
    --

    self.dayccb, self.dayitems = CCBReaderLoad("activityeveryday/everyday_zhuan",nil, true, "everyday_zhuan")
    self.coveritems.midnode:addChild(self.dayccb)
    self.animationManager = getAnimationManager(self.dayitems)

    self.coveritems.gotoButton:setTouchPriority(-103)
    --
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.coveritems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            return true
        end
    end

    local function ccTouchMoved(x, y)

    end

    local function ccTouchEnded(x, y)
        if x-self.touchX > 20 then
            self:goRight()
        elseif self.touchX-x > 20 then
            self:goLeft()
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.coveritems.touchLayer:registerScriptTouchHandler(onTouch, false, -110, true)
    self.coveritems.touchLayer:setTouchPriority(-110)
    self.coveritems.touchLayer:setTouchEnabled(true)

    --20051
    --self:reloaddata()

    return self.coverccb
end

function activityeveryday.reloaddata(self)
    if not self.show then return end

    local nowtime = os.date("*t", gamedata:time())
    local wday = ((nowtime.wday-1) < 1) and 7 or (nowtime.wday-1)
    self.showday = wday
    self.wday = wday

    self.data = gamedata.config.activity_huodong or {}

    if not self.ccbs then
        self.ccbs = {}
        for i = 1,6 do
            self.dayitems["daynode"..i]:removeAllChildrenWithCleanup(true)
            local ccb, ccbitems = CCBReaderLoad("activityeveryday/everyday", nil, true, "everyday")
            self.ccbs[i] = {ccb=ccb,ccbitems=ccbitems}
            self.dayitems["daynode"..i]:addChild(self.ccbs[i].ccb)
        end
    end

    --
    self.animationManager:runAnimationsForSequenceNamed("stop")
    self:setShowday()
end

function activityeveryday.goLeft(self)
    if not self.show then return end
    if not self.ccbs then return end
    --
    gameTouch:clickprofbytime(1)
    --
    self.showday = (self.showday+1) > 7 and 1 or (self.showday+1)
    local tem = (self.showday+1) > 7 and 1 or (self.showday+1)
    self:setdaydata(self.ccbs[3].ccbitems,self.data[tostring(tem)])
    --
    self.animationManager:setAnimationCompletedCallback(function()
        self.animationManager:runAnimationsForSequenceNamed("stop")
        self:setShowday()
    end)
    self.animationManager:runAnimationsForSequenceNamed("L")

end

function activityeveryday.goRight(self)
    if not self.show then return end
    if not self.ccbs then return end
    --
    gameTouch:clickprofbytime(1)
    --
    self.showday = (self.showday-1) < 1 and 7 or (self.showday-1)
    local tem = (self.showday-1) < 1 and 7 or (self.showday-1)
    self:setdaydata(self.ccbs[3].ccbitems,self.data[tostring(tem)])
    --
    self.animationManager:setAnimationCompletedCallback(function()
        self.animationManager:runAnimationsForSequenceNamed("stop")
        self:setShowday()
    end)
    self.animationManager:runAnimationsForSequenceNamed("R")

end

function activityeveryday.setShowday(self)
    if not self.show then return end
    if not self.ccbs then return end

    self:setdaydata(self.ccbs[1].ccbitems,self.data[tostring(self.showday)])
    self:setdaydata(self.ccbs[2].ccbitems,self.data[tostring((self.showday+1)>7 and 1 or (self.showday+1))])
    self:setdaydata(self.ccbs[5].ccbitems,self.data[tostring((self.showday+1)>7 and 1 or (self.showday+1))])
    self:setdaydata(self.ccbs[4].ccbitems,self.data[tostring((self.showday-1)<1 and 7 or (self.showday-1))])
    self:setdaydata(self.ccbs[6].ccbitems,self.data[tostring((self.showday-1)<1 and 7 or (self.showday-1))])

    --
    printT(self.data,"setShowday===")
    print("showday===",self.showday)
    if self.wday == self.showday then
        ui.removeGray("CCControlButton",self.coveritems.gotoButton)
        self.coveritems.gotoButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            GameScene:shiftLayerById(self.data[tostring(self.showday)].num)
        end, CCControlEventTouchUpInside)
    else
        ui.addGray("CCControlButton",self.coveritems.gotoButton)
        self.coveritems.gotoButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("activityeveryday",6)})
        end, CCControlEventTouchUpInside)
    end
end

function activityeveryday.setdaydata(self,item,data)
    item.e_day:setString(gameConfig.strings:string_common("activityeveryday",3)..gameConfig.strings:string_common("wdayNum",(data.open_time+1)>7 and 1 or (data.open_time+1)))
    setSpriteFrameByName(item.e_icon,data.icon or "alpha")
    item.e_desc:setString(data.desc)
    item.e_halfLab:setString(gameConfig.strings:string_common("activityeveryday",4))
    item.e_doubleLab:setString(gameConfig.strings:string_common("activityeveryday",5))
    if data.modulus and data.modulus > 1 then
        item.e_double:setVisible(true)
        item.e_half:setVisible(false)
    else
        item.e_double:setVisible(false)
        item.e_half:setVisible(true)
    end

    --
    if item.e_kuang1 then
        if self.wday == data.open_time then
            ui.removeGray("CCSprite",item.e_icon)
            ui.removeGray("CCSprite",item.e_kuang1)
            ui.removeGray("CCSprite",item.e_kuang2)
            ui.removeGray("CCSprite",item.e_kuang3)
            ui.removeGray("CCSprite",item.e_kuang4)
            ui.removeGray("CCLabelBMFont",item.e_halfLab)
            ui.removeGray("CCLabelBMFont",item.e_doubleLab)
        else
            ui.addGray("CCSprite",item.e_icon)
            ui.addGray("CCSprite",item.e_kuang1)
            ui.addGray("CCSprite",item.e_kuang2)
            ui.addGray("CCSprite",item.e_kuang3)
            ui.addGray("CCSprite",item.e_kuang4)
            ui.addGray("CCLabelBMFont",item.e_halfLab)
            ui.addGray("CCLabelBMFont",item.e_doubleLab)
        end
    end
end

function activityeveryday.clear(self)
    self.animationManager = nil
    self.ccbs = nil
    self.showday = 1
    self.wday = 1
    self.data = {}
    self.show = false

    self.dayccb = nil
    self.dayitems = nil

    self.coverccb = nil
    self.coveritems = nil
end





return activityeveryday