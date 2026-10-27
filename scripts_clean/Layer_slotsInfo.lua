--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/12/27
-- Time: 下午3:58
-- To change this template use File | Settings | File Templates.
--


local slotsInfo = {

    resource = nil,
    titleCellSize = {x=180,y=180},

    rootNode = nil,
    rootItems = nil,

    slotgems = {},
    gems = {},
    slotdata = nil,
    cheerdata = nil,
    cheerPage = {},
    slotgemsPage = {},
    generalSkeleton = {},

    generalinfo = {},

    generalListTableView = nil,
    xiaohuobanListTableView = nil,

    statusconfig = {"equip","soul","stone"},
    status = "equip",


    toallBtnType = false, -- 总览界面时，按钮置灰

    safemask = {},

    touchX = nil,
    touchY = nil,
    pagemoved = false,
    contentoffsetx = 0,
    isContentScroll = false,
    sid = 1,
    maxsid = 0,
    select_f = 0,
    quickequip = {},
    quicksoul = {},
    resolvequality = 5,--选择魔符合成的等级
    resolvequalityTimes = 1,--选择魔符合成的等级

    selectState = 0,

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

    changedequip = {},

    systemid = {
        equip = 4,
        soul=5,
        stone = 3
    },

    addedGroup = {},
    addedDataNode = {},
    dataStatusConfig={
        equip = "general",
        soul = "general",
        stone = "stone",
    },
    datastatus = "general",
    tabs = 1,
    selectStoneIndex = 1, --选中的神石索引号
    selectStoneLevel = 1, --选中的神石等级
    indexToTableKey = { --通过神石选中的索引找到对应的表key
        [1] = "atk_number",
        [2] = "def_number",
        [3] = "hp_number",
        [4] = "hit_number",
        [5] = "dodge_number",
        [6] = "parry_number",
        [7] = "resilience_number",
        [8] = "arp_number",
    },
    exclusiveArtifactData = {}
}

function slotsInfo.setStatus(self,status)
    self.status = status
end

function slotsInfo.setSafemaskHint(self)
    if gameConfig:checkBuildOpen(209) and GameScene:checkopenlevelbyId(209,true) and self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)]["hashint_safemask"] then
        self.rootItems["hint_safemask"]:setVisible(true)
    else
        self.rootItems["hint_safemask"]:setVisible(false)
    end

    if guide.controller:isNewSystemByid(462) and GameScene:checkopenlevelbyId(462,true) then
        self.rootItems["hint_safemask"]:setVisible(true)
    end
end

function slotsInfo.setExclusiveHint(self)
    ui.sethint(self.rootItems.hint_zhuanshu,false)
    if not (gameConfig:checkBuildOpen(611) and GameScene:checkopenlevelbyId(611,true)) then
        return
    end

    if self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)].general then
        local general = self.slotdata[tostring(self.sid)].general
        if general.hashint_exclusive then
            ui.sethint(self.rootItems.hint_zhuanshu,true)
        end
        if gameWindows.windows["exclusiveArtifact"].show then
            if gameWindows.windows["exclusiveArtifact"].module.data.general and gameWindows.windows["exclusiveArtifact"].module.data.general.iid == general.iid then
                gameWindows.windows["exclusiveArtifact"].module.general = table.copy(general)
                gameWindows.windows["exclusiveArtifact"].module:reloadHint()
            end
        end

    end
end

function slotsInfo.setArtifactHint(self)
    if self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)]["hashint_artifact"] then
        self.rootItems["hint_artifact"]:setVisible(true)
    else
        self.rootItems["hint_artifact"]:setVisible(false)
    end
end

function slotsInfo.setYangchengHint(self)
    print("setYangchengHint")
    if self.slotdata[tostring(self.sid)] and (self.slotdata[tostring(self.sid)]["hashint_upstar"] or self.slotdata[tostring(self.sid)]["hashint_tupo"] or self.slotdata[tostring(self.sid)]["hashint_feisheng"]) then
        self.rootItems["hint_yangcheng"]:setVisible(true)
    else
        self.rootItems["hint_yangcheng"]:setVisible(false)
    end
end

function slotsInfo.setStatusHint(self)
    for k,v in pairs(self.statusconfig) do
        if self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)]["hashint_"..v] and v~=self.status then
            self.rootItems["hint_"..v]:setVisible(true)
        else
            self.rootItems["hint_"..v]:setVisible(false)
        end
    end
end

function slotsInfo.shiftStatus(self,status)
    if not GameScene:checkopenlevelbyId(self.systemid[status]) then return end
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

        if self.datastatus == "general" then
            self.addedDataNode[self.datastatus].ccb,self.addedDataNode[self.datastatus].items = CCBReaderLoad("slotsInfo/data_general2", nil, true, "data_general2")
            self.attrStatus = "fan"
            self.addedDataNode[self.datastatus].items.attrChange:setTouchPriority(-101)
            self.addedDataNode[self.datastatus].items.attrChange:setSwallowsTouch(true)
            self.addedDataNode[self.datastatus].items.attrChange:addHandleOfControlEvent(function()
                if self.attrStatus == "fan" then
                    self.attrStatus = "xian"
                else
                    self.attrStatus = "fan"
                end
                self:reloadDataGeneral()
            end, CCControlEventTouchUpInside)
            

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

    self:shiftButtonStatus()

    if self.status == "soul" then
        self.rootItems.statusselect:setPosition(self.rootItems["statusnode_gotoSoul"]:getPosition())
    else
        self.rootItems.statusselect:setPosition(self.rootItems["statusnode_"..self.status]:getPosition())
    end

    self:setStatusHint()


    if guide.controller then
        guide.controller:UIComplete(8044)
    end
end


function slotsInfo.shiftButtonStatus(self)
    local data = self.slotdata[tostring(self.sid)]
    if self.status == "soul" then

        self.rootItems.statusnode_gotoSoul:setPositionX(-117)
        self.rootItems.statusnode_soul:setPositionX(99999)
    else

        self.rootItems.statusnode_gotoSoul:setPositionX(99999)
        self.rootItems.statusnode_soul:setPositionX(-117)
    end

    if self.status == "equip" or self.status == "soul" then

        self.rootItems.quickEquiptext = self.addedDataNode["general"].items.quickEquiptext
        self.rootItems.quickEquipUptext = self.addedDataNode["general"].items.quickEquipUptext

        self.rootItems.quickEquip = self.addedDataNode["general"].items.quickEquip
        self.rootItems.quickEquipUp = self.addedDataNode["general"].items.quickEquipUp



        ui.setLabelString(self.rootItems.quickEquiptext,"一键装备",19)
        ui.setLabelString(self.rootItems.quickEquipUptext,"一键强化",19)
    elseif self.status == "stone" then

        self.rootItems.quickEquiptext = self.addedDataNode["stone"].items.quickEquiptext
        self.rootItems.quickEquipUptext = self.addedDataNode["stone"].items.quickEquipUptext

        self.rootItems.quickEquip = self.addedDataNode["stone"].items.quickEquip
        self.rootItems.quickEquipUp = self.addedDataNode["stone"].items.quickEquipUp
        
        local allactive = true
        for i=1,8 do
            if data["g"..i] <=0 then
                allactive = false
                break
            end
        end

        ui.setLabelString(self.rootItems.quickEquiptext,allactive and "一键强化" or "一键激活",19)
        ui.setLabelString(self.rootItems.quickEquipUptext,allactive and "强化" or "激活",19)
    end





    if self.status == "soul" then
        ui.addGray("CCControlButton",self.rootItems.quickEquipUp)
        ui.addGray("CCLabelTTF",self.rootItems.quickEquipUptext)
    else
        ui.removeGray("CCControlButton",self.rootItems.quickEquipUp)
        ui.removeGray("CCLabelTTF",self.rootItems.quickEquipUptext)
    end

    self.rootItems.quickEquip:setSwallowsTouch(true)
    self.rootItems.quickEquip:setTouchPriority(-103)
    self.rootItems.quickEquip:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        --if self.isContentScroll then return end
        local slotdata = self.slotdata[tostring(self.sid)]
        if not slotdata.general then
            -- runGamePrompt({msg = "请先上阵武将"})
            runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",2)})
            return
        end

        if self.status == "equip" then
            local ididx = {"weapon","armor","accessory","head","treasure","horse",}
            local needquick = false
            for k,v in ipairs(ididx) do
                if (slotdata[v].changeiid or 0) ~= 0 then
                    needquick = true
                    break
                end
            end
            if needquick then
                UIRequest({
                    type = 1007,
                    sid = slotdata.sid, 
                    method = 1,
                    changeiids = {
                            slotdata.weapon.changeiid or 0,
                            slotdata.armor.changeiid or 0,
                            slotdata.accessory.changeiid or 0,
                            slotdata.head.changeiid or 0,
                            slotdata.treasure.changeiid or 0,
                            slotdata.horse.changeiid or 0,
                        }
                    })
                self.quickequip[slotdata.sid] = true
                gamedata.music:PlayOptSound("yjzb")
            else
                runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",6)})
            end
        elseif self.status == "soul" then
            local needquick = false
            for i=1,8 do
                if (slotdata["s"..i].changeiid or 0) ~= 0 then
                    needquick = true
                    break
                end
            end
            if needquick then
                UIRequest({
                    type = 1007,
                    sid = slotdata.sid, 
                    method = 2,
                    changeiids = {
                            slotdata.s1.changeiid or 0,
                            slotdata.s2.changeiid or 0,
                            slotdata.s3.changeiid or 0,
                            slotdata.s4.changeiid or 0,
                            slotdata.s5.changeiid or 0,
                            slotdata.s6.changeiid or 0,
                            slotdata.s7.changeiid or 0,
                            slotdata.s8.changeiid or 0,
                        }
                    })
                self.quicksoul[slotdata.sid] = true
                gamedata.music:PlayOptSound("yjzb")
            else
                runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",7)})
            end
        elseif self.status == "stone" then
            UIRequest({type = 1130,sid = slotdata.sid,method = 1})
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.quickEquipUp:setSwallowsTouch(true)
    self.rootItems.quickEquipUp:setTouchPriority(-103)
    self.rootItems.quickEquipUp:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        local slotdata = self.slotdata[tostring(self.sid)]
        if not slotdata.general then
            -- runGamePrompt({msg = "请先上阵武将"})
            runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",2)})
            return
        end
        if self.status == "equip" then
            if ui.getVipLevelByStr("b_yjqh") > GameScene.vip.vip then
                -- runGamePrompt({msg = "VIP"..ui.getVipLevelByStr("b_yjqh").."以上可使用一键强化"})
                runGamePrompt({msg = gameConfig.strings:vipSt(ui.getVipLevelByStr("b_yjqh"))})
            else
                local quickcb = function()
                    UIRequest({type = 1109,ids = {slotdata.general.iid}})
                end
                local tipconfig = gamedata.config.global_kv.equip_strengthen_level
                local tiplevel = tipconfig and tipconfig.level or 60
                if GameScene.roleinfo.level>=tonumber(tiplevel) then
                    gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("equips",27)},quickcb)
                else
                    quickcb()    
                end        
            end
        elseif self.status == "soul" then
            -- runGamePrompt({msg = "不能一键强化"})
            runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",4)})
        elseif self.status == "stone" then
            UIRequest({type = 1130,sid = slotdata.sid,method = 0})
        end

    end, CCControlEventTouchUpInside)


    --魔宫按钮
    self:changeButtonStatus()
end

