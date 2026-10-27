--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

-- 活动副本一键完成功能，海外版未开

local activity = {
    rootNode = nil,
    rootItems = nil,
    cellSize = {width = 920,height = 230},
    png = {
    	[1] = "cell_yinbi.png",
    	[2] = "cell_jingyan.png",
    },
    cellNum = 0,
    isscrolltouched = false,
    listTableView = nil,
}

function activity.open(self,touchPriority,data,callback)
    -- printT(data,"data =======")
    -- printT(GameScene.vipstatus,"vipstatus")
    self.rootNode, self.rootItems = CCBReaderLoad("copy2/copy2_xuanze", nil, true, "activity")
    self.touchPriority = touchPriority
    self.data = data
    if tonumber(data["function"]) == 1 then
    	self.configData = gamedata.config.exp_copy
    elseif tonumber(data["function"]) == 2 then
    	self.configData = gamedata.config.coin_copy
    elseif tonumber(data["function"]) == 3 then
        self.configData = gamedata.config.stone_copy
    elseif tonumber(data["function"]) == 4 then
        self.configData = gamedata.config.upstar_huodong
    elseif tonumber(data["function"]) == 5 then
        self.configData = gamedata.config.zhenfu_huodong
    elseif tonumber(data["function"]) == 6 then
        self.configData = gamedata.config.forging_copy
    end
    printT(self.configData,"==============")
    self.rootItems.closeButton:setTouchPriority(self.touchPriority) 
    self.rootItems.closeButton:addHandleOfControlEvent(function()
    	gameWindows:closeWindow("copyacivity")
    end, CCControlEventTouchUpInside)  

    ui.setLabelString(self.rootItems.timestext,nil,22)
    -- print("times===",self.data.times,data.usedTimes,GameScene.vipstatus.exp_copy_times,(self.data.times - data.usedTimes+GameScene.vipstatus.exp_copy_times))
    local buynum = 0
    if tonumber(data["function"]) == 1 then
        buynum = GameScene.vipstatus.exp_copy_times
    elseif tonumber(data["function"]) == 2 then
        buynum = GameScene.vipstatus.coin_copy_times
    elseif tonumber(data["function"]) == 3 then
        buynum = GameScene.vipstatus.stone_copy_times
    elseif tonumber(data["function"]) == 4 then
        buynum = GameScene.vipstatus.upstar_times
    elseif tonumber(data["function"]) == 5 then
        buynum = GameScene.vipstatus.zhenfu_times
    elseif tonumber(data["function"]) == 6 then
        buynum = GameScene.vipstatus.forging_copy_times
    end

    if self.data.times - data.usedTimes+buynum <= 0 then
        ui.setLabelString(self.rootItems.times,0,24)
        print("num<=0")
    else
        ui.setLabelString(self.rootItems.times,(self.data.times - data.usedTimes+buynum ),22)
        -- ui.setLabelString(self.rootItems.times,(self.data.times - data.usedTimes+GameScene.vipstatus.personalboss_times),22)
    end

    --
    if self.rootItems.desc2 and self.rootItems.desc1 then
        if tonumber(data["function"]) == 4 or tonumber(data["function"]) == 5 or tonumber(data["function"]) == 2 then
            self.rootItems.desc2:setString(gameConfig.strings:string_common("fixedString","kingman",11))
            self.rootItems.desc1:setString(gameConfig.strings:string_common("fixedString","kingman",10))
        else
            self.rootItems.desc2:setString(gameConfig.strings:string_common("fixedString","kingman",12))
            self.rootItems.desc1:setString(gameConfig.strings:string_common("fixedString","kingman",6))
        end
    end
    --

    self.rootItems.addTimes:setTouchPriority(self.touchPriority) 
    self.rootItems.addTimes:addHandleOfControlEvent(function()
        if tonumber(data["function"]) == 1 then
            activityExpBuyTimes()
        elseif  tonumber(data["function"]) == 2 then
            activityCoinBuyTimes()
        elseif tonumber(data["function"]) == 3 then
            if GameScene.roleinfo.level >= self.configData[tostring(1)].monster_level  then
                activityForgeStoneBuyTimes()
            else
                runGamePrompt({msg = self.configData[tostring(1)].monster_level.."级开启"})
            end
        elseif tonumber(data["function"]) == 4 then
            if GameScene.roleinfo.level >= self.configData[tostring(1)].monster_level  then
                activityEquipStarBuyTimes()
            else
                runGamePrompt({msg = self.configData[tostring(1)].monster_level.."级开启"})
            end
        elseif tonumber(data["function"]) == 5 then
            if GameScene.roleinfo.level >= self.configData[tostring(1)].monster_level  then
                activityZhenfuBuyTimes()
            else
                runGamePrompt({msg = self.configData[tostring(1)].monster_level.."级开启"})
            end
        elseif tonumber(data["function"]) == 6 then
            if GameScene.roleinfo.level >= self.configData[tostring(1)].monster_level  then
                activityForgingBuyTimes()
            else
                runGamePrompt({msg = self.configData[tostring(1)].monster_level.."级开启"})
            end
        end
    end, CCControlEventTouchUpInside) 
    if tonumber(data["function"]) == 3 and GameScene.roleinfo.level < self.configData[tostring(1)].monster_level then
        ui.addGray("CCControlButton",self.rootItems.addTimes)
    else
        ui.removeGray("CCControlButton",self.rootItems.addTimes)
    end    


    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","copy_activity",touchbegin)
    local function touchend(pos)
        if self.rootItems.cellscroll and ui.isTouched(self.rootItems.cellscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","copy_activity",touchend)
    
    self.listTableView = nil
    self:createActivityList()
    
    return self.rootNode	
end

function activity.close(self)
    gameTouch:UnrigistFunc("begin","copy_activity")
    gameTouch:UnrigistFunc("end","copy_activity")
    self.isscrolltouched = false
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.cellNum = 0
    self.listTableView = nil 
end

function activity.createActivityList( self )
    local celldict = {}
    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.width, self.cellSize.height)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("copy2/cell_dengji.ccbi", nil, true, "cell_level")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            cellCCB:setPosition(self.cellSize.width/2, self.cellSize.height/2)         
           	self:setCell(ccbDocumentControler,a1)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = self.data.openLevel < table.getTableLength( self.configData ) and  self.data.openLevel + 1 or table.getTableLength( self.configData ) 
            self.cellNum = r 
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.cellscroll:getContentSize().width,
        viewheight = self.rootItems.cellscroll:getContentSize().height,
        dire = 1
    })
    self.listTableView:setTouchPriority(self.touchPriority)
    self.rootItems.cellscroll:addChild(self.listTableView)	
