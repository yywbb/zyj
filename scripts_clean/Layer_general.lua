--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local generalList = {

    resource = nil,


    rootNode = nil,
    rootItems = nil,
    generalsListTableView = nil,
    fragmentsListTableView = nil,
    redfragmentsListTableView = nil,

    generalsSelected = nil,


    generalsdata = {},
    fragmentsdata = {},
    redfragmentsdata = {},
    generalslovedata = {},

    normalCellSize = {x=1080,y=270},
    detailCellSize = {x=1080,y=402},

    pageconfig = {"generals","fragments","redfragments"},--"exchange"} ,
    -- pagename = {"伙 伴","魂 魄","精 华","兑 换"},
    pagename = {gameConfig.strings:string_common("general",0),gameConfig.strings:string_common("general",1),gameConfig.strings:string_common("general",38),gameConfig.strings:string_common("general",2)},
    selectpage = "generals",

    ListTableView = nil,
    exchangeData = nil,
    allgenerals = nil,

    coin = 0,
    gold = 0,
    propnum = 0,
    redpropnum = 0,
    redpropnum2 = 0,
    hasprops = {},

    normalCellSize_ex = {x=1080,y=296},

    unrecycleCell = {},

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {6},
                title2 = {110},
            },
        },
    },
    isscrolltouched = false,
}



