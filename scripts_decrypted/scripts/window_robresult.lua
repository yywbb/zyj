--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local robresult = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    -- listScrollSize = {x=920,y=680}
    configdata = {},

    rewards = {
        [1] = {node=nil,item=nil,state = true},
        [2] = {node=nil,item=nil,state = true},
        [3] = {node=nil,item=nil,state = true},
    },
}

function robresult.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.configdata = data.data
    print("robresultis===")
    printT(data)

--    self.oneState = true
--    self.twoState = true
--    self.threeState = true

    if data.index == "robTen" then
        self.rootNode, self.rootItems = CCBReaderLoad("rub/rub_tenjieguo.ccbi", nil, true, "rub_tenjieguo")
        -- self.rootItems.listScroll:setContentSize(CCSizeMake(920,180))
        self:tenReload()
    elseif data.index == "seccess" then
        self.rootNode, self.rootItems = CCBReaderLoad("rub/rub_one.ccbi", nil, true, "rub_one")
        self:oneReload()
    elseif data.index == "fail" then
        self.rootNode, self.rootItems = CCBReaderLoad("rub/rub_lost.ccbi", nil, true, "rub_lost")
        self:reload(data,callback)
    end
    
    self.root:addChild(self.rootNode)
    return self.root
end

function robresult.oneReload(self)
    print("...i...am...oneReload.....")
    printT(self.configdata)
    if self.configdata.rob and self.configdata.rob.num and self.configdata.rob.num > 0 then
        ui.setLabelString(self.rootItems.getCoinNum, self.configdata.rob.num, 14)
        setSpriteFrameByName(self.rootItems.getCoinSprite, "duobaobi")
    elseif self.configdata.coin and self.configdata.coin.num and self.configdata.coin.num > 0 then
        ui.setLabelString(self.rootItems.getCoinNum, self.configdata.coin.num, 14)
        setSpriteFrameByName(self.rootItems.getCoinSprite, "propcoin")
    else
        ui.setLabelString(self.rootItems.getCoinNum, "0", 14)
    end

    ui.setLabelString(self.rootItems.selfname, GameScene.roleinfo.name, 46)
    self.rootItems.selfpower:setString(GameScene.roleinfo.power)

    ui.setLabelString(self.rootItems.enemyname, self.configdata.enemy.name, 46)
    self.rootItems.enemypower:setString(self.configdata.enemy.param)

    ui.setLabelString(self.rootItems.zaizhanLabel, nil, 19)
    ui.setLabelString(self.rootItems.backLabel, nil, 19)

    
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(self.touchPriority)
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        print("i..am...remove..robresult..")
        gameWindows:closeWindowDirect("robresult")
    end, CCControlEventTouchUpInside)

    self.rootItems.gainBtn:setSwallowsTouch(true)
    self.rootItems.gainBtn:setTouchPriority(self.touchPriority)
    self.rootItems.gainBtn:addHandleOfControlEvent(function()
        print("i..am...remove..robresult..")
        if self.configdata.get then
            -- runGamePrompt({msg = "已获得该物品，无法抢夺"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","googshave")})
            return
        end
        UIRequest(self.configdata.request)
        gameWindows:closeWindowDirect("robresult")
    end, CCControlEventTouchUpInside)


    local getconfig = self.configdata.get
    if getconfig then
        self.rootItems.getFragmentNode:setVisible(true)
        self.rootItems.noFragmentFont:setVisible(false)

        local getdata = ui.IDconfig(getconfig.cid)
        -- self.rootItems.FragmentFontName:setString(getdata.name)
        ui.setLabelString(self.rootItems.FragmentFontName,getdata.name,1)

        ui.addGray("CCControlButton",self.rootItems.gainBtn)
    else
        self.rootItems.getFragmentNode:setVisible(false)
        self.rootItems.noFragmentFont:setVisible(true)
    end

    self:createRewardItems()
end

function robresult.setEnabledFalse(self,bool)
    for i=1,3 do
        self.rewards[i].item.touchBtn:setEnabled(bool)
    end
end

function robresult.fanpai(self,i,data,cb)
    print("fanpai===")
    printT(data)
    ui.setNewIcon(self.rewards[i].item,data)
    local animationManager = getAnimationManager(self.rewards[i].item)
    animationManager:setAnimationCompletedCallback(function()
        if self.rewards[i].state then
            local rewarddata = ui.IDconfig(data.cid)
            ui.setLabelString(self.rewards[i].item.propNameLabel,rewarddata.name,((data.quality and data.quality ~= 0) and data.quality or 1)*2-1)
        end
        if cb then cb() end
    end)
    animationManager:runAnimationsForSequenceNamed("fanpai")
end

function robresult.createRewardItems(self)
    for i=1,3 do
        self.rewards[i].node,self.rewards[i].item = CCBReaderLoad("rub/cell_fanpaizi.ccbi", nil, true, "cell_fanpaizi")
        self.rootItems["RewardNode"..i]:addChild(self.rewards[i].node)

        self.rewards[i].item.touchBtn:setSwallowsTouch(true)
        self.rewards[i].item.touchBtn:setTouchPriority(self.touchPriority)
        self.rewards[i].item.touchBtn:addHandleOfControlEvent(function()
            print("i..am...rewardOneItem1..")
            for j=1,3 do
                self.rewards[j].State = i==j
            end
            self:setEnabledFalse(false)
            print("i..am...rewardOneItem2..")

            self:fanpai(i,self.configdata.otherreward["1"])
            print("i..am...rewardOneItem3..")
            local ccbNode, ccbitem = CCBReaderLoad("rub/cell_fanpaizi_effect.ccbi", nil, true, "cell_fanpaizi_effect")
            self.rootItems["RewardNode"..i]:addChild(ccbNode)
            
            local lootconfig = gamedata.config.loot[tostring(self.configdata.otherreward["1"].quality<2 and 2 or self.configdata.otherreward["1"].quality )].extra
            local lootreward = ui.getTableFromStr(lootconfig)

            self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.2),CCCallFunc:create(function()

                for k=1,3 do
                    if i~=k then
                        self:fanpai(k,lootreward[math.random(1,#lootreward)])
                    end
                end
            end)))
            if guide.controller then
                guide.controller:UIComplete(8080)
            end
        end, CCControlEventTouchUpInside)
    end
end

--function robresult.createRewardItems(self)
--    print("...i...am...createRewardItems.....")
--
--    self.rewardOneNode, self.rewardOneItem = CCBReaderLoad("rub/cell_fanpaizi.ccbi", nil, true, "cell_fanpaiziOne")
--    self.rewardTwoNode, self.rewardTwoItem = CCBReaderLoad("rub/cell_fanpaizi.ccbi", nil, true, "cell_fanpaiziTwo")
--    self.rewardThreeNode, self.rewardThreeItem = CCBReaderLoad("rub/cell_fanpaizi.ccbi", nil, true, "cell_fanpaiziThree")
--
--    self.rootItems.oneRewardNode:addChild(self.rewardOneNode)
--    self.rootItems.twoRewardNode:addChild(self.rewardTwoNode)
--    self.rootItems.threeRewardNode:addChild(self.rewardThreeNode)
--
--    -- 翻牌响应事件
--
--
--    self.rewardOneItem.touchBtn:setSwallowsTouch(true)
--    self.rewardOneItem.touchBtn:setTouchPriority(self.touchPriority)
--    self.rewardOneItem.touchBtn:addHandleOfControlEvent(function()
--        print("i..am...rewardOneItem..")
--        self.oneState = true
--        self.twoState = false
--        self.threeState = false
--        self:setEnabledFalse()
--
--        printT(self.configdata.otherreward)
--        ui.setNewIcon(self.rewardOneItem,self.configdata.otherreward)
--        self:fanpaiOne()
--
--    end, CCControlEventTouchUpInside)
--
--    self.rewardTwoItem.touchBtn:setSwallowsTouch(true)
--    self.rewardTwoItem.touchBtn:setTouchPriority(self.touchPriority)
--    self.rewardTwoItem.touchBtn:addHandleOfControlEvent(function()
--        print("i..am..rewardTwoItem..")
--        self.oneState = false
--        self.twoState = true
--        self.threeState = false
--        self:setEnabledFalse()
--
--        printT(self.configdata.otherreward)
--        ui.setNewIcon(self.rewardTwoItem,self.configdata.otherreward)
--        self:fanpaiTwo()
--
--    end, CCControlEventTouchUpInside)
--
--    self.rewardThreeItem.touchBtn:setSwallowsTouch(true)
--    self.rewardThreeItem.touchBtn:setTouchPriority(self.touchPriority)
--    self.rewardThreeItem.touchBtn:addHandleOfControlEvent(function()
--        print("i..am..rrewardThreeItem..")
--        self.oneState = false
--        self.twoState = false
--        self.threeState = true
--        self:setEnabledFalse()
--
--        printT(self.configdata.otherreward)
--        ui.setNewIcon(self.rewardThreeItem,self.configdata.otherreward)
--        self:fanpaiThree()
--
--    end, CCControlEventTouchUpInside)
--
--end
--
--function robresult.setEnabledFalse(self)
--    self.rewardOneItem.touchBtn:setEnabled(false)
--    self.rewardTwoItem.touchBtn:setEnabled(false)
--    self.rewardThreeItem.touchBtn:setEnabled(false)
--end
--
--function robresult.fanpaiOne(self)
--    local animationManager = getAnimationManager(self.rewardOneItem)
--    animationManager:setAnimationCompletedCallback(function()
--        if self.oneState then
--            local rewarddata = ui.IDconfig(self.configdata.otherreward.cid)
--            self.rewardOneItem.propNameLabel:setString(rewarddata.name)
--
--            self:fanpaiTwo()
--            self:fanpaiThree()
--        else
--            print("设置随机图片")
--        end
--
--    end)
--    animationManager:runAnimationsForSequenceNamed("fanpai")
--end
--function robresult.fanpaiTwo(self)
--    local animationManager = getAnimationManager(self.rewardTwoItem)
--    animationManager:setAnimationCompletedCallback(function()
--        if self.twoState then
--            local rewarddata = ui.IDconfig(self.configdata.otherreward.cid)
--            self.rewardTwoItem.propNameLabel:setString(rewarddata.name)
--
--            self:fanpaiOne()
--            self:fanpaiThree()
--        else
--            print("设置随机图片")
--        end
--
--    end)
--    animationManager:runAnimationsForSequenceNamed("fanpai")
--end
--function robresult.fanpaiThree(self)
--    local animationManager = getAnimationManager(self.rewardThreeItem)
--    animationManager:setAnimationCompletedCallback(function()
--        if self.threeState then
--            local rewarddata = ui.IDconfig(self.configdata.otherreward.cid)
--            self.rewardThreeItem.propNameLabel:setString(rewarddata.name)
--
--            self:fanpaiOne()
--            self:fanpaiTwo()
--        else
--            print("设置随机图片")
--        end
--
--    end)
--    animationManager:runAnimationsForSequenceNamed("fanpai")
--end

function robresult.reload(self,data,callback)
    self.callback = callback

    if data.index == "fail" then
        setSpriteFrameByName(self.rootItems.sprite, "obj_zi_shibai")
    elseif data.index == "lost" then
        setSpriteFrameByName(self.rootItems.sprite, "obj_zi_yihan")
    end

    -- ui.setLabelString(self.rootItems.conceltext,"返 回",19)
    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","fanhui"),19)
    self.rootItems.concel:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("robresult")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.retrytext,"再 战",19)
    ui.setLabelString(self.rootItems.retrytext,gameConfig.strings:string_common("popups","zaizhan"),19)
    self.rootItems.retry:addHandleOfControlEvent(function()
        UIRequest(data.data.request)
        gameWindows:closeWindowDirect("robresult")
    end, CCControlEventTouchUpInside)
    self.rootItems.retry:setSwallowsTouch(true)
    self.rootItems.retry:setTouchPriority(self.touchPriority)
end

function robresult.tenReload(self)

    ui.setLabelString(self.rootItems.lookRewardBtn_Text,nil,19)
    self.rootItems.lookRewardBtn:setSwallowsTouch(true)
    self.rootItems.lookRewardBtn:setTouchPriority(self.touchPriority)
    self.rootItems.lookRewardBtn:addHandleOfControlEvent(function()
        print("i..am..remove..robresult..")
        gameWindows:closeWindowDirect("robresult")
        gameWindows:openWindow("robresultreward",{data = self.configdata},nil)
    end, CCControlEventTouchUpInside)

    
    if self.configdata.get then
        -- 如果抢到碎片 就关闭 选择对手页面
        gameWindows:closeWindowDirect("robselect")

        self.rootItems.rewardDescNode:setVisible(true)
        self.rootItems.successFontNode:setVisible(true)
        self.rootItems.failFontNode:setVisible(false)

        local getdata = ui.IDconfig(self.configdata.get.cid)
        getname = getdata.name

        
        local numT = table.getTableLength(self.configdata.rob)
        self.rootItems.getnum:setString(numT)

        ui.setLabelString(self.rootItems.rewardUpName,getname,7)
        ui.setLabelString(self.rootItems.rewardDownName,getname,7)

        -- self.rootItems.rewardUpName:setString(getname)
        -- self.rootItems.rewardDownName:setString(getname)
    else
        self.rootItems.rewardDescNode:setVisible(false)
        self.rootItems.successFontNode:setVisible(false)
        self.rootItems.failFontNode:setVisible(true)
    end

    self:createList()

end

function robresult.createList(self)
    print("createPropsList")
    printT(self.configdata)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 260)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("rub/cell_tenjiesuan", nil, true, "cell_tenjiesuan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                -- ui.tableviewAnimation(self.ListTableView,cellCCB,920/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local config = {}
            if self.configdata.rob[tostring(a1+1)] and self.configdata.rob[tostring(a1+1)].num > 0 then
                config = self.configdata.rob[tostring(a1+1)]
                setSpriteFrameByName(ccbDocumentControler.getCoinTenSprite, "duobaobi")
            else
                config = self.configdata.coin[tostring(a1+1)]
                setSpriteFrameByName(ccbDocumentControler.getCoinTenSprite, "propcoin")
            end
            -- local numString = "第"..(a1+1).."次"
            local numString = gameConfig.strings:numci(a1+1)

            ccbDocumentControler.lineNumLabel:setString(numString)
            -- ccbDocumentControler.getCoinNumLabel:setString(config.num)
            ui.setLabelString(ccbDocumentControler.getCoinNumLabel,config.num or 0,13)


            local data = self.configdata.otherreward[tostring(a1+1)]
            if data and ui.IDconfig(data.cid) then
                ccbDocumentControler.getNode:setVisible(true)
                ccbDocumentControler.rewardUpName:setString(ui.IDconfig(data.cid).name)
            else
                ccbDocumentControler.getNode:setVisible(false)
            end
            cellCCB:setPosition(920/2,260/2)


            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.configdata.rob)
        elseif fn == "cellTouched" then
            -- GameScene:shiftLayerById(self.config[tostring(a1:getIdx()+1)].systemid)
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listScroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function robresult.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    GameScene:coin_effect(1,540,960,0.5)

    if self.callback then
        self.callback()
    end
end

return robresult�A  