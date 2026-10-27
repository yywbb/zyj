--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/2/4
-- Time: 上午10:39
-- To change this template use File | Settings | File Templates.
--

local collect = {

    resource = nil,
    rootNode = nil,
    rootItems = nil,

    generalTableView = nil,
    ListTableView = nil,
    equipTableView = nil,
    treasureTableView = nil,

    generalstatus = {},
    equipstatus = {},

    generalshowData = nil,
    generaldata = {},
    recommendCellSize = {x=1080, y=965},
    recommendGeneralTab = {},
    generalviewlen = {total = 0, table = {}},
    generalActivenum = {total = {active = 0,total = 0}, table = {}},

    equipshowData = nil,
    weaponData = {},
    armorData = {},
    headData = {},
    accessoryData = {},
    equipshowviewlen = nil,
    weaponviewlen = {total = 0, table = {}},
    armorviewlen = {total = 0, table = {}},
    headviewlen = {total = 0, table = {}},
    accessoryviewlen = {total = 0, table = {}},
    equipshowActivenum = nil,
    weaponActivenum = {total = {active = 0,total = 0}, table = {}},
    armorActivenum = {total = {active = 0,total = 0}, table = {}},
    headActivenum = {total = {active = 0,total = 0}, table = {}},
    accessoryActivenum = {total = {active = 0,total = 0}, table = {}},

    treasureshowData = nil,
    treasureData = {},
    horseData = {},
    treasureshowviewlen = nil,
    treasureviewlen = {total = 0, table = {}},
    horseviewlen = {total = 0, table = {}},
    treasureshowActivenum = nil,
    treasureActivenum = {total = {active = 0,total = 0}, table = {}},
    horseActivenum = {total = {active = 0,total = 0}, table = {}},

    pageconfig = {"general","equip","treasure"} ,
    -- pagename = {"伙伴","装备","宝物"},
    pagename = {gameConfig.strings:string_common("collect",0),gameConfig.strings:string_common("collect",1),gameConfig.strings:string_common("collect",2)},
    selectpage = "general",

    equiptypeconfig = {"weapon","armor","head","accessory"},
    equipselectpage = "weapon" ,
    treasuretypeconfig = {"treasure","horse"},
    treasureselectpage = "treasure",
    generaltypeconfig = {"whole", "recommend"},
    generalselectpage = "whole",
    equipactive = 0,
    equiptotal = 0,
    treasureactive = 0,
    treasuretotal = 0,
    boxStatusTab = nil,
    isscrolltouched = false,
    scheduleScript = nil,
    generalCelldict = nil,
}