function generalList.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("general/generals", nil, true, "generalList")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    -- self.rootItems.toptitle:setPositionY(toppos)
    self.rootItems.gotonode:setPositionY(toppos/2)
    self.rootItems.titlebgbottom:setVisible(false)

    self.rootItems.bagbg1:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-40-350))
    self.rootItems.generalsNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-40-600))
    self.rootItems.fragmentsNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-40-600))
    self.rootItems.redfragmentsNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-40-600))
    self.rootItems.exchangeNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-40-600))
    --兑 换 页签已经移除
    self.rootItems.exchangeNode:setVisible(false)
    self.rootItems.exchangeNode:setPositionX(9999)

    self.awakenConfig = gamedata.config.general_awaken

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","generalList",touchbegin)
    local function touchend(pos)
        if self.rootItems.generalsNode and ui.isTouched(self.rootItems.generalsNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.fragmentsNode and ui.isTouched(self.rootItems.fragmentsNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.redfragmentsNode and ui.isTouched(self.rootItems.redfragmentsNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.exchangeNode and ui.isTouched(self.rootItems.exchangeNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end        
    end
    gameTouch:rigistFunc("end","generalList",touchend)

    self.selectpage = self.selectpage or "generals"
    self:shiftPage(self.selectpage)


--    UIRequest({type = 1012})
--    UIRequest({type = 10023})
--    UIRequest({type = 10211})
end

function generalList.clear(self)

    self.hasprops = {}

    gameTouch:UnrigistFunc("begin","generalList")
    gameTouch:UnrigistFunc("end","generalList")    
    self.isscrolltouched = false    
    self.rootItems = nil
    self.generalsListTableView = nil
    self.fragmentsListTableView = nil
    self.redfragmentsListTableView = nil
    self.generalsSelected = nil

    --self.generalsdata = nil
    --self.fragmentsdata = nil
    --self.redfragmentsdata = nil
    self.ListTableView = nil
    --self.exchangeData = nil

    if self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end
    self.unrecycleCell = {}

    self.selectpage = "generals"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

--伙伴升星
function generalList.findUpStarStatus(self,data)
    local active = 0
    local msg = ""

    --无法升星
    if data.level2 <= 13 or (not gameConfig:checkBuildOpen(572)) or (not GameScene:checkopenlevelbyId(572,true)) or (GameScene.roleinfo.level < gamedata.config.build[tostring(572)].level) then
        active = 1
        return active
    end

    local nextConfig = gamedata.config.general_star[tostring(data.level5 + 1)]
    if nextConfig then

        --判断飞升等级
        if data.level8 < nextConfig.limitlv then
            active = 1
            return active
        end
        --判断消耗
        local consume = gamedata.getIDandNUMs(nextConfig.consume)
        for i,v in ipairs(consume) do
            if v.cid == 1000 then
                if v.num > 0 and GameScene.roleinfo.coin < v.num then
                    active = 1
                    return active
                end
            elseif v.cid == 1001 then
                if v.num > 0 and GameScene.roleinfo.gold < v.num then
                    active = 1
                    return active
                end
            else
                local havePropNum = self.hasprops[tostring(v.cid)] or 0
                if havePropNum < v.num then
                    active = 1
                    return active
                end
            end
        end
        
    end

    return active
end

--飞升
function generalList.findFeiShengStatus(self,data)

    local active = 0
    local msg = ""

    --无法飞升
    if (not gameConfig:checkBuildOpen(449)) or (not GameScene:checkopenlevelbyId(449,true) or not ui.judgeFeiSheng(data.cid)) then
        active = 1
        return active
    end

    local generalConfig = gamedata.config.general[tostring(data.cid)]
    local level = data.level8
    local curFeishengConfig = gamedata.config.partner_soaring[tostring(level)]
    local nextFeishengConfig = gamedata.config.partner_soaring[tostring(level + 1)]
    local originalBasic = gamedata.config.general[tostring(gamedata.getOriginCid(data.cid))].basic

    --最大级
    if not nextFeishengConfig then
        active = 1
        return active
    end

    --突破要求
    if nextFeishengConfig.breach and nextFeishengConfig.breach > 0 then
        if data.level2 < nextFeishengConfig.breach then
            active = 1
            return active
        end
    end
    
    --进修要求
    if nextFeishengConfig.immortal and nextFeishengConfig.immortal > 0 then
        --判断进修
        if data.level6 < nextFeishengConfig.immortal or data.level7 < nextFeishengConfig.immortal then
            active = 1
            return active
        end
    end

    --消耗
    local consume = ui.getIDandNUMs(nextFeishengConfig[originalBasic.."consume"])

    for i,v in ipairs(consume) do
        local havePropNum = self.hasprops[tostring(v.cid)] or 0
        local needPropNum = v.num or 0
        if needPropNum > havePropNum then
            active = 1
            return active
        end
    end
    return active
end

--突破
function generalList.findstatus(self,data)
    local configdata = gamedata.config.general[tostring(data.cid)]
    local active = 0
    local msg = ""
    --
    if not GameScene:checkopenlevelbyId(52,true) then
        active = 1
        msg = "等级不足，"..gamedata.config.build["52"].level.."级开启，努力升级吧！！"
        return active,msg
    elseif configdata.quality < 3 then
        active = 1
        msg = gameConfig.strings:string_common("general",6)
        return active,msg
    end
    --
    local redcid = (configdata.quality == 6) and data.cid or 0
    local goldcid = (configdata.quality >= 7) and data.cid or 0
    local ocid = data.cid
    if configdata.orange_id and configdata.orange_id > 0 then
        ocid = configdata.orange_id
    elseif configdata.generalid2 and configdata.generalid2 > 0 then
        ocid = configdata.generalid2
    elseif configdata.partner_id and configdata.partner_id > 0 then
        ocid = configdata.partner_id
    end 
    if configdata.red_id and configdata.red_id > 0 then
        redcid = configdata.red_id
    elseif configdata.break_id and configdata.break_id > 0 then
        redcid = configdata.break_id
    elseif (configdata.quality == 6) and configdata.partner_id and configdata.partner_id > 0 then
        redcid = configdata.partner_id   
    end   

    if configdata.gold_id and configdata.gold_id > 0 then
        goldcid = configdata.gold_id
    elseif (configdata.quality >= 7) and configdata.partner_id and configdata.partner_id > 0 then
        goldcid = configdata.partner_id     
    end

    local quality = configdata.quality or 5
    local nextnum = 0
    local nextlevel = 0
    local needprop,needcoin = 0,0
    local needredprop,needrednum,needredprop2 = 0,0
    local needawaken,needfavorate = 0,0
    local needgoldprop = {}
    local hasgoldprop = 1
    local needsoaring = 0
    if data.level2+1 <= table.getTableLength(gamedata.config.general_awake) then
        if data.level2+1 <= 10 then
            quality = configdata.quality or 5
        elseif data.level2+1 > 13 then
            if goldcid > 0 then 
                quality = 7
            else
                active = 2
                msg = gameConfig.strings:string_common("general",21)
                return active,msg
            end    
        elseif redcid > 0 then
            quality = 6
        else
            active = 2
            msg = gameConfig.strings:string_common("general",21)
            return active,msg
        end

        nextnum = gamedata.config.general_awake[tostring(data.level2+1)][quality.."piece"] or 0
        nextlevel = gamedata.config.general_awake[tostring(data.level2+1)].level or 0
        needprop = gamedata.config.general_awake[tostring(data.level2+1)][tostring(quality).."prop"] or 0
        needcoin = gamedata.config.general_awake[tostring(data.level2+1)]["coin"..tostring(quality)] or 0
        needredprop = gamedata.config.general_awake[tostring(data.level2+1)]["red_cost"] or 0
        needredprop2 = gamedata.config.general_awake[tostring(data.level2+1)]["red_cost2"] or 0
        needrednum = gamedata.config.general_awake[tostring(data.level2+1)]["red_item"] or 0
        needawaken = gamedata.config.general_awake[tostring(data.level2+1)]["awaken_lv"] or 0
        needfavorate = gamedata.config.general_awake[tostring(data.level2+1)]["favorate_lv"] or 0
        --
        --
        if gamedata.config.general_awake[tostring(data.level2+1)] and gamedata.config.general_awake[tostring(data.level2+1)].soaring_limit and gamedata.config.general_awake[tostring(data.level2+1)].soaring_limit > 0 then
            needsoaring = gamedata.config.general_awake[tostring(data.level2+1)].soaring_limit or 0
        end  
        hasgoldprop = 1
        needgoldprop = {}
        if gamedata.config.general_awake[tostring(data.level2+1)]["gold_cost"] and gamedata.config.general_awake[tostring(data.level2+1)]["gold_cost"] ~= "" then
            needgoldprop = gamedata.getIDandNUMs(gamedata.config.general_awake[tostring(data.level2+1)]["gold_cost"]) or {}
        end 
        for k,v in pairs(needgoldprop) do
            if v.num and v.num > 0 then
                if not (self.hasprops[tostring(v.cid)] and self.hasprops[tostring(v.cid)] >= v.num) then
                    active = 2
                    msg = ""
                    return active,msg
                end
            end
        end  
        --
        if needsoaring > data.level8 then
            active = 2
            msg = ""
            return active,msg
        end
        --
        --
        local favoratecid = ocid --data.cid
        -- if configdata.generalid2 and configdata.generalid2 > 0 then
        --     favoratecid = configdata.generalid2
        -- end
        local favoratelv = self.generalslovedata[tostring(favoratecid)] and self.generalslovedata[tostring(favoratecid)].level or 0
        if favoratelv < needfavorate then
            active = 2
            msg = ""
            return active,msg
        end
        --
        if needawaken > data.skilllevel then
            active = 2
            msg = ""
            return active,msg
        end
        --
        local ffnum = 0
        for k,v in pairs(self.fragmentsdata) do
            if v.cid == ocid then
                ffnum = v.num
            end
        end
        --
        local rfnum = 0
        for k,v in pairs(self.redfragmentsdata) do
            if v.cid == redcid+8000 then
                rfnum = v.num
            end
        end
        --
        if ffnum >= nextnum 
        and rfnum >= needrednum 
        and configdata.quality >= 3 
        and data.level1 >= nextlevel 
        and self.propnum >= needprop 
        and GameScene.roleinfo.coin >= needcoin 
        and self.redpropnum >= needredprop 
        and self.redpropnum2 >= needredprop2 then

        else
            active = 2
            msg = ""
            return active,msg
        end
    else
        active = 2
        msg = gameConfig.strings:string_common("general",21)
        return active,msg
    end
    --

    return active,msg
end

function generalList.setNormal(self,item,data,index,isdetail,status,feishengStatus)
    ui.setNewIcon(item,data)
    local configdata =  gamedata.config.general[tostring(data.cid)]
    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), 213)
    else
        ui.setLabelString(item.name,configdata.name..(data.level2>0 and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
    end
    -- item.power:setString("战斗力: "..data.power)
    item.power:setString("")--gameConfig.strings:powerNum(data.power))
    -- item.level:setString("等级："..data.level1)
    -- item.aptitude:setString("资质："..(configdata.basic+configdata.grow))
    item.level:setString(gameConfig.strings:string_common("general",16)..data.level1)
    local basic = configdata.basic
    local fixbasicstr = "basic"
    if configdata.quality and configdata.quality == 6 then
        fixbasicstr = "red_basic"
    end
    if configdata.quality and configdata.quality >= 7 then
        fixbasicstr = "gold_basic"
    end
    if configdata.awaken > 0 and data.skilllevel and basic < self.awakenConfig[tostring(data.skilllevel)][fixbasicstr] then
        basic = self.awakenConfig[tostring(data.skilllevel)][fixbasicstr]
    end
    item.aptitude:setString(gameConfig.strings:string_common("general",17)..(basic+configdata.grow))

    setSpriteFrameByName(item["type"], gameConfig.images[configdata.actor])
    if data.skilllevel > 0 and configdata.awaken > 0  then
        item.juexing_iocn:setVisible(true)
        item.juexing_stage:setVisible(true)
        item.name:setPositionX(367.0)
        setSpriteFrameByName(item.juexing_iocn,self.awakenConfig[tostring(data.skilllevel)].icon)
        ui.setLabelString(item.juexing_stage,self.awakenConfig[tostring(data.skilllevel)].stage,18)        
    else
        item.juexing_iocn:setVisible(false)
        item.juexing_stage:setVisible(false)
        item.name:setPositionX(299)
    end 

    ui.sethint(item.hint,(status == 0 or feishengStatus == 0))

    if data.ison == 2 then
        setSpriteFrameByName(item["ison"], "obj_z_2")
    elseif data.ison == 1 then
        setSpriteFrameByName(item["ison"], "obj_z_1")
    else
        setSpriteFrameByName(item["ison"], "alpha")
        ui.sethint(item.hint, false)
    end
    
    item.i_button:setTouchPriority(-104)
    item.i_button:setSwallowsTouch(true)
    item.i_button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        data.hashint_exclusive = nil
        gameWindows:openWindow("generalInfoRole",{data = {general = data, relation = data.relation or {}},pagetype = "info"})
    end, CCControlEventTouchUpInside)


    item.showButton:setRotation(isdetail and 180 or 0)
    item.showButton:setTouchPriority(-104)
    item.showButton:setSwallowsTouch(true)
    item.showButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        guide:setGuideProlayer(true)
        local location
        self.generalsSelected,location = ui.tableviewLocation(
            self.generalsListTableView,
            table.getTableLength(self.generalsdata),
            index,
            self.rootItems.generalsNode,
            self.generalsSelected,
            self.detailCellSize.y,
            self.normalCellSize.y
        )
        self.generalsListTableView:reloadData()
        self.generalsListTableView:setLuaContentOffset(0,location)
        if guide.controller then
            guide.controller:UIComplete(8062)
        end
    end, CCControlEventTouchUpInside)
end

function generalList.setDetail(self,item,data,status,msg,feishengStatus)
    local configdata = gamedata.config.general[tostring(data.cid)] or {}
    local fragment = {}
    if self.fragmentsdata then
        for k,v in pairs(self.fragmentsdata) do
            if v.cid == data.cid then
                fragment = v
            end
        end
    end

    -- ui.setLabelString(item.chuangongtext,"传 功",18)
    -- ui.setLabelString(item.peiyangtext,"培 养",18)
    -- ui.setLabelString(item.tupotext,"突 破",18)
    ui.setLabelString(item.chuangongtext,gameConfig.strings:string_common("general",3),18)
    ui.setLabelString(item.peiyangtext,gameConfig.strings:string_common("general",4),18)
    ui.setLabelString(item.tupotext,gameConfig.strings:string_common("general",5),18)
    ui.setLabelString(item.awakenText,gameConfig.strings:string_common("generalInfo",27),18)
    ui.setLabelString(item.xiuliantext,gameConfig.strings:string_common("general",40),18)
    ui.setLabelString(item.feishengtext,gameConfig.strings:string_common("general",48),18)

    if configdata.quality < 3 then
        ui.addGray("CCControlButton",item["tupoButton"])
        ui.addGray("CCLabelTTF",item["tupotext"])
        ui.addGray("CCControlButton",item["chuangongButton"])
        ui.addGray("CCLabelTTF",item["chuangongtext"])
        ui.addGray("CCControlButton",item["peiyangButton"])
        ui.addGray("CCLabelTTF",item["peiyangtext"])
    else
        ui.removeGray("CCControlButton",item["tupoButton"])
        ui.removeGray("CCLabelTTF",item["tupotext"])
        ui.removeGray("CCControlButton",item["chuangongButton"])
        ui.removeGray("CCLabelTTF",item["chuangongtext"])
        ui.removeGray("CCControlButton",item["peiyangButton"])
        ui.removeGray("CCLabelTTF",item["peiyangtext"])
    end

    if data.level1<=1 then
        ui.addGray("CCControlButton",item["peiyangButton"])
        ui.addGray("CCLabelTTF",item["peiyangtext"])
    elseif configdata.quality >= 3 then
        ui.removeGray("CCControlButton",item["peiyangButton"])
        ui.removeGray("CCLabelTTF",item["peiyangtext"])
    end
    if  not gameConfig:checkBuildOpen(174) or not GameScene:checkopenlevelbyId(174,true) or configdata.awaken == 0  then
        ui.addGray("CCControlButton",item["awakenButton"])
        ui.addGray("CCLabelTTF",item["awakenText"])
    else
        ui.removeGray("CCControlButton",item["awakenButton"])
        ui.removeGray("CCLabelTTF",item["awakenText"])        
    end
    if  not gameConfig:checkBuildOpen(378) or not GameScene:checkopenlevelbyId(378,true) or configdata.quality < 3 then
        ui.addGray("CCControlButton",item["xiulianButton"])
        ui.addGray("CCLabelTTF",item["xiuliantext"])
    else
        ui.removeGray("CCControlButton",item["xiulianButton"])
        ui.removeGray("CCLabelTTF",item["xiuliantext"]) 
    end
    if not GameScene:checkopenlevelbyId(51,true) then
        ui.addGray("CCControlButton",item["peiyangButton"])
        ui.addGray("CCLabelTTF",item["peiyangtext"])
    end

    if not GameScene:checkopenlevelbyId(135,true) then
        ui.addGray("CCControlButton",item["chuangongButton"])
        ui.addGray("CCLabelTTF",item["chuangongtext"])
    end

    if not GameScene:checkopenlevelbyId(52,true) then
        ui.addGray("CCControlButton",item["tupoButton"])
        ui.addGray("CCLabelTTF",item["tupotext"])
    end

    ui.sethint(item.hint_tupo,status == 0)
    ui.sethint(item.hint_feisheng,feishengStatus == 0)

    if data.ison ~= 2 and data.ison ~= 1 then
        ui.sethint(item.hint_tupo, false)
        ui.sethint(item.hint_feisheng, false)
    end

    item.tupoButton:setSwallowsTouch(true)
    item.tupoButton:setTouchPriority(-102)
    item.tupoButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        print("tupoButton clicked")
        guide:setGuideProlayer(true)
        if status ~= 1 then
            --gameWindows:openWindow("generalUp",{general = data,selectpage = "tupo"})
            GameScene:shiftLayer("generalup","up",{cid = data.cid, page = "tupo",})
        else
            runGamePrompt({msg = msg})
        end
    end, CCControlEventTouchUpInside)

    item.chuangongButton:setSwallowsTouch(true)
    item.chuangongButton:setTouchPriority(-102)
    item.chuangongButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        print("chuangongButton clicked")
        guide:setGuideProlayer(true)
        --gameWindows:openWindow("generalInfo",{data = {general = data, relation = data.relation or {}},pagetype = "inherit"})
        if configdata.quality < 3 then
            runGamePrompt({msg = "绿色伙伴无法通过经验丹升级"})
        else
            if not GameScene:checkopenlevelbyId(135) then return end
            GameScene:shiftLayer("generalup","up",{cid = data.cid, page = "up",})
        end
    end, CCControlEventTouchUpInside)

