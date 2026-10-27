--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 10:57
-- To change this template use File | Settings | File Templates.
--

local lead = {

    xid = 20161,
    upid = {},
    xhasnum = 0,
    uphasnum = 0,
    data = {},
    olddata = {},
    resource = nil,
    animationManager = nil,
    rootNode = nil,
    rootItems = nil,

    typenum = 1,
    costConfig = {},
    type = {
        [1] = "atk",
        [2] = "def",
        [3] = "hp",
    },
    effecttype = {
        [1] = "red",
        [2] = "blue",
        [3] = "green",
    },

    scopetype = {
        [1] = "tian",
        [2] = "di",
        [3] = "ren",
    },
    tupo_selectscope = 0,
    newgoldskill = {},
    gamestar = 0,
}

function lead.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("devil/devil2", nil, true, "devil2")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.animationManager = getAnimationManager(self.rootItems)
    self.animationManager:setAnimationCompletedCallback(function()

    end)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY(toppos/2+80)
    -- todo
    if self.rootItems.changeButton then
        if gamedata.config.build[tostring(303)] and gamedata.config.build[tostring(303)].switch and gamedata.config.build[tostring(303)].switch == 1 then
            self.rootItems.changeButton:setVisible(true)
        else
            self.rootItems.changeButton:setVisible(false)
        end

        self.rootItems.changeButton:setTouchPriority(-103)
        self.rootItems.changeButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)

            gameWindows:openWindow("changegender",nil,nil)
        end, CCControlEventTouchUpInside)
    end

    --
    if self.rootItems.showGoldtypeBtn then
        self.rootItems.showGoldtypeBtn:addHandleOfControlEvent(function()
            gameWindows:openWindow("scope_rule",nil,nil)
        end, CCControlEventTouchUpInside)
        self.rootItems.showGoldtypeBtn:setTouchPriority(-103)
    end
    --

    -- self.xid = tonumber(gamedata.config.global_kv.protagonist_add_propcid.value) or 20161
    -- if self.rootItems.propsprite then
    --     setSpriteFrameByName(self.rootItems.propsprite, ui.IDconfig(self.xid) and ui.IDconfig(self.xid).icon or "alpha")
    --     setSpriteFrameByName(self.rootItems.propsprite1, ui.IDconfig(self.xid) and ui.IDconfig(self.xid).icon or "alpha")
    --     setSpriteFrameByName(self.rootItems.propsprite2, ui.IDconfig(self.xid) and ui.IDconfig(self.xid).icon or "alpha")
    --     setSpriteFrameByName(self.rootItems.propsprite3, ui.IDconfig(self.xid) and ui.IDconfig(self.xid).icon or "alpha")
    -- end

    --
    local cliper1 = CCClippingNode:create()
    local stencil1 = CCSprite:createWithSpriteFrameName("devil_zhe.png")
    stencil1:setAnchorPoint(ccp(0,0))
    stencil1:setPosition(300,300)
    cliper1:setStencil(stencil1)
    cliper1:setAlphaThreshold(0)
    self.atkNode,self.atkItems = CCBReaderLoad("UIEffect/shuxingqiu/shuxingqiu_atk", nil, true, "atk")
    self.atkNode:setPosition(300,4)
    cliper1:addChild(self.atkNode)
    self.rootItems.atk_zhe:addChild(cliper1)
    --
    local cliper2 = CCClippingNode:create()
    local stencil2 = CCSprite:createWithSpriteFrameName("devil_zhe.png")
    stencil2:setAnchorPoint(ccp(0,0))
    stencil2:setPosition(300,300)
    cliper2:setStencil(stencil2)
    cliper2:setAlphaThreshold(0)
    self.defNode,self.defItems = CCBReaderLoad("UIEffect/shuxingqiu/shuxingqiu_def", nil, true, "def")
    self.defNode:setPosition(300,4)
    cliper2:addChild(self.defNode)
    self.rootItems.def_zhe:addChild(cliper2)
    --
    local cliper3 = CCClippingNode:create()
    local stencil3 = CCSprite:createWithSpriteFrameName("devil_zhe.png")
    stencil3:setAnchorPoint(ccp(0,0))
    stencil3:setPosition(300,300)
    cliper3:setStencil(stencil3)
    cliper3:setAlphaThreshold(0)
    self.hpNode,self.hpItems = CCBReaderLoad("UIEffect/shuxingqiu/shuxingqiu_hp", nil, true, "hp")
    self.hpNode:setPosition(300,4)
    cliper3:addChild(self.hpNode)
    self.rootItems.hp_zhe:addChild(cliper3)
    --
    self.rootItems.leftButton:setTouchPriority(-103)
    self.rootItems.leftButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        self.animationManager:runAnimationsForSequenceNamed(self.type[self.typenum].."_L")
        self.typenum = (self.typenum == 3 and 1 or self.typenum+1)
        self:setxnum()
    end, CCControlEventTouchUpInside)

    self.rootItems.rightButton:setTouchPriority(-103)
    self.rootItems.rightButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        self.animationManager:runAnimationsForSequenceNamed(self.type[self.typenum].."_R")
        self.typenum = (self.typenum == 1 and 3 or self.typenum-1)
        self:setxnum()
    end, CCControlEventTouchUpInside)

    --
    local growconfig = gamedata.config.protagonist_grow or {}

    self.rootItems.viewButton:setTouchPriority(-103)
    self.rootItems.viewButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --gameWindows:openWindow("devilpreview",{data = {protagonist = self.data,}})
        UIRequest({type = 1056})
    end, CCControlEventTouchUpInside)

    --local add1 = function()
    self.rootItems.addButton1:setTouchPriority(-103)
    self.rootItems.addButton1:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.data[self.type[self.typenum].."_a"]+1 > growconfig[tostring(self.data.level2+1)][self.type[self.typenum]] then
            -- runGamePrompt({msg = "不可超过属性上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("lead",8)})
        elseif self.xhasnum+0 >= growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1 then
            UIRequest({type = 1055, typenum = self.typenum, num = 1, xnum = growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1})
            --
            self.rootItems.addEffectNode:removeAllChildrenWithCleanup(true)
            local Node1,Items1 = CCBReaderLoad("UIEffect/mogong_peiyang/mogong_peiyang_"..self.effecttype[self.typenum], nil, true, "effect")
            self.rootItems.addEffectNode:addChild(Node1)
        else
            -- runGamePrompt({msg = "消耗道具不够"})
            runGamePrompt({msg = gameConfig.strings:string_common("lead",9)})
            gameWindows:openWindow("dropTips",{cid = self.xid},nil)
        end
    end, CCControlEventTouchUpInside)
    --end

    --local add2 = function()
    self.rootItems.addButton2:setTouchPriority(-103)
    self.rootItems.addButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.data[self.type[self.typenum].."_a"]+1 > growconfig[tostring(self.data.level2+1)][self.type[self.typenum]] then
            -- runGamePrompt({msg = "不可超过属性上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("lead",8)})
        elseif self.xhasnum+0 < growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1 then
            -- runGamePrompt({msg = "消耗道具不够"})
            runGamePrompt({msg = gameConfig.strings:string_common("lead",9)})
            gameWindows:openWindow("dropTips",{cid = self.xid},nil)
        else
            local xxnum = 10
            if self.data[self.type[self.typenum].."_a"]+10 > growconfig[tostring(self.data.level2+1)][self.type[self.typenum]] then
                xxnum = growconfig[tostring(self.data.level2+1)][self.type[self.typenum]] - self.data[self.type[self.typenum].."_a"]
            end
            if (self.xhasnum+0)/(growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1) < xxnum then
                xxnum = math.floor((self.xhasnum+0)/(growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1))
            end

            UIRequest({type = 1055, typenum = self.typenum, num = xxnum, xnum = growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*xxnum})
            --
            self.rootItems.addEffectNode:removeAllChildrenWithCleanup(true)
            local Node1,Items1 = CCBReaderLoad("UIEffect/mogong_peiyang/mogong_peiyang_"..self.effecttype[self.typenum], nil, true, "effect")
            self.rootItems.addEffectNode:addChild(Node1)

            --
        end
    end, CCControlEventTouchUpInside)
    --end

    --local add3 = function()
    self.rootItems.addButton3:setTouchPriority(-103)
    self.rootItems.addButton3:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.data[self.type[self.typenum].."_a"]+1 > growconfig[tostring(self.data.level2+1)][self.type[self.typenum]] then
            -- runGamePrompt({msg = "不可超过属性上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("lead",8)})
        elseif self.xhasnum+0 < growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1 then
            -- runGamePrompt({msg = "消耗道具不够"})
            runGamePrompt({msg = gameConfig.strings:string_common("lead",9)})
            gameWindows:openWindow("dropTips",{cid = self.xid},nil)
        else
            local xxnum = 1000
            if self.data[self.type[self.typenum].."_a"]+1000 > growconfig[tostring(self.data.level2+1)][self.type[self.typenum]] then
                xxnum = growconfig[tostring(self.data.level2+1)][self.type[self.typenum]] - self.data[self.type[self.typenum].."_a"]
            end
            if (self.xhasnum+0)/(growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1) < xxnum then
                xxnum = math.floor((self.xhasnum+0)/(growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1))
            end

            UIRequest({type = 1055, typenum = self.typenum, num = xxnum, xnum = growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*xxnum})
            --
            self.rootItems.addEffectNode:removeAllChildrenWithCleanup(true)
            local Node1,Items1 = CCBReaderLoad("UIEffect/mogong_peiyang/mogong_peiyang_"..self.effecttype[self.typenum], nil, true, "effect")
            self.rootItems.addEffectNode:addChild(Node1)
            --
        end
    end, CCControlEventTouchUpInside)
    --end
    --
    --ui.creatDelayButton(self.rootItems.addButton1,-103,add1)
    --ui.creatDelayButton(self.rootItems.addButton2,-103,add2)
    --ui.creatDelayButton(self.rootItems.addButton3,-103,add3)
    
    --
    ui.setLabelString(self.rootItems.tupotext,nil,19)
    self.rootItems.tupobuntton:setTouchPriority(-103)
    self.rootItems.tupobuntton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)

        local needsoaring = gamedata.config.protagonist_grow[tostring(self.data.general.level2+1)].soaring_limit or 0
        if needsoaring > self.data.general.level8 then
            runGamePrompt({msg = "飞升等级不足!"})
            return
        end  

        local needgamestar = gamedata.config.protagonist_grow[tostring(self.data.general.level2+1)].game_limit or 0
        if needgamestar > self.gamestar then
            runGamePrompt({msg = "游戏厅关卡等级不足!"})
            return
        end  
        --  
        self.olddata = table.copy(self.data)
        if self.tupo_selectscope and self.tupo_selectscope > 0 then
            local cb = function (  )
                UIRequest({type = 1057, xstr = growconfig[tostring(self.data.level2+1)]["consume"], scope = self.tupo_selectscope or 0})
            end
            gameWindows:openWindow("goldBreakConfirm",self.tupo_selectscope,cb)
        else
            UIRequest({type = 1057, xstr = growconfig[tostring(self.data.level2+1)]["consume"], scope = self.tupo_selectscope or 0})
        end
    end, CCControlEventTouchUpInside)
    --
    self.rootItems.upButton:setTouchPriority(-103)
    self.rootItems.upButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)

        self.olddata = table.copy(self.data)
        UIRequest({type = 1057, xstr = growconfig[tostring(self.data.level2+1)]["consume"], scope = self.tupo_selectscope or 0})

    end, CCControlEventTouchUpInside)
    --
    --
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            return true
        end
    end

    local function ccTouchMoved(x, y)

    end

    local function ccTouchEnded(x, y)
        if x-self.touchX > 20 then
            gameTouch:clickprofbytime(1)
            self.animationManager:runAnimationsForSequenceNamed(self.type[self.typenum].."_R")
            self.typenum = (self.typenum == 1 and 3 or self.typenum-1)
            self:setxnum()
        elseif self.touchX-x > 20 then
            gameTouch:clickprofbytime(1)
            self.animationManager:runAnimationsForSequenceNamed(self.type[self.typenum].."_L")
            self.typenum = (self.typenum == 3 and 1 or self.typenum+1)
            self:setxnum()
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -102, false)
    self.rootItems.touchLayer:setTouchPriority(-102)
    self.rootItems.touchLayer:setTouchEnabled(true)

    --
    if self.rootItems.addLab1 then
        ui.setLabelString(self.rootItems.addLab1,"+1",19)
        ui.setLabelString(self.rootItems.addLab2,"+10",19)
        ui.setLabelString(self.rootItems.addLab3,"+1000",19)
        ui.setLabelString(self.rootItems.upLab,nil,19)
    end
    --
    UIRequest({type = 1054, param = "update"})

    if gameConfig:checkBuildOpen(203) and GameScene:checkopenlevelbyId(203,true) then 
        UIRequest({type = 3720})
    end    
    --
