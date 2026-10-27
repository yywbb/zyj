--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/3
-- Time: 下午1:31
-- To change this template use File | Settings | File Templates.
--


local task = {

    rootNode = nil,
    rootItems = nil,

    normaltableview = nil,
    dailytableview = nil,

    dailydata = {},
    datarewards = {},
    itemdata = {},
    rewarddata = {},

    -- pageconfig = {"liveness","normal"} ,
    pageconfig = {"liveness"} ,
    -- pagename = {"日常任务","成 就"},
    pagename = {gameConfig.strings:string_common("task",0),gameConfig.strings:string_common("task",1)},
    selectpage = "liveness",

    normaldata = {},

    activennum = 0,

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {40},
                --title2 = {44},
            },
        },
    },
    firstdata = 0,

    livenessNum = 0,
    isscrolltouched = false,

    isfirst = false,

    titleCellSize = {x=180,y=180},
}

function task.shiftPage(self,type)

    self.selectpage = type
    for k,v in ipairs(self.pageconfig)  do
        if v == type then
            self.rootItems[v.."Node"]:setPosition(ccp(0,0))
            self.rootItems[v.."Top"]:setPosition(ccp(0,0))
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Top"]:setVisible(true)
        -- else
            self.rootItems["normal".."Node"]:setPosition(ccp(99999,0))
            self.rootItems["normal".."Top"]:setPosition(ccp(99999,0))
            self.rootItems["normal".."Node"]:setVisible(false)
            self.rootItems["normal".."Top"]:setVisible(false)
        end
    end

    if self.selectpage == "liveness" then
        if not next(self.itemdata) then
            print("liveness====")
            UIRequest({type = 2410})
            if self.weekisopen then
                UIRequest({type = 6517})
            end
        end
    else
        if not next(self.normaldata) then
            print("normaldata====")
            UIRequest({type =2400})
        end
    end
end


