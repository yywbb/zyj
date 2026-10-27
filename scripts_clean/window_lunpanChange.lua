
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local lunpanChange = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    RewarChangeTableView = nil,

    isscrolltouched = false,
}


function lunpanChange.open(self,touchPriority,data,callback)
    -- print("i...am...open...")
    -- print(data)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    

    if data.index == "change" then
        -- print("achievement===")
        self.rootNode, self.rootItems = CCBReaderLoad("activityduanwu/activityduanwu_duihuan", nil, true, "lunpan_duihuan")
        
        self:changeinit(data.data)
    else
        self.rootNode, self.rootItems = CCBReaderLoad("activityduanwu/lunpan_rule", nil, true, "lunpan_rule")
        self:tishiinit()
    end

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","lunpanChange",touchbegin)
    local function touchend(pos)
        if self.rootItems.listscroll and ui.isTouched(self.rootItems.listscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","lunpanChange",touchend)

    self.root:addChild(self.rootNode)
    return self.root
end



function lunpanChange.tishiinit(self)
    print("i...am...tishiinit...")

    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("lunpanchange")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

end



function lunpanChange.changeinit(self,data)
    print("i...am...changeinit...")
    if not data then return end

    self.data = data


    ui.setLabelString(self.rootItems.scoreText, nil, 14)
    ui.setLabelString(self.rootItems.scoreLabel, self.data, 21)


    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("lunpanchange")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self.changeData = gamedata.config.dragonBoatCarnival_exchange


    print("test1111")


    if self.RewarChangeTableView == nil then
        self:createRewardChangeList()
    else
        self.RewarChangeTableView:reloadData()
    end

end



function lunpanChange.createRewardChangeList(self)
    local celldict = {}
    local totalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(940, 190)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityduanwu/cell_jifenduihuan.ccbi", nil, true, "cell_jifenduihuan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end


            -- print("achievementlist:=",a1+1)
            local celldata = self.changeData[tostring(a1+1)]

            local spenddata = ui.getIDandNUMs(celldata.number)
            local rewarddata = ui.getIDandNUMs(celldata.reward)
            local rewarddataconfig = ui.IDconfig(rewarddata[1]["cid"])

            print("item1111",a1+1)
            ui.setLabelString(ccbDocumentControler.itemnameLabel, (rewarddataconfig.name or ""),14)
            ui.setLabelString(ccbDocumentControler.scoreText, nil,14)
            ui.setLabelString(ccbDocumentControler.scoreLabel, (spenddata[1].num or ""),21)
            


            print("item222",a1+1)
            ui.setNewIcon(ccbDocumentControler,{cid=rewarddata[1]["cid"],num=rewarddata[1]["num"]})


            print("item333",a1+1)


            if  spenddata[1].num > self.data then
                ui.addGray("CCControlButton",ccbDocumentControler.changeBtn)
                ui.addGray("CCLabelTTF",ccbDocumentControler.changeText)
            else

                ui.removeGray("CCControlButton",ccbDocumentControler.changeBtn)
                ui.removeGray("CCLabelTTF",ccbDocumentControler.changeText)
            end

            ccbDocumentControler["i_button"]:setTouchPriority(self.touchPriority)
            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                print("i_button=")   
                ui.setPopwindowByCid(rewarddata[1].cid)
                -- GameScene:shiftLayerById(185)
            end, CCControlEventTouchUpInside)

            
            ui.setLabelString(ccbDocumentControler.changeText,nil,18)
            ccbDocumentControler.changeBtn:setTouchPriority(self.touchPriority)
            ccbDocumentControler.changeBtn:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                -- print("changeBtn===is")
                if spenddata[1].num > self.data then
                    -- runGamePrompt({msg = "积分不足，不能兑换"})
                    runGamePrompt({msg = gameConfig.strings:string_common("lunpan",2)})
                else
                    -- runGamePrompt({msg = "成就已达成，可以领取"})
                    local cb = function( num )
                        UIRequest({type = 3302, id = a1+1,spendscore=spenddata[1].num ,num = num})
                    end
                    ui.exchangeMore(cb,math.floor(self.data/spenddata[1].num))
                end
            end, CCControlEventTouchUpInside)

            
            -- cellCCB:setScale(0.93)
            cellCCB:setPosition(960/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.changeData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.RewarChangeTableView = ui.createLuaTableView({
        handle = totalListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.RewarChangeTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listscroll:addChild(self.RewarChangeTableView)
end


function lunpanChange.close(self)
    gameTouch:UnrigistFunc("begin","lunpanChange")
    gameTouch:UnrigistFunc("end","lunpanChange")    
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.RewarChangeTableView = nil
end

return lunpanChange