end

function lead.updatePos(self)
    -- body
    local growconfig = gamedata.config.protagonist_grow
    local curCof = growconfig[tostring(self.data.level2+1)]
    if curCof then
        print("  self.type[self.typenum]  ",self.type[self.typenum])
        if self.type[self.typenum] == "atk" then
            if self.data.atk_a >= curCof.atk then
                if self.data.def_a < curCof.def  then
                    self.animationManager:runAnimationsForSequenceNamed(self.type[self.typenum].."_L")
                    self.typenum = (self.typenum == 3 and 1 or self.typenum+1)
                    gameTouch:clickprofbytime(0.5)
                else    
                    if self.data.hp_a < curCof.hp then
                        self.animationManager:runAnimationsForSequenceNamed(self.type[self.typenum].."_R")
                        self.typenum = (self.typenum == 1 and 3 or self.typenum-1)
                        gameTouch:clickprofbytime(0.5)
                    end
                end
            end
        elseif self.type[self.typenum] == "def" then
            if self.data.def_a >= curCof.def then
                if self.data.hp_a < curCof.hp  then
                    self.animationManager:runAnimationsForSequenceNamed(self.type[self.typenum].."_L")
                    self.typenum = (self.typenum == 3 and 1 or self.typenum+1)
                    gameTouch:clickprofbytime(0.5)
                else    
                    if self.data.atk_a < curCof.atk then
                        self.animationManager:runAnimationsForSequenceNamed(self.type[self.typenum].."_R")
                        self.typenum = (self.typenum == 1 and 3 or self.typenum-1)
                        gameTouch:clickprofbytime(0.5)
                    end
                end
            end
        elseif self.type[self.typenum] == "hp" then
            if self.data.hp_a >= curCof.hp then
                if self.data.atk_a < curCof.atk then
                    self.animationManager:runAnimationsForSequenceNamed(self.type[self.typenum].."_L")
                    self.typenum = (self.typenum == 3 and 1 or self.typenum+1)
                    gameTouch:clickprofbytime(0.5)
                else    
                    if self.data.def_a < curCof.def then
                        self.animationManager:runAnimationsForSequenceNamed(self.type[self.typenum].."_R")
                        self.typenum = (self.typenum == 1 and 3 or self.typenum-1)
                        gameTouch:clickprofbytime(0.5)
                    end
                end
            end
        end
    end
