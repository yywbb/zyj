--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午5:59
-- To change this template use File | Settings | File Templates.
--

local roleinfo = {
    rootNode = nil,
    rootItems = nil,

    profileNode = nil,
    profileItems = nil,

    titleNode = nil,
    titleItems = nil,

    iconBoxNode = nil,
    iconBoxItems = nil,

    icondata = {},
    titledata = {},
    iconBoxdata = {},

    listview = nil,
    listviewIconBox = nil,
    listviewTitle = nil,

}

function roleinfo.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.animationNode = CCNode:create()
    self.rootNode, self.rootItems = CCBReaderLoad("MainScene/player_info", nil, true, "player_info")
    self.animationNode:addChild(self.rootNode)
    self.root:addChild(self.animationNode)

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.root
end

function roleinfo.relaodIconData(self,data)
    local dataIcon = {}
    local copydataIcon = {}
    for k,v in pairs(data) do
        if v==1 then
            local config = ui.IDconfig(tonumber(k))
            if not config.quality or config.quality == 0 or (config.generalid >=10101 and config.generalid <=10115) or (config.generalid >=10997 and config.generalid <=10999) or (config.generalid >=162001 and config.generalid <=162003) then
            else
                if config.generalid >= 160001 then
                    table.insert(dataIcon,{cid = config.generalid,quality = config.quality})
                end
                table.insert(self.icondata,{cid = config.generalid,quality = config.quality})
            end
        end
    end

    if GameScene.protagonist.general.cid >=10101 and GameScene.protagonist.general.cid <=10105 then
        for i=10101,GameScene.protagonist.general.cid do
            table.insert(self.icondata,{cid = i,quality = 6})
        end
    end
    if GameScene.protagonist.general.cid >=10106 and GameScene.protagonist.general.cid <=10110 then
        for i=10106,GameScene.protagonist.general.cid do
            table.insert(self.icondata,{cid = i,quality = 6})
        end
    end
    if GameScene.protagonist.general.cid >=10111 and GameScene.protagonist.general.cid <=10115 then
        for i=10111,GameScene.protagonist.general.cid do
            table.insert(self.icondata,{cid = i,quality = 6})
        end
    end

    if (GameScene.protagonist.general.cid >=10116 and GameScene.protagonist.general.cid <=10199) or 
        (GameScene.protagonist.general.cid >=10901 and GameScene.protagonist.general.cid <=10999) then
        table.insert(self.icondata,{cid = GameScene.protagonist.general.cid,quality = 6})
    end

    if (GameScene.protagonist.general.cid >=162001 and GameScene.protagonist.general.cid <=162003) then
        table.insert(self.icondata,{cid = GameScene.protagonist.general.cid,quality = 7})
    end

    if (GameScene.protagonist.general.cid >=162004 and GameScene.protagonist.general.cid <=162030) then
        table.insert(self.icondata,{cid = GameScene.protagonist.general.cid,quality = 7})
    end

    if (GameScene.protagonist.general.cid >= 162052 and GameScene.protagonist.general.cid <= 162093) then
        table.insert(self.icondata,{cid = GameScene.protagonist.general.cid,quality = gamedata.config.general[tostring(GameScene.protagonist.general.cid)].quality})
    end

    if GameScene.partnerfashion and next(GameScene.partnerfashion) then
        for k,v in pairs(GameScene.partnerfashion) do
            if v.time ~= 0 then
                if gamedata.config.partner_fashion[tostring(v.id)] and gamedata.config.partner_fashion[tostring(v.id)].gold_partner2 and gamedata.config.partner_fashion[tostring(v.id)].gold_partner2 > 0 and data[tostring(gamedata.config.partner_fashion[tostring(v.id)].gold_partner2)] and data[tostring(gamedata.config.partner_fashion[tostring(v.id)].gold_partner2)] == 1 then
                    for m,n in pairs(dataIcon) do
                        if n.cid == gamedata.config.partner_fashion[tostring(v.id)].gold_partner then
                            table.insert(copydataIcon,{cid = gamedata.config.partner_fashion[tostring(v.id)].gold_partner,quality = 7})
                        end
                    end
                    table.insert(self.icondata,{cid = gamedata.config.partner_fashion[tostring(v.id)].gold_partner,quality = 7})
                elseif gamedata.config.partner_fashion[tostring(v.id)] and gamedata.config.partner_fashion[tostring(v.id)].red_partner2 and gamedata.config.partner_fashion[tostring(v.id)].red_partner2 > 0 and data[tostring(gamedata.config.partner_fashion[tostring(v.id)].red_partner2)] and data[tostring(gamedata.config.partner_fashion[tostring(v.id)].red_partner2)] == 1 then
                    for m,n in pairs(dataIcon) do
                        if n.cid == gamedata.config.partner_fashion[tostring(v.id)].red_partner then
                            table.insert(copydataIcon,{cid = gamedata.config.partner_fashion[tostring(v.id)].red_partner,quality = 6})
                        end
                    end
                    table.insert(self.icondata,{cid = gamedata.config.partner_fashion[tostring(v.id)].red_partner,quality = 6})
                elseif gamedata.config.partner_fashion[tostring(v.id)] and gamedata.config.partner_fashion[tostring(v.id)].orange_partner2 and gamedata.config.partner_fashion[tostring(v.id)].orange_partner2 > 0 and data[tostring(gamedata.config.partner_fashion[tostring(v.id)].orange_partner2)] and data[tostring(gamedata.config.partner_fashion[tostring(v.id)].orange_partner2)] == 1 then
                    for m,n in pairs(dataIcon) do
                        if n.cid == gamedata.config.partner_fashion[tostring(v.id)].orange_partner then
                            table.insert(copydataIcon,{cid = gamedata.config.partner_fashion[tostring(v.id)].orange_partner,quality = 5})
                        end
                    end
                    table.insert(self.icondata,{cid = gamedata.config.partner_fashion[tostring(v.id)].orange_partner,quality = 5})
                end 
            end    
        end   
        
        printT(copydataIcon,"copydataIcon")

        self:get_diff(self.icondata,copydataIcon)
        for k,v in pairs(copydataIcon) do
            if nil ~= v then
                table.insert(self.icondata,v)
            end
        end
    end    

    ui.sortData(self.icondata,"quality","cid")

    printT(self.icondata,"self.icondata")

    self:moveto("profile")
