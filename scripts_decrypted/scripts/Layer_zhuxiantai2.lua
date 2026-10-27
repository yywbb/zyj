

local zhuxiantai = {

    rootNode = nil,
    rootItems = nil,

    ismax = false,
    data = {},

    buttontouch = -103,

}

function zhuxiantai.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("zhuxiantai2/zhuxiantai2", nil, true, "zhuxiantai")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY((GameScene.topposY-1620)*0.4-120)

    self.rootItems.reward:setTouchPriority(self.buttontouch-1)
    self.rootItems.reward:setSwallowsTouch(true)
    self.rootItems.reward:addHandleOfControlEvent(function()
        gameWindows:openWindow("zhuxiantaireward",self.data,nil)
    end, CCControlEventTouchUpInside)


    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.buttontouch - 1)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)


    self.rootItems.rank:setTouchPriority(self.buttontouch-1)
    self.rootItems.rank:setSwallowsTouch(true)
    self.rootItems.rank:addHandleOfControlEvent(function()
        UIRequest({type = 3625})
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.resetLab,nil,19)
    ui.setLabelString(self.rootItems.finishLab,nil,19)
    ui.setLabelString(self.rootItems.wipeLab,nil,19)
    ui.setLabelString(self.rootItems.descLab1,nil,14)

    --
    if gamedata.config.build[tostring(164)] and gamedata.config.build[tostring(164)].switch and gamedata.config.build[tostring(164)].switch == 1 then
        self.rootItems.pointshopNode:setVisible(true)
    else
        self.rootItems.pointshopNode:setVisible(false)
    end
    --

    UIRequest({type = 3620 })

end

function zhuxiantai.setGuai(self,location,id,isboss)
    local key_Ex
    if id == nil or id == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(id-1)
    end
    if isboss then
        key_Ex = "_1"
        self.rootItems.guai1:setVisible(false)
        self.rootItems.guai3:setVisible(false)
        self.rootItems.guai2:setVisible(true)
    else
        self.rootItems["guai"..id]:setVisible(true)
    end

    local config = gamedata.config.mieshendian_monster_param or {}
    local guaiconfig = ui.IDconfig(config[tostring(location)][tostring(id)].p1)

    local pointsnum = 0
    local reward = ui.getIDandNUMs(config[tostring(location)][tostring(id)].star1reward) or {}
    for k,v in pairs(reward) do
        if v.cid == 1004 then
            pointsnum = v.num
        end
    end
    ui.setLabelString(self.rootItems["g_power"..key_Ex],"推荐战斗力:"..(config[tostring(location)][tostring(id)].power or "?"),21)
    ui.setLabelString(self.rootItems["g_points"..key_Ex],(pointsnum > 0) and ("积分:"..pointsnum) or "",46)

    --ui.setLabelString(self.rootItems["g_level"..key_Ex], isboss and "" or id.."星",48)
    ui.setLabelString(self.rootItems["g_name"..key_Ex],guaiconfig.name,14)

    if self.rootItems["g_level_node"..key_Ex] then
        for i = 1,3 do
            self.rootItems["g_level_star"..i..key_Ex]:setVisible(id == i)
        end
        self.rootItems["g_level_node"..key_Ex]:setVisible(not isboss)
    end
    self.rootItems["g_general"..key_Ex]:setScale(1.3)
    self.rootItems["g_general"..key_Ex]:removeAllChildrenWithCleanup(true)

    local generalName = gamedata.config.generalanimation[tostring(guaiconfig.animationid)].name
    local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral:setAnimation("stand",true,0)
    self.rootItems["g_general"..key_Ex]:addChild(Gneral)
    --self.rootItems["g_level"..key_Ex]:setVisible(true)
    self.rootItems["g_name"..key_Ex]:setVisible(true)

    self.rootItems["g_boss"..key_Ex]:setVisible(isboss or false)

    --self.rootItems["g_effect"..key_Ex]:removeAllChildrenWithCleanup(true)
    --local ccb, eitem = CCBReaderLoad("UIEffect/duikan/duikan.ccbi", nil, true, "duikan")
    --self.rootItems["g_effect"..key_Ex]:addChild(ccb)

    self.rootItems["g_button"..key_Ex]:setTouchPriority(self.buttontouch)
    self.rootItems["g_button"..key_Ex]:setSwallowsTouch(true)
    self.rootItems["g_button"..key_Ex]:addHandleOfControlEvent(function()
         print("选择难度:"..id)
         gameTouch:clickprofbytime(0.5)
         if gameTimer.times["MieshendianCD"] and gameTimer.times["MieshendianCD"] > 0 then
             -- runGamePrompt({msg = "请等待扫荡完成"})
             runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",25)})
         elseif self.ismax then
            -- runGamePrompt({msg = "本次挑战已通关最高层"})
            runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",26)})
         elseif config[tostring(location)][tostring(id)].number and config[tostring(location)][tostring(id)].number > 0 and config[tostring(location)][tostring(id)].number <= self.data.failcount then
            -- runGamePrompt({msg = "本层挑战失败次数过多，无法继续挑战"})
            runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",27)})
         elseif isboss then
            UIRequest({type = 36201})
         else
            UIRequest({type = 3621, id = id})
         end
    end, CCControlEventTouchUpInside)
