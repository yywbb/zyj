
local zhounian = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    buttontouch = -1,

    pages = {"pray","task"},
    selectpage = "pray",

    tasks = {},
    tasklistview = nil,

    yulanindex = 0,
    yulanConfig = {},

    general1ccb = nil,
    general1item = nil,

    general2ccb = nil,
    general2item = nil,

    jiasu = false,
    wheelnum = 0,
    rollindex = 1,

    addSpeed = 30,

    isfirst = 0,
    isfirstshowGeneral = 0,

    --主界面Icon
    mainIcon = "b_n_mainicon_zhounianshengdian"
}

function zhounian.shiftPage(self,type)
    self.selectpage = type or self.selectpage

    for k,v in ipairs(self.pages) do
        self.rootItems[v.."node"]:setVisible(v == self.selectpage)
        self.rootItems[v.."node"]:setPositionX(v == self.selectpage and 0 or 1280)
    end

    if self.selectpage == "pray" then
        self.rootItems.generalscroll:setVisible(true)
        if self.main.randomCid > 0 then
            self.rootItems.selectGeneralNode:setVisible(true)
        end
    else
        self.rootItems.generalscroll:setVisible(false)
        self.rootItems.selectGeneralNode:setVisible(false)
    end
end

function zhounian.init(self,parent,toppos,params)
    self.rootNode,self.rootItems = CCBReaderLoad("7zhounian/7zhounian", nil, true, "7zhounian")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.animationManager = getAnimationManager(self.rootItems)
        
    self.rootItems.topnode:setPositionY((toppos-1620)*0.6+1920)

    for k,v in ipairs(self.pages) do
        self.rootItems[v.."shift"]:setSwallowsTouch(true)
        self.rootItems[v.."shift"]:setTouchPriority(self.buttontouch-2)
        self.rootItems[v.."shift"]:addHandleOfControlEvent(function()
            if self.jiasu then
                return
            end
            self:shiftPage(v)
        end, CCControlEventTouchUpInside)
    end

    self.rootItems.bufferbutton:setSwallowsTouch(true)
    self.rootItems.bufferbutton:setTouchPriority(self.buttontouch-2)
    self.rootItems.bufferbutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("zhounianbuff")
    end, CCControlEventTouchUpInside)
    --许愿
    self.rootItems.praybutton:setSwallowsTouch(true)
    self.rootItems.praybutton:setTouchPriority(self.buttontouch-2)
    self.rootItems.praybutton:addHandleOfControlEvent(function()
        if self.main.status == 2 then
            runGamePrompt({msg = gameConfig.strings:string_common("activity_zhounian",21)})
        else
            self:runActionGaneralSelect(0)
        end
    end, CCControlEventTouchUpInside)
    --刷新
    self.rootItems.resetbutton:setSwallowsTouch(true)
    self.rootItems.resetbutton:setTouchPriority(self.buttontouch-4)
    self.rootItems.resetbutton:addHandleOfControlEvent(function()
        if self.main.status == 2 then
            runGamePrompt({msg=gameConfig.strings:string_common("activity_zhounian",21)})
        else
            if self.main and self.main.cid > 0 then
            else
                runGamePrompt({msg="请先许愿"})
                return
            end

            local cando = false
            for k,v in pairs(self.tasks) do
                if v.status==0 then
                    cando = true
                    break
                end
            end
            if cando then
                local cost = self:getBuyPrice("Anniversary_consume", self.main.freshtimes+1)
                if cost > GameScene.roleinfo.gold then
                    shortGold()
                else
                    UIRequest({type = 5314})
                end
            else
                runGamePrompt({msg = gameConfig.strings:string_common("activity_zhounian", 16)})
            end
        end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.luckdes1,"当前许愿值",14)
    ui.setLabelString(self.rootItems.luckdes2,"完成任务可提升许愿值！",13)    

    local tiemconfig = gamedata.config.peak_time["6"]
    if tiemconfig and tiemconfig ~= "" then
        local endString = "许愿结束时间:"..ui.getDateDesc2(tiemconfig["end"]).."0时"
        local awardString = "发奖时间:"..ui.getDateDesc2(tiemconfig["end"]).."0时".."-"..ui.getDateDesc2(tiemconfig["award"]).."0时"

        if self.rootItems.activity_end_time then
            self.rootItems.activity_end_time:setString(endString)
            ui.setLabelString(self.rootItems.activity_end_time,nil,22)
        end
        if self.rootItems.task_end_time then
            self.rootItems.task_end_time:setString(awardString)
            ui.setLabelString(self.rootItems.task_end_time,nil,22)
        end

    end
    local month,day = tonumber(string.sub(tiemconfig["end"],5,6)),tonumber(string.sub(tiemconfig["end"],7,8))

    local str = "活动期间大人可以在本界面点击“我要许愿”，选择心仪的武将参与许愿，许愿后可获得“许愿BUFF”并有几率获得许愿武将，幸运值越高获得许愿武将的几率越高。许愿奖励将于"..month.."月"..day.."日".."发放，并且还有“许愿礼包”相送！"
    self.rootItems.timeDes:setString(str)

    self.yulanConfig = gamedata.config.Anniversary_reward or {}

    self.rootItems.generalscroll:setTouchEnabled(false)

    UIRequest({type = 5310})