--    ui.addGray("CCControlButton",item["peiyangButton"])
--    ui.addGray("CCLabelTTF",item["peiyangtext"])
    item.peiyangButton:setSwallowsTouch(true)
    item.peiyangButton:setTouchPriority(-102)
    item.peiyangButton:addHandleOfControlEvent(function()
        --runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng2")})
        if not GameScene:checkopenlevelbyId(51) then return end
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        print("peiyangButton clicked")
        if configdata.quality < 3 then
            runGamePrompt({msg = "绿色伙伴无法培养"})
        elseif data.level1<=1 then
            runGamePrompt({msg = "1级伙伴无法培养"})
        else
            --gameWindows:openWindow("generalInfo",{data = {general = data, relation = data.relation or {}},pagetype = "train"})
            GameScene:shiftLayer("generalup","up",{cid = data.cid, page = "train",})
        end
    end, CCControlEventTouchUpInside)


    item.awakenButton:setSwallowsTouch(true)
    item.awakenButton:setTouchPriority(-102)
    item.awakenButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        print("peiyangButton clicked")
        if not gameConfig:checkBuildOpen(174) then
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng")})  
        elseif not GameScene:checkopenlevelbyId(174) then 
            return
        elseif configdata.awaken == 0 then
            runGamePrompt({msg =  gameConfig.strings:string_common("general",31) })
        
        elseif self.awakenConfig[tostring(1)].lv  > data.level1 then --判定伙伴等级
            runGamePrompt({msg =  gameConfig.strings:string_common("general",32) })
        else 
            GameScene:shiftLayer("generalup","up",{cid = data.cid , page = "awaken"})
        end
    end, CCControlEventTouchUpInside)
    
    item.xiulianButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        if not gameConfig:checkBuildOpen(378)  then
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng")}) 
        elseif  not GameScene:checkopenlevelbyId(378) then 
            return
        elseif configdata.quality < 3 then
            runGamePrompt({msg = gameConfig.strings:string_common("general",39)})
        -- elseif gamedata.config.Immortal_level["1"]["0"].generalLevel > data.level1 then
        --     runGamePrompt({msg =  gameConfig.strings:string_common("general",32)})
        else
            GameScene:shiftLayer("generalup","up",{cid = data.cid, page = "xiulian"})
        end
        if guide.controller then
            guide.controller:UIComplete(8063)
        end
    end, CCControlEventTouchUpInside)
    item.xiulianButton:setSwallowsTouch(true)
    item.xiulianButton:setTouchPriority(-102)


    if ui.judgeFeiSheng(data.cid) and gameConfig:checkBuildOpen(449) and GameScene:checkopenlevelbyId(449,true) then
        ui.removeGray("CCControlButton",item.feishengButton)
        ui.removeGray("CCLabelTTF",item.feishengtext)
    else
        ui.addGray("CCControlButton",item.feishengButton)
        ui.addGray("CCLabelTTF",item.feishengtext)
    end

    item.feishengButton:addHandleOfControlEvent(function()
        if not gameConfig:checkBuildOpen(449)  then
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng")}) 
        elseif not GameScene:checkopenlevelbyId(449) then 
            return
        else
            if ui.judgeFeiSheng(data.cid) then
                GameScene:shiftLayer("generalup","up",{cid = data.cid, page = "feisheng"})
            else
                runGamePrompt({msg = gameConfig.strings:string_common("general",53)})
            end
        end
    end, CCControlEventTouchUpInside)
    item.feishengButton:setSwallowsTouch(true)
    item.feishengButton:setTouchPriority(-102)
