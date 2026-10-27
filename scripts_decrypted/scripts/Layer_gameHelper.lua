--
-- Author: songyibo
-- Date: 2020-01-11 11:15:03
--

local helper = {
    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,
    
    pages = {"task","challenge","activity","guild"},
    status = "normal",  -- normal正常状态 setting设置状态
    selectPage = "task",
    containers = {},

    reset = {
    },

    funcName = {
        task        = "refreshTask",
        challenge   = "refreshChallenge",
        activity    = "refreshActivity",
        guild       = "refreshGuild",
    },
    initFirst = true,
}

function helper.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("youxizhushou/youxizhushou", nil, true, "youxizhushou")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos

    self:makeInitData()
    UIRequest({type = 6211})
    self:makeSettingData()
    self:initFixedString()
    self:initNode()
    self:shiftPage()
end

function helper.makeInitData(self)
    self.data = {}

    self.setting = {
        [1] = {
            [1] = {1},
            [2] = {1},
            [3] = {1},
            [4] = {1},
            [5] = {1},
            [6] = {1},
            [7] = {1},
            [8] = {1},
            [9] = {1},
            [10] = {1},
            [11] = {1},
            [12] = {1},
            [13] = {1},
            [14] = {1}
        },
        [2] = {
            [1] = {1},
            [2] = {1},
            [3] = {1},
            [4] = {1},
            [5] = {1},
            [6] = {1},
            [7] = {1,0},
        },
        [3] = {
            [1] = {1,1},
            [2] = {1,0},
            [3] = {1,1},
            [4] = {1,1,0,0,0,0,0,0,0,0,1},
            [5] = {1,1,1},
            [6] = {1,1,1},
            [7] = {1,1,1},
            [8] = {1,1,1,1,1},
            [9] = {1,1},
            [10] = {1},
            [11] = {0,0,0,0},
            [12] = {1},
            [13] = {1,1},
            [14] = {1,1},
            [15] = {1,1}
        },
        [4] = {
            [1] = {1,1},
            [2] = {1,1,1},
            [3] = {1,1,1},
            [4] = {1,1},
        },
    }

    self.params = {
        [1] = {
            [1] = {1},
            [2] = {1},
            [3] = {1},
            [4] = {1},
            [5] = {1},
            [6] = {1},
            [7] = {1},
            [8] = {1},
            [9] = {1},
            [10] = {1},
            [11] = {1},
            [12] = {1},
            [13] = {1},
            [14] = {1}
        },
        [2] = {
            [1] = {1},
            [2] = {1},
            [3] = {1},
            [4] = {1},
            [5] = {1},
            [6] = {1},
            [7] = {1},
        },
        [3] = {
            [1] = {1},
            [2] = {1},
            [3] = {1},
            [4] = {1},
            [5] = {1,1},
            [6] = {0},
            [7] = {1},
            [8] = {1},
            [9] = {0},
            [10] = {1},
            [11] = {1,1},
            [12] = {1},
            [13] = {0},
            [14] = {1},
            [15] = {1}
        },
        [4] = {
            [1] = {1},
            [2] = {1},
            [3] = {1},
            [4] = {0,0},
        },
    }

    self.cost = {
        [1] = {
            [1] = {},
            [2] = {},
            [3] = {},
            [4] = {},
            [5] = {},
            [6] = {},
            [7] = {},
            [8] = {},
            [9] = {},
            [10] = {},
            [11] = {},
            [12] = {},
            [13] = {},
            [14] = {}
        },
        [2] = {
            [1] = {},
            [2] = {},
            [3] = {},
            [4] = {},
            [5] = {},
            [6] = {},
            [7] = {}
        },
        [3] = {
            [1] = {},
            [2] = {},
            [3] = {},
            [4] = {},
            [5] = {},
            [6] = {},
            [7] = {0},
            [8] = {0},
            [9] = {},
            [10] = {},
            [11] = {},
            [12] = {},
            [13] = {},
            [14] = {},
            [15] = {}
        },
        [4] = {
            [1] = {},
            [2] = {},
            [3] = {},
            [4] = {},
        },
    }

end

function helper.initFixedString(self)
    ui.setLabelString(self.rootItems.executelbTotal,nil,19,42)
    ui.setLabelString(self.rootItems.executelb,nil,19,42)
    ui.setLabelString(self.rootItems.loglb,nil,19,42)
    ui.setLabelString(self.rootItems.setlb,nil,19,42)
    ui.setLabelString(self.rootItems.cancellb,nil,19,42)
    ui.setLabelString(self.rootItems.savelb,nil,19,42)

end


function helper.makeSettingData(self)
    local str = CCUserDefault:sharedUserDefault():getStringForKey("gameHelperSetting"..GameScene.roleinfo.id)
    if str and str ~= "" then
        local setting = LoadJsonStringToTable(str)

        for i=1,table.getTableLength(self.setting) do
            local d1 = self.setting[i]

            for i2=1,table.getTableLength(d1) do
                local d2 = self.setting[i][i2]

                for i3=1,table.getTableLength(d2) do
                    local d3 = self.setting[i][i2][i3]
                    if setting[i] and setting[i][i2] and setting[i][i2][i3] then
                        self.setting[i][i2][i3] = setting[i][i2][i3]
                    end
                end
            end
        end

        printT(self.setting,"makeSettingData")
    end


    local showParams = table.copy(self.params)
    local str = CCUserDefault:sharedUserDefault():getStringForKey("gameHelperParamSetting"..GameScene.roleinfo.id)
    if str and str ~= "" then
        local params = LoadJsonStringToTable(str)

        for i=1,table.getTableLength(self.params) do
            local d1 = showParams[i]

            for i2=1,table.getTableLength(d1) do
                local d2 = showParams[i][i2]

                for i3=1,table.getTableLength(d2) do
                    local d3 = showParams[i][i2][i3]
                    if params[i] and params[i][i2] and params[i][i2][i3] then
                        showParams[i][i2][i3] = params[i][i2][i3]
                    end
                end
            end
        end
        printT(self.showParams,"makeSettingData")
    end
    self.showParams = showParams
end

function helper.checkOpenLevel(self,level)
    return GameScene.roleinfo.level >= level
end

--初始化界面
function helper.initData(self,data)
    if data then
        self.data = data
    end
    self.initFirst = true
    for i,v in ipairs(self.pages) do
        if not self.containers[v] then
            self.containers[v] = {}
            self.containers[v].ccb,self.containers[v].items  = CCBReaderLoad("youxizhushou/container_"..v, nil, true, "youxizhushou")
            self.rootItems["scroll_"..v]:setContainer(self.containers[v].ccb)
            self.containers[v].ccb:setPositionY(self.viewH - 20 - self.containers[v].ccb:getContentSize().height)
        end
        if self.data[v] then
            self[self.funcName[v]](self)
        end
    end
    self.initFirst = false
end

function helper.shiftPage(self,pos)
    
    if pos and self.selectPage == pos then 
        return
    end
    self.selectPage = pos or self.selectPage
    
    self.rootItems.fixed1:setVisible(self.selectPage == "task")

    self.rootItems.btselect:setPositionX(self.rootItems[self.selectPage.."btNode"]:getPositionX())
    for i,v in ipairs(self.pages) do
        self.rootItems["scroll_"..v]:setPositionX(v == self.selectPage and 0 or 9999)
    end

    if not self.containers[self.selectPage] then
        self.containers[self.selectPage] = {}
        self.containers[self.selectPage].ccb,self.containers[self.selectPage].items  = CCBReaderLoad("youxizhushou/container_"..self.selectPage, nil, true, "youxizhushou")
        self.rootItems["scroll_"..self.selectPage]:setContainer(self.containers[self.selectPage].ccb)
        self.containers[self.selectPage].ccb:setPositionY(self.viewH - 20 - self.containers[self.selectPage].ccb:getContentSize().height)
        self:reload()
    end

    if self.reset[self.selectPage] then
        self:reload()
    end
end

--执行完成回调
function helper.exeCallback(self)
end

function helper.UIReset(self)
    UIRequest({type = 6211})
    for i,v in ipairs(self.pages) do
        self.reset[v] = true
    end
end


function helper.reload(self,data)
    print("reload",self.selectPage)
    if data then
        self.data = data
    end
    if self.data[self.selectPage] then
        self[self.funcName[self.selectPage]](self)
    end
    self.reset[self.selectPage] = false
end

function helper.initSwitch(self,items,level,method,index)

    if GameScene.roleinfo.level >= level then
        items[ui.ccbNameEx("s_lb",index)]:setString("")
        items[ui.ccbNameEx("s_openNode",index)]:setVisible(true)
        items[ui.ccbNameEx("s_closeNode",index)]:setVisible(false)

        items[ui.ccbNameEx("s_bg_off",index)]:setVisible(self.setting[method][index][1] == 0)
        items[ui.ccbNameEx("s_bg_on",index)]:setVisible(self.setting[method][index][1] == 1)
        items[ui.ccbNameEx("s_sp",index)]:setPositionX(self.setting[method][index][1] == 0 and -40 or 40)

        items[ui.ccbNameEx("s_bt",index)]:addHandleOfControlEvent(function ()

            local onposition = ccp(40,0)
            local offposition =  ccp(-40,0)
            local moveTo = CCMoveTo:create(0.3,self.setting[method][index][1] == 0 and onposition or offposition)
            local backOutmoveTo = CCEaseExponentialOut:create(moveTo)
            items[ui.ccbNameEx("s_sp",index)]:runAction(backOutmoveTo)
            if self.setting[method][index][1] == 0 then
                self.setting[method][index][1] = 1
            else
                self.setting[method][index][1] = 0
            end
            items[ui.ccbNameEx("s_bg_off",index)]:setVisible(self.setting[method][index][1] == 0)
            items[ui.ccbNameEx("s_bg_on",index)]:setVisible(self.setting[method][index][1] == 1)
            -- gameTouch:clickprofbytime(0.4)
        end,CCControlEventTouchUpInside)
        items[ui.ccbNameEx("s_bt",index)]:setSwallowsTouch(true)
        items[ui.ccbNameEx("s_bt",index)]:setTouchPriority(self.touchPriority)

    else
        items[ui.ccbNameEx("s_lb",index)]:setString(level.."级开启")
        items[ui.ccbNameEx("s_openNode",index)]:setVisible(false)
        items[ui.ccbNameEx("s_closeNode",index)]:setVisible(true)
    end