function task.init(self,parent,toppos)

    self.rootNode,self.rootItems = CCBReaderLoad("reward/reward", nil, true, "reward")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    -- self.rootItems.toptitle:setPositionY(toppos)
    self.toppos = toppos


    local config = gamedata.config.build[tostring(542)]
    if gameConfig:checkBuildOpen(542) and config and config.level <= GameScene.roleinfo.level then
        self.weekisopen = true
        self.rootItems.weekDailyNode:setVisible(true)
        self.rootItems.dailyScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-270-140-200))
        self.rootItems.dailyScroll:setPositionY(self.rootItems.dailyScroll:getPositionY()+200)
    else
         self.weekisopen = false
          self.rootItems.weekDailyNode:setVisible(false)
        self.rootItems.dailyScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-270-140))
    end   

    self.rootItems.normalScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))


    --成就的全部领取
    -- ui.setLabelString(self.rootItems.allbuttontext, "全部领取" ,18)
    ui.setLabelString(self.rootItems.allbuttontext, gameConfig.strings:string_common("task",2) ,18)
    self.rootItems.allbutton:setSwallowsTouch(true)
    self.rootItems.allbutton:setTouchPriority(-102)
    self.rootItems.allbutton:addHandleOfControlEvent(function()
        if self.activennum > 0 then
            UIRequest({type = 2401, })
        else
            -- runGamePrompt({msg = "无可领取的奖励"})
            runGamePrompt({msg = gameConfig.strings:string_common("task",3)})
        end
    end, CCControlEventTouchUpInside)

    --日常任务的全部领取
    ui.setLabelString(self.rootItems.allrewordtxt, gameConfig.strings:string_common("task",2) ,18)
    self.rootItems.allrewordbutton:setSwallowsTouch(true)
    self.rootItems.allrewordbutton:setTouchPriority(-102)
    self.rootItems.allrewordbutton:addHandleOfControlEvent(function()
        if self.livenessNum > 0 then
            UIRequest({type = 2411, })
        else
            -- runGamePrompt({msg = "无可领取的奖励"})
            runGamePrompt({msg = gameConfig.strings:string_common("task",3)})
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.button_back:setSwallowsTouch(true)
    self.rootItems.button_back:setTouchPriority(-121)
    self.rootItems.button_back:addHandleOfControlEvent(function()
        GameScene:shiftLayer("main","down")
    end, CCControlEventTouchUpInside)


    -- ui.setLabelString(self.rootItems.lab_m1, nil, 121)
    ui.setLabelString(self.rootItems.lab_m2, nil, 121)

    if not next(self.dailydata) then
        for k,v in pairs(gamedata.config.liveness) do
            table.insert(self.dailydata,table.copy(v))
        end
    end

    self.datarewards = table.copy(gamedata.config.liveness_reward)

    for k,v in pairs(self.datarewards) do
        local otherReward = ""
        if v["begin"] and v["begin"]~= "" and v["end"] and v["end"]~= ""  then
            local now =  gamedata:time()

            local b_year,b_month,b_day,b_hour,b_minute,b_second = ui.getDate(v["begin"])
            local e_year,e_month,e_day,e_hour,e_minute,e_second = ui.getDate(v["end"])
            local begint = os.time({year=tonumber(b_year), month=tonumber(b_month),day=tonumber(b_day),hour=tonumber(b_hour),min=tonumber(b_minute),sec=tonumber(b_second)})
            local endt = os.time({year=tonumber(e_year), month=tonumber(e_month),day=tonumber(e_day),hour=tonumber(e_hour),min=tonumber(e_minute),sec=tonumber(e_second)})
            
            if now>= begint and  now< endt then
              --在时间范围内返回true
               v.reward = v.additional_drop..v.reward
            end
        end
    end

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","task",touchbegin)
    local function touchend(pos)
        if self.rootItems.normalScroll and ui.isTouched(self.rootItems.normalScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.dailyScroll and ui.isTouched(self.rootItems.dailyScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","task",touchend)
    
    self:shiftPage(self.selectpage)

    local luckSpr = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("sta_18.png"))
    self.rootItems.process = CCProgressTimer:create(luckSpr);
    self.rootItems.process:setAnchorPoint(ccp(0.5,0.5))
    self.rootItems.process:setType(kCCProgressTimerTypeBar)
    self.rootItems.process:setMidpoint(ccp(0,0.5))
    self.rootItems.process:setBarChangeRate(ccp(1,0))
    self.rootItems.process:setPosition(ccp(0,0))
    self.rootItems.process:setScaleX(1.092)
    self.rootItems.process:setScaleY(1.5)
    self.rootItems.process:setPercentage(0)
    self.rootItems.processNode:addChild(self.rootItems.process)

    --玄月秘宝
    self.rootItems.xueyueNode:setVisible(false)

    ui.setLabelString(self.rootItems.meiri_zi, nil, 13)
    
    self.xuanyueReward1 = false
    self.xuanyueReward2 = false
    self.xuanyueReward3 = false

    if gameConfig:checkBuildOpen(539) then
        UIRequest({type = 7060})
    end

    if gameConfig:checkBuildOpen(559) then
        UIRequest({type = 7063})
    end

    if gameConfig:checkBuildOpen(577) then
        UIRequest({type = 7072})
    end
end

function task.setXuanyueTreasures(self,data)
    if self.xuanyueReward1 then
        return
    end
    if data.day.isopen == 1 then
        self.xuanyueReward1 = true
        local datarewards = {}
        for k,v in pairs(self.datarewards) do
            datarewards[k] = table.copy(v)
            if datarewards[k].xuanyue_reward then
                datarewards[k].reward = datarewards[k].reward..datarewards[k].xuanyue_reward
            end
        end
        self.datarewards = datarewards
    end
end

function task.setXuanyueTreasures2(self,data)

    if self.xuanyueReward2 then
        return
    end

    if data.day.isopen == 1 then
        self.xuanyueReward2 = true
        local datarewards = {}
        for k,v in pairs(self.datarewards) do
            datarewards[k] = table.copy(v)
            if datarewards[k].xuanyue2_reward then
                datarewards[k].reward = datarewards[k].reward..datarewards[k].xuanyue2_reward
            end
        end
        self.datarewards = datarewards
    end
end

function task.setXuanyueTreasures3(self,data)

    if self.xuanyueReward3 then
        return
    end
    if data.day.isopen == 1 then
        self.xuanyueReward3 = true
        local datarewards = {}
        for k,v in pairs(self.datarewards) do
            datarewards[k] = table.copy(v)
            if datarewards[k].xuanyue3_reward then
                datarewards[k].reward = datarewards[k].reward..datarewards[k].xuanyue3_reward
            end
        end
        self.datarewards = datarewards
    end
end

function task.clear(self)
    gameTouch:UnrigistFunc("begin","task")
    gameTouch:UnrigistFunc("end","task")    
    self.isscrolltouched = false
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.firstdata = 0

    self.selectpage = "liveness"
    self.itemdata = {}
    self.normaldata = {}
    self.normaltableview = nil
    self.dailytableview = nil
    self.rootNode = nil
    self.rootItems = nil
    self.isfirst = false
    self.generalListTableView = nil
end

function task.reloadWeekDaily( self,data)

    self.week_datarewards = gamedata.config.week_liveness_reward or {} --配置表
    self.week_huoyuedu = data.huoyuedu --活跃度
    self.week_data =  data.weekstatus --宝箱状态

    self.sort_week_data =  {}

    local num  = table.getTableLength(self.week_data)
    for i=1,num do
         if self.week_data[tostring(i)] ==1 then
            table.insert(self.sort_week_data,{rewardid = i,status = self.week_data[tostring(i)]})
         end   
    end
    for i=1,num do
         if self.week_data[tostring(i)] ==0  then
            table.insert(self.sort_week_data,{rewardid = i,status = self.week_data[tostring(i)]})
         end   
    end
    for i=1,num do
         if self.week_data[tostring(i)] ==2 then
            table.insert(self.sort_week_data,{rewardid = i,status = self.week_data[tostring(i)]})
         end   
    end
    ui.setLabelString(self.rootItems.liveness_weeknum2, self.week_huoyuedu, 18)
    if table.getTableLength(self.sort_week_data) <=0 then
        self.rootItems.liveness_weekfull:setVisible(true)
        self.rootItems.weekMore:setVisible(false)
    else
        self.rootItems.liveness_weekfull:setVisible(false)
        self.rootItems.weekMore:setVisible(true)
    end

    if self.generalListTableView then
        self.generalListTableView:reloadData()
    else
        self:initWeekDaily()
    end
end

function task.initWeekDaily(self)
    if self.rootItems.weekListNode then
        self.rootItems.weekListNode:removeAllChildrenWithCleanup(true)
    end    

    self.rootItems.weekListFullBtn:setSwallowsTouch(true)
    self.rootItems.weekListFullBtn:setTouchPriority(-122)

    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("reward/zhouhuoyuebox.ccbi", nil, true, "zhouhuoyuebox")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }

                ui.tableviewAnimationH(self.generalListTableView,cellCCB,self.titleCellSize.x, self.titleCellSize.y,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local index = self.sort_week_data[a1+1].rewardid or 1
            local status = self.sort_week_data[a1+1].status or 0 --0未开启 1可领取
             -- printT(self.sort_week_data[a1+1],"1")
            print(index.." index")
            local itemdata = self.week_datarewards[tostring(index)] or {}
            printT(itemdata,"itemdata")
            ccbDocumentControler.boxdesc:setString(tostring(itemdata.point))

            ccbDocumentControler["boxeffect"]:removeAllChildrenWithCleanup(true)
            -- if  status == 1 then
            --     local ccb, item = CCBReaderLoad("UIEffect/baoxiangkelingqu/baoxiangkelingqu2.ccbi", nil, true, "baoxiangkelingqu")
            --     ccbDocumentControler["boxeffect"]:addChild(ccb)
            -- end

            local icon = itemdata["icon_"..(status+1)]
            setSpriteFrameByName(ccbDocumentControler.box, icon)
            -- setSpriteFrameByName(ccbDocumentControler.box, "box1_"..status)
            local _reward = ui.getIDandNUMs(itemdata.reward)
            ccbDocumentControler.s_button:setSwallowsTouch(false)
            ccbDocumentControler.s_button:setTouchPriority(-123)
            ccbDocumentControler.s_button:addHandleOfControlEvent(function()
                -- if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                if status == 1 then
                    print("1")
                    UIRequest({type = 6530,id = index})

                 else
                    gameWindows:openWindow("getStaff",{data = _reward,type = "奖励预览"},nil)
                 end   
             end, CCControlEventTouchUpInside)

            if self.generalListTableView then
                cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.sort_week_data)
        elseif fn == "cellTouched" then
        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.generalListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.weekListNode:getContentSize().width,
        viewheight = self.rootItems.weekListNode:getContentSize().height,
        dire = 0
    })
    self.generalListTableView:setTouchPriority(-122)
    self.rootItems.weekListNode:addChild(self.generalListTableView)