end

 
function roleinfo.get_diff(self,a,b)
    for k1, v1 in ipairs(a) do
        for k2, v2 in ipairs(b) do
            --删除重复table数据
            for i=1,#b do
                if v1.cid == v2.cid then
                    table.remove(a, k1)
                end
            end
        end
    end
end

function roleinfo.relaodTitleData(self,data)
    
    self.titledata = {}

    local defautTitleCid = 35501

    local config = table.copy(gamedata.config.title)
    --time -1 永久
    --默认 2 使用中 1 获得未使用 0 未获得 -1
    for k,v in pairs(config) do

        if data[tostring(v.id)] then
            
            if GameScene.roleinfo.title == v.id then
                v.useStatus = 1
            else
                v.useStatus = 0
            end

            v.time = data[tostring(v.id)]
        else
           if defautTitleCid == v.id then
                if GameScene.roleinfo.title == v.id then
                    v.useStatus = 1
                    v.time = -1
                else
                    v.useStatus = 0
                    v.time = -1
                end
            else
                v.time = 0
                v.useStatus = -1
            end
        end

        v.priority = -v.id + (v.useStatus+2) * 1000000

        if v.useStatus == 0 then
            local isHint = false
            for i2,v2 in ipairs(GameScene.titleHintData["title"]) do
                if v2.cid == v.id then
                    isHint = true
                    break
                end
            end
            if isHint then
                v.priority = 1000000000 - v.id
            end
        end

        if v.id ~= defautTitleCid then
            table.insert(self.titledata,v)
        end
        
    end

    table.sort(self.titledata,function ( a,b)
        return tonumber(a.priority) > tonumber(b.priority)
    end)


    local defautConfig = config[tostring(defautTitleCid)]
    table.insert(self.titledata,1,defautConfig)

    self:moveto("title")
end

function roleinfo.relaodIconBoxData(self,data)
   
    printT(data,"relaodIconBoxData")
    self.iconBoxdata = {}

    local defautIconBoxCid = 35001

    local config = table.copy(gamedata.config.headframe)
    --time -1 永久
    --默认 2 使用中 1 获得未使用 0 未获得 -1
    for k,v in pairs(config) do

        if data[tostring(v.id)] then
            if GameScene.roleinfo.iconBox == v.id then
                v.useStatus = 1
            else
                v.useStatus = 0
            end

            v.time = data[tostring(v.id)]
        else

            if defautIconBoxCid == v.id then
                if GameScene.roleinfo.iconBox == v.id then
                    v.useStatus = 1
                    v.time = -1
                else
                    v.useStatus = 0
                    v.time = -1
                end
            else
                v.time = 0
                v.useStatus = -1
            end
        end

        v.priority = -v.id + (v.useStatus+2) * 1000000

        if v.useStatus == 0 then
            local isHint = false
            for i2,v2 in ipairs(GameScene.titleHintData["iconBox"]) do
                if v2.cid == v.id then
                    isHint = true
                    break
                end
            end
            if isHint then
                v.priority = 1000000000 - v.id
            end
        end

        if v.id ~= defautIconBoxCid then
            table.insert(self.iconBoxdata,v)
        end
        
    end

    table.sort(self.iconBoxdata,function ( a,b)
        return tonumber(a.priority) > tonumber(b.priority)
    end)


    local defautConfig = config[tostring(defautIconBoxCid)]
    
    table.insert(self.iconBoxdata,1,defautConfig)

    self:moveto("iconBox")