end

function lead.clear(self)
    self.gamestar = 0
    self.newgoldskill = {}
    self.tupo_selectscope = 0
    self.animationManager = nil
    self.data = {}
    self.olddata = {}
    self.typenum = 1
    self.costConfig = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function lead.reload(self,data)
    print("reload lead2")
    if not self.rootItems then return end

    local growconfig = gamedata.config.protagonist_grow or {}
    local haslvup = false
    local hasdata = false
    local fashionchange = false
    if self.data.level2 and self.data.level2 > 0 then
        hasdata = true
        if data.protagonist.level2 > self.data.level2 then
            haslvup = true
        end
        if data.protagonist.train ~= self.data.train then
            fashionchange = true
        end
        if data.protagonist.general and data.protagonist.general.cid and ( data.protagonist.general.cid ~= self.data.general.cid ) then
            fashionchange = true
        end
        if data.protagonist.w_l ~= self.data.w_l or data.protagonist.w_c ~= self.data.w_c then
            fashionchange = true
        end
    end

    self.data = data.protagonist or {}
    self.xhasnum = data.xhasnum or 0
    --fashion
    if self.data.train and self.data.train > 0 then
        self.rootItems.fashion_show_node:setVisible(true)
        if self.data.train == 1 then
            self.rootItems.fashion_show_sprite:setVisible(false)
        else
            self.rootItems.fashion_show_sprite:setVisible(true)
        end
        self.rootItems.fashion_show_button:setTouchPriority(-103)
        self.rootItems.fashion_show_button:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 1071})
        end, CCControlEventTouchUpInside)

        --
    else
        self.rootItems.fashion_show_node:setVisible(false)
    end
    --

    if self.rootItems.changeskillBtn then
        if self.data.general.scope and self.data.general.scope > 0 then
            self.rootItems.changeskillBtn:setVisible(true)
            self.rootItems.changeskillBtn:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                gameWindows:openWindow("changebreakskill",{general = table.copy(self.data.general), islead = 1},nil)
            end, CCControlEventTouchUpInside)
            self.rootItems.changeskillBtn:setSwallowsTouch(true)
            self.rootItems.changeskillBtn:setTouchPriority(-103)
        else
            self.rootItems.changeskillBtn:setVisible(false)
            self.rootItems.changeskillBtn:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                --
            end, CCControlEventTouchUpInside)
            self.rootItems.changeskillBtn:setSwallowsTouch(true)
            self.rootItems.changeskillBtn:setTouchPriority(-103)
        end
    end 
    self.rootItems.upcoinnode:setVisible(false)
    self.rootItems.tupo_coinnode:setVisible(false)
    self.upid = {}
    if growconfig[tostring(self.data.level2+1)] then
        local idnums = ui.getIDandNUMs(growconfig[tostring(self.data.level2+1)]["consume"]) or {}
        local cids = {}
        for k, v in pairs(idnums) do
            if v.cid == 1000 then
                self.rootItems.upcoinnode:setVisible(true)
                self.rootItems.tupo_coinnode:setVisible(true)
                self.rootItems.upcoin:setString(v.num or 0)
                self.rootItems.tupo_coin:setString(v.num or 0)
                if GameScene.roleinfo.coin < v.num then
                    ui.setLabelString(self.rootItems.upcoin,nil,47)
                    ui.setLabelString(self.rootItems.tupo_coin,nil,47)
                else
                    ui.setLabelString(self.rootItems.upcoin,nil,14)
                    ui.setLabelString(self.rootItems.tupo_coin,nil,14)
                end
            else
                table.insert(self.upid,{cid = v.cid, xnum = v.num, hasnum = 0})
                table.insert(cids,v.cid)
            end
        end
        UIRequest({type = 12001, order = 19001, cids = cids})
    end
    --

    -- local _str = CCUserDefault:sharedUserDefault():getStringForKey("useWingEffect"..GameScene.roleinfo.id)
    -- print("jkp-_str lead2 == ",_str)
    -- if _str == "0" or _str == "1" then
    --     local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.data.general.cid)].animationid)].name
    --     if string.find(generalName,"zhujue") or string.find(generalName,"shizhuang") then
    --         self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    --         local wing = {level = self.data.w_l, color = self.data.w_c}
    --         local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    --         Gneral1:setAnimation("stand",true,0)
    --         Gneral1:setScale(1.6)
    --         Gneral1:setPosition(0,0)
    --         self.rootItems["generalNode"]:addChild(Gneral1.root or Gneral1)
    --     end
    -- end

    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.data.general.cid)].animationid)].name
    local wing = {level = self.data.w_l, color = self.data.w_c}
    --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1.6)
    Gneral1:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(Gneral1.root or Gneral1)

    if (not hasdata) or fashionchange then
        self.rootItems["levelEffectNode"]:removeAllChildrenWithCleanup(true)
        local Node11,Item11 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(growconfig[tostring(self.data.level2+1)] and (math.mod(self.data.level2,5)+1) or 5), nil, true, "jie")
        self.rootItems.levelEffectNode:addChild(Node11)

        if self.rootItems.name then
            self.rootItems.name:setString(ui.leadName(self.data.level2))
            if gamedata.config.general[tostring(self.data.general.cid)].quality and gamedata.config.general[tostring(self.data.general.cid)].quality >= 7 then
                ui.setLabelString(self.rootItems.name,nil, 213)
            else    
                ui.setLabelString(self.rootItems.name,nil, gamedata.config.general[tostring(self.data.general.cid)].quality~=0 and 2*gamedata.config.general[tostring(self.data.general.cid)].quality-1 or 1)
            end
        end
    end
    --
    if self.rootItems.goldtypeNode then
        if self.data.general.scope and self.data.general.scope > 0 then
            self.rootItems.goldtypeNode:setVisible(true)
            setSpriteFrameByName(self.rootItems.goldtype,"tujin_"..self.scopetype[self.data.general.scope])
        else
            self.rootItems.goldtypeNode:setVisible(false)
        end    
    end   
    --
    if growconfig[tostring(self.data.level2+1)] then
        self.rootItems.maxNode:setVisible(false)
        if (self.data.level2+1) > (gamedata.config.global_kv.passive_breakthrough_limit and tonumber(gamedata.config.global_kv.passive_breakthrough_limit.value) or 23) then
            self.rootItems.addNode:setVisible(false)
            self.rootItems.addNode:setPositionX(-9999)
            self.rootItems.upNode:setVisible(false)
            self.rootItems.updes:setVisible(false)
            --
            self.rootItems.oldnode:setVisible(false)
            self.rootItems.bottomnode:setVisible(false)
            self.rootItems.newbottomnode:setVisible(true) 
            self.rootItems.tuponextattnode:setVisible(true)
            self.rootItems.tupocontrolnode:setVisible(true)
            self.rootItems.tupo_title:setString("进阶材料") 
            --
            self:setaddnum_gold()
        else
            --
            self:updatePos()
            self:setxnum()
            self:setaddnum()    
            --
            if self.data.atk_a >= growconfig[tostring(self.data.level2+1)].atk and self.data.def_a >= growconfig[tostring(self.data.level2+1)].def and self.data.hp_a >= growconfig[tostring(self.data.level2+1)].hp then
                self.rootItems.addNode:setVisible(false)
                self.rootItems.addNode:setPositionX(-9999)
                self.rootItems.upNode:setVisible(true)
                self.rootItems.updes:setVisible(false)
                --
                self.rootItems.oldnode:setVisible(true)
                self.rootItems.bottomnode:setVisible(true)
                self.rootItems.newbottomnode:setVisible(false)
            else
                self.rootItems.addNode:setVisible(true)
                self.rootItems.addNode:setPositionX(0)
                self.rootItems.upNode:setVisible(false)
                self.rootItems.updes:setVisible(true)
                --
                self.rootItems.oldnode:setVisible(true)
                self.rootItems.bottomnode:setVisible(true)
                self.rootItems.newbottomnode:setVisible(false)
                --
            end
        end    
    else
        self.rootItems.addNode:setVisible(false)
        self.rootItems.addNode:setPositionX(-9999)
        self.rootItems.upNode:setVisible(false)
        self.rootItems.updes:setVisible(false)
        --
        self.rootItems.oldnode:setVisible(false)
        self.rootItems.bottomnode:setVisible(false)
        self.rootItems.newbottomnode:setVisible(true)
        self.rootItems.tuponextattnode:setVisible(false)
        self.rootItems.tupocontrolnode:setVisible(false)
        -- self.rootItems.tupo_title:setString("已到达最高阶")
        self.rootItems.maxNode:setVisible(true)
        ui.setLabelString(self.rootItems.tupo_condition,"",48)
        ui.setLabelString(self.rootItems.tupo_condition2,"",48)
        --
        self:setaddnum_gold()
    end
   

    if haslvup then
        self.rootItems.upEffectNode:removeAllChildrenWithCleanup(true)
        --
        local Node1,Item1 = CCBReaderLoad("UIEffect/zhujuejinjie/zhujuejinjie", nil, true, "jinjie")
        self.rootItems.upEffectNode:addChild(Node1)
        local animationManager1 = getAnimationManager(Item1)
        animationManager1:setAnimationCompletedCallback(function()
            self.rootItems.upEffectNode:removeAllChildrenWithCleanup(true)
            gameWindows:openWindow("devilsuccessUp",{data = {olddata = self.olddata, newdata = self.data}})
            --
            if guide.controller then
                guide.controller:setGuideLayerVisible(true)
            end
        end)
        animationManager1:runAnimationsForSequenceNamed("zhujuejinjie")
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
            self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
            local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.data.general.cid)].animationid)].name
            local wing = {level = self.data.w_l, color = self.data.w_c}
            --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
            Gneral1:setAnimation("stand",true,0)
            Gneral1:setScale(1.6)
            Gneral1:setPosition(0,0)
            self.rootItems["generalNode"]:addChild(Gneral1.root or Gneral1)

            self.rootItems["levelEffectNode"]:removeAllChildrenWithCleanup(true)
            local Node12,Item12 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(growconfig[tostring(self.data.level2+1)] and (math.mod(self.data.level2,5)+1) or 5), nil, true, "jie")
            self.rootItems.levelEffectNode:addChild(Node12)

            if self.rootItems.name then
                self.rootItems.name:setString(ui.leadName(self.data.level2))
                if gamedata.config.general[tostring(self.data.general.cid)].quality and gamedata.config.general[tostring(self.data.general.cid)].quality >= 7 then
                    ui.setLabelString(self.rootItems.name,nil, 213)
                else
                    ui.setLabelString(self.rootItems.name,nil, gamedata.config.general[tostring(self.data.general.cid)].quality~=0 and 2*gamedata.config.general[tostring(self.data.general.cid)].quality-1 or 1)
                end
            end
        end)))
        --
    end