end


function task.setCell(self,item,data)

    local config = gamedata.config.task[tostring(data.cid)]
    setSpriteFrameByName(item.i_icon,  config.icon)
    ui.setSpriteTextureRect(item.i_icon,0,0,150,150)

    item.des:setString(config.desc)
    -- local reward = "获得"..ui.IDconfig(config.award1).name.."X"..config.award1num
    local reward = gameConfig.strings:getAward(ui.IDconfig(config.award1).name,config.award1num)

    item.content:setString(reward)

    if data.now then
        item.targetnode:setVisible(true)
        if (config.type == "copy") or (config.type == "blood") then
            if data.status == 1 then
                ui.setLabelString(item.target, "1/1",13)
            else
                ui.setLabelString(item.target, "0/1",13)
            end
        elseif string.find(config.target,",") then
            local i = string.find(config.target,",")
            local j = string.sub(config.target, i+1, string.len(config.target))
            ui.setLabelString(item.target, data.now.."/"..j,13)
        else
            ui.setLabelString(item.target, data.now.."/"..config.target,13)
        end

    else
        item.targetnode:setVisible(false)
    end


    if data.status == 0 then
        ui.addGray("CCControlButton",item.button)
        ui.addGray("CCLabelTTF",item.buttontext)
        -- ui.setLabelString(item.buttontext, "未达成" ,18)
        ui.setLabelString(item.buttontext, gameConfig.strings:string_common("task",4) ,18)
        item.button:setTouchPriority(-102)
        item.button:addHandleOfControlEvent(function()
            -- if not self.isscrolltouched then return end
            -- if gameTouch.isScrollling then return end
        end, CCControlEventTouchUpInside)
    elseif data.status == 1 then
        ui.removeGray("CCControlButton",item.button)
        ui.removeGray("CCLabelTTF",item.buttontext)
        -- ui.setLabelString(item.buttontext, "领 取" ,18)
        ui.setLabelString(item.buttontext, gameConfig.strings:string_common("moreCommon",6) ,18)
        item.button:setTouchPriority(-102)
        item.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
             UIRequest({type = 2401, id = data.cid})
        end, CCControlEventTouchUpInside)
    end