end

function roleinfo.resetIcon(self,profile)
    self.data.profile = profile
    setSpriteFrameByName(self.rootItems.usericon, gamedata.config.general[tostring(self.data.profile)].icon)
    ui.setSpriteTextureRect(self.rootItems.usericon,0,0,150,150)
    -- 更换对应武将品质的头像框
    setSpriteFrameByName(self.rootItems.iconBox, ui.i_k_quality(gamedata.config.general[tostring(self.data.profile)]))
    self:moveto("root")
end

function roleinfo.resetTitle(self,title)
    self.data.title = title

    if self.data.title == gameConfig.defautTitleId then
        setSpriteFrameByName(self.rootItems.titleicon, "alpha")
    else
        setSpriteFrameByName(self.rootItems.titleicon, gamedata.config.title[tostring(self.data.title)].icon)
    end

end

function roleinfo.resetIconBox(self,iconBox)
    self.data.iconBox = iconBox

    if self.data.iconBox == gameConfig.defautIconBoxId then
        setSpriteFrameByName(self.rootItems.iconBox, ui.i_k_quality(gamedata.config.general[tostring(self.data.profile)]))
    else
        setSpriteFrameByName(self.rootItems.iconBox, gamedata.config.headframe[tostring(self.data.iconBox)].icon)
    end
end

function roleinfo.creatList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(910, 220)
        elseif fn == "cellAtIndex" then

            local CCB,item = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                for i=1,4 do
                    CCB[i],item[i] = CCBReaderLoad("icons/new_IconLv.ccbi", nil, true, "new_IconLv")
                end
                celldict[a2] = {CCB=CCB,item=item }
            else
                first = false
                CCB = celldict[a2].CCB
                item = celldict[a2].item
            end

            for i =1, 4 do
                if self.icondata[4*(a1) +i] then
                    CCB[i]:setVisible(true)
                    local celldata =  self.icondata[4*(a1) +i]
                    ui.setIconLv(item[i],celldata)

                    item[i].il_button:addHandleOfControlEvent(function()
                        print(gameTouch.ismove,"gameTouch.ismove")
                        if not gameTouch.ismove then
                            UIRequest({type = 102,id = celldata.cid})
                            --self:moveto("root",function() UIRequest({type = 102,id = celldata.cid}) end)
                        end
                    end, CCControlEventTouchUpInside)
                    item[i].il_button:setTouchPriority(self.touchPriority-1)
                else
                    CCB[i]:setVisible(false)
                end

                CCB[i]:setPosition(15+220*(i-0.5), 110)
                if first then
                    a2:addChild(CCB[i])
                end
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.icondata)/4)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.profileItems.listscroll:getContentSize().width,
        viewheight = self.profileItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.listview:setTouchPriority(self.touchPriority)
    self.profileItems.listscroll:addChild(self.listview)
end


function roleinfo.creatListTitle(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(910, 240)
        elseif fn == "cellAtIndex" then

            local CCB,item = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                CCB,item = CCBReaderLoad("MainScene/cell_huanchenghao.ccbi", nil, true, "cell_huanchenghao")
                celldict[a2] = {CCB=CCB,item=item }
            else
                first = false
                CCB = celldict[a2].CCB
                item = celldict[a2].item
            end

            local data = self.titledata[a1+1]
            self:setTitleCell(item,data,"title")

            CCB:setPosition(910/2,0)
            if first then
                a2:addChild(CCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.titledata))
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.listviewTitle = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.titleItems.listscroll:getContentSize().width,
        viewheight = self.titleItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.listviewTitle:setTouchPriority(self.touchPriority)
    self.titleItems.listscroll:addChild(self.listviewTitle)
end

function roleinfo.setTitleCell(self,item,data,type)
    

    local isHint = false
    for i,v in ipairs(GameScene.titleHintData[type]) do
        if v.cid == data.id then
            isHint = true
        end
    end

    if item.hint then
        ui.sethint(item.hint,isHint)
    end


    printT(data,"setTitleCell")
    item.des:setString(data.obtain)

    -- for i=1,4 do
    --     if data["init"..i] > 0 then
    --         item["attribute"..i]:setString(gameConfig.strings.attr_type[data["attr"..i]].."+"..data["init"..i])
    --     else
    --         item["attribute"..i]:setString("")
    --     end
    -- end
    item.desc:setString(data.attribute_explain)
    setSpriteFrameByName(item.icon,data.icon)


    if data.useStatus == -1 then     --未获得
        item.noget:setVisible(true)
        item.inuse:setVisible(false)
        item.donode:setVisible(false)
    elseif data.useStatus == 0 then  --获得单未使用
        item.noget:setVisible(false)
        item.inuse:setVisible(false)
        item.donode:setVisible(true)
    elseif data.useStatus == 1 then  -- 使用中
        item.noget:setVisible(false)
        item.inuse:setVisible(true)
        item.donode:setVisible(false)
    end


    if data.useStatus ~= -1 then
        item.timenode:setVisible(true)
        item.time:setString(gameConfig.strings:titleEndTime(data.time))
    else
        item.timenode:setVisible(false)
    end


    ui.setLabelString(item.doLab,gameConfig.strings:string_common("fixedString","mainscene",23),19)


    item.doButton:addHandleOfControlEvent(function()
        print("使用")
        if type == "title" then
            UIRequest({type = 6302,id = data.id})
        elseif type == "iconBox" then
            UIRequest({type = 6202,id = data.id})
        end

    end, CCControlEventTouchUpInside)
    item.doButton:setTouchPriority(self.touchPriority-1)