end

function zhounian.getBuyPrice( self,key,count )
    local config = gamedata.config.buycount_price
    return config[tostring(count)] and config[tostring(count)][key] or config[tostring(table.getTableLength(config))][key]
end

function zhounian.reload( self,data )
    local main = data.data.main
    local tasks = data.data.tasks
    local taskreward  = data.data.taskreward
    local totalreward  = data.data.totalreward

    if main then
        if main.randomCid and main.randomCid > 0 then
            self.rootItems.selectGeneralNode:setVisible(true)
            self.rootItems.prayNode:setVisible(false)
            self.rootItems.doNode1:setVisible(true)
            self.rootItems.doNode2:setVisible(true)
            self.rootItems.doubleNode:setVisible(false)
            print("isfirstshowGeneral = ",self.isfirstshowGeneral)
            if self.isfirstshowGeneral == 0 then
                print("展示随机的伙伴")
                self.rootItems.randomGeneral:removeAllChildrenWithCleanup(true)
                local general = gamedata.config.general[tostring(main.randomCid)]
                local generalName = gamedata.config.generalanimation[tostring(general.animationid)].name
                local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
                Gneral:setAnimation("stand",true,0)
                Gneral:setScale(1.4)
                self.rootItems.randomGeneral:addChild(Gneral)
                self.isfirstshowGeneral = 1
            end

            --确定
            ui.setLabelString(self.rootItems.doLab1, nil, 19)
            self.rootItems.doButton1:setSwallowsTouch(true)
            self.rootItems.doButton1:setTouchPriority(self.buttontouch-2)
            self.rootItems.doButton1:addHandleOfControlEvent(function()
                UIRequest({type = 5311, cid = main.randomCid}) --选择许愿伙伴
            end, CCControlEventTouchUpInside)
            --消费
            local length = tonumber(table.getTableLength(gamedata.config.buycount_price))
            local count = main.randomNum
            if count >= length then
                count = length
            end
            local price = 0
            if count > 0 then
                price = gamedata.config.buycount_price[tostring(count)].Anniversary_cost
                self.rootItems.totalprice:setString(price)
            end
            --更换
            ui.setLabelString(self.rootItems.doLab2, nil, 19)
            self.rootItems.doButton2:setSwallowsTouch(true)
            self.rootItems.doButton2:setTouchPriority(self.buttontouch-2)
            self.rootItems.doButton2:addHandleOfControlEvent(function()
                if price > GameScene.roleinfo.gold then
                    shortGold()
                else
                    if self.general1ccb == nil then
                        self:setyulan()
                    end
                    self:runActionGaneralSelect(1)
                end
            end, CCControlEventTouchUpInside)

            if main.cid and main.cid > 0 then
                self.rootItems.doNode1:setVisible(false)
                self.rootItems.doNode2:setVisible(false)
                self.rootItems.doubleNode:setVisible(true)
            end
        else
            print("伙伴预览 = ", self.isfirst)
            self.rootItems.doubleNode:setVisible(false)
            self.rootItems.selectGeneralNode:setVisible(false)
            if self.isfirst == 0 then
                self:setyulan()
                self.isfirst = 1
            end
        end

        local total = tonumber(gamedata.config.global_kv.Anniversary_lucky_growth.value)
        ui.setLabelString(self.rootItems.luckdes,main.luck.."/"..total,13) 
        ui.setSpriteTextureRect2(self.rootItems.luckbar,0,0,696 * ((main.luck > total) and 1 or (main.luck/total)),22)
        local persent = main.luck/total
        ui.setLabelString(self.rootItems.luckdes3,"25%",persent>=0.25 and 22 or 13)
        ui.setLabelString(self.rootItems.luckdes4,"50%",persent>=0.5 and 22 or 13)
        ui.setLabelString(self.rootItems.luckdes5,"75%",persent>=0.75 and 22 or 13)
        ui.setLabelString(self.rootItems.luckdes6,"100%",persent>=1 and 22 or 13)

        local cost = self:getBuyPrice("Anniversary_consume",main.freshtimes+1)
        ui.setLabelString(self.rootItems.freshcost,cost,cost<=GameScene.roleinfo.gold and 13 or 24) 

        local totaltasks = tonumber(gamedata.config.global_kv.Anniversary_task_times.value)
        ui.setLabelString(self.rootItems.taskleft,gameConfig.strings:string_common("activity_zhounian",7)..(totaltasks-main.tasktimes),14) 

        if data.ispray then
            self.rootItems.doubleNode:setVisible(true)
            self.animationManager:runAnimationsForSequenceNamed("play")
        elseif main.praystatus == 0 then
            self.rootItems.doubleNode:setVisible(false)
            self.animationManager:runAnimationsForSequenceNamed("free")
        else
            self.rootItems.doubleNode:setVisible(true)
            self.animationManager:runAnimationsForSequenceNamed("play3")
        end

        if main.status == 2 then
            ui.addGray("CCControlButton",self.rootItems.praybutton)
        else
            ui.removeGray("CCControlButton",self.rootItems.praybutton)
        end
    end

    if taskreward then
        showRewardPopupWindow(taskreward,nil)
        UIRequest({type = 1001})
        if main.luck > self.main.luck then
            runGamePrompt({msg = "许愿值+"..(main.luck - self.main.luck)})
        end        
    end
    self.main = main or self.main
    self:shiftPage()

    if tasks then
        self.tasks = tasks
        if not self.tasklistview then
            self:creatTaskList()
        else
            self.tasklistview:reloadData()
        end

        local hint = false
        for k,v in pairs(self.tasks) do
            if v.status==2 then
                hint = true
                break
            end
        end

        local totaltasks = tonumber(gamedata.config.global_kv.Anniversary_task_times.value)
        ui.sethint(self.rootItems.hint_task,hint and totaltasks > self.main.tasktimes)
    end

    if totalreward then
        showRewardPopupWindow(totalreward,nil)
        UIRequest({type = 1001})
    end