end

function task.createnormalListview(self)
    local celldict = {}
    local normalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080,242)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("reward/cell_task.ccbi", nil, true, "cell_task")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.normaltableview,cellCCB,1080/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.normaldata[a1+1])

            if self.normaltableview then
                cellCCB:setPosition(1080/2, 0)
            end
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.normaldata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.normaltableview = ui.createLuaTableView({
        handle = normalListHandle,
        viewwidth = self.rootItems.normalScroll:getContentSize().width,
        viewheight = self.rootItems.normalScroll:getContentSize().height,
        dire = 1
    })
    self.normaltableview:setTouchPriority(-101)
    self.rootItems.normalScroll:addChild(self.normaltableview)
end


function task.reloaddata(self,data)
    local oldnumnormal =  table.getTableLength(self.normaldata)

    self.normaldata = {}
    self.activennum = 0
    for k,v in pairs(data.task) do
        table.insert(self.normaldata,v)
        if v.status == 1 then self.activennum = self.activennum +1  end
    end

    local sortbyid = function(a,b) return a.status == b.status and a.cid< b.cid or a.status > b.status end
    table.sort(self.normaldata,sortbyid)

    self.rootItems.num:setString(self.activennum.."/"..table.getTableLength(data.task))

    ui.setLabelString(self.rootItems.num, self.activennum.."/"..table.getTableLength(data.task), 18)

    local newnumnormal =  table.getTableLength(self.normaldata)

    if self.normaltableview then
        self.normaltableview:reloadData()
        self.normaltableview:setLuaContentOffset(0, self.normaltableview:getLuaContentOffsetY() - (newnumnormal - oldnumnormal)*242 )
    else
        self:createnormalListview()
    end

    if self.activennum > 0 then
        ui.removeGray("CCControlButton",self.rootItems.allbutton)
    else
        ui.addGray("CCControlButton",self.rootItems.allbutton)
    end

    --self:shiftPage(self.selectpage)
end