local function makeTablelen(data)
    local total = 0
    local table = {}
    for k,v in pairs(data)  do
        table[k] = math.ceil(#v/4)*230 +150
        total = total + table[k]
    end
    return {total = total, table = table}
end

function collect.makegeneralconfigdata(self)
    for k,v in pairs(gamedata.config:getConfigByName("general")) do
        if v.illustrated and v.illustrated == 1 then
            if not self.generaldata["quality"..v.quality]  then
                self.generaldata["quality"..v.quality] = {}
            end
            table.insert(self.generaldata["quality"..v.quality],v)
        end
    end
    local function sortcollect(a,b)
        if a.order == b.order then
            return a.generalid > b.generalid
        else
            return a.order > b.order
        end
    end

    for i=2,7 do
        if self.generaldata["quality"..i] then
            table.sort(self.generaldata["quality"..i],sortcollect)
        end
    end

    self.generalviewlen = makeTablelen(self.generaldata)
end

function collect.makeequipconfigdata(self)
    for k,v in pairs(gamedata.config:getConfigByName("equip")) do
        if v.illustrated and v.illustrated == 1 then
            if not self[v.type.."Data"]["quality"..v.quality]  then
                self[v.type.."Data"]["quality"..v.quality] = {}
            end
            table.insert(self[v.type.."Data"]["quality"..v.quality],v)
        end
    end
    self.weaponviewlen = makeTablelen(self.weaponData)
    self.armorviewlen = makeTablelen(self.armorData)
    self.headviewlen = makeTablelen(self.headData)
    self.accessoryviewlen = makeTablelen(self.accessoryData)
    self.treasureviewlen = makeTablelen(self.treasureData)
    self.horseviewlen = makeTablelen(self.horseData)
end

function collect.makeconfig(self)
    self:makegeneralconfigdata()
    self:makeequipconfigdata()
end

function collect.setTitle(self)
    if self.selectpage == "equip" then
        -- self.rootItems.title:setString("装备")
        self.rootItems.title:setString(gameConfig.strings:string_common("collect",1))
        self.rootItems.titletotal:setString(self.equipactive.."/"..self.equiptotal)
        self.rootItems["equiptitle"]:setString(gameConfig.strings.equipType[self.equipselectpage])
        self.rootItems["equiptitlenum"]:setString(self[self.equipselectpage.."Activenum"].total.active.."/"..self[self.equipselectpage.."Activenum"].total.total)
    elseif self.selectpage == "treasure" then
        -- self.rootItems.title:setString("宝物")
        self.rootItems.title:setString(gameConfig.strings:string_common("collect",2))
        self.rootItems.titletotal:setString(self.treasureactive.."/"..self.treasuretotal)
        self.rootItems["treasuretitle"]:setString(gameConfig.strings.equipType[self.treasureselectpage])
        self.rootItems["treasuretitlenum"]:setString(self[self.treasureselectpage.."Activenum"].total.active.."/"..self[self.treasureselectpage.."Activenum"].total.total)
    elseif self.selectpage == "general" then
        -- self.rootItems.title:setString("伙伴")
        self.rootItems.title:setString(gameConfig.strings:string_common("collect",0))
        self.rootItems.titletotal:setString(self.generalActivenum.total.active.."/"..self.generalActivenum.total.total)
        self.rootItems["generaltitle"]:setString("")
        self.rootItems["generaltitlenum"]:setString("")
    end
end


function collect.shiftPage(self,type,first)
    self.selectpage = type

    for k,v in ipairs(self.pageconfig) do
        if v == type then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPositionX(0)
            self.rootItems[v.."top"]:setVisible(true)
            self.rootItems[v.."top"]:setPositionX(0)
        else
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPositionX(9999)
            self.rootItems[v.."top"]:setVisible(false)
            self.rootItems[v.."top"]:setPositionX(9999)
        end
    end
    self.rootItems.recommendGeneralNode:setVisible(false)
    self.rootItems.recommendGeneralNode:setPosition(99999, 0) 
    if self.selectpage == "equip" then
        if not self.equipstatus or not next(self.equipstatus) then
            UIRequest({type = 1103})
        else
            self:shiftEquipPage(self.equipselectpage)
        end
    elseif self.selectpage == "treasure" then
        if not self.equipstatus or not next(self.equipstatus) then
            UIRequest({type = 1103})
        else
            self:shiftTreasurePage(self.treasureselectpage)
        end
    elseif self.selectpage == "general" then
        if not self.generalstatus or not next(self.generalstatus) then
            UIRequest({type = 1015})
            -- UIRequest({type = 3910})
        else
            -- self:setTitle()
            self:shiftGeneralPage(self.generalselectpage)
        end
    end

end

function collect.shiftGeneralPage(self,type,first)
    self.generalselectpage = type
    for k,v in ipairs(self.generaltypeconfig) do
        if v == type then
            self.rootItems[v.."Onbg"]:setVisible(true)
            self.rootItems[v.."Onpoint"]:setVisible(true)
        else
            self.rootItems[v.."Onbg"]:setVisible(false)
            self.rootItems[v.."Onpoint"]:setVisible(false)
        end
    end
    if type == "whole" then
        if self.ListTableView then
            self.rootItems.recommendGeneralNode:setVisible(false)
            self.rootItems.recommendGeneralNode:setPosition(99999, 0)            
        end
        self.rootItems.generalNode:setVisible(true)
        self.rootItems.generalNode:setPosition(0, 160)
        if not self.generalCelldict then
            self:creatGeneralList()
        end         
    elseif type == "recommend" then
        if not self.boxStatusTab then
            UIRequest({type = 3910})
        else
            -- self:setTitle()
            -- self:shiftGeneralPage(self.generalselectpage)
            if self.generalCelldict then
                self.rootItems.generalNode:setVisible(false)
                self.rootItems.generalNode:setPosition(99999, 0)
            end
            self.rootItems.recommendGeneralNode:setVisible(true)
            self.rootItems.recommendGeneralNode:setPosition(0, 160)
            if not self.ListTableView then
                self:createRecommendGeneralList()
            else
                self.ListTableView:reloadData()
            end             
        end    
        
    end

    self:setTitle()
end

function collect.shiftEquipPage(self,type,first)
    self.equipselectpage = type
    self.equipshowData =  self[type.."Data"]
    self.equipshowviewlen =  self[type.."viewlen"]
    self.equipshowActivenum =  self[type.."Activenum"]

    for k,v in ipairs(self.equiptypeconfig) do
        if v == type then
            self.rootItems[v.."Onbg"]:setVisible(true)
            self.rootItems[v.."Onpoint"]:setVisible(true)
        else
            self.rootItems[v.."Onbg"]:setVisible(false)
            self.rootItems[v.."Onpoint"]:setVisible(false)
        end
    end

    if self.equipTableView then
        self.equipTableView:reloadData()
        self.equipTableView:setLuaContentOffset(0, self.rootItems.equipNode:getContentSize().height - self[type.."viewlen"].total)
    else
        self:creatEquipList()
    end

    self:setTitle()
end

function collect.shiftTreasurePage(self,type,first)
    self.treasureselectpage = type
    self.treasureshowData =  self[type.."Data"]
    self.treasureshowviewlen =  self[type.."viewlen"]
    self.treasureshowActivenum =  self[type.."Activenum"]

    for k,v in ipairs(self.treasuretypeconfig) do
        if v == type then
            self.rootItems[v.."Onbg"]:setVisible(true)
            self.rootItems[v.."Onpoint"]:setVisible(true)
        else
            self.rootItems[v.."Onbg"]:setVisible(false)
            self.rootItems[v.."Onpoint"]:setVisible(false)
        end
    end

    if self.treasureTableView then
        self.treasureTableView:setLuaContentOffset(0, self.rootItems.treasureNode:getContentSize().height - self[type.."viewlen"].total)
        self.treasureTableView:reloadData()
    else
        self:creattreasureList()
    end

    self:setTitle()
end


function collect.init(self,parent,toppos, _type) -- 加了一个generalType 判断进哪个页面
    self.rootNode,self.rootItems = CCBReaderLoad("collect/tujian", nil, true, "tujian")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    if gamedata.config:getConfigByName("build")[tostring(170)] and gamedata.config:getConfigByName("build")[tostring(170)].switch == 1 then
        if self.rootItems.recommendtop then
            self.rootItems.recommendtop:setVisible(true)
        end
    else
        if self.rootItems.recommendtop then
            self.rootItems.recommendtop:setVisible(false)
        end
    end

    if _type and (_type == "recommend") then
        self.generalselectpage = _type
    end

    self.rootItems.topnode:setPositionY(toppos)


    -- self.rootItems.generalNode:setContentSize(CCSizeMake(gameConfig.originSize.width,(GameScene.topposY-1620)+1260))
    self.rootItems.recommendGeneralNode:setContentSize(CCSizeMake(gameConfig.originSize.width,(GameScene.topposY-1620)+1260))
    self.rootItems.equipNode:setContentSize(CCSizeMake(gameConfig.originSize.width,(GameScene.topposY-1620)+1260))
    self.rootItems.treasureNode:setContentSize(CCSizeMake(gameConfig.originSize.width,(GameScene.topposY-1620)+1260))

    for k,v in ipairs(self.generaltypeconfig) do
        self.rootItems[v.."Button"]:setSwallowsTouch(true)
        self.rootItems[v.."Button"]:setTouchPriority(-103)
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            self:shiftGeneralPage(v)
        end, CCControlEventTouchUpInside)
    end

    for k,v in ipairs(self.equiptypeconfig) do
        self.rootItems[v.."Button"]:setSwallowsTouch(true)
        self.rootItems[v.."Button"]:setTouchPriority(-103)
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            self:shiftEquipPage(v)
        end, CCControlEventTouchUpInside)
    end

    for k,v in ipairs(self.treasuretypeconfig) do
        self.rootItems[v.."Button"]:setSwallowsTouch(true)
        self.rootItems[v.."Button"]:setTouchPriority(-103)
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            self:shiftTreasurePage(v)
        end, CCControlEventTouchUpInside)
    end

    -- 取表中阵容
    self.recommendGeneralTab = {}
    local teamRecommend = gamedata.config:getConfigByName("team_recommend") or {}
    local generalTab = gamedata.config:getConfigByName("general") or {}
    for k,v in pairs(teamRecommend) do
        local generalId = ui.getGeneralID(v.icon)
        local generalDesc = ui.getIDandDesc(v.desc1)
        local drop = ui.getIDandNUMs(v.drop)
        local getGeneralTab = {}
        for k_i,v_i in pairs(generalId) do
            table.insert(getGeneralTab, generalTab[tostring(v_i.cid)])
        end
        table.insert(self.recommendGeneralTab, {sortNum = k, name = v.name, id = getGeneralTab, desc1 = generalDesc, desc2 = v.desc2, drop = drop})
    end
    table.sort(self.recommendGeneralTab, function(a, b)
        return a.sortNum < b.sortNum
    end)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","collect",touchbegin)
    local function touchend(pos)
        if self.rootItems.generalNode and ui.isTouched(self.rootItems.generalNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.equipNode and ui.isTouched(self.rootItems.equipNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.treasureNode and ui.isTouched(self.rootItems.treasureNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.recommendGeneralNode and ui.isTouched(self.rootItems.recommendGeneralNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end        
    end
    gameTouch:rigistFunc("end","collect",touchend)

    self:shiftPage(self.selectpage,true)

--    self:creatGeneralList()
--    self:shiftEquipPage(self.equipselectpage,self.selectpage ~= "equip")
--    self:shiftTreasurePage(self.treasureselectpage,self.selectpage ~= "treasure")
--
----    self:reloadgeneralData()
----    self:reloadequipData()
--
--    UIRequest({type = 1015})
--    UIRequest({type = 1103})
end

function collect.clear(self)

    if self.scheduleScript then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduleScript)
        self.scheduleScript = nil
    end
    self.generalCelldict = nil

    gameTouch:UnrigistFunc("begin","collect")
    gameTouch:UnrigistFunc("end","collect")    
    self.isscrolltouched = false    
    self.rootItems = nil
    self.generalTableView = nil
    self.ListTableView = nil
    self.equipTableView = nil
    self.treasureTableView = nil

    self.generalstatus = {}
    self.equipstatus = {}
    self.boxStatusTab = nil
    self.recommendGeneralTab = {}
--    self.generaldata = {}
--    self.generalviewlen = {total = 0, table = {}}
    self.generalActivenum = {total = {active = 0,total = 0}, table = {}}
--
--    self.equipshowData = nil
--    self.weaponData = {}
--    self.armorData = {}
--    self.headData = {}
--    self.accessoryData = {}
--    self.equipshowviewlen = nil
--    self.weaponviewlen = {total = 0, table = {}}
--    self.armorviewlen = {total = 0, table = {}}
--    self.headviewlen = {total = 0, table = {}}
--    self.accessoryviewlen = {total = 0, table = {}}
    self.equipshowActivenum = nil
    self.weaponActivenum = {total = {active = 0,total = 0}, table = {}}
    self.armorActivenum = {total = {active = 0,total = 0}, table = {}}
    self.headActivenum = {total = {active = 0,total = 0}, table = {}}
    self.accessoryActivenum = {total = {active = 0,total = 0}, table = {}}
--
--    self.treasureshowData = nil
--    self.treasureData = {}
--    self.horseData = {}
--    self.treasureshowviewlen = nil
--    self.treasureviewlen = {total = 0, table = {}}
--    self.horseviewlen = {total = 0, table = {}}
    self.treasureshowActivenum = nil
    self.treasureActivenum = {total = {active = 0,total = 0}, table = {}}
    self.horseActivenum = {total = {active = 0,total = 0}, table = {}}

    self.selectpage = "general"
    self.equipselectpage = "weapon"
    self.treasureselectpage = "treasure"
    self.generalselectpage = "whole"

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function  collect.setIcon(self,item,data,id,status)


    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end

    if data then
        item["i_node"..key_Ex]:setVisible(true)
    else
        item["i_node"..key_Ex]:setVisible(false)
        return
    end

    if item["i_name"..key_Ex] then
        item["i_name"..key_Ex]:setString(data.name or " ")
    end
    local  config = ui.IDconfig(data.id or data.generalid)

    if config.staffType=="general" and config.quality ==5 and config.basic >=20 then
        setSpriteFrameByName(item["i_k_quality"..key_Ex], "b_iconk5_"..config.basic )
    else
        setSpriteFrameByName(item["i_k_quality"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
    end

    setSpriteFrameByName(item["i_quality"..key_Ex], "b_iconbg"..(data.quality and data.quality>1 and data.quality or 1))
    setSpriteFrameByName(item["i_icon"..key_Ex], data.icon and data.icon or gameConfig.images.alpha)
    ui.setSpriteTextureRect(item["i_icon"..key_Ex],0,0,150,150)

    local cid = data.id or data.generalid

    if self[status][tostring(cid)] and self[status][tostring(cid)] == 1 then
        --item["i_kuang"..key_Ex]:setColor(ccc3(255,255,255))
        item["i_quality"..key_Ex]:setColor(ccc3(255,255,255))
        item["i_icon"..key_Ex]:setColor(ccc3(255,255,255))


--        ui.removeGray("CCSprite",item["i_kuang"..key_Ex])
--        ui.removeGray("CCSprite",item["i_quality"..key_Ex])
--        ui.removeGray("CCSprite",item["i_icon"..key_Ex])
    else
        --item["i_kuang"..key_Ex]:setColor(ccc3(150,150,150))
        item["i_quality"..key_Ex]:setColor(ccc3(150,150,150))
        item["i_icon"..key_Ex]:setColor(ccc3(150,150,150))

--        ui.addGray("CCSprite",item["i_kuang"..key_Ex])
--        ui.addGray("CCSprite",item["i_quality"..key_Ex])
--        ui.addGray("CCSprite",item["i_icon"..key_Ex])
    end

    if item["i_suitNode"..key_Ex] and (cid) then
        item["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
        local config = ui.IDconfig(cid)
        if config.suit and config.suit ~= 0 then
            local suitccb, suititem = CCBReaderLoad("UIEffect/icon/icon_"..config.quality..".ccbi", nil, true, "icon")
            item["i_suitNode"..key_Ex]:addChild(suitccb)
        end

        if config.quality and (config.quality == 6 or config.quality == 7) and config.staffType == "general" then
            local suitccb, suititem = CCBReaderLoad("UIEffect/pinzhikuang/"..(config.quality == 6 and "hongsepinzhi" or "jinsepinzhi"), nil, true, "jinsepinzhi")
            item["i_suitNode"..key_Ex]:addChild(suitccb)
        end
    end

    item["i_button"..key_Ex]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        if not gameTouch.ismove then
            ui.setPopwindowByCid(cid)
        end

    end, CCControlEventTouchUpInside)
    item["i_button"..key_Ex]:setTouchPriority(-2)
end

function  collect.creatGeneralList(self)
    
    -- printT(self.generaldata,"self.generaldata")
    local fixh = 0
    local diffY = 10
    local cellnum = table.getTableLength(self.generaldata)
    self.generalCelldict = {}
    for i=1,table.getTableLength(self.generaldata) do

        local quality = i + 1
        local generaldata = self.generaldata["quality"..quality]
        local lineNum = math.ceil(#generaldata/4)
        local cellH = 140 + 230 * lineNum
        fixh = fixh + cellH + (i == 1 and 5 or diffY)

        local ccb, item = CCBReaderLoad("collect/cell_tujianNew", nil, true, "cell_tujianNew")
        ccb:setPosition(540,fixh)
        self.rootItems.container:addChild(ccb)

        item.sp9_1 = tolua.cast(item.sp9_1, "CCScale9Sprite")
        item.sp9_2 = tolua.cast(item.sp9_2, "CCScale9Sprite")

        item.sp9_1:setPreferredSize(CCSizeMake(1040,cellH))
        item.sp9_2:setPreferredSize(CCSizeMake(870,230*lineNum))
        self.generalCelldict[i] = {cellH = cellH,ccb = ccb,item = item,iconNum = 0,generaldata = generaldata}

        if self.generalActivenum.table["quality"..quality] then
            item.des:setString(gameConfig.strings:partner(gameConfig.strings.quality[quality]))
            item.num:setString(self.generalActivenum.table["quality"..quality].active.."/"..self.generalActivenum.table["quality"..quality].total)
        end

        if quality == 6 then
            item.iconNode:setPositionY(-120)
            item.tip:setString(gameConfig.strings:string_common("collect",5))
        elseif quality == 7 then
            item.iconNode:setPositionY(-120)
            item.tip:setString(gameConfig.strings:string_common("collect",4))
        else
            item.iconNode:setPositionY(-90)
            item.tip:setString("")
        end
    end

    local viewH = GameScene.topposY-1620+1260
    self.rootItems.generalNode = tolua.cast(self.rootItems.generalNode, "CCScrollView")
    self.rootItems.generalNode:setTouchPriority(-103)
    self.rootItems.generalNode:setViewSize(CCSizeMake(gameConfig.originSize.width,viewH))

    self.rootItems.container:setContentSize(CCSizeMake(1080,fixh))
    self.rootItems.container:setPositionY(viewH - fixh)

    --初始化屏幕显示
    local initNum = 0
    for i=#self.generalCelldict,1,-1 do
        local isEnd = false
        local v = self.generalCelldict[i]
        local generaldata = v.generaldata
        for i2,v2 in ipairs(v.generaldata) do
            if initNum < 24 then
                v.iconNum = v.iconNum + 1
                local ccb, item = CCBReaderLoad("collect/icon", nil, true, "icon")
                self:setIcon(item,v.generaldata[v.iconNum],nil,"generalstatus")
                ccb:setScale(0.89)
                local _x = (v.iconNum%4 == 0 and 4 or v.iconNum%4)
                local _y = math.ceil(v.iconNum/4)
                ccb:setPosition(-330 + (_x - 1) * 220,-110 - (_y - 1) * 230)
                v.item.iconNode:addChild(ccb)
                initNum = initNum + 1
            end

        end
        if isEnd then break end
    end


    self.scheduleScript = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        for i,v in ipairs(self.generalCelldict) do
            if v.iconNum < #v.generaldata then
                local pos = v.item.iconNode:convertToWorldSpace(ccp(0,0))
                local y = pos.y/gameConfig.scaleNum
                --显示行数
                local line = math.ceil((y - 100)/200)
                local showNum = line * 4

                if  v.iconNum < showNum then
                    v.iconNum = v.iconNum + 1
                    local ccb, item = CCBReaderLoad("collect/icon", nil, true, "icon")
                    self:setIcon(item,v.generaldata[v.iconNum],nil,"generalstatus")
                    ccb:setScale(0.89)
                    local _x = (v.iconNum%4 == 0 and 4 or v.iconNum%4)
                    local _y = math.ceil(v.iconNum/4)
                    ccb:setPosition(-330 + (_x - 1) * 220,-110 - (_y - 1) * 230)
                    v.item.iconNode:addChild(ccb)
                end
            end
        end

    end, 0, false)
end


function collect.createRecommendGeneralList(self)
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.recommendCellSize.x, self.recommendCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("collect/tujian_tuijianzhenrong", nil, true, "tujianzhenrong")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setCell(ccbDocumentControler, self.recommendGeneralTab[a1+1], a1+1)
            cellCCB:setPosition(self.recommendCellSize.x/2, 10)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.recommendGeneralTab)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.recommendGeneralNode:getContentSize().width,
        viewheight = self.rootItems.recommendGeneralNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.recommendGeneralNode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-1)    
end

function collect.setCell(self, item, cellData, index)
    item.smallWhiteLineupLab:setString(cellData.name)
    item.lineupNumTab:setString("(" .. "   " .. "/" .. table.getTableLength(cellData.id) .. ")")
    local generalNum = 1
    local haveGeneralNum = 0

    local key_Ex = ""
    local tt = 1
    for i=1,6 do
        item["cell" .. i]:setVisible(false)
    end
    for k,v in pairs(cellData.id) do
        -- 判断阵容中有几个是得到过的武将
        item["cell" .. k]:setVisible(true)
        if gamedata.config:getConfigByName("general")[tostring(v.generalid)].illustrated and gamedata.config:getConfigByName("general")[tostring(v.generalid)].illustrated == 1 then
            if self.generalstatus[tostring(v.generalid)] and self.generalstatus[tostring(v.generalid)] == 1 then
                haveGeneralNum = haveGeneralNum + 1
            end
        end    
        -- 核心图标
        self:setIcon(item, v, k - 1, "generalstatus")
        if k ~= 1 then
            key_Ex = "_" .. (k - 1)
        end
        item["core" .. key_Ex]:setVisible(false)
        if cellData.desc1[tt] ~= nil then
            if v.generalid == cellData.desc1[tt].cid then
                item["core" .. key_Ex]:setVisible(true)
                tt = tt + 1
            else
                item["core" .. key_Ex]:setVisible(false)
            end            
        end          
    end

    ui.setLabelString(item.getNumTab, haveGeneralNum, 23)

    if self.boxStatusTab[tostring(index)] == 0 then
        setSpriteFrameByName(item.reward, "box4_0" or "alpha")-- 奖励预览
    elseif self.boxStatusTab[tostring(index)] == 1 then
        setSpriteFrameByName(item.reward, "box4_1" or "alpha")  
    elseif self.boxStatusTab[tostring(index)] == 2 then
        setSpriteFrameByName(item.reward, "box4_2" or "alpha")      
    end

    item.getItemNode:removeAllChildrenWithCleanup(true)
    if self.boxStatusTab[tostring(index)] == 1 then
        local ccb, item1 = CCBReaderLoad("UIEffect/baoxiangkelingqu/baoxiangkelingqu.ccbi", nil, true, "baoxiangkelingqu")
        item.getItemNode:addChild(ccb)
        local ccb2, item2 = CCBReaderLoad("UIEffect/lizi/baoxiang.ccbi", nil, true, "baoxiang")
        item.getItemNode:addChild(ccb2)
    end        
    
    -- "box4_2" -- 已领取 box4_1 可领取 0 奖励预览
    item.rewardBtn:setTouchPriority(-2)
    item.rewardBtn:setSwallowsTouch(true)
    item.rewardBtn:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        if self.boxStatusTab[tostring(index)] == 0 then
            -- 奖励预览
            gameWindows:openWindow("getStaff",{data = cellData.drop, type = gameConfig.strings:string_common("layer_copy",3)},nil)
        elseif self.boxStatusTab[tostring(index)] == 1 then
            -- 领取奖励
            UIRequest({type = 3911, id = index})
        elseif self.boxStatusTab[tostring(index)] == 2 then
            -- 已领取
            gameWindows:openWindow("getStaff",{data = cellData.drop,type = gameConfig.strings:string_common("layer_copy",4)},nil)
        end        
    end, CCControlEventTouchUpInside)

    for i=1,4 do
        item["coreCharacterNode" .. i]:setVisible(false)
    end
    for k,v in pairs(cellData.desc1) do
        item["coreCharacterNode" .. k]:setVisible(true)
        item["generalName" .. k]:setString(gamedata.config:getConfigByName("general")[tostring(v.cid)].name .. ":")
        ui.setLabelString(item["desc" .. k], "  " .. v.desc, 21)
    end
    item.LineupDescTab:setString("阵容说明：" .. cellData.desc2)
end

function  collect.creatEquipList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            --printT(self.equipshowviewlen.table)
            r = CCSizeMake(1080, self.equipshowviewlen.table["quality"..((table.getTableLength(self.equipshowData)+1)-a1)])
        elseif fn == "cellAtIndex" then

            local cellCCB, ccbItem
            local data = self.equipshowData["quality"..((table.getTableLength(self.equipshowData)+1)-a1)]
            local num = math.ceil(#data/4)

            local first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbItem = CCBReaderLoad("collect/cell_tujian_"..num..".ccbi", nil, true, "cell_tujian_"..num..".ccbi")
                celldict[a2] = {cellCCB=cellCCB, ccbItem=ccbItem, num = num}
            else
                if celldict[a2].num == num then
                    cellCCB = celldict[a2].cellCCB
                    ccbItem = celldict[a2].ccbItem
                    first =false
                else
                    celldict[a2].cellCCB:removeFromParentAndCleanup(true)
                    cellCCB, ccbItem = CCBReaderLoad("collect/cell_tujian_"..num..".ccbi", nil, true, "cell_tujian_"..num..".ccbi")
                    celldict[a2] = {cellCCB=cellCCB, ccbItem=ccbItem, num = num}
                end
            end

            for i=1,num*4 do
                self:setIcon(ccbItem,data[i],i-1,"equipstatus")
            end

            if self.equipshowActivenum.table["quality"..((table.getTableLength(self.equipshowData)+1)-a1)] then
                ccbItem.des:setString(gameConfig.strings.quality[(table.getTableLength(self.equipshowData)+1)-a1]..gameConfig.strings.equipType[self.equipselectpage])
                ccbItem.num:setString(self.equipshowActivenum.table["quality"..((table.getTableLength(self.equipshowData)+1)-a1)].active.."/"..self.equipshowActivenum.table["quality"..((table.getTableLength(self.equipshowData)+1)-a1)].total)
            end

            --ccbItem.sartnode:setPositionX(-160 + a1*40)

            if first then
                cellCCB:setPosition(ccp(1080/2,0))
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.equipshowData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.equipTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.equipNode:getContentSize().width,
        viewheight = self.rootItems.equipNode:getContentSize().height,
        dire = 1
    })
    self.equipTableView:setTouchPriority(-1)
    self.rootItems.equipNode:addChild(self.equipTableView)
end

function  collect.creattreasureList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            r = CCSizeMake(1080, self.treasureshowviewlen.table["quality"..((table.getTableLength(self.treasureshowData)+1)-a1)])
        elseif fn == "cellAtIndex" then

            local cellCCB, ccbItem
            local data = self.treasureshowData["quality"..((table.getTableLength(self.treasureshowData)+1)-a1)]
            local num = math.ceil(#data/4)

            local first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbItem = CCBReaderLoad("collect/cell_tujian_"..num..".ccbi", nil, true, "cell_tujian_"..num..".ccbi")
                celldict[a2] = {cellCCB=cellCCB, ccbItem=ccbItem, num = num}
            else
                if celldict[a2].num == num then
                    cellCCB = celldict[a2].cellCCB
                    ccbItem = celldict[a2].ccbItem
                    first =false
                else
                    celldict[a2].cellCCB:removeFromParentAndCleanup(true)
                    cellCCB, ccbItem = CCBReaderLoad("collect/cell_tujian_"..num..".ccbi", nil, true, "cell_tujian_"..num..".ccbi")
                    celldict[a2] = {cellCCB=cellCCB, ccbItem=ccbItem, num = num}
                end
            end

            for i=1,num*4 do
                self:setIcon(ccbItem,data[i],i-1,"equipstatus")
            end

            if self.treasureshowActivenum.table["quality"..((table.getTableLength(self.treasureshowData)+1)-a1)] then
                ccbItem.des:setString(gameConfig.strings.quality[(table.getTableLength(self.treasureshowData)+1)-a1]..gameConfig.strings.equipType[self.treasureselectpage])
                ccbItem.num:setString(self.treasureshowActivenum.table["quality"..((table.getTableLength(self.treasureshowData)+1)-a1)].active.."/"..self.treasureshowActivenum.table["quality"..((table.getTableLength(self.treasureshowData)+1)-a1)].total)
            end

            if first then
                cellCCB:setPosition(ccp(1080/2,0))
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.treasureshowData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.treasureTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.treasureNode:getContentSize().width,
        viewheight = self.rootItems.treasureNode:getContentSize().height,
        dire = 1
    })
    self.treasureTableView:setTouchPriority(-1)
    self.rootItems.treasureNode:addChild(self.treasureTableView)
