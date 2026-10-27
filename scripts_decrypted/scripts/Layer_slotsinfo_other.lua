--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/3/31
-- Time: 上午11:43
-- To change this template use File | Settings | File Templates.
--

local slotsInfo = {

    resource = nil,
    titleCellSize = {x=180,y=180},

    rootNode = nil,
    rootItems = nil,

    palyerdata = {},

    slotgems = {},
    gems = {},
    slotdata = nil,
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
        equip = "general",
        soul = "general",
        stone = "stone",
    },
    datastatus = "general",
    exclusiveArtifactData = {},
    exclusiveArtifactQilingData = {},

}

function slotsInfo.setStatus(self,status)
    self.status = status
end

function slotsInfo.shiftStatus(self,status)
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

function slotsInfo.init(self,parent,toppos,param,index)
    self.rootNode,self.rootItems = CCBReaderLoad("slotsInfo/slotsinfo_other", nil, true, "slotsinfo_other")
    parent:addChild(self.rootNode)
    self.show = true

    self.sid = 1

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

    self.rootItems.closeButton:setTouchPriority(self.touchpriority)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:removetempLayers("other_slotinfo")
    end, CCControlEventTouchUpInside)
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
            if not self.slotdata[tostring(self.sid)].general then
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
            if self.sid+1 <=self.maxsid+2 then
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchpriority-1, false)
    self.rootItems.touchLayer:setTouchPriority(self.touchpriority-1)
    self.rootItems.touchLayer:setTouchEnabled(true)

    if param then
        self.palyerdata = param
        self.rootItems.palyername:setString(self.palyerdata.name)
        if param.othertype and param.othertype == "champion" then
            UIRequest({type = 4719, rid = self.palyerdata.rid, level = self.palyerdata.level})
        else
            UIRequest({type = 1020, rid = self.palyerdata.rid, level = self.palyerdata.level})
        end
    end

    self.rootItems["artifactBtn"]:setSwallowsTouch(true)
    self.rootItems["artifactBtn"]:setTouchPriority(self.touchpriority)
    self.rootItems["artifactBtn"]:addHandleOfControlEvent(function()
        if type(self.slotdata[tostring(self.sid)].newartifact) == "table" then
            gameWindows:openWindow("artifactInfoOther",{artifactData = self.slotdata[tostring(self.sid)].newartifact,isOther = true},nil)
        end
    end,CCControlEventTouchUpInside)

    self.rootItems["zhuanshubutton"]:setSwallowsTouch(true)
    self.rootItems["zhuanshubutton"]:setTouchPriority(self.touchpriority)
    self.rootItems["zhuanshubutton"]:addHandleOfControlEvent(function()
        if self.slotdata[tostring(self.sid)] and self.slotdata[tostring(self.sid)].general then
            gameWindows:openWindow("exclusiveArtifact", {general = self.slotdata[tostring(self.sid)].general,opt = 3})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("slotsInfo",2)})
        end
    end,CCControlEventTouchUpInside)
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
        ui.setEquipIcon(data[v],self.addedGroup["equip"].items,k-1)
    end
end

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

    for i = 1, 8 do
        ui.setStoneIcon({level=data["g"..i]},self.addedGroup["stone"].items,i-1)
    end
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

    if next(data) and data.general then
        local configdata = gamedata.config.general[tostring(data.general.cid)] or {}
        item.atk:setString(data.general.atk)
        item.hp:setString(data.general.hp)
        item.defense:setString(data.general.defense)
        item.speed:setString(data.general.speed)
        for i = 1, 6 do
            if data.relation[tostring(i)] and data.relation[tostring(i)].activate >1 then
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

function slotsInfo.reloadDataStone(self)
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
    self.addedDataNode["stone"].items.fragmentnode:setVisible(false)

end

function slotsInfo.reloadBottomData(self)
    if self.datastatus == "general" then
        self:reloadDataGeneral()
    elseif  self.datastatus == "stone" then
        self:reloadDataStone()
    end
end

function slotsInfo.setpagedata(self,item,data)

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

        self.rootItems.powerTotal:setString("战力: "..data.general.power)
    else
        ui.setSpriteTextureRect2(item.jingyantiao,0,0,0,item.jingyantiao:getContentSize().height)
        item.lv:setString(0)
        item.exp:setString("0%")

        ui.setLabelString(item.name," ",1)
        setSpriteFrameByName(item["type"], gameConfig.images.alpha)

        self.rootItems.powerTotal:setString("战力: 0")
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

function slotsInfo.setArtifactShow(self)
    
    local data = self.slotdata[tostring(self.sid)]
    if type(data.newartifact) == "table" then
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
    self.xiaohuobanListTableView:setTouchPriority(self.touchpriority)