function task.setDaily(self,item,data,index)
    printT(data)

    local key_Ex
    local icon_key
    if index == nil or index == 1 then
        key_Ex = ""
    else
        key_Ex = "2"
    end

    if not data then
        return
    end

    local reward_id,reward_num = ui.getIDandNUM(data.reward)
    local reward_config = ui.IDconfig(reward_id)

    item["name"..key_Ex]:setString(data.desc or " ")

    -- item.name_reward:setString("奖励: "..reward_config.name.."x"..reward_num)
    -- item.num_h:setString("奖励: "..tostring(data.point or 0).."点活跃度")

    if data.description then
        -- item.name_reward:setString("奖励: "..data.description)
        ui.setLabelString(item["name_reward"..key_Ex], "奖励："..data.description,13)
    else    
        -- item.name_reward:setString(gameConfig.strings:awardNum(reward_config.name,reward_num))
        ui.setLabelString(item["name_reward"..key_Ex], gameConfig.strings:awardNum(reward_config.name,reward_num),13)
    end
    ui.setLabelString(item["jiangli"..key_Ex], nil, 13)
    -- item["num_h"..key_Ex]:setString(gameConfig.strings:awardPoint(tostring(data.point or 0)))
    ui.setLabelString(item["num_h"..key_Ex], gameConfig.strings:awardPoint(tostring(data.point or 0)), 4)

    ui.setLabelString(item["jindu"..key_Ex], nil, 13)
    ui.setLabelString(item["num_t"..key_Ex], (self.itemdata[tostring(data.id)] and self.itemdata[tostring(data.id)].num or 0).."/"..data.num or 0,4)

    setSpriteFrameByName(item["i_icon"..key_Ex],data.icon)

    item["button"..key_Ex]:setTouchPriority(-102)

    ui.sethint(item["hint_reward"..key_Ex], false)
    if self.itemdata[tostring(data.id)] and self.itemdata[tostring(data.id)].status == 1 then
        item["button"..key_Ex]:setVisible(true)
        item["buttontext"..key_Ex]:setVisible(true)
        setControlButtonFrame(item["button"..key_Ex], "b_s_button2", "b_s_button2_h","b_s_button2")
        -- ui.setLabelString(item.buttontext, "领 取" ,18)
        ui.setLabelString(item["buttontext"..key_Ex], gameConfig.strings:string_common("moreCommon",6) ,18)
        ui.removeGray("CCControlButton",item["button"..key_Ex])
        ui.removeGray("CCLabelTTF",item["buttontext"..key_Ex])
        item["button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            UIRequest({type = 2411, id = 100+data.id})
        end, CCControlEventTouchUpInside)
        ui.sethint(item["hint_reward"..key_Ex], true)
    elseif self.itemdata[tostring(data.id)] and self.itemdata[tostring(data.id)].status == 2 then
        item["button"..key_Ex]:setVisible(true)
        item["buttontext"..key_Ex]:setVisible(true)
        setControlButtonFrame(item["button"..key_Ex], "b_s_button2", "b_s_button2_h","b_s_button2")
        -- ui.setLabelString(item.buttontext, "已领取" ,18)
        ui.setLabelString(item["buttontext"..key_Ex], gameConfig.strings:string_common("moreCommon",5) ,18)
        ui.addGray("CCControlButton",item["button"..key_Ex])
        ui.addGray("CCLabelTTF",item["buttontext"..key_Ex])
        item["button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            -- runGamePrompt({msg = "已领取"})
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)
    else
        
        setControlButtonFrame(item["button"..key_Ex], "b_s_button1", "b_s_button1_h","b_s_button1")
        -- ui.setLabelString(item.buttontext, "前 往" ,18)
        ui.setLabelString(item["buttontext"..key_Ex], gameConfig.strings:string_common("task",5) ,18)
        -- ui.removeGray("CCControlButton",item.button)
        -- ui.removeGray("CCLabelTTF",item.buttontext)
        item["button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            GameScene:shiftLayerById(data.sys,data.sysparam)
        end, CCControlEventTouchUpInside)

        --
        if data.sys and data.sys > 0 then 
            item["button"..key_Ex]:setVisible(true)
            item["buttontext"..key_Ex]:setVisible(true)
            --
            if GameScene:checkopenlevelbyId(data.sys,true) then
                ui.removeGray("CCControlButton",item["button"..key_Ex])
                ui.removeGray("CCLabelTTF",item["buttontext"..key_Ex])
            else
                ui.addGray("CCControlButton",item["button"..key_Ex])
                ui.addGray("CCLabelTTF",item["buttontext"..key_Ex])
            end    
        else
            item["button"..key_Ex]:setVisible(false)
            item["buttontext"..key_Ex]:setVisible(false)
        end

    end

