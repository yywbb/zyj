--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

--等级冲榜
local newrank = {
    isscrolltouched = false,
    buttontouch = -103,

    normalCellSize = {x=1080,y=282+14},

    activityId = 11,
    rankId = 1,
    

    -- pageconfig = {"reward","achieve",} ,
    pageconfig = {"reward"} ,
    pagename =   {"排名奖励","成就",},
    
    selectpage = "reward",
    RewardListTableView = nil,
    AchieveListTableView = nil,

    rewardData = {},
    achieveData = {},

    isEnd = false,
    rankData = {}, --排行榜数据
    panelID = "106",
}

--按钮高亮状态的显示
function  newrank.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if vm == page then
            setSpriteFrameByName(self.coveritems["buttonsprite"..km], gameConfig.images.pageButtonON)
            --self.coveritems["buttonnode"..km]:setZOrder(1)
        else
            setSpriteFrameByName(self.coveritems["buttonsprite"..km], gameConfig.images.pageButtonOFF)
            --self.coveritems["buttonnode"..km]:setZOrder(0)
        end
    end
end

function newrank.shiftPage(self,type)
    if type and self.selectpage == type then
        return
    end

    if type then
        self.selectpage = type
    end

    self:shiftlayerpage(self.selectpage)
    print("i...am..shiftPage",type)
    for k,v in ipairs(self.pageconfig) do
        if v == self.selectpage then
            self.coveritems[v.."Node"]:setPositionX(0)
            self.coveritems[v.."Node"]:setVisible(true)
        else
            self.coveritems[v.."Node"]:setPositionX(9999)
            self.coveritems[v.."Node"]:setVisible(false)
        end
    end

    if self.selectpage == "reward" then
        self:reloadRewardData()
    elseif self.selectpage == "achieve" then

        if self.achieveData then
            self:reloadAchieveData(self.achieveData)
        else
            self:reloadAchieveData(self.achieveData)
        end
    end
end

function newrank.init(self,size,activityId)
    self.contentsize = size
    self.activityId = activityId
    self.rankId = gameConfig.activityRankConfig[self.activityId].rankId

    self.show = true
    self:initUI()

    if #self.pageconfig > 1 then
        self:shiftPage()
    else
        self:reloadRewardData()
    end
    
    -- self:reloadData()
    UIRequest({type=5601,method = (self.isEnd and 2 or 1), rankId = self.rankId,activityRankId = self.activityId})
    return self.coverccb
end


