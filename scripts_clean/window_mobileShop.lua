--
-- Author: songyibo
-- Date: 2018-09-29 15:34:14
--


local shop = {
    rootNode = nil,
    rootItems = nil,
    
    cellsize = {x = 960, y= 220},
    listview = nil,
    data = {},
    buyConfig = {},
}

function shop.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shop/suishenshop", nil, true, "suishenshop")
    self.touchPriority = touchPriority
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("mobileShop")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    -- local skeleton = CCSkeletonAnimation:create("diaochanhong/diaochanhong.json","diaochanhong/diaochanhong.atlas",1)
    -- skeleton:setPosition(0,0)
    -- skeleton:setScale(2)
    -- skeleton:setAnimation("stand",true,0)
    -- self.rootItems.generalnode:addChild(skeleton)

    self:reloadData(data)

    return self.rootNode
end
-- 道具使用的时候更
function shop.updatePropsShow( self )
    -- body
    if self.curData then
        self:reloadData(self.curData);
    end
end

function shop.reloadData(self,data)
    self.curData = data;
    if data then
        if not data.props then
            return
        end
        self.data = {}
        self.mobileShopId = data.mobileShopId

        local config = gamedata.config.portable_store[tostring(data.mobileShopId)]

        if config then
            local ids = string.split(config.mall,",")
            for i,v in ipairs(ids) do
                self.data[i] = {id = tonumber(v), buyNum = data.props[tostring(v)] or 0}
            end
        end

        printT(self.data,"self.data")
    end


	self.buyConfig = {}

    local curIds = {}
	for k,v in pairs(self.data) do
		self.buyConfig[tonumber(k)] = {}

		self.buyConfig[tonumber(k)].id = v.id
        self.buyConfig[tonumber(k)].canBuyMaxNum = self:canBuyMaxTime(v.id)
        self.buyConfig[tonumber(k)].buyNum = v.buyNum
		self.buyConfig[tonumber(k)].canBuyNum = self.buyConfig[tonumber(k)].canBuyMaxNum - v.buyNum
        local curCid = gamedata.config.shop[tostring(v.id)].id
        self.buyConfig[tonumber(k)].cid = curCid

        self.buyConfig[tonumber(k)].num = 1
        self.buyConfig[tonumber(k)].price = 0;
        curIds[k] = curCid;

	end

    UIRequest({type = 12001,order = 32000,cids = curIds});

    printT(self.buyConfig,"buyConfig")

end

function shop.reloadListData(self,nums)
    print(" shop.reloadListData ");
    printT(nums)
    self.allNum = nums;
    if not self.listview  then
        self:createList()
    else
        self.listview:reloadData()
    end
end

function shop.totalprice(self,id,usenum,buynum)

    local config = gamedata.config.shop[tostring(id)]
    local shopPriceConfig = gamedata.config.shop_price
    local shopPriceNum = table.getTableLength(shopPriceConfig)
    local totalprice = 0


    if config.discount and config.discount > 0 then
        totalprice = buynum*config.discount
    else
        local num = 0
        for i = usenum +1,usenum + buynum do
            if shopPriceConfig[tostring(i)] ~= nil then
                totalprice = totalprice +  shopPriceConfig[tostring(i)][config.seq.."_id"] 
            else
                totalprice = totalprice + shopPriceConfig[tostring(shopPriceNum)][config.seq.."_id"] 
            end
        end
    end
    return totalprice
end

function shop.canBuyMaxTime(self,id)

    local config = gamedata.config.shop[tostring(id)]
    local  canBuyMaxTime = 0
    if config["vip"..GameScene.vip.vip .."_times"] ~= 0  then
        canBuyMaxTime = config["vip"..GameScene.vip.vip .."_times"]
    else
        canBuyMaxTime = config.num
    end

    return canBuyMaxTime
end


