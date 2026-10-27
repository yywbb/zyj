--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/2/17
-- Time: 11:29
-- To change this template use File | Settings | File Templates.
--


local cangjingge_task = {
    rootNode = nil,
    rootItems = nil,

    manortask = {},
    taskselect = 1,

    maxtaskcount = 0,
    extnum = 0,

}

function cangjingge_task.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("cangjingge/cangjingge_renwu", nil, true, "cangjingge_task")
    self.touchPriority = touchPriority

    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("cangjingge_task")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self:setquality(data)

    UIRequest({type = 4824,opt = 0})
    return self.rootNode
end

function cangjingge_task.setquality(self,data)
    --
    local config_building = gamedata.config.home_building and gamedata.config.home_building["2"][tostring(data.buildquality > 0 and data.buildquality or 1)] or {}
    ui.setLabelString(self.rootItems.building_name,config_building.name,(data.buildquality > 0) and (data.buildquality*2+3) or 5)
    setSpriteFrameByName(self.rootItems.building_sprite, "c_b_jianzhu2".."_"..(data.buildquality > 0 and data.buildquality or 1))
    local qstr = config_building.extra_attr
    local extnum = config_building.reward_up or 0
    self.rootItems["quality_attr0"]:setAnchorPoint(ccp(1, 0.5))
    if extnum > 0 then
        self.rootItems["quality_attr0"]:setString(gameConfig.strings:string_common("cangjingge",29)..":")
        self.rootItems["quality_attrnum0"]:setString(extnum)
    elseif data.buildquality > 1 then
        self.rootItems["quality_attr0"]:setAnchorPoint(ccp(0.5, 0.5))
        self.rootItems["quality_attr0"]:setString(gameConfig.strings:string_common("cangjingge",48))
        self.rootItems["quality_attrnum0"]:setString("")
    else
        self.rootItems["quality_attr0"]:setString("")
        self.rootItems["quality_attrnum0"]:setString("")
    end

    if qstr and qstr ~= "" then
        ui.setLabelString(self.rootItems.qualityattrlab,gameConfig.strings:string_common("cangjingge",1),(data.buildquality > 0) and (data.buildquality*2+3) or 5)
        local attrs = ui.getSTRandNUMs(qstr)
        for i = 1,3 do
            if attrs[i] then
                self.rootItems["quality_attr"..i]:setString(gameConfig.strings.attr_type[attrs[i].str]..":")
                self.rootItems["quality_attrnum"..i]:setString((attrs[i].num < 1) and ((attrs[i].num*100).."%") or attrs[i].num)
            else
                self.rootItems["quality_attr"..i]:setString("")
                self.rootItems["quality_attrnum"..i]:setString("")
            end
        end
    else
        ui.setLabelString(self.rootItems.qualityattrlab,gameConfig.strings:string_common("cangjingge",(data.buildquality > 1) and 1 or 2),(data.buildquality > 0) and (data.buildquality*2+3) or 5)
        self.rootItems.quality_attr1:setString("")
        self.rootItems.quality_attr2:setString("")
        self.rootItems.quality_attr3:setString("")
        self.rootItems.quality_attrnum1:setString("")
        self.rootItems.quality_attrnum2:setString("")
        self.rootItems.quality_attrnum3:setString("")
    end
    --
    ui.setLabelString(self.rootItems.upquality_lab,gameConfig.strings:string_common("cangjingge",11),18)
    self.rootItems.upquality_button:addHandleOfControlEvent(function()
        gameWindows:openWindow("cangjingge_qualityup",data,nil)
        gameWindows:closeWindowDirect("cangjingge_task")
    end, CCControlEventTouchUpInside)
    self.rootItems.upquality_button:setSwallowsTouch(true)
    self.rootItems.upquality_button:setTouchPriority(self.touchPriority)
    --

    ui.setLabelString(self.rootItems.tasklab1,gameConfig.strings:string_common("cangjingge",17),14)
    ui.setLabelString(self.rootItems.tasklab2,gameConfig.strings:string_common("cangjingge",18),14)
    ui.setLabelString(self.rootItems.tasklab3,gameConfig.strings:string_common("cangjingge",19),14)
    ui.setLabelString(self.rootItems.gotoLab,gameConfig.strings:string_common("cangjingge",20),21)
    --
    self.extnum = 0
    self.maxtaskcount = gamedata.config.global_kv.home_task_limit and tonumber(gamedata.config.global_kv.home_task_limit.value) or 0
    if data.building then
        if data.building["1"] and data.building["1"].quality then
            self.maxtaskcount = self.maxtaskcount + (gamedata.config.home_building["1"][tostring(data.building["1"].quality)] and gamedata.config.home_building["1"][tostring(data.building["1"].quality)].reward_up or 0)
        end
        for i = 2,5,1 do
            if data.building[tostring(i)] and data.building[tostring(i)].quality then
                self.extnum = self.extnum + (gamedata.config.home_building[tostring(i)][tostring(data.building[tostring(i)].quality)] and gamedata.config.home_building[tostring(i)][tostring(data.building[tostring(i)].quality)].reward_up or 0)
            end
        end
    end
    --
    --time
    if gameTimer.times["manorqualitytime"] and gameTimer.times["manorqualitytime"] > 0 then
        if data.buildquality > 1 then
            gameTimer:rigistTime("manorqualitytime2",gameTimer.times["manorqualitytime"])
            gameTimer:rigistTimeFunc("manorqualitytime2",function()
                if gameTimer.times["manorqualitytime2"] <= 0 then
                    gameTimer:UnrigistTimeFunc("manorqualitytime2")
                    ui.setLabelString(self.rootItems.updesc,gameConfig.strings:string_common("cangjingge",45),22)
                else
                    ui.setLabelString(self.rootItems.updesc,gameConfig.strings:string_common("cangjingge",45)..gameConfig.strings:string_common("cangjingge",47)..ui.makeTimeDayText(gameTimer.times["manorqualitytime2"],"day"),22)
                end
            end)
            self.rootItems.upqualitynode:setVisible(false)
            self.rootItems.updesc:setVisible(true)
        else
            self.rootItems.upqualitynode:setVisible(true)
            self.rootItems.updesc:setVisible(false)
        end
    else
        self.rootItems.upqualitynode:setVisible(true)
        self.rootItems.updesc:setVisible(false)
    end
    --

