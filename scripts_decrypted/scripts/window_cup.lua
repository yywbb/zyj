--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/19
-- Time: 下午12:00
-- To change this template use File | Settings | File Templates.
--

local cup = {
    rootNode = nil,
    rootItems = nil,

    input = nil,
    xcid = 0,
    xnum = 0,
    hasprop = 0,
    rewardNum = 1,
}

function cup.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    if data.type == "rule" then
        self.rootNode, self.rootItems = CCBReaderLoad("cup/cuprule", nil, true, "cuprule")
        self:reloadRule(data,callback)
        self.root:addChild(self.rootNode)
        return self.root
    elseif data.type == "bet" then
        self.rootNode, self.rootItems = CCBReaderLoad("cup/cupbet", nil, true, "cupbet")
        self:reloadBet(data.data,callback)
        self.root:addChild(self.rootNode)
        return self.root, true
    end
end

function cup.reloadRule(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("cup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    if data.rewardNum then
        self.rewardNum = data.rewardNum
    end
    local rewardtable = {}

    for k,v in pairs(gamedata.config.cup_reward) do
        if v.star ~= 0 then
            table.insert(rewardtable,v)
        end
    end

    local sort = function(a,b)
        if a.star>b.star then
            return true
        elseif a.star<b.star then
            return false
        elseif a.star==b.star then
            if a.top > b.top then
                return true
            else
                return false
            end
        end
    end

    table.sort(rewardtable,sort)

    for i=1,7 do
        local curReward = rewardtable[i].reward
        if self.rewardNum == 2 then
            curReward = rewardtable[i].reward2
        end
        local rewards= ui.getIDandNUMs(curReward)
        local des = ""
        for k,v in ipairs(rewards) do
            local destemp = des
            if (v.cid >= 11101 and v.cid <= 12000) or (v.cid >= 161001 and v.cid <= 162000) or (v.cid >= 171001 and v.cid <= 172000) or (v.cid >= 163001 and v.cid <= 164000) or (v.cid >= 165001 and v.cid <= 166000) or (v.cid >= 175001 and v.cid <= 176000) then
                -- des = destemp..(ui.IDconfig(v.cid).name).."魂x"..v.num.."+"
                des = gameConfig.strings:hunGet(destemp,ui.IDconfig(v.cid).name,v.num)
            else
                des = destemp..(ui.IDconfig(v.cid).name).."x"..v.num.."+"
                -- des = destemp.."竞技场积分".."x"..v.num.."+"
            end
        end
        des = string.sub(des,1,string.len(des)-1)

        if i==1 then
            self.rootItems["name"]:setString(rewardtable[i].name.."：")
            self.rootItems["reward"]:setString(des)
        else

            self.rootItems["name".."_"..(i-1)]:setString(rewardtable[i].name.."：")
            self.rootItems["reward".."_"..(i-1)]:setString(des)

        end
    end
    local curTime = gamedata.config.global_kv.check_node.value
    self.rootItems.rewardTxt:setString("开服"..curTime.."天后奖励提升");
end

function cup.setCupPropNum(self,nums)
    --self.propnum = nums["20047"]
    --self.rootItems.restprop:setString(self.propnum)
    self.hasprop = nums[tostring(self.xcid)] or 0
end

function cup.reloadBet(self,data,callback)

    self.data = data

    -- printT(self.data)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("cup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    --local betconfig = GameScene.layers["cup"].module.betcoonfig
    --self.rootItems.betnum:setString(betconfig[self.data.round-9])
    local curNum = tostring(self:getIndexByLevel())
    -- print("  curNum  ",curNum)
    -- printT(gamedata.config.cup_bet_consume,"  curNum  ")
    if gamedata.config.cup_bet_consume and gamedata.config.cup_bet_consume[curNum]["consume"..self.data.round-9] then
        local cid,num = ui.getIDandNUM(gamedata.config.cup_bet_consume[curNum]["consume"..self.data.round-9])
        self.xcid = cid
        self.xnum = num
        self.rootItems.betnum:setString(num)
    end


    if self.data.support and self.data.support ~= 0 then
        ui.setLabelString(self.rootItems.support_a,self.data.support.."%",22)
        ui.setLabelString(self.rootItems.support_b,(100-self.data.support).."%",22)
    end

--    self.rootItems.level_a:setString(self.data.a.level)
--    self.rootItems.level_b:setString(self.data.b.level)

    ui.setLabelString(self.rootItems.name_a,self.data.a.name,1)
    ui.setLabelString(self.rootItems.name_b,self.data.b.name,1)

    -- ui.setLabelString(self.rootItems.bet_a_buttontext,"下 注",18)
    -- ui.setLabelString(self.rootItems.bet_b_buttontext,"下 注",18)
    ui.setLabelString(self.rootItems.bet_a_buttontext,gameConfig.strings:string_common("popups","xiazu"),18)
    ui.setLabelString(self.rootItems.bet_b_buttontext,gameConfig.strings:string_common("popups","xiazu"),18)

    self.rootItems.bet_a_button:addHandleOfControlEvent(function() end, CCControlEventTouchUpInside)
    self.rootItems.bet_b_button:addHandleOfControlEvent(function() end, CCControlEventTouchUpInside)
    self.rootItems.playbutton:addHandleOfControlEvent(function() end, CCControlEventTouchUpInside)

    if self.data.status == -1 then
        if self.data.bet==-1 then
            self.rootItems.hasbetNode:setVisible(false)
            self.rootItems.palyNode:setVisible(false)
            self.rootItems.betNode:setVisible(true)
            self.rootItems.bet_a_button:addHandleOfControlEvent(function()
                if GameScene.layers["cup"].module.betnum <=0 then
                    -- runGamePrompt({msg = "下注次数不足"})
                    runGamePrompt({msg = gameConfig.strings:string_common("popups","xiazucishu")})
                elseif self.xnum > self.hasprop then
                    if self.xcid+0 == 1000 then
                        shortCoin()
                    elseif self.xcid+0 == 1001 then
                        shortGold()
                    else
                        -- runGamePrompt({msg = ui.IDconfig(self.xcid).name.."不足"})
                        runGamePrompt({msg = gameConfig.strings:nameBuzu(ui.IDconfig(self.xcid).name)})
                        --runGamePrompt({msg = gameConfig.strings:string_common("popups","xianqu")})
                    end
                else
                    local curLevel = self:getIndexByLevel()
                    UIRequest({type = 2105, round = self.data.round, id = self.data.id, bet = 1,curLevel = curLevel})
                end

            end, CCControlEventTouchUpInside)
            self.rootItems.bet_a_button:setSwallowsTouch(true)
            self.rootItems.bet_a_button:setTouchPriority(self.touchPriority)
            self.rootItems.bet_b_button:addHandleOfControlEvent(function()
                if GameScene.layers["cup"].module.betnum <=0 then
                    -- runGamePrompt({msg = "下注次数不足"})
                    runGamePrompt({msg = gameConfig.strings:string_common("popups","xiazucishu")})
                elseif self.xnum > self.hasprop then
                    if self.xcid+0 == 1000 then
                        shortCoin()
                    elseif self.xcid+0 == 1001 then
                        shortGold()
                    else
                        -- runGamePrompt({msg = ui.IDconfig(self.xcid).name.."不足"})
                        runGamePrompt({msg = gameConfig.strings:nameBuzu(ui.IDconfig(self.xcid).name)})
                        --runGamePrompt({msg = gameConfig.strings:string_common("popups","xianqu")})
                    end
                else
                    local curLevel = self:getIndexByLevel()
                    UIRequest({type = 2105, round = self.data.round, id = self.data.id, bet = 0,curLevel = curLevel})
                end
            end, CCControlEventTouchUpInside)
            self.rootItems.bet_b_button:setSwallowsTouch(true)
            self.rootItems.bet_b_button:setTouchPriority(self.touchPriority)
        else
            self.rootItems.hasbetNode:setVisible(true)
            self.rootItems.palyNode:setVisible(false)
            self.rootItems.betNode:setVisible(false)
            self.rootItems.bet_a:setVisible(self.data.bet == 1)
            self.rootItems.bet_b:setVisible(self.data.bet == 0)
        end
    else
        self.rootItems.hasbetNode:setVisible(false)
        self.rootItems.palyNode:setVisible(true)

        if data.see ==0 then
            -- ui.setLabelString(self.rootItems.playlab,"直 播",18)
            ui.setLabelString(self.rootItems.playlab,gameConfig.strings:string_common("popups","zhibo"),18)
        else
            -- ui.setLabelString(self.rootItems.playlab,"重 播",18)
            ui.setLabelString(self.rootItems.playlab,gameConfig.strings:string_common("popups","chongbo"),18)
        end
        self.rootItems.betNode:setVisible(false)
        self.rootItems.playbutton:addHandleOfControlEvent(function()
            UIRequest({type = 2103, round = data.round, id = data.id,})
            UIRequest({type = 21021, id = data.id,})
        end, CCControlEventTouchUpInside)
        self.rootItems.playbutton:setSwallowsTouch(true)
        self.rootItems.playbutton:setTouchPriority(self.touchPriority)
    end

    for i=1,7 do
        if self.data.a.generals[tostring(i)] then
            self.rootItems["il_root"..(i==1 and "" or "_"..(i-1))]:setVisible(true)
            -- 设置头像
            local oldcid = self.data.a.generals[tostring(i)].oldcid
            local oldconfigdata = {}
            if oldcid > 0 then
                oldconfigdata = gamedata.config.general[tostring(oldcid)]
            end
            if next(oldconfigdata) then
                ui.setIconLv(self.rootItems,{cid = self.data.a.generals[tostring(i)].cid ,level = self.data.a.generals[tostring(i)].level1,skilllevel = self.data.a.generals[tostring(i)].skilllevel or -1, quality = oldconfigdata.quality},i-1)
            else
                ui.setIconLv(self.rootItems,{cid = self.data.a.generals[tostring(i)].cid ,level = self.data.a.generals[tostring(i)].level1,skilllevel = self.data.a.generals[tostring(i)].skilllevel or -1},i-1)
            end
        else
            self.rootItems["il_root"..(i==1 and "" or "_"..(i-1))]:setVisible(false)
        end
    end

    for i=1,7 do
        if self.data.b.generals[tostring(i)] then
            self.rootItems["il_root".."_"..(i+6)]:setVisible(true)
            --设置头像
            local oldcid = self.data.b.generals[tostring(i)].oldcid
            local oldconfigdata = {}
            if oldcid > 0 then
                oldconfigdata = gamedata.config.general[tostring(oldcid)]
            end
            if next(oldconfigdata) then
                ui.setIconLv(self.rootItems,{cid = self.data.b.generals[tostring(i)].cid ,level = self.data.b.generals[tostring(i)].level1,skilllevel = self.data.b.generals[tostring(i)].skilllevel or -1, quality = oldconfigdata.quality},i+6)
            else
                ui.setIconLv(self.rootItems,{cid = self.data.b.generals[tostring(i)].cid ,level = self.data.b.generals[tostring(i)].level1,skilllevel = self.data.b.generals[tostring(i)].skilllevel or -1},i+6)
            end
            self.rootItems["il_icon".."_"..(i+6)]:setScaleX(-1)
        else
            self.rootItems["il_root".."_"..(i+6)]:setVisible(false)
        end
    end

    UIRequest({type = 12001, cids = {self.xcid}, order=21001})

end

-- 根据等级获取索引
function cup.getIndexByLevel( self)
    local curLevel = GameScene.roleinfo.level
    local curNum = math.ceil(curLevel/10)
    return curNum
end

function cup.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    self.rewardNum = 1
    if self.callback then
        self.callback()
    end
end

return cup   a1  