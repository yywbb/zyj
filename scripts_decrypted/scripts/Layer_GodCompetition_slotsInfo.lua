--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/3/31
-- Time: 上午11:43
-- To change this template use File | Settings | File Templates.
--

local godCompetitionSlotsInfo = {

    resource = nil,
    titleCellSize = {x=180,y=180},

    rootNode = nil,
    rootItems = nil,

    palyerdata = {},

    slotgems = {},
    gems = {},
    slotdata = nil, --武将信息 
    onlineslotdata = nil, --武将信息 

    cheerdata = nil,
    cheerPage = {},
    slotgemsPage = {},
    generalSkeleton = {},

    generalListTableView = nil,
    xiaohuobanListTableView = nil,

    statusconfig = {"equip","soul","stone"},
    status = "equip",

    touchX = nil,
    touchY = nil,
    pagemoved = false,
    contentoffsetx = 0,
    isContentScroll = false,
    sid = 1,
    maxsid = 0,
    select_f = 0,
    touchpriority = -135,


    orderconfig = {
        [1] = {key = "horse", win = "equip_info",dir = "equip"},
        [2] = {key = "weapon", win = "equip_info",dir = "equip"},
        [3] = {key = "treasure", win = "equip_info",dir = "equip"},
        [4] = {key = "head", win = "equip_info",dir = "equip"},
        [5] = {key = "skill", win = "skill_info",dir = "general"},
        [6] = {key = "armor", win = "equip_info",dir = "equip"},
        [7] = {key = "combskill", win = "skill_info",dir = "general"},
        [8] = {key = "accessory", win = "equip_info",dir = "equip"},
    },

    addedGroup = {},
    addedDataNode = {},
    dataStatusConfig={
        equip = "general_godcompetition",
        soul = "general_godcompetition",
        stone = "stone",
    },
    datastatus = "general_godcompetition",
    exclusiveArtifactData = {},
    exclusiveArtifactQilingData = {},


    pageconfig = {"1","2","3"},
    pagename = {gameConfig.strings:string_common("godCompetition",1),gameConfig.strings:string_common("godCompetition",2),gameConfig.strings:string_common("godCompetition",3)},
    selectpage = "1",


    -- required int32 id = 1;   // 阵容ID 1～3
    -- repeated Slot_General slots = 2;
    -- repeated Cheer_General cheers = 3;
    -- optional int32 pet = 4;
    -- return { type = 8252,slots = t.slots, cheers = t.cheers, slotgems = t.slotgems, gems = t.gems, protagonist = t.protagonist}

    godCompetionData = {},
    buzhen_mach = {},
    data = {},
    buffdata = {},--阵容buff
    godcompetition_slotIndex = 0,
}

function godCompetitionSlotsInfo.shiftPage(self,type)
    self.selectpage = type
    print("shiftPage",self.selectpage)
    self.sid = 1
    self:checkrelation(true)
    self:reload()
end

function godCompetitionSlotsInfo.setStatus(self,status)
    self.status = status
end

--装备/命格/神石 状态切换
function godCompetitionSlotsInfo.shiftStatus(self,status)
    gameTouch:clickprofbytime(0.5)
    gamedata.music:PlayOptSound("zbqh")

    if self.status and self.status ~= status and self.addedGroup[self.status] then
        local status_ = self.status
        self.addedGroup[status_].animationManager:setAnimationCompletedCallback(function()
            self.addedGroup[status_].ccb:setVisible(false)
        end)
        self.addedGroup[status_].animationManager:runAnimationsForSequenceNamed("hide")
    end

    self.status = status

    if not self.addedGroup[self.status] then
        self.addedGroup[self.status] = {}
        self.addedGroup[self.status].ccb,self.addedGroup[self.status].items = CCBReaderLoad("slotsInfo/group_"..self.status, nil, true, self.status)
        self.addedGroup[self.status].animationManager = getAnimationManager(self.addedGroup[self.status].items)
        self.rootItems.groupnode:addChild(self.addedGroup[self.status].ccb)
    else
        self.addedGroup[self.status].ccb:setVisible(true)
    end
    self:reloadGroup()
    self.addedGroup[self.status].animationManager:runAnimationsForSequenceNamed("show")


    local needanimation = (not next(self.addedDataNode)) or (self.datastatus ~= self.dataStatusConfig[self.status])
    if self.datastatus and self.datastatus and self.addedDataNode[self.datastatus] and needanimation then
        self.addedDataNode[self.datastatus].animationManager:runAnimationsForSequenceNamed("hide")
    end
    self.datastatus = self.dataStatusConfig[self.status]

    if not self.addedDataNode[self.datastatus] then
        self.addedDataNode[self.datastatus] = {}

        if self.datastatus == "stone" then
            self.addedDataNode[self.datastatus].ccb,self.addedDataNode[self.datastatus].items = CCBReaderLoad("slotsInfo/data_stone_other", nil, true, "data_stone_other")
        else
            self.addedDataNode[self.datastatus].ccb,self.addedDataNode[self.datastatus].items = CCBReaderLoad("slotsInfo/data_"..self.datastatus, nil, true, self.datastatus)
        end
        self.addedDataNode[self.datastatus].animationManager = getAnimationManager(self.addedDataNode[self.datastatus].items)
        self.rootItems.datanode:addChild(self.addedDataNode[self.datastatus].ccb)
    end
    self:reloadBottomData()
    if needanimation then
        self.addedDataNode[self.datastatus].animationManager:runAnimationsForSequenceNamed("show")
    end

    self.rootItems.statusselect:setPosition(self.rootItems["statusnode_"..self.status]:getPosition())
end