end

--
function zhounian.runActionGaneralSelect( self, isOne )
    gameTouch:clickprofbytime(5)
    self.rootItems.selectGeneralNode:setVisible(false)
    UIRequest({type = 5309, count = self.main.randomNum, isOne = isOne})
end

function zhounian.reloadRandomCid(self, data)
    self.randomCid = data.cid
    self.wheelnum = 0
    self.rollindex = 1

    self.rootItems.prayNode:setVisible(false)
    self.rootItems.selectGeneralNode:setVisible(false)
    self.general1ccb:setVisible(true)
    
    if self.jiasu then
        self.jiasu = false
    else
        self.jiasu = true
    end

    self.general1ccb:stopAllActions()
    self:repeataction(self.general1ccb, self.general1item)
    self.general2ccb:stopAllActions()
    self.general2ccb:setPosition(ccp(1600,5))

end

function zhounian.setOneyulan(self,ccb,item,pos)
    self.yulanindex = self.yulanindex +1
    if self.yulanindex > table.getTableLength(self.yulanConfig) then
        self.yulanindex = 1
    end
    print("yulanindex = ",self.yulanindex)
    if self.jiasu then
        if self.rollindex%7 == 0 then
            self.wheelnum = self.wheelnum + 1
        end
        self.rollindex = self.rollindex + 1
    end

    item.general:removeAllChildrenWithCleanup(true)
    local cid,num = ui.getIDandNUM(self.yulanConfig[tostring(self.yulanindex)].reward)
    local general = {}
    if self.wheelnum >= 2 then
        general = gamedata.config.general[tostring(self.randomCid)]
    else
        general = gamedata.config.general[tostring(cid)]
    end
    local generalName = gamedata.config.generalanimation[tostring(general.animationid)].name
    local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(1.4)

    item.general:addChild(Gneral)
    ccb:setPosition(pos)
