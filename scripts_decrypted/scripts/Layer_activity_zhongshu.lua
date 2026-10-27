--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local treerise = {
    isscrolltouched = false,
    buttontouch = -103,

    tasklistview = nil,
    normalCellSize = {x=1080,y=230},
}


function treerise.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("zhongshu/zhongshu",nil, true, "zhongshu")
    -- self.coverccb, self.coveritems = CCBReaderLoad("zhongshu/guoqingzhufu",nil, true, "guoqingzhufu")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.bottomnode:setPositionY(self.contentsize.y-180)
    self.coveritems.tasklist:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-1170))

    self.coveritems.rankbutton:setTouchPriority(self.buttontouch)
    self.coveritems.rankbutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("zhongshuRank",self.main.point)
    end, CCControlEventTouchUpInside)

    self.coveritems.ruleButton:setTouchPriority(self.buttontouch)
    self.coveritems.ruleButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("zhongshuRule")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.coveritems.waterdes,"当前拥有:",14)
    ui.setLabelString(self.coveritems.pointdes,"当前拥有灌溉积分: ",13)
    -- ui.setLabelString(self.coveritems.pointdes,"当前拥有祝福积分: ",13)

    self.coveritems.buywater:setTouchPriority(self.buttontouch)
    self.coveritems.buywater:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        --local limit = gamedata.config.global_kv.zhongshu_time.value

        if self.extra_time then
            return runGamePrompt({msg = "活动结束"})
        end
        gameWindows:openWindow("buyprop",{
                usenum = self.main.waterbuy,
                --maxnum = tonumber(limit),
                id = 20604,
                request = 5328,
                pricekey = "zhongshu_consume",
            })
    end, CCControlEventTouchUpInside)

    self.coveritems.waterbutton:setTouchPriority(self.buttontouch)
    self.coveritems.waterbutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if self.extra_time then
            return runGamePrompt({msg = "活动结束"})
        end

        if self.pronum < 10 then
            runGamePrompt({msg = "水滴不足"})
        else
            --20870
            gameWindows:openWindow("water",{id = 20604,total = self.pronum},function(usenum)
                UIRequest({type = 5324,num=usenum})
            end)
        end
    end, CCControlEventTouchUpInside)

    

    self.coveritems.resetbutton:setSwallowsTouch(true)
    self.coveritems.resetbutton:setTouchPriority(self.buttontouch-4)
    self.coveritems.resetbutton:addHandleOfControlEvent(function()

        if self.extra_time then
            return runGamePrompt({msg = "活动结束"})
        end

        local cando = false
        for k,v in pairs(self.tasks) do
            if v.status==0 then
                cando = true
                break
            end
        end
        if cando then
            local cost = self:getBuyPrice("zhongshu_tasks",self.main.freshtimes+1)
            if cost>GameScene.roleinfo.gold then
                shortGold()
            else
                UIRequest({type = 5329})
            end
        else
            runGamePrompt({msg = gameConfig.strings:string_common("activity_zhounian",16)})
        end
    end, CCControlEventTouchUpInside)
    
    self.totalpoint = 0
    for k,v in pairs(gamedata.config.zhongshu_awards) do
        self.totalpoint = math.max(self.totalpoint,v.integral)
    end

    -- 活动时间
    local timediff = 0
    if self.coveritems.time and gamedata.config.activity_time["102"]["end"] and gamedata.config.activity_time["102"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["102"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;

        self.extra_time = (timediff <= 0)
    end
    

    if self.extra_time then
        timediff = timediff + 86400 * gamedata.config.activity_time["102"].extra_time
        ui.addGray("CCControlButton",self.coveritems.resetbutton)
    else
        ui.removeGray("CCControlButton",self.coveritems.resetbutton)
    end

    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("Activitytree",timediff)

        if gameTimer.times["Activitytree"] and gameTimer.times["Activitytree"] > 0 then
            gameTimer:rigistTimeFunc("Activitytree", function()
                if gameTimer.times["Activitytree"] <= 0 then
                    if gameTimer.times["Activitytree"] then
                        gameTimer:UnrigistTimeFunc("Activitytree")
                    end
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["Activitytree"],"day"))
                    ui.setLabelString(self.coveritems.time,nil,23)
                end
            end)
        end
    end

    ui.setLabelString(self.coveritems.time,nil,23)
    if self.extra_time then
        ui.setLabelString(self.coveritems.desc1,"展示结束倒计时: ",14)
    else
        ui.setLabelString(self.coveritems.desc1,"活动结束倒计时: ",14)
    end
    

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","treerise",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","treerise",touchend)
    --

    return self.coverccb
