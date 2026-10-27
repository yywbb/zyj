--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/3/8
-- Time: 11:01
-- To change this template use File | Settings | File Templates.
-- 68



local totalrecharge = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    status = {},
    ListTableView = nil,
    normalCellSize = {x=1080,y=282+10},

    pageconfig = {"one","two","three",} ,
    pagename = {gameConfig.strings:string_common("totalrecharge",1),gameConfig.strings:string_common("totalrecharge",2),gameConfig.strings:string_common("totalrecharge",3)},
    selectpage = "one",
}


function totalrecharge.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/lianxuchongzhi",nil, true, "reward")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-740))

    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(GameScene.protagonist.general.cid)].animationid)].name
    -- local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    if activityConfig[tostring(68)].generalanimation and activityConfig[tostring(68)].generalanimation > 0 then
        local name = generalConfig[tostring(activityConfig[tostring(68)].generalanimation)].name
        local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(2)
        Gneral1:setPosition(0,0)
        self.coveritems["generalNode"]:addChild(Gneral1)
    end

    self.coveritems.rechargebutton:setTouchPriority(self.buttontouch)
    self.coveritems.rechargebutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)

    self.coveritems.title:setString(activityConfig[tostring(68)].name)

    ui.setLabelString(self.coveritems.desc,nil,1)
    ui.setLabelString(self.coveritems.desc1,nil,111)
    ui.setLabelString(self.coveritems.daydesc,nil,111)
    ui.setLabelString(self.coveritems.rmbdesc,nil,111)


    local config = gamedata.dailyCpActivityConfig("continuous_recharge",68)
    if config and config["1"] then
        self.coveritems.neednum:setString(gameConfig.strings:money(config["1"].rmb))
    end

    -- if gamedata.config.continuous_recharge and gamedata.config.continuous_recharge["1"] then
    --     self.coveritems.neednum:setString(gameConfig.strings:money(gamedata.config.continuous_recharge["1"].rmb))
    -- end
    --
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","totalrecharge",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","totalrecharge",touchend)
    --

    self.coveritems.buttonnode4:setVisible(false)
    for k=1,3 do
        self.coveritems["buttontext"..k]:setString(self.pagename[k])

        self.coveritems["button"..k]:setSwallowsTouch(true)
        self.coveritems["button"..k]:setTouchPriority(-102)
        self.coveritems["button"..k]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            self:shiftPage(self.pageconfig[k])
        end,CCControlEventTouchUpInside)
    end
    --
    self.cellccb1, self.cellitems1 = CCBReaderLoad("activityreward_new/cell_reward1",nil, true, "cell_reward1")
    self.cellccb2, self.cellitems2 = CCBReaderLoad("activityreward_new/cell_zhenpinzhekou",nil, true, "cell_reward")

    self.cellccb1:setScale(0.98)
    self.coveritems.cellnode1:removeAllChildrenWithCleanup(true)
    self.coveritems.cellnode1:addChild(self.cellccb1)

    self.cellccb2:setScale(0.98)
    self.coveritems.cellnode2:removeAllChildrenWithCleanup(true)
    self.coveritems.cellnode2:addChild(self.cellccb2)

    return self.coverccb
end