end

function zhounian.repeataction(self,ccb,item)
    self:setOneyulan(ccb,item,ccp(-200,5))
    if self.wheelnum >= 2 then
        self.jiasu = false
        local first = CCMoveTo:create(1.2, ccp(540, 5))
        local sequence = CCSequence:createWithTwoActions(first, CCCallFunc:create(function()
            --
            UIRequest({type = 5310})
            ccb:stopAllActions()
            ccb:setVisible(false)
            self.rootItems.selectGeneralNode:setVisible(true)
            --展示随机的伙伴
            self.rootItems.randomGeneral:removeAllChildrenWithCleanup(true)
            local general = gamedata.config.general[tostring(self.randomCid)]
            local generalName = gamedata.config.generalanimation[tostring(general.animationid)].name
            local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            Gneral:setAnimation("stand",true,0)
            Gneral:setScale(1.4)
            self.rootItems.randomGeneral:addChild(Gneral)
        end))
        local backOut = CCEaseOut:create(sequence,1.2)
        ccb:runAction(backOut)
        return
    end

    if self.jiasu then
        local first = CCMoveTo:create(8, ccp(1280, 5))
        local sequence = CCSequence:createWithTwoActions(first, CCCallFunc:create(function()
            self:repeataction(ccb,item)
        end))
        ccb:runAction(CCSpeed:create(sequence, self.addSpeed))
    else
        local first = CCMoveTo:create(8, ccp(1280, 5))
        ccb:runAction(CCSequence:createWithTwoActions(first, CCCallFunc:create(function()
            self:repeataction(ccb,item)
        end)))
    end
end

function zhounian.setyulan(self)
    self.general1ccb, self.general1item = CCBReaderLoad("7zhounian/7zhounian_point", nil, true, "7zhounian_point")
    self.rootItems.container:addChild(self.general1ccb)
    self:setOneyulan(self.general1ccb, self.general1item, ccp(540,5))

    local first = CCMoveTo:create(4, ccp(1280, 5))
    self.general1ccb:runAction(CCSequence:createWithTwoActions(first, CCCallFunc:create(function()
         self:repeataction(self.general1ccb, self.general1item)
    end)))

    self.general2ccb, self.general2item = CCBReaderLoad("7zhounian/7zhounian_point", nil, true, "7zhounian_point")
    self.rootItems.container:addChild(self.general2ccb)
    self:repeataction(self.general2ccb, self.general2item)

end
--

function zhounian.creatTaskList( self )
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1060, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("2zhounian/cell_2zhounian", nil, true, "cell_2zhounian")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.tasks[a1+1] or self.tasks[tostring(a1+1)])

            cellCCB:setPosition(530, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.tasks)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.tasklistview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.tasklist:getContentSize().width,
        viewheight = self.rootItems.tasklist:getContentSize().height,
        dire = 1
    })
    self.rootItems.tasklist:addChild(self.tasklistview)
    self.tasklistview:setTouchPriority(self.buttontouch-2)
end