function newrank.initUI(self)
    self.coverccb, self.coveritems = CCBReaderLoad("chongbang/chongbang",nil, true, "chongbang")
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.rewardList:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-840))
    self.coveritems.achieveList:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-840))

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[self.panelID].generalanimation)].name
    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    if name~= "" then
        local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)     
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(2)
        Gneral1:setPosition(0,0)
        self.coveritems["generalNode"]:addChild(Gneral1)
    end
    
    -- 活动时间
    local timediff = 0
    self.coveritems.timeNode:setVisible(true)
    if self.coveritems.time and gamedata.config.activity_time[self.panelID]["open_type"] and gamedata.config.activity_time[self.panelID]["open_type"] == 2 then
        self.coveritems.timeNode:setVisible(false)
    elseif self.coveritems.time and gamedata.config.activity_time[self.panelID]["open_type"] and gamedata.config.activity_time[self.panelID]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time[self.panelID]["continued_time"]+(gamedata.config.activity_time[self.panelID]["days_later"] or 0)) - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < 0 then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time[self.panelID]["continued_time"]+(gamedata.config.activity_time[self.panelID]["days_later2"] or 0))- nowtime - temp.hour*3600 - temp.min*60 - temp.sec
        end

    elseif self.coveritems.time and gamedata.config.activity_time[self.panelID]["end"] and gamedata.config.activity_time[self.panelID]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time[self.panelID]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime
    end

    self.isEnd = (timediff < 0)

    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("Activitynewrank"..self.activityId,timediff)

        if gameTimer.times["Activitynewrank"..self.activityId] and gameTimer.times["Activitynewrank"..self.activityId] > 0 then
            gameTimer:rigistTimeFunc("Activitynewrank"..self.activityId, function()
                if gameTimer.times["Activitynewrank"..self.activityId] <= 0 then
                    if gameTimer.times["Activitynewrank"..self.activityId] then
                        gameTimer:UnrigistTimeFunc("Activitynewrank"..self.activityId)
                    end

                    self.isEnd = true
                    self.coveritems.time:setString(gameConfig.strings:string_common("fixedString","activityRank",12))
                    print("活动结束")
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["Activitynewrank"..self.activityId],"day"))
                end
                ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
            end)
        end
    else
        self.coveritems.time:setString(gameConfig.strings:string_common("fixedString","activityRank",12))
    end

    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)



    --排行榜
    self.coveritems.rankButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        print("rankButton")

        if next(self.rankData) then
            self:openRankWindow()
        else
            if self.isEnd then
                UIRequest({type = 3503,activityRankId = self.activityId, method = self.rankId,pos = 1,num = 50})
            else
                UIRequest({type = 3500,activityRankId = self.activityId, method = self.rankId,pos = 1,num = 50})
            end
        end
        
    end, CCControlEventTouchUpInside)
    self.coveritems.rankButton:setSwallowsTouch(true)
    self.coveritems.rankButton:setTouchPriority(self.buttontouch)


    local buildId = gamedata.config.activity_time[tostring(self.activityId)].systemid
    --跳转
    self.coveritems.doButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        print("doButton")

        if gamedata.config.build[tostring(buildId)].param2 ~= "" then
            GameScene:shiftLayerById(gamedata.config.build[tostring(buildId)].param2)
        end

    end, CCControlEventTouchUpInside)
    self.coveritems.doButton:setSwallowsTouch(true)
    self.coveritems.doButton:setTouchPriority(self.buttontouch)

   
    --说明
    self.coveritems.ruleButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        print("ruleButton")

        gameWindows:openWindow("newRankRule",{systemid = buildId})

    end, CCControlEventTouchUpInside)
    self.coveritems.ruleButton:setSwallowsTouch(true)
    self.coveritems.ruleButton:setTouchPriority(self.buttontouch)


    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","newrank"..self.activityId,touchbegin)

    local function touchend(pos)
        if (self.coveritems.rewardList and ui.isTouched(self.coveritems.rewardList,pos.x,pos.y)) or (self.coveritems.achieveList and ui.isTouched(self.coveritems.achieveList,pos.x,pos.y)) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","newrank"..self.activityId,touchend)
    self:initFixedString()

    if #self.pageconfig > 1 then
        ui.setLayerpageshift(self,self.coveritems,self.buttontouch)
        self.coveritems.pagemenu:setVisible(true)
    else
        self.coveritems.pagemenu:setVisible(false)
    end

        -- 根据活动是否结束判断
    if self.isEnd == true then
        self.coveritems.fixlab7:setVisible(false);
        self.coveritems.myscore:setVisible(false);
        self.coveritems.doNode:setVisible(false)
        self.coveritems.time:setColor(ccc3(255,0,0))
    else
        self.coveritems.fixlab7:setVisible(true);
        self.coveritems.myscore:setVisible(true);
        self.coveritems.doNode:setVisible(true)
        self.coveritems.time:setColor(ccc3(248,237,245))
    end
    
end

function newrank.openRankWindow(self,data)
    if data then
        self.rankData = data
    end

    if gameWindows.windows["activityNewRank"].show then
        gameWindows.windows["activityNewRank"]:reloadData({players = self.rankData,mydata = self.data.my, rankId = self.rankId})
    else
        gameWindows:openWindow("activityNewRank",{players = self.rankData,mydata = self.data.my, rankId = self.rankId})
    end

    
end