end

function helper.refreshTask(self)
    print("refreshTask")
    local items = self.containers["task"].items
    local config = gamedata.config.game_helper["1"]
    for i=1,table.getTableLength(config) do
        items["des"..i]:setString(config[tostring(i)].name)
        self:initSwitch(items,config[tostring(i)].level,1,i)
    end
end

function helper.refreshChallenge(self)
    print("refreshChallenge")
    local items = self.containers["challenge"].items
    local config = gamedata.config.game_helper["2"]
    for i=1,7 do
        self:initSwitch(items,config[tostring(i)].level,2,i)
    end

    for i=1,6 do

        if self.data["challenge"][tostring(i)].open == 0 and self:checkOpenLevel(config[tostring(i)].level) then
            items[ui.ccbNameEx("s_lb",i)]:setString(gameConfig.strings:string_common("gameHelper",1))
            items[ui.ccbNameEx("s_openNode",i)]:setVisible(false)
            items[ui.ccbNameEx("s_closeNode",i)]:setVisible(true)

            items["cl"..i]:setString("")

            local function cb(num)
                runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",17)})
            end

            self:initNumModel(2,i,0,0,0,cb,config[tostring(i)].level,"活动副本未开启"..i)

        else

            local id = gamedata.config.daily_function[tostring(i)]["function"]

            --当前挑战
            local configData = nil
            if tonumber(id) == 1 then
                configData = gamedata.config:getConfigByName("exp_copy")
            elseif tonumber(id) == 2 then
                configData = gamedata.config:getConfigByName("coin_copy")
            elseif tonumber(id) == 3 then
                configData = gamedata.config:getConfigByName("stone_copy")
            elseif tonumber(id) == 4 then
                configData = gamedata.config:getConfigByName("upstar_huodong")
            elseif tonumber(id) == 5 then
                configData = gamedata.config:getConfigByName("zhenfu_huodong")
            elseif tonumber(id) == 6 then
                configData = gamedata.config:getConfigByName("forging_copy")
            end

            --挑战次数
            local tag_vip = ""
            local tag_buy = ""
            if tonumber(id) == 1 then
                tag_vip = "exp_copy_times"
                tag_buy = "exp_copy_cost"
            elseif tonumber(id) == 2 then
                tag_vip = "coin_copy_times"
                tag_buy = "coin_copy_cost"
            elseif tonumber(id) == 3 then
                tag_vip = "stone_copy_times"
                tag_buy = "stone_cost"
            elseif tonumber(id) == 4 then
                tag_vip = "upstar_times"
                tag_buy = "upstar_copy_cost"
            elseif tonumber(id) == 5 then
                tag_vip = "zhenfu_times"
                tag_buy = "zhenfu_copy_cost"
            elseif tonumber(id) == 6 then
                tag_vip = "forging_copy_times"
                tag_buy = "forging_cost"
            end
            
            --购买次数
            -- local buynum = GameScene.vipstatus[tag_vip] or 0
            local buynum = 0
            --免费次数
            local freetimes = gamedata.config.vip["0"][tag_vip] or 0
            --最大可购买次数
            local canbuytimes_max = gamedata.config.vip[tostring(GameScene.vip.vip)][tag_vip] or 0
            --已挑战次数
            local challengeTimes = self.data["challenge"][tostring(i)].challengeTimes
            --可购买次数
            local canbuytimes = canbuytimes_max - buynum

            local initChallengeTimes = math.max(challengeTimes,freetimes)

            local maxChallengeTimes = freetimes + canbuytimes_max

            local configData = nil
            if tonumber(id) == 1 then
                configData = gamedata.config:getConfigByName("exp_copy")
            elseif tonumber(id) == 2 then
                configData = gamedata.config:getConfigByName("coin_copy")
            elseif tonumber(id) == 3 then
                configData = gamedata.config:getConfigByName("stone_copy")
            elseif tonumber(id) == 4 then
                configData = gamedata.config:getConfigByName("upstar_huodong")
            elseif tonumber(id) == 5 then
                configData = gamedata.config:getConfigByName("zhenfu_huodong")
            elseif tonumber(id) == 6 then
                configData = gamedata.config:getConfigByName("forging_copy")
            end

            local maxLevel = self.data["challenge"][tostring(i)].maxLevel
            maxLevel = math.min(maxLevel,table.getTableLength(configData))

            if maxLevel <= 0 then
                items["cl"..i]:setString(gameConfig.strings:string_common("gameHelper",2).."无")
                -- initChallengeTimes = 0
            else
                items["cl"..i]:setString(gameConfig.strings:string_common("gameHelper",2)..configData[tostring(maxLevel)].name)
            end

            local function setPrice(num,method)

                if method and method == "max" then
                    runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",16)})
                    return
                end

                local buy = num - freetimes
                local buynum = 0
                local totalprice = 0
                if buy > 0 then
                    for k= buynum+1, buynum+buy do
                        if gamedata.config.buycount_price[tostring(k)] then
                            totalprice = totalprice + gamedata.config.buycount_price[tostring(k)][tag_buy]
                        end
                    end
                end

                items["p"..i]:setString(totalprice)
                self.cost[2][i][1001] = totalprice
                self.params[2][i][1] = math.max(num - challengeTimes,0)
            end

            local initNum = self.showParams[2][i][1]
            local minNum = 1
            initNum = self:initNumModel(2,i,initNum,minNum,maxChallengeTimes,setPrice,config[tostring(i)].level,"活动副本"..i)
            setPrice(initNum)

        end
    end
    self:reloadMingjiang(items)
end

function helper.reloadMingjiang(self,items)
    --名将副本
    local data = self.data["challenge"]["7"]

    items.cl7:setString((gamedata.config.global_kv.star_copy_times.value-data.challengeTimes).."次")
    if data.maxLevel <= 0 and self.status ~= "normal" then
        self.setting[2][7][2] = 0
        items["cb_7_1"]:setVisible(false)
        ui.addGray("CCSprite",items["cbbg_7_1"])
        items["cbn_7_1"]:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",47)})
        end, CCControlEventTouchUpInside)
        items["cbn_7_1"]:setSwallowsTouch(true)
        items["cbn_7_1"]:setTouchPriority(self.touchPriority)
        return
    end

    self:initSelectBox(items,2,7,1,2)
end

function helper.refreshActivity(self)
    print("refreshActivity")
    local items = self.containers["activity"].items
    local config = gamedata.config.game_helper["3"]
    for i=1,15 do
        self:initSwitch(items,config[tostring(i)].level,3,i)
    end

    self:initSelectBox(items,3,3,1,2)
    
    self:initSelectBox(items,3,5,1,2)
    self:initSelectBox(items,3,6,1,2)
    self:initSelectBox(items,3,6,2,3)

    self:initMultipleSelectBox(items,3,4,1,11,3)
    self:initMultipleSelectBox(items,3,5,1,3,3)

    self:reloadMieshen(items)
    self:reloadGuanxing(items)
    self:reloadPenglai(items)
    self:reloadShenlong(items)
    self:reloadChampion(items)
    self:reloadCangjingge(items)
    self:reloadFriend(items)
    self:reloadTtyz(items)
    self:reloadJingjichang(items)
    self:reloadFriendCopy(items)
    -- self:reloadPasskill(items)
    self:reloadKingman(items)
    self:reloadTongji(items)
    self:reloadFuzhiTiangong(items)
    self:reloadBabelTower(items)
end


function helper.reloadBabelTower(self,items)
    --通天塔
    local data = self.data["activity"]["15"]

    local cb = function (type,id,index,pos,num,value,oldIndex,initCallback)
        if data.levels[tostring(value)] and data.levels[tostring(value)] > 0 then
            items.cl15:setString(gameConfig.strings:string_common("gameHelper",40)..gamedata.config.tongtianta_guaiwu[tostring(value)][tostring(data.levels[tostring(value)])].name)
        else
            items.cl15:setString(gameConfig.strings:string_common("gameHelper",40).."无")
            if not initCallback then
                runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",46)})
                self.setting[type][id][pos] = oldIndex
                for i=1,6 do
                    items["mcb_15_1".."_"..i]:setVisible(self.setting[type][id][pos] == i)
                end
                return
            end
        end
    end

    self:initMultipleSelectBox(items,3,15,1,2,6,cb)

    --未开启置灰
    for i=1,6 do
        if (data.levels[tostring(i)] and data.levels[tostring(i)] > 0) or (self.setting[3][15][2] == i) then
        else
            ui.addGray("CCSprite",items["mcbbg_15_1_"..i])
        end
    end

    --免费次数
    local freetimes = gamedata.config.vip["0"]["tongtianta_cishu"] or 0
    --最大可购买次数
    local canbuytimes_max = gamedata.config.vip[tostring(GameScene.vip.vip)]["tongtianta_cishu"] or 0
    
    local maxChallengeTimes = freetimes + canbuytimes_max

    local function setPrice(num,method)

        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",16)})
            return
        end

        local buy = num - freetimes
        local buynum = 0
        local totalprice = 0
        if buy > 0 then
            for k= buynum+1, buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice = totalprice + gamedata.config.buycount_price[tostring(k)]["tongtianta_goumai_jiage"]
                end
            end
        end

        items["p15"]:setString(totalprice)
        self.cost[3][15][1025] = totalprice
        self.params[3][15][1] = math.max(num - data.challengeTimes,0)
    end

    local initNum = self.showParams[3][15][1]
    local minNum = 1
    initReset = self:initNumModel(3,15,initNum,minNum,maxChallengeTimes,setPrice,gamedata.config.game_helper["3"]["15"].level,"通天塔")
    setPrice(initReset)
end