function godCompetitionSlotsInfo.init(self,parent,toppos,data,index)
    self.rootNode,self.rootItems = CCBReaderLoad("fengshensai/fengshensai_generalinfo", nil, true, "fengshensai_generalinfo")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    UIRequest({type = 825200})

    local param =  GameScene.roleinfo
    --返回
    self.rootItems.closeButton:setTouchPriority(self.touchpriority)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("godCompetitionSlotsDetail","up",{buzhendata = self.data, buffdata= self.buffdata})
    end, CCControlEventTouchUpInside)
    
    --布阵
    if self.rootItems.buzhenSprite then
        setSpriteFrameByName(self.rootItems.buzhenSprite,"lingzhen")
    end
    self.rootItems.buzhen:setTouchPriority(-101)
    self.rootItems.buzhen:setSwallowsTouch(true)
    self.rootItems.buzhen:addHandleOfControlEvent(function()
        GameScene:shiftLayer("godCompetitiondeployment","up",{team_id = self.selectpage, slotdata = self.godCompetionData[tostring(self.selectpage)].slot_General,buffdata= self.buffdata})
    end, CCControlEventTouchUpInside)


    self.show = true
    self.sid = 1 --默认选中第一个位置

    if index and index ==2 then
        self.touchpriority = -301
    end

    self.equipconfig = gameConfig.equipconfig

    self.topposy = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.bgnode:setPositionY((GameScene.topposY-1620)*0.6 - 60)

    self.rootItems.datanode:setPositionY((GameScene.topposY-1620)*0.25)
    self.rootItems.midnode:setPositionY((GameScene.topposY-1620)*0.6+908)

    self.rootItems.generalscroll = tolua.cast(self.rootItems.generalscroll, "CCScrollView")
    self.rootItems.generalscroll:setTouchEnabled(false)

   
    self.awakenConfig = gamedata.config.general_awaken
    if param and param.sid then
        self.sid = param.sid
    end

    for k,v in pairs(self.statusconfig) do
        self.rootItems["hint_"..v]:setVisible(false)
        -- ui.setLabelString(self.rootItems["statustext_"..v],nil,18)
        self.rootItems["status_"..v]:setSwallowsTouch(true)
        self.rootItems["status_"..v]:setTouchPriority(self.touchpriority)
        self.rootItems["status_"..v]:addHandleOfControlEvent(function()
            
            if self.buzhen_mach[self.selectpage][tostring(self.sid)] == 0 then --底部按钮状态切换
                runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",2)})
                return
            end

            if self.status ~= v then
                self:shiftStatus(v)
            end
        end,CCControlEventTouchUpInside)
    end


    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchX = x
            self.touchY = y
            self.pagemoved = false
            self.contentoffsetx = self.rootItems.generalcontainer:getPositionX()
            self.pagecontentoffsetx = self.rootItems.pagenode:getPositionX()
            return true
        end
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 10 then
            self.isContentScroll = true
        end

        if math.abs(x - self.touchX) > 20 and math.abs(y - self.touchY)/math.abs(x - self.touchX) <0.3 then
            self.pagemoved = true
            if self.sid < self.maxsid then
                local offsetX = self.contentoffsetx + (x - self.touchX)
                self.rootItems.generalcontainer:setPositionX(offsetX)
            elseif self.sid == self.maxsid then
                if x - self.touchX >0 then
                    local offsetX = self.contentoffsetx + (x - self.touchX)
                    self.rootItems.generalcontainer:setPositionX(offsetX)
                else
                    local offsetX = self.pagecontentoffsetx + (x - self.touchX)
                    self.rootItems.pagenode:setPositionX(offsetX)
                end
            else
                local offsetX = self.pagecontentoffsetx + (x - self.touchX)
                self.rootItems.pagenode:setPositionX(offsetX)
            end
        end
    end

    local function ccTouchEnded(x, y)
        local moveX = self.touchX -x
        print(moveX)

        if moveX > 20 and self.pagemoved then
            if self.sid+1 <=self.maxsid+3 then
                local sid = self.sid+1
                if sid == 8 then
                    sid = 9
                end    
                self:setPage(sid,true)
            else
                self:setPage(self.sid)
            end
        elseif moveX < -20 and self.pagemoved then
            if self.sid-1 >0 then
                local sid = self.sid-1
                if sid == 8 then
                    sid = 7
                end    
                self:setPage(sid,true)
            else
                self:setPage(self.sid)
            end
        else
            --self:setPage(self.presentPage)
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchpriority-1, false)
    self.rootItems.touchLayer:setTouchPriority(self.touchpriority-1)
    self.rootItems.touchLayer:setTouchEnabled(true)

    if param then
        self.palyerdata = param
    end

    self.rootItems["artifactBtn"]:setSwallowsTouch(true)
    self.rootItems["artifactBtn"]:setTouchPriority(self.touchpriority)
    self.rootItems["artifactBtn"]:addHandleOfControlEvent(function()

        local data = self.onlineslotdata[tostring(self.buzhen_mach[tostring(self.selectpage)][tostring(self.sid)])]

        if type(data.newartifact) == "table" then --神器
            gameWindows:openWindow("artifactInfoOther",{artifactData = data.newartifact,isOther = true},nil)
        end
    end,CCControlEventTouchUpInside)

    self.rootItems["zhuanshubutton"]:setSwallowsTouch(true)
    self.rootItems["zhuanshubutton"]:setTouchPriority(self.touchpriority)
    self.rootItems["zhuanshubutton"]:addHandleOfControlEvent(function()
        local data = self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(self.sid)]
        if data and data.general then --专属神器
            gameWindows:openWindow("exclusiveArtifact", {general = data.general,opt = 11})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",2)})
        end
    end,CCControlEventTouchUpInside)

    --上阵新武将
    self.rootItems.generalNodeButton:setTouchPriority(-101)
    self.rootItems.generalNodeButton:addHandleOfControlEvent(function()
        print("generalNodeButton")
        if self.isContentScroll then return end
        if self.buzhen_mach[self.selectpage][tostring(self.sid)] == 0 then --没有武将,没有匹配槽位
            local callback = function(selectedData)
                for k,v in pairs(selectedData) do
                    UIRequest({type=8253,pos = self.sid, iid = v.iid, team_id = self.selectpage, change_type = 1})
                    break
                end
            end
            gameWindows:openWindow("selectlist",{type = "changegeneral_godcompetition",param = self.selectpage, param2="slot"},callback)
        end    
    end, CCControlEventTouchUpInside)

   -- 更换武将
    self.rootItems.status_change:addHandleOfControlEvent(function()
        local callback = function(selectedData)
            for k,v in pairs(selectedData) do
                UIRequest({type=8253,pos = self.sid, iid = v.iid, team_id = self.selectpage, change_type = 1})
                break
            end
        end
        local data =  self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(self.sid)]
        print(data.general.cid,"更换武将的cid")
        gameWindows:openWindow("selectlist",{type = "changegeneral_godcompetition",param = self.selectpage, param2="slot",param3 = data.general.cid },callback)
    end, CCControlEventTouchUpInside)
    self.rootItems.status_change:setSwallowsTouch(true)
    self.rootItems.status_change:setTouchPriority(-103)

    if data and data.buzhendata and data.buzhendata.godCompetionData then
        print("godCompetitionSlotsInfo init  have data")
        self:reload(data.buzhendata)
    else
        UIRequest({type=8252})
    end    

    if data and data.buffdata then
        self.buffdata = data.buffdata
    end    

    if data and data.page then
        self.selectpage = data.page
    end    

end

--命格
function godCompetitionSlotsInfo.reloadSouls(self)
    if not self.addedGroup["soul"] then return end
    local data = self.onlineslotdata[tostring(self.buzhen_mach[tostring(self.selectpage)][tostring(self.sid)])]
    if data then
        for i = 1, 8 do
            if data["s"..i] then
                data["s"..i].has = false
                data["s"..i].notice = false
                ui.setSoulIcon(data["s"..i],self.addedGroup["soul"].items,i-1)
            end    
        end
    end    
end

--加载装备数据
function godCompetitionSlotsInfo.reloadEquip(self)
    if not self.addedGroup["equip"] then return end
    local data = self.onlineslotdata[tostring(self.buzhen_mach[tostring(self.selectpage)][tostring(self.sid)])]
        for k,v in ipairs(self.equipconfig) do
            print(v,"reloadEquip")
            if data and data[v] then
                data[v].has = false
                data[v].notice = false
                ui.setEquipIcon(data[v],self.addedGroup["equip"].items,k-1)
            else
                ui.setEquipIcon(nil,self.addedGroup["equip"].items,k-1)
            end    
        end
end

--技能 普通或者幻化技能
function godCompetitionSlotsInfo.reloadSkill(self)
    if not self.addedGroup["equip"] then return end
    local data = self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(self.sid)]
    -- 设置技能
    if next(data) and data.general then
        if data.general.illusionGeneralCid then
            local configGeneral = gamedata.config.general[tostring(data.general.illusionGeneralCid)]
            local gdata = ui.getConfigGeneralSion(data.general)
            if next(gdata) and configGeneral.fashion_id == 0 then
                if gdata.skillid and gdata.skillid > 0 then
                    data.general.skill.cid = gdata.skillid
                end
                if gdata.special_skill_reveal and gdata.special_skill_reveal > 0 then
                    data.general.skill.cid = gdata.special_skill_reveal
                end
                data.general.skill.quality = data.general.quality
            end
        else
            local configGeneral = gamedata.config.general[tostring(data.general.cid)]
            local gdata = ui.getConfigGeneral(data.general)
            if next(gdata) and configGeneral.fashion_id == 0 then
                if gdata.skillid and gdata.skillid > 0 then
                    data.general.skill.cid = gdata.skillid
                end
                if gdata.special_skill_reveal and gdata.special_skill_reveal > 0 then
                    data.general.skill.cid = gdata.special_skill_reveal
                end
                data.general.skill.quality = data.general.quality
            end
        end

        -- printT(data.general.combskill,"data.general.combskill")
        ui.setSkillIcon(data.general.skill,self.addedGroup["equip"].items)
        ui.setSkillIcon(data.general.combskill,self.addedGroup["equip"].items,1)

        local callback = function(i) 
            if  self.status == "equip" then
                if i == 5  then
                    gameWindows:openWindow("generalInfoSkill",{data = data, sid = 0, pagetype = "skillinfo", skilltype = "skill"})
                elseif i == 7 and data.general.combskill.cid then
                    if data.general.combskill.islead then
                        gameWindows:openWindow("generalInfoSkill",{data = data, sid = 0, islead = 1, pagetype = "skillinfo", skilltype = "leadskill"})
                    else
                        gameWindows:openWindow("generalInfoSkill",{data = data, sid = 0, pagetype = "skillinfo", skilltype = "combskill"})
                    end
                end
            end 
        end

        self.rootItems["skillbutton1"]:setTouchPriority(-101)
        self.rootItems["skillbutton1"]:addHandleOfControlEvent(function()
                callback(5)
        end, CCControlEventTouchUpInside)

        self.rootItems["skillbutton2"]:setTouchPriority(-101)
        self.rootItems["skillbutton2"]:addHandleOfControlEvent(function()
            callback(7)
        end, CCControlEventTouchUpInside)





    else
        ui.setSkillIcon(nil,self.addedGroup["equip"].items)
        ui.setSkillIcon(nil,self.addedGroup["equip"].items,1)
    end
end

--
function godCompetitionSlotsInfo.reloadStone(self)
    if not self.addedGroup["stone"] then return end
    local data = self.onlineslotdata[tostring(self.sid)]
    

    for i = 1, 8 do
        local levels = data["g"..i] or 0
        print("reloadStone",levels)
        ui.setStoneIcon({level=levels},self.addedGroup["stone"].items,i-1)
    end
end

function godCompetitionSlotsInfo.reloadGroup(self)
    if self.status == "equip" then
        self:reloadEquip()--
        self:reloadSkill()   
    elseif self.status == "soul" then
        self:reloadSouls()--
    elseif self.status == "stone" then
        self:reloadStone()
    end
end