end

function treerise.getBuyPrice( self,key,count )
    local config = gamedata.config.buycount_price
    return config[tostring(count)] and config[tostring(count)][key] or config[tostring(table.getTableLength(config))][key]
end

function treerise.reloaddata(self,t)
    if not self.show then return end

    if t.data.pronum then
        ui.setLabelString(self.coveritems.water,t.data.pronum,23)
        self.pronum = t.data.pronum
    end

    self.coveritems.hintwater:setVisible(self.pronum>=50 and (not self.extra_time))

    if t.data.reward then
        showRewardPopupWindow(t.data.reward,nil)
        UIRequest({type = 1001})
    end

    local main = t.data.main
    local oldmain = self.main and table.copy(self.main) or nil
    if oldmain and main.point>oldmain.point then
        runGamePrompt({msg = "祝福积分+"..(main.point-oldmain.point)})
    end 
    self.main = main or self.main

    local totaltasks = tonumber(gamedata.config.global_kv.zhongshu_task_times.value)
    ui.setLabelString(self.coveritems.taskdes,gameConfig.strings:string_common("activity_zhounian",7)..(totaltasks-self.main.tasktimes),14) 

    local cost = self:getBuyPrice("zhongshu_tasks",self.main.freshtimes+1)
    ui.setLabelString(self.coveritems.refreshgold,cost,cost<=GameScene.roleinfo.gold and 13 or 24) 

    ui.setLabelString(self.coveritems.point,self.main.point,2)
    ui.setSpriteTextureRect2(self.coveritems.pointbar,0,0,807 * ((self.main.point > self.totalpoint) and 1 or (self.main.point/self.totalpoint)),22)

    local rewardconfig = gamedata.config.zhongshu_awards
    for i=1,3 do
        local oneconfig = rewardconfig[tostring(i)]
        self.coveritems["reward"..i]:setPositionX(807*(oneconfig.integral/self.totalpoint)-405)
        ui.setLabelString(self.coveritems["rewardpoint"..i],oneconfig.integral,self.main.point>=oneconfig.integral and 23 or 14)
        
        local status = self.main["box"..i]
        setSpriteFrameByName(self.coveritems["box"..i], "box"..i.."_"..status)
            
        self.coveritems["boxeffect"..i]:removeAllChildrenWithCleanup(true)
        if  status == 1 then
            local ccb, item = CCBReaderLoad("UIEffect/baoxiangkelingqu/baoxiangkelingqu.ccbi", nil, true, "baoxiangkelingqu")
            self.coveritems["boxeffect"..i]:addChild(ccb)
        end
        
        self.coveritems["s_button"..i]:setSwallowsTouch(true)
        self.coveritems["s_button"..i]:setTouchPriority(-102)
        self.coveritems["s_button"..i]:addHandleOfControlEvent(function()
            local tempdata = ui.getIDandNUMs(oneconfig.props)
            if status == 1 then
                UIRequest({type = 5330,id = i})
            elseif status == 0 then
                gameWindows:openWindow("getStaff",{data = tempdata,type = gameConfig.strings:string_common("task",6)},nil)
            else
                gameWindows:openWindow("getStaff",{data = tempdata,type = gameConfig.strings:string_common("moreCommon",5)},nil)
            end
        end, CCControlEventTouchUpInside)    
    end

    local tasks = t.data.tasks
    if tasks then
        self.tasks = tasks
        if not self.tasklistview then
            self:creatTaskList()
        else
            self.tasklistview:reloadData()
        end
    end
end

function treerise.findStatus(self,main )
    for i=1,3 do
        if main["box"..i]==0 then
            return i
        end
    end
    return 4
end