function helper.reloadFuzhiTiangong(self,items)
    --福祉天宫
    local data = self.data["activity"]["14"]
    local cb = function (type,id,index,pos,num,value,oldIndex,initCallback)
        if data.levels[tostring(value)] and data.levels[tostring(value)] > 0 then
            items.cl14:setString(gameConfig.strings:string_common("gameHelper",39)..gameConfig.strings:string_common("gameHelper",40 + data.levels[tostring(value)]))
        else
            if not initCallback then
                runGamePrompt({msg = string.format(gameConfig.strings:string_common("gameHelper",45), value)})
                self.setting[type][id][pos] = oldIndex
                for i=1,6 do
                    items["mcb_14_1".."_"..i]:setVisible(self.setting[type][id][pos] == i)
                end
                return
            end
            items.cl14:setString(gameConfig.strings:string_common("gameHelper",39).."无")
        end
    end

    self:initMultipleSelectBox(items,3,14,1,2,6,cb)

    --未开启置灰
    for i=1,6 do
        if data.levels[tostring(i)] and data.levels[tostring(i)] > 0 then
        else
            ui.addGray("CCSprite",items["mcbbg_14_1_"..i])
        end
    end

    --免费次数
    local freetimes = gamedata.config.vip["0"]["xianku_cishu"] or 0
    --最大可购买次数
    local canbuytimes_max = gamedata.config.vip[tostring(GameScene.vip.vip)]["xianku_cishu"] or 0
    
    local maxChallengeTimes = freetimes + canbuytimes_max

    local function setPrice(num,method)

        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",16)})
            return
        end

        local buy = num - freetimes
        local buynum = 0
        local totalprice = 0
        if buy > 0 then
            for k= buynum+1, buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice = totalprice + gamedata.config.buycount_price[tostring(k)]["fuzhi_goumai_jiage"]
                end
            end
        end

        items["p14"]:setString(totalprice)
        self.cost[3][14][1025] = totalprice
        self.params[3][14][1] = math.max(num - data.challengeTimes,0)
    end

    local initNum = self.showParams[3][14][1]
    local minNum = 1
    initReset = self:initNumModel(3,14,initNum,minNum,maxChallengeTimes,setPrice,gamedata.config.game_helper["3"]["14"].level,"福祉天宫")
    setPrice(initReset)
end

function helper.reloadTongji(self,items)
    --通缉副本
    local data = self.data["activity"]["13"]
    self:initSelectBox(items,3,13,1,2)
    local price = gamedata.config.hell_helper["1"].consume
    items["p13"]:setString(price)
    self.cost[3][13][1001] = price
end

function helper.reloadPasskill(self,items)
    --过关斩将
    local data = self.data["activity"]["11"]
    self:initMultipleSelectBox(items,3,11,1,2,3)
    self:initSelectBox(items,3,11,1,3)
    self:initSelectBox(items,3,11,2,4)

    local totalprice1 = 0
    local totalprice2 = 0

    local setPrice1 = nil
    local setPrice2 = nil

    local paramconfig = gamedata.config.through_param[tostring(1)]
    --免费次数
    local freetimes_challenge = paramconfig.challenge_max
    --最大可购买次数
    local canbuytimes_max_challenge = gamedata.config.vip[tostring(GameScene.vip.vip)]["through_times"] or 0
    
    local maxChallengeTimes = freetimes_challenge + canbuytimes_max_challenge


    setPrice1 = function (num,method)
        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",11)})
            return
        end

        local buy = num - freetimes_challenge
        local buynum = 0
        totalprice1 = 0
        if buy > 0 then
            for k= buynum+1, buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice1 = totalprice1 + gamedata.config.buycount_price[tostring(k)]["through_cost"]
                end
            end
        end

        print("setPrice1",totalprice1,totalprice2)

        items["p11_1"]:setString(totalprice1)
        self.cost[3][11][1001] = totalprice1 + totalprice2
        self.params[3][11][1] = num - data.challengeTimes
    end

    local initNum = self.showParams[3][11][1]
    local minNum = 1
    initNum = self:initNumModel(3,"11_1",initNum,minNum,maxChallengeTimes,setPrice1,gamedata.config.game_helper["3"]["11"].level,"过关斩将")
    setPrice1(initNum)

    --免费次数
    local freetimes_refresh = paramconfig.refresh_max
    --最大可购买次数
    local canbuytimes_max_refresh = 9999999
    
    local maxRefreshTimes = freetimes_refresh + canbuytimes_max_refresh

    setPrice2 = function (num,method)
        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",6)})
            return
        end

        local buy = num
        local buynum = 0
        totalprice2 = 0
        if buy > 0 then
            for k= buynum+1, buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice2 = totalprice2 + gamedata.config.buycount_price[tostring(k)]["refresh_cost"]
                end
            end
        end
        items["p11_2"]:setString(totalprice2)
        self.cost[3][11][1001] = totalprice1 + totalprice2
        self.params[3][11][2] = math.max(num - data.refreshTimes,0)
    end


    local initNum = self.showParams[3][11][2]
    local minNum = 1
    initNum = self:initNumModel(3,"11_2",initNum,minNum,maxRefreshTimes,setPrice2,gamedata.config.game_helper["3"]["11"].level,"过关斩将")
    setPrice2(initNum)

end

function helper.reloadFriendCopy(self,items)
    --好友副本
    local data = self.data["activity"]["10"]

    if data.openlevel > 0 and gamedata.config.expedition_map[tostring(data.openlevel)] then
        items.cl10_1:setString(gameConfig.strings:string_common("gameHelper",2)..gameConfig.strings:lvNum(data.openlevel - 43000,gamedata.config.expedition_map[tostring(data.openlevel)].name))
    else
        items.cl10_1:setString(gameConfig.strings:string_common("gameHelper",2).."无")
    end

    --免费次数
    local freetimes = 3
    --最大可购买次数
    local canbuytimes_max = gamedata.config.vip[tostring(GameScene.vip.vip)]["friendcopy_times"] or 0
    
    local maxChallengeTimes = freetimes + canbuytimes_max

    local function setPrice(num,method)

        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",16)})
            return
        end

        local buy = num - freetimes
        local buynum = 0
        local totalprice = 0
        if buy > 0 then
            for k= buynum+1, buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice = totalprice + gamedata.config.buycount_price[tostring(k)]["friendcopycost"]
                end
            end
        end

        items["p10"]:setString(totalprice)
        self.cost[3][10][1001] = totalprice
        self.params[3][10][1] = math.max(num - data.challengeTimes,0)
    end

    local initNum = self.showParams[3][10][1]
    local minNum = 1
    initReset = self:initNumModel(3,10,initNum,minNum,maxChallengeTimes,setPrice,gamedata.config.game_helper["3"]["10"].level,"好友副本")
    setPrice(initReset)
end

function helper.reloadJingjichang(self,items)
    self:initSelectBox(items,3,9,1,2)
    --竞技场
    local data = self.data["activity"]["9"]
    --购买次数
    local buynum = GameScene.vipstatus["b_athletics"] or 0
    --最大可购买次数
    local canbuytimes_max = gamedata.config.vip[tostring(GameScene.vip.vip)]["b_athletics"] or 0
    --剩余挑战次数
    local canChallengeTimes = data.canChallengeTimes

    items["resetlb9_1"]:setString(canChallengeTimes.."次")

    local function setPrice(num,method)
        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",12)})
            return
        end

        local buy = num
        local _buynum = 0
        local totalprice = 0
        if buy > 0 then
            for k= _buynum+1, _buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice = totalprice + gamedata.config.buycount_price[tostring(k)]["athletics"]
                end
            end
        end

        items["p9"]:setString(totalprice)
        self.cost[3][9][1001] = totalprice
        self.params[3][9][1] = math.max(num - buynum,0)
    end

    local initNum = self.showParams[3][9][1]
    local minNum = 0
    initNum = self:initNumModel(3,9,initNum,minNum,canbuytimes_max,setPrice,gamedata.config.game_helper["3"]["9"].level,"竞技场")
    setPrice(initNum)

end


function helper.reloadMieshen(self,items)
    --灭神殿
    local data = self.data["activity"]["1"]
    local totalcount = gamedata.config.vip[tostring(GameScene.vip.vip)].bzxtrst
    local resetcount = totalcount - data.reset
    items["maxlevel"]:setString(string.format(gameConfig.strings:string_common("gameHelper",5), data.maxlevel or 0))
    items["endtime1"]:setString(ui.makeTimeText(data.endtime or 0,"hour"))
    
    local notmeet = ui.getVipLevelByStr("mieshendian_sweep") > GameScene.vip.vip and (gamedata.config:getConfigByName("global_kv").mieshendian_saodang_openlv and tonumber(gamedata.config:getConfigByName("global_kv").mieshendian_saodang_openlv.value) > GameScene.roleinfo.level)

    if notmeet then
        local function cb( )
            if notmeet then
                runGamePrompt({msg = (gameConfig.strings:string_common("worldboss",9))..ui.getVipLevelByStr("mieshendian_sweep")..(gameConfig.strings:string_common("zhuxiantai",43))..(gamedata.config:getConfigByName("global_kv").mieshendian_saodang_openlv.value)..(gameConfig.strings:string_common("zhuxiantai",44))})
            -- elseif resetcount <= 0 then
            --     runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",26)})
            end
        end

        items["cbn_1_2"]:addHandleOfControlEvent(function()
            cb()
        end, CCControlEventTouchUpInside)
        items["cbn_1_2"]:setSwallowsTouch(true)
        items["cbn_1_2"]:setTouchPriority(self.touchPriority)


        items["cbn_1_1"]:addHandleOfControlEvent(function()
            cb()
        end, CCControlEventTouchUpInside)
        items["cbn_1_1"]:setSwallowsTouch(true)
        items["cbn_1_1"]:setTouchPriority(self.touchPriority)


        items["sub1"]:addHandleOfControlEvent(function()
            cb()
        end, CCControlEventTouchUpInside)
        items["sub1"]:setSwallowsTouch(true)
        items["sub1"]:setTouchPriority(self.touchPriority)

        items["add1"]:addHandleOfControlEvent(function()
            cb()
        end, CCControlEventTouchUpInside)
        items["add1"]:setSwallowsTouch(true)
        items["add1"]:setTouchPriority(self.touchPriority)
        return
    end
    
    local setPrice = nil
    --立即完成
    local totalprice1 = 0
    --重置
    local totalprice2 = 0

    --一键扫荡
    local cb = function (value)
        -- if value == 1 and self.params[3][1][1] <= 0 and resetcount > 0 then
        --     setPrice(1)
        --     self:initNumModel(3,1,1,resetcount,setPrice,gamedata.config.game_helper["3"]["1"].level,"灭神殿")
        -- end
    end
    self:initSelectBox(items,3,1,1,2,cb)

    if data.endtime and data.endtime > 0 then
        gameTimer:rigistTime("mieshendianCountdown",data.endtime)
        if gameTimer.times["mieshendianCountdown"] then
            gameTimer:UnrigistTimeFunc("mieshendianCountdown")
        end

        if gameTimer.times["mieshendianCountdown"] and gameTimer.times["mieshendianCountdown"] > 0 then
            gameTimer:rigistTimeFunc("mieshendianCountdown", function()
        
                if gameTimer.times["mieshendianCountdown"] <= 0 then
                    if gameTimer.times["mieshendianCountdown"] then
                        gameTimer:UnrigistTimeFunc("mieshendianCountdown")
                    end
                    items["endtime1"]:setString(ui.makeTimeText(0,"hour"))
                else

                    items["endtime1"]:setString(ui.makeTimeText(gameTimer.times["mieshendianCountdown"],"hour"))
                end
            end)
        end
    else
        gameTimer:rigistTime("mieshendianCountdown",0)
    end


    setPrice = function (num,method)
        print("setPrice",num)
        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",6)})
            return
        end

        local buy = num
        local buynum = 0
        totalprice2 = 0
        if buy > 0 then
            for k= buynum+1, buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice2 = totalprice2 + gamedata.config.buycount_price[tostring(k)]["mieshendian"]
                end
            end
        end

        items["p1"]:setString(totalprice2)
        self.cost[3][1][1001] = totalprice2 + totalprice1
        self.params[3][1][1] = math.max(num - data.reset,0)
    end

    local initReset = self.showParams[3][1][1]
    local minNum = 1
    initReset = self:initNumModel(3,1,initReset,minNum,totalcount,setPrice,gamedata.config.game_helper["3"]["1"].level,"灭神殿")
    cb(initReset)
    print("initReset",initReset)
    setPrice(initReset)