end

function cangjingge_task.reload(self,data,callback)

    self.manortask = data and data.manortask or {}

    local taskconfig = gamedata.config.home_task or {}
    for i = 1,3 do
        if self.manortask["task"..i] and self.manortask["task"..i].id and self.manortask["task"..i].id > 0 then
            self.rootItems["tasknode"..i]:setVisible(true)
            local task = taskconfig[tostring(self.manortask["task"..i].id)] or {}
            local reward = ui.getIDandNUMs(task.reward)
            if reward and reward[1] then
                reward[1].num = reward[1].num + self.extnum
                ui.setNewIconName(self.rootItems,reward[1],i-1)
            end
            for j = 1,5 do
                if j <= task.star then
                    self.rootItems["t"..i.."_taskStar"..j]:setVisible(true)
                else
                    self.rootItems["t"..i.."_taskStar"..j]:setVisible(false)
                end
            end
            self.rootItems["t"..i.."_taskStarNode"]:setPositionX(20*(5-task.star))
            --
            if self.manortask["task"..i].status then
                if self.manortask["task"..i].status == 1 then
                    ui.setLabelString(self.rootItems["t"..i.."_status"],gameConfig.strings:string_common("cangjingge",14),23)
                elseif self.manortask["task"..i].status == 2 then
                    ui.setLabelString(self.rootItems["t"..i.."_status"],gameConfig.strings:string_common("cangjingge",15),23)
                elseif self.manortask["task"..i].status == 3 then
                    ui.setLabelString(self.rootItems["t"..i.."_status"],gameConfig.strings:string_common("cangjingge",16),14)
                else
                    ui.setLabelString(self.rootItems["t"..i.."_status"],gameConfig.strings:string_common("cangjingge",13),14)
                end
            end
            --
            self.rootItems["t"..i.."_selectButton"]:addHandleOfControlEvent(function()
                self.taskselect = i
                self:settask()
            end, CCControlEventTouchUpInside)
            self.rootItems["t"..i.."_selectButton"]:setSwallowsTouch(true)
            self.rootItems["t"..i.."_selectButton"]:setTouchPriority(self.touchPriority)
        else
            self.rootItems["tasknode"..i]:setVisible(false)
        end
    end
    --

    ui.setLabelString(self.rootItems.taskcount,gameConfig.strings:string_common("cangjingge",26)..((self.maxtaskcount-self.manortask.count) > 0 and (self.maxtaskcount-self.manortask.count) or 0).."/"..self.maxtaskcount,(self.maxtaskcount-self.manortask.count)>0 and 22 or 24)
    --
    local resetnum = 0
    if gamedata.config.buycount_price[tostring(self.manortask.reset+1)] then
        resetnum = gamedata.config.buycount_price[tostring(self.manortask.reset+1)].home_task_cost
    else
        resetnum = gamedata.config.buycount_price["60"].home_task_cost
    end

    ui.setLabelString(self.rootItems.resetGoldNum,resetnum,21)

    ui.setLabelString(self.rootItems.resetLab,gameConfig.strings:string_common("cangjingge",28),18)

    self.rootItems["resetButton"]:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        UIRequest({type = 4824,opt = 1,xgold = resetnum})
    end, CCControlEventTouchUpInside)
    self.rootItems["resetButton"]:setSwallowsTouch(true)
    self.rootItems["resetButton"]:setTouchPriority(self.touchPriority)

    --
    self:settask()


end