function newrank.reloadData(self,data)

    if data then
        self.data = data
    end

    -- self.data = {
    --     players = {
    --         ["1"] = {name = "张三",score = 3000,score2 = 200},
    --         ["2"] = {name = "李四",score = 3000,score2 = 200},
    --         ["3"] = {name = "王五",score = 3000,score2 = 200},
    --     },

    --     my = {
    --         rank = 1,
    --         score = 500,
    --         score2 = 200
    --     }
    -- } --13,24

    if self.coveritems.p_powernode then
        if self.data.my.p_score then
            self.coveritems.p_powernode:setVisible(true)
            ui.setLabelString(self.coveritems.p_powerstr,"初始战力：",13)
            ui.setLabelString(self.coveritems.p_power,self.data.my.p_score or 0,24)
        else
            self.coveritems.p_powernode:setVisible(false)
        end
    end

    local len = table.getTableLength(self.data.players)
    --翅膀
    if self.rankId == 5 then
        if len >= 1 then
            if len >=3 then
                len = 3
            end
            for i=1,len do
                local values = string.split(self.data.players[tostring(i)].score,"-")
                self.data.players[tostring(i)].score = gameConfig.strings:wingGrow(values[1],values[2])
            end
            local values = string.split(self.data.my.score,"-")
            self.data.my.score = gameConfig.strings:wingGrow(values[1],values[2])
        end
    end
    
    if len >= 1 then
        if len >=3 then
            len = 3
        end
        for i=1,len do
            self.coveritems["name"..i]:setString(self.data.players[tostring(i)].name)
            self.coveritems["score"..i]:setString(self.data.players[tostring(i)].score)
        end
    end
    

    if self.data.my.rank <= 0 then
        self.coveritems.myrank:setString(gameConfig.strings:string_common("fixedString","activityRank",14))
    else
        self.coveritems.myrank:setString(self.data.my.rank)
    end
    

    if gameConfig.strings:string_common("fixedString","activityRank",100+self.rankId) then
        self.coveritems.fixlab7:setString(gameConfig.strings:string_common("fixedString","activityRank",100)..gameConfig.strings:string_common("fixedString","activityRank",100+self.rankId))
    end

    self.coveritems.myscore:setString(self.data.my.score)
    self.coveritems.myscore:setPositionX(self.coveritems.fixlab7:getPositionX()+self.coveritems.fixlab7:getContentSize().width + 3)
end

function newrank.reloadRewardData(self)

    if not next(self.rewardData) then
        local config = gamedata.config[gameConfig.activityRankConfig[self.activityId].reward]
        if not config then
            return
        end
        for k,v in pairs(config) do
            table.insert(self.rewardData,v)
        end

        table.sort(self.rewardData,function (a,b )
            return a.id < b.id
        end)
    end
    
    if self.coveritems then
        if not self.RewardListTableView then
            self:createRewardList()
        else
            if self.RewardListTableView:getLuaContentOffsetY() < self.coveritems.rewardList:getContentSize().height - table.getTableLength(self.rewardData)*self.normalCellSize.y then
                self.RewardListTableView:setLuaContentOffset(0, self.coveritems.rewardList:getContentSize().height - table.getTableLength(self.rewardData)*self.normalCellSize.y)
            end
            self.RewardListTableView:reloadData()
        end
    end

    local len = table.getTableLength(self.rewardData)
    self.coveritems.showNum:setString(self.rewardData[len].id)
    
end

function newrank.createRewardList(self)

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

            self:setRewardCell(ccbDocumentControler,self.rewardData[a1+1] or self.rewardData[tostring(a1+1)],a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rewardData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.RewardListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.rewardList:getContentSize().width,
        viewheight = self.coveritems.rewardList:getContentSize().height,
        dire = 1
    })
    self.coveritems.rewardList:addChild(self.RewardListTableView)
    self.RewardListTableView:setTouchPriority(-101)
end


function newrank.setRewardCell(self,item,data,index)

    item.doNode:setVisible(false)
    item.title:setString(gameConfig.strings:RankReward1(data.id))
    if index > 1  and self.rewardData[index-1].id+1 < data.id then
        item.title:setString(gameConfig.strings:RankReward2(self.rewardData[index-1].id+1,data.id))
    end

    for i=1, 4 do
        if data["propsid"..i] and data["propsid"..i] > 0 then
            item["reward"..i]:setVisible(true)
            local config = ui.IDconfig(data["propsid"..i])
            if config then
                ui.setNewIcon(item,{cid = data["propsid"..i], num = data["nmb"..i]},i-1)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    ui.setPopwindowByCid(data["propsid"..i])
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        else
            item["reward"..i]:setVisible(false)
        end
    end
end


function newrank.reloadAchieveData(self,data)

    self.achieveData = {
        [1] = 0,
        [2] = 1,
        [3] = 0,
        [4] = 2,
        [5] = 0,
        [6] = 0,
        [7] = 2,
        [8] = 0,
    }

    table.sort(self.achieveData,function ( a,b)
        if a == 1 and b ~= 1 then
            return true
        elseif  a ~= 1 and b == 1  then
            return false
        elseif a == 0 and b ~= 0 then
            return true
        else
            return false
        end
    end)

    if self.coveritems then
        if not self.AchieveListTableView then
            self:createAchieveList()
        else
            if self.AchieveListTableView:getLuaContentOffsetY() < self.coveritems.achieveList:getContentSize().height - table.getTableLength(self.achieveData)*self.normalCellSize.y then
                self.AchieveListTableView:setLuaContentOffset(0, self.coveritems.achieveList:getContentSize().height - table.getTableLength(self.achieveData)*self.normalCellSize.y)
            end
            self.AchieveListTableView:reloadData()
        end
    end