end

function helper.reloadGuanxing(self,items)
    --观星台
    local data = self.data["activity"]["2"]


    local tmpNVip = 100
    for k,v in pairs(gamedata.config:getConfigByName("vip")) do
        if gamedata.config:getConfigByName("vip")[tostring(k)].lookstar_onekey > 0 then
            if tonumber(k) < tmpNVip then
                tmpNVip = tonumber(k)
            end
        end
    end

    if GameScene.vip.vip < tmpNVip then

        self.setting[3][2][2] = 0
        items["cb_2_1"]:setVisible(false)
        items["cbn_2_1"]:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("fairycave",11)})
        end, CCControlEventTouchUpInside)
        items["cbn_2_1"]:setSwallowsTouch(true)
        items["cbn_2_1"]:setTouchPriority(self.touchPriority)
        return
    end

    local cb = function (value)
        local freetimes = gamedata.config:getConfigByName("vip")[tostring(GameScene.vip.vip)].c_watchstar_change
        local cnum = freetimes - data.freetimes
        if value == 1 then
            self.cost[3][2][1001] = gamedata.config.watchstar_helper[tostring(cnum)] and gamedata.config.watchstar_helper[tostring(cnum)].consume or 0
        else
            self.cost[3][2][1001] = 0
        end

        items.p2:setString(self.cost[3][2][1001])
    end
    self:initSelectBox(items,3,2,1,2,cb)

    cb(self.setting[3][2][2])
end

function helper.reloadPenglai(self,items)
    --蓬莱仙洞
    local data = self.data["activity"]["3"]
    local totalcount = gamedata.config.vip[tostring(GameScene.vip.vip)].penglai3_times
    local resetcount = totalcount - data.reset

    local function setPrice(num,method)

        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",6)})
            return
        end

        local buy = num
        local buynum = 0
        local totalprice = 0
        if buy > 0 then
            for k= buynum+1, buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice = totalprice + gamedata.config.buycount_price[tostring(k)]["penglai3reset"]
                end
            end
        end

        items["p3"]:setString(totalprice)
        self.cost[3][3][1001] = totalprice
        self.params[3][3][1] = math.max(num - data.reset,0)
    end

    local initReset = self.showParams[3][3][1]
    local minNum = 1
    initReset = self:initNumModel(3,3,initReset,minNum,totalcount,setPrice,gamedata.config.game_helper["3"]["3"].level,"蓬莱仙洞")
    setPrice(initReset)
end

function helper.reloadShenlong(self,items)
    --神龙许愿

    local levelnow = GameScene.roleinfo.level or 0
    local level = 999
    for k,v in pairs(gamedata.config.shenlong_reward) do
        if (levelnow <= v.level) and (level > v.level) then
            level = v.level
        end
    end
    local levelreward = gamedata.config.shenlong_reward[tostring(level)] or {}
    for i=1,3 do
        local rewardconfig = levelreward["reward"..i] or {}
        local reward = ui.getTableFromStr(rewardconfig)
        local config = ui.IDconfig(reward[1].cid)
        items["shenlongxuyuan_reward"..i]:setString(config.name)
    end

    local prices = {
        [1] = gamedata.config.shenlong_discount["75"]["1"].price,
        [2] = gamedata.config.shenlong_discount["75"]["2"].price,
        [3] = gamedata.config.shenlong_discount["75"]["3"].price,
        [4] = gamedata.config.shenlong_discount["75"]["4"].price,
        [5] = gamedata.config.shenlong_discount["150"]["1"].price,
        [6] = gamedata.config.shenlong_discount["150"]["2"].price,
        [7] = gamedata.config.shenlong_discount["150"]["3"].price,
        [8] = gamedata.config.shenlong_discount["150"]["4"].price,
    }

    local cb = nil
    cb = function (value,type,id,index)
        local totalprice = 0
        for i=1,8 do
            if self.setting[3][4][i+2] == 1 then
                totalprice = totalprice + prices[i]
            end
        end
        items.p4:setString(totalprice*3)
        self.cost[3][4][1001] = totalprice*3

        if value and value == 1 and GameScene.roleinfo.gold < totalprice*3 then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",29)})
            self.setting[type][id][index] = 0
            items["cb_4_"..(index-1)]:setVisible(false)
            cb()
        end
    end

    

    self:initSelectBox(items,3,4,1,2,cb)

    if GameScene.roleinfo.level <= 75 then
        self:initSelectBox(items,3,4,2,3,cb)
        self:initSelectBox(items,3,4,3,4,cb)
        self:initSelectBox(items,3,4,4,5,cb)
        self:initSelectBox(items,3,4,5,6,cb)

        for i=1,4 do
            local _pos = i + 5
            self.setting[3][4][_pos + 1] = 0
            ui.addGray("CCSprite",items["cbbg_4_".._pos])
            items["cb_4_".._pos]:setVisible(false)

            items["cbn_4_".._pos]:addHandleOfControlEvent(function()
                runGamePrompt({msg = "等级需要大于75级"})
            end, CCControlEventTouchUpInside)
            items["cbn_4_".._pos]:setSwallowsTouch(true)
            items["cbn_4_".._pos]:setTouchPriority(self.touchPriority)
        end
    else
        self:initSelectBox(items,3,4,6,7,cb)
        self:initSelectBox(items,3,4,7,8,cb)
        self:initSelectBox(items,3,4,8,9,cb)
        self:initSelectBox(items,3,4,9,10,cb)

        for i=1,4 do
            local _pos = i + 1
            self.setting[3][4][_pos + 1] = 0
            ui.addGray("CCSprite",items["cbbg_4_".._pos])
            items["cb_4_".._pos]:setVisible(false)

            items["cbn_4_".._pos]:addHandleOfControlEvent(function()
                runGamePrompt({msg = "等级已超过75级"})
            end, CCControlEventTouchUpInside)
            items["cbn_4_".._pos]:setSwallowsTouch(true)
            items["cbn_4_".._pos]:setTouchPriority(self.touchPriority)
        end
    end

    cb()
end

function helper.reloadChampion(self,items)
    --冠军试炼
    local data = self.data["activity"]["5"]

    local totalprice1 = 0
    local totalprice2 = 0

    local totalcount = 5
    local resetcount = totalcount
    items["resetlb5_1"]:setString(string.format(gameConfig.strings:string_common("gameHelper",30), totalcount))

    local setPrice1 = nil
    local setPrice2 = nil

    setPrice1 = function (num,method)
        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",11)})
            return
        end

        local buy = num
        local buynum = 0
        totalprice1 = 0
        if buy > 0 then
            for k= buynum+1, buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice1 = totalprice1 + gamedata.config.buycount_price[tostring(k)]["championbox_cost"]
                end
            end
        end

        print("setPrice1",totalprice1,self.params[3][5][2])
        totalprice1 = totalprice1 * 2
        totalprice1 = totalprice1 * (self.params[3][5][2] + 1)
        items["p5_1"]:setString(totalprice1)
        self.cost[3][5][1001] = totalprice1 + totalprice2
        self.params[3][5][1] = num
    end

    local initNum = self.showParams[3][5][1]
    local minNum = 1
    initNum = self:initNumModel(3,"5_1",initNum,minNum,resetcount,setPrice1,gamedata.config.game_helper["3"]["5"].level,"冠军试炼")
    setPrice1(initNum)

    local totalcount = gamedata.config:getConfigByName("vip")[tostring(GameScene.vip.vip)] and gamedata.config:getConfigByName("vip")[tostring(GameScene.vip.vip)].champion_times or 0
    local resetcount = totalcount - data.reset
    setPrice2 = function (num,method)
        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",6)})
            return
        end

        local buy = num
        local buynum = 0
        totalprice2 = 0
        if buy > 0 then
            for k= buynum+1, buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice2 = totalprice2 + gamedata.config.buycount_price[tostring(k)]["champion_cost"]
                end
            end
        end
        items["p5_2"]:setString(totalprice2)
        self.cost[3][5][1001] = totalprice1 + totalprice2
        self.params[3][5][2] = math.max(num - data.reset,0)
        
        setPrice1(self.params[3][5][1])
    end


    local initNum = self.showParams[3][5][2]
    local minNum = 1
    initNum = self:initNumModel(3,"5_2",initNum,minNum,totalcount,setPrice2,gamedata.config.game_helper["3"]["5"].level,"冠军试炼重置")
    setPrice2(initNum)
    