function cangjingge_task.settask(self)

    for i = 1,3 do
        if i == self.taskselect then
            self.rootItems["t"..i.."_select"]:setVisible(true)
        else
            self.rootItems["t"..i.."_select"]:setVisible(false)
        end
    end

    --

    local taskconfig = gamedata.config.home_task or {}
    local task = taskconfig[tostring(self.manortask["task"..self.taskselect].id)] or {}
    local reward = ui.getIDandNUMs(task.reward)

    for j = 1,5 do
        if j <= task.star then
            self.rootItems["taskStar"..j]:setVisible(true)
        else
            self.rootItems["taskStar"..j]:setVisible(false)
        end
    end

    --
    ui.setLabelString(self.rootItems.taskdesc,task.description.."  ("..self.manortask["task"..self.taskselect].pos.."/"..task.attr..")",14)
    --
    if reward and reward[1] then
        ui.setLabelString(self.rootItems.taskreward,ui.IDconfig(reward[1].cid).name.." X"..(reward[1].num+self.extnum),14)
    end
    --

    self.rootItems["gotoButton"]:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(task.sys,task.sysparam)
    end, CCControlEventTouchUpInside)
    self.rootItems["gotoButton"]:setSwallowsTouch(true)
    self.rootItems["gotoButton"]:setTouchPriority(self.touchPriority)

    --
    local xgold = task.finish_instant or 0
    ui.setLabelString(self.rootItems.finishGoldNum,xgold,21)
    ui.setLabelString(self.rootItems.finishLab,gameConfig.strings:string_common("cangjingge",21),18)
    self.rootItems["finishButton"]:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if (self.maxtaskcount-self.manortask.count) > 0 then
            UIRequest({type = 4827,id = self.manortask["task"..self.taskselect].id,opt = 1,xgold = xgold})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("cangjingge",27)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems["finishButton"]:setSwallowsTouch(true)
    self.rootItems["finishButton"]:setTouchPriority(self.touchPriority)
    --

    if self.manortask["task"..self.taskselect].status == 1 then
        --
        self.rootItems.gotoNode:setVisible(true)
        self.rootItems.finishNode:setVisible(true)
        self.rootItems.finishGold:setVisible(true)
        setControlButtonFrame(self.rootItems.doButton,"b_s_button1","b_s_button1_h","b_s_button1")
        ui.removeGray("CCControlButton",self.rootItems.doButton)
        --
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("cangjingge",50),18)
        self.rootItems["doButton"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4826,id = self.manortask["task"..self.taskselect].id,opt = 1})
        end, CCControlEventTouchUpInside)
        self.rootItems["doButton"]:setSwallowsTouch(true)
        self.rootItems["doButton"]:setTouchPriority(self.touchPriority)
    elseif self.manortask["task"..self.taskselect].status == 2 then
        --
        self.rootItems.gotoNode:setVisible(false)
        self.rootItems.finishNode:setVisible(false)
        self.rootItems.finishGold:setVisible(false)
        setControlButtonFrame(self.rootItems.doButton,"b_s_button2","b_s_button2_h","b_s_button2")
        ui.removeGray("CCControlButton",self.rootItems.doButton)
        --
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("cangjingge",23),18)
        self.rootItems["doButton"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            if (self.maxtaskcount-self.manortask.count) > 0 then
                UIRequest({type = 4827,id = self.manortask["task"..self.taskselect].id,opt = 0,xgold = 0})
            else
                runGamePrompt({msg = gameConfig.strings:string_common("cangjingge",27)})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems["doButton"]:setSwallowsTouch(true)
        self.rootItems["doButton"]:setTouchPriority(self.touchPriority)
    elseif self.manortask["task"..self.taskselect].status == 3 then
        --
        self.rootItems.gotoNode:setVisible(false)
        self.rootItems.finishNode:setVisible(false)
        self.rootItems.finishGold:setVisible(false)
        setControlButtonFrame(self.rootItems.doButton,"b_s_button2","b_s_button2_h","b_s_button2")
        ui.addGray("CCControlButton",self.rootItems.doButton)
        --
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("cangjingge",16),18)
        self.rootItems["doButton"]:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("cangjingge",25)})
        end, CCControlEventTouchUpInside)
        self.rootItems["doButton"]:setSwallowsTouch(true)
        self.rootItems["doButton"]:setTouchPriority(self.touchPriority)
    else
        --
        self.rootItems.gotoNode:setVisible(false)
        self.rootItems.finishNode:setVisible(false)
        self.rootItems.finishGold:setVisible(false)
        setControlButtonFrame(self.rootItems.doButton,"b_s_button2","b_s_button2_h","b_s_button2")
        ui.removeGray("CCControlButton",self.rootItems.doButton)
        --
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("cangjingge",22),18)
        self.rootItems["doButton"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4826,id = self.manortask["task"..self.taskselect].id,opt = 0})
        end, CCControlEventTouchUpInside)
        self.rootItems["doButton"]:setSwallowsTouch(true)
        self.rootItems["doButton"]:setTouchPriority(self.touchPriority)
    end




end


function cangjingge_task.close(self)
    gameTimer:UnrigistTimeFunc("manorqualitytime2")
    self.extnum = 0
    self.maxtaskcount = 0
    self.taskselect = 1
    self.manortask = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return cangjingge_task

