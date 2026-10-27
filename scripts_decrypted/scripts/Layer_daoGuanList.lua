--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/30
-- Time: 下午4:37
-- To change this template use File | Settings | File Templates.
--

local daoGuanList = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    buttontouch = -103,
    
    paramData = {},
    panelData = {},
    config = {},

    -- item控制列表
    ctrlList = {},

    -- 活动时间
    begintimenum = {week=3,hour=20,min=30,sec=0},
    endtimenum = {week=3,hour=21,min=0,sec=0},
    finaltimenum = {week=3,hour=21,min=10,sec=0},

    isopen = false,

    servicewaropen = false,
}

-- 初始化
function daoGuanList.init(self, parent, toppos, param)
    self:initCCB(parent, toppos)
    self:initParam(param)
    self:initEvent()
    self:initTxtField()
    self:initReward(self.paramData.type);
    self:initIcon(self.paramData.type)
    self:initItemTable();
    self:inittiming()

    self.isPowerEnough = param.isPowerEnough
    if not self.isPowerEnough then
        runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 42)})
    end
    
    UIRequest({type = 5303, id = self.paramData.type})
end

function daoGuanList.inittiming( self )
    local times = GameScene.layers.daoGuanMain.module:gettimes()

    local timetext = ""
    local time = ""
    self.timestatus = ""
    if times.now<times.over then
        time = times.over-times.now
        self.timestatus = "battle"
    else
        time = times.finaly-times.now
        self.timestatus = "reward"
    end
    
    gameTimer:rigistTime("daoguan_timing_in", time)
    gameTimer:rigistTimeFunc("daoguan_timing_in", function()
        if gameTimer.times["daoguan_timing_in"] <= 0 then
            if self.timestatus == "battle" then
                gameTimer:rigistTime("daoguan_timing_in", times.finaly-times.over)
                self.timestatus = "reward"
            else
                runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 38)})
                GameScene:shiftLayer("main")
            end
        end
    end)
end

-- 初始化ccb
function daoGuanList.initCCB(self, parent, toppos)
    self.rootNode, self.rootItems = CCBReaderLoad("daoguanshouwei/daoguanshouwei_challenge", nil, true, "daoguanshouwei_challenge")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(toppos)
end

-- 初始化相关参数
function daoGuanList.initParam(self, param)
    self.paramData = param
    self.config = gamedata.config.daoguan_param
end

-- 初始化事件
function daoGuanList.initEvent(self)
    self:initBtnBack()
    self:initBtnBattleReport()
    self:initBtnChallenge()
    self:initBtnBuy()

    local now = gamedata:time()
    self.rootItems.rankRefreshBtn:setTouchPriority(self.buttontouch)
    self.rootItems.rankRefreshBtn:addHandleOfControlEvent(function ()
        local now_ = gamedata:time()
        if now_- now >= 15 then
            UIRequest({type = 5303, id = self.paramData.type})
            now = now_
        else
            runGamePrompt({msg=gameConfig.strings:daoguanrefresh(15-(now_- now))})
        end
    end, CCControlEventTouchUpInside)
end

-- 初始化文本
function daoGuanList.initTxtField(self)
    -- 获取奖励
    ui.setLabelString(self.rootItems.masterRewardText,gameConfig.strings:string_common("daoguanshouwei", 6),14)
    ui.setLabelString(self.rootItems.memberRewardText,gameConfig.strings:string_common("daoguanshouwei", 7),14)
    -- 战报按钮
    -- ui.setLabelString(self.rootItems.doLab1, gameConfig.strings:string_common("daoguanshouwei", 8), 18)
    ui.setLabelString(self.rootItems.doLab2, gameConfig.strings:string_common("daoguanshouwei", 9), 19)
    -- 文本显示
    ui.setLabelString(self.rootItems.txtLabel2,gameConfig.strings:string_common("daoguanshouwei", 11),23)
    
    -- 设置时间的更新
    ui.setLabelString(self.rootItems.challengeLabel,gameConfig.strings:string_common("daoguanshouwei", 12),22)
end

-- 初始化奖励
function daoGuanList.initReward(self, daoguanType)
    -- local reward1 = self.config[tostring(daoguanType)].reward1
    -- for k,v in ipairs(ui.getIDandNUMs(reward1)) do
    --     local ccb,item = CCBReaderLoad("icons/new_icon.ccbi", nil, true, "new_icon")
    --     self.rootItems.topnode:addChild(ccb)
    --     ccb:setPosition(-60+(k-1)*60,-100)
    --     ccb:setScale(0.33)
    --     ui.setNewIcon(item,v)
    -- end

    -- local reward2 = self.config[tostring(daoguanType)].reward2
    -- for k,v in ipairs(ui.getIDandNUMs(reward2)) do
    --     local ccb,item = CCBReaderLoad("icons/new_icon.ccbi", nil, true, "new_icon")
    --     self.rootItems.topnode:addChild(ccb)
    --     ccb:setPosition(-60+(k-1)*60,-40)
    --     ccb:setScale(0.33)
    --     ui.setNewIcon(item,v)
    -- end