end

function helper.reloadCangjingge(self,items)
    local data = self.data["activity"]["6"]

    --购买次数
    local buynum = GameScene.vipstatus["home_challenge_times"] or 0
    --免费次数
    local freetimes = gamedata.config.vip["0"]["home_challenge_times"] or 0
    --最大可购买次数
    local canbuytimes_max = gamedata.config.vip[tostring(GameScene.vip.vip)]["home_challenge_times"] or 0
    --剩余挑战次数
    local helpTimes = data.helpcount
    --可购买次数
    local canbuytimes = canbuytimes_max - buynum

    items["resetlb6_1"]:setString(helpTimes.."次")

    local function setPrice(num,method)

        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",12)})
            return
        end

        local buy = num
        local _buynum = 0
        local totalprice = 0
        if buy > 0 then
            for k= _buynum+1, _buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice = totalprice + gamedata.config.buycount_price[tostring(k)]["home_monster_cost"]
                end
            end
        end

        items["p6"]:setString(totalprice)
        self.cost[3][6][1001] = totalprice
        self.params[3][6][1] = math.max(num - buynum,0)
    end


    -- local initNum = math.max(self.params[3][5][2],data.reset)
    
    local initNum = self.showParams[3][6][1]
    local minNum = 0
    initNum = self:initNumModel(3,6,initNum,minNum,canbuytimes_max,setPrice,gamedata.config.game_helper["3"]["6"].level,"藏经阁")
    --藏经阁、公会Boss默认特殊处理
    -- items["buynum6"]:setString(0)
    setPrice(initNum)
    
end

function helper.reloadFriend(self,items)
    --好友
    self:initSelectBox(items,3,7,1,2)
    self:initSelectBox(items,3,7,2,3)

end

function helper.reloadTtyz(self,items)
    print("reloadTtyz")
     --天庭银座
    local data = self.data["activity"]["8"]

    local _str = CCUserDefault:sharedUserDefault():getStringForKey("nightClubAddOne"..GameScene.roleinfo.id)
    local _temp = ui.getIDandNUMs(_str)
    local nightClubAutoAdd = {}
    local generalsdata = GameScene.layers["generals"].module.generalsdata
    
    for i,v in ipairs(_temp) do
        for k,vv in pairs(generalsdata) do
            if v.num == vv.cid then
                table.insert(nightClubAutoAdd,vv.iid)
            end
        end
    end

    -- if data.onGenerals and next(data.onGenerals) then
    --     for k,v in pairs(data.onGenerals) do
    --         for kk,vv in pairs(nightClubAutoAdd) do
    --             if v == vv then
    --                 nightClubAutoAdd[kk] = nil
    --             end
    --         end
    --     end
    -- end

    self.nightClubAutoAdd = nightClubAutoAdd

    printT(self.nightClubAutoAdd,"nightClubAutoAdd")

    local setPrice = function (type,id,index,pos,num,value,oldIndex)

        --vip开启
        if index == 3 and GameScene.roleinfo.vip < 7 then
            self.setting[type][id][pos] = oldIndex
            for i=1,num do
                items["mcb_"..id.."_"..index.."_"..j]:setVisible(self.setting[type][id][pos] == i)
            end
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("gameHelper",37), 7)})
            return
        end

        local c_gold = 0
        local c_shaqi = 0

        local param1 = self.setting[3][8][4]
        local param2 = self.setting[3][8][5]

        local id = (param2 - 1) * 3 + param1

        c_gold = gamedata.config.tiantingyz_time[tostring(id)] and gamedata.config.tiantingyz_time[tostring(id)].Ingots or 0
        c_shaqi = gamedata.config.tiantingyz_time[tostring(id)] and gamedata.config.tiantingyz_time[tostring(id)].murderous or 0

        local c_num = 0

        --一键添加不勾选 一键收获勾选
        if self.setting[3][8][2] == 0 and self.setting[3][8][3] == 1 then
            -- c_num = data.awardNum
        elseif self.setting[3][8][2] == 1 and self.setting[3][8][3] == 0 then
            c_num = data.freeNum
        elseif self.setting[3][8][2] == 1 and self.setting[3][8][3] == 1 then
            c_num = data.freeNum + data.awardNum
        end

        c_num = math.min(c_num,table.getTableLength(self.nightClubAutoAdd))

        items.p8_1:setString(c_gold*c_num)
        items.p8_2:setString(c_shaqi*c_num)
        self.cost[3][8][1001] = c_gold*c_num
        self.cost[3][8][1003] = c_shaqi*c_num
        print("setPrice",param1,param2,id,c_gold,c_shaqi,c_num,self.setting[3][8][2],self.setting[3][8][3])
    end

    self:initMultipleSelectBox(items,3,8,1,4,3,setPrice)
    self:initMultipleSelectBox(items,3,8,2,5,3,setPrice)

    local cb = function (value,type,id,index)
        if (data.open == 0) and (value == 1) then
            self.setting[type][id][index] = 0
            items["cb_8_1"]:setVisible(false)
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",33)})
        end
        setPrice()
    end

    self:initSelectBox(items,3,8,1,2,cb)
    self:initSelectBox(items,3,8,2,3,cb)

    setPrice()
end

function helper.reloadKingman(self,items)
    --王的男人
    local data = self.data["activity"]["12"]

    local bossConfig = gamedata.config.personalboss_att[tostring(data.openlevel)]
    if data.openlevel > 0 and bossConfig then
        items.cl12_1:setString(gameConfig.strings:string_common("gameHelper",2).."等级"..bossConfig.level.." "..bossConfig.name)
    else
        items.cl12_1:setString(gameConfig.strings:string_common("gameHelper",2).."无")
    end

    --免费次数
    local freetimes = gamedata.config.vip["0"]["personalboss_times"] or 0
    --最大可购买次数
    local canbuytimes_max = gamedata.config.vip[tostring(GameScene.vip.vip)]["personalboss_times"] or 0
    
    local maxChallengeTimes = freetimes + canbuytimes_max

    local function setPrice(num,method)

        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",16)})
            return
        end

        local buy = num - freetimes
        local buynum = 0
        local totalprice = 0
        if buy > 0 then
            for k= buynum+1, buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice = totalprice + gamedata.config.buycount_price[tostring(k)]["personalboss_cost"]
                end
            end
        end

        items["p12"]:setString(totalprice)
        self.cost[3][12][1001] = totalprice
        self.params[3][12][1] = math.max(num - data.challengeTimes,0)
    end

    local initNum = self.showParams[3][12][1]
    local minNum = 1
    initReset = self:initNumModel(3,12,initNum,minNum,maxChallengeTimes,setPrice,gamedata.config.game_helper["3"]["12"].level,"王的男人")
    setPrice(initReset)

end

function helper.refreshGuild(self)
    print("refreshGuild")
    local items = self.containers["guild"].items
    local config = gamedata.config.game_helper["4"]
    for i=1,4 do
        self:initSwitch(items,config[tostring(i)].level,4,i)

        
        if self:checkOpenLevel(config[tostring(i)].level) then
            --未加入公会
            if not next(self.data["guild"].gang2status) then
                items[ui.ccbNameEx("s_lb",i)]:setString(gameConfig.strings:string_common("gameHelper",13))
                items[ui.ccbNameEx("s_openNode",i)]:setVisible(false)
                items[ui.ccbNameEx("s_closeNode",i)]:setVisible(true)
            --公会BOSS需要公会等级2级
            elseif i == 4 then
                local needlevel = tonumber(gamedata.config:getConfigByName("global_kv").sociaty_boss_class and gamedata.config:getConfigByName("global_kv").sociaty_boss_class.value or 0)

                if self.data["guild"].gang2status.level < needlevel then
                    items[ui.ccbNameEx("s_lb",i)]:setString(string.format(gameConfig.strings:string_common("gameHelper",14), needlevel))
                    items[ui.ccbNameEx("s_openNode",i)]:setVisible(false)
                    items[ui.ccbNameEx("s_closeNode",i)]:setVisible(true)
                end
            end
        end

    end

    self:initSelectBox(items,4,1,1,2)
    self:initSelectBox(items,4,2,1,2)
    self:initSelectBox(items,4,2,2,3)
    self:initSelectBox(items,4,3,1,2)
    self:initSelectBox(items,4,4,1,2)

    local function cb(type,id,index,pos,num,value)
        local config = gamedata.config.gang2_incense[tostring(value)]
        local props = ui.getIDandNUMs(config.param)[1]
        setSpriteFrameByName(items.costIcon3,props.cid == 1000 and gameConfig.images.s_icon_1000 or gameConfig.images.s_icon_1001)
        items.p3:setString(props.num)

        self.cost[4][3] = {}
        self.cost[4][3][props.cid] = props.num
    end

    self:initMultipleSelectBox(items,4,3,1,3,3,cb)
    

    self:GuildFuli(items)
    self:GuildWenquan(items)
    self:GuildBaishen(items)
    self:reloadGuildBoss(items)
end

function helper.GuildFuli(self,items)
    if self.data["guild"].bossInfo == 0 then
        local cb = function (  )
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",13)})
        end

        items["cb_1_1"]:setVisible(false)
        self.setting[4][1][2] = 0
        items["cbn_1_1"]:addHandleOfControlEvent(function()
            cb()
        end, CCControlEventTouchUpInside)
        items["cbn_1_1"]:setSwallowsTouch(true)
        items["cbn_1_1"]:setTouchPriority(self.touchPriority)
    end
end

