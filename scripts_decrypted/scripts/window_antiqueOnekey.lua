antiqueOnekey = {
   antiqueOriginalItem = {},

   paimai_num = 0,
   chengjiao_num = 0,

   paimai_max = 0,
   paimai_min = 1,

   chengjiao_max = 0,
   chengjiao_min =1,

   coinID = 1001,
   exceptnum = 1,
   isOnce = true,
   delayButtonStatus = true,


}




function antiqueOnekey.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.isOnce = true
    self.delayButtonStatus = true
end

function antiqueOnekey.open(self, touchPriority, data, callback)
     isOnce = true
    self.antiqueOriginalItem = gamedata.config.antique_item
    self:initNode(touchPriority)
    self:initConfig()
    self:initEventBtn()
    self:initFixedString()
    self:initAddSubBtn()
    self:reloadData()
    self:setAddandReduceBtn()

    return self.rootNode
end

function antiqueOnekey.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("activitygudong/gudong_select_1", nil, true, "gudong_select_1")
    self.touchPriority = touchPriority
end

function antiqueOnekey.initConfig(self)
    self.antiqueItem = {}

    for k,v in pairs(gamedata.config.antique_item) do
        table.insert(self.antiqueItem, v)
    end

    local _tableSort = function(left, right)
        return left.cid < right.cid
    end

    table.sort(self.antiqueItem, _tableSort)
end

function antiqueOnekey.initEventBtn(self)
    self:initCloseBtn()
    self:initStartAuctionBtn()
end

function antiqueOnekey.initCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("activityantiqueOnekey")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

function antiqueOnekey.initStartAuctionBtn(self)
    local _cb = function()
        if self.currentItem then
            
            if self.paimai_num >0 and self.chengjiao_num >0 then

               GameScene.antiqueResultType = self.coinID

               UIRequest({type = 5415, cid = self.items[self.currentItem].cid, num = self.paimai_num , price = self.chengjiao_num})
            end    

            -- UIRequest({type = 5410, cid = self.items[self.currentItem].cid})
            -- if GameScene.roleinfo then
            --     CCUserDefault:sharedUserDefault():setIntegerForKey("activityAuctionTimer_"..gameWindows.windows["roleinfo"].module.SelectedServer.id..GameScene.roleinfo.id, gamedata:time())
            -- end
        else
            runGamePrompt({msg = gameConfig.strings:string_common("activityAuction", 2)})
        end
    end

    self:commonBtn(self.rootItems, "startAuctionBtn", _cb)
end