--底部得缘分展示
function godCompetitionSlotsInfo.reloadDataGeneral(self)
    if not self.addedDataNode["general_godcompetition"] then return end
    local data = self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(self.sid)]
    local item = self.addedDataNode["general_godcompetition"].items

    if data and next(data) and data.general then
        local configdata = gamedata.config.general[tostring(data.general.cid)] or {}
        item.atk:setString(data.general.g_atk)
        item.hp:setString(data.general.g_hp)
        item.defense:setString(data.general.g_defense)
        item.speed:setString(data.general.speed or 0)

        local relationdata = self.godCompetionData[tostring(self.selectpage)].slot_General.relation[tostring(self.sid)]
        for i = 1, 6 do
            if relationdata and relationdata[tostring(i)] and relationdata[tostring(i)].activate >1 then
                ui.setLabelString(item["yuan"..tostring(i)],configdata["cond"..tostring(i).."name"] or " ",31)
            else
                ui.setLabelString(item["yuan"..tostring(i)],configdata["cond"..tostring(i).."name"] or " ",29)
            end

            item["yuanbtn_"..i]:setTouchPriority(self.touchpriority-2)
            item["yuanbtn_"..i]:setSwallowsTouch(true)
            item["yuanbtn_"..i]:setVisible(true)
            item["yuanbtn_"..i]:addHandleOfControlEvent(function()
                if configdata["cond"..tostring(i).."name"] and configdata["cond"..tostring(i).."name"] ~= "" then 
                    gameWindows:openWindow("fateInfoPop", {cid = data.general.cid, id = i}, nil)
                end
            end,CCControlEventTouchUpInside)
        end
    else
        item.atk:setString(0)
        item.hp:setString(0)
        item.defense:setString(0)
        item.speed:setString(0)
        for i = 1, 6 do
            ui.setLabelString(item["yuan"..tostring(i)]," ",29)

            item["yuanbtn_"..i]:setTouchPriority(self.touchpriority-2)
            item["yuanbtn_"..i]:setSwallowsTouch(true)
            item["yuanbtn_"..i]:setVisible(true)
            item["yuanbtn_"..i]:addHandleOfControlEvent(function()
            end,CCControlEventTouchUpInside)
        end
    end
end

--神石底部属性的计算(命/防/攻/速度)
function godCompetitionSlotsInfo.reloadDataStone(self)
    if not self.addedDataNode["stone"] then return end
    local data = self.onlineslotdata[tostring(self.sid)]
    for i=1,8 do
        local key = gamedata.config.godstone[tostring(i)].attribute
        local number = 0
        if data and data["g"..i] and data["g"..i] >0 then
            number = gamedata.config.godstonestrengthening[tostring(data["g"..i])][key]
            if number < 1 then
                number = (number*100).."%"
            end
        end
        if self.addedDataNode["stone"].items[key] then
            self.addedDataNode["stone"].items[key]:setString("+ "..number)
        end
    end
    self.addedDataNode["stone"].items.fragmentnode:setVisible(false)

end

--底部数据的刷新
function godCompetitionSlotsInfo.reloadBottomData(self)
    if self.datastatus == "general_godcompetition" then
        self:reloadDataGeneral()
    elseif  self.datastatus == "stone" then
        self:reloadDataStone()
    end
end

--顶部武将页面 图标点击切换
function godCompetitionSlotsInfo.setpagedata(self,item,data)

    if next(data) and data.general then
        local configdata = gamedata.config.general[tostring(data.general.illusionGeneralCid or data.general.cid)] or {}
        local expconfigdata = gamedata.config.general_exp[tostring(data.general.level1)] or {}

        local power = tostring(data.general.power or 0)
        local name = tostring(configdata.name or ' ')
        local lv = tostring(data.general.level1 or 1)
        local exp = tostring(data.general.exp or 0)
        local region = tostring(configdata.region or ' ')
        local lv2 =  tostring(data.general.level2 or 0)
        local nextexp = 0
        if configdata.actor and configdata.actor == "lead" then
            nextexp = tostring(expconfigdata["exp"] or 0)
        else
            nextexp = tostring(expconfigdata[tostring(configdata.quality).."exp"] or 0)
        end

        item.lv:setString(lv)
        -- item.exp:setString(exp .. ' / ' .. nextexp)
        item.exp:setString(math.floor(exp/nextexp*100).."%")


        ui.setSpriteTextureRect2(item.jingyantiao,0,0,415 * exp / nextexp, item.jingyantiao:getContentSize().height)

        if data.general.iid == self.protagonist.iid then
            if configdata.quality and configdata.quality >= 7 then
                ui.setLabelString(item.name,ui.leadName(self.protagonist.level2,self.palyerdata.name),213)
            else
                ui.setLabelString(item.name,ui.leadName(self.protagonist.level2,self.palyerdata.name),configdata.quality and 2*configdata.quality-1 or 1)
            end    
        
            item.shenqinode:setVisible(false)
        else
            if configdata.quality and configdata.quality >= 7 then
                ui.setLabelString(item.name,name..(data.general.level2>0 and " +"..data.general.level2 or "")..(data.general.illusionGeneralCid and "(幻化)" or ""), 213)
            else
                ui.setLabelString(item.name,name..(data.general.level2>0 and " +"..data.general.level2 or "")..(data.general.illusionGeneralCid and "(幻化)" or ""), configdata.quality and 2*configdata.quality-1 or 1)
            end   
        
            item.shenqinode:setVisible(configdata.quality>=6 and gameConfig:checkBuildOpen(363))
            if configdata.quality>=6 and gameConfig:checkBuildOpen(363) then
                ui.setShenqiIcon(self.rootItems,data.general)
            end
        end

        if not gameConfig.images[configdata.actor] then
            setSpriteFrameByName(item["type"], gameConfig.images.alpha)
        else
            setSpriteFrameByName(item["type"], gameConfig.images[configdata.actor])
        end
        item["type"]:setPositionX(item.name:getPositionX() - item.name:getContentSize().width/2 - 30)

        if configdata.awaken == 0 or data.general.skilllevel <= 0 then
            item.juexing:setVisible(false)
        else
            item.juexing:setVisible(true)
            setSpriteFrameByName(item.juexing_icon,  self.awakenConfig[tostring(data.general.skilllevel)].icon )
            ui.setLabelString(item.juexing_name, self.awakenConfig[tostring(data.general.skilllevel)].stage,18) 
        end

        self.rootItems.powerTotal:setString("仙战力: "..(data.general.g_power or 0))
    else
        ui.setSpriteTextureRect2(item.jingyantiao,0,0,0,item.jingyantiao:getContentSize().height)
        item.lv:setString(0)
        item.exp:setString("0%")

        ui.setLabelString(item.name," ",1)
        setSpriteFrameByName(item["type"], gameConfig.images.alpha)
        item.shenqinode:setVisible(false)
        item.juexing:setVisible(false)
        self.rootItems.powerTotal:setString("仙战力: 0")
    end
    self:setArtifactShow()
    self:setExclusiveShow()
    if not next(self.addedGroup) or not next(self.addedDataNode) then
        self:shiftStatus(self.status)
    else
        self:reloadGroup()
        self:reloadBottomData()
    end
end


--普通神器展示
function godCompetitionSlotsInfo.setArtifactShow(self)
    
    -- self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(self.sid)]
    local data = self.onlineslotdata[tostring(self.buzhen_mach[tostring(self.selectpage)][tostring(self.sid)])]
    if data and type(data.newartifact) == "table" then
        self.rootItems.artifact:setVisible(true)
        local artifactConfig = gamedata.config.trump[tostring(data.newartifact.cid)]
        
        local totalLevel = 0
        for i = 1,4 do
            if  data.newartifact["jewel"..i] > 0 then
                local config = gamedata.config.trump_gem[tostring(data.newartifact["jewel"..i])]
                totalLevel = totalLevel + config.lv
            end
        end
        local shenqiSkeletonMeta = require"SkeletonShenqi"
        local skeleton = shenqiSkeletonMeta:init(artifactConfig,totalLevel)
        skeleton:setScale(0.5)
        skeleton:setPosition(0,-80)
        skeleton:setAnimation("stand",true,0)
        self.rootItems.artifactSpine:removeAllChildrenWithCleanup(true)
        self.rootItems.artifactSpine:addChild(skeleton.root or skeleton)
    else
        self.rootItems.artifact:setVisible(false)
    end
end

--缘分效果列表
function godCompetitionSlotsInfo.creatxhbdeslist(self,item)
    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(550, 650)
        elseif fn == "cellAtIndex" then

            local cellCCB,items = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, items = CCBReaderLoad("slotsInfo/slot-xhb_des.ccbi", nil, true, "slot-xhb_des")
                celldict[a2] = {cellCCB=cellCCB,items=items }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                items = celldict[a2].items
            end

            local data = self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(a1+1)]
            if data.general then
                local configdata = gamedata.config.general[tostring(data.general.cid)]
                local relationdata = self.godCompetionData[tostring(self.selectpage)].slot_General.relation
                printT(relationdata,"relationdata")
                items.generalname:setString(configdata.name)
                for i = 1, 6 do
                    local name = (configdata["cond"..tostring(i).."name"] and configdata["cond"..tostring(i).."name"] ~= "") and configdata["cond"..tostring(i).."name"].."：" or " "
                    items["name"..tostring(i)]:setString(name)
                    items["des"..tostring(i)]:setString(configdata["cond"..tostring(i).."desc"] or " ")
                    items["name"..tostring(i)]:setColor(ccc3(124,120,109))
                    items["des"..tostring(i)]:setColor(ccc3(124,120,109))

                    if relationdata and relationdata[tostring(a1+1)] and relationdata[tostring(a1+1)][tostring(i)] then
                        printT(relationdata,"relationdata i")
                        if relationdata[tostring(a1+1)][tostring(i)].activate >1  then
                            items["name"..tostring(i)]:setColor(ccc3(115, 66, 25))
                            items["des"..tostring(i)]:setColor(ccc3(115, 66, 25))
                        end
                    end


                end
            else
                for i = 1, 6 do
                    items["name"..tostring(i)]:setString(" ")
                    items["des"..tostring(i)]:setString(" ")
                end
                items.generalname:setString("")
            end


            cellCCB:setPosition(550/2, 49)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = self.maxsid
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.xiaohuobanListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = item.listscroll:getContentSize().width,
        viewheight = item.listscroll:getContentSize().height,
        dire = 1
    })
    item.listscroll:addChild(self.xiaohuobanListTableView)
    self.xiaohuobanListTableView:setTouchPriority(self.touchpriority)