end

-- 武将列表
function generalList.setGeneralCell(self,data,items,index,selectpage)

    local key_Ex
    local id = index-1
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end
    ui.sethint(items["i_hint"..key_Ex],false)
    if selectpage == "generals" then
        -- 设置头像
        if data.illusionGeneralCid == nil then
            local configGeneral = gamedata.config.general[tostring(data.cid)]
            local gdata = ui.getConfigGeneral(data)
            if next(gdata) and configGeneral.fashion_id == 0 then
                ui.setPropIcon(items, {cid = data.cid, num = data.num}, index-1, data, gdata)
            else
                ui.setPropIcon(items, {cid = data.cid, num = data.num}, index-1, data)
            end
        else
            ui.setPropIcon(items, {cid = data.cid, num = data.num}, index-1, data)
        end
        
        local configdata = ui.IDconfig(data.cid) or {}
        if data.quality and data.quality >= 7 then
            ui.setLabelString(items["i_name"..key_Ex],configdata.name..(data.level2>0 and "+"..data.level2 or ""), 213)
        else
            ui.setLabelString(items["i_name"..key_Ex],configdata.name..(data.level2>0 and "+"..data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
        end

        if items["i_isonNode"..key_Ex] then
            if data.ison then
                items["i_isonNode"..key_Ex]:setVisible(true)
                if data.ison == 1 then
                    items["i_isonLab"..key_Ex]:setString("助阵中")
                else
                    items["i_isonLab"..key_Ex]:setString("已上阵")

                    local status,msg = self:findstatus(data)
                    local feishengStatus = self:findFeiShengStatus(data)
                    local upstarStatus = self:findUpStarStatus(data)

                    print("hintStatus",status,feishengStatus,upstarStatus)

                    ui.sethint(items["i_hint"..key_Ex],(status == 0 or feishengStatus == 0 or upstarStatus == 0))
                    items["i_hint"..key_Ex]:setPosition(165,170)

                end
            else
                items["i_isonNode"..key_Ex]:setVisible(false)
            end
        end

    elseif selectpage == "fragments" then
        ui.setPropIcon(items, {cid = data.cid}, index-1)
        setSpriteFrameByName(items["i_soulsprite"..key_Ex], "b_soulsprite")
        -- if data.quality and data.quality >= 7 then
        --     ui.setLabelString(items["i_name"..key_Ex],gameConfig.strings:hunpo(configdata.name), 213)
        -- else
        --     ui.setLabelString(items["i_name"..key_Ex],gameConfig.strings:hunpo(configdata.name),((data.quality and data.quality ~= 0) and data.quality or 1)*2-1)
        -- end

        if items["barNode"..key_Ex] then
            items["barNode"..key_Ex]:setVisible(true)
            if data.status == 2 then 
                ui.setLabelString(items["barLabel"..key_Ex], data.num, 14)
            else
                ui.sethint(items["i_hint"..key_Ex],data.neednum <= data.num)
                items["i_hint"..key_Ex]:setPosition(160,-45)

                ui.setLabelString(items["barLabel"..key_Ex], data.num.."/"..data.neednum, 14)
                ui.setSpriteTextureRect2(items["bar_bright"..key_Ex],0,0,154*(data.num < data.neednum and data.num/data.neednum or 1),30)
            end
        end

        

    elseif selectpage == "redfragments" then
        ui.setPropIcon(items, {cid = data.cid}, index-1)
        if items["barNode"..key_Ex] then
            items["barNode"..key_Ex]:setVisible(true)
            ui.setLabelString(items["barLabel"..key_Ex], data.num, 14)
        end
    end

    items["i_button"..key_Ex]:setTouchPriority(-104)
    -- items["i_button"..key_Ex]:setSwallowsTouch(true)
    items["i_button"..key_Ex]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        -- pageconfig = {"generals","fragments","redfragments"}
        if self.selectpage == "generals" then
            data.hashint_exclusive = nil
            gameWindows:openWindow("generalInfoRole",{data = {general = data, relation = data.relation or {}},pagetype = "info"})
        elseif self.selectpage == "fragments" then
            ui.setPopwindowByCid(data.fragmentCid,data)
            -- gameWindows:openWindow("infoAndAccess",{prop = { cid = data.cid, param = data }, pagetype = "info"})
        elseif self.selectpage == "redfragments" then
            ui.setPopwindowByCid(data.cid,data)
        end
        -- 
    end, CCControlEventTouchUpInside)
end

function generalList.createGeneralsList(self)
    local celldict = {}
    local generalsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("general/cell_general_icon", nil, true, "cell_general_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.generalsListTableView,cellCCB,self.normalCellSize.x/2+30,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- self:setNormal(ccbDocumentControler,self.generalsdata[tostring(a1+1)],a1+1,nil,status,feishengStatus)
            for i=4,0,-1 do
                if self.generalsdata[(a1+1)*5-i] or self.generalsdata[tostring((a1+1)*5-i)] then

                    self:setGeneralCell(self.generalsdata[(a1+1)*5-i] or self.generalsdata[tostring((a1+1)*5-i)],ccbDocumentControler,5-i,"generals")
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                else
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end

            if self.generalsListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2+30, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.generalsdata)
            r = math.ceil(table.getTableLength(self.generalsdata)/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.generalsListTableView = ui.createLuaTableView({
        handle = generalsListHandle,
        viewwidth = self.rootItems.generalsNode:getContentSize().width,
        viewheight = self.rootItems.generalsNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.generalsNode:addChild(self.generalsListTableView)
    self.generalsListTableView:setTouchPriority(-101)
end

-- function generalList.createGeneralsList(self)
--     local celldict = {}
--     local generalsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
--         local r
--         if fn == "cellSize" then

--         elseif fn == "hasFixedCellSize" then
--             r = false
--         elseif fn == "cellSizeForIndex" then
--             if self.generalsSelected and self.generalsSelected == a1+1 then
--                 r = CCSizeMake(self.detailCellSize.x, self.detailCellSize.y)
--             else
--                 r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
--             end
--         elseif fn == "isRecycle" then
--             for k,v in pairs (self.unrecycleCell) do
--                 if a2 == v.cell then
--                     print("unrecycleCELL ")
--                     return false
--                 end
--             end
--             return true
--         elseif fn == "cellAtIndex" then
--             if self.generalsSelected and self.generalsSelected == a1+1 then
--                 local ccb, items,ccb1, items1
--                 if self.unrecycleCell.detailCell == nil then
--                     a2 = CCTableViewCell:create()
--                     ccb, items =  CCBReaderLoad("general/cell_general", nil, true, "cell_general")
--                     ccb1, items1 =  CCBReaderLoad("general/cell_general_pop", nil, true, "cell_general_pop")

--                     ccb1:setPosition(self.detailCellSize.x/2, -self.detailCellSize.y)
--                     a2:addChild(ccb1)
--                     ccb:setPosition(self.detailCellSize.x/2, -self.normalCellSize.y)
--                     a2:addChild(ccb)

--                     self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1}
--                     self.unrecycleCell.detailCell.cell:retain()
--                 else
--                     a2 = self.unrecycleCell.detailCell.cell
--                     ccb = self.unrecycleCell.detailCell.ccb
--                     items = self.unrecycleCell.detailCell.items
--                     ccb1 = self.unrecycleCell.detailCell.ccb1
--                     items1 = self.unrecycleCell.detailCell.items1
--                 end

--                 local status,msg = self:findstatus(self.generalsdata[tostring(a1+1)])
--                 local feishengStatus = self:findFeiShengStatus(self.generalsdata[tostring(a1+1)])
--                 self:setNormal(items,self.generalsdata[tostring(a1+1)],a1+1,true,status,feishengStatus)
--                 self:setDetail(items1,self.generalsdata[tostring(a1+1)],status,msg,feishengStatus)
--             else
--                 local cellCCB,ccbDocumentControler = 0,0
--                 local first = true
--                 if not a2 then
--                     a2 = CCTableViewCell:create()
--                     cellCCB, ccbDocumentControler = CCBReaderLoad("general/cell_general", nil, true, "cell_general")
--                     celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
--                     ui.tableviewAnimation(self.generalsListTableView,cellCCB,self.normalCellSize.x/2,-self.normalCellSize.y,a1)
--                 else
--                     first = false
--                     cellCCB = celldict[a2].cellCCB
--                     ccbDocumentControler = celldict[a2].ccbDocumentControler
--                 end

--                 local status,msg = self:findstatus(self.generalsdata[tostring(a1+1)])
--                 local feishengStatus = self:findFeiShengStatus(self.generalsdata[tostring(a1+1)])
--                 self:setNormal(ccbDocumentControler,self.generalsdata[tostring(a1+1)],a1+1,nil,status,feishengStatus)

--                 if self.generalsListTableView then
--                     cellCCB:setPosition(self.normalCellSize.x/2, -self.normalCellSize.y)
--                 end

--                 if first then
--                     a2:addChild(cellCCB)
--                 end
--             end
--             r = a2

--         elseif fn == "numberOfCells" then
--             r = table.getTableLength(self.generalsdata)
--         elseif fn == "cellTouched" then

--         elseif fn == "scrollViewDidScroll" then
--             --gameTouch.isScrollling = true
--         end
--         return r
--     end)

--     self.generalsListTableView = ui.createLuaTableView({
--         handle = generalsListHandle,
--         viewwidth = self.rootItems.generalsNode:getContentSize().width,
--         viewheight = self.rootItems.generalsNode:getContentSize().height,
--         dire = 1
--     })
--     self.rootItems.generalsNode:addChild(self.generalsListTableView)
--     self.generalsListTableView:setTouchPriority(-101)
-- end

function generalList.ReloadGenerals(self,data)

    --self.generalsSelected = nil
    self.generalsdata = data

end

function generalList.showGenerals(self)
    UIRequest({type = 12001,order = 10121,cids = {20017,20354,20551,20811,20812,20813,20814,20815,20816,1000,20818,20817,20819,20820,20821,20890,20891,20892,20893,20067,20068,20069,20070,20071,20072,1025}})
end

function generalList.setGneneral(self,prop)
    self.hasprops = prop or {}
    self.propnum = prop["20017"] or 0
    self.redpropnum = prop["20354"] or 0
    self.redpropnum2 = prop["20551"] or 0
    if self.rootItems then
        if not self.generalsListTableView then
            self:createGeneralsList()
        else
            -- if self.isdetail then
            --     self.generalsListTableView:setLuaContentOffset(0, self.generalsListTableView:getLuaContentOffsetY()+160)
            -- end
            if self.generalsListTableView:getLuaContentOffsetY() < self.rootItems.generalsNode:getContentSize().height - math.ceil(table.getTableLength(self.generalsdata)/5)*self.normalCellSize.y then
                self.generalsListTableView:setLuaContentOffset(0, self.rootItems.generalsNode:getContentSize().height - math.ceil(table.getTableLength(self.generalsdata)/5)*self.normalCellSize.y)
            end
            self.generalsListTableView:reloadData()
        end
        ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.generalsdata) == 0,"general")
    end