end

function collect.getgeneralData(self,data)
    self.generalstatus = data
end

function collect.makeGeneralNum(self)
    self.generalActivenum = {total = {active = 0,total = 0}, table = {} }
    for k,v in pairs(gamedata.config:getConfigByName("general")) do
        if v.illustrated and v.illustrated == 1 then
            if not self.generalActivenum.table["quality"..v.quality]  then
                self.generalActivenum.table["quality"..v.quality] = {active = 0,total = 0}
            end

            if self.generalstatus[k] and self.generalstatus[k] == 1 then
                self.generalActivenum.table["quality"..v.quality].active = self.generalActivenum.table["quality"..v.quality].active +1
                self.generalActivenum.total.active = self.generalActivenum.total.active + 1
            end
            self.generalActivenum.table["quality"..v.quality].total = self.generalActivenum.table["quality"..v.quality].total +1
            self.generalActivenum.total.total = self.generalActivenum.total.total + 1
        end
    end

end


function collect.reloadgeneralData(self,data)
    if data then
        self.generalstatus = data
    end
    self:makeGeneralNum()

    -- if not self.generalTableView then
    --     self:creatGeneralList()
    -- else
    --     self.generalTableView:reloadData()
    -- end

    -- self:setTitle()
    self:shiftGeneralPage(self.generalselectpage, self.selectpage ~= "general")