end


function zhuxiantai.reloadData(self,data,goldnum)

    local goldnum = GameScene.roleinfo.gold
    if goldnum then
        goldnum = goldnum
    end
    if data then self.data = data end

    self.ismax = false
    if self.data.floor > table.getTableLength(gamedata.config.mieshendian_monster_param) then
       self.ismax = true
       self.data.floor = table.getTableLength(gamedata.config.mieshendian_monster_param)
    end

    -- self.rootItems.floor:setString(self.data.floor.."层")
    self.rootItems.floor:setString(self.data.floor.."层")
    -- self.rootItems.count:setString(self.data.failcount.."次")
    self.rootItems.count:setString(self.data.failcount.."次")
    self.rootItems.totalstar:setString(self.data.star)
    --
    local config = gamedata.config.mieshendian_monster_param or {}
    if config[tostring(self.data.floor)]["1"] and config[tostring(self.data.floor)]["1"].number and config[tostring(self.data.floor)]["1"].number+0 > 0 then
        self.rootItems.count:setString((config[tostring(self.data.floor)]["1"].number-self.data.failcount).."/"..config[tostring(self.data.floor)]["1"].number.."次")
    end
    --
    self.rootItems.condition:setString("战胜全部目标")
    ui.setLabelString(self.rootItems.condition,nil,27)
    if self.rootItems.condition then
       local condition_config = gamedata.config.mieshendian_condition or {}
       local type_config = gamedata.config.mieshendian_type or {}

       local condition = "战胜全部目标"
       local condition_num = ""
       if condition_config[tostring(self.data.floor)] and condition_config[tostring(self.data.floor)].condition then
          if condition_config[tostring(self.data.floor)].condition_param and condition_config[tostring(self.data.floor)].condition_param ~= 0 then
             if condition_config[tostring(self.data.floor)].condition_param < 1 then
                 condition_num = (condition_config[tostring(self.data.floor)].condition_param*100).."%"
             else
                 condition_num = tostring(condition_config[tostring(self.data.floor)].condition_param)
             end
          end
          if type_config[tostring(condition_config[tostring(self.data.floor)].condition)] and type_config[tostring(condition_config[tostring(self.data.floor)].condition)].type then
              condition = string.format(type_config[tostring(condition_config[tostring(self.data.floor)].condition)].type,condition_num)
          end
       end
       self.rootItems.condition:setString(condition)
       ui.setLabelString(self.rootItems.condition,nil,27)
    end
    --
    if math.mod(self.data.floor,5) == 0 then
        self:setGuai(self.data.floor,1,true)
    else
        for i = 1,3 do
            self:setGuai(self.data.floor,i)
        end
    end
    --

    self.rootItems.cdtime:setString("")
    self.rootItems.goldnode:setVisible(false)
    -- self.rootItems.wipeLab:setString("扫 荡")
    self.rootItems.wipeLab:setString(gameConfig.strings:string_common("zhuxiantai",28))
    ui.setLabelString(self.rootItems.wipeLab,nil,19)
    --
    local resetgold = 0
    --local resetcount = tonumber(gamedata.config.global_kv.mieshendian_free.value) + self.data.resetbuy - self.data.todaycount
    local resetcount = gamedata.config.vip[tostring(GameScene.vip.vip)].bzxtrst - self.data.todaycount
    self.rootItems.resetnum:setString(resetcount)
    if gamedata.config.buycount_price[tostring(self.data.todaycount+1)] and gamedata.config.buycount_price[tostring(self.data.todaycount+1)].mieshendian then
        resetgold = gamedata.config.buycount_price[tostring(self.data.todaycount+1)].mieshendian+0
    end
    if (resetgold > 0) and (resetcount > 0) then
        self.rootItems.reset_goldnode:setVisible(true)
        print("goldnum-====",goldnum,resetgold)

        if goldnum and goldnum >= resetgold then
            ui.setLabelString(self.rootItems.reset_xgold,resetgold,21)
        else
            ui.setLabelString(self.rootItems.reset_xgold,resetgold,11)
        end
        -- self.rootItems.reset_xgold:setString(resetgold)
    else
        self.rootItems.reset_goldnode:setVisible(false)
    end
    --
    self.rootItems.resetButton:setTouchPriority(self.buttontouch-1)
    self.rootItems.resetButton:setSwallowsTouch(true)
    self.rootItems.resetButton:addHandleOfControlEvent(function()
        if gameTimer.times["MieshendianCD"] and gameTimer.times["MieshendianCD"] > 0 then
            -- runGamePrompt({msg = "请等待扫荡完成"})
            runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",30)})
        elseif resetcount < 1 then
            runGamePrompt({msg = "重置次数不足"})
        else
            if self.data.floor == 1 then
                runGamePrompt({msg = "已经是最底层无法重置"})
            else
                local cb = function()
                    UIRequest({type = 3626, xgold = resetgold})
                end
                --gameWindows:openWindow("confirm",{msg = "是否重置当前灭神殿层数?"}, cb)
                local rich = {
                    {fontID = 1,content = "当前处于"..self.data.floor.."层，\n",},
                    {fontID = 1,content = "是否消耗 ",},
                    {fontID = 0,content = "obj_s_gold",},
                    {fontID = 11,content = " "..resetgold,},
                    {fontID = 1,content = " 重置当前灭神殿？",},
                }
                gameWindows:openWindow("confirm",{rich = rich}, cb)
            end
        end
    end, CCControlEventTouchUpInside)

    if resetcount < 1 then
        ui.addGray("CCControlButton",self.rootItems.resetButton)
    else
        ui.removeGray("CCControlButton",self.rootItems.resetButton)
    end

    self.rootItems.wipeButton:setTouchPriority(self.buttontouch-1)
    self.rootItems.wipeButton:setSwallowsTouch(true)
    self.rootItems.wipeButton:addHandleOfControlEvent(function()
        --
        -- print("level===",ui.getVipLevelByStr("mieshendian_sweep"),GameScene.vip.vip,gamedata.config.global_kv.mieshendian_saodang_openlv.value,GameScene.roleinfo.level)
        if ui.getVipLevelByStr("mieshendian_sweep") > GameScene.vip.vip and (gamedata.config.global_kv.mieshendian_saodang_openlv and tonumber(gamedata.config.global_kv.mieshendian_saodang_openlv.value) > GameScene.roleinfo.level) then
            -- runGamePrompt({msg = "VIP"..ui.getVipLevelByStr("mieshendian_sweep").."以上,或者队伍等级"..(gamedata.config.global_kv.mieshendian_saodang_openlv.value).."以上可使用扫荡功能"})
            runGamePrompt({msg = (gameConfig.strings:string_common("worldboss",9))..ui.getVipLevelByStr("mieshendian_sweep")..(gameConfig.strings:string_common("zhuxiantai",43))..(gamedata.config.global_kv.mieshendian_saodang_openlv.value)..(gameConfig.strings:string_common("zhuxiantai",44))})
            
        --elseif self.data.maxfloor < 5 then
            -- runGamePrompt({msg = "历史最高层大于5层才可扫荡"})
        --    runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",31)})
        elseif gameTimer.times["MieshendianCD"] and gameTimer.times["MieshendianCD"] > 0 then
            -- runGamePrompt({msg = "请等待扫荡完成"})
            runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",32)})
        elseif self.ismax then
            -- runGamePrompt({msg = "本次挑战已通关最高层"})
            runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",33)})
        --elseif math.floor(self.data.floor/5) >= math.floor(self.data.maxfloor/5) then
        elseif self.data.floor >= self.data.maxwipe+1 then
            -- runGamePrompt({msg = "已到达本次可扫荡的最高层"})
            runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",34)})
        else
            UIRequest({type = 3623})
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.finishButton:setTouchPriority(self.buttontouch-1)
    self.rootItems.finishButton:setSwallowsTouch(true)
    self.rootItems.finishButton:addHandleOfControlEvent(function()
        if gameTimer.times["MieshendianCD"] and gameTimer.times["MieshendianCD"] > 0 then
            UIRequest({type = 3624, xnum = math.ceil(gameTimer.times["MieshendianCD"]/60)*(tonumber(gamedata.config.global_kv.mieshendian_saodang_gold.value))})
        else
            -- runGamePrompt({msg = "现在并无扫荡，无法立即完成"})
            runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",35)})
        end
    end, CCControlEventTouchUpInside)

    --
    ui.setLabelString(self.rootItems.points,"积分:"..(self.data.points or 0),21)
    self.rootItems.pointshop:setTouchPriority(self.buttontouch-1)
    self.rootItems.pointshop:setSwallowsTouch(true)
    self.rootItems.pointshop:addHandleOfControlEvent(function()
        print("去灭神商店")
        -- GameScene:shiftLayer("destroyTempleShop","up")
        GameScene:shiftLayerById(164)
    end, CCControlEventTouchUpInside)
    --

    if gameTimer.times["MieshendianCD"] and gameTimer.times["MieshendianCD"] > 0 then
        gameTimer:rigistTimeFunc("MieshendianCD",function()
            if  gameTimer.times["MieshendianCD"] <= 0 then
                UIRequest({type = 3620})
                gameTimer:UnrigistTimeFunc("MieshendianCD")
            else
                self.rootItems.cdtime:setString(ui.makeTimeText(gameTimer.times["MieshendianCD"],"hour") )
                -- self.rootItems.wipeLab:setString("扫荡中...")
                self.rootItems.wipeLab:setString(gameConfig.strings:string_common("zhuxiantai",36))
                ui.setLabelString(self.rootItems.wipeLab,nil,19)
                self.rootItems.goldnode:setVisible(true)
                local spendnum = math.ceil(gameTimer.times["MieshendianCD"]/60)*(tonumber(gamedata.config.global_kv.mieshendian_saodang_gold.value))
                
                print("goldnum-====222",goldnum,spendnum)
                if goldnum and goldnum >= spendnum then
                    ui.setLabelString(self.rootItems.xgold,spendnum,21)
                else
                    ui.setLabelString(self.rootItems.xgold,spendnum,11)
                end

                -- self.rootItems.xgold:setString()
            end
        end)
    else
        self.rootItems.cdtime:setString("")
        self.rootItems.goldnode:setVisible(false)
        -- self.rootItems.wipeLab:setString("扫 荡")
        self.rootItems.wipeLab:setString(gameConfig.strings:string_common("zhuxiantai",28))
        ui.setLabelString(self.rootItems.wipeLab,nil,19)
    end


end

function zhuxiantai.clear(self)
    if gameTimer.times["MieshendianCD"] then
        gameTimer:UnrigistTimeFunc("MieshendianCD")
    end
    self.data = {}
    self.ismax = false
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function zhuxiantai.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 3620})
    end
end

return zhuxiantai  R@  