end


function roleinfo.creatListIconBox(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(910, 240)
        elseif fn == "cellAtIndex" then

            local CCB,item = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                CCB,item = CCBReaderLoad("MainScene/cell_huankuang.ccbi", nil, true, "cell_huankuang")
                celldict[a2] = {CCB=CCB,item=item }
            else
                first = false
                CCB = celldict[a2].CCB
                item = celldict[a2].item
            end

            local data = self.iconBoxdata[a1+1]
            self:setTitleCell(item,data,"iconBox")

            CCB:setPosition(910/2,0)
            if first then
                a2:addChild(CCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.iconBoxdata))
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.listviewIconBox = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.iconBoxItems.listscroll:getContentSize().width,
        viewheight = self.iconBoxItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.listviewIconBox:setTouchPriority(self.touchPriority)
    self.iconBoxItems.listscroll:addChild(self.listviewIconBox)
end


function roleinfo.moveto(self,type,callback)

    print("moveto",type)

    if type == "profile" then
        self:initProfileNode()
    elseif type == "iconBox" then
        self:initIconBoxNode()
    elseif type == "title" then
        self:initTitleNode()
    end

    self:hideOtherNode(type)

    local moveTo = CCMoveTo:create(0.3, ccp(type == "root" and 0 or -1080, 0))
    local backOut = CCEaseExponentialOut:create(moveTo)
    self.animationNode:runAction(backOut)
    gameTouch:clickprofbytime(0.4)
end

function roleinfo.hideOtherNode(self,type)
    
    local names = {"profile","iconBox","title"}

    for k,v in pairs(names) do
        if type == v then
            if self[v.."Node"] then
                self[v.."Node"]:setVisible(true)
                self[v.."Node"]:setPositionX(1080)
            end
        else
            if self[v.."Node"] then
                self[v.."Node"]:setVisible(false)
                self[v.."Node"]:setPositionX(2160)
            end
        end
    end

    if type == "root" then
        --关闭计时器
        gameTimer:UnrigistTimeFunc("freshTitle")
        gameTimer:UnrigistTimeFunc("freshIconBox")

        gameTimer:UnrigistTime("freshTitle")
        gameTimer:UnrigistTime("freshIconBox")
    end
end

function roleinfo.initProfileNode(self)
    if not self.profileNode then
        self.profileNode, self.profileItems = CCBReaderLoad("MainScene/player_huantouxiang", nil, true, "player_huantouxiang")
        self.animationNode:addChild(self.profileNode)

        self.profileItems.closeButton:addHandleOfControlEvent(function()
            self:moveto("root")
        end, CCControlEventTouchUpInside)
        self.profileItems.closeButton:setSwallowsTouch(true)
        self.profileItems.closeButton:setTouchPriority(self.touchPriority)
    end
    if not self.listview then
        self:creatList()
    else
        self.listview:reloadData()
    end
end

function roleinfo.initTitleNode(self)
    if not self.titleNode then
        self.titleNode, self.titleItems = CCBReaderLoad("MainScene/player_huanchenghao", nil, true, "player_huanchenghao")
        self.animationNode:addChild(self.titleNode)

        self.titleItems.closeButton:addHandleOfControlEvent(function()
            self:moveto("root")
        end, CCControlEventTouchUpInside)
        self.titleItems.closeButton:setSwallowsTouch(true)
        self.titleItems.closeButton:setTouchPriority(self.touchPriority)

        self.titleItems.title:setString(gameConfig.strings:string_common("fixedString","mainscene",17))
        self.titleItems.fixed1:setString(gameConfig.strings:string_common("fixedString","mainscene",18))
        self.titleItems.fixed2:setString(gameConfig.strings:string_common("fixedString","mainscene",19))

    end

    if not self.listviewTitle then
        self:creatListTitle()
    else
        self.listviewTitle:reloadData()
    end

    if not gameTimer.timeFuncs["freshTitle"] then
        gameTimer:rigistTime("freshTitle",10001)
        gameTimer:rigistTimeFunc("freshTitle",function(now)
            if gameTimer.times["freshTitle"]== 0 then
                gameTimer:rigistTime("freshTitle",10000)
            end

            if math.mod(gameTimer.times["freshTitle"],30) == 0 then
                UIRequest({type = 6301})
            end
        end)
    end