end

function collect.getBoxData(self, data)
    self.boxStatusTab = data

    self:shiftGeneralPage(self.generalselectpage, self.selectpage ~= "general")   
end

function collect.getequipData(self,data)
    self.equipstatus = data
end

function collect.makeEquipNum(self)

    self.weaponActivenum = {total = {active = 0,total = 0}, table = {}}
    self.armorActivenum = {total = {active = 0,total = 0}, table = {}}
    self.headActivenum = {total = {active = 0,total = 0}, table = {}}
    self.accessoryActivenum = {total = {active = 0,total = 0}, table = {}}

    self.treasureActivenum = {total = {active = 0,total = 0}, table = {}}
    self.horseActivenum = {total = {active = 0,total = 0}, table = {}}

    for k, v in pairs(gamedata.config:getConfigByName("equip")) do
        if not self[v.type.."Activenum"].table["quality"..v.quality]  then
            self[v.type.."Activenum"].table["quality"..v.quality] = {active = 0,total = 0}
        end

        if self.equipstatus[k] and self.equipstatus[k] == 1 and v.illustrated == 1 then
            self[v.type.."Activenum"].table["quality"..v.quality].active = self[v.type.."Activenum"].table["quality"..v.quality].active +1
            self[v.type.."Activenum"].total.active = self[v.type.."Activenum"].total.active + 1
        end
        if  v.illustrated == 1 then
            self[v.type.."Activenum"].table["quality"..v.quality].total = self[v.type.."Activenum"].table["quality"..v.quality].total +1
            self[v.type.."Activenum"].total.total = self[v.type.."Activenum"].total.total + 1
        end
    end
end


function collect.reloadequipData(self,data)
    if data then
        self.equipstatus = data
    end
    self:makeEquipNum()

    self.equipactive = 0
    self.equiptotal = 0
    self.treasureactive = 0
    self.treasuretotal = 0

    for k,v in ipairs(self.equiptypeconfig) do
        self.equipactive = self.equipactive + self[v.."Activenum"].total.active
        self.equiptotal = self.equiptotal + self[v.."Activenum"].total.total
    end

    for k,v in ipairs(self.treasuretypeconfig) do
        self.treasureactive = self.treasureactive + self[v.."Activenum"].total.active
        self.treasuretotal = self.treasuretotal + self[v.."Activenum"].total.total
    end



    self:shiftEquipPage(self.equipselectpage,self.selectpage ~= "equip")
    self:shiftTreasurePage(self.treasureselectpage,self.selectpage ~= "treasure")
end



return collect
