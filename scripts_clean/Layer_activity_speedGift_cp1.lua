--
-- Created by IntelliJ IDEA.
-- User: yxf
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local speedGiftCP = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    day = 1,
    status = {},
    ListTableView = nil,
    normalCellSize = {x=1080,y=282+10},

    --不同的活动替换一下相关id
    activityid = "154",
    lingquRequestId = 8029,
    timerName = "ActivityspeedGiftCP",
    touchName = "speedGiftCP",
    ccbnames = "activityreward_new/jiasulibao",
    ccbbienames = "jiasulibaocp",
}


function speedGiftCP.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad(self.ccbnames,nil, true, self.ccbbienames)

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-500))

   
    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin",self.touchName,touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end",self.touchName,touchend)
    --


    --配置表
    self.special_gift_time = gamedata.config.speedup_gift_time_x2
    self.special_gift = gamedata.config.speedup_gift


    return self.coverccb
end


function speedGiftCP.reloaddata(self,data)
    if not self.show then return end
    --
    if not data then return end
    self.giftdata = data.giftdata or {}

     --找到对应轮数的奖励字符串和icon
    local rewardStr = ""
    local iconname = ""
    local activitydata = GameScene.layers["activity"].module:getDailyCPActivityDataById(tonumber(self.activityid))
    printT(activitydata,"activitydata")
    self.status = {}
    for k,v in pairs(self.special_gift_time) do
        if v.day and v.day ~= "" then
            table.insert(self.status,v)
        end
    end
    table.sort(self.status, function(a,b) return a.day < b.day end)
    printT(self.status)
    if activitydata and activitydata.cpday then
        local cpday = activitydata.cpday or 1
        for i=1 , table.getTableLength(self.status) do
            local currentday = self.status[i].day
            local afterday =  (self.status[i+1] ~=nil)  and (self.status[i+1].day) or  -1 
            printT(self.status[i],"--------")
            if cpday>=currentday and cpday<afterday then
                  rewardStr = self.status[i].reward
                  iconname = self.status[i].icon
                  break
            end    
            if afterday == -1 and cpday>=currentday  then
                rewardStr = self.status[i].reward
                iconname = self.status[i].icon
                break
            end    
        end
    end
    print("rewardStr:"..rewardStr)
    local rewarddata = ui.getIDSFromStr(rewardStr)
    printT(rewarddata,"data")

   --根据配置表排序
   self.newgiftdata = {}
    for k,v in ipairs(rewarddata) do
        print("rewarddata v"..v)
        for i=1,table.getTableLength(self.giftdata) do
            if v == self.giftdata[tostring(i)].id then
                if self.giftdata[tostring(i)].status == 2 then --已经领取完成的
                     table.insert(self.newgiftdata,{status = 2, id =k, data = self.giftdata[tostring(i)]})
                elseif self.giftdata[tostring(i)].status == 1 then --待领取的
                     table.insert(self.newgiftdata,{status = 0, id =k, data = self.giftdata[tostring(i)]})
                else--未完成的
                     table.insert(self.newgiftdata,{status = 1, id =k, data = self.giftdata[tostring(i)]})
                end    
            end    
        end
        
    end
    local sortfunc = function (a,b)
         if a.status ~= b.status then
            return  a.status < b.status 
         else
            return  a.id < b.id
         end   
    end
    table.sort(self.newgiftdata,sortfunc)

    --设置背景图片
     print("iconname name: "..iconname)
    if iconname ~= "" then
        setSpriteFrameByName(self.coveritems.giftsprite,iconname)
    end   

    -- -- 活动时间
    -- local timediff = 0
    -- if self.coveritems.time and gamedata.config:getConfigByName("activity_time")[self.activityid]["open_type"] and gamedata.config:getConfigByName("activity_time")[self.activityid]["open_type"] == 5 then
    --     -- local nowtime = gamedata:time()
    --     -- local temp = os.date("*t", nowtime)
    --     -- timediff = 86400*(gamedata.config:getConfigByName("activity_time")[self.activityid]["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    --     timediff = GameScene.layers["activity"].module:getDailyCpActivityTime(tonumber(self.activityid))
    -- elseif self.coveritems.time and gamedata.config:getConfigByName("activity_time")[self.activityid]["open_type"] and gamedata.config:getConfigByName("activity_time")[self.activityid]["open_type"] == 7 then
    --     timediff = GameScene.layers["activity"].module:getDailyCpActivityTime(tonumber(self.activityid))
    -- elseif self.coveritems.time and gamedata.config:getConfigByName("activity_time")[self.activityid]["end"] and gamedata.config:getConfigByName("activity_time")[self.activityid]["end"] ~= "" then
    --     local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config:getConfigByName("activity_time")[self.activityid]["end"])
    --     local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
    --     local nowtime = gamedata:time()
    --     timediff = time1-nowtime;
    -- elseif self.coveritems.time then
    --     self.coveritems.time:setString("")
    --     self.coveritems.desc1:setString("")
    -- end


    -- if self.coveritems.time and timediff and timediff > 0 then
    --     gameTimer:rigistTime(self.timerName,timediff)

    --     if gameTimer.times[self.timerName] and gameTimer.times[self.timerName] > 0 then
    --         gameTimer:rigistTimeFunc(self.timerName, function()
    --             if gameTimer.times[self.timerName] <= 0 then
    --                 if gameTimer.times[self.timerName] then
    --                     gameTimer:UnrigistTimeFunc(self.timerName)
    --                 end
    --             else
    --                 self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times[self.timerName],"day"))
    --                 ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
    --             end
    --         end)
    --     end
    -- end

    self.coveritems.time:setString("礼包每天0点重置")
    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
  
   
    --创建list列表
    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else                                                                                                                     -- self.data                         
            if self.ListTableView:getLuaContentOffsetY() < self.coveritems.listnode:getContentSize().height - table.getTableLength(self.newgiftdata)*self.normalCellSize.y then
                self.ListTableView:setLuaContentOffset(0, self.coveritems.listnode:getContentSize().height - table.getTableLength(self.newgiftdata)*self.normalCellSize.y)
            end
            self.ListTableView:reloadData()
        end
    end