end

--缘分小伙伴头像
function  godCompetitionSlotsInfo.setxhbpagedata(self,item)
    local open = true
    local first = true
    self.tabs = 1
    for i=1,8 do
        printT(self.cheerdata[tostring(i)], "伙伴等级")
        if self.cheerdata[tostring(i)].general then
            if first then
                first = false
                self.allPartnerLv = self.cheerdata[tostring(i)].general.level1
                self.allPartnerBreachLv = self.cheerdata[tostring(i)].general.level2 
            end
            if self.allPartnerLv > self.cheerdata[tostring(i)].general.level1 then
                self.allPartnerLv = self.cheerdata[tostring(i)].general.level1
            end
            if self.allPartnerBreachLv > self.cheerdata[tostring(i)].general.level2 then
                self.allPartnerBreachLv = self.cheerdata[tostring(i)].general.level2
            end

            local generalconfig = gamedata.config.general[tostring(self.cheerdata[tostring(i)].general.cid)]
            item["g_button"..(i==1 and "" or "_"..(i-1))]:setTouchPriority(-101)
            item["g_button"..(i==1 and "" or "_"..(i-1))]:addHandleOfControlEvent(function()
                if self.isContentScroll then return end
                local cheersid = i or 1
                local callback = function(selectedData)
                    for k,v in pairs(selectedData) do
                        UIRequest({type=8253,pos = cheersid, iid = v.iid, team_id = self.selectpage, change_type = 2})
                        break
                    end
                end
                gameWindows:openWindow("selectlist",{type = "changegeneral_godcompetition",param=self.selectpage, param2="cheer" },callback)
            end, CCControlEventTouchUpInside)



        elseif self.cheerdata[tostring(i)].isopen then
            self.allPartnerLv = 0
            self.allPartnerBreachLv = 0

            item["g_button"..(i==1 and "" or "_"..(i-1))]:setTouchPriority(-101)
            item["g_button"..(i==1 and "" or "_"..(i-1))]:addHandleOfControlEvent(function()
                if self.isContentScroll then return end
                local cheersid = i or 1
                local callback = function(selectedData)
                    for k,v in pairs(selectedData) do
                        UIRequest({type=8253,pos = cheersid, iid = v.iid, team_id = self.selectpage, change_type = 2})
                        break
                    end
                end
                gameWindows:openWindow("selectlist",{type = "changegeneral_godcompetition",param=self.selectpage, param2="cheer" },callback)
            end, CCControlEventTouchUpInside)
            open = false
        else
            self.allPartnerLv = 0
            self.allPartnerBreachLv = 0
            open = false
        end

        -- 设置头像
        if self.cheerdata[tostring(i)].general then
            if self.cheerdata[tostring(i)].general.illusionGeneralCid then
                local configGeneral = gamedata.config.general[tostring(self.cheerdata[tostring(i)].general.illusionGeneralCid)]
                local gdata = ui.getConfigGeneralSion(self.cheerdata[tostring(i)].general)
                if next(gdata) and configGeneral.fashion_id == 0 then
                    ui.setSlotGeneralIcon(self.cheerdata[tostring(i)],item,i-1,gdata)
                else
                    ui.setSlotGeneralIcon(self.cheerdata[tostring(i)],item,i-1)
                end
            else
                local configGeneral = gamedata.config.general[tostring(self.cheerdata[tostring(i)].general.cid)]
                local gdata = ui.getConfigGeneral(self.cheerdata[tostring(i)].general)
                if next(gdata) and configGeneral.fashion_id == 0 then
                    ui.setSlotGeneralIcon(self.cheerdata[tostring(i)],item,i-1,gdata)
                else
                    ui.setSlotGeneralIcon(self.cheerdata[tostring(i)],item,i-1)
                end
            end
        else
            ui.setSlotGeneralIcon(self.cheerdata[tostring(i)],item,i-1)
        end
    end
    print("open", open)

    print(item.partnerBtn)
    item.fateNode:setVisible(true)
    item.partnerNode:setVisible(true)
    item.partnerBtn:setTouchPriority(self.touchpriority)
    item.partnerBtn:setSwallowsTouch(true)
    item.partnerBtn:addHandleOfControlEvent(function()
        print("touch")
        if open then
            self:onAnimation(item, true)
        else
            runGamePrompt({msg = "助阵位置全部开启且上满小伙伴可激活"})
        end
    end, CCControlEventTouchUpInside)


    if item.attributeNode:isVisible() then
        self:onCreateXhbAttribute(item)

    else
        self:onPartnerShow(item)

    end

    -- if self.xiaohuobanListTableView then
    --     self.xiaohuobanListTableView:reloadData()
    -- else
    --     self:creatxhbdeslist(item)
    -- end
end

--伙伴缘分/加成 展示
function godCompetitionSlotsInfo.onPartnerShow(self, item)
    if self.tabs == 1 then
        item.xhbTabLab:setString("伙伴缘分效果")
        if self.xiaohuobanListTableView then
            self.xiaohuobanListTableView:reloadData()
        else
            self:creatxhbdeslist(item)
        end            
        item.listscroll:setVisible(true)
        item.attributeNode:setVisible(false)
    else
        self:onCreateXhbAttribute(item)
        item.xhbTabLab:setString("小伙伴加成")
        self.tabs = 0
        item.listscroll:setVisible(false)
        item.attributeNode:setVisible(true)                    
    end    
end
--伙伴 缘分/加成 动画
function godCompetitionSlotsInfo.onAnimation(self, item)
    local _type = nil
    self.tabs = self.tabs + 1
    if self.tabs == 1 then
        _type = 2
    else
        _type = 1
    end
    if _type then
        self.cheerPage.ccb:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.01),CCCallFunc:create(function()
            local animationManager = getAnimationManager(self.cheerPage.item)
            animationManager:setAnimationCompletedCallback(function()
                self:onPartnerShow(item)
            end)
            animationManager:runAnimationsForSequenceNamed(tostring(_type))
        end)))        
    end
end