function slotsInfo.init(self,parent,toppos,param)
    print("slotsInfo.init =======")
    printT(param)
    self.rootNode,self.rootItems = CCBReaderLoad("slotsInfo/slotsinfo", nil, true, "slotsinfo")
    parent:addChild(self.rootNode)

    self.equipconfig = gameConfig.equipconfig

    self.topposy = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.bgnode:setPositionY((GameScene.topposY-1620)*0.6)

    self.rootItems.datanode:setPositionY((GameScene.topposY-1620)*0.25)
    self.rootItems.buttonnode:setPositionY((GameScene.topposY-1620)*0.40+492)
    self.rootItems.midnode:setPositionY((GameScene.topposY-1620)*0.6+968)
    --self.rootItems.generaltop:setPositionY((GameScene.topposY-1620)*0.25)

    self.rootItems.generalscroll = tolua.cast(self.rootItems.generalscroll, "CCScrollView")
    self.rootItems.generalscroll:setTouchEnabled(false)

    --
    if self.rootItems.buzhenSprite then
        if gameConfig:checkBuildOpen(198) and GameScene:checkopenlevelbyId(198,true) then
            setSpriteFrameByName(self.rootItems.buzhenSprite,"lingzhen")
        else
            setSpriteFrameByName(self.rootItems.buzhenSprite,"b_n_button5_2")
        end
    end
    --
    self.rootItems.buzhen:setTouchPriority(-101)
    self.rootItems.buzhen:setSwallowsTouch(true)
    self.rootItems.buzhen:addHandleOfControlEvent(function()
        --todo
        if gameConfig:checkBuildOpen(198) and GameScene:checkopenlevelbyId(198,true) then
            GameScene:shiftLayer("deployment","up",self.arrangedata)
        else
            gameWindows:openWindow("slotarrange",self.arrangedata,nil)
        end
    end, CCControlEventTouchUpInside)

    if param and param.sid then
        self.sid = param.sid
        if tonumber(self.sid) and tonumber(self.sid) <= self.maxsid then
            if param.sidtype and param.sidtype == "slot" then
            else
                if type(param.sid) == "number" and next(self.slotdata) and next(self.arrangedata) and self.arrangedata[tostring(param.sid)].general then
                    for k,v in pairs(self.slotdata) do
                        if  v.general and self.arrangedata[tostring(param.sid)].general.iid == v.general.iid then
                            print(v.general)
                            self.sid = tonumber(k)
                            break
                        end
                    end
                end
            end
        end
    elseif guide.controller.isOnGuide then
        self.sid = 1
    end

    if param and param.status then
        self.status = param.status
    end
    self.awakenConfig = gamedata.config.general_awaken
    self.rootItems.gotoSoulBtn:setSwallowsTouch(true)
    self.rootItems.gotoSoulBtn:setTouchPriority(-101)
    self.rootItems.gotoSoulBtn:addHandleOfControlEvent(function()
        print("点击去猎命")
        GameScene:shiftLayer("soul","up")
    end, CCControlEventTouchUpInside)

    self.rootItems.generalNodeButton:setTouchPriority(-101)
    self.rootItems.generalNodeButton:addHandleOfControlEvent(function()
        print("generalNodeButton")

        if self.isContentScroll then return end
        guide:setGuideProlayer(true)
        local slotdata = self.slotdata[tostring(self.sid)]
        if slotdata.general then
            gameWindows:openWindow("generalInfoRole",{data = slotdata, sid = slotdata.sid, pagetype = "info"})
            -- gameWindows:openWindow("generalInfo",{data = slotdata, sid = slotdata.sid, pagetype = "info"})
        else
            local callback = function(selectedData)
                for k,v in pairs(selectedData) do
                    UIRequest({type=1003,pos1 = slotdata.sid, iid = v.iid})
                    break
                end
            end
            gameWindows:openWindow("selectlist",{type = "changegeneral",param = nil, param2="slot"},callback)
        end
    end, CCControlEventTouchUpInside)



    for k,v in pairs(self.statusconfig) do

        -- ui.setLabelString(self.rootItems["statustext_"..v],nil,18)
        self.rootItems["status_"..v]:setSwallowsTouch(true)
        self.rootItems["status_"..v]:setTouchPriority(-103)
        self.rootItems["status_"..v]:addHandleOfControlEvent(function()
            guide:setGuideProlayer(true)
            if not self.slotdata[tostring(self.sid)].general then
                runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",2)})
                return
            end
            if self.status ~= v then
                self:shiftStatus(v)
            end
        end,CCControlEventTouchUpInside)
    end

    if GameScene:checkopenlevelbyId(self.systemid["stone"],true) then
        ui.removeGray("CCSprite",self.rootItems.stone_sp)
    else
        ui.addGray("CCSprite",self.rootItems.stone_sp)
    end

    if GameScene:checkopenlevelbyId(self.systemid["soul"],true) then
        ui.removeGray("CCSprite",self.rootItems.soul_sp)
    else
        ui.addGray("CCSprite",self.rootItems.soul_sp)
    end

    --
    if self.rootItems.safemask_lab then
        ui.setLabelString(self.rootItems.safemask_lab,gameConfig.strings:string_common("fixedString","safemask",4),18)
    end
    --

    self.rootItems["safemaskup"]:setSwallowsTouch(true)
    self.rootItems["safemaskup"]:setTouchPriority(-103)
    self.rootItems["safemaskup"]:addHandleOfControlEvent(function()
        if gameConfig:checkBuildOpen(209) and GameScene:checkopenlevelbyId(209) then
            if self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)].general then
                GameScene:shiftLayer("safemask","up",{sid = self.slotdata[tostring(self.sid)].sid or 1,slotdata = self.slotdata or {},safemask = self.safemask or {}})
            else
                runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",2)})
            end
        end
    end,CCControlEventTouchUpInside)


    if self.rootItems.token_lab then
        ui.setLabelString(self.rootItems.token_lab,gameConfig.strings:string_common("token", 1),18)
    end

    if GameScene:checkopenlevelbyId(631, true) then
        ui.removeGray("CCSprite", self.rootItems.token_sprite)
    else
        ui.addGray("CCSprite", self.rootItems.token_sprite)
    end

    local _tokenCb = function()
        if GameScene:checkopenlevelbyId(631, false) then
            GameScene:shiftLayer("tokenMain", "up", {page = "token", sid = self.slotdata[tostring(self.sid)].sid or 1, slotdata = self.slotdata or {}})
        end
    end

    ui.commonBtn(self, self.rootItems, "tokenBtn", _tokenCb, -103)
    
    local _hintData = false

    if GameScene.hintdata[tostring(631)] and GameScene.hintdata[tostring(631)] ~= 0 then
        _hintData = true
    end
   
    ui.sethint(self.rootItems.hint_token, _hintData)

    


    -- self.rootItems["shenqibutton"]:setSwallowsTouch(true)
    -- self.rootItems["shenqibutton"]:setTouchPriority(-103)
    -- self.rootItems["shenqibutton"]:addHandleOfControlEvent(function()
    --     if self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)].general then
    --         local _generalTable,index = self:getGeneralTable()
    --         gameWindows:openWindow("exclusiveArtifact", {general = _generalTable, sid = self.sid,index = index})
    --     else
    --         runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",2)})
    --     end
    -- end,CCControlEventTouchUpInside)


    self.rootItems["zhuanshubutton"]:setSwallowsTouch(true)
    self.rootItems["zhuanshubutton"]:setTouchPriority(-103)
    self.rootItems["zhuanshubutton"]:addHandleOfControlEvent(function()
        if self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)].general then
            gameWindows:openWindow("exclusiveArtifact", {general = self.slotdata[tostring(self.sid)].general,sid = self.slotdata[tostring(self.sid)].sid,opt = 1})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",2)})
        end
    end,CCControlEventTouchUpInside)

    self.rootItems["artifactBtn"]:setSwallowsTouch(true)
    self.rootItems["artifactBtn"]:setTouchPriority(-103)
    self.rootItems["artifactBtn"]:addHandleOfControlEvent(function()
        if gameConfig:checkBuildOpen(366) and GameScene:checkopenlevelbyId(366) then
            if self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)].general then
                if self.slotdata[tostring(self.sid)] and type(self.slotdata[tostring(self.sid)].newartifact) == "table" then
                    local hasHint = (self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)]["hashint_artifact"]) and 1 or 0
                    gameWindows:openWindow("artifactInfo",{artifactData = self.slotdata[tostring(self.sid)].newartifact,isUp = true,hasHint = hasHint, self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)]["hashint_artifact"],sid = self.slotdata[tostring(self.sid)].sid,openType = 1},nil)
                else
                    gameWindows:openWindow("artifactSelect",{showType = "checked"},function(artifact)
                        if artifact then
                            gameTouch:clickprofbytime(1)
                            UIRequest({type = 5503,sid = self.slotdata[tostring(self.sid)].sid,iid = artifact.iid})
                        end
                    end)
                end
            else
                runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",2)})
            end
        end
    end,CCControlEventTouchUpInside)

    
    for i=1, 8 do
        self.rootItems["button"..i]:setTouchPriority(-101)
        self.rootItems["button"..i]:addHandleOfControlEvent(function()
            if self.isContentScroll then return end
            guide:setGuideProlayer(true)
            if not self.slotdata[tostring(self.sid)].general then return end
            local slotdata = self.slotdata[tostring(self.sid)]
            if self.status ==  "equip" then
                if i == 5  then
                    gameWindows:openWindow("generalInfoSkill",{data = slotdata, sid = slotdata.sid, pagetype = "skillinfo", skilltype = "skill"})
                elseif i == 7 and slotdata.general.combskill.cid then
                    if slotdata.general.combskill.islead then
                        gameWindows:openWindow("generalInfoSkill",{data = slotdata, sid = slotdata.sid, islead = 1, pagetype = "skillinfo", skilltype = "leadskill"})
                    else
                        gameWindows:openWindow("generalInfoSkill",{data = slotdata, sid = slotdata.sid, pagetype = "skillinfo", skilltype = "combskill"})
                    end
                else

                    if slotdata[self.orderconfig[i].key] and slotdata[self.orderconfig[i].key].cid and slotdata[self.orderconfig[i].key].cid ~=0 then
                        local configdata =  gamedata.config.equip[tostring(slotdata[self.orderconfig[i].key].cid)] or {}
                        -- print("  slotdata.sid  ",slotdata.sid,"  self.sid  ",self.sid);

                        gameWindows:openWindow("equipInfo",{equip = slotdata[self.orderconfig[i].key], sid = slotdata.sid, pagetype = "info",index = self.sid})
                    else
                        local callback = function(selectedData)
                            for k,v in pairs(selectedData) do
                                UIRequest({type=1005,slot = slotdata.sid,equipeid = v.iid})
                                break
                            end
                        end
                        gameWindows:openWindow("selectlist",{type = "change_"..self.orderconfig[i].key.."_all",param = {equipiid = 0,sid = slotdata.sid}},callback)
                    end
                end
            elseif self.status == "soul" then
                if slotdata["s"..i] and slotdata["s"..i].cid then
                    gameWindows:openWindow("soulInfo",table.merge(slotdata["s"..i],{fromtype = "slot",sid=slotdata.sid,pagetype = "info"}) )
                elseif slotdata["s"..i].openlevel then
                    -- runGamePrompt({msg = slotdata["s"..i].openlevel.."级开启"})
                    runGamePrompt({msg = gameConfig.strings:lvOpen(slotdata["s"..i].openlevel)})
                else
                    local callback = function(selectedData)
                        for k,v in pairs(selectedData) do
                            UIRequest({type=1006,slot = slotdata.sid, soulpos =slotdata["s"..i].soulpos, soulid = v.iid})
                            break
                        end
                    end
                    gameWindows:openWindow("selectlist",{type = "changesoul",param = {sid=slotdata.sid,soulpos = slotdata["s"..i].soulpos}},callback)
                end
            end
        end, CCControlEventTouchUpInside)
    end


    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self:loadpagesExt()
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
            if self.sid+1 <= self.maxsid+2 then
                self:setPage(self.sid+1,true)
            else
                self:setPage(self.sid)
            end
        elseif moveX < -20 and self.pagemoved then
            if self.sid-1 >0 then
                self:setPage(self.sid-1,true)
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -102, false)
    self.rootItems.touchLayer:setTouchPriority(-102)
    self.rootItems.touchLayer:setTouchEnabled(true)

    if not GameScene:checkUpdate(10021) and not GameScene:checkUpdate(10022) and not GameScene:checkUpdate(10028) then
        addDelayUpdateFunc(function()
            self:reload()
        end,"slotreload")
    end

    if self.rootItems.hint_fashion then
        self.rootItems.hint_fashion:setVisible(false)
    end 
end