function antiqueOnekey.initAddSubBtn(self)
     self.rootItems.add1:addHandleOfControlEvent(function()
        -- self:numchange(1,0)
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add2:addHandleOfControlEvent(function()
        -- self:numchange(10,0)
    end, CCControlEventTouchUpInside)
    self.rootItems.add2:setSwallowsTouch(true)
    self.rootItems.add2:setTouchPriority(self.touchPriority)

    self.rootItems.sub1:addHandleOfControlEvent(function()
        -- self:numchange(-1,0)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub2:addHandleOfControlEvent(function()
        -- self:numchange(-10,0)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub2:setSwallowsTouch(true)
    self.rootItems.sub2:setTouchPriority(self.touchPriority)


    self.rootItems.add3:addHandleOfControlEvent(function()
        -- self:numchange(10000,1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add3:setSwallowsTouch(true)
    self.rootItems.add3:setTouchPriority(self.touchPriority)

    self.rootItems.add4:addHandleOfControlEvent(function()
        -- self:numchange(100000,1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add4:setSwallowsTouch(true)
    self.rootItems.add4:setTouchPriority(self.touchPriority)

    self.rootItems.sub3:addHandleOfControlEvent(function()
        -- self:numchange(-10000,1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub3:setSwallowsTouch(true)
    self.rootItems.sub3:setTouchPriority(self.touchPriority)

    self.rootItems.sub4:addHandleOfControlEvent(function()
        -- self:numchange(-100000,1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub4:setSwallowsTouch(true)
    self.rootItems.sub4:setTouchPriority(self.touchPriority)



end

function antiqueOnekey.initFixedString(self)
    self.rootItems.paimainum:setString("0")
    self.rootItems.chengjiaonum:setString("0")  
    self.paimai_num = 1
    self.chengjiao_num = 0
    ui.setLabelString(self.rootItems.startAuctionTxt, gameConfig.strings:string_common("activityAuction", 1),18)
end

function antiqueOnekey.reloadData(self, data)
    self.currentItem = nil
    self.antiqueItemTableLength = table.getTableLength(self.antiqueItem)

    if not data then
        local _cids = {}

        for i = 1, self.antiqueItemTableLength do

            table.insert(_cids, self.antiqueItem[i].cid)
        end

        UIRequest({type = 12001, order = 33012, cids = _cids})

        return 
    end

    self.items = {}

    for i = 1, self.antiqueItemTableLength do
        self.items[i] = {}
        self.items[i].cid = self.antiqueItem[i].cid
        self.items[i].num = data[tostring(self.antiqueItem[i].cid)] or 0
        self:setItem(i)
        self:setEffect(self.rootItems["choose"..i], false)
    end


end

function antiqueOnekey.setEffect(self, item, isShow)
    item:setVisible(isShow)
end

-- 设置奖励
function antiqueOnekey.setItem(self, index)
    local _key_Ex = ""
    
    if index == 1 then
        _key_Ex = ""
    else
        _key_Ex = "_"..(index - 1)
    end

    ui.setNewIconName(self.rootItems, {cid = self.items[index].cid, num = self.items[index].num}, index - 1)

    local _cb = function()

        if GameScene.roleinfo.level < self.antiqueItem[index].level then
            runGamePrompt({msg = gameConfig.strings:activityAuctionChooseOneKey(self.antiqueItem[index].level)})
            return
        end

        if self:checkItemIsCanUse(index, self.items[index].num)  then
            runGamePrompt({msg = "古董数量为0"})
           return
        end    


        self:setCurrentItem(index, self.items[index].num)
        local prices = self.antiqueOriginalItem[tostring(self.items[index].cid)].fast_min  or 0
        local maxprices = self.antiqueOriginalItem[tostring(self.items[index].cid)].fast_max  or 0
        self.coinID = self.antiqueOriginalItem[tostring(self.items[index].cid)].coinID  or 0
        if self.coinID == 1000 then
           self.exceptnum = 10000
            self.rootItems.chengjiaonum:setString(prices/self.exceptnum..gameConfig.strings:string_common("activityAuction", 5))

        else
           self.exceptnum = 1
            self.rootItems.chengjiaonum:setString(tostring(prices/self.exceptnum).."元宝")

        end    

        self.rootItems.buynum2:setString(tostring(prices/self.exceptnum))
        self.rootItems.paimainum:setString("1")
        self.rootItems.buynum1:setString("1")
        self.chengjiao_num = prices
        self.chengjiao_min = prices
        self.chengjiao_max = maxprices
        self.paimai_min = 1
        self.paimai_max = self.items[index].num
        self.paimai_num = 1
    end

    if self:checkItemIsCanUse(index, self.items[index].num) then
        ui.addGray("CCSprite", self.rootItems["in_quality".._key_Ex])
        ui.addGray("CCSprite", self.rootItems["in_icon".._key_Ex])
        ui.addGray("CCSprite", self.rootItems["in_k_quality".._key_Ex])
    end
    self:commonBtn(self.rootItems, "i_button".._key_Ex, _cb)
end

function antiqueOnekey.setCurrentItem(self, index, num)
   
    if self.currentItem then
        self:setEffect(self.rootItems["choose"..self.currentItem], false)
    end

    self.currentItem = index
    self:setEffect(self.rootItems["choose"..self.currentItem], true)
end

function antiqueOnekey.checkItemIsCanUse(self, index, num)
    return (num <= 0) or (GameScene.roleinfo.level < self.antiqueItem[index].level)
end

-- 通用按钮
function antiqueOnekey.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(toucnhPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end


function antiqueOnekey.numchange(self,num,numtype)
    print("  self.isOnce  ",self.isOnce)
    if not self.currentItem then
        runGamePrompt({msg = gameConfig.strings:string_common("activityAuction", 2)})
        return
    end

    if numtype == 0 then
        local canbuynum = self.paimai_max
        if self.paimai_num +num < self.paimai_min then
            self.paimai_num = self.paimai_min
            runGamePrompt({msg = gameConfig.strings:string_common("activityAuction", 13)})
        elseif self.paimai_num+num > canbuynum then
            self.paimai_num = canbuynum
            runGamePrompt({msg = gameConfig.strings:string_common("activityAuction", 10)})
        else
            self.paimai_num = self.paimai_num + num
        end

        self.rootItems.paimainum:setString(tostring(self.paimai_num))
        self.rootItems.buynum1:setString(tostring(self.paimai_num))

    else    
        
        if self.coinID == 1001 then
           num = num/10000
        end    

        local canbuynum = self.chengjiao_max
        if self.chengjiao_num+num < self.chengjiao_min then
            self.chengjiao_num = self.chengjiao_min
            runGamePrompt({msg = gameConfig.strings:string_common("activityAuction", 12)..self.chengjiao_min/self.exceptnum})
        elseif self.chengjiao_num+num > canbuynum then
            self.chengjiao_num = canbuynum
            runGamePrompt({msg = gameConfig.strings:string_common("activityAuction", 11)})
        else
            self.chengjiao_num = self.chengjiao_num + num
        end

        if self.coinID == 1000 then
            self.rootItems.chengjiaonum:setString(self.chengjiao_num/self.exceptnum..gameConfig.strings:string_common("activityAuction", 5))
        else
           self.rootItems.chengjiaonum:setString(tostring(self.chengjiao_num/self.exceptnum).."元宝")
        end    
        -- self.rootItems.chengjiaonum:setString(self.chengjiao_num/self.exceptnum..gameConfig.strings:string_common("activityAuction", 5))
        self.rootItems.buynum2:setString(tostring(self.chengjiao_num/self.exceptnum))

    end  


end


-- 增加 减少按钮
function antiqueOnekey.setAddandReduceBtn( self)
    local beginFunc = function(index)
        print("beginFunc"..index)
    end

    local endFunc = function(index)
        print("endFunc"..index)
    end
    --
    local Func1 = function()
        print("Func1====")
        self:numchange(1,0)
        self.isOnce = false
    end

    local Func2 = function()
        print("Func2====")
        self:numchange(10,0)
        self.isOnce = false
    end


    local reduce1 = function()
        print("reduce1====")
        self:numchange(-1,0)
        self.isOnce = false
    end

    local reduce2 = function()
        print("reduce2====")
        self:numchange(-10,0)
        self.isOnce = false
    end



    local beginFuncPrice = function(index)
        print("beginFuncPrice"..index)
    end

    local endFuncPrice = function(index)
        print("endFuncPrice"..index)
    end
    --
    local FuncPrice1 = function()
        print("FuncPrice1====")
        self:numchange(10000,1)
        self.isOnce = false
    end

    local FuncPrice2 = function()
        print("FuncPrice2====")
        self:numchange(100000,1)
        self.isOnce = false
    end


    local reducePrice1 = function()
        print("reducePrice1====")
        self:numchange(-10000,1)
        self.isOnce = false
    end

    local reducePrice2 = function()
        print("reducePrice2====")
        self:numchange(-100000,1)
        self.isOnce = false
    end


    print("aaaaaa====")
    if self.delayButtonStatus then
        ui.creatDelayButton(self.rootItems.add1,self.touchPriority,Func1,beginFunc,endFunc,1)
        ui.creatDelayButton(self.rootItems.add2,self.touchPriority,Func2,beginFunc,endFunc,2)

        ui.creatDelayButton(self.rootItems.sub1,self.touchPriority,reduce1)
        ui.creatDelayButton(self.rootItems.sub2,self.touchPriority,reduce2)


        ui.creatDelayButton(self.rootItems.add3,self.touchPriority,FuncPrice1,beginFuncPrice,endFuncPrice,1)
        ui.creatDelayButton(self.rootItems.add4,self.touchPriority,FuncPrice2,beginFuncPrice,endFuncPrice,2)

        ui.creatDelayButton(self.rootItems.sub3,self.touchPriority,reducePrice1)
        ui.creatDelayButton(self.rootItems.sub4,self.touchPriority,reducePrice2)

    end
    self.delayButtonStatus = false
end


return antiqueOnekey  N3  