end


function activity.setCell( self,aiCell,aiIndex )
	-- print("activity.setCell ============")
	print(aiIndex)
	printT(self.data)
    printT(self.configData)
    -- 双倍掉落判断
    if aiCell.isrewarddouble then
        local datatmp = ui.CheckHuodongByParam(6)
        -- local datatmp = ui.CheckHuodongByParam(1)
        -- local timesnum = ui.GetHuodongModulus(6)
        if datatmp then
            aiCell.isrewarddouble:setVisible(true)
            -- local doublestring = "("..gameConfig.strings:cutOff( timesnum*10 )..")"
            ui.setLabelString(aiCell.isrewarddouble, gameConfig.strings:string_common("doublereward",1), 24)
        else
            aiCell.isrewarddouble:setVisible(false)
        end
    end

    local tData = nil
    local lowGradeName = nil
    if self.configData[tostring(self.data.openLevel - aiIndex )] ~= nil then
        lowGradeName = self.configData[tostring(self.data.openLevel - aiIndex)].name
    else
        lowGradeName = self.configData[tostring(1)].name
    end     
    if self.data.openLevel >= table.getTableLength( self.configData ) then
        tData = self.configData[tostring(self.data.openLevel - aiIndex)]
    else
	    tData = self.configData[tostring(self.data.openLevel + 1 - aiIndex)]      
    end
	aiCell.leveltext:setString(tData.name)
    aiCell.level:setString(tData.monster_level.."级可进入")
    if GameScene.roleinfo.level < tData.monster_level then
        ui.addGray("CCLabelBMFont",aiCell.leveltext)
    else
        ui.removeGray("CCLabelBMFont",aiCell.leveltext)
    end

    if self.data.openLevel < tData.id then
        ui.addGray("CCSprite",aiCell.fight)
    else
        ui.removeGray("CCSprite",aiCell.fight)
    end 
    aiCell.lookitem:setSwallowsTouch(true)
    aiCell.lookitem:setTouchPriority(self.touchPriority-1)
    aiCell.lookitem:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling  then return end
        print("查看掉了")
        local datatmp = ui.CheckHuodongByParam(6)
        -- local datatmp = ui.CheckHuodongByParam(1)

        gameWindows:openWindow("copyacivityitem",{self.data,tData,isrewarddouble = datatmp})
    end, CCControlEventTouchUpInside)

    aiCell.button:setTouchPriority(self.touchPriority)
    aiCell.onekey:setSwallowsTouch(true)
    aiCell.onekey:setTouchPriority(self.touchPriority-1)
    if tData.id <= self.data.openLevel then
        aiCell.onekey:setVisible(true)
    else
        aiCell.onekey:setVisible(false)
    end
    if tonumber(self.data.aid) == 1 then
        --setSpriteFrameByName(aiCell.bg,self.png[1])
        aiCell.bg1:setVisible(true)
        aiCell.bg2:setVisible(false)
        aiCell.bg3:setVisible(false)
        aiCell.bg4:setVisible(false)
        aiCell.bg5:setVisible(false)
        aiCell.bg6:setVisible(false)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling  then return end
            print("挑战经验副本333")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.exp_copy_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityExpBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id  then
                runGamePrompt({msg = "请先挑战过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1342,id = tData.id})
                print("UIRequest.1342")
            end
        end, CCControlEventTouchUpInside)
        --
        aiCell.onekey:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling  then return end
            print("挑战经验副本onekey")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.exp_copy_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityExpBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id  then
                runGamePrompt({msg = "请先挑战过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1346,aid = tonumber(self.data.aid), id = tData.id})
            end
        end, CCControlEventTouchUpInside)

    elseif tonumber(self.data.aid) == 2 then
        --setSpriteFrameByName(aiCell.bg,self.png[2])
        aiCell.bg1:setVisible(false)
        aiCell.bg2:setVisible(true)
        aiCell.bg3:setVisible(false)
        aiCell.bg4:setVisible(false)
        aiCell.bg5:setVisible(false)
        aiCell.bg6:setVisible(false)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战银币副本")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.coin_copy_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityCoinBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id then
                runGamePrompt({msg = "需100%伤害通过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1341,id = tData.id})
            end
        end, CCControlEventTouchUpInside)
        --
        aiCell.onekey:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战银币副本onekey")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.coin_copy_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityCoinBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id then
                runGamePrompt({msg = "需100%伤害通过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1346,aid = tonumber(self.data.aid), id = tData.id})
            end
        end, CCControlEventTouchUpInside)
    elseif tonumber(self.data.aid) == 3 then
        aiCell.bg1:setVisible(false)
        aiCell.bg2:setVisible(false)
        aiCell.bg3:setVisible(true)
        aiCell.bg4:setVisible(false)
        aiCell.bg5:setVisible(false)
        aiCell.bg6:setVisible(false)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战锻造石副本")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.stone_copy_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityForgeStoneBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id then
                runGamePrompt({msg = "请先挑战过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1343,id = tData.id})
            end
        end, CCControlEventTouchUpInside)
        --
        aiCell.onekey:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战锻造石副本onekey")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.stone_copy_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityForgeStoneBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id then
                runGamePrompt({msg = "请先挑战过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1346,aid = tonumber(self.data.aid), id = tData.id})
            end
        end, CCControlEventTouchUpInside)
    elseif tonumber(self.data.aid) == 4 then
        aiCell.bg1:setVisible(false)
        aiCell.bg2:setVisible(false)
        aiCell.bg3:setVisible(false)
        aiCell.bg4:setVisible(true)
        aiCell.bg5:setVisible(false)
        aiCell.bg6:setVisible(false)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战升星石副本")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.upstar_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityEquipStarBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id then
                runGamePrompt({msg = "需100%伤害通过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1344,id = tData.id})
            end
        end, CCControlEventTouchUpInside)
        --
        aiCell.onekey:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战升星石副本onekey")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.upstar_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityEquipStarBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id then
                runGamePrompt({msg = "需100%伤害通过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1346,aid = tonumber(self.data.aid), id = tData.id})
            end
        end, CCControlEventTouchUpInside)
    elseif tonumber(self.data.aid) == 5 then
        aiCell.bg1:setVisible(false)
        aiCell.bg2:setVisible(false)
        aiCell.bg3:setVisible(false)
        aiCell.bg4:setVisible(false)
        aiCell.bg5:setVisible(true)
        aiCell.bg6:setVisible(false)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战阵符副本")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.zhenfu_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityZhenfuBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id then
                runGamePrompt({msg = "需100%伤害通过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1345,id = tData.id})
            end
        end, CCControlEventTouchUpInside)
        --
        aiCell.onekey:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战阵符副本onekey")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.zhenfu_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityZhenfuBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id then
                runGamePrompt({msg = "需100%伤害通过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1346,aid = tonumber(self.data.aid), id = tData.id})
            end
        end, CCControlEventTouchUpInside)
    elseif tonumber(self.data.aid) == 6 then
        aiCell.bg1:setVisible(false)
        aiCell.bg2:setVisible(false)
        aiCell.bg3:setVisible(false)
        aiCell.bg4:setVisible(false)
        aiCell.bg5:setVisible(false)
        aiCell.bg6:setVisible(true)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战淬灵石副本")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.forging_copy_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityForgingBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id then
                runGamePrompt({msg = "请先挑战过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1347,id = tData.id})
            end
        end, CCControlEventTouchUpInside)
        --
        aiCell.onekey:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战淬灵石副本onekey")
            if self.data.usedTimes >= (self.data.times+GameScene.vipstatus.forging_copy_times) then
                runGamePrompt({msg = "您没有挑战次数了！"})
                activityForgingBuyTimes()
            elseif GameScene.roleinfo.level < tData.monster_level then
                runGamePrompt({msg = "等级不足"})
            elseif self.data.openLevel < tData.id then
                runGamePrompt({msg = "请先挑战过"..lowGradeName})
            else
                gameTouch:clickprofbytime(1.5)
                UIRequest({type = 1346,aid = tonumber(self.data.aid), id = tData.id})
            end
        end, CCControlEventTouchUpInside)
    end 
end

function activity.activityReload(self,aiData,pass)
    self.data = aiData
    -- print("refresh")
    -- printT(GameScene.vipstatus,"vipstatus,refresh")

    local delay = 0
    if self.rootItems.passeffect then
        self.rootItems.passeffect:removeAllChildrenWithCleanup(true)
        if pass and pass == 1 then
            gameTouch:clickprofbytime(2)
            delay = 1
            local ccbnode,ccbitem = CCBReaderLoad("copy2/copyfinish", nil, true, "copyfinish")
            self.rootItems.passeffect:addChild(ccbnode)
        end
    end

    local dofunc = function()
        local buynum = 0
        if tonumber(aiData["function"]) == 1 then
            buynum = GameScene.vipstatus.exp_copy_times
        elseif  tonumber(aiData["function"]) == 2 then
            buynum = GameScene.vipstatus.coin_copy_times
        elseif  tonumber(aiData["function"]) == 3 then
            buynum = GameScene.vipstatus.stone_copy_times
        elseif  tonumber(aiData["function"]) == 4 then
            buynum = GameScene.vipstatus.upstar_times
        elseif  tonumber(aiData["function"]) == 5 then
            buynum = GameScene.vipstatus.zhenfu_times
        elseif  tonumber(aiData["function"]) == 6 then
            buynum = GameScene.vipstatus.forging_copy_times
        end

        if self.data.times - aiData.usedTimes+buynum <= 0 then
            ui.setLabelString(self.rootItems.times,0,24)
        else
            -- print("fun1,tiems===",self.data.times,aiData.usedTimes,buynum,(self.data.times - aiData.usedTimes+buynum ))
            ui.setLabelString(self.rootItems.times,(self.data.times - aiData.usedTimes+buynum ),22)
            -- ui.setLabelString(self.rootItems.times,(self.data.times - aiData.usedTimes),22)
        end
        self.listTableView:reloadData()
        self.listTableView:setLuaContentOffset(0, self.rootItems.cellscroll:getContentSize().height - self.cellNum *self.cellSize.height)
    end

    if delay > 0 then
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.5),CCCallFunc:create(function()
            dofunc()
        end)))
    else
        dofunc()
    end
end
return activity  ^a  