function zhounian.setCell( self,item,data )
    local config = gamedata.config.Anniversary_task[tostring(data.kind)][tostring(data.cid)]
    local icon = gamedata.config.Anniversary_weights[tostring(data.kind)].icon

    if config.type and tonumber(config.type) == 1 then
        item.desc:setString(config.description)
    else
        item.desc:setString(config.description.."("..data.process.."/"..config.attr..")")
    end

    ui.setNewIcon(item,{icon=icon})
    ui.setNewIcon(item,{icon="xingyunzhi",num=config.luck},1)

    local reward = ui.getIDandNUMs(config.reward)
    for i=1,4 do
        local v = reward[i]
        if v then 
            item["reward"..i]:setVisible(true)
            ui.setNewIcon(item,{cid=v.cid,num=v.num},i+1)
            item["i_button_"..i+1]:setSwallowsTouch(true)
            item["i_button_"..i+1]:setTouchPriority(self.buttontouch - 3)
            item["i_button_"..i+1]:addHandleOfControlEvent(function()
                if tonumber(v.cid == 1000) or tonumber(v.cid) == 1001 or tonumber(v.cid) == 70000 then
                    return
                end
                ui.setPopwindowByCid(v.cid)
            end, CCControlEventTouchUpInside)
        else
            item["reward"..i]:setVisible(false)
        end
    end
        

    item.getNode:setVisible(data.status == 0)
    item.rewardNode:setVisible(data.status == 2)
    item.ingNode:setVisible(data.status == 1)
    local totaltasks = tonumber(gamedata.config.global_kv.Anniversary_task_times.value)
    item.hintreward:setVisible(self.main.tasktimes<totaltasks)

    ui.setLabelString(item.gettext,gameConfig.strings:string_common("activity_zhounian",9),18)
    ui.setLabelString(item.rewardtext,gameConfig.strings:string_common("buttontext","lingqu"),18)
    ui.setLabelString(item.canceltext,gameConfig.strings:string_common("activity_zhounian",18),18)

    item.rewardbutton:setSwallowsTouch(true)
    item.rewardbutton:setTouchPriority(self.buttontouch-3)
    item.rewardbutton:addHandleOfControlEvent(function()
        local totaltasks = tonumber(gamedata.config.global_kv.Anniversary_task_times.value)
        if self.main.tasktimes>=totaltasks then
            runGamePrompt({msg = gameConfig.strings:string_common("activity_zhounian",19)})
        else
            UIRequest({type = 5313,id = data.iid})
        end
        
    end, CCControlEventTouchUpInside)

    if self.main.status == 2 then
        item.ing:setVisible(false)

        ui.addGray("CCControlButton",item.getbutton)
        ui.addGray("CCControlButton",item.cancelbutton)

        ui.setLabelString(item.gettext,"活动结束",18)
        ui.setLabelString(item.canceltext,"活动结束",18)

        item.getbutton:setSwallowsTouch(true)
        item.getbutton:setTouchPriority(self.buttontouch-3)
        item.getbutton:addHandleOfControlEvent(function()
            runGamePrompt({msg="活动已结束，无法接取和进行任务"})
        end, CCControlEventTouchUpInside)

        item.cancelbutton:setSwallowsTouch(true)
        item.cancelbutton:setTouchPriority(self.buttontouch-3)
        item.cancelbutton:addHandleOfControlEvent(function()
            runGamePrompt({msg="活动已结束，无法接取和进行任务"})
        end, CCControlEventTouchUpInside)
        return 

    else

        ui.removeGray("CCControlButton",item.getbutton)
        ui.removeGray("CCControlButton",item.cancelbutton)
        item.getbutton:setSwallowsTouch(true)
        item.getbutton:setTouchPriority(self.buttontouch-3)
        item.getbutton:addHandleOfControlEvent(function()
            if self.main and self.main.cid > 0 then
                UIRequest({type = 5312,id = data.iid})
            else
                runGamePrompt({msg="请先许愿"})
            end
        end, CCControlEventTouchUpInside) 

        item.cancelbutton:setSwallowsTouch(true)
        item.cancelbutton:setTouchPriority(self.buttontouch-3)
        item.cancelbutton:addHandleOfControlEvent(function()
            UIRequest({type = 5318,id = data.iid})
        end, CCControlEventTouchUpInside)
    end
end

function zhounian.UIUpdateData( self )
    UIRequest({type = 5310})
end


function zhounian.clear(self)
    print("zhounian - clear")
    self.selectpage = "pray"
    if self.general1ccb then
        self.general1ccb:stopAllActions()
        self.general1ccb = nil
        self.general1item = nil
    end
    if self.general2ccb then
        self.general2ccb:stopAllActions()
        self.general2ccb = nil
        self.general2item = nil
    end
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.tasklistview = nil
    self.tasks = {}

    self.yulanindex = 0
    self.yulanConfig = {}

    self.wheelnum = 0
    self.rollindex = 1
    self.jiasu = false
    self.isfirst = 0
    self.isfirstshowGeneral = 0

    print("isfirst = ",self.isfirst)
    print("isfirstshowGeneral = ",self.isfirstshowGeneral)
end

return zhounian