end

function newrank.createAchieveList(self)

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

            self:setAchieveCell(ccbDocumentControler,self.achieveData[a1+1] or self.achieveData[tostring(a1+1)],a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.achieveData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.AchieveListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.achieveList:getContentSize().width,
        viewheight = self.coveritems.achieveList:getContentSize().height,
        dire = 1
    })
    self.coveritems.achieveList:addChild(self.AchieveListTableView)
    self.AchieveListTableView:setTouchPriority(-101)
end


function newrank.setAchieveCell(self,item,data,index)

    
    local config = gamedata.config.openlevel_rank_achievement[tostring(index)]
    if data == 0 then
        ui.addGray("CCControlButton",item.doButton)
        ui.setLabelString(item.doLab, gameConfig.strings:string_common("fixedString","activityRank",6), 19)
        
    elseif data == 1 then
        ui.removeGray("CCControlButton",item.doButton)
        ui.setLabelString(item.doLab, gameConfig.strings:string_common("fixedString","activityRank",7), 19)
    elseif data == 2 then
        ui.addGray("CCControlButton",item.doButton)
        ui.setLabelString(item.doLab, gameConfig.strings:string_common("fixedString","activityRank",8), 19)
    end

    item.title:setString(config.desc)


    item["doButton"]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if data == 0 then
            runGamePrompt({msg=gameConfig.strings:string_common("fixedString","activityRank",6)})
        elseif data == 1 then
            
        elseif data == 2 then
            runGamePrompt({msg=gameConfig.strings:string_common("fixedString","activityRank",8)})
        end

    end, CCControlEventTouchUpInside)
    item["doButton"]:setTouchPriority(-103)


    local rewards = ui.getIDandNUMs(config.reward)

    for i=1, 4 do
        if rewards[i] and rewards[i].cid then
            item["reward"..i]:setVisible(true)
            local config = ui.IDconfig(rewards[i].cid)
            if config then
                ui.setNewIcon(item,{cid = rewards[i].cid, num = rewards[i].num},i-1)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    ui.setPopwindowByCid(rewards[i].cid)
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        else
            item["reward"..i]:setVisible(false)
        end
    end
end

function newrank.initFixedString(self)
    self.coveritems.fixlab1:setString(gameConfig.strings:string_common("fixedString","activityRank",1))
    self.coveritems.fixlab2:setString(gameConfig.strings:string_common("fixedString","activityRank",2))
    self.coveritems.fixlab3:setString(gameConfig.strings:string_common("fixedString","activityRank",3))
    self.coveritems.fixlab9:setString(gameConfig.strings:string_common("fixedString","activityRank",5))
    self.coveritems.fixlab8:setString(gameConfig.strings:string_common("fixedString","activityRank",4))


    self.coveritems.fixlab4:setString(gameConfig.strings:string_common("fixedString","activityRank",9))
    self.coveritems.fixlab5:setString(gameConfig.strings:string_common("fixedString","activityRank",10))
    self.coveritems.fixlab6:setString(gameConfig.strings:string_common("fixedString","activityRank",11))

    if gameConfig.strings:string_common("fixedString","activityRank",200 + self.rankId) then
        self.coveritems.title:setString(gameConfig.strings:string_common("fixedString","activityRank",200 + self.rankId))
    end
    
end

function newrank.clear(self)
    gameTouch:UnrigistFunc("begin","newrank"..self.activityId)
    gameTouch:UnrigistFunc("end","newrank"..self.activityId)
    if gameTimer.times["Activitynewrank"..self.activityId] then
        gameTimer:UnrigistTimeFunc("Activitynewrank"..self.activityId)
    end
    self.show = false
    self.coverccb = nil
    self.coveritems = nil

    self.selectpage = "reward"
    self.RewardListTableView = nil
    self.AchieveListTableView = nil
    self.rewardData = {}
    self.achieveData = {}

    self.isEnd = false
    self.rankData = {} --排行榜数据
end

return newrank