end

function generalList.ReloadFragments(self,data)
    self.fragmentsdata = {}
    local generalData = data.generalfragments
    for k,v in pairs(generalData) do
        table.insert(self.fragmentsdata, v)
    end

    for k,v in pairs(self.fragmentsdata) do
        if v.status == 1 then
            if v.num >= v.neednum then
                v.sorting = v.status + (10-v.quality)*10000 + v.cid
            else
                v.sorting = v.status * 10 + (10 - v.quality) * 100000 + v.cid
            end
        else
            v.sorting = v.status * 100 + (10 - v.quality) * 1000000 + v.cid
        end
    end

    table.sort(self.fragmentsdata, function(a, b)
        return a.sorting < b.sorting
    end)
end

function generalList.showFragments(self)
    if self.rootItems then
        if not self.fragmentsListTableView then
            self:createFragmentsList()
        else
            if self.fragmentsListTableView:getLuaContentOffsetY() < self.rootItems.fragmentsNode:getContentSize().height - math.ceil(table.getTableLength(self.fragmentsdata)/5)*self.normalCellSize.y then
                self.fragmentsListTableView:setLuaContentOffset(0, self.rootItems.fragmentsNode:getContentSize().height - math.ceil(table.getTableLength(self.fragmentsdata)/5)*self.normalCellSize.y)
            end
            self.fragmentsListTableView:reloadData()
        end
        ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.fragmentsdata) == 0,"generalfragment")
    end