end

-- 初始化图标
function daoGuanList.initIcon(self, daoguanType)
    for i = 1, 4 do
        local _isShow = false

        if i == daoguanType then
            _isShow = true
        end

        self:setIcon(i, _isShow)
    end
end

-- 设置图标
function daoGuanList.setIcon(self, type, isShow)
    if type == 1 then
        self.rootItems.guangHuiIcon:setVisible(isShow)
    elseif type == 2 then
        self.rootItems.rongYaoIcon:setVisible(isShow)
    elseif type == 3 then
        self.rootItems.dianFengIcon:setVisible(isShow)
    elseif type == 4 then
        self.rootItems.chuanQiIcon:setVisible(isShow)
    else
        print("daoGuanList setIcon type is wrong.")
    end
end

-- 初始化道馆成员节点
function daoGuanList.initItemTable(self)
    self.ctrlList = {}
    local cellCCB, ccbDocumentControler = 0,0

    for i= 1, 8 do
        cellCCB, ccbDocumentControler = CCBReaderLoad("daoguanshouwei/daoguanplayericon.ccbi", nil, true, "cell")
        ccbDocumentControler.power:setString("")
        self.rootItems["playerItem"..i]:addChild(cellCCB)
        self.ctrlList[i] = {cellCCB = cellCCB, ccbDocumentControler = ccbDocumentControler}
        self.ctrlList[i].ccbDocumentControler.i_button:setTouchPriority(self.buttontouch - 1)
        self.ctrlList[i].ccbDocumentControler.i_button:addHandleOfControlEvent(function ()
            
            if not self.isPowerEnough then
                runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 42)})
                return
            end

            if self.panelData.laststatus ~= 0 then
                runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 39)})
                return
            end

            if self.timestatus == "reward" then
                runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 37)})
                return
            end

            -- 判断是馆员还是馆长
            local _isMemberOrLeader = true
            local _type = 0

            if self.panelData.rid == self.panelData.players["1"].rid then
                _isMemberOrLeader = false
                _type = 1
            else
                for i = 2, 9 do
                    if self.panelData.rid == self.panelData.players[tostring(i)].rid then
                        _isMemberOrLeader = false
                        _type = 2
                        break
                    end
                end
            end  

            -- 道馆馆长是自己不能挑战, 已经是成员不能挑战
            if _isMemberOrLeader then
                --gameWindows:openWindow("confirm",{msg=gameConfig.strings:daoguanmember(self.paramData.type,self.panelData.players[tostring(i+1)].name)},function()
                    UIRequest({type = 5306, id = self.paramData.type, position = i + 1})
                --end)
            else
                if _type == 1 then
                    runGamePrompt({msg = gameConfig.strings:string_common("daoguanshouwei", 19)})
                elseif _type == 2 then
                    runGamePrompt({msg = gameConfig.strings:string_common("daoguanshouwei", 20)})
                end
            end
        end, CCControlEventTouchUpInside)
    end
end

-- 设置道馆成员
function daoGuanList.setItemTable(self, data)
    for i = 1, 8 do
        local leaderguildid = self.panelData.players["1"].params["1"].i
        local memberguildid = data[tostring(i + 1)].params["1"].i


        self.ctrlList[i].ccbDocumentControler.guidetip:setVisible(leaderguildid~=0 and leaderguildid==memberguildid)


        ui.setNewIcon(self.ctrlList[i].ccbDocumentControler, {cid = data[tostring(i + 1)].profile})


        --不同一公会 用红框 同一工会用蓝框
        if leaderguildid == 0 then
            setSpriteFrameByName(self.ctrlList[i].ccbDocumentControler.i_k_quality, "b_iconk6")
        else
            if leaderguildid == memberguildid then
                setSpriteFrameByName(self.ctrlList[i].ccbDocumentControler.i_k_quality, "b_iconk3")
            else
                setSpriteFrameByName(self.ctrlList[i].ccbDocumentControler.i_k_quality, "b_iconk6")
            end
        end

        self.ctrlList[i].ccbDocumentControler.name:setString(data[tostring(i + 1)].name)
        self.ctrlList[i].ccbDocumentControler.power:setString(gameConfig.strings:string_common("daoguanshouwei", 16)..data[tostring(i + 1)].param)
    end

    local gangNum = 0
    local gangId = data["1"].params["1"].i

    if gangId > 0 then
        for i=2,9 do
            if data[tostring(i)] and (data[tostring(i)].params["1"].i == gangId) then
                gangNum = gangNum + 1
            end
        end
    end

    self.rootItems.gangNumText:setString(gameConfig.strings:string_common("daoguanshouwei", 40))
    self.rootItems.gangAddText:setString(gameConfig.strings:string_common("daoguanshouwei", 41))

    self.rootItems.gangNum:setString(gangNum)
    self.rootItems.gangAdd:setString((gangNum * gamedata.config.global_kv.hall_hp_add.value * 100).."%")