end


function lead.setaddnum(self)

    local growconfig = gamedata.config.protagonist_grow or {}
    if growconfig[tostring(self.data.level2+1)] and growconfig[tostring(self.data.level2+1)]["atk_cost"] then
        self.xid = tonumber(growconfig[tostring(self.data.level2+1)]["atk_cost"]) or 20161
    end

    print("self.xid  ---   ",self.xid)
    if self.rootItems.propsprite then
        setSpriteFrameByName(self.rootItems.propsprite, ui.IDconfig(self.xid) and ui.IDconfig(self.xid).icon or "alpha")
    end

    self.rootItems.propnum:setString((gamedata.config.props[tostring(self.xid)] and gamedata.config.props[tostring(self.xid)].name..": " or "") ..self.xhasnum)


    local grow_atk,grow_def,grow_hp,grow_speed = 0,0,0,0
    for i = 2,self.data.level2 do
       if growconfig[tostring(i)] then
           grow_atk = grow_atk+growconfig[tostring(i)].atk+growconfig[tostring(i)].atk_grow
           grow_def = grow_def+growconfig[tostring(i)].def+growconfig[tostring(i)].def_grow
           grow_hp = grow_hp+growconfig[tostring(i)].hp+growconfig[tostring(i)].hp_grow
           grow_speed = grow_speed+growconfig[tostring(i)].speed_grow
       end
    end

    self.rootItems.add_atk:setString("+"..(grow_atk+self.data.atk_a))
    self.rootItems.add_def:setString("+"..(grow_def+self.data.def_a))
    self.rootItems.add_hp:setString("+"..(grow_hp+self.data.hp_a))
    self.rootItems.add_speed:setString("+"..(grow_speed or 0))

    if growconfig[tostring(self.data.level2+1)] then
        self.rootItems.addnum_atk:setString((self.data.atk_a or 0).."/"..growconfig[tostring(self.data.level2+1)].atk)
        self.rootItems.addnum_def:setString((self.data.def_a or 0).."/"..growconfig[tostring(self.data.level2+1)].def)
        self.rootItems.addnum_hp:setString((self.data.hp_a or 0).."/"..growconfig[tostring(self.data.level2+1)].hp)
        self.atkNode:setPosition(300,(300*(self.data.atk_a+0)/growconfig[tostring(self.data.level2+1)].atk)+4)
        self.defNode:setPosition(300,(300*(self.data.def_a+0)/growconfig[tostring(self.data.level2+1)].def)+4)
        self.hpNode:setPosition(300,(300*(self.data.hp_a+0)/growconfig[tostring(self.data.level2+1)].hp)+4)

    else
        self.rootItems.addnum_atk:setString("Max")
        self.rootItems.addnum_def:setString("Max")
        self.rootItems.addnum_hp:setString("Max")
        self.atkNode:setPosition(300,304)
        self.defNode:setPosition(300,304)
        self.hpNode:setPosition(300,304)
    end

    ui.setLabelString(self.rootItems.addnum_atk,nil,14)
    ui.setLabelString(self.rootItems.addnum_def,nil,14)
    ui.setLabelString(self.rootItems.addnum_hp,nil,14)

