
--进阶预览弹窗

local devilpreview = {
    data = {},
    rootNode = nil,
    rootItems = nil,
    index = 0,

    attrStatus = "fan",

    scopetype = {
        [1] = "tian",
        [2] = "di",
        [3] = "ren",
    },
}

function devilpreview.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("devil/devil_yulan", nil, true, "devil_yulan")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function devilpreview.reload(self,data,callback)
    self.callback = callback

    local growconfig = gamedata.config.protagonist_grow or {}

    data.protagonist.general.level2 =  data.protagonist.level2
    self.data = data or {}
    self.data.protagonistpreveiw[tostring(data.protagonist.level2)] = data.protagonist.general

    printT(self.data)
    self.index =  self.data.protagonist.level2 or 0
    --关闭按钮
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("devilpreview")
    end,CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    self.rootItems.changeButton:setVisible(GameScene:checkopenlevelbyId(449,true))
    self.rootItems.attrChange:addHandleOfControlEvent(function()
        if self.attrStatus == "fan" then
            self.attrStatus = "xian"
        else
            self.attrStatus = "fan"
        end
        self:setAttr_info()
    end, CCControlEventTouchUpInside)
    self.rootItems.attrChange:setSwallowsTouch(true)
    self.rootItems.attrChange:setTouchPriority(self.touchPriority )

    --向左滑动按钮
    self.rootItems.advanceleft:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        local index = self.index
        while index > self.data.protagonist.level2 do
            index = index-1
            if growconfig[tostring(index)].display == 1 then
                break
            end
        end
        self.index = index
        self:setBasenature()
    end,CCControlEventTouchUpInside)
    self.rootItems.advanceleft:setSwallowsTouch(true)
    self.rootItems.advanceleft:setTouchPriority(self.touchPriority)

    --向右滑动按钮
    self.rootItems.advanceright:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        local index = self.index
        while self.data.protagonistpreveiw[tostring(index+1)] do
            index = index+1
            if growconfig[tostring(index)].display == 1 then
                self.index = index
                self:setBasenature()
                break
            end
        end
    end,CCControlEventTouchUpInside)
    self.rootItems.advanceright:setSwallowsTouch(true)
    self.rootItems.advanceright:setTouchPriority(self.touchPriority)


    --玩家等级
    self.rootItems.lvnum:setString(data.protagonist.level1 or 1)


    --设置弹窗的属性
    self:setBasenature()

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
            local index = self.index
            while self.data.protagonistpreveiw[tostring(index+1)] do
                index = index+1
                if growconfig[tostring(index)].display == 1 then
                    self.index = index
                    self:setBasenature()
                    break
                end
            end
        elseif self.touchX-x > 20 then
            gameTouch:clickprofbytime(1)
            local index = self.index
            while index > self.data.protagonist.level2 do
                index = index-1
                if growconfig[tostring(index)].display == 1 then
                    break
                end
            end
            self.index = index
            self:setBasenature()
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
    if self.rootItems.touchLayer then
        self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority, false)
        self.rootItems.touchLayer:setTouchPriority(self.touchPriority)
        self.rootItems.touchLayer:setTouchEnabled(true)
    end
end

--设置凡仙
function devilpreview.setAttr_info(self)
    

    if self.attrStatus == "fan" then
        self.rootItems.fan:setVisible(true)
        self.rootItems.xian:setVisible(false)
        --
        --攻击属性的修改
        self.rootItems.attr_atk:setString("攻击")
        self.rootItems.atknum1:setString(self.data.protagonistpreveiw[tostring(self.index)].atk or "")
        self.rootItems.atknum2:setString("")
        --血量属性的修改
        self.rootItems.attr_hp:setString("生命")
        self.rootItems.hpnum1:setString(self.data.protagonistpreveiw[tostring(self.index)].hp or "")
        self.rootItems.hpnum2:setString("")
        --防御属性的修改
        self.rootItems.attr_def:setString("防御")
        self.rootItems.defnum1:setString(self.data.protagonistpreveiw[tostring(self.index)].defense or "")
        self.rootItems.defnum2:setString("")
        --速度属性的修改
        self.rootItems.attr_speed:setString("速度")
        self.rootItems.speednum1:setString(self.data.protagonistpreveiw[tostring(self.index)].speed or "")
        self.rootItems.speednum2:setString("")
    elseif self.attrStatus == "xian" then
        self.rootItems.fan:setVisible(false)
        self.rootItems.xian:setVisible(true)
        --
        --攻击属性的修改
        self.rootItems.attr_atk:setString("仙攻")
        self.rootItems.atknum1:setString(self.data.protagonistpreveiw[tostring(self.index)].g_atk or "")
        self.rootItems.atknum2:setString("")
        --血量属性的修改
        self.rootItems.attr_hp:setString("仙命")
        self.rootItems.hpnum1:setString(self.data.protagonistpreveiw[tostring(self.index)].g_hp or "")
        self.rootItems.hpnum2:setString("")
        --防御属性的修改
        self.rootItems.attr_def:setString("仙防")
        self.rootItems.defnum1:setString(self.data.protagonistpreveiw[tostring(self.index)].g_defense or "")
        self.rootItems.defnum2:setString("")
        --速度属性的修改
        self.rootItems.attr_speed:setString("速度")
        self.rootItems.speednum1:setString(self.data.protagonistpreveiw[tostring(self.index)].speed or "")
        self.rootItems.speednum2:setString("")
    end