end

function generalList.ReloadRedFragments(self,data)
    self.redfragmentsdata = {}
    local redData = data
    -- local priority = gamedata.config.redl_awake_item[tostring(v.cid)].priority
    for k,v in pairs(redData) do
        table.insert(self.redfragmentsdata, v)
    end

    for k,v in pairs(self.redfragmentsdata) do
        v.priority = gamedata.config.redl_awake_item[tostring(v.cid)].priority
    end

    table.sort(self.redfragmentsdata, function(a, b)
        return a.priority > b.priority
    end)
end

function generalList.showRedFragments(self)
    if self.rootItems then
        if not self.redfragmentsListTableView then
            self:createRedFragmentsList()
        else
            if self.redfragmentsListTableView:getLuaContentOffsetY() < self.rootItems.redfragmentsNode:getContentSize().height - math.ceil(table.getTableLength(self.redfragmentsdata)/5)*self.normalCellSize.y then
                self.redfragmentsListTableView:setLuaContentOffset(0, self.rootItems.redfragmentsNode:getContentSize().height - math.ceil(table.getTableLength(self.redfragmentsdata)/5)*self.normalCellSize.y)
            end
            self.redfragmentsListTableView:reloadData()
        end
        ui.setGoto(self.rootItems.gotonode,false,"generalfragment")
    end