end

function task.createdailyListview(self)
    local celldict = {}
    local specialListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080,320)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("reward/cell_daily_new.ccbi", nil, true, "cell_daily")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.dailytableview,cellCCB,1080/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setDaily(ccbDocumentControler,self.dailydata[(a1+1)*2-1] or self.dailydata[tostring((a1+1)*2-1)],1)
            if self.dailydata[(a1+1)*2] or self.dailydata[tostring((a1+1)*2)] then
                self:setDaily(ccbDocumentControler,self.dailydata[(a1+1)*2] or self.dailydata[tostring((a1+1)*2)],2)
                ccbDocumentControler.node2:setVisible(true)
            else
                ccbDocumentControler.node2:setVisible(false)
            end

            if self.dailytableview then
                cellCCB:setPosition(1080/2, 0)
            end
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.dailydata)
            r = math.ceil(table.getTableLength(self.dailydata)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.dailytableview = ui.createLuaTableView({
        handle = specialListHandle,
        viewwidth = self.rootItems.dailyScroll:getContentSize().width,
        viewheight = self.rootItems.dailyScroll:getContentSize().height,
        dire = 1
    })
    self.dailytableview:setTouchPriority(-101)
    self.rootItems.dailyScroll:addChild(self.dailytableview)
end

function task.setLivenessOne(self,status,i)

    if self.rootItems["boxnode"..i] then
        self.rootItems["boxnode"..i]:setPositionX(943*(self.datarewards[tostring(i)].point/150)-470)
    end

    ui.setLabelString(self.rootItems["boxdesc"..i],self.datarewards[tostring(i)].point or "",14)
    -- if status == 0 then
    --     ui.addGray("CCSprite",self.rootItems["boxstate"..i])
    -- else
    --     ui.removeGray("CCSprite",self.rootItems["boxstate"..i])
    -- end
    setSpriteFrameByName(self.rootItems["box"..i], "box"..(i>4 and 4 or i).."_"..status)

    -- ui.setLabelString(self.rootItems["boxdes"..i], status == 2 and "已领取" or self.datarewards[tostring(i)].point.."活跃度", status == 2 and 13 or 11)
    -- ui.setLabelString(self.rootItems["boxdes"..i], status == 2 and gameConfig.strings:string_common("moreCommon",5) or gameConfig.strings:getActivity(self.datarewards[tostring(i)].point), status == 2 and 13 or 11)
    self.rootItems["boxeffect"..i]:removeAllChildrenWithCleanup(true)
    if  status == 1 then
        local ccb, item = CCBReaderLoad("UIEffect/baoxiangkelingqu/baoxiangkelingqu2.ccbi", nil, true, "baoxiangkelingqu")
        self.rootItems["boxeffect"..i]:addChild(ccb)
        -- local ccb2, item2 = CCBReaderLoad("UIEffect/lizi/baoxiang.ccbi", nil, true, "baoxiang")
        -- self.rootItems["boxeffect"..i]:addChild(ccb2)
    end

    self.rootItems["s_button"..i]:setSwallowsTouch(true)
    self.rootItems["s_button"..i]:setTouchPriority(-102)
    self.rootItems["s_button"..i]:addHandleOfControlEvent(function()
        -- 双倍活动判断
        local tempdata = ui.getIDandNUMs(self.datarewards[tostring(i)].reward) or {}
        local datatmp = false
        datatmp = ui.CheckHuodongByParam(1)
        local timesnum = ui.GetHuodongModulus(1)
        -- datatmp = ui.CheckHuodongByParam(1)
        -- local timesnum = ui.GetHuodongModulus(1)
        if self.datarewards[tostring(i)].drop_lv and self.datarewards[tostring(i)].drop_extra then
            if GameScene.roleinfo.level >= self.datarewards[tostring(i)].drop_lv then
                local extdata = ui.getTableFromStr(self.datarewards[tostring(i)].drop_extra)
                if extdata and next(extdata) then
                    for i,v in ipairs(extdata) do
                        v.extra = 1
                        table.insert(tempdata,v)
                    end    
                end    
            end    
        end    

        if datatmp then
            for i,v in ipairs(tempdata) do
                v.num = v.num * tonumber(timesnum)
            end
        end
        print("rewardDoule==",datatmp,timesnum)

        if status == 0 then
            -- gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(self.datarewards[tostring(i)].reward),type = gameConfig.strings:string_common("task",6), huodongnum = 1},nil)
            gameWindows:openWindow("getStaff",{data = tempdata,type = gameConfig.strings:string_common("task",6), isrewarddouble = datatmp},nil)
        elseif status == 1 then
            UIRequest({type = 2411, id =i})
        elseif status == 2 then
            -- gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(self.datarewards[tostring(i)].reward),type = "已领取"},nil)
            gameWindows:openWindow("getStaff",{data = tempdata,type = gameConfig.strings:string_common("moreCommon",5), isrewarddouble = datatmp},nil)
        end
    end, CCControlEventTouchUpInside)