end

function roleinfo.initIconBoxNode(self)
    if not self.iconBoxNode then
        self.iconBoxNode, self.iconBoxItems = CCBReaderLoad("MainScene/player_huankuang", nil, true, "player_huankuang")
        self.animationNode:addChild(self.iconBoxNode)

        self.iconBoxItems.closeButton:addHandleOfControlEvent(function()
            self:moveto("root")
        end, CCControlEventTouchUpInside)
        self.iconBoxItems.closeButton:setSwallowsTouch(true)
        self.iconBoxItems.closeButton:setTouchPriority(self.touchPriority)

        self.iconBoxItems.title:setString(gameConfig.strings:string_common("fixedString","mainscene",14))
        self.iconBoxItems.fixed1:setString(gameConfig.strings:string_common("fixedString","mainscene",15))
        self.iconBoxItems.fixed2:setString(gameConfig.strings:string_common("fixedString","mainscene",16))

    end

    if not self.listviewIconBox then
        self:creatListIconBox()
    else
        self.listviewIconBox:reloadData()
    end

    if not gameTimer.timeFuncs["freshIconBox"] then
        gameTimer:rigistTime("freshIconBox",10001)
        gameTimer:rigistTimeFunc("freshIconBox",function(now)
            if gameTimer.times["freshIconBox"]== 0 then
                gameTimer:rigistTime("freshIconBox",10000)
            end

            if math.mod(gameTimer.times["freshIconBox"],30) == 0 then
                UIRequest({type = 6201})
            end
        end)
    end

    

end