end

function generalList.shiftPage(self,type)
    self.selectpage = type

    for k,v in ipairs(self.pageconfig) do
        if v == type then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPositionX(0)
        else
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPositionX(9999)
        end
    end

    if type == "generals" then
        if not GameScene:checkUpdate(10023) then
            self:showGenerals()
        end

    elseif type == "fragments" then
        if not GameScene:checkUpdate(1012) then
            self:showFragments()
        end

    elseif type == "redfragments" then
        if not GameScene:checkUpdate(10030) then
            self:showRedFragments()
        end

    elseif type == "exchange" then
        if not self.exchangeData or not next(self.exchangeData) then
            UIRequest({type = 10211})
        else
            if not GameScene:checkUpdate(10211) then
                self:ReloadData()
            end
        end

    end
end

function generalList.createFragmentsList(self)

    local celldict = {}
    local fragmentsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("general/cell_general_icon", nil, true, "cell_fragment")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.fragmentsListTableView,cellCCB,self.normalCellSize.x/2+30,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- self:setFragments(ccbDocumentControler,self.fragmentsdata[(a1+1)])
            for i=4,0,-1 do
                if self.fragmentsdata[(a1+1)*5-i] or self.fragmentsdata[tostring((a1+1)*5-i)] then
                    self:setGeneralCell(self.fragmentsdata[(a1+1)*5-i] or self.fragmentsdata[tostring((a1+1)*5-i)],ccbDocumentControler,5-i,"fragments")
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                else
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end

            if self.fragmentsListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2+30, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.fragmentsdata)
            r = math.ceil(table.getTableLength(self.fragmentsdata)/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.fragmentsListTableView = ui.createLuaTableView({
        handle = fragmentsListHandle,
        viewwidth = self.rootItems.fragmentsNode:getContentSize().width,
        viewheight = self.rootItems.fragmentsNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.fragmentsNode:addChild(self.fragmentsListTableView)
    self.fragmentsListTableView:setTouchPriority(-101)
end

function generalList.setFragments(self,item,data)
    printT(data,"data ============")
    ui.setIconLv(item,data)
    local configdata =  gamedata.config.general[tostring(data.cid)]
    -- ui.setLabelString(item.name,configdata.name.."魂魄", configdata.quality and 2*configdata.quality-1 or 1)
    ui.setLabelString(item.name,gameConfig.strings:hunpo(configdata.name), configdata.quality and 2*configdata.quality-1 or 1)

    setSpriteFrameByName(item["type"], gameConfig.images[configdata.actor])
    setSpriteFrameByName(item["il_fragment"], "b_soulsprite")

    -- item.num:setString("数量: "..data.num .. "/" .. (data.num + data.neednum == 0 and "已达最高阶" or (data.num + data.neednum)))
    if data.neednum <= 0 or data.status ==2 then
        item.num:setString(gameConfig.strings:string_common("general",12)..data.num)
    else
        item.num:setString(gameConfig.strings:string_common("general",12)..data.num .. "/" .. data.neednum)
    end

    item.recruit:setTouchPriority(-102)
    if data.status == 2 then
        setControlButtonFrame(item.recruit,"b_s_button1","b_s_button1_h","b_s_button1")
        ui.setLabelString(item.lb_recruit,gameConfig.strings:string_common("ui",19),18)
        item.alreadyHave:setVisible(true)
        item.recruit:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            gameWindows:openWindow("dropTips",{cid = data.fragmentCid},nil)
        end, CCControlEventTouchUpInside)
    else
        item.alreadyHave:setVisible(false)
        if data.neednum > data.num then
            setControlButtonFrame(item.recruit,"b_s_button1","b_s_button1_h","b_s_button1")
            ui.setLabelString(item.lb_recruit,gameConfig.strings:string_common("ui",19),18)
            item.recruit:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                gameWindows:openWindow("dropTips",{cid = data.fragmentCid},nil)
            end, CCControlEventTouchUpInside)
        else
            -- ui.setLabelString(item.lb_recruit,"招 募",18)
            setControlButtonFrame(item.recruit,"b_s_button2","b_s_button2_h","b_s_button2")
            ui.setLabelString(item.lb_recruit,gameConfig.strings:string_common("general",8),18)
            item.recruit:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                UIRequest({type = 1016, ids = {data.cid}})
            end, CCControlEventTouchUpInside)
        end
    end

    item.il_button:setTouchPriority(-104)
    item.il_button:setSwallowsTouch(true)
    item.il_button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end        
        ui.setPopwindowByCid(data.cid,data)
    end, CCControlEventTouchUpInside)
end