function slotsInfo.getGeneralTable(self)
    local _generalTable = {}
    local index = 1

    for i = 2, 7 do
        if self.slotdata and next(self.slotdata) and
           self.slotdata[tostring(i)] and self.slotdata[tostring(i)].general then
           table.insert(_generalTable, self.slotdata[tostring(i)].general)
           _generalTable[#_generalTable].sid = i
           if self.sid == i then 
                index = #_generalTable 
            end
        end
    end
    
    return _generalTable,index
end


function slotsInfo.reloadSouls(self)
    if not self.addedGroup["soul"] then return end
    local data = self.slotdata[tostring(self.sid)]

    for i = 1, 8 do
        ui.setSoulIcon(data["s"..i],self.addedGroup["soul"].items,i-1)
    end
end

function slotsInfo.reloadEquip(self)
    if not self.addedGroup["equip"] then return end
    local data = self.slotdata[tostring(self.sid)]

    for k,v in ipairs(self.equipconfig) do
        if data[v] and data[v].iid and self.changedequip[data[v].iid] then
            print("equipconfig111111")
            -- ui.setEquipIcon(data[v],self.addedGroup["equip"].items,k-1,self.changedequip[data[v].iid])
            printT(data[v])
            -- 添加升星显示
            ui.setEquipIcon(data[v],self.addedGroup["equip"].items,k-1,self.changedequip[data[v].iid],data[v])
            self.changedequip[data[v].iid] = nil
        else
            print("equipconfig22222")
            printT(data[v])
            -- ui.setEquipIcon(data[v],self.addedGroup["equip"].items,k-1)
            -- 添加升星显示
            ui.setEquipIcon(data[v],self.addedGroup["equip"].items,k-1,nil,data[v])

        end
    end
end

-- 武将技能
function slotsInfo.reloadSkill(self)
    if not self.addedGroup["equip"] then return end
    local data = self.slotdata[tostring(self.sid)]
    -- 设置技能
    if next(data) and data.general then
        if data.general.illusionGeneralCid then
            local configGeneral = gamedata.config.general[tostring(data.general.illusionGeneralCid)]
            local gdata = ui.getConfigGeneralSion(data.general)
            if next(gdata) and configGeneral.fashion_id == 0 then
                if gdata.skillid and gdata.skillid > 0 then
                    self.slotdata[tostring(self.sid)].general.skill.cid = gdata.skillid
                end
                if gdata.special_skill_reveal and gdata.special_skill_reveal > 0 then
                    self.slotdata[tostring(self.sid)].general.skill.cid = gdata.special_skill_reveal
                end
                self.slotdata[tostring(self.sid)].general.skill.quality = data.general.quality
            end
        else
            local configGeneral = gamedata.config.general[tostring(data.general.cid)]
            local gdata = ui.getConfigGeneral(data.general)
            if next(gdata) and configGeneral.fashion_id == 0 then
                if gdata.skillid and gdata.skillid > 0 then
                    self.slotdata[tostring(self.sid)].general.skill.cid = gdata.skillid
                end
                if gdata.special_skill_reveal and gdata.special_skill_reveal > 0 then
                    self.slotdata[tostring(self.sid)].general.skill.cid = gdata.special_skill_reveal
                end
                self.slotdata[tostring(self.sid)].general.skill.quality = data.general.quality
            end
        end
        ui.setSkillIcon(self.slotdata[tostring(self.sid)].general.skill,self.addedGroup["equip"].items)
        ui.setSkillIcon(data.general.combskill,self.addedGroup["equip"].items,1)
    else
        ui.setSkillIcon(nil,self.addedGroup["equip"].items)
        ui.setSkillIcon(nil,self.addedGroup["equip"].items,1)
    end
end

function slotsInfo.reloadStone(self)
    if not self.addedGroup["stone"] then return end
    local data = self.slotdata[tostring(self.sid)]
    self.selectStoneIndex ,self.selectStoneLevel = 1,1
    for i = 1, 8 do
        if data["g"..i] < data["g1"] then
            self.selectStoneIndex = i
            self.selectStoneLevel = data["g"..i]
            break
        end
    end
    if self.selectStoneIndex == 1 and self.selectStoneLevel == 1 then
        self.selectStoneLevel = data["g1"]
    end
    for i = 1, 8 do
        ui.setStoneIcon({level=data["g"..i]},self.addedGroup["stone"].items,i-1,i==self.selectStoneIndex,self.changedstone and self.changedstone[tostring(i)])
        self.addedGroup["stone"].items["stoneInfoButon"..(i ~= 1 and ("_"..(i -1)) or "")]:addHandleOfControlEvent(function()
            gameWindows:openWindow("godStoneInfo",{posID = i,level = data["g"..i]},nil)
        end,CCControlEventTouchUpInside)
        self.addedGroup["stone"].items["stoneInfoButon"..(i ~= 1 and ("_"..(i -1)) or "")]:setTouchPriority(-105)
        self.addedGroup["stone"].items["stoneInfoButon"..(i ~= 1 and ("_"..(i -1)) or "")]:setSwallowsTouch(true)        
    end
    self.changedstone = nil

    if guide.controller then
        guide.controller:NewSystem(3)
    end
    guide.controller:addComplete(3,function()
        UIRequest({type = 2882,opt=1,sysID=3})
    end)
end

function slotsInfo.reloadGroup(self)
    if self.status == "equip" then
        self:reloadEquip()
        self:reloadSkill()
    elseif self.status == "soul" then
        self:reloadSouls()
    elseif self.status == "stone" then
        self:reloadStone()
    end
end

function slotsInfo.reloadDataGeneral(self)
    if not self.addedDataNode["general"] then return end

    local data = self.slotdata[tostring(self.sid)]
    local item = self.addedDataNode["general"].items

    if GameScene:checkopenlevelbyId(449,true) then
        item.changeAttrNode:setVisible(true)
    else
        self.attrStatus = "fan"
        item.changeAttrNode:setVisible(false)
    end

    local tag = ""
    if self.attrStatus == "fan" then
        item.fan:setVisible(true)
        item.xian:setVisible(false)
        
        item.g_hpSp:setVisible(false)
        item.g_atkSp:setVisible(false)
        item.g_defSp:setVisible(false)
        item.g_speedSp:setVisible(false)

        item.hpSp:setVisible(true)
        item.atkSp:setVisible(true)
        item.defSp:setVisible(true)
        item.speedSp:setVisible(true)
    elseif self.attrStatus == "xian" then
        item.fan:setVisible(false)
        item.xian:setVisible(true)
        tag = "g_"

        item.g_hpSp:setVisible(true)
        item.g_atkSp:setVisible(true)
        item.g_defSp:setVisible(true)
        item.g_speedSp:setVisible(true)

        item.hpSp:setVisible(false)
        item.atkSp:setVisible(false)
        item.defSp:setVisible(false)
        item.speedSp:setVisible(false)
    end


    item.atklab:setString(gameConfig.strings.attr_type[tag.."atk"].."：")
    item.defenselab:setString(gameConfig.strings.attr_type[tag.."def"].."：")
    item.hplab:setString(gameConfig.strings.attr_type[tag.."hp"].."：")

    if next(data) and data.general then
        local configdata = gamedata.config.general[tostring(data.general.cid)] or {}

        if self.attrStatus == "fan" then

            item.atk:setString(data.general["atk"])
            item.hp:setString(data.general["hp"])
            item.defense:setString(data.general["defense"])
        else
             --凡属性转换仙属性折算比例
            -- local every_fairy_turn = gamedata.config.global_kv.every_fairy_turn.value
            -- item.atk:setString(math.floor(data.general["g_atk"] + data.general["atk"] * every_fairy_turn))
            -- item.hp:setString(math.floor(data.general["g_hp"] + data.general["hp"] * every_fairy_turn))
            -- item.defense:setString(math.floor(data.general["g_defense"] + data.general["defense"] * every_fairy_turn))

            item.atk:setString(data.general["g_atk"])
            item.hp:setString(data.general["g_hp"])
            item.defense:setString(data.general["g_defense"])
        end

        item.speed:setString(data.general.speed)
        for i = 1, 6 do
            if data.relation[tostring(i)] and data.relation[tostring(i)].activate >1 then
                ui.setLabelString(item["yuan"..tostring(i)],configdata["cond"..tostring(i).."name"] or " ",31,28)
            else
                ui.setLabelString(item["yuan"..tostring(i)],configdata["cond"..tostring(i).."name"] or " ",29,28)
            end

            item["yuanbtn_"..i]:setTouchPriority(-104)
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
            item["yuanbtn_"..i]:setTouchPriority(-104)
            item["yuanbtn_"..i]:setSwallowsTouch(true)
            item["yuanbtn_"..i]:setVisible(true)
            item["yuanbtn_"..i]:addHandleOfControlEvent(function()
                
            end,CCControlEventTouchUpInside)
        end
    end



end

function slotsInfo.reloadDataStone(self)
    printT(self.addedGroup)
    if not self.addedDataNode["stone"] then return end
    local data = self.slotdata[tostring(self.sid)]

    for i=1,8 do
        local key = gamedata.config.godstone[tostring(i)].attribute

        local number = 0
        if data["g"..i] >0 then
            number = gamedata.config.godstonestrengthening[tostring(data["g"..i])][key]
            if number < 1 then
                number = (number*100).."%"
            end
        end
        if self.addedDataNode["stone"].items[key] then
            self.addedDataNode["stone"].items[key]:setString("+ "..number)
        end
    end
    UIRequest({type = 12001,order = 11301,cids = {20223}})
end

function slotsInfo.setStoneFragment(self,data)
    local stone = data["20223"] or 0
    self.addedDataNode["stone"].items.buyGodStone:addHandleOfControlEvent(function()
        gameWindows:openWindow("dropTips",{cid = 20223,num = stone},nil)
    end, CCControlEventTouchUpInside)
    self.addedDataNode["stone"].items.buyGodStone:setTouchPriority(-104)
    self.addedDataNode["stone"].items.buyGodStone:setSwallowsTouch(true)
    local needStoneNum = 0
    if gamedata.config.godstonestrengthening[tostring(self.selectStoneLevel + 1)] then
        needStoneNum = gamedata.config.godstonestrengthening[tostring(self.selectStoneLevel+1)][self.indexToTableKey[self.selectStoneIndex]]
    end
    if stone >= needStoneNum then
        ui.setLabelString(self.addedDataNode["stone"].items.stonenum,stone.."/"..needStoneNum,3)
    else
        ui.setLabelString(self.addedDataNode["stone"].items.stonenum,stone.."/"..needStoneNum,11)
    end
    self.addedDataNode["stone"].items.stoneNumIcon:setPositionX(self.addedDataNode["stone"].items.stonenum:getPositionX()-self.addedDataNode["stone"].items.stonenum:getContentSize().width)
end

function slotsInfo.reloadBottomData(self)
    if self.datastatus == "general" then
        self:reloadDataGeneral()
    elseif  self.datastatus == "stone" then
        self:reloadDataStone()
    end

end

function slotsInfo.setpagedata(self,item,data)

    if item.illusionDescNode then
        item.illusionDescNode:setVisible(false)
    end

    if next(data) and data.general then
        local configdata = gamedata.config.general[tostring(data.general.illusionGeneralCid or data.general.cid)] or {}
        local expconfigdata = gamedata.config.general_exp[tostring(data.general.level1)] or {}

        local fixbasicstr = "basic"
        if configdata.quality and configdata.quality == 6 then
            fixbasicstr = "red_basic"
        elseif configdata.quality and configdata.quality >= 7 then
            fixbasicstr = "gold_basic"    
        end
        -- local basic = (configdata.basic  and configdata.basic or 0 ) + (configdata.grow and configdata.grow or 0)
        local basic = (configdata.basic > self.awakenConfig[tostring(data.general.skilllevel)][fixbasicstr]  or data.general.skilllevel <= 0 ) and configdata.basic or self.awakenConfig[tostring(data.general.skilllevel)][fixbasicstr]
        local power = tostring(data.general.power or 0)
        local name = tostring(configdata.name or ' ')
        local lv = tostring(data.general.level1 or 1)
        local exp = tostring(data.general.exp or 0)
        local region = tostring(configdata.region or ' ')
        local lv2 = tostring(data.general.level2 or 0)
        local nextexp = 0
        if configdata.actor and configdata.actor == "lead" then
            nextexp = tostring(expconfigdata["exp"] or 0)
        else
            nextexp = tostring(expconfigdata[tostring(configdata.quality).."exp"] or 0)
        end
        ui.setLabelString(item.basic,"资质: "..basic,22)
        -- item.basic:setPositionX(-300) 

        if data.general.iid == GameScene.protagonist.iid and data.general.skilllevel > 0 then
            item.juexing:setVisible(true)
            setSpriteFrameByName(item.juexing_icon,  gamedata.config.protagonist_awaken[tostring(data.general.skilllevel)].icon )
            ui.setLabelString(item.juexing_name, gamedata.config.protagonist_awaken[tostring(data.general.skilllevel)].stage,18)
        elseif configdata.awaken > 0 and data.general.skilllevel > 0 then
            item.juexing:setVisible(true)
            setSpriteFrameByName(item.juexing_icon,  self.awakenConfig[tostring(data.general.skilllevel)].icon )
            ui.setLabelString(item.juexing_name, self.awakenConfig[tostring(data.general.skilllevel)].stage,18)
        else
            item.juexing:setVisible(false)
        end

        item.lv:setString(lv)

        item.exp:setString(math.floor(exp/nextexp*100).."%")

        ui.setSpriteTextureRect2(item.jingyantiao,0,0,415 * exp / nextexp, item.jingyantiao:getContentSize().height)
        ui.removeGray("CCSprite",self.rootItems.safemask_sprite)
        if data.general.iid == GameScene.protagonist.iid then
            local nowlvconfig = gamedata.config.wing_stage[tostring(GameScene.protagonist.w_l)] or {}
            basic = configdata.basic
            ui.setLabelString(item.basic,"资质: "..(basic+(nowlvconfig["effect"..5] or 0)),22)
            
            if configdata.quality and configdata.quality >= 7 then
                ui.setLabelString(item.name,ui.leadName(GameScene.protagonist.level2), 213)
            else
                ui.setLabelString(item.name,ui.leadName(GameScene.protagonist.level2), configdata.quality and 2*configdata.quality-1 or 1)
            end    

            

            self.rootItems.shenqinode:setVisible(false)

            --
            if self.rootItems.fashionButton then
                if self.rootItems.hint_fashion then
                    self.rootItems.hint_fashion:setVisible(false)
                end

                self.rootItems.fashionButton:setVisible(false)
                self.rootItems.fashionButton:setSwallowsTouch(true)
                self.rootItems.fashionButton:setTouchPriority(-103)
                self.rootItems.fashionButton:addHandleOfControlEvent(function()
                end, CCControlEventTouchUpInside)
            end    

            
        else
            if configdata.quality and configdata.quality >= 7 then
                ui.setLabelString(item.name,name..(data.general.level2>0 and " +"..data.general.level2 or ""), 213)
            else
                ui.setLabelString(item.name,name..(data.general.level2>0 and " +"..data.general.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
            end    

            if data.general.illusionGeneralCid then
                item.illusionDescNode:setVisible(true)
                local _generalConfig = gamedata.config.general[tostring(data.general.cid)]
                local str = "("..string.format(gameConfig.strings:string_common("huanhua",6), _generalConfig.name)..(data.general.illusion.attrWeaken > 0 and "  "..gameConfig.strings:string_common("huanhua",7)..data.general.illusion.attrWeaken.."%" or "")..")"
                if configdata.quality and configdata.quality >= 7 then
                    ui.setLabelString(item.illusionDescLab,str, 213,29)
                else
                    ui.setLabelString(item.illusionDescLab,str, configdata.quality and 2*configdata.quality-1 or 1,29)
                end
            end
            

            self.rootItems.shenqinode:setVisible(configdata.quality>=6 and gameConfig:checkBuildOpen(363))
            if configdata.quality>=6 and gameConfig:checkBuildOpen(363) then
                ui.setShenqiIcon(self.rootItems,data.general)
            end

            --
            if self.rootItems.fashionButton then
                if self.rootItems.hint_fashion then
                    self.rootItems.hint_fashion:setVisible(false)
                end  
                self.rootItems.fashionButton:setVisible(false)
                if gameConfig:checkBuildOpen(444) then
                    if configdata.breach_upper_limit > 10 then
                        self.rootItems.fashionButton:setVisible(true)
                    end
                    if configdata.fashion_image and configdata.fashion_image ~= "" then
                        self.rootItems.fashionButton:setVisible(true)
                    end
                    self.rootItems.fashionButton:setSwallowsTouch(true)
                    self.rootItems.fashionButton:setTouchPriority(-103)
                    self.rootItems.fashionButton:addHandleOfControlEvent(function()
                        local gcid = data.general.illusionGeneralCid or data.general.cid
                        savePartnerfashionOnceToSqlite(data.general.cid,0)
                        gameWindows:openWindow("partner_fashion",{cid = gcid, iid = data.general.iid or 0, general = data.general},nil)
                        -- 皮肤红点
                        if getPartnerfashionOnceFromSqlite(data.general.cid) == 1 then
                            self.rootItems.hint_fashion:setVisible(true)
                        else
                            self.rootItems.hint_fashion:setVisible(false)
                        end
                        -- 时装红点
                        local o_cid = data.general.cid
                        if gamedata.config.general[tostring(o_cid)] and gamedata.config.general[tostring(o_cid)].partner_id and gamedata.config.general[tostring(o_cid)].partner_id > 0 then
                            o_cid = gamedata.config.general[tostring(o_cid)].partner_id
                        end  
                        for k,v in pairs(gamedata.config.partner_fashion) do
                            if (v.orange_partner2 == o_cid) or (v.red_partner2 == o_cid) or (v.gold_partner2 == o_cid) then
                                if getPartnerfashionOnceFromSqlite(v.fashion_id) == 1 then
                                    self.rootItems.hint_fashion:setVisible(true)
                                    break
                                end 
                            end    
                        end
                    end, CCControlEventTouchUpInside)
                    --
                    if self.rootItems.hint_fashion then
                        -- 皮肤红点
                        if getPartnerfashionOnceFromSqlite(data.general.cid) == 1 then
                            self.rootItems.hint_fashion:setVisible(true)
                        else
                            self.rootItems.hint_fashion:setVisible(false)
                        end
                        -- 时装红点
                        local o_cid = data.general.cid
                        if gamedata.config.general[tostring(o_cid)] and gamedata.config.general[tostring(o_cid)].partner_id and gamedata.config.general[tostring(o_cid)].partner_id > 0 then
                            o_cid = gamedata.config.general[tostring(o_cid)].partner_id
                        end  
                        for k,v in pairs(gamedata.config.partner_fashion) do
                            if (v.orange_partner2 == o_cid) or (v.red_partner2 == o_cid) or (v.gold_partner2 == o_cid) then
                                if getPartnerfashionOnceFromSqlite(v.fashion_id) == 1 then
                                    self.rootItems.hint_fashion:setVisible(true)
                                    break
                                end 
                            end    
                        end
                    end
                    --
                end        
            end    
        end

        if not gameConfig.images[configdata.actor] then
            setSpriteFrameByName(item["type"], gameConfig.images.alpha)
        else
            setSpriteFrameByName(item["type"], gameConfig.images[configdata.actor])
        end

        self.rootItems.powerTotal:setString("战力: "..data.general.power)

        --safemask
        if gameConfig:checkBuildOpen(209) and GameScene:checkopenlevelbyId(209,true) then
            local config = gamedata.config.mozhao_break or {}
            local safemask = {sid = 1, level = 0}
            for k,v in pairs(self.safemask) do
                if v.sid == data.sid then
                    safemask = v
                end
            end
            if self.rootItems.safemask_level then
                if gameConfig:checkBuildOpen(330) then
                    ui.setLabelString(self.rootItems.safemask_level,(safemask.level2 or "0").."阶"..safemask.level.."级",14)
                else
                    ui.setLabelString(self.rootItems.safemask_level,safemask.level.."级",14)  
                end
            end
            if self.rootItems.safemask_sprite then
                setSpriteFrameByName(self.rootItems.safemask_sprite, "mozhao"..((config[tostring(safemask.level)] and config[tostring(safemask.level)].quality or 2)-1) )
            end


        else
            if self.rootItems.safemask_level then
                ui.setLabelString(self.rootItems.safemask_level,"",14)
            end
            if self.rootItems.safemask_sprite then
                setSpriteFrameByName(self.rootItems.safemask_sprite, "mozhao1")
            end

            ui.addGray("CCSprite",self.rootItems.safemask_sprite)
        end
    else
        ui.setSpriteTextureRect2(item.jingyantiao,0,0,0,item.jingyantiao:getContentSize().height)
        item.lv:setString(0)
        item.exp:setString("0%")
        ui.setLabelString(item.basic,"资质: 0",22)

        ui.setLabelString(item.name," ",1)

        setSpriteFrameByName(item["type"], gameConfig.images.alpha)

        self.rootItems.powerTotal:setString("战力: 0")
        --safemask
        if self.rootItems.safemask_level then
            ui.setLabelString(self.rootItems.safemask_level,"",14)
        end
        if self.rootItems.safemask_sprite then
            setSpriteFrameByName(self.rootItems.safemask_sprite, "mozhao1")
        end
    end

    self:setArtifactShow()
    self:setExclusiveShow()
    self:xiuLianNodeShow()

    if not next(self.addedGroup) or not next(self.addedDataNode) then
        self:shiftStatus(self.status)
    else
        self:reloadGroup()
        self:reloadBottomData()
        self:shiftButtonStatus()
    end
end

function slotsInfo.changeButtonStatus(self)

    local data = self.slotdata[tostring(self.sid)]
    print("changeButtonStatus")
    ui.removeGray("CCContorlButton",self.rootItems.change)
    ui.sethint(self.rootItems.hint_mogong,false)
    self.rootItems.statusnode_mogong:setPositionX(9999)
    self.rootItems.statusnode_change:setPositionX(215)
    self.rootItems.statusnode_yangcheng:setPositionX(240)

    if next(data) and data.general then

        if data.general.iid == GameScene.protagonist.iid then
            self.rootItems.statusnode_mogong:setPositionX(240)
            self.rootItems.statusnode_change:setPositionX(9999)
            self.rootItems.statusnode_yangcheng:setPositionX(9999)
            self.rootItems.status_mogong:addHandleOfControlEvent(function()
                GameScene:shiftLayer("lead","up")
            end, CCControlEventTouchUpInside)
            self.rootItems.status_mogong:setSwallowsTouch(true)
            self.rootItems.status_mogong:setTouchPriority(-103)

            ui.sethint(self.rootItems.hint_mogong,GameScene.hintdata[tostring(115)] and GameScene.hintdata[tostring(115)] ~= 0)

        else
            self.rootItems.status_change:addHandleOfControlEvent(function()
                local callback = function(selectedData)
                    for k,v in pairs(selectedData) do
                        UIRequest({type = 1003, pos1 = data.sid, iid = v.iid})
                        break
                    end
                end
                gameWindows:openWindow("selectlist",{type = "changegeneral", param = data.general.cid, param2="slot"},callback)
            end, CCControlEventTouchUpInside)
            self.rootItems.status_change:setSwallowsTouch(true)
            self.rootItems.status_change:setTouchPriority(-103)

            self.rootItems.status_yangcheng:addHandleOfControlEvent(function()
                GameScene:shiftLayer("generalup","up",{cid = data.general.cid, page = "up",})
            end, CCControlEventTouchUpInside)
            self.rootItems.status_yangcheng:setSwallowsTouch(true)
            self.rootItems.status_yangcheng:setTouchPriority(-103)

        end
    else
        ui.addGray("CCContorlButton",self.rootItems.change)
        self.rootItems.status_change:addHandleOfControlEvent(function()
            runGamePrompt({msg = "请先上阵新伙伴"})
        end, CCControlEventTouchUpInside)
        self.rootItems.status_change:setSwallowsTouch(true)
        self.rootItems.status_change:setTouchPriority(-103)
    end

end

function slotsInfo.creatxhbdeslist(self,item)
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

            if self.slotdata[tostring(a1+1)].general then
                local data = self.slotdata[tostring(a1+1)]
                local configdata = gamedata.config.general[tostring(data.general.cid)]
                items.generalname:setString(configdata.name)
                for i = 1, 6 do
                    local name = (configdata["cond"..tostring(i).."name"] and configdata["cond"..tostring(i).."name"] ~= "") and configdata["cond"..tostring(i).."name"].."：" or " "
                    items["name"..tostring(i)]:setString(name)
                    items["des"..tostring(i)]:setString(configdata["cond"..tostring(i).."desc"] or " ")
                    items["name"..tostring(i)]:setColor(ccc3(124,120,109))
                    items["des"..tostring(i)]:setColor(ccc3(124,120,109))
                    if data.relation[tostring(i)] then
                        if data.relation[tostring(i)].activate >1  then
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
    self.xiaohuobanListTableView:setTouchPriority(-101)
end

function  slotsInfo.setxhbpagedata(self,item)
    -- printT(self.cheerdata[tostring(1)],"jkp-cheerdata")
    local open = true
    local first = true
    for i=1,8 do
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
        -- printT(self.cheerdata[tostring(i)], "伙伴等级")
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
                gameWindows:openWindow("generalInfoRole",{data = self.cheerdata[tostring(i)], sid = self.maxsid+1, cheersid = i,opt = 3, pagetype = "info"})
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
                        UIRequest({type = 1004, pos1 = cheersid, iid = v.iid})
                        break
                    end
                end
                gameWindows:openWindow("selectlist",{type = "changegeneral",param=nil, param2="cheer" },callback)
            end, CCControlEventTouchUpInside)
            open = false
        else
            self.allPartnerLv = 0
            self.allPartnerBreachLv = 0
            open = false
        end
    end
    print("open", open)

    item.fateNode:setVisible(true)
    item.partnerNode:setVisible(true)
    item.partnerBtn:setTouchPriority(-103)
    item.partnerBtn:setSwallowsTouch(true)
    if GameScene:checkopenlevelbyId(189,true) and open then
        self:onAnimation(item, true)
    end
    item.partnerBtn:addHandleOfControlEvent(function()
        if GameScene:checkopenlevelbyId(189) then
            if open then
                self:onAnimation(item, true)
            else
                runGamePrompt({msg = "助阵位置全部开启且上满小伙伴可激活"})
            end
        end
    end, CCControlEventTouchUpInside)

    if item.attributeNode:isVisible() then
        print("attributeNode")
        self:onCreateXhbAttribute(item)

    else
        print("onPartnerShow")
        self:onPartnerShow(item)

    end
end

function slotsInfo.onPartnerShow(self, item)
    print("onPartnerShow   tabs ",self.tabs)
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

function slotsInfo.onAnimation(self, item)
    print("onAnimation")
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

function slotsInfo.onCreateXhbAttribute(self, item)
    print("onCreateXhbAttribute")
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

    -- printT(partnerAttribute2)
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

    -- printT(partnerAttribute1,"partnerAttribute1===")
    for i=1, 6 do

        -- print("init===",partnerAttribute1[1]["init"..i])
        number1_1, number1_2, number2_1, number2_2 = 0, 0, 0, 0
        if partnerAttribute1[1]["attr"..i] ~= nil then
            --if partnerAttribute1[1]["method"..i] == "value" then
                if partnerAttribute1[1]["init"..i] >= 1 or partnerAttribute1[1]["init"..i] == 0 then
                    number1_1 = partnerAttribute1[1]["init"..i] or 0
                    -- number1_2 = next(partnerAttribute1[2]) and partnerAttribute1[2]["init"..i] or 0    
                    -- print("int===",number1_1)                
                elseif partnerAttribute1[1]["init"..i] > 0 and partnerAttribute1[1]["init"..i] < 1 then
                    number1_1 = partnerAttribute1[1]["init"..i] * 100 .. "%" or 0
                    -- number1_2 = next(partnerAttribute1[2]) and partnerAttribute1[2]["init"..i] * 100 .. "%" or 0      
                    -- print("float===",number1_1)                                
                end

                if next(partnerAttribute1[2]) and (partnerAttribute1[2]["init"..i] >= 1 or partnerAttribute1[2]["init"..i] == 0) then
                    -- number1_1 = partnerAttribute1[1]["init"..i] or 0
                    number1_2 = next(partnerAttribute1[2]) and partnerAttribute1[2]["init"..i] or 0    
                    -- print("int===",number1_2)                
                elseif next(partnerAttribute1[2]) and  partnerAttribute1[2]["init"..i] > 0 and partnerAttribute1[2]["init"..i] < 1 then
                    -- number1_1 = partnerAttribute1[1]["init"..i] * 100 .. "%" or 0
                    number1_2 = next(partnerAttribute1[2]) and partnerAttribute1[2]["init"..i] * 100 .. "%" or 0      
                    -- print("float===",number1_2)
                else
                    number1_2 = nil
                end

            --end
            if partnerAttribute1[1]["attr"..i] == "atk" then
                attribute1 = "攻击："
            elseif partnerAttribute1[1]["attr"..i] == "def" then
                attribute1 = "防御："
            elseif partnerAttribute1[1]["attr"..i] == "hp" then
                attribute1 = "生命："
            end
            if number1_1 then
                item["attributeLab1_" .. i]:setVisible(true)
                ui.setLabelString(item["attributeLab1_" .. i], attribute1 .. number1_1, 13)     
            else
                item["attributeLab1_" .. i]:setVisible(false)
            end
            if number1_2 then
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

function  slotsInfo.setslotgemspagedata(self,item)
    print("setslotgemspagedata")
    local sigilpositionconfig = gamedata.config.sigilposition or {}
    local slotconfig = gamedata.config.general_cheer

    if GameScene.roleinfo.level >= slotconfig["1"] then
        ui.removeGray("CCControlButton",item.toallBtn)
        item.iconLock:setVisible(false)
    else
        ui.addGray("CCControlButton",item.toallBtn)
        item.iconLock:setVisible(true)
    end
    -- 总览界面时，按钮置灰
    if self.toallBtnType == false then
        ui.addGray("CCControlButton",item.toallBtn)
    end

    ui.setMobileShopShow(item.mobieshop,-102,12,true)

    item.toallBtn:setTouchPriority(-102)
    item.toallBtn:setSwallowsTouch(true)
    item.toallBtn:addHandleOfControlEvent(function()
        if GameScene.roleinfo.level >= slotconfig["1"] then
            ui.addGray("CCControlButton",item.toallBtn)
            if self.toallBtnType == false then
                runGamePrompt({msg = "当前界面。"})
            end
            self.toallBtnType = false
            item.alldatanode:setVisible(true)
            item.onedatanode:setVisible(false)
            self:setslotgemsdataall(item)
        else
            runGamePrompt({msg = "未到达开启等级"})
        end
    end, CCControlEventTouchUpInside)

    item.gotomufuBtn:setTouchPriority(-102)
    item.gotomufuBtn:setSwallowsTouch(true)
    item.gotomufuBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("mofulist","up")
        
    end, CCControlEventTouchUpInside)

    --
    ui.setLabelString(item.mofugetlab,nil,21)
    item.mofugetbutton:setTouchPriority(-102)
    item.mofugetbutton:setSwallowsTouch(true)
    item.mofugetbutton:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(140)
    end, CCControlEventTouchUpInside)
    --
    for i = 1,8 do
        item["g_button"..(i>1 and ("_"..i-1) or "")]:setTouchPriority(-102)
        item["g_button"..(i>1 and ("_"..i-1) or "")]:setSwallowsTouch(true)
        item["g_button"..(i>1 and ("_"..i-1) or "")]:addHandleOfControlEvent(function()

            if guide.controller then
                guide.controller:UIComplete(8078)
            end

            if GameScene.roleinfo.level >= slotconfig[tostring(i)] then
                ui.removeGray("CCControlButton",item.toallBtn)
                self.toallBtnType = true
                item.alldatanode:setVisible(false)
                item.onedatanode:setVisible(true)
                self:setslotgemsdataone(item,i)
            else
                runGamePrompt({msg = slotconfig[tostring(i)].."级开启"})
            end
        end, CCControlEventTouchUpInside)
        --


        if GameScene.roleinfo.level >= slotconfig[tostring(i)] then
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

        item["g_notice"..(i>1 and ("_"..i-1) or "")]:removeAllChildrenWithCleanup(true)
        if self.slotgems[tostring(i)].notice then
            local eccb,eitem = CCBReaderLoad("slotsInfo/notice", nil, true, "notice")
            item["g_notice"..(i>1 and ("_"..i-1) or "")]:addChild(eccb)
            setSpriteFrameByName(eitem.notice,"obj_"..self.slotgems[tostring(i)].notice )
        end

    end

   -- self:checkMofuNotice(item)

    if self.select_f == 0 then
        self:setslotgemsdataall(item)
    else
        self:setslotgemsdataone(item,self.select_f)
    end