function helper.GuildWenquan(self,items)
    if self.data["guild"].bossInfo == 0 then
        local cb = function (  )
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",13)})
        end

        items["cb_2_1"]:setVisible(false)
        self.setting[4][2][2] = 0
        items["cbn_2_1"]:addHandleOfControlEvent(function()
            cb()
        end, CCControlEventTouchUpInside)
        items["cbn_2_1"]:setSwallowsTouch(true)
        items["cbn_2_1"]:setTouchPriority(self.touchPriority)
    end
end

function helper.GuildBaishen(self,items)
    if self.data["guild"].bossInfo == 0 then
        local cb = function (  )
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",13)})
        end

        items["cb_3_1"]:setVisible(false)
        self.setting[4][3][2] = 0
        items["cbn_3_1"]:addHandleOfControlEvent(function()
            cb()
        end, CCControlEventTouchUpInside)
        items["cbn_3_1"]:setSwallowsTouch(true)
        items["cbn_3_1"]:setTouchPriority(self.touchPriority)
    end
end

function helper.reloadGuildBoss(self,items)
    --公会boss
    local data = self.data["guild"]
    
    local cb = nil
    --没有公会
    if self.data["guild"].bossInfo == 0 then
        cb = function (  )
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",13)})
        end
    --入会时间小于一天
    elseif self.data["guild"].bossInfo == 1 then
        cb = function (  )
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",28)})
        end
    --公会等级不足
    elseif self.data["guild"].bossInfo == 2 then
        
        cb = function (  )
            local needlevel = tonumber(gamedata.config.global_kv.sociaty_boss_class and gamedata.config.global_kv.sociaty_boss_class.value or 0)
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("gameHelper",14), needlevel)})
        end
    end


    if self.data["guild"].bossInfo == 0 or self.data["guild"].bossInfo == 1 or self.data["guild"].bossInfo == 2 then

        items["cb_4_1"]:setVisible(false)
        self.setting[4][4][2] = 0
        items["cbn_4_1"]:addHandleOfControlEvent(function()
            cb()
        end, CCControlEventTouchUpInside)
        items["cbn_4_1"]:setSwallowsTouch(true)
        items["cbn_4_1"]:setTouchPriority(self.touchPriority)

        self:initNumModel(4,"4_1",0,0,0,cb,gamedata.config.game_helper["4"]["4"].level,"公会Boss未开启")
        self:initNumModel(4,"4_2",0,0,0,cb,gamedata.config.game_helper["4"]["4"].level,"公会Boss未开启")

        items["label4_1"]:setString(gameConfig.strings:string_common("gameHelper",23))
        -- items["label4_2"]:setString(gameConfig.strings:string_common("gameHelper",15)..0)
        items["p4_1"]:setString(0)
        items["p4_2"]:setString(0)

        return
    end

    --购买次数
    local buynum = GameScene.vipstatus["sociaty_boss_order"] or 0
    --免费次数
    local freetimes = gamedata.config.vip["0"]["sociaty_boss_order"] or 0
    --最大可购买次数
    local canbuytimes_max = gamedata.config.vip[tostring(GameScene.vip.vip)]["sociaty_boss_order"] or 0
    --剩余挑战次数
    local challengeTimes = data.bossChallengeTimes
    --可购买次数
    local canbuytimes = canbuytimes_max - buynum
    
    print("freetimes",freetimes)
    print("buynum",buynum)
    print("canbuytimes_max",canbuytimes_max)
    print("challengeTimes",challengeTimes)
    print("canbuytimes",canbuytimes)

    items["resetlb4_2"]:setString(challengeTimes.."次")
    --购买价格
    local totalprice1 = 0
    --元宝鼓舞价格
    local totalprice2 = 0

    -- items["label4_2"]:setString(gameConfig.strings:string_common("gameHelper",15)..(canbuytimes + challengeTimes))

    local function setPrice(num,method)
        if method and method == "max" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",16)})
            return
        end

        local buy = num
        local _buynum = 0
        totalprice2 = 0
        if buy > 0 then
            for k= _buynum+1, _buynum+buy do
                if gamedata.config.buycount_price[tostring(k)] then
                    totalprice2 = totalprice2 + gamedata.config.buycount_price[tostring(k)]["sociaty_boss_frequency"]
                end
            end
        end

        items["p4_2"]:setString(totalprice2)
        self.cost[4][4][1001] = totalprice1 + totalprice2

        -- if data.bossChallengeTimes < freetimes then
        --     self.params[4][4][2] = num
        -- else
        --     self.params[4][4][2] = num - challengeTimes
        -- end

        self.params[4][4][2] = math.max(num - buynum,0)

    end

    
    print("公会Boss",freetimes,buynum,challengeTimes)

    local initNum = self.showParams[4][4][2]
    local minNum = 0
    initNum = self:initNumModel(4,"4_2",initNum,minNum,canbuytimes_max,setPrice,gamedata.config.game_helper["4"]["4"].level,"公会Boss")
    --藏经阁、公会Boss默认特殊处理
    -- items["buynum4_2"]:setString(challengeTimes)
    setPrice(initNum)

    --一键鼓舞部分
    local needvip = 0
    for i = 1, table.getTableLength(gamedata.config.vip) do
        if gamedata.config.vip[tostring(i)] and gamedata.config.vip[tostring(i)].vip_inspire and tonumber(gamedata.config.vip[tostring(i)].vip_inspire) > 0 then
            needvip = i
            break
        end
    end

    print("needvip",needvip)

    if needvip > GameScene.roleinfo.vip then
        local function cb()
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("gameHelper",24), needvip)})
        end
        self:initNumModel(4,"4_1",0,0,0,cb,gamedata.config.game_helper["4"]["4"].level,"公会Boss一键鼓舞")
        items["label4_1"]:setString(gameConfig.strings:string_common("gameHelper",23))
        items["p4_1"]:setString(0)
    else

        local maxinspire = table.getTableLength(gamedata.config.gang2_boss_encouraging)
        -- items["label4_1"]:setString(string.format(gameConfig.strings:string_common("gameHelper",22), maxinspire - data.inspire,maxinspire))

        local function setPrice(num,method)
            if method and method == "max" then
                runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",25)})
                return
            end
            
            local buy = num
            local buynum = 0
            totalprice1 = 0
            if buy > 0 then
                for k= buynum+1, buynum+buy do
                    if gamedata.config.gang2_boss_encouraging[tostring(k)] then
                        local spend = ui.getIDandNUMs(gamedata.config.gang2_boss_encouraging[tostring(k)].money)
                        for k2,v2 in pairs(spend) do
                            if v2.cid == 1001 then
                               totalprice1 = totalprice1 + v2.num
                            end
                        end
                    end
                end
            end
            items["p4_1"]:setString(totalprice1)
            self.cost[4][4][1001] = totalprice1 + totalprice2
            self.params[4][4][1] = math.max(num - data.inspire,0)
        end
        
        local initNum = self.showParams[4][4][1]
        local minNum = 0
        initNum = self:initNumModel(4,"4_1",initNum,minNum,maxinspire,setPrice,gamedata.config.game_helper["4"]["4"].level,"公会Boss一键鼓舞")
        setPrice(initNum)
        
    end

end

function helper.initSelectBox(self,items,type,id,index,pos,callback)

    local buildId = gamedata.config.game_helper[tostring(type)][tostring(id)].level

    print("initSelectBox",type,id,index,pos)
    items["cb_"..id.."_"..index]:setVisible(self.setting[type][id][pos] == 1)

    if self.setting[type][id][pos] == 0 and self.status == "normal" then
        ui.addGray("CCSprite",items["cbbg_"..id.."_"..index])
    else
        ui.removeGray("CCSprite",items["cbbg_"..id.."_"..index])
    end

    items["cbn_"..id.."_"..index]:addHandleOfControlEvent(function()
        --非设置状态置灰 不能点击
        if self.status == "normal" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",38)})
            return
        end
        if not self:checkOpenLevel(buildId) then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",18)})
            return
        end

        if self.setting[type][id][pos] == 1 then
            self.setting[type][id][pos] = 0
        else
            self.setting[type][id][pos] = 1
        end

        print("initSelectBox",type,id,pos)
        items["cb_"..id.."_"..index]:setVisible(self.setting[type][id][pos] == 1)

        if callback then
            callback(self.setting[type][id][pos],type,id,pos)
        end

    end, CCControlEventTouchUpInside)
    items["cbn_"..id.."_"..index]:setSwallowsTouch(true)
    items["cbn_"..id.."_"..index]:setTouchPriority(self.touchPriority)

end

--pos setting数组里面的位置
-- 类型 id 第几组 setting数组里面的位置 数量
function helper.initMultipleSelectBox(self,items,type,id,index,pos,num,callback)
    print("initMultipleSelectBox",type,id,pos,num)

    for i=1,num do
        print(self.setting[type][id][pos],i)

        if self.setting[type][id][pos] ~= i and self.status == "normal" then
            ui.addGray("CCSprite",items["mcbbg_"..id.."_"..index.."_"..i])
        else
            ui.removeGray("CCSprite",items["mcbbg_"..id.."_"..index.."_"..i])
        end

        items["mcb_"..id.."_"..index.."_"..i]:setVisible(self.setting[type][id][pos] == i)
        items["mcbn_"..id.."_"..index.."_"..i]:addHandleOfControlEvent(function()
            --非设置状态置灰 不能点击
            if self.status == "normal" then
                runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",38)})
                return
            end
            local oldValue = self.setting[type][id][pos]
            self.setting[type][id][pos] = i
            for j=1,num do
                items["mcb_"..id.."_"..index.."_"..j]:setVisible(self.setting[type][id][pos] == j)
            end

            if callback then
                callback(type,id,index,pos,num,i,oldValue,false)
            end

        end, CCControlEventTouchUpInside)
        items["mcbn_"..id.."_"..index.."_"..i]:setSwallowsTouch(true)
        items["mcbn_"..id.."_"..index.."_"..i]:setTouchPriority(self.touchPriority)
    end

    if callback then
        callback(type,id,index,pos,num,self.setting[type][id][pos],self.setting[type][id][pos],true)
    end
end