function totalrecharge.reloaddata(self,data)
    if not self.show then return end
    --
    if not data then return end
    self.data = data.data or {}

    ui.setLabelString(self.coveritems.rmb,gameConfig.strings:money(self.data.rmb),21)
    ui.setLabelString(self.coveritems.day,gameConfig.strings:Day(self.data.day),23)

    -- 活动时间
    local timediff = 0
    if self.coveritems.time and gamedata.config.activity_time["68"]["open_type"] and gamedata.config.activity_time["68"]["open_type"] == 2 then
        ui.setLabelString(self.coveritems.time,"",26)
        self.coveritems.desc1:setString("")
    elseif self.coveritems.time and gamedata.config.activity_time["68"]["open_type"] and gamedata.config.activity_time["68"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time["68"]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
    elseif self.coveritems.time and gamedata.config.activity_time["68"]["open_type"] and gamedata.config.activity_time["68"]["open_type"] == 7 then

        timediff = GameScene.layers["activity"].module:getDailyCpActivityTime(68)
    
    elseif self.coveritems.time and gamedata.config.activity_time["68"]["end"] and gamedata.config.activity_time["68"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["68"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        ui.setLabelString(self.coveritems.time,"",26)
        self.coveritems.desc1:setString("")
    end


    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("Totalcharge",timediff)

        if gameTimer.times["Totalcharge"] and gameTimer.times["Totalcharge"] > 0 then
            gameTimer:rigistTimeFunc("Totalcharge", function()
                if gameTimer.times["Totalcharge"] <= 0 then
                    if gameTimer.times["Totalcharge"] then
                        gameTimer:UnrigistTimeFunc("Totalcharge")
                    end
                else
                    ui.setLabelString(self.coveritems.time,ui.makeTimeDayText(gameTimer.times["Totalcharge"],"day"),26)
                end
            end)
        end
    end


    local config = gamedata.dailyCpActivityConfig("continuous_recharge",68)
    --
    self.status = {}
    for k,v in pairs(config) do
        if v.jackpot and v.jackpot ~= "" then
            table.insert(self.status,v)
        end
    end
    table.sort(self.status, function(a,b) return a.day < b.day end)
    --
    for k,v in ipairs(self.status) do
        self.status[k].index = k
        self.status[k].status = self.data.status3[tostring(k)] or 0
    end
    --
    local sortfunc = function (a,b)
        if a.status == b.status then
            return a.day < b.day
        elseif a.status == 1 and b.status ~= 1 then
            return true
        elseif a.status ~= 1 and b.status == 1 then
            return false
        else
            return a.status < b.status
        end
    end
    table.sort(self.status,sortfunc)
    --
    printT(self.status)
    --
    local reward1 = {}
    local prizeConfig = gamedata.dailyCpActivityConfig("prize",68)
    print("jkp-prizeConfig num = ",table.getTableLength(prizeConfig))
    if prizeConfig then
        if GameScene.roleinfo.level > table.getTableLength(prizeConfig) then
            reward1 = ui.getIDandNUMs(prizeConfig[tostring(table.getTableLength(prizeConfig))].reward)
        else
            reward1 = ui.getIDandNUMs(prizeConfig[tostring(GameScene.roleinfo.level)].reward)
        end
    end
    printT(reward1,"jkp-reward1")
    for i = 1,4 do
        if i <= #reward1 then
            self.cellitems1["reward"..i]:setVisible(true)
            ui.setNewIcon(self.cellitems1,reward1[i],i-1)
            self.cellitems1["i_button"..(i>1 and "_"..(i-1) or "")]:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                ui.setPopwindowByCid(reward1[i].cid)
            end, CCControlEventTouchUpInside)
            self.cellitems1["i_button"..(i>1 and "_"..(i-1) or "")]:setTouchPriority(-103)
        else
            self.cellitems1["reward"..i]:setVisible(false)
        end
    end
    self.cellitems1.title:setString(gameConfig.strings:string_common("totalrecharge",1))
    --

    --
    if self.data.status1 == 1 then
        self.cellitems1.rechargeNode:setVisible(false)
        self.cellitems1.nonenode:setVisible(false)
        self.cellitems1.doNode:setVisible(true)
        self.cellitems1.hasnode:setVisible(false)
        --
        ui.setLabelString(self.cellitems1.doLab,gameConfig.strings:string_common("totalrecharge",4),18)
        setControlButtonFrame(self.cellitems1["doButton"],"b_s_button2","b_s_button2_h","b_s_button2")
        ui.removeGray("CCControlButton",self.cellitems1["doButton"])
        --
        self.cellitems1["doButton"]:setSwallowsTouch(true)
        self.cellitems1["doButton"]:setTouchPriority(-103)
        self.cellitems1["doButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4861,opt = 1,index = 1,cost = {}})
        end,CCControlEventTouchUpInside)
    elseif self.data.status1 == 2 then
        self.cellitems1.rechargeNode:setVisible(false)
        self.cellitems1.nonenode:setVisible(false)
        self.cellitems1.doNode:setVisible(false)
        self.cellitems1.hasnode:setVisible(true)
        --
        ui.setLabelString(self.cellitems1.doLab,gameConfig.strings:string_common("totalrecharge",5),18)
        setControlButtonFrame(self.cellitems1["doButton"],"b_s_button2","b_s_button2_h","b_s_button2")
        ui.addGray("CCControlButton",self.cellitems1["doButton"])
        --
        self.cellitems1["doButton"]:setSwallowsTouch(true)
        self.cellitems1["doButton"]:setTouchPriority(-103)
        self.cellitems1["doButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("totalrecharge",5)})
        end,CCControlEventTouchUpInside)
    else
        self.cellitems1.rechargeNode:setVisible(false)
        self.cellitems1.nonenode:setVisible(false)
        self.cellitems1.doNode:setVisible(true)
        self.cellitems1.hasnode:setVisible(false)
        --
        ui.setLabelString(self.cellitems1.doLab,gameConfig.strings:string_common("totalrecharge",6),18)
        setControlButtonFrame(self.cellitems1["doButton"],"b_s_button1","b_s_button1_h","b_s_button1")
        ui.removeGray("CCControlButton",self.cellitems1["doButton"])
        --
        self.cellitems1["doButton"]:setSwallowsTouch(true)
        self.cellitems1["doButton"]:setTouchPriority(-103)
        self.cellitems1["doButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameWindows:openWindow("recharge",{pagetype = "info"})
        end,CCControlEventTouchUpInside)
        --

    end

    --
    local config = gamedata.dailyCpActivityConfig("continuous_recharge",68)
    
    if self.data.now > table.getTableLength(config) then
        self.data.now = table.getTableLength(config)
    end
    local discount = 0
    local reward2 = {}
    local cost2 = {}
    if config and config[tostring(self.data.now)] then
        reward2 = ui.getIDandNUMs(config[tostring(self.data.now)].target)
        cost2 = ui.getIDandNUMs(config[tostring(self.data.now)].generals)
        discount = config[tostring(self.data.now)].discount or 0
    end

    if discount > 0 and discount < 10 then
        setSpriteFrameByName(self.cellitems2.discountLv,discount.."zhe")
    else
        setSpriteFrameByName(self.cellitems2.discountLv,"alpha")
    end

    local consumnum = #cost2
    local props = {}
    for k,v in ipairs(cost2) do
        table.insert(props,v)
    end
    for k,v in ipairs(reward2) do
        table.insert(props,v)
    end

    for i=1, 4 do
        if props[i] and props[i].cid then
            self.cellitems2["reward"..i]:setVisible(true)
            local config = ui.IDconfig(props[i].cid)
            if config then
                ui.setNewIcon(self.cellitems2,{cid = props[i].cid, num = props[i].num,},i-1)
                --
                self.cellitems2["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    ui.setPopwindowByCid(props[i].cid)
                end, CCControlEventTouchUpInside)
                self.cellitems2["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
            if i<= consumnum then
                self.cellitems2["reward"..i]:setPositionX(114+(i-1)*136)
            else
                self.cellitems2["reward"..i]:setPositionX(174+(i-1)*136)
            end
            self.cellitems2.esprite:setPositionX(210+(consumnum-1)*136)
        else
            self.cellitems2["reward"..i]:setVisible(false)
        end
    end

    --
    self.cellitems2.exchangeNode:setVisible(false)
    self.cellitems2.desc:setString(gameConfig.strings:string_common("totalrecharge",9))
    --
    if self.data.status2 == 1 then
        self.cellitems2.descNode:setVisible(false)
        ui.setLabelString(self.cellitems2.exchangeLab,gameConfig.strings:string_common("totalrecharge",7),18)
        setControlButtonFrame(self.cellitems2["exchangeBtn"],"b_s_button2","b_s_button2_h","b_s_button2")
        ui.removeGray("CCControlButton",self.cellitems2["exchangeBtn"])
        --
        self.cellitems2["exchangeBtn"]:setSwallowsTouch(true)
        self.cellitems2["exchangeBtn"]:setTouchPriority(-103)
        self.cellitems2["exchangeBtn"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4861,opt = 2,index = 1,cost = cost2 or {}})
        end,CCControlEventTouchUpInside)
    elseif self.data.status2 == 2 then
        self.cellitems2.descNode:setVisible(false)
        ui.setLabelString(self.cellitems2.exchangeLab,gameConfig.strings:string_common("totalrecharge",8),18)
        setControlButtonFrame(self.cellitems2["exchangeBtn"],"b_s_button2","b_s_button2_h","b_s_button2")
        ui.addGray("CCControlButton",self.cellitems2["exchangeBtn"])
        --
        self.cellitems2["exchangeBtn"]:setSwallowsTouch(true)
        self.cellitems2["exchangeBtn"]:setTouchPriority(-103)
        self.cellitems2["exchangeBtn"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("totalrecharge",8)})
        end,CCControlEventTouchUpInside)
    else
        self.cellitems2.descNode:setVisible(true)
        ui.setLabelString(self.cellitems2.exchangeLab,gameConfig.strings:string_common("totalrecharge",6),18)
        setControlButtonFrame(self.cellitems2["exchangeBtn"],"b_s_button1","b_s_button1_h","b_s_button1")
        ui.removeGray("CCControlButton",self.cellitems2["exchangeBtn"])
        --
        self.cellitems2["exchangeBtn"]:setSwallowsTouch(true)
        self.cellitems2["exchangeBtn"]:setTouchPriority(-103)
        self.cellitems2["exchangeBtn"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameWindows:openWindow("recharge",{pagetype = "info"})
        end,CCControlEventTouchUpInside)
    end


    --
    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            if self.ListTableView:getLuaContentOffsetY() < self.coveritems.listnode:getContentSize().height - table.getTableLength(self.status)*self.normalCellSize.y then
                self.ListTableView:setLuaContentOffset(0, self.coveritems.listnode:getContentSize().height - table.getTableLength(self.status)*self.normalCellSize.y)
            end
            self.ListTableView:reloadData()
        end
    end
    --
    self:shiftPage(self.selectpage)