end

function  slotsInfo.setslotgemsdataall(self,item)
    print("setslotgemsdataall")
    self.select_f = 0

    for i = 1,8 do
        item["selectEffect"..(i>1 and ("_"..i-1) or "")]:removeAllChildrenWithCleanup(true)
    end

    local sigilconfig = gamedata.config.sigil or {}

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

    printT(self.slotgems)

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

    if hasnum > 0 then
        item.nomofu:setVisible(false)
    else
        item.nomofu:setVisible(true)
    end

    local slotconfig = gamedata.config.general_cheer
    if GameScene.roleinfo.level < slotconfig["1"] then
        item.nomofu:setVisible(false)
        item.getmofu:setVisible(false)
    else
        item.getmofu:setVisible(true)
    end
end

function  slotsInfo.setslotgemsdataone(self,item,index)
    print("setslotgemsdataone:"..index)
    self.select_f = index
    item.nomofu:setVisible(false)
    item.getmofu:setVisible(false)

    for i = 1,8 do
        item["selectEffect"..(i>1 and ("_"..i-1) or "")]:removeAllChildrenWithCleanup(true)
    end
    local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
    item["selectEffect"..(self.select_f>1 and ("_"..self.select_f-1) or "")]:addChild(eccb)

    if not self.slotgems[tostring(index)] then return end

    for i = 1,6 do
        if item["upnotice"..i] then
            item["upnotice"..i]:removeAllChildrenWithCleanup(true)
            if self.slotgems[tostring(index)]["up"..i] and self.slotgems[tostring(index)]["up"..i] == 1 then
                local eccb,eitem = CCBReaderLoad("slotsInfo/notice", nil, true, "notice")
                item["upnotice"..i]:addChild(eccb)
                setSpriteFrameByName(eitem.notice,"obj_up3")
            end
        end
    end

    for i = 1,5 do
           if self.slotgems[tostring(index)].data[tostring(i)] and self.slotgems[tostring(index)].data[tostring(i)].iid > 0 then

               local gem = self.slotgems[tostring(index)].data[tostring(i)].data
               gem.temp = ui.IDconfig(self.slotgems[tostring(index)].data[tostring(i)].data.cid)

               item["b_has"..(i>1 and ("_"..i-1) or "")]:setVisible(true)
               item["b_add"..(i>1 and ("_"..i-1) or "")]:setVisible(false)
               setSpriteFrameByName(item["b_icon"..(i>1 and ("_"..i-1) or "")], gem.temp.icon)
               ui.setLabelString(item["b_name"..(i>1 and ("_"..i-1) or "")],gem.temp.name,21)
               ui.setSpriteTextureRect2(item["b_exppos"..(i>1 and ("_"..i-1) or "")],0,0,125*((gem.exp>gem.temp.exp) and 1 or (gem.exp/gem.temp.exp)),14)
               --
               item["b_button"..(i>1 and ("_"..i-1) or "")]:setTouchPriority(-103)
               item["b_button"..(i>1 and ("_"..i-1) or "")]:setSwallowsTouch(true)
               item["b_button"..(i>1 and ("_"..i-1) or "")]:addHandleOfControlEvent(function()
                   print("b_button  has  "..i)
                   if guide.controller then
                        guide.controller:UIComplete(8082)
                   end
                   local slotcb = function(cbtype)
                       if cbtype and cbtype == 1 then
                           local cb = function(data)
                               if data and data[1] then
                                    UIRequest({type = 1141, pos = index*10+i, iid = data[1].iid})
                               end
                           end
                           gameWindows:openWindow("mofuselect",{listtype = i,
                               choosedata = {},
                               infodata = {},
                               selecttype = 2,
                               nolevelup = 1,
                           },cb)
                       end
                   end
                   gameWindows:openWindow("mofuproperty",{infodata = gem,selectlistdata=self.gems,page = "slot"},slotcb)
               end, CCControlEventTouchUpInside)
           else

               item["b_has"..(i>1 and ("_"..i-1) or "")]:setVisible(false)
               item["b_add"..(i>1 and ("_"..i-1) or "")]:setVisible(true)
               --
               if self.slotgems[tostring(index)].data[tostring(i)].has then
                   ui.removeGray("CCSprite",item["b_add"..(i>1 and ("_"..i-1) or "")])
               else
                   ui.addGray("CCSprite",item["b_add"..(i>1 and ("_"..i-1) or "")])
               end
               --
               item["b_button"..(i>1 and ("_"..i-1) or "")]:setTouchPriority(-103)
               item["b_button"..(i>1 and ("_"..i-1) or "")]:setSwallowsTouch(true)
               item["b_button"..(i>1 and ("_"..i-1) or "")]:addHandleOfControlEvent(function()
                   print("b_button  no  "..i)
                   if guide.controller then
                        guide.controller:UIComplete(8082)
                   end
                   local cb = function(data)
                       if data and data[1] then
                           UIRequest({type = 1141, pos = index*10+i, iid = data[1].iid})
                       end
                   end
                   gameWindows:openWindow("mofuselect",{listtype = i,
                       choosedata = {},
                       infodata = {},
                       selecttype = 2,
                       nolevelup = 1,
                   },cb)
               end, CCControlEventTouchUpInside)
           end
    end

    if self.slotgems[tostring(index)].data["6"] and self.slotgems[tostring(index)].data["6"].iid > 0 then
           local gem = self.slotgems[tostring(index)].data["6"].data
           gem.temp = ui.IDconfig(self.slotgems[tostring(index)].data["6"].data.cid)

           item["b_has_w"]:setVisible(true)
           item["b_add_w"]:setVisible(false)
           item["b_lock_w"]:setVisible(false)
           setSpriteFrameByName(item["b_icon_w"], gem.temp.icon)
           ui.setLabelString(item["b_name_w"],gem.temp.name,21)
           ui.setSpriteTextureRect2(item["b_exppos_w"],0,0,125*((gem.exp>gem.temp.exp) and 1 or (gem.exp/gem.temp.exp)),14)
           --
           item["b_button_w"]:setTouchPriority(-103)
           item["b_button_w"]:setSwallowsTouch(true)
           item["b_button_w"]:addHandleOfControlEvent(function()
               print("b_button_w  has")
               if guide.controller then
                    guide.controller:UIComplete(8082)
                end
               local slotcb = function(cbtype)
                   if cbtype and cbtype == 1 then
                       local cb = function(data)
                           if data and data[1] then
                               UIRequest({type = 1141, pos = index*10+6, iid = data[1].iid})
                           end
                       end
                       gameWindows:openWindow("mofuselect",{listtype = 6,
                           choosedata = {},
                           infodata = {},
                           selecttype = 2,
                           nolevelup = 1,
                       },cb)
                   end
               end
               gameWindows:openWindow("mofuproperty",{infodata = gem,selectlistdata=self.gems,page = "slot"},slotcb)
           end, CCControlEventTouchUpInside)
    else

           item["b_has_w"]:setVisible(false)
           --
           if self.slotgems[tostring(index)].data["6"] and self.slotgems[tostring(index)].data["6"].iid == -1 then
               item["b_lock_w"]:setVisible(true)
               item["b_add_w"]:setVisible(false)
           else
               item["b_lock_w"]:setVisible(false)
               item["b_add_w"]:setVisible(true)
               if self.slotgems[tostring(index)].data["6"].has then
                   ui.removeGray("CCSprite",item["b_add_w"])
               else
                   ui.addGray("CCSprite",item["b_add_w"])
               end
           end
           --
           item["b_button_w"]:setTouchPriority(-103)
           item["b_button_w"]:setSwallowsTouch(true)
           item["b_button_w"]:addHandleOfControlEvent(function()
               print("b_button_w  no")
               if self.slotgems[tostring(index)].data["6"] and self.slotgems[tostring(index)].data["6"].iid == -1 then
                   local openlv = gamedata.config.global_kv["6_sigil_requirement"].value or "?"
                   runGamePrompt({msg = "镶嵌5枚"..openlv.."级以上魔符后开启"})
               else
                    if guide.controller then
                        guide.controller:UIComplete(8082)
                   end
                   local cb = function(data)
                       if data and data[1] then
                           UIRequest({type = 1141, pos = index*10+6, iid = data[1].iid})
                       end
                   end
                   gameWindows:openWindow("mofuselect",{listtype = 6,
                       choosedata = {},
                       infodata = {},
                       selecttype = 2,
                       nolevelup = 1,
                   },cb)
               end
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


function slotsInfo.loadPage(self,sid)
    if sid <= self.maxsid+2 and sid>0 then
        if sid <= self.maxsid  then
            if not self.slotdata[tostring(sid)].general then
                if self.generalSkeleton[sid] and self.generalSkeleton[sid].name ~=  "empty" then
                    ui.itemcache:detachskeleton(self.generalSkeleton[sid].name)
                    self.generalSkeleton[sid].r_node:removeFromParentAndCleanup(true)
                    self.generalSkeleton[sid] = nil
                end
                if not self.generalSkeleton[sid] then
                    self.generalSkeleton[sid] = {}
                    self.generalSkeleton[sid].name = "empty"
                    -- self.generalSkeleton[sid].r_node = CCNode:create()
                    -- self.generalSkeleton[sid].node = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("obj_7.png"))
                    -- self.generalSkeleton[sid].node:setAnchorPoint(ccp(0.5,0))
                    -- self.generalSkeleton[sid].node:setScale(2)
                    -- self.generalSkeleton[sid].r_node:addChild(self.generalSkeleton[sid].node)
                    -- self.generalSkeleton[sid].r_node:setPosition(1080*(sid-0.5),100)

                    self.generalSkeleton[sid].r_node,self.generalSkeleton[sid].node = CCBReaderLoad("slotsInfo/weishangzhen", nil, true, "weishangzhen")
                    self.generalSkeleton[sid].r_node:setPosition(1080*(sid-0.5),324)
                    
                    self.rootItems.generalcontainer:addChild(self.generalSkeleton[sid].r_node)
                else
                    self.generalSkeleton[sid].r_node:setVisible(true)
                end
            else
                -- 设置形象
                local configGeneral = gamedata.config.general[tostring(self.slotdata[tostring(sid)].general.illusionGeneralCid or self.slotdata[tostring(sid)].general.cid)]
                local generalName = gamedata.config.generalanimation[tostring(configGeneral.animationid)].name
                if configGeneral.fashion_id == 0 then --非时装
                    if self.slotdata[tostring(sid)].general.illusionGeneralCid then
                        generalName = ui.getGeneralAnimationidSion(generalName, self.slotdata[tostring(sid)].general)
                    else
                        generalName = ui.getGeneralAnimationid(generalName, self.slotdata[tostring(sid)].general)
                    end
                end

                if self.generalSkeleton[sid] and self.generalSkeleton[sid].name ~=  generalName then
                    if self.generalSkeleton[sid].r_node:getChildrenCount() >0 and self.generalSkeleton[sid].name ~= "empty" then
                        ui.itemcache:detachskeleton(self.generalSkeleton[sid].name)
                    end
                    self.generalSkeleton[sid].r_node:removeFromParentAndCleanup(true)
                    self.generalSkeleton[sid] = nil
                end
                if not self.generalSkeleton[sid] then
                    self.generalSkeleton[sid] = {}
                    self.generalSkeleton[sid].name = generalName
                    self.generalSkeleton[sid].r_node = CCNode:create()

                    local wingData = {level=GameScene.protagonist.w_l,color=GameScene.protagonist.w_c}
                    self.generalSkeleton[sid].node = ui.itemcache:attachskeleton(self.generalSkeleton[sid].name, self.generalSkeleton[sid].r_node,wingData)

                    --self.generalSkeleton[sid].node = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
                    self.generalSkeleton[sid].node:setAnimation("stand",true,0)
                    self.generalSkeleton[sid].node:setScale(1.7)
                    --self.generalSkeleton[sid].r_node:addChild(self.generalSkeleton[sid].node)
                    if gamedata.config.general[tostring(self.slotdata[tostring(sid)].general.cid)].name == "主角" then
                        local growconfig = gamedata.config.protagonist_grow or {}
                        local data = GameScene.protagonist
                        local Node11,Item11 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(growconfig[tostring(data.level2+1)] and (math.mod(data.level2,5)+1) or 5), nil, true, "jie")
                        self.generalSkeleton[sid].r_node:addChild(Node11)
                    else
                        ui.addAwakeEffect(self.generalSkeleton[sid].r_node,self.slotdata[tostring(sid)].general.skilllevel,2.2)
                    end

                    self.generalSkeleton[sid].r_node:setPosition(1080*(sid-0.5),100)
                    self.rootItems.generalcontainer:addChild(self.generalSkeleton[sid].r_node)
                else
                    self.generalSkeleton[sid].r_node:setVisible(true)
                end
            end
        elseif sid == self.maxsid+1 then
            if not next(self.cheerPage) then
                self.cheerPage.ccb,self.cheerPage.item = CCBReaderLoad("slotsInfo/slot-xhb.ccbi", nil, true, "slot-xhb")
                self.cheerPage.item.adaptnode:setPositionY((GameScene.topposY-1620)/2)
                self.cheerPage.ccb:setPosition(1080,0)
                self.rootItems.pagenode:addChild(self.cheerPage.ccb)
                self.tabs = 1
                print("resettabs",self.tabs)
                self:setxhbpagedata(self.cheerPage.item)
            end
        elseif sid == self.maxsid+2 then
            if not next(self.slotgemsPage) then
                self.slotgemsPage.ccb,self.slotgemsPage.item = CCBReaderLoad("slotsInfo/slot-baoshi.ccbi", nil, true, "slot-baoshi")
                self.slotgemsPage.item.adaptnode:setPositionY((GameScene.topposY-1620)/2)
                self.slotgemsPage.ccb:setPosition(1080*2,0)
                self.rootItems.pagenode:addChild(self.slotgemsPage.ccb)
                self:setslotgemspagedata(self.slotgemsPage.item)
                self:setSelectList(self.slotgemsPage.item);
                -- 魔符自动合成查询接口说明
                UIRequest({type = 6405})
            end
        end
        if next(self.slotgemsPage) then
            self:resetquicknode("close")
        end
    end