end


function lead.setxnum(self)

    local growconfig = gamedata.config.protagonist_grow or {}
    if growconfig[tostring(self.data.level2+1)] then
        -- self.rootItems.propnum1:setString("消耗"..growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1)
        -- self.rootItems.propnum2:setString("消耗"..growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*10)
        -- self.rootItems.propnum3:setString("消耗"..growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1000)
        self.rootItems.propnum1:setString(gameConfig.strings:string_common("lead",10)..growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1)
        self.rootItems.propnum2:setString(gameConfig.strings:string_common("lead",10)..growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*10)
        self.rootItems.propnum3:setString(gameConfig.strings:string_common("lead",10)..growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_stone"]*1000)

        self.costConfig[self.type[self.typenum]] = tonumber(growconfig[tostring(self.data.level2+1)][self.type[self.typenum].."_cost"]) or 20161
        
        if self.rootItems.propsprite then
            setSpriteFrameByName(self.rootItems.propsprite1, ui.IDconfig(self.costConfig[self.type[self.typenum]]) and ui.IDconfig(self.costConfig[self.type[self.typenum]]).icon or "alpha")
            setSpriteFrameByName(self.rootItems.propsprite2, ui.IDconfig(self.costConfig[self.type[self.typenum]]) and ui.IDconfig(self.costConfig[self.type[self.typenum]]).icon or "alpha")
            setSpriteFrameByName(self.rootItems.propsprite3, ui.IDconfig(self.costConfig[self.type[self.typenum]]) and ui.IDconfig(self.costConfig[self.type[self.typenum]]).icon or "alpha")
        end


        --propsprite3
    else
        -- self.rootItems.propnum1:setString("满阶无法消耗")
        -- self.rootItems.propnum2:setString("满阶无法消耗")
        -- self.rootItems.propnum3:setString("满阶无法消耗")
        self.rootItems.propnum1:setString(gameConfig.strings:string_common("lead",11))
        self.rootItems.propnum2:setString(gameConfig.strings:string_common("lead",11))
        self.rootItems.propnum3:setString(gameConfig.strings:string_common("lead",11))
    end
end

function lead.setPropNum(self,props)

    for k,v in ipairs(self.upid) do
        v.hasnum = props[tostring(v.cid)] or 0

        if k <= 3 then
            ui.setNewIcon(self.rootItems,{cid = v.cid,num = v.hasnum.."/"..v.xnum},k-1)
            ui.setLabelString(self.rootItems["i_num"..(k==1 and "" or "_"..(k-1))],nil,(v.hasnum >= v.xnum) and 22 or 24)
            self.rootItems["i_button"..(k==1 and "" or "_"..(k-1))]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(v.cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..(k==1 and "" or "_"..(k-1))]:setTouchPriority(-104)
        end
        --
        if k <= 5 then 
            ui.setNewIcon(self.rootItems,{cid = v.cid,num = v.hasnum.."/"..v.xnum},k+2)
            ui.setLabelString(self.rootItems["i_num_"..(k+2)],nil,(v.hasnum >= v.xnum) and 22 or 24)
            self.rootItems["i_button_"..(k+2)]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(v.cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button_"..(k+2)]:setTouchPriority(-104)
        end
    end

    if self.upid[3] then
        self.rootItems.upprop1:setPositionX(-170)
        self.rootItems.upprop2:setPositionX(0)
        self.rootItems.upprop3:setPositionX(170)
    elseif self.upid[2] then
        self.rootItems.upprop1:setPositionX(-100)
        self.rootItems.upprop2:setPositionX(100)
        self.rootItems.upprop3:setPositionX(9999)
    elseif self.upid[1] then
        self.rootItems.upprop1:setPositionX(0)
        self.rootItems.upprop2:setPositionX(9999)
        self.rootItems.upprop3:setPositionX(9999)
    else
        self.rootItems.upprop1:setPositionX(9999)
        self.rootItems.upprop2:setPositionX(9999)
        self.rootItems.upprop3:setPositionX(9999)
    end

    for i = 1,5 do
        if self.upid[i] then
            self.rootItems["tupo_propnode"..i]:setVisible(true)
        else
            self.rootItems["tupo_propnode"..i]:setVisible(false)
        end    
    end    

end

function lead.setaddnum_gold(self)

    local growconfig = gamedata.config.protagonist_grow or {}

    local grow_atk,grow_def,grow_hp,grow_speed = 0,0,0,0
    local grow_g_atk,grow_g_def,grow_g_hp = 0,0,0
    for i = 2,self.data.level2 do
        if growconfig[tostring(i)] then
            grow_atk = grow_atk+growconfig[tostring(i)].atk+growconfig[tostring(i)].atk_grow
            grow_def = grow_def+growconfig[tostring(i)].def+growconfig[tostring(i)].def_grow
            grow_hp = grow_hp+growconfig[tostring(i)].hp+growconfig[tostring(i)].hp_grow
            grow_speed = grow_speed+growconfig[tostring(i)].speed_grow
            --
            if growconfig[tostring(i)].gold_will_attribute and growconfig[tostring(i)].gold_will_attribute ~= "" then
                local g_att = ui.getSTRandNUMs(growconfig[tostring(i)].gold_will_attribute)
                if g_att and next(g_att) then
                    for k,v in pairs(g_att) do
                        if v.str == "atk" then
                            grow_atk = grow_atk + v.num
                        elseif v.str == "def" then 
                            grow_def = grow_def + v.num
                        elseif v.str == "hp" then 
                            grow_hp = grow_hp + v.num
                        elseif v.str == "speed" then 
                            grow_speed = grow_speed + v.num
                        elseif v.str == "g_atk" then 
                            grow_g_atk = grow_g_atk + v.num
                        elseif v.str == "g_def" then 
                            grow_g_def = grow_g_def + v.num
                        elseif v.str == "g_hp" then 
                            grow_g_hp = grow_g_hp + v.num                                                      
                        end
                    end    
                end
            end    
        end
    end

    ui.setLabelString(self.rootItems.tupo_atk,grow_atk,14)
    ui.setLabelString(self.rootItems.tupo_def,grow_def,14)
    ui.setLabelString(self.rootItems.tupo_hp,grow_hp,14)
    ui.setLabelString(self.rootItems.tupo_speed,grow_speed,14)
    ui.setLabelString(self.rootItems.tupo_g_atk,grow_g_atk,14)
    ui.setLabelString(self.rootItems.tupo_g_def,grow_g_def,14)
    ui.setLabelString(self.rootItems.tupo_g_hp,grow_g_hp,14)

    --
    if self.data.general.scope and self.data.general.scope > 0 then
        setSpriteFrameByName(self.rootItems.goldtype_now,"tujin_"..self.scopetype[self.data.general.scope])
    else
        setSpriteFrameByName(self.rootItems.goldtype_now,"alpha")
    end    
    --    

    self.rootItems.newskillnode:setVisible(false)

    if growconfig[tostring(self.data.level2+1)] then 
        local next_grow_atk,next_grow_def,next_grow_hp,next_grow_speed = 0,0,0,0
        local next_grow_g_atk,next_grow_g_def,next_grow_g_hp = 0,0,0
        --
        next_grow_atk = grow_atk+growconfig[tostring(self.data.level2+1)].atk+growconfig[tostring(self.data.level2+1)].atk_grow
        next_grow_def = grow_def+growconfig[tostring(self.data.level2+1)].def+growconfig[tostring(self.data.level2+1)].def_grow
        next_grow_hp = grow_hp+growconfig[tostring(self.data.level2+1)].hp+growconfig[tostring(self.data.level2+1)].hp_grow
        next_grow_speed = grow_speed+growconfig[tostring(self.data.level2+1)].speed_grow
        next_grow_g_atk = grow_g_atk
        next_grow_g_def = grow_g_def
        next_grow_g_hp = grow_g_hp
        --
        if growconfig[tostring(self.data.level2+1)].gold_will_attribute and growconfig[tostring(self.data.level2+1)].gold_will_attribute ~= "" then
            local n_g_att = ui.getSTRandNUMs(growconfig[tostring(self.data.level2+1)].gold_will_attribute)
            if n_g_att and next(n_g_att) then
                for k,v in pairs(n_g_att) do
                    if v.str == "atk" then
                        next_grow_atk = next_grow_atk + v.num
                    elseif v.str == "def" then 
                        next_grow_def = next_grow_def + v.num
                    elseif v.str == "hp" then 
                        next_grow_hp = next_grow_hp + v.num
                    elseif v.str == "speed" then 
                        next_grow_speed = next_grow_speed + v.num
                    elseif v.str == "g_atk" then 
                        next_grow_g_atk = next_grow_g_atk + v.num
                    elseif v.str == "g_def" then 
                        next_grow_g_def = next_grow_g_def + v.num
                    elseif v.str == "g_hp" then 
                        next_grow_g_hp = next_grow_g_hp + v.num                                                      
                    end
                end    
            end
        end   
        --
        ui.setLabelString(self.rootItems.tupo_next_atk,next_grow_atk,23)
        ui.setLabelString(self.rootItems.tupo_next_def,next_grow_def,23)
        ui.setLabelString(self.rootItems.tupo_next_hp,next_grow_hp,23)
        ui.setLabelString(self.rootItems.tupo_next_speed,next_grow_speed,23)
        ui.setLabelString(self.rootItems.tupo_next_g_atk,next_grow_g_atk,23)
        ui.setLabelString(self.rootItems.tupo_next_g_def,next_grow_g_def,23)
        ui.setLabelString(self.rootItems.tupo_next_g_hp,next_grow_g_hp,23) 
        --
        --skill
        setSpriteFrameByName(self.rootItems.goldtype_next,"alpha")
        --
        self.newgoldskill = {}
        if (self.data.general.level2+1) > (gamedata.config.global_kv.passive_breakthrough_limit and tonumber(gamedata.config.global_kv.passive_breakthrough_limit.value) or 23) then
            --
            self.rootItems.goldtypeselectNode:setVisible(true)
            --
            local goldlv = (self.data.general.level2+1)-(gamedata.config.global_kv.passive_breakthrough_limit and tonumber(gamedata.config.global_kv.passive_breakthrough_limit.value) or 23)
            local skilltmp = {}
            if growconfig[tostring(self.data.level2+1)].gold_will_skills and growconfig[tostring(self.data.level2+1)].gold_will_skills ~= "" then
                skilltmp = ui.getIDandNUMs(growconfig[tostring(self.data.level2+1)].gold_will_skills)
            end
            for k,v in pairs(skilltmp) do
                table.insert(self.newgoldskill,{goldtype = v.cid, breakskillid = v.num})
            end
            --
            if self.tupo_selectscope > 0 then
            else    
                self.tupo_selectscope = self.newgoldskill[1].goldtype
            end
            --
            for i = 1,3 do
                self.rootItems["goldtypeselectBtn"..i]:setSwallowsTouch(true)
                self.rootItems["goldtypeselectBtn"..i]:setTouchPriority(-102)
                --
                if self.newgoldskill[i] then
                    self.rootItems["goldtypeselectNode"..i]:setVisible(true)
                    setSpriteFrameByName(self.rootItems["goldtypeselect"..i],"tujin_"..self.scopetype[self.newgoldskill[i].goldtype])
                    self.rootItems["goldtypeselectBtn"..i]:addHandleOfControlEvent(function()
                        self.tupo_selectscope = self.newgoldskill[i].goldtype
                        self:setgoldskill(goldlv)
                    end, CCControlEventTouchUpInside)
                else               
                    self.rootItems["goldtypeselectNode"..i]:setVisible(false)
                    self.rootItems["goldtypeselectBtn"..i]:addHandleOfControlEvent(function()
                        --
                    end, CCControlEventTouchUpInside)    
                end
            end 
            -- 
            self:setgoldskill(goldlv)  
        end

        --
        local needsoaring = gamedata.config.protagonist_grow[tostring(self.data.general.level2+1)].soaring_limit or 0
        if needsoaring > 0 then
            ui.setLabelString(self.rootItems.tupo_condition,"需要飞升等级: "..gamedata.config.passive_soaring[tostring(needsoaring)].name,(self.data.general.level8+0<needsoaring+0) and 24 or 22)
        else
            ui.setLabelString(self.rootItems.tupo_condition,"",22)
        end
 
        local needgamestar = gamedata.config.protagonist_grow[tostring(self.data.general.level2+1)].game_limit or 0
        if needgamestar > 0 then
            ui.setLabelString(self.rootItems.tupo_condition2,"需要游戏厅关卡等级: "..needgamestar,(self.gamestar+0<needgamestar+0) and 24 or 22)
        else
            ui.setLabelString(self.rootItems.tupo_condition2,"",22)
        end
    end

end

function lead.setgoldskill(self,goldlv)
    for i = 1,3 do
        if self.newgoldskill[i] then
            if self.tupo_selectscope == self.newgoldskill[i].goldtype then
                setSpriteFrameByName(self.rootItems["goldtypeselect"..i],"tujin_"..self.scopetype[self.newgoldskill[i].goldtype].."_h")
                local newskillid = self.newgoldskill[i].breakskillid
                if newskillid and newskillid ~= 0 then
                    self.rootItems.newskillnode:setVisible(true)
                    ui.setLabelString(self.rootItems.newskillname,"进阶后解锁: "..gamedata.config.breakskill[tostring(newskillid)].name,48)
                    ui.setLabelString(self.rootItems.newskilldes,gamedata.config.breakskill[tostring(newskillid)].desc,14)
                end
            else
                setSpriteFrameByName(self.rootItems["goldtypeselect"..i],"tujin_"..self.scopetype[self.newgoldskill[i].goldtype])
            end    
        end
    end
    --
    if goldlv and goldlv > 0 then
        local scopetmp = (self.data.general.g_score1 or 0)*100 + (self.data.general.g_score2 or 0)*10 + (self.data.general.g_score3 or 0)
        if goldlv == 1 then
            scopetmp = scopetmp + self.tupo_selectscope*100
        elseif goldlv == 2 then  
            scopetmp = scopetmp + self.tupo_selectscope*10
        elseif goldlv == 3 then 
            scopetmp = scopetmp + self.tupo_selectscope
        end 
        --
        if gamedata.config.jinjiangkezhiguanxi and gamedata.config.jinjiangkezhiguanxi[tostring(scopetmp)] and gamedata.config.jinjiangkezhiguanxi[tostring(scopetmp)].camp then
            setSpriteFrameByName(self.rootItems.goldtype_next,"tujin_"..self.scopetype[gamedata.config.jinjiangkezhiguanxi[tostring(scopetmp)].camp])
        end
    end
    --

end    

function lead.setgamestar(self,data)

    self.gamestar = data and data._cellIndex or 0

    if gamedata.config.protagonist_grow[tostring(self.data.level2+1)] then 
        local needgamestar = gamedata.config.protagonist_grow[tostring(self.data.general.level2+1)].game_limit or 0
        if needgamestar > 0 then
            ui.setLabelString(self.rootItems.tupo_condition2,"需要游戏厅关卡等级: "..needgamestar,(self.gamestar+0<needgamestar+0) and 24 or 22)
        else
            ui.setLabelString(self.rootItems.tupo_condition2,"",22)
        end    
    end

end

function lead.refreshFunc(self)
    print("refreshFunc")
    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    UIRequest({type = 1054, param = "update"})
end

return lead  v�  