--
function generalList.createRedFragmentsList(self)

    local celldict = {}
    local redfragmentsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("general/cell_general_icon", nil, true, "cell_redfragment")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.redfragmentsListTableView,cellCCB,self.normalCellSize.x/2+30,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- self:setRedFragments(ccbDocumentControler,self.redfragmentsdata[(a1+1)])
            for i=4,0,-1 do
                if self.redfragmentsdata[(a1+1)*5-i] or self.redfragmentsdata[tostring((a1+1)*5-i)] then
                    self:setGeneralCell(self.redfragmentsdata[(a1+1)*5-i] or self.redfragmentsdata[tostring((a1+1)*5-i)],ccbDocumentControler,5-i,"redfragments")
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(true)
                else
                    ccbDocumentControler["cell_icon"..(5-i)]:setVisible(false)
                end
            end

            if self.redfragmentsListTableView then
                cellCCB:setPosition(self.normalCellSize.x/2+30, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.redfragmentsdata)
            r = math.ceil(table.getTableLength(self.redfragmentsdata)/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.redfragmentsListTableView = ui.createLuaTableView({
        handle = redfragmentsListHandle,
        viewwidth = self.rootItems.redfragmentsNode:getContentSize().width,
        viewheight = self.rootItems.redfragmentsNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.redfragmentsNode:addChild(self.redfragmentsListTableView)
    self.redfragmentsListTableView:setTouchPriority(-101)
end

function generalList.setRedFragments(self,item,data)
    printT(data,"data ============")

    ui.setNewIcon(item,{cid = data.cid})
    local configdata =  gamedata.config.general[tostring(data.cid-8000)]
    setSpriteFrameByName(item["type"], gameConfig.images[configdata.actor])

    ui.setLabelString(item.name,ui.IDconfig(data.cid).name or "", ui.IDconfig(data.cid).quality and 2*ui.IDconfig(data.cid).quality-1 or 1)

    item.num:setString("数量: "..data.num )

    item.recruit:setTouchPriority(-102)
    ui.setLabelString(item.lb_recruit,gameConfig.strings:string_common("ui",19),18)
    item.alreadyHave:setVisible(false)
    item.recruit:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        gameWindows:openWindow("dropTips",{cid = data.cid},nil)
    end, CCControlEventTouchUpInside)

    --
    item.i_button:setTouchPriority(-104)
    item.i_button:setSwallowsTouch(true)
    item.i_button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        ui.setPopwindowByCid(data.cid,data)
    end, CCControlEventTouchUpInside)
end
--

function generalList.createList(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize_ex.x, self.normalCellSize_ex.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("general/cell_exchange", nil, true, "cell_exchange")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.ListTableView,cellCCB,self.normalCellSize_ex.x/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setExchange(ccbDocumentControler,self.exchangeData[a1+1])

            if self.ListTableView then
                cellCCB:setPosition(self.normalCellSize_ex.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.exchangeData)
            -- r = math.ceil(table.getTableLength(self.exchangeData)/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.exchangeNode:getContentSize().width,
        viewheight = self.rootItems.exchangeNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.exchangeNode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end


function generalList.setExchange(self,item,data)

    --printT(item)
    if data.gold > 0 then
        item["goldNode"]:setVisible(true)
        -- item["gold"]:setString("消耗元宝"..data.gold)
        item["gold"]:setString(gameConfig.strings:ctgold(data.gold))
    else
        item["goldNode"]:setVisible(false)
    end
    if data.coin > 0 then
        item["coinNode"]:setVisible(true)
        -- item["coin"]:setString("消耗银币"..data.coin)
        item["coin"]:setString(gameConfig.strings:ctcoin(data.coin))
    else
        item["coinNode"]:setVisible(false)
    end

    local generals = ui.Split(data.generals,";")

    local has = {false,false,false}

    for i=1,3 do
        item["i_button"..(i==1 and "" or "_"..(i-1))]:setTouchPriority(-102)
        if generals[i] then
            item["g"..i]:setVisible(true)
            for k, v in pairs( self.allgenerals ) do
                if 0+v.cid == 0+generals[i] then
                    has[i] = true
                end
            end
            ui.setNewIcon(item,{num = has[i] and "1/1" or "0/1",cid = generals[i]},i-1)
            if has[i] then
                ui.setLabelString(item["i_num"..(i==1 and "" or "_"..(i-1))],nil,22)
            else
                ui.setLabelString(item["i_num"..(i==1 and "" or "_"..(i-1))],nil,24)
            end
            item["i_button"..(i==1 and "" or "_"..(i-1))]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(generals[i])
            end, CCControlEventTouchUpInside)
        else
            item["g"..i]:setVisible(false)
            has[i]=true
            item["i_button"..(i==1 and "" or "_"..(i-1))]:addHandleOfControlEvent(function()
                -- if not self.isscrolltouched then return end
                -- if gameTouch.isScrollling then return end
            end, CCControlEventTouchUpInside)
        end
    end

    if data.target then
        if gamedata.config.general[tostring(data.target)] then
            ui.setNewIcon(item,{cid = data.target},3)
            item.i_button_3:setTouchPriority(-102)
            item.i_button_3:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(data.target)
            end, CCControlEventTouchUpInside)

        end
    end

    if has[1] and has[2] and has[3] then
        ui.removeGray("CCControlButton",item.buyButton)
        ui.removeGray("CCLabelTTF",item.buyLab)
        if data.gold > 0 then
            item.buyButton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                gameTouch:clickprofbytime(0.5)
                if  data.gold > self.gold then
                    shortGold()
                else
                    UIRequest({type = 1021, configid = data.id})
                    gamedata.music:PlayOptSound("wjdh")
                end
            end, CCControlEventTouchUpInside)

        elseif data.coin > 0 then
            item.buyButton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                gameTouch:clickprofbytime(0.5)
                if  data.coin > self.coin then
                    -- runGamePrompt({msg = "银币不足"})
                    --runGamePrompt({msg = gameConfig.strings:string_common("general",9)})
                    shortCoin()
                else
                    UIRequest({type = 1021, configid = data.id})
                    gamedata.music:PlayOptSound("wjdh")
                end
            end, CCControlEventTouchUpInside)
        end
    else
        item.buyButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            -- runGamePrompt({msg = "所需伙伴不足"})
            runGamePrompt({msg = gameConfig.strings:string_common("general",10)})
        end, CCControlEventTouchUpInside)
        ui.addGray("CCControlButton",item.buyButton)
        ui.addGray("CCLabelTTF",item.buyLab)
    end

    item.buyButton:setTouchPriority(-102)
    -- ui.setLabelString(item.buyLab,"兑 换",18)
    ui.setLabelString(item.buyLab,gameConfig.strings:string_common("general",11),18)
end

function generalList.ReloadData(self,data)
    print("ReloadData")

    if data then
        self.allgenerals = data.generals or {}
        self.coin = data.coin
        self.gold = data.gold

        self.exchangeData = {}
        for k, v in pairs( data.openids ) do
            table.insert(self.exchangeData,gamedata.config.general_exchange[v])
        end
        local sortfunc = function (a,b)
            if  a.id < b.id  then
                return true
            else
                return false
            end
        end

        table.sort(self.exchangeData,sortfunc)
    end

    if self.rootItems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
        ui.setGoto(self.rootItems.gotonode,false,"general")
    end
end

function generalList.UIUpdateData(self, isreset)

    self:shiftPage(self.selectpage)

end

return generalList