end

function slotsInfo.loadpagesExt(self)
    self:loadPage(self.sid+1)
    self:loadPage(self.sid-1)
end


function slotsInfo.loadpages(self)

    for k,v in pairs(self.generalSkeleton) do
        v.r_node:setVisible(k==self.sid)
    end
    if self.cheerPage.ccb then self.cheerPage.ccb:setVisible(self.sid == self.maxsid or self.sid == self.maxsid +1 or self.sid == self.maxsid +2) end
    --if self.cheerPage.ccb then self.cheerPage.ccb:setVisible(self.sid == 8) end
    if self.slotgemsPage.ccb then self.slotgemsPage.ccb:setVisible(self.sid == self.maxsid +1 or self.sid == self.maxsid +2) end

    self:loadPage(self.sid)
    printT(ui.itemcache.attachedSkeletons)
end

function slotsInfo.setPage(self,page,needReset)
    local oldsid =  self.sid
    self.sid = page
    --self.rootItems.powerTotal:setVisible(self.sid~=self.maxsid+1)
    self.rootItems.powerTotal:setVisible(self.sid~=self.maxsid+1 and self.sid~=self.maxsid+2)
    self.rootItems.nameNode:setVisible(self.sid~=self.maxsid+1 and self.sid~=self.maxsid+2)
    -- todo
    if self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)].general then
    elseif self.sid <= self.maxsid then
       self:shiftStatus("equip")
    end
    --

    if not self.generalListTableView then
        self:reloadGeneralList()
    else
        print("generalListTableView reload")
        self.generalListTableView:reloadData()
    end

    --    if self.sid == self.maxsid +1 then
    --        if self.maxsid <7 then
    --            self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * (self.sid+1),0),0.2)
    --        else
    --            self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * (self.sid),0),0.2)
    --        end
    --    elseif  self.titleCellSize.x * self.sid >  self.rootItems.generalListScroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
    --        self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * self.sid,0),0.2)
    --    elseif self.titleCellSize.x * (self.sid-1) < -self.generalListTableView:getLuaContentOffsetX() then
    --        self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.sid-1) ,0),0.2)
    --    end
    if self.sid == self.maxsid +2 then
        self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * (9),0),0.2)
    elseif self.sid == self.maxsid +1 then
        if self.titleCellSize.x * 8 >  self.rootItems.generalListScroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
            self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * (8),0),0.2)
        end
    elseif  self.titleCellSize.x * self.sid >  self.rootItems.generalListScroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
        self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * self.sid,0),0.2)
    elseif self.titleCellSize.x * (self.sid-1) < -self.generalListTableView:getLuaContentOffsetX() then
        self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.sid-1) ,0),0.2)
    end
    self.rootItems.juexing:setVisible(false)
    if self.sid <= self.maxsid and needReset then
        self:setpagedata(self.rootItems,self.slotdata[tostring(self.sid)])
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


        local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.sid - self.maxsid), 0))
        self.rootItems.pagenode:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
            self:loadpages()
        end)))
    end

    self:setStatusHint()    --装备 命格 神石
    self:setSafemaskHint()  --魔罩
    --print("lipurposes set artifact hint")
    self:setArtifactHint()  --神器

    self:setYangchengHint() --养成

    if self.sid == self.maxsid +2 then
        guide.controller:addComplete(146,function()
            UIRequest({type = 2882,opt=1,sysID=146})
        end)
    elseif self.sid <= self.maxsid then
        if not self.slotdata[tostring(self.sid)].general then
            UIRequest({type = 2882,opt=1,sysID=self.slotdata[tostring(self.sid)].sid+51})
        end
    end
