--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/3
-- Time: 下午4:31
-- To change this template use File | Settings | File Templates.
--

local buy = {
    rootNode = nil,
    rootItems = nil,

    buynum = 0,

    data = {},
    delayButtonStatus = true,
    isOnce = true,
}

function buy.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shop/tc_shop", nil, true, "tc_shop")

    self.touchPriority = touchPriority
    self.isOnce = true

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.buynum,self.touchPriority,function (num)
        self.buynum = 0
        self:numchange(num)
    end)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("shopbuy")
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

    self.rootItems.add100:addHandleOfControlEvent(function()
        -- self:numchange(100)
    end, CCControlEventTouchUpInside)
    self.rootItems.add100:setSwallowsTouch(true)
    self.rootItems.add100:setTouchPriority(self.touchPriority)

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

    self.rootItems.sub100:addHandleOfControlEvent(function()
        -- self:numchange(-100)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub100:setSwallowsTouch(true)
    self.rootItems.sub100:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab1,"取 消",18)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("shopbuy")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab2,"确 定",18)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        print("self.buynum = "..self.buynum)
        if self.buynum >0 then
            if self.buynum <= self.data.canBuyMaxTime then
                UIRequest({type = 3201,id = self.data.seq, num = self.buynum,gold = tonumber(self.rootItems.totalprice:getString()),maxBuyNum = self.data.canBuyMaxTime})
                gameWindows:closeWindow("shopbuy")
            end
            gamedata.music:PlayOptSound("ccgm")
        else
           -- runGamePrompt({msg = "请选择数量"})
           runGamePrompt({msg = gameConfig.strings:string_common("popups","ch_num")})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    self.shopPriceConfig = gamedata.config.shop_price
    self.shopPriceNum = table.getTableLength(self.shopPriceConfig)  

    self:reload(data,callback)

    self:initnum(0)

    self:setAddandReduceBtn()
    return self.rootNode
end



-- 增加 减少按钮
function buy.setAddandReduceBtn( self)
    


    local beginFunc = function(index)
        print("beginFunc"..index)
        -- if self.refine["l_num"..index] < 1 then return end

        -- self["effect_begin"..index] = false
        -- self["effect_end"..index] = false
        -- --
        -- self.rootItems["selectEffectNode"..index]:stopAllActions()
        -- self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
        -- local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/cailiaoxuanzhong/cailiaoxuanzhong", nil, true, "cailiaoxuanzhong")
        -- qianghuaNode:setPosition(0,0)
        -- self.rootItems["selectEffectNode"..index]:addChild(qianghuaNode)
        -- self.rootItems["selectEffectNode"..index]:setScale(1)
        -- local animationManager = getAnimationManager(qianghuaItems)
        -- animationManager:runAnimationsForSequenceNamed("zhenrongxuanzhong")
        -- --
        -- self.rootItems["selectEffectNode"..index]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
        --     self["effect_begin"..index] = true
        --     if self["effect_end"..index] then
        --         self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
        --     end
        -- end)))
    end

    local endFunc = function(index)
        print("endFunc"..index)
        -- self["effect_end"..index] = true
        -- if self["effect_begin"..index] then
        --     self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
        -- end
    end
    --
    local Func1 = function()
        print("Func1====")
        self:numchange(1)
        self.isOnce = false
    end

    local Func2 = function()
        print("Func2====")
        self:numchange(10)
        self.isOnce = false
    end

    local Func3 = function()
        print("Func3====")
        self:numchange(100)
        self.isOnce = false
    end


    local reduce1 = function()
        print("reduce1====")
        self:numchange(-1)
        self.isOnce = false
    end

    local reduce2 = function()
        print("reduce2====")
        self:numchange(-10)
        self.isOnce = false
    end

    local reduce3 = function()
        print("reduce3====")
        self:numchange(-100)
        self.isOnce = false
    end
    print("aaaaaa====")
    -- printT(self.rootItems)
    if self.delayButtonStatus then
        print("setbtn====")
        ui.creatDelayButton(self.rootItems.add1,self.touchPriority,Func1,beginFunc,endFunc,1)
        ui.creatDelayButton(self.rootItems.add10,self.touchPriority,Func2,beginFunc,endFunc,2)
        ui.creatDelayButton(self.rootItems.add100,self.touchPriority,Func3,beginFunc,endFunc,3)

        ui.creatDelayButton(self.rootItems.sub1,self.touchPriority,reduce1)
        ui.creatDelayButton(self.rootItems.sub10,self.touchPriority,reduce2)
        ui.creatDelayButton(self.rootItems.sub100,self.touchPriority,reduce3)

    end
    self.delayButtonStatus = false

end