function helper.initNumModel(self,t,id,initNum,minNum,maxNum,callback,buildId,tag)

    print("initNumModel",tag,initNum,maxNum)

    local _initNum = minNum

    local _curNum = initNum


    --对应的参数数据 self.params
    local _type = t
    local _id = id
    local _index = 1

    if type(id) == "string" then
        local t = string.split(id,"_")
        _id = tonumber(t[1])
        _index = tonumber(t[2])
    end

    local items = self.containers[self.pages[t]].items
    local btnSub = nil
    local btnAdd = nil
    local numLb = nil

    btnSub = items["sub"..id]
    btnAdd = items["add"..id]
    numLb = items["buynum"..id]

    --默认值切换
    -- if not self.initFirst then
    --     _curNum = tonumber(numLb:getString()) or 0
    -- end

    --按钮不能操作置灰
    local setButtonStatus = function (  )

        ui.removeGray("CCControlButton",btnSub)
        ui.removeGray("CCControlButton",btnAdd)

        if self.status == "normal" then
            ui.addGray("CCControlButton",btnSub)
            ui.addGray("CCControlButton",btnAdd)
            return
        end

        --未开启
        if buildId and not self:checkOpenLevel(buildId) then
            ui.addGray("CCControlButton",btnSub)
            ui.addGray("CCControlButton",btnAdd)
            return
        end

        if _curNum <= _initNum then
            ui.addGray("CCControlButton",btnSub)
        end

        if _curNum >= maxNum then
            ui.addGray("CCControlButton",btnAdd)
        end
    end

    if not self:checkOpenLevel(buildId) then
        numLb:setString(0)
    else
        numLb:setString(_curNum)
    end
    btnSub:addHandleOfControlEvent(function()

        if self.status == "normal" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",38)})
            return
        end

        --未开启
        if buildId and not self:checkOpenLevel(buildId) then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",18)})
            return
        end

        --不能小于初始值
        if _curNum == _initNum then
            return
        end
        _curNum = math.max(_curNum - 1,0)
        setButtonStatus()
        numLb:setString(_curNum)
        print("btnSub",_curNum,tag)

        self.showParams[_type][_id][_index] = _curNum
        callback(_curNum)
    end, CCControlEventTouchUpInside)
    btnSub:setSwallowsTouch(true)
    btnSub:setTouchPriority(self.touchPriority)

    btnAdd:addHandleOfControlEvent(function()

        if self.status == "normal" then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",38)})
            return
        end

        if buildId and not self:checkOpenLevel(buildId) then
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",18)})
            return
        end

        if _curNum >= maxNum then
           callback(_curNum,"max")
           return
        end
        _curNum = _curNum + 1
        setButtonStatus()
        numLb:setString(_curNum)
        print("btnAdd",_curNum,tag)

        self.showParams[_type][_id][_index] = _curNum
        callback(_curNum)
    end, CCControlEventTouchUpInside)
    btnAdd:setSwallowsTouch(true)
    btnAdd:setTouchPriority(self.touchPriority)

    setButtonStatus()

    return _curNum
end

