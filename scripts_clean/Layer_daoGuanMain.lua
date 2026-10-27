local daoGuanMain = {
    rootNode = nil,
    rootItems = nil,

    touchPriority = -103,
    listTableView = nil,

    cellSize = {width = 1080, height = 410},

    panelData = {},
    config = {},

    -- 活动时间
    begintimenum = {week=3,hour=20,min=30,sec=0},
    endtimenum = {week=3,hour=21,min=0,sec=0},
    finaltimenum = {week=3,hour=21,min=10,sec=0},

    isopen = false,
    daoguanOnceHint = false,
}

function daoGuanMain.init(self, parent, toppos)
    self:initNode(parent, toppos)
    self:initConfig()
    self:initEvent()
    self:initLabelText()

    self.daoguanOnceHint = true
    GameScene:hintDataExt()
    
    UIRequest({type = 5301})
end

function daoGuanMain.initNode(self, parent, toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("daoguanshouwei/daoguanshouwei", nil, true, "daoguanshouwei")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.listScroll:setContentSize(CCSizeMake(1080, GameScene.topposY - 460))
end

function daoGuanMain.initConfig(self)
    self.config = gamedata.config.daoguan_param
end

-- 初始化事件
function daoGuanMain.initEvent(self)
    self:initRewardBtn()
    self:initRuleBtn()
end

function daoGuanMain.initRewardBtn(self)
    -- 奖励预览
    local _cb = function()
        gameWindows:openWindow("daoGuanRewardview", self.panelData)
    end

    ui.commonBtn(self, self.rootItems, "r_button", _cb)
end

function daoGuanMain.initRuleBtn(self)
    -- 说明
    local _cb = function()
        gameWindows:openWindow("daoGuanExplain")
    end

    ui.commonBtn(self, self.rootItems, "ruleBtn", _cb)
end

function daoGuanMain.gettimes( self )
    local _nowTime = self:getNowTime()
    local _dayNums = self:getDayNum(_nowTime)
    local _config = gamedata.config.daoguan_time[tostring(_dayNums)]

    local nowSec = _nowTime.hour*3600 + _nowTime.min*60 + _nowTime.sec

    if _config then
        for k,v in pairs(_config) do
            local _hour1, _min1, _sec1 = ui.getGangBattleTime(v.prompt_time)
            local _hour2, _min2, _sec2 = ui.getGangBattleTime(v.finaly_time)
            local beginSec = _hour1*3600 + _min1*60 + _sec1
            local endSec = _hour2*3600 + _min2*60 + _sec2

            if nowSec >= beginSec and nowSec <= endSec then
                local _hour3, _min3, _sec3 = ui.getGangBattleTime(v.open_time)
                local _hour4, _min4, _sec4 = ui.getGangBattleTime(v.over_time)
                return {
                    prompt = beginSec,
                    open   = _hour3*3600 + _min3*60 + _sec3,
                    over   = _hour4*3600 + _min4*60 + _sec4,
                    finaly = endSec,
                    now    = nowSec,
                }
            end
        end
    end
    return nil   
end

-- 初始化文本
function daoGuanMain.initLabelText(self)
    local times = self:gettimes()

    local timetext = ""
    local time = ""
    self.timestatus = ""
    if times.now<times.over then
        timetext = gameConfig.strings:string_common("daoguanshouwei", 35)
        time = times.over-times.now
        self.timestatus = "battle"
    else
        timetext = gameConfig.strings:string_common("daoguanshouwei", 36)
        time = times.finaly-times.now
        self.timestatus = "reward"
    end

    ui.setLabelString(self.rootItems.txtField4, timetext, 23)
    
    gameTimer:rigistTime("daoguan_timing", time)
    gameTimer:rigistTimeFunc("daoguan_timing", function()
        ui.setLabelString(self.rootItems.startTime,ui.makeTimeText(gameTimer.times["daoguan_timing"], "hour"), 14)
        if gameTimer.times["daoguan_timing"] <= 0 then
            if self.timestatus == "battle" then
                gameTimer:rigistTime("daoguan_timing", times.finaly-times.over)
                ui.setLabelString(self.rootItems.txtField4, gameConfig.strings:string_common("daoguanshouwei", 36), 23)
                self.timestatus = "reward"
            else
                runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 38)})
                GameScene:shiftLayer("main")
            end
        end
    end)
    
    ui.setLabelString(self.rootItems.txtField5, gameConfig.strings:string_common("daoguanshouwei", 2), 23)
end

function daoGuanMain.clear(self)
    gameTimer:UnrigistTimeFunc("daoguan_timing")
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.listTableView = nil

    self.isopen = false
end