--伙伴加成
function godCompetitionSlotsInfo.onCreateXhbAttribute(self, item)
    local config = gamedata.config.cheer or {}
    local partnerAttribute1 = {}
    local partnerAttribute2 = {}
    partnerAttribute1[1] = {}
    partnerAttribute2[1] = {}
    partnerAttribute1[2] = {}
    partnerAttribute2[2] = {}

    for k,v in pairs(config["1"]) do
        if v.type_coefficient > self.allPartnerLv then
            if not next(partnerAttribute1[2]) or v.type_coefficient < partnerAttribute1[2].type_coefficient then
                partnerAttribute1[2] = v 
            end  
        else
            if not next(partnerAttribute1[1]) or v.type_coefficient > partnerAttribute1[1].type_coefficient then
               partnerAttribute1[1] = v 
            end  
        end
    end

    for k,v in pairs(config["2"]) do
        if v.type_coefficient > self.allPartnerBreachLv then
            if not next(partnerAttribute2[2]) or v.type_coefficient < partnerAttribute2[2].type_coefficient then
                partnerAttribute2[2] = v 
            end  
        else
            if not next(partnerAttribute2[1]) or v.type_coefficient > partnerAttribute2[1].type_coefficient then
               partnerAttribute2[1] = v 
            end  
        end
    end

    printT(partnerAttribute2)
    local attribute1, attrubute2 = "", ""
    local number1_1, number1_2, number2_1, number2_2 = 0, 0, 0, 0

    local colorNum = nil
    local key_Ex = "_1"
    for i=1,2 do
        if i == 1 then
            colorNum = 13
        else
            colorNum = 2        
        end      
        if next(partnerAttribute1[i]) then
            item["lvNum" .. i]:setVisible(true)
            ui.setLabelString(item["lvNum" .. i], "等级." .. partnerAttribute1[i].type_coefficient, colorNum)
            item["attributeNode" .. i]:setVisible(true)
        else
            item["attributeNode" .. i]:setVisible(false)
        end
        if next(partnerAttribute2[i]) then
            item["lvNum" .. i .. key_Ex]:setVisible(true)
            ui.setLabelString(item["lvNum" .. i .. key_Ex], "等级." .. partnerAttribute2[i].type_coefficient, colorNum)
            item["attributeNode" .. i .. key_Ex]:setVisible(true)
        else
            item["attributeNode" .. i .. key_Ex]:setVisible(false)
        end
    end    

    for i=1, 6 do
        if partnerAttribute1[1]["attr"..i] ~= nil then
            --if partnerAttribute1[1]["method"..i] == "value" then
                if partnerAttribute1[1]["init"..i] >= 1 then
                    number1_1 = partnerAttribute1[1]["init"..i] or 0
                    number1_2 = next(partnerAttribute1[2]) and partnerAttribute1[2]["init"..i] or 0                    
                elseif partnerAttribute1[1]["init"..i] > 0 and partnerAttribute1[1]["init"..i] < 1 then
                    number1_1 = partnerAttribute1[1]["init"..i] * 100 .. "%" or 0
                    number1_2 = next(partnerAttribute1[2]) and partnerAttribute1[2]["init"..i] * 100 .. "%" or 0                    
                end
            --end
            if partnerAttribute1[1]["attr"..i] == "atk" then
                attribute1 = "攻击："
            elseif partnerAttribute1[1]["attr"..i] == "def" then
                attribute1 = "防御："
            elseif partnerAttribute1[1]["attr"..i] == "hp" then
                attribute1 = "生命："
            end
            if number1_1 ~= 0 then
                item["attributeLab1_" .. i]:setVisible(true)
                ui.setLabelString(item["attributeLab1_" .. i], attribute1 .. number1_1, 13)     
            else
                item["attributeLab1_" .. i]:setVisible(false)
            end
            if number1_2 ~= 0 then
                item["attributeLab2_" .. i]:setVisible(true)
                ui.setLabelString(item["attributeLab2_" .. i], attribute1 .. number1_2, 22)    
            else
                item["attributeLab2_" .. i]:setVisible(false)
            end
        end

        if partnerAttribute2[1]["attr"..i] or partnerAttribute2[2]["attr"..i] then
            --if partnerAttribute2[1]["method"..i] == "value" or partnerAttribute2[2]["method"..i] == "value" then
                if partnerAttribute2[1]["init"..i] >= 1 or partnerAttribute2[1]["init"..i] == 0 then
                    number2_1 = next(partnerAttribute2[1]) and partnerAttribute2[1]["init"..i] or nil
                elseif partnerAttribute2[1]["init"..i] > 0 and partnerAttribute2[1]["init"..i] < 1 then
                    number2_1 = next(partnerAttribute2[1]) and partnerAttribute2[1]["init"..i] * 100 .. "%" or nil
                end
                if next(partnerAttribute2[2]) and (partnerAttribute2[2]["init"..i] >= 1 or partnerAttribute2[2]["init"..i] == 0) then
                    number2_2 = next(partnerAttribute2[2]) and partnerAttribute2[2]["init"..i] or nil
                elseif next(partnerAttribute2[2]) and partnerAttribute2[2]["init"..i] > 0 and partnerAttribute2[2]["init"..i] < 1 then
                    number2_2 = next(partnerAttribute2[2]) and partnerAttribute2[2]["init"..i] * 100 .. "%" or nil
                else
                    number2_2 = nil
                end
            --end
            if partnerAttribute2[1]["attr"..i] == "atk" then
                attribute1 = "攻击："
            elseif partnerAttribute2[1]["attr"..i] == "def" then
                attribute1 = "防御："
            elseif partnerAttribute2[1]["attr"..i] == "hp" then
                attribute1 = "生命："
            end
            if number2_1 then
                item["attributeLab1_" .. i .. "_1"]:setVisible(true)
                ui.setLabelString(item["attributeLab1_" .. i .. "_1"], attribute1 .. number2_1, 13)
            else
                item["attributeLab1_" .. i .. "_1"]:setVisible(false)
            end
            if number2_2 then
                item["attributeLab2_" .. i .. "_1"]:setVisible(true)
                ui.setLabelString(item["attributeLab2_" .. i .. "_1"], attribute1 .. number2_2, 22)
            else
                item["attributeLab2_" .. i .. "_1"]:setVisible(false)
            end
        end    
    end
end

function  godCompetitionSlotsInfo.setslotgemspagedata(self,item)
    print("setslotgemspagedata")
    local sigilpositionconfig = gamedata.config.sigilposition or {}
    local slotconfig = gamedata.config.general_cheer
    printT(slotconfig)

    item.gotomufuBtn:setVisible(false)

    item.toallBtn:setTouchPriority(self.touchpriority-3)
    item.toallBtn:setSwallowsTouch(true)
    item.toallBtn:addHandleOfControlEvent(function()
        item.alldatanode:setVisible(true)
        item.onedatanode:setVisible(false)
        self:setslotgemsdataall(item)
    end, CCControlEventTouchUpInside)

    for i = 1,8 do
        item["g_button"..(i>1 and ("_"..i-1) or "")]:setTouchPriority(self.touchpriority-3)
        item["g_button"..(i>1 and ("_"..i-1) or "")]:setSwallowsTouch(true)
        item["g_button"..(i>1 and ("_"..i-1) or "")]:addHandleOfControlEvent(function()
            if self.palyerdata.level >= slotconfig[tostring(i)] then
                item.alldatanode:setVisible(false)
                item.onedatanode:setVisible(true)
                self:setslotgemsdataone(item,i)
            else
                -- runGamePrompt({msg = slotconfig[tostring(i)].."级开启"})
            end
        end, CCControlEventTouchUpInside)
        --
        if self.palyerdata.level >= slotconfig[tostring(i)] then
            setSpriteFrameByName(item["g_k_quality"..(i>1 and ("_"..i-1) or "")], "b_iconk0")
            setSpriteFrameByName(item["g_quality"..(i>1 and ("_"..i-1) or "")], "b_iconbg0")
            ui.setLabelString(item["g_name"..(i>1 and ("_"..i-1) or "")],sigilpositionconfig[tostring(i)].name,1)
            setSpriteFrameByName(item["g_icon"..(i>1 and ("_"..i-1) or "")], sigilpositionconfig[tostring(i)].icon)
            item["g_lv2"..(i>1 and ("_"..i-1) or "")]:setVisible(false)
            item["g_status"..(i>1 and ("_"..i-1) or "")]:setVisible(false)
            item["g_lock"..(i>1 and ("_"..i-1) or "")]:setVisible(false)
        else
            setSpriteFrameByName(item["g_k_quality"..(i>1 and ("_"..i-1) or "")], "b_iconk0")
            setSpriteFrameByName(item["g_quality"..(i>1 and ("_"..i-1) or "")], "b_iconbg0")
            ui.setLabelString(item["g_name"..(i>1 and ("_"..i-1) or "")],sigilpositionconfig[tostring(i)].name,1)
            setSpriteFrameByName(item["g_icon"..(i>1 and ("_"..i-1) or "")], sigilpositionconfig[tostring(i)].icon.."_c")
            item["g_lv2"..(i>1 and ("_"..i-1) or "")]:setVisible(false)
            item["g_status"..(i>1 and ("_"..i-1) or "")]:setVisible(true)
            item["g_lock"..(i>1 and ("_"..i-1) or "")]:setVisible(false)
            ui.setLabelString(item["g_status"..(i>1 and ("_"..i-1) or "")],slotconfig[tostring(i)].."级开启",13)
        end
    end

    if self.select_f == 0 then
        self:setslotgemsdataall(item)
    else
        self:setslotgemsdataone(item,self.select_f)
    end

    item.getmofu:setVisible(false)
end


function  godCompetitionSlotsInfo.setslotgemsdataall(self,item)
    print("setslotgemsdataall")
    self.select_f = 0

    for i = 1,8 do
        item["selectEffect"..(i>1 and ("_"..i-1) or "")]:removeAllChildrenWithCleanup(true)
    end

    local sigilconfig = gamedata.config.sigil or {}

    local gemsiid = {}
    for k,v in pairs(self.gems) do
        gemsiid[tostring(v.iid)] = table.copy(v)
    end

    local allnum = {
        atk = 0,
        def = 0,
        hp = 0,
        hit = 0,
        critical = 0,
        criticaldmg = 0,
        adddmg = 0,
        subdmg = 0,
    }

    for k,v in pairs(self.slotgems) do
        if v.data then
            for k1, v1 in pairs(v.data) do
                if v1.iid > 0 and next(v1.data) then
                   for i = 1,4 do
                       if allnum[sigilconfig[tostring(v1.data.cid)]["attr"..i]] then
                           allnum[sigilconfig[tostring(v1.data.cid)]["attr"..i]] = allnum[sigilconfig[tostring(v1.data.cid)]["attr"..i]] + sigilconfig[tostring(v1.data.cid)]["init"..i]
                       end
                   end
                end
            end
        end
    end

    for i = 1,8 do
        item["all_att"..i]:setString("")
        item["all_num"..i]:setString("")
    end

    local hasnum = 0
    for k,v in pairs(allnum) do
        if v > 0 then
            hasnum = hasnum+1
            if hasnum <= 8 then
                item["all_att"..hasnum]:setString(gameConfig.strings.attr_type[k]..":  ")
                item["all_num"..hasnum]:setString((k == "critical") and ((v*100).."%") or v)
            end
        end
    end

end