function helper.initNode(self)
    self.rootItems.topnode:setPositionY(self.toppos)

    self.viewH = self.toppos - 310 - 200 - 180

    self.rootItems.s9_bg1 = tolua.cast(self.rootItems.s9_bg1, "CCScale9Sprite")
    self.rootItems.s9_bg2 = tolua.cast(self.rootItems.s9_bg1, "CCScale9Sprite")
    self.rootItems.s9_bg3 = tolua.cast(self.rootItems.s9_bg1, "CCScale9Sprite")


    self.rootItems.s9_bg1:setPreferredSize(CCSizeMake(1070,self.viewH))
    self.rootItems.s9_bg2:setPreferredSize(CCSizeMake(1046,self.viewH))
    self.rootItems.s9_bg3:setPreferredSize(CCSizeMake(1046,self.viewH))


    self.rootItems.scroll_navigation = tolua.cast(self.rootItems.scroll_navigation, "CCScrollView")
    self.rootItems.scroll_navigation:setTouchPriority(self.touchPriority - 1)

    self.rootItems.swallowbt:addHandleOfControlEvent(function()
    end, CCControlEventTouchUpInside)
    self.rootItems.swallowbt:setSwallowsTouch(true)
    self.rootItems.swallowbt:setTouchPriority(self.touchPriority - 1)

    self.rootItems.scroll_task = tolua.cast(self.rootItems.scroll_task, "CCScrollView")
    self.rootItems.scroll_task:setTouchPriority(self.touchPriority)

    self.rootItems.scroll_challenge = tolua.cast(self.rootItems.scroll_challenge, "CCScrollView")
    self.rootItems.scroll_challenge:setTouchPriority(self.touchPriority)

    self.rootItems.scroll_activity = tolua.cast(self.rootItems.scroll_activity, "CCScrollView")
    self.rootItems.scroll_activity:setTouchPriority(self.touchPriority)

    self.rootItems.scroll_guild = tolua.cast(self.rootItems.scroll_guild, "CCScrollView")
    self.rootItems.scroll_guild:setTouchPriority(self.touchPriority)

    self.rootItems.scroll_task:setViewSize(CCSizeMake(gameConfig.originSize.width,self.viewH - 40))
    self.rootItems.scroll_challenge:setViewSize(CCSizeMake(gameConfig.originSize.width,self.viewH - 40))
    self.rootItems.scroll_activity:setViewSize(CCSizeMake(gameConfig.originSize.width,self.viewH - 40))
    self.rootItems.scroll_guild:setViewSize(CCSizeMake(gameConfig.originSize.width,self.viewH - 40))

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("main","down")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority - 1)

    self.rootItems.ruleButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("gameHelperRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.ruleButton:setSwallowsTouch(true)
    self.rootItems.ruleButton:setTouchPriority(self.touchPriority - 1)

    self.rootItems.taskbt:addHandleOfControlEvent(function()
        self:shiftPage("task")
    end, CCControlEventTouchUpInside)
    self.rootItems.taskbt:setSwallowsTouch(true)
    self.rootItems.taskbt:setTouchPriority(self.touchPriority - 1)

    self.rootItems.challengebt:addHandleOfControlEvent(function()
        self:shiftPage("challenge")
    end, CCControlEventTouchUpInside)
    self.rootItems.challengebt:setSwallowsTouch(true)
    self.rootItems.challengebt:setTouchPriority(self.touchPriority - 1)

    self.rootItems.activitybt:addHandleOfControlEvent(function()
        self:shiftPage("activity")
    end, CCControlEventTouchUpInside)
    self.rootItems.activitybt:setSwallowsTouch(true)
    self.rootItems.activitybt:setTouchPriority(self.touchPriority - 1)

    self.rootItems.guildbt:addHandleOfControlEvent(function()
        self:shiftPage("guild")
    end, CCControlEventTouchUpInside)
    self.rootItems.guildbt:setSwallowsTouch(true)
    self.rootItems.guildbt:setTouchPriority(self.touchPriority - 1)


    self.rootItems.setbt:addHandleOfControlEvent(function()
        print("方案设置")
        self:setStatus("setting")
    end, CCControlEventTouchUpInside)
    self.rootItems.setbt:setSwallowsTouch(true)
    self.rootItems.setbt:setTouchPriority(self.touchPriority - 1)

    self.rootItems.logbt:addHandleOfControlEvent(function()
        print("查看日志")
        if gameWindows.windows["gameHelperLog"].module.copyData then
            gameWindows:openWindow("gameHelperLog",{method = "log"})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",20)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.logbt:setSwallowsTouch(true)
    self.rootItems.logbt:setTouchPriority(self.touchPriority - 1)

    self.rootItems.executebt:addHandleOfControlEvent(function()
        print("执行本页")
        self:executeHelper(false)
    end, CCControlEventTouchUpInside)
    self.rootItems.executebt:setSwallowsTouch(true)
    self.rootItems.executebt:setTouchPriority(self.touchPriority - 1)
    
    self.rootItems.executebtTotal:addHandleOfControlEvent(function()
        print("执行全部")
        self:executeHelper(true)
    end, CCControlEventTouchUpInside)
    self.rootItems.executebtTotal:setSwallowsTouch(true)
    self.rootItems.executebtTotal:setTouchPriority(self.touchPriority - 1)

    self.rootItems.canceltb:addHandleOfControlEvent(function()
        print("取消")
        self:setStatus("normal")
    end, CCControlEventTouchUpInside)
    self.rootItems.canceltb:setSwallowsTouch(true)
    self.rootItems.canceltb:setTouchPriority(self.touchPriority - 1)

    self.rootItems.savebt:addHandleOfControlEvent(function()
        print("保存")
        self:saveSettingFunc()
    end, CCControlEventTouchUpInside)
    self.rootItems.savebt:setSwallowsTouch(true)
    self.rootItems.savebt:setTouchPriority(self.touchPriority - 1)
end

function helper.executeHelper(self,isall)


    local params = {}
    local ext = {}

    if isall then
        for i,v in ipairs(self.pages) do
            local p,_ext = self:makeHelperParams(v)
            for i2,v2 in ipairs(p) do
                table.insert(params,v2)
            end

            for kk,vv in pairs(_ext) do
                ext[kk] = vv
            end
        end
    else
        params,ext = self:makeHelperParams(self.selectPage)
    end

    printT(params,"executeHelper")


    printT(self.cost,"self.cost")
    local cost = {}
    for k,v in pairs(params) do
        for k2,v2 in pairs(self.cost[v.type][v.id]) do
            if cost[k2] then
                cost[k2] = cost[k2] + v2
            else
                cost[k2] = v2
            end
        end
    end

    printT(cost,"cost")

    if not next(params) then
        runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",19)})
        return
    end

    --检测元宝数量够不够


    local checkCopy = nil
    local checkGold = nil

    checkCopy = function ()
        --检测更高级副本
        local copyNames = {}
        for k,v in pairs(params) do
            if v.type == 2 then
                local config = nil
                if v.id == 1 then
                    config = gamedata.config:getConfigByName("exp_copy")
                elseif v.id == 2 then
                    config = gamedata.config:getConfigByName("coin_copy")
                elseif v.id == 3 then
                    config = gamedata.config:getConfigByName("stone_copy")
                elseif v.id == 4 then
                    config = gamedata.config:getConfigByName("upstar_huodong")
                elseif v.id == 5 then
                    config = gamedata.config:getConfigByName("zhenfu_huodong")
                elseif v.id == 6 then
                    config = gamedata.config:getConfigByName("forging_copy")
                end


                local maxLevel = self.data["challenge"][tostring(v.id)].maxLevel
                local openMaxLevel = 1

                for i=1,table.getTableLength(config) do
                    if tonumber(config[tostring(i)].monster_level) <= GameScene.roleinfo.level  then
                        openMaxLevel = config[tostring(i)].id
                    else
                        break
                    end
                end
                print("checkCopy",v.id,maxLevel,openMaxLevel)
                if openMaxLevel > maxLevel then
                    table.insert(copyNames,config[tostring(openMaxLevel)])
                end
            end
        end

        if next(copyNames) then
            gameWindows:openWindow("gameHelperTip",{data = copyNames},checkGold)
        else
            checkGold()
        end
    end

    checkGold = function (  )

        if (cost[1000] and cost[1000] > 0) or (cost[1001] and cost[1001] > 0) or (cost[1003] and cost[1003] > 0) or (cost[1025] and cost[1025] > 0) then
            --精力不足
            if (cost[1003] and cost[1003] > 0 and GameScene.roleinfo.energy < cost[1003]) then
                runGamePrompt({msg = "精力值不足!"})
                return
            end

            if (cost[1000] and cost[1000] > 0) or (cost[1001] and cost[1001] > 0) or (cost[1025] and cost[1025] > 0) then
                --元宝、金币消耗提示弹窗
                gameWindows:openWindow("gameHelperConfirm",{data = cost},function ()
                    if cost[1000] and cost[1000] > GameScene.roleinfo.coin then
                        shortCoin()
                    elseif cost[1001] and cost[1001] > GameScene.roleinfo.gold then
                        shortGold()
                    elseif cost[1025] and cost[1025] > GameScene.roleinfo.g_gold then
                        shortPropById(1025)
                    else
                        UIRequest({type = 6212,params = params,cost = cost,ext = ext})
                    end
                end)
            else
                UIRequest({type = 6212,params = params,cost = cost,ext = ext})
            end

        else
            UIRequest({type = 6212,params = params,cost = cost,ext = ext})
        end
        
    end

    checkCopy()
end


--执行参数
function helper.makeHelperParams(self,type)

    local params = {}
    local ext = {}
    if type == "task" then
        for i,v in ipairs(self.setting[1]) do
            if v[1] == 1 and self:checkOpenLevel(gamedata.config.game_helper["1"][tostring(i)].level) then
                table.insert(params,self.helperParams(1,i))
            end
        end
    end

    if type == "challenge" then
        for i=1,6 do
            local v = self.setting[2][i]
            if v[1] == 1 and self:checkOpenLevel(gamedata.config.game_helper["2"][tostring(i)].level) and self.data["challenge"][tostring(i)].open == 1 and self.params[2][i][1] > 0 then
                table.insert(params,self.helperParams(2,i,self.params[2][i][1]))
            end
        end

        if self.setting[2][7][1] == 1 and self.setting[2][7][2] == 1 and self:checkOpenLevel(gamedata.config.game_helper["2"]["7"].level) then
            table.insert(params,self.helperParams(2,7))
        end
    end


    if type == "activity" then
        for i,v in ipairs(self.setting[3]) do
            if v[1] == 1  and self:checkOpenLevel(gamedata.config.game_helper["3"][tostring(i)].level) then

                --灭神殿
                if i == 1 and v[2] == 1 then
                    table.insert(params,self.helperParams(3,i,self.params[3][i][1]))
                --观星台
                elseif i == 2 and v[2] == 1 then
                    table.insert(params,self.helperParams(3,i,self.params[3][i][1]))
                --蓬莱仙洞
                elseif i == 3 and v[2] == 1 then
                    table.insert(params,self.helperParams(3,i,self.params[3][i][1]))
                --神龙许愿
                elseif i == 4 and v[2] == 1 then

                    local str = ""
                    if GameScene.roleinfo.level <= 75 then
                        for n=3,6 do
                            if v[n] == 1 then
                                str = str..(n-2)
                            end
                        end
                    else
                        for n=7,10 do
                            if v[n] == 1 then
                                str = str..(n-6)
                            end
                        end
                    end
                    table.insert(params,self.helperParams(3,i,tonumber(str),v[11]))
                --冠军试炼
                elseif i == 5 and v[2] == 1 then
                    table.insert(params,self.helperParams(3,i,v[3],self.params[3][i][1],self.params[3][i][2]))
                --藏经阁
                elseif i == 6 and v[2] == 1 then
                    table.insert(params,self.helperParams(3,i,v[3],self.params[3][i][1]))
                --好友
                elseif i == 7 then
                    table.insert(params,self.helperParams(3,i,v[2],v[3]))
                --天庭银座
                elseif i == 8 then
                
                    --天庭银座上阵武将参数
                    ext.ttyz = {}
                    local c_num = 0
                    --一键添加不勾选 一键收获勾选
                    if self.setting[3][8][2] == 0 and self.setting[3][8][3] == 1 then
                        c_num = self.data["activity"]["8"].awardNum
                    elseif self.setting[3][8][2] == 1 and self.setting[3][8][3] == 0 then
                        c_num = self.data["activity"]["8"].freeNum
                    elseif self.setting[3][8][2] == 1 and self.setting[3][8][3] == 1 then
                        c_num = self.data["activity"]["8"].freeNum + self.data["activity"]["8"].awardNum
                    end
                    c_num = math.min(c_num,table.getTableLength(self.nightClubAutoAdd))

                    for kk,vv in pairs(self.nightClubAutoAdd) do
                        table.insert(ext.ttyz,vv)
                    end

                    -- if c_num > 0 then
                    --     local param1 = self.setting[3][8][4]
                    --     local param2 = self.setting[3][8][5]
                    --     local id = (param2 - 1) * 3 + param1
                    --     table.insert(params,self.helperParams(3,i,v[2],id,v[3]))
                    -- end

                    local param1 = self.setting[3][8][4]
                    local param2 = self.setting[3][8][5]
                    local id = (param2 - 1) * 3 + param1
                    table.insert(params,self.helperParams(3,i,v[2],id,v[3]))
                --竞技场
                elseif i == 9 and v[2] == 1 then
                    table.insert(params,self.helperParams(3,i,self.params[3][i][1]))
                --好友副本
                elseif i == 10 and self.params[3][i][1] > 0 then
                    local openlevel = self.data["activity"]["10"].openlevel
                    table.insert(params,self.helperParams(3,i,self.params[3][i][1],openlevel))
                --过关斩将
                elseif i == 11 and self.params[3][i][1] > 0 then
                    table.insert(params,self.helperParams(3,i,v[2],v[3],v[4],self.params[3][i][1],self.params[3][i][2]))
                --王的男人
                elseif i == 12 and self.params[3][i][1] > 0 then
                    local openlevel = self.data["activity"]["12"].openlevel
                    table.insert(params,self.helperParams(3,i,self.params[3][i][1],openlevel))
                --通缉副本
                elseif i == 13 and v[2] == 1 then
                    table.insert(params,self.helperParams(3,i))
                --福祉天宫
                elseif i == 14 and self.params[3][i][1] > 0 then
                    local level = self.data["activity"]["14"].levels[tostring(v[2])] or 0
                    table.insert(params,self.helperParams(3,i,v[2],level,self.params[3][i][1]))
                --通天塔
                elseif i == 15 and self.params[3][i][1] >= 0 then
                    local level = self.data["activity"]["15"].levels[tostring(v[2])] or 0
                    table.insert(params,self.helperParams(3,i,v[2],level,self.params[3][i][1]))
                end
                
            end
        end
    end

    if type == "guild" then
        if next(self.data["guild"].gang2status) then
            for i,v in ipairs(self.setting[4]) do
                if v[1] == 1 and v[2] == 1 and self:checkOpenLevel(gamedata.config.game_helper["4"][tostring(i)].level) then

                    if i == 1 then
                       table.insert(params,self.helperParams(4,i))
                    elseif i == 2 then
                       table.insert(params,self.helperParams(4,i,v[3]))
                    elseif i == 3 then
                        table.insert(params,self.helperParams(4,i,v[3]))
                    elseif i == 4 and (self.params[4][i][2] > 0 or self.data["guild"].bossChallengeTimes > 0) then
                        table.insert(params,self.helperParams(4,i,self.params[4][i][1],self.params[4][i][2]))
                    end
                end
            end
        end
    end

    return params,ext
end

function helper.helperParams(type,id,param1,param2,param3,param4,param5)
    return {
        type = type,
        id = id,
        param1 = param1 or 0,
        param2 = param2 or 0,
        param3 = param3 or 0,
        param4 = param4 or 0,
        param5 = param5 or 0,
    }
end

function helper.setStatus(self,status)
    self.status = status
    self.rootItems.s9_bg2:setVisible(self.status == "normal")
    self.rootItems.s9_bg3:setVisible(self.status == "setting")
    self.rootItems.normalNode:setVisible(self.status == "normal")
    self.rootItems.setNode:setVisible(self.status == "setting")

    --切换时刷新状态
    for k,v in pairs(self.pages) do
        self.reset[v] = true
    end

    self:makeSettingData()
    self:reload()
end

function helper.saveSettingFunc(self)
    local str = MakeJsonStringFromTable(self.setting)
    print("saveSetting",str)
    CCUserDefault:sharedUserDefault():setStringForKey("gameHelperSetting"..GameScene.roleinfo.id, str)


    local str = MakeJsonStringFromTable(self.showParams)
    print("saveParam",str)
    CCUserDefault:sharedUserDefault():setStringForKey("gameHelperParamSetting"..GameScene.roleinfo.id, str)

    self:setStatus("normal")
end

function helper.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.initFirst = true
    self.status = "normal"  -- normal正常状态 setting设置状态
    self.selectPage = "task"
    self.containers = {}
    self.reset = {}
    self:makeInitData()

    if gameTimer.times["mieshendianCountdown"] then
        gameTimer:UnrigistTimeFunc("mieshendianCountdown")
    end

end

return helper #V 