end




function speedGiftCP.clear(self)
    gameTouch:UnrigistFunc("begin",self.touchName)
    gameTouch:UnrigistFunc("end",self.touchName)

    if gameTimer.times[self.timerName] then
        gameTimer:UnrigistTimeFunc(self.timerName)
    end
    self.show = false
    self.ListTableView = nil
    self.giftdata = {}
    self.day = 1
    self.coverccb = nil
    self.coveritems = nil
end

function speedGiftCP.createList(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward1", nil, true, "cell_reward1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.newgiftdata[a1+1].data,a1+1)

            cellCCB:setScale(0.98)
            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.newgiftdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.listnode:getContentSize().width,
        viewheight = self.coveritems.listnode:getContentSize().height,
        dire = 1
    })
    self.coveritems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end


function speedGiftCP.setCell(self,item,data,index)
    print("setCell")
    printT(data)

    local config =  self.special_gift[tostring(data.id)]

    printT(config,"config")

    item.doButton:setTouchPriority(-102)
    item.rechargeButton:setTouchPriority(-102)
    if data.status and data.status == 1 then--可领取
        item.nonenode:setVisible(false)
        item.doNode:setVisible(true)
        item.hasnode:setVisible(false)
        item.rechargeNode:setVisible(false)
        ui.removeGray("CCControlButton",item.doButton)
        ui.removeGray("CCLabelTTF",item.doLab)
        -- item.doLab:setString("领取")
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(1)
            print("getbutton clicked")

            UIRequest({type = self.lingquRequestId, id = data.id or 1})

        end, CCControlEventTouchUpInside)
    elseif data.status and data.status == 2 then--已领取
        item.nonenode:setVisible(false)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(true)
        item.rechargeNode:setVisible(false)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",5))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)
    else  --去充值
        item.nonenode:setVisible(false)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        item.rechargeNode:setVisible(true)

        local rechargeconfig = gamedata.config:getConfigByName("recharge")[tostring(config.rmb)]
        ui.setLabelString(item.rechargeLab,rechargeconfig.rmb.."元",18)
        item.rechargeButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end

            if RechargeLimit(rechargeconfig.rmb) then
                return
            end
            
            -- UIRequest({type = 115,cid = rechargeconfig.id,bagid=tonumber(activityid)})
            if sdk:isValid() then
                UIRequest({type = 115,cid = rechargeconfig.id,bagid=tonumber(config.id)})
            else
                -- runGamePrompt({msg = "未接入充值渠道"})
                runGamePrompt({msg = gameConfig.strings:string_common("popups","change_qudao")})
            end  
        end, CCControlEventTouchUpInside)
    end

    item.lavenum:setVisible(true)

    local totalnum = config.number
    local usetime = data.times
    if data.status and data.status == 2 then
         item.lavenum:setString("剩余次数：0/"..totalnum)
    elseif data.status and data.status == 1 then
         item.lavenum:setString("剩余次数："..(totalnum-usetime-1).."/"..totalnum)
    else
        item.lavenum:setString("剩余次数："..(totalnum-usetime).."/"..totalnum)
    end

    item.title:setString(config.name or "")
    local props = ui.getIDandNUMs(config.reward) or {}

    for i=1, 4 do
        if props[i] and props[i].cid then
            item["reward"..i]:setVisible(true)
            local config = ui.IDconfig(props[i].cid)
            if config then
                ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    ui.setPopwindowByCid(props[i].cid)
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        else
            item["reward"..i]:setVisible(false)
        end
    end

    item.typenode:setVisible(false)
end



return speedGiftCP