end

function  slotsInfo.setxhbpagedata(self,item)
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

function slotsInfo.onPartnerShow(self, item)
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

function  slotsInfo.setslotgemspagedata(self,item)
    print("setslotgemspagedata")
    local sigilpositionconfig = gamedata.config.sigilposition or {}
    local slotconfig = gamedata.config.general_cheer

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


function  slotsInfo.setslotgemsdataall(self,item)
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
        for k1, v1 in pairs(v) do
            if v1 > 0 and gemsiid[tostring(v1)] then
                for i = 1,4 do
                    if allnum[sigilconfig[tostring(gemsiid[tostring(v1)].cid)]["attr"..i]] then
                        allnum[sigilconfig[tostring(gemsiid[tostring(v1)].cid)]["attr"..i]] = allnum[sigilconfig[tostring(gemsiid[tostring(v1)].cid)]["attr"..i]] + sigilconfig[tostring(gemsiid[tostring(v1)].cid)]["init"..i]
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

function  slotsInfo.setslotgemsdataone(self,item,index)
    print("setslotgemsdataone:"..index)
    self.select_f = index

    for i = 1,8 do
        item["selectEffect"..(i>1 and ("_"..i-1) or "")]:removeAllChildrenWithCleanup(true)
    end
    local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
    item["selectEffect"..(self.select_f>1 and ("_"..self.select_f-1) or "")]:addChild(eccb)

    if not self.slotgems[tostring(index)] then return end

    for i = 1,5 do
        if self.slotgems[tostring(index)][tostring(i)] and self.slotgems[tostring(index)][tostring(i)] > 0 then
            local gem = {}
            for k,v in pairs(self.gems) do
                if v.iid == self.slotgems[tostring(index)][tostring(i)] then
                    gem = v
                end
            end
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

    if self.slotgems[tostring(index)]["6"] and self.slotgems[tostring(index)]["6"] > 0 then
        local gem = {}
        for k,v in pairs(self.gems) do
            if v.iid == self.slotgems[tostring(index)]["6"] then
                gem = v
            end
        end
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
        if self.slotgems[tostring(index)]["6"] and self.slotgems[tostring(index)]["6"] == -1 then
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

    local gemsiid = {}
    for k,v in pairs(self.gems) do
        gemsiid[tostring(v.iid)] = table.copy(v)
    end

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

    for k1, v1 in pairs(self.slotgems[tostring(index)]) do
        if v1 > 0 and gemsiid[tostring(v1)] then
            for i = 1,4 do
                if onenum[sigilconfig[tostring(gemsiid[tostring(v1)].cid)]["attr"..i]] then
                    onenum[sigilconfig[tostring(gemsiid[tostring(v1)].cid)]["attr"..i]] = onenum[sigilconfig[tostring(gemsiid[tostring(v1)].cid)]["attr"..i]] + sigilconfig[tostring(gemsiid[tostring(v1)].cid)]["init"..i]
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
    if sid <= self.maxsid +2 and sid>0 then
        if sid <= self.maxsid  then
            if not self.slotdata[tostring(sid)].general then
                if self.generalSkeleton[sid] and self.generalSkeleton[sid].name ~=  "empty" then
                    self.generalSkeleton[sid].r_node:removeFromParentAndCleanup(true)
                    self.generalSkeleton[sid] = nil
                end
                if not self.generalSkeleton[sid] then
                    self.generalSkeleton[sid] = {}
                    self.generalSkeleton[sid].name = "empty"
                    self.generalSkeleton[sid].r_node = CCNode:create()
                    self.generalSkeleton[sid].node = CCSprite:createWithSpriteFrameName("alpha.png")
                    self.generalSkeleton[sid].node:setAnchorPoint(ccp(0.5,0))
                    self.generalSkeleton[sid].node:setScale(2)
                    self.generalSkeleton[sid].r_node:addChild(self.generalSkeleton[sid].node)
                    self.generalSkeleton[sid].r_node:setPosition(1080*(sid-0.5),100)
                    self.rootItems.generalcontainer:addChild(self.generalSkeleton[sid].r_node)
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

                    if gamedata.config.general[tostring(self.slotdata[tostring(sid)].general.cid)].name == "主角" then
                        local growconfig = gamedata.config.protagonist_grow or {}
                        local data = self.slotdata[tostring(sid)].general
                        local Node11,Item11 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(growconfig[tostring(data.level2+1)] and (math.mod(data.level2,5)+1) or 5), nil, true, "jie")
                        self.generalSkeleton[sid].r_node:addChild(Node11)
                    else
                        ui.addAwakeEffect(self.generalSkeleton[sid].r_node,self.slotdata[tostring(sid)].general.skilllevel,2.2)
                    end

                    self.generalSkeleton[sid].r_node:setPosition(1080*(sid-0.5),100)
                    self.rootItems.generalcontainer:addChild(self.generalSkeleton[sid].r_node)
                end
            end
        elseif sid == self.maxsid +1 then
            if not next(self.cheerPage) then
                self.cheerPage.ccb,self.cheerPage.item = CCBReaderLoad("slotsInfo/slot-xhb.ccbi", nil, true, "slot-xhb")
                self.cheerPage.item.adaptnode:setPositionY((GameScene.topposY-1620)/2)
                self.cheerPage.ccb:setPosition(1080,0)
                self.rootItems.pagenode:addChild(self.cheerPage.ccb)
                self:setxhbpagedata(self.cheerPage.item)
            end
        elseif sid == self.maxsid+2 then
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