end

function totalrecharge.clear(self)
    gameTouch:UnrigistFunc("begin","totalrecharge")
    gameTouch:UnrigistFunc("end","totalrecharge")

    if gameTimer.times["Totalcharge"] then
        gameTimer:UnrigistTimeFunc("Totalcharge")
    end

    self.selectpage = "one"
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.status = {}
    self.coverccb = nil
    self.coveritems = nil
end

function totalrecharge.createList(self)
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

            self:setCell(ccbDocumentControler,a1+1)
            cellCCB:setScale(0.98)
            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.status)
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


function totalrecharge.setCell(self,item,index)
    print("setCell")
    local config = self.status[index]

    item.doButton:setTouchPriority(-102)
    if config.status == 1 then
        item.rechargeNode:setVisible(false) --
        item.nonenode:setVisible(false)
        item.doNode:setVisible(true)
        item.hasnode:setVisible(false)
        ui.removeGray("CCControlButton",item.doButton)
        ui.removeGray("CCLabelTTF",item.doLab)
        ui.setLabelString(item.doLab,gameConfig.strings:string_common("buttontext","lingqu"),18)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4861,opt = 3,index = config.index,cost = {}})
        end, CCControlEventTouchUpInside)
    elseif config.status == 2 then
        item.rechargeNode:setVisible(false) --
        item.nonenode:setVisible(false)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(true)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        ui.setLabelString(item.doLab,gameConfig.strings:string_common("buttontext","yilingqu"),18)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)
    else
        item.nonenode:setVisible(true) --
        item.rechargeNode:setVisible(false) --
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        ui.setLabelString(item.doLab,gameConfig.strings:string_common("buttontext","lingqu"),18)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","weiwancheng")})
        end, CCControlEventTouchUpInside)

    end

    item.title:setString(gameConfig.strings:string_common("totalrecharge",10)..gameConfig.strings:Day(config.day))
    local props = ui.getIDandNUMs(config.jackpot) or {}

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