function shop.createList(self)
    print("createRankList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellsize.x, self.cellsize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shop/cell_suishenshop", nil, true, "cell_suishenshop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
            --     if not self.isscrolltouched then return end
            --     if gameTouch.isScrollling then return end                
            --     if self.players[a1+1].rid ~= GameScene.roleinfo.id then
            --         gameWindows:openWindow("chatpop",self.players[a1+1],nil)
            --     end
            -- end, CCControlEventTouchUpInside)
            -- ccbDocumentControler["i_button"]:setTouchPriority(self.touchPriority)

            --

            self:setSell(ccbDocumentControler,a1+1)
            cellCCB:setPosition(self.cellsize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end

function shop.setNum(self,item,index,add)
    local data = self.buyConfig[index]

    if data.num + add <= 0 then
        data.num = 1
    elseif (data.canBuyNum ~= 0) and (data.num + add > data.canBuyNum) then
        --达到上限
        runGamePrompt({msg = gameConfig.strings:string_common("popups","buy_num")})
        data.num = data.canBuyNum
    else
        if data.num == 1 then
            if add == 10 then
                data.num = 10
            else
                data.num = data.num + add
            end
        else
            data.num = data.num + add
        end
    end
    if data.canBuyNum == 0 then
        data.num = 0;
    end

    data.price = self:totalprice(data.id,data.buyNum,data.num)
    -- ui.setLabelString(item.pricelabel,self:totalprice(data.id,data.buyNum,1),122)
    item.buynum:setString(data.num)
    -- item.allpricelabel:setString(data.price)



    ui.setLabelString(item.pricelabel, self:totalprice(data.id,data.buyNum,1), 13)
    ui.setLabelString(item.allpricelabel, data.price, 13)

    print("  data.price  ",data.price,GameScene.roleinfo.gold)
    if data.price > GameScene.roleinfo.gold then
        ui.removeLabelStroke(item.allpricelabel)
        item.allpricelabel:setColor(ccc3(252,31,25));
    else
        item.allpricelabel:setColor(ccc3(255,255,255))
    end
end

function shop.setSell(self,item,index)
    local data = self.buyConfig[index]

    if not data.cid then
        return
    end
    print("  data.cid   ");
    printT(data)
    print("--------------")
    printT(self.allNum)
    if data.cid >=33002 and data.cid <=33077 then
        item.myNum:setString("");
    else
        item.myNum:setString("当前拥有:"..self.allNum[tostring(data.cid)]);
    end

    ui.setNewIcon(item,{cid = data.cid})
    local config = ui.IDconfig(data.cid)
    ui.setLabelString(item.name,config.name, config.quality~=0 and 2*config.quality-1 or 1)
    
    item.fiexd1:setString(gameConfig.strings:string_common("mobileShop",2))
    item.canbuylabel:setString(string.format(gameConfig.strings:string_common("mobileShop",1), data.canBuyNum))
    
    self:setNum(item,index,0)

    ui.setLabelString(item.doLab,gameConfig.strings:string_common("shop_list",3),18)

    item.addbutton1:setTouchPriority(self.touchPriority-1)
    item.addbutton1:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        print("add")
        local data = self.buyConfig[index]
        if data.canBuyNum <= 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("popups","buy_num")})
        else
            self:setNum(item,index,1)
        end

    end, CCControlEventTouchUpInside)

    item.addbutton10:setTouchPriority(self.touchPriority-1)
    item.addbutton10:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        print("add")
        local data = self.buyConfig[index]
        if data.canBuyNum <= 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("popups","buy_num")})
        else
            self:setNum(item,index,10)
        end

    end, CCControlEventTouchUpInside)

    item.reducebutton1:setTouchPriority(self.touchPriority-1)
    item.reducebutton1:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        print("reduce")
        local data = self.buyConfig[index]
        if data.canBuyNum <= 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("popups","buy_num")})
        else
            self:setNum(item,index,-1)
        end

    end, CCControlEventTouchUpInside)

    item.reducebutton10:setTouchPriority(self.touchPriority-1)
    item.reducebutton10:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        print("reduce")
        local data = self.buyConfig[index]
        if data.canBuyNum <= 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("popups","buy_num")})
        else
            self:setNum(item,index,-10)
        end

    end, CCControlEventTouchUpInside)

    if data.canBuyNum > 0  then
        ui.removeGray("CCControlButton",item["doButton"])
    else
        ui.addGray("CCControlButton",item["doButton"])
    end

    item.i_button:setTouchPriority(self.touchPriority-1)
    item.i_button:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        ui.setPopwindowByCid(data.cid);
    end, CCControlEventTouchUpInside)

    item.doButton:setTouchPriority(self.touchPriority-1)
    item.doButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end

        print("buyButton clicked")
        if data.canBuyNum > 0  then
            --gameWindows:openWindow("shopbuy",data,nil)
            print("购买")
            UIRequest({type = 3201,mobileShopId = self.mobileShopId ,id = data.id, num = data.num,gold = data.price,maxBuyNum = data.canBuyMaxNum})
            gamedata.music:PlayOptSound("ccgm")

        else
            -- runGamePrompt({msg = "今日购买个数已用完"})
            runGamePrompt({msg = gameConfig.strings:string_common("shop_list",4)})
        end

    end, CCControlEventTouchUpInside)
end


function shop.close(self)  
    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.listview = nil

    if self.callback then
        self.callback()
    end
end

return shop