function slotsInfo.loadpages(self)
    self:loadPage(self.sid)
    self:loadPage(self.sid+1)
    self:loadPage(self.sid-1)
end

function slotsInfo.setPage(self,page,needReset)
    local oldsid =  self.sid
    self.sid = page
    self.rootItems.powerTotal:setVisible(self.sid~=self.maxsid+1 and self.sid~=self.maxsid+2)

    if not self.generalListTableView then
        self:reloadGeneralList()
    else
        print("generalListTableView reload")
        self.generalListTableView:reloadData()
    end

    if self.sid == self.maxsid +2 then
--        if self.maxsid <7 then
--            self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * (self.sid+1),0),0.2)
--        else
        if  self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * (self.sid) < 0  then
            self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * (self.sid),0),0.2)
        end

--        end
    elseif  self.titleCellSize.x * self.sid >  self.rootItems.generalListScroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
        self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.generalListScroll:getContentSize().width - self.titleCellSize.x * self.sid,0),0.2)
    elseif self.titleCellSize.x * (self.sid-1) < -self.generalListTableView:getLuaContentOffsetX() then
        self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.sid-1) ,0),0.2)
    end

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
end

function slotsInfo.reload(self,slots,cheers,protagonist,slotgems,gems,exclusiveArtifactDatas,exclusiveArtifactQiLingDatas)
    if slots then
        self.slotdata = slots
    end
    if cheers then
        self.cheerdata = cheers
    end
    if protagonist then
        self.protagonist = protagonist
    end
    if slotgems then
        self.slotgems = slotgems
    end
    if gems then
        self.gems = gems
    end


    if exclusiveArtifactDatas then
        for k,v in pairs(exclusiveArtifactDatas) do
            self.exclusiveArtifactData[v.generalIid] = v
        end
    end

    if exclusiveArtifactQiLingDatas then
        for k,v in pairs(exclusiveArtifactQiLingDatas) do
            self.exclusiveArtifactQilingData[v.iid] = v
        end
    end

    self:setExclusiveShow()

    self.maxsid = table.getTableLength(self.slotdata)

    if self.palyerdata.othertype and self.palyerdata.othertype == "togeneral" then
        for k,v in pairs(self.slotdata) do
            if v.general.cid == self.palyerdata.params["1"].i then
                self.sid = tonumber(k)
                break
            end
        end        
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
end


function slotsInfo.setExclusiveShow(self)
    if (self.palyerdata.level or 0) < gamedata.config.build[tostring(611)].level then
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

function slotsInfo.clear(self)
    self.select_f = 0
    self.generalListTableView = nil
    self.xiaohuobanListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.addedGroup = {}
    self.addedDataNode = {}
    self.exclusiveArtifactData = {}
    self.exclusiveArtifactQilingData = {}
    self.level = 0

    self.status = "equip"
    self.datastatus = "general"
    self.slotgemsPage = {}
    self.cheerPage = {}
    self.generalSkeleton = {}

    self.rootNode = nil
    self.rootItems = nil
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

            if a1+1<= self.maxsid then
                -- 设置头像
                local generalData = self.slotdata[tostring(a1+1)] or {}
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
                    ui.setSlotGeneralIcon(self.slotdata[tostring(a1+1)],ccbDocumentControler)
                end
            elseif a1+1 == self.maxsid+1 then
                ui.setxiaohuobanIcon(ccbDocumentControler)
            else
                ui.setslotgemsIcon(ccbDocumentControler)
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
            r = self.maxsid +2
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            if a1:getIdx()+1 <= self.maxsid then
                self:setPage(a1:getIdx()+1,true)
            elseif a1:getIdx()+1 >= self.maxsid+1 then
--                if self.maxsid<7 then
--
--                else
                    self:setPage(a1:getIdx()+1)
--                end
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


return slotsInfo   I�  