function  godCompetitionSlotsInfo.setslotgemsdataone(self,item,index)
    print("setslotgemsdataone:"..index)
    self.select_f = index

    for i = 1,8 do
        item["selectEffect"..(i>1 and ("_"..i-1) or "")]:removeAllChildrenWithCleanup(true)
    end
    local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
    item["selectEffect"..(self.select_f>1 and ("_"..self.select_f-1) or "")]:addChild(eccb)

    if not self.slotgems[tostring(index)] then return end

    printT(self.slotgems[tostring(index)])
    for i = 1,5 do

        if self.slotgems[tostring(index)] and self.slotgems[tostring(index)].data and self.slotgems[tostring(index)].data[tostring(i)].iid > 0 then
            print(self.slotgems[tostring(index)].data[tostring(i)].iid ,"------11")
            local gem = {}
            for k,v in pairs(self.gems) do
                if v.iid == self.slotgems[tostring(index)].data[tostring(i)].iid then
                    gem = v
                end
            end
            gem.temp = ui.IDconfig(self.slotgems[tostring(index)].data[tostring(i)].data.cid)
            item["b_has"..(i>1 and ("_"..i-1) or "")]:setVisible(true)
            setSpriteFrameByName(item["b_icon"..(i>1 and ("_"..i-1) or "")], gem.temp.icon)
            ui.setLabelString(item["b_name"..(i>1 and ("_"..i-1) or "")],gem.temp.name,21)
            ui.setSpriteTextureRect2(item["b_exppos"..(i>1 and ("_"..i-1) or "")],0,0,125*((gem.exp>gem.temp.exp) and 1 or (gem.exp/gem.temp.exp)),14)
            --
            item["b_button"..(i>1 and ("_"..i-1) or "")]:setTouchPriority(self.touchpriority-3)
            item["b_button"..(i>1 and ("_"..i-1) or "")]:setSwallowsTouch(true)
            item["b_button"..(i>1 and ("_"..i-1) or "")]:addHandleOfControlEvent(function()
                print("b_button  has  "..i)
                gameWindows:openWindow("mofuproperty",{infodata = gem,page = "other"},nil)
            end, CCControlEventTouchUpInside)
        else
            item["b_has"..(i>1 and ("_"..i-1) or "")]:setVisible(false)
            --
            item["b_button"..(i>1 and ("_"..i-1) or "")]:setTouchPriority(self.touchpriority-3)
            item["b_button"..(i>1 and ("_"..i-1) or "")]:setSwallowsTouch(true)
            item["b_button"..(i>1 and ("_"..i-1) or "")]:addHandleOfControlEvent(function()
                print("b_button  no  "..i)
            end, CCControlEventTouchUpInside)
        end
    end

    if self.slotgems[tostring(index)].data["6"] and self.slotgems[tostring(index)].data["6"].iid > 0 then
        local gem = {}
        for k,v in pairs(self.gems) do
            if v.iid == self.slotgems[tostring(index)].data["6"].iid then
                gem = v
            end
        end
        gem.temp = ui.IDconfig(self.slotgems[tostring(index)].data["6"].data.cid)
        item["b_has_w"]:setVisible(true)
        item["b_lock_w"]:setVisible(false)
        setSpriteFrameByName(item["b_icon_w"], gem.temp.icon)
        ui.setLabelString(item["b_name_w"],gem.temp.name,21)
        ui.setSpriteTextureRect2(item["b_exppos_w"],0,0,125*((gem.exp>gem.temp.exp) and 1 or (gem.exp/gem.temp.exp)),14)
        --
        item["b_button_w"]:setTouchPriority(self.touchpriority-3)
        item["b_button_w"]:setSwallowsTouch(true)
        item["b_button_w"]:addHandleOfControlEvent(function()
            print("b_button_w  has")
            gameWindows:openWindow("mofuproperty",{infodata = gem,page = "other"},nil)
        end, CCControlEventTouchUpInside)
    else
        item["b_has_w"]:setVisible(false)
        if self.slotgems[tostring(index)].data["6"] and self.slotgems[tostring(index)].data["6"].iid == -1 then
            item["b_lock_w"]:setVisible(true)
        else
            item["b_lock_w"]:setVisible(false)
        end
        --
        item["b_button_w"]:setTouchPriority(self.touchpriority-3)
        item["b_button_w"]:setSwallowsTouch(true)
        item["b_button_w"]:addHandleOfControlEvent(function()
            print("b_button_w  no")
        end, CCControlEventTouchUpInside)
    end

    --num
    local sigilconfig = gamedata.config.sigil or {}

    local onenum = {
        atk = 0,
        def = 0,
        hp = 0,
        hit = 0,
        critical = 0,
        criticaldmg = 0,
        adddmg = 0,
        subdmg = 0,
    }

    for k1, v1 in pairs(self.slotgems[tostring(index)].data) do
            if v1.iid > 0 and next(v1.data) then
                for i = 1,4 do
                    if onenum[sigilconfig[tostring(v1.data.cid)]["attr"..i]] then
                        onenum[sigilconfig[tostring(v1.data.cid)]["attr"..i]] = onenum[sigilconfig[tostring(v1.data.cid)]["attr"..i]] + sigilconfig[tostring(v1.data.cid)]["init"..i]
                    end
                end
            end
    end

    for i = 1,6 do
        item["one_att"..i]:setString("")
        item["one_num"..i]:setString("")
    end

    local hasnum = 0
    for k,v in pairs(onenum) do
        if v > 0 then
            hasnum = hasnum+1
            if hasnum <= 6 then
                item["one_att"..hasnum]:setString(gameConfig.strings.attr_type[k]..":  ")
                item["one_num"..hasnum]:setString((k == "critical") and ((v*100).."%") or v)
            end
        end
    end
    --


end

--加载整体界面 
function godCompetitionSlotsInfo.loadPage(self,sid)
    if sid == 8 then return  end--魔宠
    if sid <= self.maxsid +3 and sid>0 then
        if sid <= self.maxsid  then
              
            if self.buzhen_mach[self.selectpage][tostring(sid)] == 0 then --没有武将,没有匹配槽位
                if self.generalSkeleton[sid] and self.generalSkeleton[sid].name ~=  "empty" then
                    self.generalSkeleton[sid].r_node:removeFromParentAndCleanup(true)
                    self.generalSkeleton[sid] = nil
                end
                if not self.generalSkeleton[sid] then
                    self.generalSkeleton[sid] = {}
                    self.generalSkeleton[sid].name = "empty"
                    -- self.generalSkeleton[sid].r_node = CCNode:create()
                    -- self.generalSkeleton[sid].node = CCSprite:createWithSpriteFrameName("alpha.png")
                    -- self.generalSkeleton[sid].node:setAnchorPoint(ccp(0.5,0))
                    -- self.generalSkeleton[sid].node:setScale(2)
                    -- self.generalSkeleton[sid].r_node:addChild(self.generalSkeleton[sid].node)
                    -- self.generalSkeleton[sid].r_node:setPosition(1080*(sid-0.5),100)
                    -- self.rootItems.generalcontainer:addChild(self.generalSkeleton[sid].r_node)
                    self.generalSkeleton[sid].r_node,self.generalSkeleton[sid].node = CCBReaderLoad("slotsInfo/weishangzhen", nil, true, "weishangzhen")
                    self.generalSkeleton[sid].r_node:setPosition(1080*(sid-0.5),324)
                    
                    self.rootItems.generalcontainer:addChild(self.generalSkeleton[sid].r_node)

                    self.rootItems.exclusiveArtifactNode:setVisible(false)
                    
                   
                else
                    self.generalSkeleton[sid].r_node:setVisible(true)    
                end
            else
                -- 设置形象
                -- print(gamedata.config.general[tostring(self.slotdata[tostring(sid)])],"slots1")
                local slots2 = self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(sid)]
                printT(slots2,"slots2")
                local configGeneral = gamedata.config.general[tostring(slots2.general.illusionGeneralCid or slots2.general.cid)]
                local generalName = gamedata.config.generalanimation[tostring(configGeneral.animationid)].name
                if configGeneral.fashion_id == 0 then --非时装
                    if slots2.general.illusionGeneralCid then
                        generalName = ui.getGeneralAnimationidSion(generalName, slots2.general)
                    else
                        generalName = ui.getGeneralAnimationid(generalName, slots2.general)
                    end
                end
                
                if self.generalSkeleton[sid] and self.generalSkeleton[sid].name ~=  generalName then
                    self.generalSkeleton[sid].r_node:removeFromParentAndCleanup(true)
                    self.generalSkeleton[sid] = nil
                end
                if not self.generalSkeleton[sid] then
                    self.generalSkeleton[sid] = {}
                    self.generalSkeleton[sid].name = generalName
                    self.generalSkeleton[sid].r_node = CCNode:create()

                    local wing = {level = self.protagonist.w_l,color = self.protagonist.w_c }
                    self.generalSkeleton[sid].node = ui.itemcache:loadSkeleton(generalName,wing)
                    --self.generalSkeleton[sid].node = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
                    self.generalSkeleton[sid].node:setAnimation("stand",true,0)
                    self.generalSkeleton[sid].node:setScale(2)
                    self.generalSkeleton[sid].r_node:addChild(self.generalSkeleton[sid].node.root or self.generalSkeleton[sid].node)

                    if gamedata.config.general[tostring(slots2.general.cid)].name == "主角" then
                        local growconfig = gamedata.config.protagonist_grow or {}
                        local data = slots2.general
                        local Node11,Item11 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(growconfig[tostring(data.level2+1)] and (math.mod(data.level2,5)+1) or 5), nil, true, "jie")
                        self.generalSkeleton[sid].r_node:addChild(Node11)
                    else
                        ui.addAwakeEffect(self.generalSkeleton[sid].r_node,slots2.general.skilllevel,2.2)
                    end

                    self.generalSkeleton[sid].r_node:setPosition(1080*(sid-0.5),100)
                    self.rootItems.generalcontainer:addChild(self.generalSkeleton[sid].r_node)
                end
            end
        elseif sid == self.maxsid +2 then
            if not next(self.cheerPage) then
                self.cheerPage.ccb,self.cheerPage.item = CCBReaderLoad("slotsInfo/slot-xhb.ccbi", nil, true, "slot-xhb")
                self.cheerPage.item.adaptnode:setPositionY((GameScene.topposY-1620)/2)
                self.cheerPage.ccb:setPosition(1080,0)
                self.rootItems.pagenode:addChild(self.cheerPage.ccb)
                self:setxhbpagedata(self.cheerPage.item)
            end
        elseif sid == self.maxsid+3 then
            if not next(self.slotgemsPage) then
                self.slotgemsPage.ccb,self.slotgemsPage.item = CCBReaderLoad("slotsInfo/slot-baoshi.ccbi", nil, true, "slot-baoshi")
                self.slotgemsPage.item.adaptnode:setPositionY((GameScene.topposY-1620)/2)
                self.slotgemsPage.ccb:setPosition(1080*2,0)
                self.rootItems.pagenode:addChild(self.slotgemsPage.ccb)
                self:setslotgemspagedata(self.slotgemsPage.item)
            end
        end
    end