end    

--设置基本属性
function devilpreview.setBasenature(self)

    if self.index <= self.data.protagonist.level2 then
        self.rootItems.advanceleft:setVisible(false)
    else
        self.rootItems.advanceleft:setVisible(true)
    end
    if self.data.protagonistpreveiw[tostring(self.index+1)] then
        self.rootItems.advanceright:setVisible(true)
    else
        self.rootItems.advanceright:setVisible(false)
    end

    --玩家名字
    self.rootItems.playername:setString(ui.leadName(self.index))
    if self.data.protagonistpreveiw[tostring(self.index)].quality >= 7 then
        ui.setLabelString(self.rootItems.playername,nil, 213)
    else
        ui.setLabelString(self.rootItems.playername,nil, self.data.protagonistpreveiw[tostring(self.index)].quality~=0 and 2*self.data.protagonistpreveiw[tostring(self.index)].quality-1 or 1)
    end

    self:setAttr_info()

    --人物形象
    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.data.protagonistpreveiw[tostring(self.index)].cid)].animationid)].name
    local wing = {level = GameScene.protagonist.w_l, color = GameScene.protagonist.w_c }
    local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
          Gneral1:setAnimation("stand",true,0)
          Gneral1:setScale(1.3)
          Gneral1:setPosition(0,0)
    self.rootItems.generalNode:addChild(Gneral1.root or Gneral1)

    self.rootItems["levelEffectNode"]:removeAllChildrenWithCleanup(true)
    --local Node11,Item11 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(math.mod(self.data.protagonistpreveiw[tostring(self.index)].level2,5)+1), nil, true, "jie")
    --Node11:setScale(0.8)
    --self.rootItems.levelEffectNode:addChild(Node11)
    
    --
    self.rootItems.container:removeAllChildrenWithCleanup(true)
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.yuanNode, self.yuanItems = CCBReaderLoad("devil/cell_yulan", nil, true, "yuan")
    self.rootItems.container:addChild(self.yuanNode)
    --
    --skill
    self.yuanItems["zdskillName1"]:setString(gamedata.config.skill[tostring(self.data.protagonistpreveiw[tostring(self.index)].skill.cid)].name or "")
    self.yuanItems["zdskillDesc1"]:setString(gamedata.config.skill[tostring(self.data.protagonistpreveiw[tostring(self.index)].skill.cid)]["skill-desc"] or "")
    if gamedata.config.skill[tostring(self.data.protagonistpreveiw[tostring(self.index)].skill.cid)].quality >= 7 then
        ui.setLabelString(self.yuanItems["zdskillName1"],nil, 213)
    else
        ui.setLabelString(self.yuanItems["zdskillName1"],nil, gamedata.config.skill[tostring(self.data.protagonistpreveiw[tostring(self.index)].skill.cid)].quality~=0 and 2*gamedata.config.skill[tostring(self.data.protagonistpreveiw[tostring(self.index)].skill.cid)].quality-1 or 1)
    end
    ui.setNewIcon(self.yuanItems,{cid = self.data.protagonistpreveiw[tostring(self.index)].skill.cid},0)
    if gamedata.config.general[tostring(self.data.protagonistpreveiw[tostring(self.index)].cid)].combskillid and gamedata.config.general[tostring(self.data.protagonistpreveiw[tostring(self.index)].cid)].combskillid > 0 then
        self.yuanItems["zdskillNode2"]:setVisible(true)
        self.yuanItems["zdskillName2"]:setString(gamedata.config.combskill[tostring(self.data.protagonistpreveiw[tostring(self.index)].combskill.cid)].name or "")
        self.yuanItems["zdskillDesc2"]:setString(gamedata.config.combskill[tostring(self.data.protagonistpreveiw[tostring(self.index)].combskill.cid)]["skill-desc"] or "")
        if gamedata.config.combskill[tostring(self.data.protagonistpreveiw[tostring(self.index)].combskill.cid)].quality >= 7 then
            ui.setLabelString(self.yuanItems["zdskillName2"],nil, 213)
        else
            ui.setLabelString(self.yuanItems["zdskillName2"],nil, gamedata.config.combskill[tostring(self.data.protagonistpreveiw[tostring(self.index)].combskill.cid)].quality~=0 and 2*gamedata.config.combskill[tostring(self.data.protagonistpreveiw[tostring(self.index)].combskill.cid)].quality-1 or 1)
        end
        ui.setNewIcon(self.yuanItems,{cid = self.data.protagonistpreveiw[tostring(self.index)].combskill.cid},1)
    else
        self.yuanItems["zdskillNode2"]:setVisible(false)
    end
    --
    local passive_skill = {}
    for k,v in pairs(gamedata.config.protagonist_grow) do
        if v.skill_ext and v.skill_ext > 0 then
            table.insert(passive_skill,{level = v.level, skill_ext = v.skill_ext})
        end
    end
    local skillconfig = gamedata.config.breakskill
    local sortfunc = function (a,b)
        return a["level"] < b["level"]
    end
    table.sort(passive_skill,sortfunc)
    for i = 1,7 do
       if passive_skill[i] then
           self.yuanItems["bdskillDesc"..i]:setString(skillconfig[tostring(passive_skill[i].skill_ext)].desc)
           if self.data.protagonistpreveiw[tostring(self.index)].level2+0 >= passive_skill[i].level then
               self.yuanItems["skill_yes"..i]:setVisible(true)
               self.yuanItems["skill_no"..i]:setVisible(false)
               self.yuanItems["bdskillDesc"..i]:setColor(ccc3(255,255,255))
           else
               self.yuanItems["skill_yes"..i]:setVisible(false)
               self.yuanItems["skill_no"..i]:setVisible(true)
               self.yuanItems["bdskillDesc"..i]:setColor(ccc3(169,169,169))
           end
       else
           self.yuanItems["bdskillDesc"..i]:setString("")
           self.yuanItems["skill_yes"..i]:setVisible(false)
           self.yuanItems["skill_no"..i]:setVisible(true)
       end
    end
    --
    for i = 1,3 do
        for j = 1,3 do
            if gamedata.config.general[tostring(self.data.protagonistpreveiw[tostring(self.index)].cid)]["gold"..i.."_will_skills_"..j] and gamedata.config.general[tostring(self.data.protagonistpreveiw[tostring(self.index)].cid)]["gold"..i.."_will_skills_"..j] > 0 then
                self.yuanItems["G"..i..j]:setVisible(true)
                self.yuanItems["bdskillDescG"..i..j]:setString(skillconfig[tostring(gamedata.config.general[tostring(self.data.protagonistpreveiw[tostring(self.index)].cid)]["gold"..i.."_will_skills_"..j])].desc)
                setSpriteFrameByName(self.yuanItems["scopeG"..i..j],"tujin_"..self.scopetype[j])
                if self.data.protagonistpreveiw[tostring(self.index)].level2+0 >= 23+i then
                   self.yuanItems["bdskillDescG"..i..j]:setColor(ccc3(255,255,255))
                else
                   self.yuanItems["bdskillDescG"..i..j]:setColor(ccc3(169,169,169))
                end
                if self.data.protagonist.general["g_score"..i] and self.data.protagonist.general["g_score"..i] == j then
                    self.yuanItems["n_selectG"..i..j]:setVisible(false)
                    self.yuanItems["y_selectG"..i..j]:setVisible(true)
                else
                    self.yuanItems["n_selectG"..i..j]:setVisible(true)
                    self.yuanItems["y_selectG"..i..j]:setVisible(false)
                end
            else
                self.yuanItems["G"..i..j]:setVisible(false)
            end
        end
    end    
    --
    self.yuanItems.yuanNode:removeAllChildrenWithCleanup(true)
    local generalConfig = gamedata.config.general[tostring(self.data.protagonistpreveiw[tostring(self.index)].cid)]
    local shownum = 0
    for i = 1,50 do
        if shownum >= 50 then break end
        if generalConfig["cond"..i.."ids"] and generalConfig["cond"..i.."ids"]~="" then
            local ids = ui.Split(generalConfig["cond"..i.."ids"],";") or {}
            if ids[1] and ids[1]~="" then
                local yNode, yItems = CCBReaderLoad("devil/cell_yulan_yuan", nil, true, "yuan")
                yNode:setPosition(0,0-shownum*150)
                self.yuanItems.yuanNode:addChild(yNode)
                yItems.yuan_name:setString(generalConfig["cond"..i.."name"]..": ")
                yItems.yuan_desc:setString(generalConfig["cond"..i.."desc"])
                ui.setNewIcon(yItems,{cid = ids[1]},0)
                ui.setLabelString(yItems.yuan_name,nil, ui.IDconfig(ids[1]).quality~=0 and 2*ui.IDconfig(ids[1]).quality-1 or 1)
                shownum = shownum+1
                if self.index == self.data.protagonist.level2 and self.data.protagonist.relation and self.data.protagonist.relation[tostring(i)] and self.data.protagonist.relation[tostring(i)].activate >= 2 then
                    yItems.yuan_yes:setVisible(true)
                    yItems.yuan_no:setVisible(false)
                    yItems.yuan_desc:setColor(ccc3(255,255,255))
                else
                    yItems.yuan_yes:setVisible(false)
                    yItems.yuan_no:setVisible(true)
                    yItems.yuan_desc:setColor(ccc3(169,169,169))
                end
            end
        end
    end
    self.yuanItems.yuanbg:setContentSize(CCSize(900,20+shownum*150))
    self.rootItems.container:setContentSize(CCSize(900,1905+shownum*150))
    self.yuanNode:setPosition(0,1905+shownum*150)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,880-1905-shownum*150),0)
end

function devilpreview.close(self)

    self.attrStatus = "fan"
    self.data = {}
    self.index = 0
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end



return devilpreview


  ^A  