end

-- 初始化 返回按钮
function daoGuanList.initBtnBack(self)
    self.rootItems.backBtn:setTouchPriority(self.buttontouch)
    self.rootItems.backBtn:addHandleOfControlEvent(function ()
        GameScene:shiftLayer("daoGuanMain","up")
    end, CCControlEventTouchUpInside)
end

-- 初始化 打开战报
function daoGuanList.initBtnBattleReport(self)
    self.rootItems.noteButton:setTouchPriority(self.buttontouch)
    self.rootItems.noteButton:addHandleOfControlEvent(function () 
        if not self.isPowerEnough then
            runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 42)})
            return
        end

        UIRequest({type = 5305, id = self.paramData.type})
    end, CCControlEventTouchUpInside)

    self.rootItems.rewardButton:setTouchPriority(self.buttontouch)
    self.rootItems.rewardButton:addHandleOfControlEvent(function ()       
        gameWindows:openWindow("daoGuanRewardview2",{daoguanType = self.paramData.type})
    end, CCControlEventTouchUpInside)
end

--初始化 打开布阵 挑战馆长
function daoGuanList.initBtnChallenge(self)
    self.rootItems.fightButton:setTouchPriority(self.buttontouch)
    self.rootItems.fightButton:addHandleOfControlEvent(function ()

        if not self.isPowerEnough then
            runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 42)})
            return
        end

        if self.panelData.laststatus ~= 0 then
            runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 39)})
            return
        end

        if self.timestatus == "reward" then
            runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 37)})
            return
        end

        if self.panelData.cando ~= 1 then
            runGamePrompt({msg=gameConfig.strings:string_common("daoguanshouwei", 34)})
            return
        end

        -- 道馆馆长是自己不能挑战
        local _isLeader = true

        if self.panelData.rid == self.panelData.players["1"].rid then
            _isLeader = false
        end

        if _isLeader then
            --gameWindows:openWindow("confirm",{msg=gameConfig.strings:daoguanleader(self.paramData.type,self.panelData.players["1"].name)},function()
                UIRequest({type = 5306, id = self.paramData.type, position = 1})
            --end)
        else
            runGamePrompt({msg = gameConfig.strings:string_common("daoguanshouwei", 19)})
        end
    end, CCControlEventTouchUpInside)
end

-- 初始化 购买按钮
function daoGuanList.initBtnBuy(self)
    self.rootItems.buyGodStone:setTouchPriority(self.buttontouch)
    self.rootItems.buyGodStone:addHandleOfControlEvent(function ()
        DaoGuanBuyTimes()
        -- gameWindows:openWindow("daoGuanBuyCount")
    end, CCControlEventTouchUpInside)
end

-- 回调刷新
function daoGuanList.reloaddata(self, data)
    printT(data, "daoGuanList")


    self.panelData = data
    local maxCount = gamedata.config.global_kv.hall_challenge_times.value
    ui.setLabelString(self.rootItems.challengeCount,self.panelData.count,13)

    -- 设置玩家名字
    ui.setLabelString(self.rootItems.masterName,self.panelData.players["1"].name,21)
    -- 工会名字
    local guildName = self.panelData.players["1"].params["1"].s
    ui.setLabelString(self.rootItems.guildName,guildName,21)
    self.rootItems.guildbg:setVisible(guildName~="")
    -- 设置Icon
    self:setItemTable(self.panelData.players)
    -- 设置馆长
    self:setMasterSpine(self.panelData.players["1"])
    -- 按NPC显示还是按玩家显示
    self:updateNpcOrPlayer(self.panelData.players["1"].rid, self.panelData.players["1"].param)
end

function daoGuanList.refreshData(self )
    UIRequest({type = 5303, id = self.paramData.type})
end

-- 设置馆长Spine
function daoGuanList.setMasterSpine(self, data)
    printT(data, "setMasterSpine")
    self.rootItems.spine:removeAllChildrenWithCleanup(true)

    local _generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(data.profile).animationid)].name
    local _wing = {level = data.params["2"].i, color = data.params["3"].i }
    local _gneral = ui.itemcache:loadSkeleton(_generalName, _wing)
    _gneral:setAnimation("stand", true, 0)
    _gneral:setScale(1.6)
    _gneral:setPosition(0, 0)
    printT(_gneral, "setMasterSpine")
    self.rootItems.spine:addChild(_gneral.root or _gneral)
end

function daoGuanList.updateNpcOrPlayer(self, rid, power)
    -- if rid < 0 then
    --     self.rootItems.powerNode:setVisible(false)
    -- else
        self.rootItems.powerNode:setVisible(true)
        self.rootItems.powerLabel:setString(power)
    -- end
end

-- 清除界面
function daoGuanList.clear(self)
    self.ListTableView = nil
    gameTimer:UnrigistTimeFunc("daoguan_timing_in")

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.isopen = false
end

return daoGuanList   :  