function daoGuanMain.reloaddata(self,data)
    self.panelData = data.maindata
    self.players = data.players or {}
    printT(self.panelData,"panelData")

    ui.setLabelString(self.rootItems.challengeLabel,gameConfig.strings:string_common("daoguanshouwei", 12),23)
    local maxCount = gamedata.config.global_kv.hall_challenge_times.value
    ui.setLabelString(self.rootItems.challengeCount,self.panelData.times,14)

    ui.sethint(self.rootItems.hint_reward,self.panelData.rewardstatus==1)

    if not self.listTableView then
        self:creatList()
    else
        self.listTableView:reloadData()
    end
end

function daoGuanMain.creatList(self)
    local _cellDict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r
        if fn == "cellSize" then
            _r = CCSizeMake(self.cellSize.width, self.cellSize.height)
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = 0, 0
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("daoguanshouwei/cell_daoguanshouwei", nil, true, "cell_daoguanshouwei")
                _cellDict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler, index = a1 + 1}
            else
                _first = false
                _cellCCB = _cellDict[a2].cellCCB
                _ccbDocumentControler = _cellDict[a2].ccbDocumentControler
            end

            self:setCell(_ccbDocumentControler, self.config[a1 + 1], a1 + 1)

            _cellCCB:setPosition(0, 0)

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.config)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems["listScroll"]:getContentSize().width,
        viewheight = self.rootItems["listScroll"]:getContentSize().height,
        dire = 1
    })
    self.rootItems["listScroll"]:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority - 1)
end

function daoGuanMain.setCell(self, item, data, index)
    local idx = tostring(index)
    local _str = self.config[idx].atk1.."-"..self.config[idx].atk2

    if index == table.getTableLength(self.config) then
        _str = self.config[idx].atk1.."以上"
    end

    ui.setLabelString(item.atkTxt, _str, 29)
    ui.setLabelString(item.txtField, gameConfig.strings:string_common("daoguanshouwei", 3), 29)
    ui.setLabelString(item.txt, gameConfig.strings:string_common("daoguanshouwei", 5)..self.panelData.list[idx].."/1", 29)

    if self.players[idx] then
        item["general"]:removeAllChildrenWithCleanup(true)
        ui.setLabelString(item["keeper"], self.panelData.list[idx]>0 and gameConfig.strings:string_common("daoguanshouwei", 29) or gameConfig.strings:string_common("daoguanshouwei", 28), 3)
        ui.setLabelString(item["name"], self.players[idx].name, 21)
        
        local cid = self.players[idx].profile
        local generalconfig = gamedata.config.general[tostring(cid)]
        if generalconfig then
            local generalName = gamedata.config.generalanimation[tostring(generalconfig.animationid)].name
            local Gneral = ui.itemcache:loadSkeleton(generalName)
            Gneral:setAnimation("stand",true,0)
            Gneral:setScale(1.5)
            item["general"]:addChild(Gneral.root or Gneral)
        end
    end 

    if self.panelData.list[idx] == 0 then
        ui.setLabelString(item["lab"], gameConfig.strings:string_common("daoguanshouwei", 27), 18)
    else
        ui.setLabelString(item["lab"], gameConfig.strings:string_common("daoguanshouwei", 4), 18)
    end

    local _cb = function()
        if self.panelData.list[idx] == 0 then
            if self.timestatus == "reward" then
                runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 37)})
                return
            end
            
            UIRequest({type = 5306, id = index, position = 1})
        else
            local isPowerEnough = false

            if GameScene.roleinfo.f_power >= self.config[idx].atk1 and GameScene.roleinfo.f_power <= self.config[idx].atk2 then
                isPowerEnough = true
            end

            GameScene:shiftLayer("daoGuanList", "up", {type = index, isPowerEnough = isPowerEnough})
        end
    end

    ui.commonBtn(self, item, "button", _cb, self.touchPriority - 2)

    setSpriteFrameByName(item["titleSprite"], self.config[idx].biaoti_icon)
    setSpriteFrameByName(item["huizhangSprite"], self.config[idx].huizhang_icon)
    setSpriteFrameByName(item["bgSprite"], self.config[idx].background)
    -- item["txt"]:setVisible(self.panelData.list[idx]>=0)
    -- item["txtField"]:setVisible(self.panelData.list[idx]>0)
    -- item["powerSp"]:setVisible(self.panelData.list[idx]>0)
end

function daoGuanMain.getNowTime(self)
    return os.date("*t", gamedata:time())
end

function daoGuanMain.getDayNum(self, nowTime)
    return nowTime.wday == 1 and 7 or (nowTime.wday - 1)
end

return daoGuanMain