function treerise.animation( self,t,anitype )

    if not self.tree then
        self.tree = CCSkeletonAnimation:create("zhongshu/zhongshu.json","zhongshu/zhongshu.atlas",1)
        self.coveritems.tree:addChild(self.tree)
    end    

    local oldmain = self.main or t.data.main
    local newmain = t.data.main or self.main

    local oldstatus = self:findStatus(oldmain)
    local newstatus = self:findStatus(newmain)
    print("treerise.animation",oldstatus,newstatus)

    local delay = 0
    if anitype == "water" then
        self.tree:setAnimation(oldstatus.."2",false,0)
        if newstatus~= oldstatus then
            self.tree:addAnimation(oldstatus.."3",false,0,0)
            self.tree:addAnimation(newstatus.."1",true,0,0)
            delay = 2.5
        else
            self.tree:addAnimation(oldstatus.."1",true,0,0)
            delay = 1.5
        end
    elseif anitype == "require" then
        self.tree:setAnimation(newstatus.."1",true,0)
    end

    gameTouch:clickprofbytime(delay+0.5)
    self.coveritems.tree:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(delay), CCCallFunc:create(function()
        self:reloaddata(t)
    end)))
    
end


function treerise.creatTaskList( self )
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhongshu/cell_zhongshu", nil, true, "cell_zhongshu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.tasks[a1+1] or self.tasks[tostring(a1+1)])

            cellCCB:setPosition(540, 0)
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
        viewwidth = self.coveritems.tasklist:getContentSize().width,
        viewheight = self.coveritems.tasklist:getContentSize().height,
        dire = 1
    })
    self.coveritems.tasklist:addChild(self.tasklistview)
    self.tasklistview:setTouchPriority(self.buttontouch-2)
end

function treerise.setCell( self,item,data )
    local config = gamedata.config.zhongshu_task[tostring(data.kind)][tostring(data.cid)]
    local icon = gamedata.config.zhongshu_weights[tostring(data.kind)].icon

    if config.type and tonumber(config.type) == 1 then
        item.desc:setString(config.description)
    else
        item.desc:setString(config.description.."("..data.process.."/"..config.attr..")")
    end

    ui.setNewIcon(item,{icon=icon})

    local reward = ui.getIDandNUMs(config.reward)

    for i=1,5 do
        local v = reward[i]
        if v then 
            item["reward"..i]:setVisible(true)
            ui.setNewIcon(item,{cid=v.cid,num=v.num},i)
        else
            item["reward"..i]:setVisible(false)
        end
    end

    item.getNode:setVisible(data.status == 0)
    item.rewardNode:setVisible(data.status == 2)
    item.ingNode:setVisible(data.status == 1)

    if self.extra_time then
        item.ing:setVisible(false)
        ui.addGray("CCControlButton",item.getbutton)
        ui.addGray("CCControlButton",item.cancelbutton)
    else
        ui.removeGray("CCControlButton",item.getbutton)
        ui.removeGray("CCControlButton",item.cancelbutton)
    end

    ui.setLabelString(item.gettext,gameConfig.strings:string_common("activity_zhounian",9),18)
    
    item.getbutton:setSwallowsTouch(true)
    item.getbutton:setTouchPriority(self.buttontouch-3)
    item.getbutton:addHandleOfControlEvent(function()
        if self.extra_time then
            return runGamePrompt({msg = "活动结束"})
        end
        UIRequest({type = 5325,id = data.iid})
    end, CCControlEventTouchUpInside) 

    ui.setLabelString(item.rewardtext,gameConfig.strings:string_common("buttontext","lingqu"),18)
    item.rewardbutton:setSwallowsTouch(true)
    item.rewardbutton:setTouchPriority(self.buttontouch-3)
    item.rewardbutton:addHandleOfControlEvent(function()

        local totaltasks = tonumber(gamedata.config.global_kv.zhongshu_task_times.value)
        if self.main.tasktimes>=totaltasks then
            runGamePrompt({msg = gameConfig.strings:string_common("activity_zhounian",19)})
        else
            UIRequest({type = 5326,id = data.iid})
        end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(item.canceltext,gameConfig.strings:string_common("activity_zhounian",18),18)
    item.cancelbutton:setSwallowsTouch(true)
    item.cancelbutton:setTouchPriority(self.buttontouch-3)
    item.cancelbutton:addHandleOfControlEvent(function()
        if self.extra_time then
            return runGamePrompt({msg = "活动结束"})
        end
        UIRequest({type = 5327,id = data.iid})
    end, CCControlEventTouchUpInside)

end

function treerise.clear(self)
    gameTouch:UnrigistFunc("begin","treerise")
    gameTouch:UnrigistFunc("end","treerise")

    if gameTimer.times["Activitytree"] then
        gameTimer:UnrigistTimeFunc("Activitytree")
    end
    self.show = false
    self.tasklistview = nil
    self.tree = nil
    self.main = nil
    self.coverccb = nil
    self.coveritems = nil
end


return treerise
  v>  