function buy.setbuydata(self)
    if self.data.canBuyMaxTime > 0 then
        if self.buynum <= 0 then
            self.buynum = 1
        end
    end
    self.rootItems.buynum:setString(self.buynum)
    if self.data.discount and self.data.discount > 0 then
        self.rootItems.totalprice:setString(self.buynum*self.data.discount)
    else
        local num = 0
        for i = self.data.usenum +1,self.data.usenum + self.buynum do
            if self.shopPriceConfig[tostring(i)] ~= nil then
                num = num +  self.shopPriceConfig[tostring(i)][self.data.seq.."_id"] 
            else
                num = num + self.shopPriceConfig[tostring(self.shopPriceNum)][self.data.seq.."_id"] 
            end
        end
        self.rootItems.totalprice:setString(num)
    end
end

function buy.initnum(self,num)
    local needGold = 0
    for i = self.data.usenum +1,self.data.usenum + num do
        if self.shopPriceConfig[tostring(i)] ~= nil then
            needGold = needGold +  self.shopPriceConfig[tostring(i)][self.data.seq.."_id"] 
        else
            needGold = needGold + self.shopPriceConfig[tostring(self.shopPriceNum)][self.data.seq.."_id"] 
        end
    end    
    if needGold > GameScene.roleinfo.gold then
    elseif num > self.data.canBuyMaxTime - self.data.usenum then
    else
        self:numchange(num)
    end
end

function buy.numchange(self,num)
    print("  self.isOnce  ",self.isOnce)
    local canbuynum = 0
    if self.buynum+num > self.data.canBuyMaxTime - self.data.usenum then
        canbuynum = self.data.canBuyMaxTime - self.data.usenum
    else
        canbuynum = self.buynum + num
    end

    local needGold = 0
    for i = self.data.usenum +1,canbuynum do
        if self.shopPriceConfig[tostring(i)] ~= nil then
            needGold = needGold +  self.shopPriceConfig[tostring(i)][self.data.seq.."_id"]
        else
            needGold = needGold + self.shopPriceConfig[tostring(self.shopPriceNum)][self.data.seq.."_id"]
        end
    end

    if needGold > GameScene.roleinfo.gold then
        shortGold()
    elseif self.buynum+num < 0 then
        self.buynum = 0
    elseif self.price*(self.buynum+num) < 0 then
        self.buynum = 0
    elseif self.buynum+num > self.data.canBuyMaxTime - self.data.usenum then
        self.buynum = self.data.canBuyMaxTime - self.data.usenum
        -- runGamePrompt({msg = "购买个数已达上限"})
        runGamePrompt({msg = gameConfig.strings:string_common("popups","buy_num")})
    else
        if self.buynum == 1 then
            if num == 10 and self.isOnce == true then
                self.buynum = 10
            else
                self.buynum = self.buynum + num
            end
        else
            self.buynum = self.buynum + num
        end

    end
    self:setbuydata()
end

function buy.setPropdata(self,data)
    -- printT(data,"setPropdata===")

    if ui.IDconfig(data.id) and ui.IDconfig(data.id).staffType == "props" then
        self.rootItems.hasdescText:setVisible(true)
        self.rootItems.hasnum:setVisible(true)
    else
        self.rootItems.hasdescText:setVisible(false)
        self.rootItems.hasnum:setVisible(false)
    end


    local oldCanBuyMaxTimes = self.data and self.data.canBuyMaxTime or 0
    self.data = data
    self.data.canBuyMaxTime = self.data.canBuyMaxTime == nil and oldCanBuyMaxTimes or self.data.canBuyMaxTime
    local configdata = ui.IDconfig(data.id)
    ui.setIconLv(self.rootItems,{cid = data.id})
    ui.setLabelString(self.rootItems.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)

    ui.setLabelString(self.rootItems.buytime, data.canBuyMaxTime - data.usenum, 13)

    self.price = (data.discount and data.discount >0) and data.discount or data.gold

    UIRequest({type = 12001, order = 32011, cids = {data.id}})
end

function buy.setpropNum(self,data)
    local num = data[tostring(self.data.id)] or 0
    self.rootItems["hasnum"]:setString(tostring(num))
    if not self.needeffect then
        self.needeffect = true
    else
        local scaleTo1 = CCScaleTo:create(0.2, 1.7,1.7)
        local scaleTo2 = CCScaleTo:create(0.2, 1,1)
        self.rootItems["hasnum"]:runAction(CCSequence:createWithTwoActions(scaleTo1,scaleTo2))
    end
end

function buy.reload(self,data,callback)
    self.callback = callback
    self:setPropdata(data)
    self:setbuydata()
end

function buy.reloadData(self,data)
    self:setPropdata(data)
    self:numchange(0-self.buynum)
end

function buy.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.needeffect = nil

    if self.callback then
        self.callback()
    end
    self.buynum = 0
    self.isOnce = true
    self.delayButtonStatus = true
end

return buy  �.  