end


function  totalrecharge.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if vm == page then
            setSpriteFrameByName(self.coveritems["buttonsprite"..km], gameConfig.images.pageButtonON)
        else
            setSpriteFrameByName(self.coveritems["buttonsprite"..km], gameConfig.images.pageButtonOFF)
        end
    end
end

function totalrecharge.shiftPage(self,type)

    if type then
        self.selectpage = type
    end

    self:shiftlayerpage(self.selectpage)

    if self.selectpage == "one" then
        self.coveritems.cellnode1:setPositionX(0)
        self.coveritems.cellnode2:setPositionX(9999)
        self.coveritems.listnode:setPositionX(9999)
    elseif self.selectpage == "two" then
        -- 标签1按钮状态(0未充值，1充值未领取，2已领取)
        -- printT(self.data,"  self.data")
        local isShow = false
        for k,v in pairs(self.data.status3) do
            if v == 1 then
                isShow = true
            end
        end
        if self.data.status1 == 2 and isShow == false then
            UIRequest({type = 10321,notupdate = 1,ids = {264}})
        end
        ui.sethint(self.coveritems.hint_title2,false);
        self.coveritems.cellnode1:setPositionX(9999)
        self.coveritems.cellnode2:setPositionX(0)
        self.coveritems.listnode:setPositionX(9999)
    elseif self.selectpage == "three" then
        self.coveritems.cellnode1:setPositionX(9999)
        self.coveritems.cellnode2:setPositionX(9999)
        self.coveritems.listnode:setPositionX(0)
    end

end


return totalrecharget^  