end

function slotsInfo.reorderData(self)

    local temp = nil
    for i=1,self.maxsid do

        if self.slotdata[tostring(i)].general and self.slotdata[tostring(i)].general.iid == GameScene.protagonist.iid then
            --主阵容主角固定放第一位,  导致封神赛阵容显示顺序需要自己还原,故 存了主角的阵容index
            UIRequest({type = 825200,godCompetionSlotIndex = i})
            print("slotsInfo.reorderData i:----------",i)
            self.slotdata["1"] = self.slotdata[tostring(i)]
            self.slotdata[tostring(i)] = temp or self.slotdata[tostring(i)]
            break
        else
            local temp_ = self.slotdata[tostring(i)]
            self.slotdata[tostring(i)] = temp
            temp = temp_
        end
    end
end

function slotsInfo.setSlotData(self,slots)
    if slots then
        self.slotdata = slots
        self.arrangedata = table.copy(self.slotdata)
    end
    self.maxsid = table.getTableLength(self.slotdata)
    self.arrangedata = self.arrangedata or table.copy(self.slotdata)
    self:reorderData()
    print("self.maxsid",self.maxsid)
end

function slotsInfo.getGeneralIson(self,iid)
    local general = nil
    --更新神器数据
    for k,v in pairs(self.slotdata) do
        if v.general and v.general.iid == iid then
            general = table.copy(v.general)
            break
        end
    end
    return general