end

function godCompetitionSlotsInfo.loadpages(self)
    self:loadPage(self.sid)
    self:loadPage(self.sid+1)
    self:loadPage(self.sid-1)
end

--设置某个page
function godCompetitionSlotsInfo.setPage(self,page,needReset)
    local oldsid =  self.sid
    self.sid = page
    self.rootItems.powerTotal:setVisible(self.sid~=self.maxsid+1 and self.sid~=self.maxsid+2 and self.sid~=self.maxsid+3)

    if self.sid <= self.maxsid and self.buzhen_mach[self.selectpage][tostring(self.sid)] > 0 then
        self.rootItems.statusnode_change:setVisible(true)
        local data = self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(self.sid)]
        if self.protagonist.iid == data.general.iid then
            self.rootItems.statusnode_change:setVisible(false)
        end    
    elseif self.sid <= self.maxsid then --没有武将,没有匹配槽位
        self:shiftStatus("equip")
        self.rootItems.statusnode_change:setVisible(false)
    end
   
    if not self.generalListTableView then
        self:reloadGeneralList()
    else
        print("generalListTableView reload")
        self.generalListTableView:reloadData()
    end

    if self.sid ~=8 then
        local sid = self.sid
        if self.sid > self.maxsid then
            sid = sid -1
        end    
        if sid == self.maxsid +2 then
            if  self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * (self.sid) < 0  then
                self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * (self.sid),0),0.2)
            end
        elseif  self.titleCellSize.x * sid >  self.rootItems.generalListScroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
            self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * sid,0),0.2)
        elseif self.titleCellSize.x * (sid-1) < -self.generalListTableView:getLuaContentOffsetX() then
            self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (sid-1) ,0),0.2)
        end
    end    

    print("setPage needReset",needReset)
    if self.sid <= self.maxsid and needReset then
       
        self:setpagedata(self.rootItems, self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(self.sid)])
    end
    gameTouch:clickprofbytime(0.2)

    if self.sid <= self.maxsid then
        --if oldsid > self.maxsid then
        local moveto = CCMoveTo:create(0.2, ccp(0, 0))
        self.rootItems.pagenode:runAction(moveto)
        --end

        local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.sid-1), 0))
        self.rootItems.generalcontainer:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
            self:loadpages()
        end)))
    else
        if self.sid ~= 8 then --魔宠位子
            local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.sid - 1 - self.maxsid), 0))
            self.rootItems.pagenode:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
                self:loadpages()
            end)))   
        end    
    end
end

function godCompetitionSlotsInfo.reloadSlotsIndex(self,data)
    if data and data.godcompetition_slotIndex then
        self.godcompetition_slotIndex = data.godcompetition_slotIndex
    end    
end
function godCompetitionSlotsInfo.reload(self,data)
    local buzhen_mach = {}
    if data and data.godCompetionData then
        self.data = data
        self.godCompetionData = data.godCompetionData
        printT(self.godCompetionData,"self.godCompetionData")
        for i=1,3 do
            local _zhenrongdata  =  self.godCompetionData[tostring(i)].slot_General
            printT(_zhenrongdata,"zhenrongdata")
            local _mach = {}
            for kk,vv in pairs(_zhenrongdata.sid) do
                printT(_zhenrongdata.general[tostring(kk)],"kk_zhengrong")
                if _zhenrongdata.general and _zhenrongdata.general[tostring(kk)] and table.getTableLength(_zhenrongdata.general[tostring(kk)]) > 0 then
                   _mach[kk] =  _zhenrongdata.general[tostring(kk)].general.godCompetitionArrayId
                else
                   _mach[kk] = 0
                end
            end  
            buzhen_mach[tostring(i)] = _mach
        end    
        self.buzhen_mach = buzhen_mach
        printT(self.buzhen_mach,"buzhen_mach")
    end    
    self.maxsid = 7
   --  local _godCompetionData = { slot_General= {},cheer_General = {},pet = nil}

    -- printT(data,"godCompetitionSlotsInfo")
    if data and data.slots then
        self.onlineslotdata =  table.copy(data.slots)
    else
        self.onlineslotdata =  table.copy(GameScene.layers["slotsInfo"].module.slotdata) 
    end

    if  data and data.godcompetition_slotIndex then
        self.godcompetition_slotIndex = data.godcompetition_slotIndex
    end    
    
    if self.godcompetition_slotIndex >0  then
        self:reorderData(self.godcompetition_slotIndex)
    end    
    
    local cheerdata = self.godCompetionData[tostring(self.selectpage)].cheer_General
    if cheerdata  then
        self.cheerdata = cheerdata
    end

    if data and data.protagonist then
        self.protagonist = data.protagonist
    end


    --魔符 --不用动
    if data and data.slotgems then
        self.slotgems = data.slotgems
    end
    if data and data.gems then
        self.gems = data.gems
    end



    -- --神器
    -- if data and data.exclusiveArtifactDatas then
    --     for k,v in pairs(data.exclusiveArtifactDatas) do
    --         self.exclusiveArtifactData[v.generalIid] = v
    --     end
    -- end

    -- if data and data.exclusiveArtifactQiLingDatas then
    --     for k,v in pairs(data.exclusiveArtifactQiLingDatas) do
    --         self.exclusiveArtifactQilingData[v.iid] = v
    --     end
    -- end

    -- -- 专属神器
    -- self:setExclusiveShow()



    
  

    -- --默认选中武将id
    -- if self.palyerdata.othertype and self.palyerdata.othertype == "togeneral" then
    --     for k,v in pairs(self.slotdata) do
    --         if v.general.cid == self.palyerdata.params["1"].i then
    --             self.sid = tonumber(k)
    --             break
    --         end
    --     end        
    -- end


    --助阵小伙伴
    if next(self.cheerPage) then
        self:setxhbpagedata(self.cheerPage.item)
    end
    --魔符
    if next(self.slotgemsPage) then
        self:setslotgemspagedata(self.slotgemsPage.item)
    end
    --初始化页面(左右各一个)
    self:loadpages()

    -- --显示其中一个页面
    self:setPage(self.sid,true)

    if data then
        self:checkrelation()
    end    
end

function godCompetitionSlotsInfo.reorderData(self,index)
    print("godCompetitionSlotsInfo.reorderData index----------:",index)
    local temp = nil
    if index == 1 then return end 
    local data1 = self.onlineslotdata["1"] 
    for i=1,self.maxsid do
        if i <index then
            local temp_ = self.onlineslotdata[tostring(i+1)]
            self.onlineslotdata[tostring(i)] = temp_
        elseif i == index then
            print(i,"reorderData mainrole")
            self.onlineslotdata[tostring(index)] = data1
            break
        end
    end
    -- printT(self.onlineslotdata,"")
end

