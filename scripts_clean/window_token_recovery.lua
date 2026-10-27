
--

local tokenRecovery = {
    rootNode = nil,
    rootItems = nil,

    buynum = 0,
    basicnum = 0,
    basicgetnum = 0,

    data = {},
    delayButtonStatus = true,
}

function tokenRecovery.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/props_recovery", nil, true, "props_recovery")

    self.data = data or {}
    self.touchPriority = touchPriority

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.buynum,self.touchPriority,function (num)
        self.buynum = 0
        self:numchange(num)
    end) 

    --
    local configdata = gamedata.config.token[tostring(self.data.cid or 0)] or {}
    self.basicnum = configdata.mix_num or 0
    local recover = configdata.recover or {}
    local coinid,coinnum= ui.getIDandNUM(recover)
    self.basicgetnum = coinnum or 0
    if coinid == 1000 then
        setSpriteFrameByName(self.rootItems.sprite_coin,"obj_s_coin")
    elseif coinid == 1001 then
        setSpriteFrameByName(self.rootItems.sprite_coin,"obj_s_gold")
    elseif coinid == 1034 then
        setSpriteFrameByName(self.rootItems.sprite_coin,"yaoqi")
        self.rootItems.sprite_coin:setScale(0.4)
    end

    self.rootItems.sprite_coin:setVisible(true)
    self.rootItems.sprite_gold:setVisible(false)
   
    self.rootItems["basicnum"]:setString(gameConfig.strings:recovery_basic_num(self.basicnum))
    --
    ui.setIconLv(self.rootItems,{cid = self.data.cid})
    ui.setLabelString(self.rootItems.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)
    self.rootItems["hasnum"]:setString(self.data.num or 0)
    --

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("tokenRecovery")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.add1:addHandleOfControlEvent(function()
    -- self:numchange(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
    -- self:numchange(10)
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)

    self.rootItems.sub1:addHandleOfControlEvent(function()
    -- self:numchange(-1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub10:addHandleOfControlEvent(function()
    -- self:numchange(-10)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab1,"取 消",18)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("tokenRecovery")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab2,"确 定",18)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        if self.buynum >0 then
            UIRequest({type = 8243,cid = self.data.cid, num = self.buynum*self.basicnum })
            gamedata.music:PlayOptSound("ccgm")
            gameWindows:closeWindowDirect("tokenRecovery")
        else
            -- runGamePrompt({msg = "请选择数量"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","ch_num")})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    self:setAddandReduceBtn()

    self:numchange(1)

    return self.rootNode
end



-- 增加 减少按钮
function tokenRecovery.setAddandReduceBtn( self)
    --
    local Func1 = function()
        self:numchange(1)
    end

    local Func2 = function()
        self:numchange(10)
    end


    local reduce1 = function()
        self:numchange(-1)
    end

    local reduce2 = function()
        self:numchange(-10)
    end

    if self.delayButtonStatus then
        ui.creatDelayButton(self.rootItems.add1,self.touchPriority,Func1)
        ui.creatDelayButton(self.rootItems.add10,self.touchPriority,Func2)

        ui.creatDelayButton(self.rootItems.sub1,self.touchPriority,reduce1)
        ui.creatDelayButton(self.rootItems.sub10,self.touchPriority,reduce2)
    end
    self.delayButtonStatus = false

end


function tokenRecovery.numchange(self,num)
    if self.basicnum < 1 then
        self.buynum = 0
        return
    end

    if (self.buynum+num) < 0 then
        self.buynum = 0
    elseif (self.buynum+num)*self.basicnum > self.data.num then
        self.buynum = math.floor(self.data.num/self.basicnum)
    else
        self.buynum = self.buynum+num
    end

    self.rootItems.buynum:setString(self.buynum)

    self.rootItems.totalprice:setString(self.buynum*self.basicgetnum)
    if self.buynum*self.basicnum > 0 then
        ui.setLabelString(self.rootItems.changenum,"-"..(self.buynum*self.basicnum),24)
    else
        ui.setLabelString(self.rootItems.changenum,"",24)
    end
end


function tokenRecovery.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.data = {}
    self.buynum = 0
    self.basicnum = 0
    self.basicgetnum = 0
    self.delayButtonStatus = true

    if self.callback then
        self.callback()
    end

end

return tokenRecovery