end

function slotsInfo.setExclusiveArtifactData(self,data,reset)
    if reset then
        self.exclusiveArtifactData = {}
    end
    
    if data then
        for k,v in pairs(data) do
            self.exclusiveArtifactData[v.generalIid] = v
        end
    end
end


function slotsInfo.setExclusiveShow(self)
    self:setExclusiveHint()
    if not (gameConfig:checkBuildOpen(611) and GameScene:checkopenlevelbyId(611,true)) then
        self.rootItems.exclusiveArtifactNode:setVisible(false)
        return
    end
    self.rootItems.zhuanshu:removeAllChildrenWithCleanup(true)
    self.rootItems.exclusiveArtifactNode:setVisible(false)
    local general = self.slotdata[tostring(self.sid)].general
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

function slotsInfo.artifactEquipSuccess(self,slotdata)
    self.arrangedata[tostring(slotdata.sid)].newartifact = slotdata.newartifact
    for k,v in pairs(self.slotdata) do
        if v.sid == slotdata.sid then
            v.newartifact = slotdata.newartifact
            break
        end
    end
    if GameScene.layers["slotsInfo"].show then
        self:setArtifactShow()
    end
end

function slotsInfo.setArtifactShow(self)
    self.rootItems.artifact:setVisible(gameConfig:checkBuildOpen(366) and GameScene:checkopenlevelbyId(366,true))
    local data = self.slotdata[tostring(self.sid)]
    if data.newartifact and type(data.newartifact) == "table" then
        self.rootItems.artifactSp:setVisible(false)
        local artifactConfig = gamedata.config.trump[tostring(data.newartifact.cid)]
        --setSpriteFrameByName(self.rootItems.artifactSp,artifactConfig.icon)
        self.rootItems.artifactSp:stopAllActions()
        --self.rootItems.artifactSp:setOpacity(255)
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
        --setSpriteFrameByName(self.rootItems.artifactSp, "obj_add")
        self.rootItems.artifactSpine:removeAllChildrenWithCleanup(true)
        self.rootItems.artifactSp:setVisible(true)
        if data["hashint_artifact"] then
            ui.blink(self.rootItems.artifactSp,1.5)
        else
            self.rootItems.artifactSp:stopAllActions()
            self.rootItems.artifactSp:setOpacity(255)
        end
    end
end

function slotsInfo.xiuLianNodeShow(self)
    local isShow = true
    local general,generalConfig
    if self.slotdata[tostring(self.sid)].general then
        general = self.slotdata[tostring(self.sid)].general
        generalConfig = gamedata.config.general[tostring(general.cid)]
        if not gameConfig:checkBuildOpen(378)  then
            isShow = false
        elseif  not GameScene:checkopenlevelbyId(378,true) then 
            isShow = false
        elseif general.iid == GameScene.protagonist.iid then
            isShow = false
        elseif generalConfig.quality < 3 then
            isShow = false
        end
    else
        isShow = false
    end
    self.rootItems.xiuLianNode:setVisible(isShow)
    if not isShow then
        return
    end
    ui.setLabelString(self.rootItems.xiuLian1,""..general.level6,61)
    ui.setLabelString(self.rootItems.xiuLian2,""..general.level7,61)
end


function slotsInfo.checkrelation(self)
    --
    local relationtemp = {}

    if not self.oldrelation then
        self.oldrelation = self.slotdata
        return
    end

    for k,v in pairs(self.slotdata) do
        if v.general and v.general.cid then
            local configdata = gamedata.config.general[tostring(v.general.cid)] or {}
            if v.relation then
                for k1,v1 in pairs(v.relation) do
                    if v1.activate == 2 then
                       local isnew = true
                       for k2,v2 in pairs(self.oldrelation) do
                           if v2.general and v2.general.cid and v2.general.cid == v.general.cid and v2.relation[tostring(k1)].activate == 2 then
                               isnew = false
                           end
                       end

                       --if self.oldrelation[tostring(k)] and self.oldrelation[tostring(k)].relation and self.oldrelation[tostring(k)].relation[tostring(k1)] and self.oldrelation[tostring(k)].relation[tostring(k1)].activate and self.oldrelation[tostring(k)].relation[tostring(k1)].activate == 2 then
                       --elseif self.oldrelation[tostring(k)] and self.oldrelation[tostring(k)].general and self.oldrelation[tostring(k)].general.cid ~= v.general.cid then
                       --else
                           if isnew and not relationtemp[tostring(configdata["cond"..tostring(k1).."name"])] then
                                relationtemp[tostring(configdata["cond"..tostring(k1).."name"])] = 1
                                local rnum = table.getTableLength(relationtemp) or 1
                                self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5*rnum),CCCallFunc:create(function()
                                    --runGamePrompt({msg = "激活缘分 \""..configdata["cond"..tostring(k1).."name"].."\""})
                                    runGamePromptSkill({type = "relation", name = configdata["cond"..tostring(k1).."name"]})
                                end)))
                           end
                       --end

                    end
                end
            end
        end
    end

    for k,v in pairs(self.slotdata) do
        if v.general and v.general.cid then
            if v.general.combskillstatus and v.general.combskillstatus == 2 then
                local configdata = gamedata.config.general[tostring(v.general.cid)] or {}
                local combskillconfig = gamedata.config.combskill[tostring(v.general.combskill and v.general.combskill.cid or 0)] or {}
                local isnew = true
                for k2,v2 in pairs(self.oldrelation) do
                    if v2.general and v2.general.cid and v2.general.cid == v.general.cid and v2.general.combskillstatus and v2.general.combskillstatus == 2 then
                        isnew = false
                    end
                end

                if isnew and not relationtemp[tostring(combskillconfig["name"])] then
                    relationtemp[tostring(combskillconfig["name"])] = 1
                    local rnum = table.getTableLength(relationtemp) or 1
                    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5*rnum),CCCallFunc:create(function()
                    --runGamePrompt({msg = "激活合体技 \""..combskillconfig["name"].."\""})
                        runGamePromptSkill({type = "skill", name = combskillconfig["name"]})
                    end)))
                end
            end
        end
    end

    self.oldrelation = self.slotdata
end


function slotsInfo.reload(self,slots,cheers,slotgems,gems)
    if slots then
        self:setSlotData(slots)
    end
    if cheers then
        self.cheerdata = cheers
    end
    if slotgems then
        self.slotgems = slotgems
    end
    if gems then
        self.gems = gems
    end

    self.quickequip = {}
    self.quicksoul = {}

    if tostring(self.sid) == "cheer" then
        self.sid = self.maxsid +1
    elseif tostring(self.sid) == "mofu" then
        self.sid = self.maxsid +2
    elseif self.sid > self.maxsid+1  then
        self.sid = self.maxsid +2
    end

    --    self.powertotal = 0
    --    for k,v in pairs(self.slotdata) do
    --        self.powertotal = self.powertotal + v.power
    --    end
    --    -- self.rootItems.powerTotal:setString("总战力: "..self.powertotal)
    --    self.rootItems.powerTotal:setString(gameConfig.strings:TolPower(self.powertotal))

    if next(self.cheerPage) then
        self:setxhbpagedata(self.cheerPage.item)
    end

    if next(self.slotgemsPage) then
        self:setslotgemspagedata(self.slotgemsPage.item)
    end

    self:loadpages()
    self:setPage(self.sid,true)

    self:checkrelation()

end

function slotsInfo.clear(self)

    self.select_f = 0
    self.generalListTableView = nil
    self.xiaohuobanListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.addedGroup = {}
    self.addedDataNode = {}

    self.status = "equip"
    self.datastatus = "general"
    self.slotgemsPage = {}
    self.cheerPage = {}
    self.generalSkeleton = {}

    self.quickequip = {}
    self.quicksoul = {}

    self.changedequip = {}

    self.rootNode = nil
    self.rootItems = nil
    self.selectStoneIndex = 1
    self.selectStoneLevel = 1
    self.toallBtnType = false
end