--专属神器
function godCompetitionSlotsInfo.setExclusiveShow(self)
    if (self.palyerdata.level or 0) < gamedata.config.build[tostring(611)].level then
        self.rootItems.exclusiveArtifactNode:setVisible(false)
        return
    end

    self.rootItems.zhuanshu:removeAllChildrenWithCleanup(true)
    self.rootItems.exclusiveArtifactNode:setVisible(false)
    local general = self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(self.sid)].general
    if general then
        local generalConfig = gamedata.config.general[tostring(general.illusionGeneralCid or general.cid)]
        if generalConfig.exclusive and generalConfig.exclusive > 0 then
            self.rootItems.exclusiveArtifactNode:setVisible(true)
            local exclusiveConfig = ui.IDconfig(generalConfig.exclusive) or {}
            local skeleton = ui.createExclusiveSkeleton(exclusiveConfig.animation)
            if skeleton then
                skeleton:setAnimation("stand",true,0)
                self.rootItems.zhuanshu:addChild(skeleton)
                if generalConfig.quality < 7 then
                    ui.addGray("CCNode",skeleton)
                elseif general.exclusiveArtifactCid == 0 then
                    ui.addGray("CCNode",skeleton)
                else
                end
            end
        end
    end

end

function godCompetitionSlotsInfo.clear(self)
    self.select_f = 0
    self.generalListTableView = nil
    self.xiaohuobanListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.addedGroup = {}
    self.addedDataNode = {}
    self.exclusiveArtifactData = {}
    self.exclusiveArtifactQilingData = {}
    self.godCompetionData = {}
    self.buzhen_mach = {}
    self.data = {}
    self.sid = 1
    self.level = 0

    self.status = "equip"
    self.datastatus = "general_godcompetition"
    self.slotgemsPage = {}
    self.cheerPage = {}
    self.generalSkeleton = {}

    self.palyerdata = {}

    self.slotgems = {}
    self.gems = {}
    self.slotdata = nil
    self.onlineslotdata = nil
    self.buffdata = {}
    self.cheerdata = nil

    self.selectpage = "1"
    self.godcompetition_slotIndex = 0

    self.rootNode = nil
    self.rootItems = nil

    self.oldrelation = nil
    self.oldgeneral = nil
end


--武将列表
function godCompetitionSlotsInfo.reloadGeneralList(self,alldata)
    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("slotsInfo/generalIcon.ccbi", nil, true, "generalIcon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }

                ui.tableviewAnimationH(self.generalListTableView,cellCCB,self.titleCellSize.x, self.titleCellSize.y,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            cellCCB:setScale(0.89)
            ccbDocumentControler.selectEffect:removeAllChildrenWithCleanup(true)

            if a1+1<= self.maxsid then
                -- 设置头像

                local generalData = self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(a1+1)]
                -- local generalData = self.slotdata[tostring(a1+1)] or {}
                if generalData.general then
                    if generalData.general.illusionGeneralCid then
                        local configGeneral = gamedata.config.general[tostring(generalData.general.illusionGeneralCid)]
                        local gdata = ui.getConfigGeneralSion(generalData.general)
                        if next(gdata) and configGeneral.fashion_id == 0 then
                            if configGeneral.passiveskills and configGeneral.passiveskills > 0 then
                                gdata.skillid = configGeneral.passiveskills
                            end
                            ui.setSlotGeneralIcon(generalData,ccbDocumentControler,0,gdata)
                        else
                            ui.setSlotGeneralIcon(generalData,ccbDocumentControler)
                        end
                    else
                        local configGeneral = gamedata.config.general[tostring(generalData.general.cid)]
                        local gdata = ui.getConfigGeneral(generalData.general)
                        if next(gdata) and configGeneral.fashion_id == 0 then
                            if configGeneral.passiveskills and configGeneral.passiveskills > 0 then
                                gdata.skillid = configGeneral.passiveskills
                            end
                            ui.setSlotGeneralIcon(generalData,ccbDocumentControler,0,gdata)
                        else
                            ui.setSlotGeneralIcon(generalData,ccbDocumentControler)
                        end
                    end
                else
                    ui.setSlotGeneralIcon(generalData,ccbDocumentControler)
                end
            elseif a1+1 == self.maxsid+1 then --魔宠
                local pet = self.godCompetionData[tostring(self.selectpage)].pet
                if pet and pet.cid > 0 then
                    ui.setSlotPetIcon(ccbDocumentControler,{cid=pet.cid, level=pet.level})
                else
                    ui.setSlotGeneralIcon({},ccbDocumentControler)
                end    

            elseif a1+1 == self.maxsid+2 then
                ui.setxiaohuobanIcon(ccbDocumentControler,nil,true)
            else
                ui.setslotgemsIcon(ccbDocumentControler,nil,true)
            end
            if a1+1 == self.sid then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                ccbDocumentControler.selectEffect:addChild(eccb)
            end
            if self.generalListTableView then
                cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = self.maxsid +3
        elseif fn == "cellTouched" then
            local index = a1:getIdx()+1
            print(index,"cellTouched")
            gameTouch:clickprofbytime(0.5)
            if index == 8 then
                --选择魔宠
                local onlinePet =  {}
                for i=1,3 do
                    local petid  =  self.godCompetionData[tostring(i)].pet.iid
                    if petid > 0 then
                        table.insert(onlinePet, {petid = petid, team_id = i})
                    end    
                end    
                gameWindows:openWindow("godCompetitionPetList",{onlinePet = onlinePet, team_id_now = self.selectpage})
            elseif index <= self.maxsid then
                self:setPage(index,true)
            elseif index >= self.maxsid+1 then
                self:setPage(index)
            end
           
        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.generalListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.generalListScroll:getContentSize().width,
        viewheight = self.rootItems.generalListScroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.generalListScroll:addChild(self.generalListTableView)
    self.generalListTableView:setTouchPriority(self.touchpriority)
end



function godCompetitionSlotsInfo.checkrelation(self,isshiftPage)
    -- print("checkrelation-----------------------------")
    local relationtemp = {}
    if not self.oldrelation or isshiftPage then
        self.oldrelation = self.godCompetionData[tostring(self.selectpage)].slot_General.relation
        self.oldgeneral = self.godCompetionData[tostring(self.selectpage)].slot_General.general
        return
    end

    --缘分
    for i=1,7 do
        local data = self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(i)]
        if data and next(data) and data.general then
            local configdata = gamedata.config.general[tostring(data.general.cid)] or {}
            print(data.general.cid ,"cid")
            local relationdata = self.godCompetionData[tostring(self.selectpage)].slot_General.relation[tostring(i)]
            printT(relationdata,"checkrelation relationdata tt")
            if relationdata then
                for k1,v1 in pairs(relationdata) do
                    print(k1)
                    print(v1,"checkrelation relationdata v1")
                    if v1.activate == 2 then
                        local isnew = true
                        if self.oldrelation and self.oldrelation[tostring(i)] then
                            for k2,v2 in pairs(self.oldrelation[tostring(i)]) do
                                print(k2,v2,"k2v2")
                                if v2.ids and next(v2.ids) then
                                    for k3,v3 in pairs(v2.ids) do
                                        print(k3,v3,"k3v3")
                                        if v3 and v3 == v2.ids[k3]  and v2.activate == 2 then
                                            print(k3,v3,"already have")
                                            isnew = false
                                        end    
                                    end 
                                end    
                            end
                        end    
                      
                        print(k1,"checkrelation relationdata k1")
                        if isnew and not relationtemp[tostring(configdata["cond"..tostring(k1).."name"])] then
                            print("checkrelation relationdata k1 enter")
                             relationtemp[tostring(configdata["cond"..tostring(k1).."name"])] = 1
                             local rnum = table.getTableLength(relationtemp) or 1
                             self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5*rnum),CCCallFunc:create(function()
                                 runGamePromptSkill({type = "relation", name = configdata["cond"..tostring(k1).."name"]})
                             end)))
                         end
                    end    
                end    
            end    
             
        end    
    end    

    --合体技
    for i=1,7 do
        local data = self.godCompetionData[tostring(self.selectpage)].slot_General.general[tostring(i)]
        if data and next(data) and data.general then
            if data.general.combskillstatus and data.general.combskillstatus == 2 then
                local configdata = gamedata.config.general[tostring(data.general.cid)] or {}
                local combskillconfig = gamedata.config.combskill[tostring(data.general.combskill and data.general.combskill.cid or 0)] or {}
                local isnew = true

                if self.oldgeneral and self.oldgeneral[tostring(i)] then
                    for k2,v2 in pairs(self.oldgeneral[tostring(i)]) do
                        print(k2,"k2v2 general")
                        printT(v2)
                        if v2 and  type(v2) == "table" then
                            if v2.cid and v2.cid == data.general.cid and v2.combskillstatus and v2.combskillstatus == 2 then
                                print("k2v2 general enter")
                                isnew = false
                            end
                        end
                    end
                end    

                if isnew and not relationtemp[tostring(combskillconfig["name"])] then
                    relationtemp[tostring(combskillconfig["name"])] = 1
                    local rnum = table.getTableLength(relationtemp) or 1
                    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5*rnum),CCCallFunc:create(function()
                        runGamePromptSkill({type = "skill", name = combskillconfig["name"]})
                    end)))
                end
            end
        end
    end    


    self.oldrelation = self.godCompetionData[tostring(self.selectpage)].slot_General.relation
    self.oldgeneral = self.godCompetionData[tostring(self.selectpage)].slot_General.general

end



return godCompetitionSlotsInfo(5 