function roleinfo.reloadTitleHint(self)
    if self.rootItems.title_hint then
        ui.sethint(self.rootItems.title_hint,#GameScene.titleHintData.title > 0 or #GameScene.titleHintData.iconBox > 0)
    end

    if self.listviewTitle then
        self.listviewTitle:reloadData()
    end

    if self.listviewIconBox then
        self.listviewIconBox:reloadData()
    end
end


function roleinfo.popWindow(self)

    if self.popNode then
        return
    end

    local node, items = CCBReaderLoad("MainScene/cell_touxiangbutton", nil, true, "cell_touxiangbutton")
    self.rootItems.popNode:addChild(node)
    self.popNode = node

    if items.title_hint then
        ui.sethint(items.title_hint,#GameScene.titleHintData.title > 0)
    end
    if items.iconBox_hint then
        ui.sethint(items.iconBox_hint,#GameScene.titleHintData.title > 0)
    end

    items.titleNode:setPositionY(9999)
    items.iconBoxNode:setPositionY(9999)

    local opens = {}
    if gameConfig:checkBuildOpen(560) then
        table.insert(opens,"title")
    end

    if gameConfig:checkBuildOpen(561) then
        table.insert(opens,"iconBox")
    end

    for i,v in ipairs(opens) do
        items[v.."Node"]:setPositionY(i == 1 and -140 or -230)
    end

    items.bg = tolua.cast(items.bg, "CCScale9Sprite")
    if #opens == 1 then
        items.bg:setPreferredSize(CCSizeMake(372,190))
    else
        items.bg:setPreferredSize(CCSizeMake(372,283))
    end
    

    local animationManager = getAnimationManager(items)
    animationManager:runAnimationsForSequenceNamed("open")


    items.button1:addHandleOfControlEvent(function()
        if not next(self.icondata) then
            UIRequest({type = 1015})
        else
            self:moveto("profile")
        end
    end, CCControlEventTouchUpInside)
    items.button1:setTouchPriority(self.touchPriority)

    items.button2:addHandleOfControlEvent(function()

        if not next(self.titledata) then
            UIRequest({type = 6301})
        else
            self:moveto("title")
        end
    end, CCControlEventTouchUpInside)
    items.button2:setTouchPriority(self.touchPriority)

    items.button3:addHandleOfControlEvent(function()

        if not next(self.iconBoxdata) then
            UIRequest({type = 6201})
        else
            self:moveto("iconBox")
        end

    end, CCControlEventTouchUpInside)
    items.button3:setTouchPriority(self.touchPriority)

    items.fixed1:setString(gameConfig.strings:string_common("fixedString","mainscene",20))
    items.fixed2:setString(gameConfig.strings:string_common("fixedString","mainscene",21))
    items.fixed3:setString(gameConfig.strings:string_common("fixedString","mainscene",22))

    local proflayer = nil

    local callback = function (  )
        print("callback")
        
        gameTouch:clickprofbytime(0.3)
        local animationManager = getAnimationManager(items)
        animationManager:setAnimationCompletedCallback(function()
            node:removeFromParentAndCleanup(true)
            proflayer:removeFromParentAndCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("close")

        self.popNode = nil
    end

    proflayer = ui.addProflayer(self.root,self.touchPriority + 1,nil,ccc4(0,0,0,0),nil,nil,nil,callback,"playerIconPop",true)
end

function roleinfo.reload(self,data,callback)

    if callback then
        self.callback = callback
    end

    self.data = data

    local vipLevel = tonumber(data.vip or 0)
    local levelNum = tostring(data.level or 1)
    local expCurrent = tonumber(data.exp or 0)
    local expTotal = tonumber(data.nextexp or 0)
    local energyCurrent = tostring(data.energy or 0)
    local energyTotal = tostring(data.maxenergy or 0)
    local staminaCurrent = tostring(data.stamina or 0)
    local staminaTotal = tostring(data.maxstamina or 0)
    local coinNum = tostring(data.coin or 0)
    local goldNum = tostring(data.gold or 0)
    local name = tostring(data.name or "")
    local power = tostring(data.power or 0)
    local staminanext = tostring(data.staminanext or 0)
    local staminaall = tostring(data.staminaall or 0)
    local energynext = tostring(data.energynext or 0)
    local energyall = tostring(data.energyall or 0)


    --todo
    --part
    if self.rootItems.duanNode then
        ui.setWudaoPart(self.rootItems,data.part_point or 0)
    end

    -- if not gameConfig:checkBuildOpen(154) then
    --     self.rootItems.vipnode:setVisible(false)
    -- else
    --     self.rootItems.vipnode:setVisible(true)
    -- end

    ui.setLabelString(self.rootItems.fixed1,gameConfig.strings:string_common("fixedString","mainscene",29),127)
    ui.setLabelString(self.rootItems.fixed2,gameConfig.strings:string_common("fixedString","mainscene",30),127)


    --弹出框里的信息
    setSpriteFrameByName(self.rootItems.usericon, gamedata.config.general[tostring(data.profile)].icon)
    ui.setSpriteTextureRect(self.rootItems.usericon,0,0,150,150)

    printT(data,"data")
    if data.title == gameConfig.defautTitleId then
        setSpriteFrameByName(self.rootItems.titleicon, "alpha")
    else
        setSpriteFrameByName(self.rootItems.titleicon, gamedata.config.title[tostring(data.title)].icon)
    end

     if data.iconBox == gameConfig.defautIconBoxId then
        print("data.iconBox",ui.i_k_quality(gamedata.config.general[tostring(data.profile)]))
        setSpriteFrameByName(self.rootItems.iconBox, ui.i_k_quality(gamedata.config.general[tostring(data.profile)]))
    else
        setSpriteFrameByName(self.rootItems.iconBox, gamedata.config.headframe[tostring(data.iconBox)].icon)
    end
    

    ui.setLabelString(self.rootItems.icondes,nil,10)
    self.rootItems.role_button:setSwallowsTouch(true)
    self.rootItems.role_button:setTouchPriority(self.touchPriority)
    self.rootItems.role_button:addHandleOfControlEvent(function()
            
        if gameConfig:checkBuildOpen(560) or gameConfig:checkBuildOpen(561) then
            self:popWindow()
        else
            if not next(self.icondata) then
                UIRequest({type = 1015})
            else
                self:moveto("profile")
            end
        end

    end, CCControlEventTouchUpInside)

    self.rootItems.power:setString(power)

    -- ui.setLabelString(self.rootItems.Role_name,name,46)

    -- 添加段位排名闪烁
    ui.setWudaoDuanweiRankEffect(self.rootItems,self.data,0,40/34,46,self.rootItems.Role_name)


    -- ui.setLabelString(self.rootItems.levelNum,"队伍等级: "..levelNum,46)
    ui.setLabelString(self.rootItems.levelNum,gameConfig.strings:teamLv(levelNum),46)

    ui.setLabelString(self.rootItems.coinNum,coinNum,14)
    ui.setLabelString(self.rootItems.goldNum,goldNum,14)

    self.rootItems.Stamina:setString(staminaCurrent .. " / " .. staminaTotal)
    self.rootItems.Murderous:setString(energyCurrent .. " / " .. energyTotal)

    self.rootItems.NextStamina:setString(ui.makeTimeText(staminanext,"hour"))
    self.rootItems.AllStamina:setString(ui.makeTimeText(staminaall,"hour"))
    self.rootItems.NextMurderous:setString(ui.makeTimeText(energynext,"hour"))
    self.rootItems.AllMurderous:setString(ui.makeTimeText(energyall,"hour"))

    ui.setLabelString(self.rootItems.exp,expCurrent.."/"..expTotal,14)
    ui.setSpriteTextureRect2(self.rootItems.expbar,0,0,280 * ((expCurrent > expTotal) and 1 or (expCurrent/expTotal)),36)

    -- setSpriteFrameByName(self.rootItems["vipLevel"],"b_n_vip_"..vipLevel)

    self.rootItems.userid:setString(data.showid or data.id)

    if self.rootItems.channelid then
        local channelconfig = gamedata.config.channel_identification
        self.rootItems.channelid:setString(channelconfig["1"].code)
    end

    if self.SelectedServer and next(self.SelectedServer) then
        self.rootItems.server:setString(gameConfig.strings:idStatus(self.SelectedServer.id).." "..self.SelectedServer.name)
    end

    if  gameTimer.times["staminanext"] and gameTimer.times["staminanext"] ~= 0 then
        gameTimer:rigistTimeFunc("staminanext",function()
            if  gameTimer.times["staminanext"] ~= 0 then
                self.rootItems.NextStamina:setString(ui.makeTimeText(gameTimer.times["staminanext"],"hour"))
            else
                self.rootItems.NextStamina:setString((staminaCurrent>=staminaTotal) and "已满" or "00:00:00")
            end
        end)
    else
        self.rootItems.NextStamina:setString((staminaCurrent>=staminaTotal) and "已满" or "00:00:00")
    end

    if  gameTimer.times["staminaall"] and gameTimer.times["staminaall"] ~= 0 then
        gameTimer:rigistTimeFunc("staminaall",function()
            if  gameTimer.times["staminaall"] ~= 0 then
                self.rootItems.AllStamina:setString(ui.makeTimeText(gameTimer.times["staminaall"],"hour"))
            else
                self.rootItems.AllStamina:setString((staminaCurrent>=staminaTotal) and "已满" or "00:00:00")
            end
        end)
    else
        self.rootItems.AllStamina:setString((staminaCurrent>=staminaTotal) and "已满" or "00:00:00")
    end

    if  gameTimer.times["energynext"] and gameTimer.times["energynext"] ~= 0 then
        gameTimer:rigistTimeFunc("energynext",function()
            if  gameTimer.times["energynext"] ~= 0 then
                self.rootItems.NextMurderous:setString(ui.makeTimeText(gameTimer.times["energynext"],"hour"))
            else
                self.rootItems.NextMurderous:setString((energyCurrent>=energyTotal) and "已满" or "00:00:00")
            end
        end)
    else
        self.rootItems.NextMurderous:setString((energyCurrent>=energyTotal) and "已满" or "00:00:00")
    end

    if  gameTimer.times["energyall"] and gameTimer.times["energyall"] ~= 0 then
        gameTimer:rigistTimeFunc("energyall",function()
            if  gameTimer.times["energyall"] ~= 0 then
                self.rootItems.AllMurderous:setString(ui.makeTimeText(gameTimer.times["energyall"],"hour"))
            else
                self.rootItems.AllMurderous:setString((energyCurrent>=energyTotal) and "已满" or "00:00:00")
            end
        end)
    else
        self.rootItems.AllMurderous:setString((energyCurrent>=energyTotal) and "已满" or "00:00:00")
    end

    ------------------------------------------------------------------------

    ui.addGray("CCControlButton",self.rootItems.m_gonglue)

    ui.setLabelString(self.rootItems.m_gonglue_text,nil,18)
    self.rootItems.m_gonglue:setSwallowsTouch(true)
    self.rootItems.m_gonglue:setTouchPriority(self.touchPriority)
    self.rootItems.m_gonglue:addHandleOfControlEvent(function()
        --GameScene:shiftLayer("gonglve","up")
        --todo
        runGamePrompt({msg = "尽请期待"})
    end, CCControlEventTouchUpInside)


    ui.setLabelString(self.rootItems.m_post_text,nil,18)
    self.rootItems.m_post:setSwallowsTouch(true)
    self.rootItems.m_post:setTouchPriority(self.touchPriority)
    self.rootItems.m_post:addHandleOfControlEvent(function()
        gameWindows:openWindow("post", nil, nil)
    end, CCControlEventTouchUpInside)

    if gameConfig:checkBuildOpen(152) then
        ui.setLabelString(self.rootItems.m_cdk_text,nil,18)
        self.rootItems.m_cdk:setSwallowsTouch(true)
        self.rootItems.m_cdk:setTouchPriority(self.touchPriority)
        self.rootItems.m_cdk:addHandleOfControlEvent(function()
            gameWindows:openWindow("cdkey",nil)
        end, CCControlEventTouchUpInside)
    else
        self.rootItems.cdknode:setVisible(false)
    end

    if gameConfig:checkBuildOpen(151) then
        ui.setLabelString(self.rootItems.m_kefu_text,nil,18)
        self.rootItems.m_kefu:setSwallowsTouch(true)
        self.rootItems.m_kefu:setTouchPriority(self.touchPriority)
        self.rootItems.m_kefu:addHandleOfControlEvent(function()
            gameWindows:openWindow("kefu",nil)
        end, CCControlEventTouchUpInside)
    else
        self.rootItems.kefunode:setVisible(false)
        self.rootItems.buttonnode:setPositionX(305)
    end

    if not gameConfig:checkBuildOpen(152) and not gameConfig:checkBuildOpen(151) then
        self.rootItems.buttonnode:setPositionX(305)
    end

    --用户协议
    if self.rootItems.agreementnode then
        ui.setLabelString(self.rootItems.m_agreement_text,nil,18)
        self.rootItems.m_agreement:setSwallowsTouch(true)
        self.rootItems.m_agreement:setTouchPriority(self.touchPriority)
        self.rootItems.m_agreement:addHandleOfControlEvent(function()
            gameWindows:openWindow("userAndPrivacyAgreement",{type = 0, window = 1})
        end, CCControlEventTouchUpInside)
    end
    --隐私政策
    if self.rootItems.policynode then
        ui.setLabelString(self.rootItems.m_policy_text,nil,18)
        self.rootItems.m_policy:setSwallowsTouch(true)
        self.rootItems.m_policy:setTouchPriority(self.touchPriority)
        self.rootItems.m_policy:addHandleOfControlEvent(function()
            gameWindows:openWindow("userAndPrivacyAgreement",{type = 1, window = 1})
        end, CCControlEventTouchUpInside)
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("roleinfo")
        UIRequest({type = 1001})
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --music

    self:shiftbuttonstatus(self.rootItems.musicsprite,self.rootItems.musicOn,gamedata.music and gamedata.music.isMusicOn,true)
    self:shiftbuttonstatus(self.rootItems.soundsprite,self.rootItems.soundOn,gamedata.music and gamedata.music.isSoundOn,true)

    self.rootItems.setSoundButton:addHandleOfControlEvent(function()
        if gamedata.music and gamedata.music.isSoundOn then
            gamedata.music:SetSound(false)
            self:shiftbuttonstatus(self.rootItems.soundsprite,self.rootItems.soundOn,false)
        elseif gamedata.music then
            gamedata.music:SetSound(true)
            self:shiftbuttonstatus(self.rootItems.soundsprite,self.rootItems.soundOn,true)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.setSoundButton:setSwallowsTouch(true)
    self.rootItems.setSoundButton:setTouchPriority(self.touchPriority)

    self.rootItems.setMusicButton:addHandleOfControlEvent(function()
        if gamedata.music and gamedata.music.isMusicOn then
            gamedata.music:SetMusic(false)
            self:shiftbuttonstatus(self.rootItems.musicsprite,self.rootItems.musicOn,false)
        elseif gamedata.music then
            gamedata.music:SetMusic(true)
            self:shiftbuttonstatus(self.rootItems.musicsprite,self.rootItems.musicOn,true)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.setMusicButton:setSwallowsTouch(true)
    self.rootItems.setMusicButton:setTouchPriority(self.touchPriority)

    self:updateRenzheng()

    self:reloadTitleHint()
end

function roleinfo.updateRenzheng( self )
    self.rootItems.renzhengbutton:setVisible(false)

    if gamedata.sdk.idCardStatus then
        if gamedata.sdk.idCardStatus == 0 then
            self.rootItems.renzhengbutton:setVisible(true)
            self.rootItems.renzhengbutton:addHandleOfControlEvent(function()
                gameWindows:openWindow("shiming",{page="renzheng"})
            end, CCControlEventTouchUpInside)
            self.rootItems.renzhengbutton:setSwallowsTouch(true)
            self.rootItems.renzhengbutton:setTouchPriority(self.touchPriority)
        end
    end
end

function roleinfo.shiftbuttonstatus(self,locSprite,onSprite,status,isfirst)
    local onposition = ccp(160,-2)
    local offposition =  ccp(30,-2)
    if isfirst then
        locSprite:setPosition(status and onposition or offposition)
        onSprite:setOpacity(status and 255 or 0)
    else
        local moveTo = CCMoveTo:create(0.3,status and onposition or offposition)
        local backOutmoveTo = CCEaseExponentialOut:create(moveTo)
        local fade = CCFadeTo:create(0.3,status and 255 or 0)
        local backOutfade = CCEaseExponentialOut:create(fade)

        locSprite:runAction(backOutmoveTo)
        onSprite:runAction(backOutfade)
    end
end

function roleinfo.close(self)
    gameTimer:UnrigistTimeFunc("staminanext")
    gameTimer:UnrigistTimeFunc("staminaall")
    gameTimer:UnrigistTimeFunc("energynext")
    gameTimer:UnrigistTimeFunc("energyall")
    gameTimer:UnrigistTimeFunc("freshTitle")
    gameTimer:UnrigistTimeFunc("freshIconBox")

    gameTimer:UnrigistTime("freshTitle")
    gameTimer:UnrigistTime("freshIconBox")

    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.profileNode = nil
    self.profileItems = nil


    self.titleNode = nil
    self.titleItems = nil

    self.iconBoxNode = nil
    self.iconBoxItems = nil


    self.listview = nil
    self.listviewIconBox = nil
    self.listviewTitle = nil

    self.icondata = {}
    self.titledata = {}
    self.iconBoxdata = {}

    self.popNode = nil

    if self.callback then
        self.callback()
    end
end

return roleinfo