function slotsInfo.reloadGeneralList(self,alldata)
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

            --            if a1+1<= self.maxsid then
            --                ui.setSlotGeneralIcon(self.slotdata[tostring(a1+1)],ccbDocumentControler)
            --
            --                if a1+1 == self.sid then
            --                    --cellCCB:setScale(1)
            --                    local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
            --                    ccbDocumentControler.selectEffect:addChild(eccb)
            --                end
            --            elseif a1+1 == self.maxsid+1 then
            --                if self.maxsid<7 then
            --                    local slotconfig = gamedata.config.general_slot
            --                    local nextlevel = slotconfig[tostring(a1+1)]
            --                    ui.setSlotGeneralIcon({openlevel = nextlevel},ccbDocumentControler)
            --                else
            --                    ui.setxiaohuobanIcon(ccbDocumentControler,self.cheerdata)
            --                    if self.sid == a1+1 then
            --                        --cellCCB:setScale(1)
            --                        local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
            --                        ccbDocumentControler.selectEffect:addChild(eccb)
            --                    end
            --                end
            --            elseif a1+1== self.maxsid+2 then
            --                ui.setxiaohuobanIcon(ccbDocumentControler,self.cheerdata)
            --                if self.sid+1 == a1+1 then
            --                    --cellCCB:setScale(1)
            --                    local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
            --                    ccbDocumentControler.selectEffect:addChild(eccb)
            --                end
            --            end



            if  a1+1 <= 7 then
                if a1+1 <= self.maxsid then
                    -- 设置头像
                    local generalData = self.slotdata[tostring(a1+1)] or {}
                    if generalData.general then
                        if generalData.general.illusionGeneralCid then
                            local configGeneral = gamedata.config.general[tostring(generalData.general.illusionGeneralCid)]
                            local gdata = ui.getConfigGeneralSion(generalData.general)
                            if next(gdata) and configGeneral.fashion_id == 0 then
                                ui.setSlotGeneralIcon(generalData,ccbDocumentControler,0,gdata)
                            else
                                ui.setSlotGeneralIcon(generalData,ccbDocumentControler)
                            end
                        else
                            local configGeneral = gamedata.config.general[tostring(generalData.general.cid)]
                            local gdata = ui.getConfigGeneral(generalData.general)
                            if next(gdata) and configGeneral.fashion_id == 0 then
                                ui.setSlotGeneralIcon(generalData,ccbDocumentControler,0,gdata)
                            else
                                ui.setSlotGeneralIcon(generalData,ccbDocumentControler)
                            end
                        end
                    else
                        ui.setSlotGeneralIcon(self.slotdata[tostring(a1+1)],ccbDocumentControler)
                    end

                    if guide.controller:isNewSystemByid(462) and GameScene:checkopenlevelbyId(462,true) then
                        ui.sethint(ccbDocumentControler.g_hint,true)
                    end

                    if self.sid == a1+1 then
                        local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                        ccbDocumentControler.selectEffect:addChild(eccb)
                    end
                    --
                    if gameConfig:checkBuildOpen(444) then
                        if self.slotdata[tostring(a1+1)] and self.slotdata[tostring(a1+1)].general and self.slotdata[tostring(a1+1)].general.cid then
                            local o_cid = self.slotdata[tostring(a1+1)].general.cid
                            if gamedata.config.general[tostring(o_cid)] and gamedata.config.general[tostring(o_cid)].partner_id and gamedata.config.general[tostring(o_cid)].partner_id > 0 then
                                o_cid = gamedata.config.general[tostring(o_cid)].partner_id
                            end    
                            for k,v in pairs(gamedata.config.partner_fashion) do
                                if (v.orange_partner2 == o_cid) or (v.red_partner2 == o_cid) or (v.gold_partner2 == o_cid) then
                                    if getPartnerfashionOnceFromSqlite(v.fashion_id) == 1 then
                                        ui.sethint(ccbDocumentControler["g_hint"],true)
                                        break
                                    end 
                                end    
                            end 
                            -- 皮肤红点
                            if getPartnerfashionOnceFromSqlite(self.slotdata[tostring(a1+1)].general.cid) == 1 then
                                ui.sethint(ccbDocumentControler["g_hint"],true)
                            end
                        end   
                    end

                    if  GameScene:checkopenlevelbyId(611,true) then
                        if self.slotdata[tostring(a1+1)] and self.slotdata[tostring(a1+1)].general and self.slotdata[tostring(a1+1)].general.cid then
                            if self.slotdata[tostring(a1+1)].general.hashint_exclusive then
                                ui.sethint(ccbDocumentControler["g_hint"],true)
                            end
                        end
                    end
                    --
                else
                    local slotconfig = gamedata.config.general_slot
                    local nextlevel = slotconfig[tostring(a1+1)]
                    ui.setSlotGeneralIcon({openlevel = nextlevel},ccbDocumentControler)
                end
            elseif a1+1 == 8 then
                ui.setxiaohuobanIcon(ccbDocumentControler,self.cheerdata)
                if self.sid == self.maxsid+1 then
                    local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                    ccbDocumentControler.selectEffect:addChild(eccb)
                end
            elseif a1+1 > 8 then
                ui.setslotgemsIcon(ccbDocumentControler)
                if self.sid == self.maxsid+2 then
                    local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                    ccbDocumentControler.selectEffect:addChild(eccb)
                end
            end

            if self.generalListTableView then
                cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = 9 --self.maxsid<7 and self.maxsid +2 or self.maxsid +1
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            guide:setGuideProlayer(true)
            --            if a1:getIdx()+1 <= self.maxsid then
            --                self:setPage(a1:getIdx()+1,true)
            --            elseif a1:getIdx()+1 == self.maxsid+1 then
            --                if self.maxsid<7 then
            --
            --                else
            --                    self:setPage(a1:getIdx()+1)
            --                end
            --            elseif a1:getIdx()+1== self.maxsid+2 then
            --                self:setPage(a1:getIdx())
            --            end

            if  a1:getIdx()+1 <= 7 then
                if a1:getIdx()+1<= self.maxsid then
                    self:setPage(a1:getIdx()+1,true)
                else

                end
            elseif a1:getIdx()+1 == 8 then
                self:setPage(self.maxsid+1)
            elseif a1:getIdx()+1 > 8 then
                self:setPage(self.maxsid+2)
            end

            if guide.controller then
                guide.controller:UIComplete(8030)
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
    self.generalListTableView:setTouchPriority(-102)
end

function slotsInfo.setChangedEquip(self,data,nums)
    printT(data)
    printT(nums)
    for k,v in pairs(data) do
        if v.iid then
            self.changedequip[v.iid] = nums[tostring(v.iid)] or 0
        end
    end
end

function slotsInfo.UIUpdateData(self,isreset)
    GameScene:checkUpdate(10021)
    GameScene:checkUpdate(10022)
    GameScene:checkUpdate(10028)
end

function slotsInfo.setSelectList(self,item)
    self.quickNode1,self.quickItems = CCBReaderLoad("slotsInfo/cell_button1_mofu", nil, true, "cell_button1_mofu")
    item.quicknode:addChild(self.quickNode1) 

    if item.carryonShop then
       item.carryonShop:setVisible(false)--随身商店屏蔽
    end    

    self.quickani = getAnimationManager(self.quickItems)
    -- print("  self.resolvequality  ",self.resolvequality)
    
    if self.quickItems["q_node"..(self.resolvequality)] then
        self.quickItems["q_node"..(self.resolvequality)]:setZOrder(1)
    end

    for i=5,9 do
        local yu = math.fmod( i, 5 )    -- 取余数
        local currentindex = i+yu
        self.quickItems["q_button"..currentindex]:setSwallowsTouch(true)
        self.quickItems["q_button"..currentindex]:setTouchPriority(self.resolvequality == (currentindex) and -107 or -106)
        self.quickItems["q_button"..currentindex]:addHandleOfControlEvent(function()
            print("q_button ----",currentindex)
            print("  self.quickstatus   ",self.quickstatus)
            print("  self.resolvequality   ",self.resolvequality)
            if self.quickstatus == true then
                if currentindex == self.resolvequality then
                     print("等级相同")
                     self.quickstatus = not self.quickstatus
                     self:resetquicknode(self.quickstatus and "open" or "close")
                    return
                end  
                self.resolvequality = currentindex
                self.quickstatus = not self.quickstatus
                self:resetquicknode(self.quickstatus and "open" or "close")
                if self.selectState == 1 then
                    UIRequest({type = 6406,autoState = self.selectState,autoLevel = self.resolvequality})
                end
            else
                self.quickstatus = not self.quickstatus
                self:resetquicknode(self.quickstatus and "open" or "close")
            end
        end, CCControlEventTouchUpInside)
    end

    self.quickItems.selectSp2:setVisible(false);

    self.quickItems.selectUse:setSwallowsTouch(true)
    self.quickItems.selectUse:setTouchPriority(-106)
    self.quickItems.selectUse:addHandleOfControlEvent(function()
        if self.selectState == 1 then
            self.selectState = 0
            self.quickItems.selectSp2:setVisible(false);
            UIRequest({type = 6406,autoState = self.selectState,autoLevel = self.resolvequality})
            print("self.resolvequality:"..self.resolvequality)

        else
            self.selectState = 1
            self.quickItems.selectSp2:setVisible(true);
            UIRequest({type = 6406,autoState = self.selectState,autoLevel = self.resolvequality})
            print("self.resolvequality:"..self.resolvequality)

        end
        print(" self.resolvequality  ",self.resolvequality,self.selectState)
    end, CCControlEventTouchUpInside)

end


function slotsInfo.resetquicknode( self,status)
    -- print("  status 111111  ",status," self.resolvequality ",self.resolvequality);

    if status == "open" then
        local index = 1
        for i=5,9 do
            local yu = math.fmod( i, 5 )    
            local currentindex = i+yu
            self.quickItems["q_node"..currentindex]:stopAllActions()
            if (currentindex)==self.resolvequality then
                self.quickItems["q_node"..currentindex]:setZOrder(1)
                self.quickItems["q_node"..currentindex]:setPosition(0,0)
            else
                local moveto = CCMoveTo:create(0.5,ccp(0,index*65))
                local backout = CCEaseBackOut:create(moveto)
                self.quickItems["q_node"..currentindex]:setZOrder(0)
                self.quickItems["q_node"..currentindex]:runAction(backout)
                index = index +1
            end
        end
        self.quickstatus = true

        self.quickItems.q_buttonbg:stopAllActions()
        local scaleto = CCScaleTo:create(0.2,1,1)
        self.quickItems.q_buttonbg:runAction(scaleto)
        -- self.quickItems.q_buttonbg:setVisible(true)
    else
        for i=5,9 do
            local yu = math.fmod( i, 5 )  
            local currentindex = i+yu
            self.quickItems["q_node"..currentindex]:stopAllActions()
            if (currentindex)==self.resolvequality then
                self.quickItems["q_node"..currentindex]:setZOrder(1)
                self.quickItems["q_button"..currentindex]:setTouchPriority(-107)
            else
                self.quickItems["q_node"..currentindex]:setZOrder(0)
                self.quickItems["q_button"..currentindex]:setTouchPriority(-106)
            end
            local moveto = CCMoveTo:create(0.08,ccp(0,0))
            local backout = CCEaseBackIn:create(moveto)
            self.quickItems["q_node"..currentindex]:runAction(backout)
        end
        self.quickstatus = false

        self.quickItems.q_buttonbg:stopAllActions()
        local scaleto = CCScaleTo:create(0.2,1,0)
        self.quickItems.q_buttonbg:runAction(scaleto)
    end
end

-- 自动合成魔符状态查询
function slotsInfo.updateAutoQuery( self,data )
    -- body

    self.selectState = data.autoState;
    self.resolvequality = data.autoLevel

    self.quickItems["q_node"..(data.autoLevel)]:setZOrder(1)
    if data.autoState == 0 then
        self.quickItems.selectSp2:setVisible(false);
    else
        self.quickItems.selectSp2:setVisible(true);
    end
   

    local openAutoSlotLv = gamedata.config.global_kv.sigil_autosynthetic_lv and tonumber(gamedata.config.global_kv.sigil_autosynthetic_lv.value) or 0
    local rolelv = data.rolelv or 0 

    print("updateAutoQuery  openAutoSlotLv:"..tonumber(openAutoSlotLv))
    print("updateAutoQuery  rolelv:"..tonumber(rolelv))

    if tonumber(openAutoSlotLv) >=0 and tonumber(rolelv) >= tonumber(openAutoSlotLv)  then
        print("updateAutoQuery open")
        self.slotgemsPage.item.quicknode:setVisible(true)
    end    

end

function slotsInfo.updateAutoCompose( self,data )
    -- if self.selectState == 1 then
        -- 给提示
        runGamePrompt({msg = "更改成功，重新登录游戏自动合成生效"})
    -- else
        
    -- end
end


return slotsInfo