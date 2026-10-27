--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/8/28
-- Time: 下午3:28
-- To change this template use File | Settings | File Templates.
--

local guildWarMain = {

    rootNode = nil,
    rootItems = nil,

    -- 夺宝战 报名时间
    begintimenum = {week=4,hour=10,min=0,sec=0},
    endtimenum = {week=5,hour=24,min=0,sec=0},

    -- 夺宝战 入场时间
    beginreadingnum = {week=6,hour=20,min=0,sec=0},
    endreadingnum = {week=6,hour=20,min=10,sec=0},

    -- 夺宝战 攻打时间
    beginfightingnum = {week=6,hour=20,min=10,sec=0},
    endfightingnum = {week=6,hour=22,min=0,sec=0},

    -- 夺宝战 领奖时间
    beginrewardnum = {week=6,hour=22,min=0,sec=0},
    endrewardgnum = {week=6,hour=24,min=0,sec=0},



    -- -----------------------------------------------
    -- begintimenum1 = {week=4,hour=18,min=37,sec=0},
    -- endtimenum1 = {week=4,hour=18,min=38,sec=0},

    -- -- 夺宝战 准备时间
    -- beginreadingnum1 = {week=4,hour=18,min=39,sec=0},
    -- endreadingnum1 = {week=4,hour=18,min=40,sec=0},

    -- -- 夺宝战 攻打时间
    -- beginfightingnum1 = {week=4,hour=18,min=40,sec=0},
    -- endfightingnum1 = {week=4,hour=18,min=41,sec=0},


    -- -----------------------------------------------
    -- begintimenum2 = {week=1,hour=16,min=0,sec=0},
    -- endtimenum2 = {week=1,hour=16,min=10,sec=0},

    -- -- 夺宝战 准备时间
    -- beginreadingnum2 = {week=1,hour=16,min=20,sec=0},
    -- endreadingnum2 = {week=1,hour=16,min=40,sec=0},

    -- -- 夺宝战 攻打时间
    -- beginfightingnum2 = {week=1,hour=16,min=40,sec=0},
    -- endfightingnum2 = {week=1,hour=17,min=20,sec=0},



    -- -----------------------------------------------
    -- begintimenum3 = {week=1,hour=18,min=0,sec=0},
    -- endtimenum3 = {week=1,hour=18,min=10,sec=0},

    -- -- 夺宝战 准备时间
    -- beginreadingnum3 = {week=1,hour=18,min=20,sec=0},
    -- endreadingnum3 = {week=1,hour=18,min=40,sec=0},

    -- -- 夺宝战 攻打时间
    -- beginfightingnum3 = {week=1,hour=18,min=40,sec=0},
    -- endfightingnum3 = {week=1,hour=19,min=20,sec=0},


    isleader = false,
    isInspire = false,
}