end

function task.reloadDaily(self,data,id)

    printT(data)
    self.livenessNum = 0
    for k,v in pairs(data.items) do
        if v.status == 1 then
            self.livenessNum = self.livenessNum + 1
        end
    end

    self.itemdata = data.items
    self.rewarddata = data.reward

    -- ui.setLabelString(self.rootItems["boxdesc0"],nil,13)
    for i =1, 5 do
        self:setLivenessOne(self.rewarddata[tostring(i)],i)
    end

    self.dailydata = {}
    for k,v in pairs(gamedata.config.liveness) do
        if self.itemdata[tostring(v.id)] and self.itemdata[tostring(v.id)].num and self.itemdata[tostring(v.id)].num < 0 then
            --notshow
        else    
            table.insert(self.dailydata,table.copy(v))
        end
    end   

    for k,v in pairs(self.dailydata) do
        if self.itemdata[tostring(v.id)] then
            if self.itemdata[tostring(v.id)].status == 2 then
                v.seq = 400 + (gamedata.config.liveness[tostring(v.id)] and gamedata.config.liveness[tostring(v.id)].seq or 0 )
            elseif self.itemdata[tostring(v.id)].status == 1 then
                v.seq = -200 + (gamedata.config.liveness[tostring(v.id)] and gamedata.config.liveness[tostring(v.id)].seq or 0 )
            elseif gamedata.config.liveness[tostring(v.id)].sys and gamedata.config.liveness[tostring(v.id)].sys > 0 and not GameScene:checkopenlevelbyId(gamedata.config.liveness[tostring(v.id)].sys,true) then
                v.seq = 200 + (gamedata.config.liveness[tostring(v.id)] and gamedata.config.liveness[tostring(v.id)].seq or 0 )
            else    
                v.seq = (gamedata.config.liveness[tostring(v.id)] and gamedata.config.liveness[tostring(v.id)].seq or 0 )
            end
        else
            v.seq = 0
        end
    end

    table.sort(self.dailydata, function(a,b) return a.seq < b.seq end)

    local now = 0
    local total = 0
    for k,v in pairs(self.dailydata) do
        total = total + v.point
        if self.itemdata[tostring(v.id)] and self.itemdata[tostring(v.id)].status == 2 then
            now = now + v.point
        end
    end

    --ui.setSpriteTextureRect2(self.rootItems.process,0,0,465 * (now > 150 and 150 or now) / 150,19)
    local nowDtSp = 100*(now > 150 and 150 or now) / 150
    local processSpr = CCProgressFromTo:create(0.5,self.firstdata,nowDtSp)
    self.rootItems.process:runAction(processSpr)
    self.firstdata = nowDtSp
   
    if now < 15  then
        isfirst = true
    end    
    if isfirst then
        if now >=15 then
            print("牧游推广 深度数据提交 活跃度 reloadDailyShengdu")
            isfirst = false
            if gamedata.gameconfig and gamedata.gameconfig.isshengduTG then
                if gamedata.sdk and gamedata.sdk.sdkShengDu then
                    gamedata.sdk:sdkShengDu("huoyuedu")
                    print("now --------3-")
                end    
            end 
        end   
    end    

    ui.setLabelString(self.rootItems.liveness_num, tostring(now), 18)

    if self.dailytableview then
        self.dailytableview:reloadData()
    else
        self:createdailyListview()
    end

    if self.livenessNum > 0 then
        ui.removeGray("CCControlButton",self.rootItems.allrewordbutton)
    else
        ui.addGray("CCControlButton",self.rootItems.allrewordbutton)
    end
end

function task.UIUpdateData(self, isreset)
    if isreset then
        self:shiftPage(self.selectpage)
    end
end

return task   щ  