function guildWarMain.setFightingTimeData( self )
    local battletimeconfig = gamedata.config.gang2_battleTime

    -- 夺宝战 报名时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["1"]["1"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["1"]["1"]["overtime"])
    print("hour1,min1,sec1==",hour1,min1,sec1)
    print("hour2,min2,sec2==",hour2,min2,sec2)

    self.begintimenum1 = {week=battletimeconfig["1"]["1"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endtimenum1 = {week=battletimeconfig["1"]["1"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 入场时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["1"]["2"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["1"]["2"]["overtime"])

    self.beginreadingnum1 = {week=battletimeconfig["1"]["2"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endreadingnum1 = {week=battletimeconfig["1"]["2"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 攻打时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["1"]["3"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["1"]["4"]["overtime"])

    self.beginfightingnum1 = {week=battletimeconfig["1"]["3"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endfightingnum1 = {week=battletimeconfig["1"]["4"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 领奖时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["1"]["5"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["1"]["5"]["overtime"])

    self.beginrewardnum1 = {week=battletimeconfig["1"]["5"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endrewardgnum1 = {week=battletimeconfig["1"]["5"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -----------------------------------------------------------
    -----------------------------------------------------------
    -- 第二场 公会战 
    
    -- 夺宝战 报名时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["2"]["1"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["2"]["1"]["overtime"])

    self.begintimenum2 = {week=battletimeconfig["2"]["1"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endtimenum2 = {week=battletimeconfig["2"]["1"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 入场时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["2"]["2"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["2"]["2"]["overtime"])

    self.beginreadingnum2 = {week=battletimeconfig["2"]["2"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endreadingnum2 = {week=battletimeconfig["2"]["2"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 攻打时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["2"]["3"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["2"]["4"]["overtime"])

    self.beginfightingnum2 = {week=battletimeconfig["2"]["3"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endfightingnum2 = {week=battletimeconfig["2"]["4"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

    -- 夺宝战 领奖时间
    local hour1,min1,sec1 = ui.getGangBattleTime(battletimeconfig["2"]["5"]["opentime"])
    local hour2,min2,sec2 = ui.getGangBattleTime(battletimeconfig["2"]["5"]["overtime"])

    self.beginrewardnum2 = {week=battletimeconfig["2"]["5"]["weektime_open"], hour=hour1, min=min1, sec=sec1}
    self.endrewardgnum2 = {week=battletimeconfig["2"]["5"]["weektime_over"], hour=hour2, min=min2, sec=sec2}

end

function guildWarMain.setTimeData( self )
    -- printT(gamedata.config.gang2_battleTime,"battletimeconfig===")


    if gamedata.config.gang2_battleTime and gamedata.config.gang2_battleTime["1"] and gamedata.config.gang2_battleTime["1"]["1"] and gamedata.config.gang2_battleTime["1"]["1"].weektime_open and gamedata.config.gang2_battleTime["1"]["1"].weektime_open > 0 then

    else
        return
    end

    
    self:setFightingTimeData()
    local nowtime = os.date("*t", gamedata:time())
    -- print("nowtime===")
    -- printT(nowtime)

    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec

    if alltimes >= self:gettimenum(self.endrewardgnum1) and alltimes < self:gettimenum(self.endrewardgnum2) then
        -- 夺宝战 报名时间(第二轮)
        self.begintimenum = self.begintimenum2
        self.endtimenum = self.endtimenum2

        -- 夺宝战 入场时间
        self.beginreadingnum = self.beginreadingnum2
        self.endreadingnum = self.endreadingnum2

        -- 夺宝战 攻打时间
        self.beginfightingnum = self.beginfightingnum2
        self.endfightingnum = self.endfightingnum2

        -- 夺宝战 领奖时间
        self.beginrewardnum = self.beginrewardnum2
        self.endrewardgnum = self.endrewardgnum2
    else
        -- 夺宝战 报名时间（第一轮
        self.begintimenum = self.begintimenum1
        self.endtimenum = self.endtimenum1

        -- 夺宝战 入场时间
        self.beginreadingnum = self.beginreadingnum1
        self.endreadingnum = self.endreadingnum1

        -- 夺宝战 攻打时间
        self.beginfightingnum = self.beginfightingnum1
        self.endfightingnum = self.endfightingnum1

        -- 夺宝战 领奖时间 
        self.beginrewardnum = self.beginrewardnum1
        self.endrewardgnum = self.endrewardgnum1
    end


end


function guildWarMain.init(self,parent,toppos,data)
   	self.rootNode,self.rootItems = CCBReaderLoad("gonghuizhan/warmain", nil, true, "warmain")
   	self.rootNode:setPosition(0,0)
   	parent:addChild(self.rootNode)

    self.rootItems.container:setContentSize(CCSize(830*3,960*3))
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(-101)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(-780,-720),0)

  

    self.mapNode, self.mapItems = CCBReaderLoad("gonghuizhan/gonghuizhan_map", nil, true, "gonghuizhan_map")
    self.mapNode:setPosition(0,0)
    self.rootItems.container:addChild(self.mapNode)


    self.rootItems.topnode:setPositionY(toppos)
    -- self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-160))
    -- self.rootItems.scrollnode:


    -- ui.setLabelString(self.rootItems.turntext,nil,19)

    -- self:zhuanpanStateAction("hidewheel")
    -- 返回
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(-103)
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        print("i..am.....backBtn..end")
        gameTouch:clickprofbytime(0.5)
        -- gameWindows:openWindow("penglaiResult",{index= "ruleview",data = {}},nil)
        UIRequest({type = 2230, param = "main"})
    end, CCControlEventTouchUpInside)

    -- 介绍
    self.rootItems.aboutBtn:setSwallowsTouch(true)
    self.rootItems.aboutBtn:setTouchPriority(-103)
    self.rootItems.aboutBtn:addHandleOfControlEvent(function()
        print("i..am.....aboutBtn..end")
         -- runGamePrompt({msg = "暂未开启"})
        if gamedata.config.gang2_battleTime and gamedata.config.gang2_battleTime["1"] and gamedata.config.gang2_battleTime["1"]["1"] and gamedata.config.gang2_battleTime["1"]["1"].weektime_open and gamedata.config.gang2_battleTime["1"]["1"].weektime_open > 0 then
            gameWindows:openWindow("guildwarabout",{isnew = true}, nil)
        else
            gameWindows:openWindow("guildwarabout",nil, nil)
        end
        -- gameWindows:openWindow("penglaiReward",{point = self.config.island.PointWeek , movetype = self.movetype},nil)
    end, CCControlEventTouchUpInside)

    -- 报名参赛
    local globConfig = gamedata.config.global_kv
    self.rootItems.signBtn:setSwallowsTouch(true)
    self.rootItems.signBtn:setTouchPriority(-103)
    self.rootItems.signBtn:addHandleOfControlEvent(function()
        print("i..am.....signBtn..end")
        gameTouch:clickprofbytime(1)
        if self.takewardata.onepoint ~= 0 then
            if self.battleSignstatus == 0 and self.isInspire == true then
                function guildWarSureRequest()
                    local costData = gamedata.getIDandNUMs(globConfig.quick_war_cost.value)
                    UIRequest({type = 2147,num = costData[1].num})          
                end
                gameWindows:openWindow("guildWarSure",{index = 1},guildWarSureRequest)
            else 
                runGamePrompt({msg = "当前不能一键参赛"})
            end
        else
            runGamePrompt({msg = "当前不能一键参赛"})
        end

    end, CCControlEventTouchUpInside)

   -- 一键鼓舞
    self.rootItems.inspireBtn:setSwallowsTouch(true)
    self.rootItems.inspireBtn:setTouchPriority(-103)
    self.rootItems.inspireBtn:addHandleOfControlEvent(function()
        print("i..am.....inspireBtn..end")
        gameTouch:clickprofbytime(1)
        if self.takewardata.onepoint ~= 0 then
            if self.inspirestatus == 0 and self.isInspire == true then
                function guildWarSureRequest()
                    local costData = gamedata.getIDandNUMs(globConfig.quick_Inspire_cost.value)
                    UIRequest({type = 2146,num = costData[1].num})          
                end
                gameWindows:openWindow("guildWarSure",{index = 2},guildWarSureRequest)
            else 
                runGamePrompt({msg = "当前不能一键鼓舞"})
            end
        else
            runGamePrompt({msg = "当前不能一键鼓舞"})
        end
        
    end, CCControlEventTouchUpInside)



    local quick_war_cost = ui.getIDandNUMs(gamedata.config.global_kv.quick_war_cost.value)
    ui.setLabelString(self.rootItems.cost1_gold,quick_war_cost[1].num,GameScene.roleinfo.gold >= quick_war_cost[1].num and 13 or 27)


    local quick_Inspire_cost = ui.getIDandNUMs(gamedata.config.global_kv.quick_Inspire_cost.value)
    ui.setLabelString(self.rootItems.cost2_gold,quick_Inspire_cost[1].num,GameScene.roleinfo.gold >= quick_Inspire_cost[1].num and 13 or 27)
    ui.setLabelString(self.rootItems.cost2_coin,quick_Inspire_cost[2].num,GameScene.roleinfo.coin >= quick_Inspire_cost[2].num and 13 or 27)
    
    
    -- 测试时间设置（2个循环）
    self:setTimeData()

    --UIRequest({type = 2130})
    UIRequest({type = 2236})

    if data then
        self:reloaddata(data)
    else
        UIRequest({type = 2130})
    end

end




function guildWarMain.reloaddata(self,data)
    print("i...am..reload....")
    printT(data,"reloaddata===")
    self.allpointsdata = data.allpointsdata or {}
    self.takewardata = data.takewardata or {}


    self.inspirestatus = data.inspirestatus 
    self.battleSignstatus = data.battleSignstatus

    -- if self.inspirestatus and self.inspirestatus == 0 then
    --     ui.removeGray("CCControlButton",self.rootItems.inspireBtn)
    -- else 
    --     ui.addGray("CCControlButton",self.rootItems.inspireBtn)
    -- end

    -- if self.battleSignstatus and self.battleSignstatus == 0 then
    --     ui.removeGray("CCControlButton",self.rootItems.signBtn)
    -- else 
    --     ui.addGray("CCControlButton",self.rootItems.signBtn)
    -- end


    local pointawardconfig = gamedata.config.gang2_cityaward
    -- printT(pointawardconfig)
    -- printT(self.mapItems)
    for k,v in pairs(self.allpointsdata) do
        local pointconfigdata = pointawardconfig[tostring(k)]

        local ccbname = "gonghuizhan/baozhang"..pointconfigdata.quality

        print("ccbName===",ccbname)
        if self.mapItems["p"..k] then
            self.mapItems["p"..k]:removeAllChildrenWithCleanup(true)
        end

        local pointNode, pointItems = CCBReaderLoad(ccbname, nil, true, "ccbName")
        self.mapItems["p"..k]:addChild(pointNode)
        if v.id == 0 then
            pointItems.ownerNode:setVisible(false)
        else
            pointItems.ownerNode:setVisible(true)
            ui.setLabelString(pointItems.ownerNameLabel,v.name,29)
        end
        pointItems.rewardStateNode:setVisible(false)
        

        ui.setLabelString(pointItems.cityNameLabel,pointconfigdata.name,(((pointconfigdata.quality+1) and (pointconfigdata.quality+1) ~= 0) and (pointconfigdata.quality+1) or 1)*2)

        local memberrewarddata = gamedata.getIDandNUMs(pointconfigdata.member)
        print("member====")
        -- printT(memberrewarddata)
        ui.setLabelString(pointItems.cityrewardLabel,memberrewarddata[1].num,13)

        local idconfig = ui.IDconfig(memberrewarddata[1].cid)
        -- printT(idconfig)
        print("idconfig==",idconfig.icon)
        setSpriteFrameByName(pointItems.awardicon,(idconfig.icon..".png"))
        if memberrewarddata[1].cid == 1001 or memberrewarddata[1].cid == 1000 then
            pointItems.awardicon:setScale(0.4)
        else
            pointItems.awardicon:setScale(0.4)
        end
        
        pointItems.gotoBtn:setSwallowsTouch(true)
        pointItems.gotoBtn:setTouchPriority(-102)
        pointItems.gotoBtn:addHandleOfControlEvent(function()
            print("点击城池")
            -- cid = v.cid
            print(k)
            gameWindows:openWindow("guildtreasureinfo",{id = tonumber(k),isleader = self.isleader})
            -- UIRequest({type = 2131,id = tonumber(k) or 1,isleader = self.isleader })
            
        end, CCControlEventTouchUpInside)

    end


    self:setTopNode()
    self:updatetimeFunc()
end


function guildWarMain.setTopNode( self )
    print("setTopNode===")

    ui.setLabelString(self.rootItems.contributionLabel,self.takewardata.contributionNum,14)
    -- self.takewardata.rewardpoint = 5
    -- self.takewardata.rewardstatus = 1
    -- self.allpointsdata[tostring(5)].id = 1001
    -- self.allpointsdata[tostring(5)].name = "皇城帝都"

    -- self.takewardata.onepoint = 4
    -- self.allpointsdata[tostring(4)].id = 1002
    -- self.allpointsdata[tostring(4)].name = "魔焱城"

    -- self.takewardata.twopoint = 28
    -- self.allpointsdata[tostring(28)].id = 1004
    -- self.allpointsdata[tostring(28)].name = "风之谷"  

    self.rootItems.takeNode1:setScale(0.7)
    self.rootItems.takeNode2:setScale(0.7)
    self.rootItems.takeNode3:setScale(0.7)

    self.rootItems.takeNode1:setVisible(false)
    self.rootItems.takeNode2:setVisible(false)
    self.rootItems.takeNode3:setVisible(false)

    self.rootItems.takeitemNode1:removeAllChildrenWithCleanup(true)
    self.rootItems.takeitemNode2:removeAllChildrenWithCleanup(true)
    self.rootItems.takeitemNode3:removeAllChildrenWithCleanup(true)


    -- 初始化底板响应事件
    -- for i=1,3 do
    --     self.rootItems["takeBtn"..i]:setSwallowsTouch(true)
    --     self.rootItems["takeBtn"..i]:setTouchPriority(-102)
    -- end
    


    if self.takewardata.rewardpoint ~= 0 then
        local cityCCBNode = self:setCitydata(1,self.takewardata.rewardpoint,self.takewardata.rewardstatus)
        self.rootItems.takeitemNode1:addChild(cityCCBNode)
        self.rootItems.takeNode1:setVisible(true)

        if self.takewardata.onepoint ~= 0 then
            local onecityCCBNode = self:setCitydata(2,self.takewardata.onepoint,nil)
            self.rootItems.takeitemNode2:addChild(onecityCCBNode)
            self.rootItems.takeNode2:setVisible(true)

            if self.takewardata.twopoint ~= 0 then
                local twocityCCBNode = self:setCitydata(3,self.takewardata.twopoint,nil)
                self.rootItems.takeitemNode3:addChild(twocityCCBNode)
                self.rootItems.takeNode3:setVisible(true)
            end
        elseif self.takewardata.twopoint ~= 0 then
            local twocityCCBNode = self:setCitydata(2,self.takewardata.twopoint,nil)
            self.rootItems.takeitemNode2:addChild(twocityCCBNode)
            self.rootItems.takeNode2:setVisible(true)
        end
    elseif self.takewardata.onepoint ~= 0 then
        local onecityCCBNode = self:setCitydata(1,self.takewardata.onepoint,nil)
        self.rootItems.takeitemNode1:addChild(onecityCCBNode)
        self.rootItems.takeNode1:setVisible(true)

        if self.takewardata.twopoint ~= 0 then
            local twocityCCBNode = self:setCitydata(2,self.takewardata.twopoint,nil)
            self.rootItems.takeitemNode2:addChild(twocityCCBNode)
            self.rootItems.takeNode2:setVisible(true)
        end
    elseif self.takewardata.twopoint ~= 0 then
        local twocityCCBNode = self:setCitydata(1,self.takewardata.twopoint,nil)
        self.rootItems.takeitemNode1:addChild(twocityCCBNode)
        self.rootItems.takeNode1:setVisible(true)
    end
    
end

function guildWarMain.setCitydata( self, typenum, cidnum, status)

    local pointconfigdata = gamedata.config.gang2_cityaward[tostring(cidnum)]

    local ccbname = "gonghuizhan/baozhang"..pointconfigdata.quality

    print("ccbName===1111",ccbname)

    local pointNode, pointItems = CCBReaderLoad(ccbname, nil, true, "ccbName")
    -- self.mapItems["p"..k]:addChild(pointNode)


    ui.setLabelString(pointItems.cityNameLabel,pointconfigdata.name,(((pointconfigdata.quality+1) and (pointconfigdata.quality+1) ~= 0) and (pointconfigdata.quality+1) or 1)*2)
    local memberrewarddata = gamedata.getIDandNUMs(pointconfigdata.member)
    print("member====1111")
    -- printT(memberrewarddata)
    ui.setLabelString(pointItems.cityrewardLabel,memberrewarddata[1].num,13)

    local idconfig = ui.IDconfig(memberrewarddata[1].cid)
    -- printT(idconfig)
    print("idconfig==1111",idconfig.icon)
    setSpriteFrameByName(pointItems.awardicon,(idconfig.icon..".png"))
    if memberrewarddata[1].cid == 1001 or memberrewarddata[1].cid == 1000 then
        pointItems.awardicon:setScale(0.4)
    else
        pointItems.awardicon:setScale(0.4)
    end


    if self.allpointsdata[tostring(cidnum)].id ~= 0 then
        pointItems.ownerNode:setVisible(true)
        ui.setLabelString(pointItems.ownerNameLabel,self.allpointsdata[tostring(cidnum)].name,29)
    else
        pointItems.ownerNode:setVisible(false)
    end
    


    
    pointItems.rewardStateNode:setVisible(true)
    print("status-===",status)
    if status then
        if status == 1 then
            print("可领取")
            -- ui.setLabelString(pointItems.rewardStateLabel,"可领取",13)
            setSpriteFrameByName(pointItems.statusSprite, "gonghuizhan_lingqu.png")
        elseif status == 2 then
            print("已领取")
            -- ui.setLabelString(pointItems.rewardStateLabel,"已领取",13)
            setSpriteFrameByName(pointItems.statusSprite, "gonghuizhan_yilingqu.png")
        else
            setSpriteFrameByName(pointItems.statusSprite, "gonghuizhan_yizhanling.png")

            -- pointItems.rewardStateNode:setVisible(false)
        end
    else
            print("已报名")
        -- ui.setLabelString(pointItems.rewardStateLabel,"已报名",13)
            setSpriteFrameByName(pointItems.statusSprite, "gonghuizhan_baoming.png")
    end



    pointItems.gotoBtn:setSwallowsTouch(true)
    pointItems.gotoBtn:setTouchPriority(-103)
    pointItems.gotoBtn:addHandleOfControlEvent(function()
        print("浮窗城池点击")
        -- cid = v.cid
        gameTouch:clickprofbytime(0.5)
        if status==1 then
            UIRequest({type = 2142,id = cidnum})
        else
            gameWindows:openWindow("guildtreasureinfo",{id = cidnum, isleader = self.isleader})
            -- UIRequest({type = 2131,id = cidnum or 1,isleader = self.isleader })
        end
        
        
    end, CCControlEventTouchUpInside)

    self.rootItems["takeBtn"..typenum]:setSwallowsTouch(true)
    self.rootItems["takeBtn"..typenum]:setTouchPriority(-102)
    self.rootItems["takeBtn"..typenum]:addHandleOfControlEvent(function()
        print("浮窗城池点击")
        -- cid = v.cid
        gameTouch:clickprofbytime(0.5)
        if status==1 then
            UIRequest({type = 2142,id = cidnum})
        else
            gameWindows:openWindow("guildtreasureinfo",{id = cidnum, isleader = self.isleader})
            -- UIRequest({type = 2131,id = cidnum or 1,isleader = self.isleader })
        end
        
        
    end, CCControlEventTouchUpInside)


    return pointNode
end

-- 公告设置
function guildWarMain.updatetimeFunc(self)

    self.rootItems.contributionLabel:setVisible(false)
    self.rootItems.contributionText:setVisible(false)

    local nowtime = os.date("*t", gamedata:time())
    print("nowtime===")
    printT(nowtime)
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local alltimes = (daynums - 1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

    -- printT(self.begintimenum)
    -- printT(self.endtimenum)
    local remaintime = 0
    -- if (self.begintimenum.week == (nowtime.wday-1) and nowtime.hour>=self.begintimenum.hour) or ((nowtime.wday-1) == self.endtimenum.week and nowtime.hour<self.endtimenum.hour) then
    print("11111==",self:gettimenum(self.begintimenum),alltimes,self:gettimenum(self.endtimenum))
    print("22222==",self:gettimenum(self.beginreadingnum),alltimes,self:gettimenum(self.endreadingnum))
    print("33333==",self:gettimenum(self.beginfightingnum),alltimes,self:gettimenum(self.endfightingnum))
    print("444444==",self:gettimenum(self.beginrewardnum),alltimes,self:gettimenum(self.endrewardgnum))

    if self:gettimenum(self.begintimenum) <= alltimes and alltimes < self:gettimenum(self.endtimenum) then

        print("报名已开始------------------")
        self.rootItems.contributionLabel:setVisible(true)
        self.rootItems.contributionText:setVisible(true)

        -- remaintime = ((self.endtimenum.week-(nowtime.wday-1))*24*3600 + self.endtimenum.hour*3600) -nowtime.hour*3600-nowtime.min*60-nowtime.sec
        remaintime = self:gettimenum(self.endtimenum) - alltimes
        if remaintime > 0 then
            self.isInspire = true
        end

        if self.inspirestatus and self.inspirestatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.inspireBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.inspireBtn)
        end

        if self.battleSignstatus and self.battleSignstatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.signBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.signBtn)
        end

        ui.setLabelString(self.rootItems.noticeDescLabel, "报名已开始，截止倒计时：", 21)
        self.rootItems.noticeTimeLabel:setVisible(true)
        print("remaintime===",remaintime)

        self.rootItems.noticeDescLabel:setPositionX(-70)

        gameTimer:rigistTime("guildwar_main", remaintime)
        gameTimer:rigistTimeFunc("guildwar_main",function()
            
            if gameTimer.times["guildwar_main"] >= 0 then
                ui.setLabelString(self.rootItems.noticeTimeLabel,ui.makeTimeText(gameTimer.times["guildwar_main"],"hour"),21)
                -- print("1111111====",ui.makeTimeText(gameTimer.times["guildwar_main"],"hour"))
                -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
            end
            if gameTimer.times["guildwar_main"] == 0 then
                print("guildwar_main====")
                gameTimer:UnrigistTimeFunc("guildwar_main")

                self:updatetimeFunc()
                UIRequest({type = 2130})
                -- ui.setLabelString(self.rootItems.noticeDescLabel, "公会战报名时间：每周四早10点 到 周五晚24点", 21)
                -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
                -- self.rootItems.noticeTimeLabel:setVisible(false)
                -- self.rootItems.noticeDescLabel:setPositionX(0)
            end
        end)
    elseif self:gettimenum(self.endtimenum) <= alltimes and alltimes < self:gettimenum(self.beginreadingnum) then
        print("等待入场--------报名已结束，距离正式开战倒计时：55:55：55----------")

        remaintime = self:gettimenum(self.beginreadingnum) - alltimes
        print("remaintime===",remaintime)

        if remaintime > 0 then
            self.isInspire = false
        end


        if self.inspirestatus and self.inspirestatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.inspireBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.inspireBtn)
        end

        if self.battleSignstatus and self.battleSignstatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.signBtn)
        else
            ui.addGray("CCControlButton",self.rootItems.signBtn)
        end

        ui.setLabelString(self.rootItems.noticeDescLabel, "报名已结束，入场倒计时：", 21)
        self.rootItems.noticeTimeLabel:setVisible(true)

        self.rootItems.noticeDescLabel:setPositionX(-70)
        gameTimer:rigistTime("guildwar_waiting", remaintime)
        gameTimer:rigistTimeFunc("guildwar_waiting",function()
            
            if gameTimer.times["guildwar_waiting"] >= 0 then
                ui.setLabelString(self.rootItems.noticeTimeLabel,ui.makeTimeText(gameTimer.times["guildwar_waiting"],"hour"),21)
                -- print("2222222====",ui.makeTimeText(gameTimer.times["guildwar_waiting"],"hour"))
                -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
            end
            if gameTimer.times["guildwar_waiting"] == 0 then
                print("guildwar_waiting====")
                gameTimer:UnrigistTimeFunc("guildwar_waiting")
                self.isInspire = false
                self:updatetimeFunc()
                UIRequest({type = 2130})

                -- ui.setLabelString(self.rootItems.noticeDescLabel, "夺宝战正在进行ing～", 21)
                -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
                -- self.rootItems.noticeTimeLabel:setVisible(false)
                -- self.rootItems.noticeDescLabel:setPositionX(0)
            end
        end)

    -- elseif self.beginreadingnum.week == (nowtime.wday-1) and (nowtime.hour>=self.beginreadingnum.hour and nowtime.min>=self.beginreadingnum.min) and (nowtime.hour <self.endreadingnum.hour and nowtime.min <self.endreadingnum.min) then
    elseif self:gettimenum(self.beginreadingnum) <= alltimes and alltimes < self:gettimenum(self.endreadingnum) then
        print("入场------------------")
        -- beginreadingnum = {week=6,hour=20,min=00)
        -- endreadingnum = {week=6,hour=20,min=10}

        -- remaintime = self.endreadingnum.min*60 - nowtime.min*60-nowtime.sec
        remaintime = self:gettimenum(self.endreadingnum) - alltimes
        print("remaintime===",remaintime)

        if remaintime > 0 then
            self.isInspire = false
        end

        if self.inspirestatus and self.inspirestatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.inspireBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.inspireBtn)
        end

        if self.battleSignstatus and self.battleSignstatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.signBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.signBtn)
        end

        ui.setLabelString(self.rootItems.noticeDescLabel, "夺宝战入场，截止倒计时：", 21)
        self.rootItems.noticeTimeLabel:setVisible(true)

        self.rootItems.noticeDescLabel:setPositionX(-70)
        gameTimer:rigistTime("guildwar_reading", remaintime)
        gameTimer:rigistTimeFunc("guildwar_reading",function()
            
            if gameTimer.times["guildwar_reading"] >= 0 then
                ui.setLabelString(self.rootItems.noticeTimeLabel,ui.makeTimeText(gameTimer.times["guildwar_reading"],"hour"),21)
                -- print("33333333333====",ui.makeTimeText(gameTimer.times["guildwar_reading"],"hour"))
                -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
            end
            if gameTimer.times["guildwar_reading"] == 0 then
                print("guildwar_reading====")
                gameTimer:UnrigistTimeFunc("guildwar_reading")
                self.isInspire = false
                self:updatetimeFunc()

                -- ui.setLabelString(self.rootItems.noticeDescLabel, "夺宝战正在进行ing～", 21)
                -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
                -- self.rootItems.noticeTimeLabel:setVisible(false)
                -- self.rootItems.noticeDescLabel:setPositionX(0)
            end
        end)

    -- elseif self.beginfightingnum.week == (nowtime.wday-1) and (nowtime.hour>=self.beginfightingnum.hour and nowtime.min>=self.beginfightingnum.min) and (nowtime.hour <self.endfightingnum.hour and nowtime.min <self.endfightingnum.min) then
    elseif self:gettimenum(self.beginfightingnum) <= alltimes and alltimes < self:gettimenum(self.endfightingnum) then
        -- beginfightingnum = {week=6,hour=20,min=10}
        -- endfightingnum = {week=6,hour=22,min=0}
        print("战斗已开始------------------")


        ui.setLabelString(self.rootItems.noticeDescLabel, "夺宝战战斗中,结束倒计时：", 21)
        -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
        self.rootItems.noticeTimeLabel:setVisible(true)
        self.rootItems.noticeDescLabel:setPositionX(-70)


        -- remaintime =(self.endfightingnum.hour-nowtime.hour)*3600 + self.endfightingnum.min*60 - nowtime.min*60-nowtime.sec
        remaintime = self:gettimenum(self.endfightingnum) - alltimes
        print("remaintime===",remaintime)
        if remaintime > 0 then
            self.isInspire = false
        end

        if self.inspirestatus and self.inspirestatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.inspireBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.inspireBtn)
        end

        if self.battleSignstatus and self.battleSignstatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.signBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.signBtn)
        end

        self.rootItems.noticeDescLabel:setPositionX(-70)
        gameTimer:rigistTime("guildwar_start", remaintime)
        gameTimer:rigistTimeFunc("guildwar_start",function()
            
            if gameTimer.times["guildwar_start"] >= 0 then
                ui.setLabelString(self.rootItems.noticeTimeLabel,ui.makeTimeText(gameTimer.times["guildwar_start"],"hour"),21)
                -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
                -- print("44444444444====",ui.makeTimeText(gameTimer.times["guildwar_start"],"hour"))
            end
            if gameTimer.times["guildwar_start"] == 0 then
                print("guildwar_start====")
                gameTimer:UnrigistTimeFunc("guildwar_start")
                self:updatetimeFunc()
                UIRequest({type = 2130})
                
                -- ui.setLabelString(self.rootItems.noticeDescLabel, "夺宝战正在进行ing～", 21)
                -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
                -- self.rootItems.noticeTimeLabel:setVisible(false)
                -- self.rootItems.noticeDescLabel:setPositionX(0)
            end
        end)
    elseif self:gettimenum(self.beginrewardnum) <= alltimes and alltimes < self:gettimenum(self.endrewardgnum) then
        -- beginrewardnum = {week=6,hour=20,min=10}
        -- endrewardgnum  = {week=6,hour=22,min=0} 
        print("领奖时间------------------")

        ui.setLabelString(self.rootItems.noticeDescLabel, "夺宝战结束,奖励通过邮件领取", 21)
        -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
        self.rootItems.noticeTimeLabel:setVisible(false)
        --self.rootItems.noticeDescLabel:setPositionX(-70)


        -- remaintime =(self.endfightingnum.hour-nowtime.hour)*3600 + self.endfightingnum.min*60 - nowtime.min*60-nowtime.sec
        remaintime = self:gettimenum(self.endrewardgnum) - alltimes
        print("remaintime===",remaintime)
        if remaintime > 0 then
            self.isInspire = false
        end

        if self.inspirestatus and self.inspirestatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.inspireBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.inspireBtn)
        end

        if self.battleSignstatus and self.battleSignstatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.signBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.signBtn)
        end

        if self.inspirestatus and self.inspirestatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.inspireBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.inspireBtn)
        end

        if self.battleSignstatus and self.battleSignstatus == 0 and self.isInspire == true then
            ui.removeGray("CCControlButton",self.rootItems.signBtn)
        else 
            ui.addGray("CCControlButton",self.rootItems.signBtn)
        end

        self.rootItems.noticeDescLabel:setPositionX(-70)
        gameTimer:rigistTime("guildwar_reward", remaintime)
        gameTimer:rigistTimeFunc("guildwar_reward",function()
            
            if gameTimer.times["guildwar_reward"] >= 0 then
                ui.setLabelString(self.rootItems.noticeTimeLabel,ui.makeTimeDayText(gameTimer.times["guildwar_reward"],"day"),21)
                -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
                -- print("44444444444====",ui.makeTimeText(gameTimer.times["guildwar_reward"],"hour"))
            end
            if gameTimer.times["guildwar_reward"] == 0 then
                print("guildwar_reward====")
                gameTimer:UnrigistTimeFunc("guildwar_reward")
                self:updatetimeFunc()
                UIRequest({type = 2130})
                
                -- ui.setLabelString(self.rootItems.noticeDescLabel, "夺宝战正在进行ing～", 21)
                -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
                -- self.rootItems.noticeTimeLabel:setVisible(false)
                -- self.rootItems.noticeDescLabel:setPositionX(0)
            end
        end)
    elseif self:gettimenum(self.endrewardgnum1) <= alltimes and alltimes < self:gettimenum(self.begintimenum2) then
        -- beginrewardnum = {week=6,hour=20,min=10}
        -- endrewardgnum = {week=6,hour=22,min=0}endrewardgnum1,begintimenum2

        print("等待第二轮公会战报名------------------")

        ui.setLabelString(self.rootItems.noticeDescLabel, "下一场战斗开启，倒计时：", 21)
        -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
        self.rootItems.noticeTimeLabel:setVisible(true)
        self.rootItems.noticeDescLabel:setPositionX(-70)


        -- remaintime =(self.endfightingnum.hour-nowtime.hour)*3600 + self.endfightingnum.min*60 - nowtime.min*60-nowtime.sec
        remaintime = self:gettimenum(self.begintimenum2) - alltimes
        print("remaintime===",remaintime)

        self.rootItems.noticeDescLabel:setPositionX(-70)
        gameTimer:rigistTime("guildwar_nextfight2", remaintime)
        gameTimer:rigistTimeFunc("guildwar_nextfight2",function()
            
            if gameTimer.times["guildwar_nextfight2"] >= 0 then
                ui.setLabelString(self.rootItems.noticeTimeLabel,ui.makeTimeText(gameTimer.times["guildwar_nextfight2"],"hour"),21)
                -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
                -- print("44444444444====",ui.makeTimeText(gameTimer.times["guildwar_nextfight2"],"hour"))
            end
            if gameTimer.times["guildwar_nextfight2"] == 0 then
                print("guildwar_nextfight2====")
                gameTimer:UnrigistTimeFunc("guildwar_nextfight2")
                self:updatetimeFunc()
                UIRequest({type = 2130})
                
                -- ui.setLabelString(self.rootItems.noticeDescLabel, "夺宝战正在进行ing～", 21)
                -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
                -- self.rootItems.noticeTimeLabel:setVisible(false)
                -- self.rootItems.noticeDescLabel:setPositionX(0)
            end
        end)

    else
        print("等待第一轮公会战报名------------------")

        ui.setLabelString(self.rootItems.noticeDescLabel, "下一场战斗开启，倒计时：", 21)
        -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
        self.rootItems.noticeTimeLabel:setVisible(true)
        self.rootItems.noticeDescLabel:setPositionX(-70)

        -- endrewardgnum2,begintimenum1
        local firstreadynum = self:gettimenum(self.begintimenum1)
        if alltimes >= self:gettimenum(self.endrewardgnum2) then
            remaintime = 7*24*3600 - alltimes + firstreadynum
        else
            remaintime = firstreadynum - alltimes
        end

        -- remaintime =(self.endfightingnum.hour-nowtime.hour)*3600 + self.endfightingnum.min*60 - nowtime.min*60-nowtime.sec
        -- remaintime = self:gettimenum(self.begintimenum2) - alltimes
        print("remaintime===",remaintime)

        self.rootItems.noticeDescLabel:setPositionX(-70)
        gameTimer:rigistTime("guildwar_nextfight1", remaintime)
        gameTimer:rigistTimeFunc("guildwar_nextfight1",function()
            
            if gameTimer.times["guildwar_nextfight1"] >= 0 then
                ui.setLabelString(self.rootItems.noticeTimeLabel,ui.makeTimeDayText(gameTimer.times["guildwar_nextfight1"],"day"),21)
                -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
                -- print("44444444444====",ui.makeTimeText(gameTimer.times["guildwar_nextfight1"],"hour"))
            end
            if gameTimer.times["guildwar_nextfight1"] == 0 then
                print("guildwar_nextfight1====")
                gameTimer:UnrigistTimeFunc("guildwar_nextfight1")
                self:updatetimeFunc()
                UIRequest({type = 2130})
                
                -- ui.setLabelString(self.rootItems.noticeDescLabel, "夺宝战正在进行ing～", 21)
                -- self.rootItems.noticeDescLabel:setString("公会战报名时间为每周四 10:00～24:00")
                -- self.rootItems.noticeTimeLabel:setVisible(false)
                -- self.rootItems.noticeDescLabel:setPositionX(0)
            end
        end)
        
        -- 当在活动时间内 刷新一次
        gameTimer:rigistTime("guildwar_main_flesh", 2*24*3600)
        gameTimer:rigistTimeFunc("guildwar_main_flesh",function()
            -- if self.begintimenum.week == (nowtime.wday-1) and nowtime.hour>=self.begintimenum.hour then
            local nowtime = os.date("*t", gamedata:time())
            local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
            local alltimes = (daynums-1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

            -- print("55555555555====",self:gettimenum(self.begintimenum),alltimes)
            if (self:gettimenum(self.begintimenum) <= alltimes and alltimes < self:gettimenum(self.endtimenum)) or (self:gettimenum(self.beginreadingnum) <= alltimes and alltimes < self:gettimenum(self.endreadingnum)) or (self:gettimenum(self.beginfightingnum) <= alltimes and alltimes < self:gettimenum(self.endfightingnum)) or (self:gettimenum(self.beginrewardnum) <= alltimes and alltimes < self:gettimenum(self.endrewardgnum)) then

                print("guildwar_main_flesh====")
                self:updatetimeFunc()
                gameTimer:UnrigistTimeFunc("guildwar_main_flesh")
            end
        end)
    end


end

function guildWarMain.gettimenum(self,times,minnum)
    -- print("minnum===",minnum)
    local min = 0
    if minnum then
        min = minnum
    end
    local alltimes = 0
    alltimes = (times.week and (times.week-1) or 0)*24*3600 + (times.hour or 0)*3600 + times.min*60 + times.sec + min*60
    return alltimes
end

function guildWarMain.reloadmembers(self,data)
    if data then
        self.isleader = false
        for k,v in pairs(data.gangmembers or {}) do
            if v.rid == data.gang2post.post1 then
                if v.rid == GameScene.roleinfo.id then self.isleader = true end
            elseif v.rid == data.gang2post.post2_1 or v.rid == data.gang2post.post2_2 or v.rid == data.gang2post.post2_3 then
                if v.rid == GameScene.roleinfo.id then self.isleader = true end
            end
        end
    end
end


function guildWarMain.clear(self)
    print("guildWarMain.clear=")

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.mapNode then
        self.mapNode = nil
        self.mapItems = nil
    end
    self.isInspire = false
    

    if gameTimer.times["guildwar_main"] then
        gameTimer:UnrigistTimeFunc("guildwar_main")
    end

    if gameTimer.times["guildwar_main_flesh"] then
        gameTimer:UnrigistTimeFunc("guildwar_main_flesh")
    end

    if gameTimer.times["guildwar_reading"] then
        gameTimer:UnrigistTimeFunc("guildwar_reading")
    end

    if gameTimer.times["guildwar_waiting"] then
        gameTimer:UnrigistTimeFunc("guildwar_waiting")
    end

    if gameTimer.times["guildwar_start"] then
        gameTimer:UnrigistTimeFunc("guildwar_start")
    end

    if gameTimer.times["guildwar_reward"] then
        gameTimer:UnrigistTimeFunc("guildwar_reward")
    end
    
    if gameTimer.times["guildwar_nextfight1"] then
        gameTimer:UnrigistTimeFunc("guildwar_nextfight1")
    end

    if gameTimer.times["guildwar_nextfight2"] then
        gameTimer:UnrigistTimeFunc("guildwar_nextfight2")
    end
    
end

return guildWarMain
