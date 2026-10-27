--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:51
-- To change this template use File | Settings | File Templates.
--

--与海外版有差异，国内版名将副本没有通关宝箱

local copyChapter = {

    resource = nil,


    rootNode = nil,
    rootItems = nil,
    -- pageconfig = {"normal","star","hades","activity","hell"},
    pageconfig = {"normal","star","hades","activity"},
    -- pagename = {"普通","名将","地狱","活动","通缉"},
    pagename = {"普通","名将","地狱","活动"},

    -- pagebuild = {1,148,430,157,397},
    pagebuild = {1,148,430,157},

    selectpage = "normal",

    stardata = nil,
    normaldata = {},
    bravedata = {},
    helldata = nil,
    presentPage_normal = nil,
    presentPage_brave = nil,
    hadesdata = nil,

    hadesCCB = nil,

    data = {},
    presentPage = nil,
    createdpage={},

    touchX = nil,

    requests= {
        normal = 1300,
        brave = 1330,
        star = 1350,
        activity = 1340,
        hades = 1370,
    },

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {12},
                title2 = {148},
                title3 = {430},
                title4 = {157}, --副本活动
                -- title5 = {397},
            },
        },
    },
    CellSize = {x = 1080,y = 310},
    png = {
        [1] = "copy_jingyan.png",
        [2] = "copy_yinbi.png",        
    },
    isscrolltouched = false,
    activityListTableView = nil,
    isshow_settig = false,
    hadesGenerals = {},

}

function copyChapter.setParam(self,param)
    if param then
        if param.normaldata then
            self.normaldata = param.normaldata
        end
        if param.bravedata then
            self.bravedata = param.bravedata
        end
        if param.datatype then
            self.selectpage = param.datatype
        end

        self.presentPage = param.section

    end
end
--根据页签设置ui位置
function copyChapter.setUIPosition( self,type )
    if type == "activity" then
        self.rootItems.list:setPositionX(-99999)
        self.rootItems.bravetop:setPositionX(-99999)
        self.rootItems.hadestop:setPositionX(-99999)
        self.rootItems.activity:setPositionX(0)
        self.rootItems.activityFinishNode:setPositionX(410)
        self.rootItems.hades:setPositionX(-99999)
    elseif type == "hades" then
        self.rootItems.list:setPositionX(-99999)
        self.rootItems.bravetop:setPositionX(-99999)
        self.rootItems.hadestop:setPositionX(-99999)
        self.rootItems.activity:setPositionX(-99999)
        self.rootItems.activityFinishNode:setPositionX(-99999)
        self.rootItems.hades:setPositionX(0)
    else
        self.rootItems.list:setPositionX(0)
        self.rootItems.bravetop:setPositionX(-540)
        self.rootItems.hadestop:setPositionX(-540)
        self.rootItems.activity:setPositionX(-99999)
        self.rootItems.activityFinishNode:setPositionX(-99999)
        self.rootItems.hades:setPositionX(-99999)
    end
end

function copyChapter.shiftPage(self,type,isnewmap)
    self:setUIPosition(type)
    if type == "activity" then
        self.selectpage = type
        if self.activitydata ~= nil then
        else
            UIRequest({type = 1340})
        end
    elseif type == "hell" then
        self:reloadHellCopyData()
    elseif type == "hades" then
        self.selectpage = type
        if not self.hadesCCB then
            local node,items = CCBReaderLoad("yuangushenyuan/yuangushenyuan", nil, true, "yuangushenyuan")
            self.rootItems.hades:addChild(node)

            local node2,items2 = CCBReaderLoad("yuangushenyuan/yuangushenyuan_map", nil, true, "yuangushenyuan_map")
            items.generalNode:addChild(node2)

            self.hadesCCB = {node = node,items = items,generalNode = node2,generalItems = items2}
            self.hadesCCB.items.topnode:setPositionY(self.toppos - 100)
        end

        if self.hadesdata ~= nil then
        else
            UIRequest({type = 1370})
        end
    else
        self["presentPage_"..self.selectpage] = self.presentPage
        self.selectpage = type
        self.presentPage =  self["presentPage_"..self.selectpage]

        if not self[type.."data"] or not next(self[type.."data"]) then
            UIRequest({type = self.requests[type]})
        else
            self:reloaddata(isnewmap)
        end
    end


end


function copyChapter.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("copy/copy_chapter", nil, true, "copy_chapter")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.activityDailyConfigureData = gamedata.config.daily_function
    self.activityExpConfigureData = gamedata.config.exp_copy
    self.activityCoinConfigureData = gamedata.config.coin_copy
    self.rootItems.activitynode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))
    -- print("daily_function ============")
    -- printT(self.activityDailyConfigureData)
    -- print("exp_copy ==================")
    -- printT(self.activityExpConfigureData)
    -- print("coin_copy =================")
    -- printT(self.activityCoinConfigureData)   
    self.animationManager = getAnimationManager(self.rootItems)

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.toptitle:setPositionY(toppos)


    self.rootItems.touchLayer:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-150-gameConfig.labelnodeheight))

    -- 阵容推荐btn
    if gamedata.config.build[tostring(170)] and gamedata.config.build[tostring(170)].switch == 1 then
        self.rootItems.recommendBtn:setVisible(true)
    else
        self.rootItems.recommendBtn:setVisible(false)
    end
    self.rootItems.recommendBtn:setSwallowsTouch(true)
    self.rootItems.recommendBtn:setTouchPriority(-104)
    self.rootItems.recommendBtn:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(170)
    end, CCControlEventTouchUpInside)


    local globConfig = gamedata.config.global_kv
    if GameScene.roleinfo.level >= tonumber(globConfig.huodong_quick_complete_level.value) then
        self.rootItems.oneFinishBtn:setVisible(true)
    else
        self.rootItems.oneFinishBtn:setVisible(false)
    end

    self.rootItems.oneFinishBtn:setSwallowsTouch(true)
    self.rootItems.oneFinishBtn:setTouchPriority(-104)
    self.rootItems.oneFinishBtn:addHandleOfControlEvent(function()
        if GameScene.roleinfo.level >= tonumber(globConfig.huodong_quick_complete_level.value) then
            if GameScene.roleinfo.level >= tonumber(globConfig.huodong_quick_complete_level2.value) then
                gameWindows:openWindow("activityCopySelect",self.activitydataused)
            else
                if GameScene.roleinfo.vip >= tonumber(globConfig.huodong_quick_complete_vip.value) then
                    gameWindows:openWindow("activityCopySelect",self.activitydataused)
                else
                    runGamePrompt({msg = "需要队伍等级"..globConfig.huodong_quick_complete_level2.value.."或VIP"..globConfig.huodong_quick_complete_vip.value.."开启"})
                end
            end
        else
            runGamePrompt({msg = "需要等级"..globConfig.huodong_quick_complete_level.value.."开启"})
        end
        --gameWindows:openWindow("activityCopySelect",self.activitydataused)
    end, CCControlEventTouchUpInside)



    -- 扫荡设置btn
    if  GameScene.roleinfo.level >= tonumber(globConfig.exp_change.value) and self.selectpage == "normal" then
        self.rootItems.copySettingBtn:setVisible(true)
        self.isshow_settig = true
    end
    self.rootItems.copySettingBtn:setSwallowsTouch(true)
    self.rootItems.copySettingBtn:setTouchPriority(-104)
    self.rootItems.copySettingBtn:addHandleOfControlEvent(function()
            gameWindows:openWindow("copyexchange",nil,nil)
    end, CCControlEventTouchUpInside)

    self.rootItems.button_left:setSwallowsTouch(true)
    self.rootItems.button_left:setTouchPriority(-103)
    self.rootItems.button_left:addHandleOfControlEvent(function()
        if self.selectpage == "star" then
            self:setStarPage(self.presentPage-1)
        elseif self.selectpage == "hades" then
            self:setHadesPage(self.presentPage-1)
        else
            self:setPage(self.presentPage-1)
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.button_right:setSwallowsTouch(true)
    self.rootItems.button_right:setTouchPriority(-103)
    self.rootItems.button_right:addHandleOfControlEvent(function()
        if self.selectpage == "star" then
            self:setStarPage(self.presentPage+1)
        elseif self.selectpage == "hades" then
            self:setHadesPage(self.presentPage+1)
        else
            self:setPage(self.presentPage+1)
        end
    end, CCControlEventTouchUpInside)

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchX = x
            self.contentoffsetx = self.rootItems.pagenode:getPositionX()
            return true
        end
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 10 then
            self.isContentScroll = true
        end

        if math.abs(x - self.touchX) > 30 then
            local offsetX = self.contentoffsetx + (x - self.touchX)
            self.rootItems.pagenode:setPositionX(offsetX)
        end
    end

    local function ccTouchEnded(x, y)
        if self.touchX - x > 20 then
            if self.selectpage == "star" then
                self:setStarPage(self.presentPage+1)
            elseif self.selectpage == "hades" then
                self:setHadesPage(self.presentPage+1)
            else
                self:setPage(self.presentPage+1)
            end
        elseif self.touchX - x < -20 then
            if self.selectpage == "star" then
                self:setStarPage(self.presentPage-1)
            elseif self.selectpage == "hades" then
                self:setHadesPage(self.presentPage-1)
            else
                self:setPage(self.presentPage-1)
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

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","copy_chapter",touchbegin)
    local function touchend(pos)
        if self.rootItems.activitynode and ui.isTouched(self.rootItems.activitynode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","copy_chapter",touchend)

    self:setParam(param)
    self:shiftPage(self.selectpage,param and param.isnewmap)
end

function copyChapter.clear(self)
    gameTouch:UnrigistFunc("begin","copy_chapter")
    gameTouch:UnrigistFunc("end","copy_chapter")
    self.isscrolltouched = false   
--    self.normaldata = {}
--    self.bravedata = {}
    --self.selectpage = "normal"
    if self.bravesprite then
        self.bravesprite:removeFromParentAndCleanup(true)
        self.bravesprite = nil
    end
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.createdpage={}
    self.activitydata = nil
    self.activityListTableView = nil
    self.helldata = nil

    self.hadesCCB = nil
    self.hadesdata = nil
    self.hadesGenerals = {}
end


function copyChapter.setMap(self,item,data,k)

    item["button2"]:setTouchPriority(-103)
    item["button2"]:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        guide:setGuideProlayer(true)
        gameTouch:clickprofbytime(0.5)
        GameScene:shiftLayer("copy_map","up",{
            [self.selectpage.."data"] = self[self.selectpage.."data"],
            section = self.presentPage,
            map = tonumber(k),
            datatype = self.selectpage
        })
    end, CCControlEventTouchUpInside)

    for i=1, 3 do
       if i <= data.star then
           setSpriteFrameByName(item["star"..i], gameConfig.images.starON)
       else
           setSpriteFrameByName(item["star"..i], gameConfig.images.starOFF)
       end
    end

    if self.selectpage == "normal" then
        data.config = gamedata.config.map[tostring(data.id)]
    else
        data.config = gamedata.config.brave_map[tostring(data.id)]
    end
    item["name"]:setString(data.config.name)

    local index = 0
    local status = 1
    for i=1,3 do
        if data["pa"..i]~= 3 then
            index = i
            status = data["pa"..i]
            break
        end
    end

    item["lingqueffect"]:removeAllChildrenWithCleanup(true)
    if index == 0 then
        item["box"]:setVisible(false)
    else
        setSpriteFrameByName(item["box"], "box"..(index+1).."_"..(status-1))
    end

    if status == 2 then
        local ccb1, item1 = CCBReaderLoad("UIEffect/baoxiangkelingqu/baoxiangkelingqu.ccbi", nil, true, "baoxiangkelingqu")
        item["lingqueffect"]:addChild(ccb1)
    end

    local iconname = gamedata.config.general[tostring(data.config.id)].icon
    local cliper = CCClippingNode:create()
    local stencil = CCSprite:createWithSpriteFrameName("copymap_iconmask.png")
    stencil:setAnchorPoint(ccp(0,0))
    cliper:setStencil(stencil)
    cliper:setAlphaThreshold(0)
    local icon = CCSprite:create()
    setSpriteFrameByName(icon,iconname..".png")
    icon:setAnchorPoint(ccp(0,0))
    icon:setScale(0.87)
    cliper:addChild(icon)
    item.iconnode:addChild(cliper)

    if  data.star <= 0 then
--        if isnewmap then
--            local animationManager = getAnimationManager(item)
--            animationManager:setAnimationCompletedCallback(function()
--                local battleccb,battleitem =  CCBReaderLoad("UIEffect/duikan/duikan", nil, true, "duikan")
--                battleccb:setPosition(0,40)
--                battleccb:setScale(0.6)
--                item["battlenode"]:addChild(battleccb)
--            end)
--            animationManager:runAnimationsForSequenceNamed("new")
--        else
            local battleccb,battleitem =  CCBReaderLoad("UIEffect/duikan/duikan", nil, true, "duikan")
            battleccb:setPosition(0,40)
            battleccb:setScale(0.6)
            item["battlenode"]:addChild(battleccb)
--        end
    end

end

function copyChapter.setStarMap(self,item,data,k)

    --todo
    item["button2"]:setTouchPriority(-103)
    item["button2"]:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        guide:setGuideProlayer(true)
        gameTouch:clickprofbytime(0.5)
        print("StarMapButton")
        if  data.status and data.status >= 0 then
            GameScene:shiftLayer("starcopy_map","up",{data = data, index = k, attacknum = self.stardata.attacknum, alldata = self.stardata.sections,})
        else
            runGamePrompt({msg = "未到达开启条件"})
        end
    end, CCControlEventTouchUpInside)
    --与海外版差异，国服没有通关宝箱

    data.config = gamedata.config.star_map[tostring(data.mapid)]

    item["name"]:setString(data.config.name)

    local iconname = gamedata.config.general[tostring(data.config.id)].icon
    local cliper = CCClippingNode:create()
    local stencil = CCSprite:createWithSpriteFrameName("copymap_iconmask.png")
    stencil:setAnchorPoint(ccp(0,0))
    cliper:setStencil(stencil)
    cliper:setAlphaThreshold(0)
    local icon = CCSprite:create()
    setSpriteFrameByName(icon,iconname..".png")
    icon:setAnchorPoint(ccp(0,0))
    icon:setScale(0.87)
    cliper:addChild(icon)
    item.iconnode:addChild(cliper)

    if  data.status and data.status == 0 then
        local battleccb,battleitem =  CCBReaderLoad("UIEffect/duikan/duikan", nil, true, "duikan")
        battleccb:setPosition(0,40)
        battleccb:setScale(0.6)
        item["battlenode"]:addChild(battleccb)
    end

    if  data.status and data.status == -1 then
        ui.setLabelString(item["opendesc"],"通关普通副本"..gamedata.config.map[tostring(data.config.condition)].name.."后开启",21)
    else
        ui.setLabelString(item["opendesc"],"",21)
    end


end

function copyChapter.setHadesMap(self,item,data,k)

    --todo
    item["button2"]:setTouchPriority(-103)
    item["button2"]:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        guide:setGuideProlayer(true)
        gameTouch:clickprofbytime(0.5)
        print("HadesMapButton")
        if  data.status and data.status >= 0 then
            GameScene:shiftLayer("hadescopy_map","up",{data = data, index = k, attacknum = self.hadesdata.attacknum, alldata = self.hadesdata.sections,})
        else
            runGamePrompt({msg = "未到达开启条件"})
        end
    end, CCControlEventTouchUpInside)
    --

    data.config = gamedata.config.hades_map[tostring(data.mapid)]

    item["name"]:setString(data.config.name)

    local iconname = gamedata.config.general[tostring(data.config.id)].icon
    local cliper = CCClippingNode:create()
    local stencil = CCSprite:createWithSpriteFrameName("copymap_iconmask.png")
    stencil:setAnchorPoint(ccp(0,0))
    cliper:setStencil(stencil)
    cliper:setAlphaThreshold(0)
    local icon = CCSprite:create()
    setSpriteFrameByName(icon,iconname..".png")
    icon:setAnchorPoint(ccp(0,0))
    icon:setScale(0.87)
    cliper:addChild(icon)
    item.iconnode:addChild(cliper)

    if  data.status and data.status == 0 then
        local battleccb,battleitem =  CCBReaderLoad("UIEffect/duikan/duikan", nil, true, "duikan")
        battleccb:setPosition(0,40)
        battleccb:setScale(0.6)
        item["battlenode"]:addChild(battleccb)
    end

    if  data.status and data.status == -1 then
        ui.setLabelString(item["opendesc"],"通关普通副本"..gamedata.config.map[tostring(data.config.condition)].name.."后开启",21)
    else
        ui.setLabelString(item["opendesc"],"",21)
    end

    --
    item["hint_reward"]:setVisible(data.mapbox and data.mapbox == 1 or false)

end

function copyChapter.setChapter(self,item,data,page,isnewmap)
    local mapnum = table.getTableLength(data.maps)
    for k,v in pairs(data.maps) do
        if not self.createdpage[page].maps[k] then
            self.createdpage[page].maps[k] = {}
            item["p"..k]:removeAllChildrenWithCleanup(true)
            self.createdpage[page].maps[k].mapccb, self.createdpage[page].maps[k].mapitem = CCBReaderLoad("copy/map_point_"..self.selectpage, nil, true, "map_point_"..self.selectpage)
            item["p"..k]:addChild(self.createdpage[page].maps[k].mapccb)
            self:setMap(self.createdpage[page].maps[k].mapitem,v,k)
        end
    end


    local animationManager = getAnimationManager(item)
    for i=1,4 do
        item["pnode"..i]:setVisible(i<mapnum)
    end

    if isnewmap then
        self.createdpage[page].maps[tostring(mapnum)].mapccb:setVisible(false)
        if mapnum == 1 then
            local animationManager2 = getAnimationManager(self.createdpage[page].maps[tostring(mapnum)].mapitem)
            animationManager2:runAnimationsForSequenceNamed("new")
            self.createdpage[page].maps[tostring(mapnum)].mapccb:setVisible(true)
        else
            animationManager:setAnimationCompletedCallback(function()
                local animationManager2 = getAnimationManager(self.createdpage[page].maps[tostring(mapnum)].mapitem)
                animationManager2:runAnimationsForSequenceNamed("new")
                self.createdpage[page].maps[tostring(mapnum)].mapccb:setVisible(true)
            end)
            animationManager:runAnimationsForSequenceNamed((mapnum-1).."-"..mapnum)
        end
    end
    --todo
end

function copyChapter.setStarChapter(self,item,data,page,isnewmap)

    local mapnum = table.getTableLength(data)
    for k,v in pairs(data) do
        if not self.createdpage[page].maps[k] then
            self.createdpage[page].maps[k] = {}
            item["p"..k]:removeAllChildrenWithCleanup(true)
            self.createdpage[page].maps[k].mapccb, self.createdpage[page].maps[k].mapitem = CCBReaderLoad("copystar/map_point_copystar", nil, true, "map_point_copystar")
            item["p"..k]:addChild(self.createdpage[page].maps[k].mapccb)
            self:setStarMap(self.createdpage[page].maps[k].mapitem,v,k)
        end
    end


    local animationManager = getAnimationManager(item)
    for i=1,4 do
        item["pnode"..i]:setVisible(i<mapnum)
    end

    if isnewmap then
        self.createdpage[page].maps[tostring(mapnum)].mapccb:setVisible(false)
        if mapnum == 1 then
            local animationManager2 = getAnimationManager(self.createdpage[page].maps[tostring(mapnum)].mapitem)
            animationManager2:runAnimationsForSequenceNamed("new")
            self.createdpage[page].maps[tostring(mapnum)].mapccb:setVisible(true)
        else
            animationManager:setAnimationCompletedCallback(function()
                local animationManager2 = getAnimationManager(self.createdpage[page].maps[tostring(mapnum)].mapitem)
                animationManager2:runAnimationsForSequenceNamed("new")
                self.createdpage[page].maps[tostring(mapnum)].mapccb:setVisible(true)
            end)
            animationManager:runAnimationsForSequenceNamed((mapnum-1).."-"..mapnum)
        end
    end
    --todo
end

function copyChapter.setHadesChapter(self,item,data,page,isnewmap)

    local mapnum = table.getTableLength(data)
    for k,v in pairs(data) do
        if not self.createdpage[page].maps[k] then
            self.createdpage[page].maps[k] = {}
            item["p"..k]:removeAllChildrenWithCleanup(true)
            self.createdpage[page].maps[k].mapccb, self.createdpage[page].maps[k].mapitem = CCBReaderLoad("copydiyu/map_point_copydiyu", nil, true, "map_point_copydiyu")
            item["p"..k]:addChild(self.createdpage[page].maps[k].mapccb)
            self:setHadesMap(self.createdpage[page].maps[k].mapitem,v,k)
        end
    end

    local animationManager = getAnimationManager(item)
    for i=1,4 do
        item["pnode"..i]:setVisible(i<mapnum)
    end

    if isnewmap then
        self.createdpage[page].maps[tostring(mapnum)].mapccb:setVisible(false)
        if mapnum == 1 then
            local animationManager2 = getAnimationManager(self.createdpage[page].maps[tostring(mapnum)].mapitem)
            animationManager2:runAnimationsForSequenceNamed("new")
            self.createdpage[page].maps[tostring(mapnum)].mapccb:setVisible(true)
        else
            animationManager:setAnimationCompletedCallback(function()
                local animationManager2 = getAnimationManager(self.createdpage[page].maps[tostring(mapnum)].mapitem)
                animationManager2:runAnimationsForSequenceNamed("new")
                self.createdpage[page].maps[tostring(mapnum)].mapccb:setVisible(true)
            end)
            animationManager:runAnimationsForSequenceNamed((mapnum-1).."-"..mapnum)
        end
    end
    --todo
end

function copyChapter.loadPage(self,page,isnewmap)
    local maxpage = 1
    if self.selectpage == "star" then
        maxpage = table.getTableLength(self.stardata.sections)
    elseif self.selectpage == "hades" then
        maxpage = table.getTableLength(self.hadesdata.sections)
    else
        maxpage = table.getTableLength(self.data)
    end

    if page>0 and page <= maxpage then
        if not self.createdpage[page] then
            self.createdpage[page] = {}
            self.createdpage[page].chapterccb, self.createdpage[page].chapteritem = CCBReaderLoad("copy/"..(40000+page), nil, true, "copy_chapter"..page)
            self.createdpage[page].chapterccb:setPosition(1080*(page-1),0)
            self.rootItems.pagenode:addChild(self.createdpage[page].chapterccb)
            self.createdpage[page].maps = {}

            if self.createdpage[page].chapteritem.effectnode then
                local ccb, item = CCBReaderLoad("UIEffect/changjing/"..(40000+page).."_effect", nil, true, "_effect")
                self.createdpage[page].chapteritem.effectnode:addChild(ccb)
            end

            if (self.selectpage == "star") or (self.selectpage == "hades") then
                for i=1,4 do
                    for j=1,5 do
                         if self.createdpage[page].chapteritem["p"..i.."_"..j] then
                             setSpriteFrameByName(self.createdpage[page].chapteritem["p"..i.."_"..j],"copypoint_normal4.png")
                         else
                            break
                         end
                    end
                end
            end
        end
        if self.selectpage == "star" then
            self:setStarChapter(self.createdpage[page].chapteritem,self.stardata.sections[tostring(page)],page,isnewmap)
            if self.createdpage[page].chapteritem.hades_effect then
                self.createdpage[page].chapteritem.hades_effect:setVisible(false)
            end    
        elseif self.selectpage == "hades" then
            self:setHadesChapter(self.createdpage[page].chapteritem,self.hadesdata.sections[tostring(page)],page,isnewmap)
            if self.createdpage[page].chapteritem.hades_effect then
                self.createdpage[page].chapteritem.hades_effect:setVisible(true)
            end    
        else
            self:setChapter(self.createdpage[page].chapteritem,self.data[tostring(page)],page,isnewmap)
            if self.createdpage[page].chapteritem.hades_effect then
                self.createdpage[page].chapteritem.hades_effect:setVisible(false)
            end    
        end
    end
end

function copyChapter.loadpages(self,isnewmap)
    self:loadPage(self.presentPage,isnewmap)
    self:loadPage(self.presentPage+1)
    self:loadPage(self.presentPage-1)
end

function copyChapter.setShiftPage(self)
    local maxpage = 1
    if self.selectpage == "star" then
        maxpage = table.getTableLength(self.stardata.sections)
    elseif self.selectpage == "hades" then
        maxpage = table.getTableLength(self.hadesdata.sections)
    else
        maxpage = table.getTableLength(self.data)
    end

    if maxpage >1 then
            if self.presentPage == 1  then
                self.animationManager:runAnimationsForSequenceNamed("right")
            elseif self.presentPage == maxpage then
                self.animationManager:runAnimationsForSequenceNamed("left")
            else
                self.animationManager:runAnimationsForSequenceNamed("double")
            end
    else
            self.animationManager:runAnimationsForSequenceNamed("none")
    end

end

function copyChapter.setPage(self,page,isnewmap)
    if page <1 then
        self.presentPage = 1
    elseif page >table.getTableLength(self.data) then
        if page <= table.getTableLength(gamedata.config.section) then
            runGamePrompt({msg = "请先通过当前章节"})
        end
        self.presentPage = table.getTableLength(self.data)
    else
        self.presentPage = page
    end



    self.rootItems.chapter:setString(gameConfig.strings:NumName(gameConfig.strings.bigNum[self.data[tostring(self.presentPage)].section],self.data[tostring(self.presentPage)].name))
    if not next(self.createdpage) then
        self.rootItems.pagenode:setPosition(ccp(-1080*(self.presentPage-1), 0))
        self:loadpages(isnewmap)
    else
        local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.presentPage-1), 0))
        self.rootItems.pagenode:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
            self:loadpages(isnewmap)
        end)))
    end

    self:setShiftPage()
end

function copyChapter.setStarPage(self,page,isnewmap)
    if page < 1 then
        self.presentPage = 1
    elseif page > table.getTableLength(self.stardata.sections) then
        self.presentPage = table.getTableLength(self.stardata.sections)
    else
        self.presentPage = page
    end

    self.rootItems.chapter:setString("第"..gameConfig.strings.bigNum[self.presentPage].."章: "..gamedata.config.section[tostring(self.presentPage+40000)].name)
    if not next(self.createdpage) then
        self.rootItems.pagenode:setPosition(ccp(-1080*(self.presentPage-1), 0))
        self:loadpages(isnewmap)
    else
        local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.presentPage-1), 0))
        self.rootItems.pagenode:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
            self:loadpages(isnewmap)
        end)))
    end

    self:setShiftPage()
end

function copyChapter.setHadesPage(self,page,isnewmap)
    if page < 1 then
        self.presentPage = 1
    elseif page > table.getTableLength(self.hadesdata.sections) then
        self.presentPage = table.getTableLength(self.hadesdata.sections)
    else
        self.presentPage = page
    end

    self.rootItems.chapter:setString("第"..gameConfig.strings.bigNum[self.presentPage].."章: "..gamedata.config.section[tostring(self.presentPage+40000)].name)
    if not next(self.createdpage) then
        self.rootItems.pagenode:setPosition(ccp(-1080*(self.presentPage-1), 0))
        self:loadpages(isnewmap)
    else
        local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.presentPage-1), 0))
        self.rootItems.pagenode:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
            self:loadpages(isnewmap)
        end)))
    end

    self:setShiftPage()
end

function copyChapter.reloaddata(self,isnewmap)
    print("copyChapter.reloadData")

    self.data = self[self.selectpage.."data"]
    self.createdpage={}
    self.rootItems.pagenode:removeAllChildrenWithCleanup(true)

    if self.selectpage == "star" then
        if not self.presentPage then self.presentPage = table.getTableLength(self.stardata.sections) end
        self:setStarPage(self.presentPage,isnewmap)
    elseif self.selectpage == "hades" then
        if not self.presentPage then self.presentPage = table.getTableLength(self.hadesdata.sections) end
        self:setHadesPage(self.presentPage,isnewmap)
    elseif self.selectpage == "activity" then
        
    else
        if not self.presentPage then self.presentPage = table.getTableLength(self.data) end
        self:setPage(self.presentPage,isnewmap)
    end

    self.rootItems.bravebottom:setVisible(self.selectpage == "star")
    self.rootItems.bravetop:setVisible(self.selectpage == "star")

    self.rootItems.hadesbottom:setVisible(self.selectpage == "hades")
    self.rootItems.hadestop:setVisible(self.selectpage == "hades")

    if self.isshow_settig then
        self.rootItems.copySettingBtn:setVisible(self.selectpage == "normal")
    end    
end
--创建活动界面
function copyChapter.createActivityList( self )
    local celldict = {}

    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("copy2/cell_huodong", nil, true, "cell_activity")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.activityListTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setCell(ccbDocumentControler,self.activitydataused[tostring(a1 + 1)])
            if self.activityListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then 
            r = table.getTableLength(self.activitydataused  )
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.activityListTableView = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.activitynode:getContentSize().width,
        viewheight = self.rootItems.activitynode:getContentSize().height,
        dire = 1
    })
    self.rootItems.activitynode:addChild(self.activityListTableView)
    self.activityListTableView:setTouchPriority(-101)
end
--zzx添加
--设置金币cell
function copyChapter.setCell(self,aiCell,aiData)
    -- printT(GameScene.vipstatus)
    -- print("copyChapter.setCell")
    -- printT(aiCell)
    -- printT(aiData)
    if aiData.isOpen == 1 then

        ui.removeGray("CCSprite",aiCell.bgcoin)
        ui.removeGray("CCSprite",aiCell.bgexp)
        ui.removeGray("CCSprite",aiCell.bgFrogeStone)
        ui.removeGray("CCSprite",aiCell.bgEquipStarStone)
        ui.removeGray("CCSprite",aiCell.bgZhenfu)
        ui.removeGray("CCSprite",aiCell.bgForging)
        ui.removeGray("CCLabelTTF",aiCell.opentext)
        aiCell.times:setVisible(true)
        aiCell.timestext:setVisible(true)

        ui.setLabelString(aiCell.timestext,nil,22)

        local buynum = 0
        if tonumber(aiData["function"]) == 1 then
            buynum = GameScene.vipstatus.exp_copy_times
        elseif tonumber(aiData["function"]) == 2 then
            buynum = GameScene.vipstatus.coin_copy_times
        elseif tonumber(aiData["function"]) == 3 then
            buynum = GameScene.vipstatus.stone_copy_times
        elseif tonumber(aiData["function"]) == 4 then
            buynum = GameScene.vipstatus.upstar_times
        elseif tonumber(aiData["function"]) == 5 then
            buynum = GameScene.vipstatus.zhenfu_times
        elseif tonumber(aiData["function"]) == 6 then
            buynum = GameScene.vipstatus.forging_copy_times
        end

        if aiData.times-aiData.usedTimes+buynum <=  0 then
            ui.setLabelString(aiCell.times,0,24) 
        else
            ui.setLabelString(aiCell.times,(aiData.times - aiData.usedTimes+buynum ),22)
            
            -- ui.setLabelString(aiCell.times,aiData.times-aiData.usedTimes+GameScene.vipstatus.coin_copy_times,22) 
        end
        aiCell.button:setTouchEnabled(true)
    else
        ui.addGray("CCSprite",aiCell.bgcoin)
        ui.addGray("CCSprite",aiCell.bgexp)
        ui.addGray("CCSprite",aiCell.bgFrogeStone)
        ui.addGray("CCSprite",aiCell.bgEquipStarStone)
        ui.addGray("CCSprite",aiCell.bgZhenfu)
        ui.addGray("CCSprite",aiCell.bgForging)
        ui.addGray("CCLabelTTF",aiCell.opentext)
        aiCell.times:setVisible(false)
        aiCell.timestext:setVisible(false)
        aiCell.button:setTouchEnabled(true)
    end
    local st = ui.Split(aiData.date,";") 
    printT(st)
    local s = "每周"
    for k,v in ipairs(st) do
        if tonumber(v) == 1 then
            s = s.."一、"
        elseif  tonumber(v) == 2 then
            s = s.."二、"            
        elseif  tonumber(v) == 3 then
            s = s.."三、"
        elseif  tonumber(v) == 4 then
            s = s.."四、"            
        elseif  tonumber(v) == 5 then
            s = s.."五、"
        elseif  tonumber(v) == 6 then
            s = s.."六、"            
        elseif  tonumber(v) == 7 then
            s = s.."日"
        end
    end 
    s = s.."开启"
    if tonumber(aiData["function"]) == 1 then
        aiCell.bgexp:setVisible(true)
        aiCell.bgcoin:setVisible(false)
        aiCell.bgFrogeStone:setVisible(false)
        aiCell.bgEquipStarStone:setVisible(false)
        aiCell.bgZhenfu:setVisible(false)
        aiCell.bgForging:setVisible(false)
        ui.setLabelString(aiCell.opentext,s,14)
        aiCell.button:setTouchPriority(-103)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("挑战经验副本111")
            if aiData.isOpen ~= 1 then
                runGamePrompt({msg = "未到活动开启时间"})
            else
                gameWindows:openWindow("copyacivity",aiData)                 
            end
        end, CCControlEventTouchUpInside)   
    elseif tonumber(aiData["function"]) == 2 then
        aiCell.bgexp:setVisible(false)
        aiCell.bgcoin:setVisible(true)
        aiCell.bgFrogeStone:setVisible(false)
        aiCell.bgEquipStarStone:setVisible(false)
        aiCell.bgZhenfu:setVisible(false)
        aiCell.bgForging:setVisible(false)
        ui.setLabelString(aiCell.opentext,s,14)
        aiCell.button:setTouchPriority(-103)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling  then return end
            print("挑战金币副本")
            if aiData.isOpen ~= 1 then
                runGamePrompt({msg = "明天就能打哦~"})
            else
                gameWindows:openWindow("copyacivity",aiData)                 
            end            
        end, CCControlEventTouchUpInside)         
    elseif tonumber(aiData["function"]) == 3 then
        if not GameScene:checkopenlevelbyId(173,true) then
            ui.addGray("CCSprite",aiCell.bgcoin)
            ui.addGray("CCSprite",aiCell.bgexp)
            ui.addGray("CCSprite",aiCell.bgFrogeStone)
            ui.addGray("CCSprite",aiCell.bgEquipStarStone)
            ui.addGray("CCSprite",aiCell.bgZhenfu)
            ui.addGray("CCSprite",aiCell.bgForging)
            ui.addGray("CCLabelTTF",aiCell.opentext)
            aiCell.times:setVisible(false)
            aiCell.timestext:setVisible(false)
            aiCell.button:setTouchEnabled(true)
        end
        aiCell.bgexp:setVisible(false)
        aiCell.bgcoin:setVisible(false)
        aiCell.bgFrogeStone:setVisible(true)
        aiCell.bgEquipStarStone:setVisible(false)
        aiCell.bgZhenfu:setVisible(false)
        aiCell.bgForging:setVisible(false)
        ui.setLabelString(aiCell.opentext,s,14)
        aiCell.button:setTouchPriority(-103)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling  then return end
            print("挑战精炼石副本")
            if not GameScene:checkopenlevelbyId(173) then
                print("not open")
            elseif aiData.isOpen ~= 1 then
                runGamePrompt({msg = "明天就能打哦~"})
            else
                gameWindows:openWindow("copyacivity",aiData)                 
            end            
        end, CCControlEventTouchUpInside)
    elseif tonumber(aiData["function"]) == 4 then
        if not GameScene:checkopenlevelbyId(206,true) then
            ui.addGray("CCSprite",aiCell.bgcoin)
            ui.addGray("CCSprite",aiCell.bgexp)
            ui.addGray("CCSprite",aiCell.bgFrogeStone)
            ui.addGray("CCSprite",aiCell.bgEquipStarStone)
            ui.addGray("CCSprite",aiCell.bgZhenfu)
            ui.addGray("CCSprite",aiCell.bgForging)
            ui.addGray("CCLabelTTF",aiCell.opentext)
            aiCell.times:setVisible(false)
            aiCell.timestext:setVisible(false)
            aiCell.button:setTouchEnabled(true)
        end
        aiCell.bgexp:setVisible(false)
        aiCell.bgcoin:setVisible(false)
        aiCell.bgFrogeStone:setVisible(false)
        aiCell.bgEquipStarStone:setVisible(true)
        aiCell.bgZhenfu:setVisible(false)
        aiCell.bgForging:setVisible(false)
        ui.setLabelString(aiCell.opentext,s,14)
        aiCell.button:setTouchPriority(-103)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling  then return end
            print("挑战精炼石副本")
            if not GameScene:checkopenlevelbyId(206) then
                print("not open")
            elseif aiData.isOpen ~= 1 then
                runGamePrompt({msg = "明天就能打哦~"})
            else
                gameWindows:openWindow("copyacivity",aiData)
            end
        end, CCControlEventTouchUpInside)
    elseif tonumber(aiData["function"]) == 5 then
        if not GameScene:checkopenlevelbyId(207,true) then
            ui.addGray("CCSprite",aiCell.bgcoin)
            ui.addGray("CCSprite",aiCell.bgexp)
            ui.addGray("CCSprite",aiCell.bgFrogeStone)
            ui.addGray("CCSprite",aiCell.bgEquipStarStone)
            ui.addGray("CCSprite",aiCell.bgZhenfu)
            ui.addGray("CCSprite",aiCell.bgForging)
            ui.addGray("CCLabelTTF",aiCell.opentext)
            aiCell.times:setVisible(false)
            aiCell.timestext:setVisible(false)
            aiCell.button:setTouchEnabled(true)
        end
        aiCell.bgexp:setVisible(false)
        aiCell.bgcoin:setVisible(false)
        aiCell.bgFrogeStone:setVisible(false)
        aiCell.bgEquipStarStone:setVisible(false)
        aiCell.bgZhenfu:setVisible(true)
        aiCell.bgForging:setVisible(false)
        ui.setLabelString(aiCell.opentext,s,14)
        aiCell.button:setTouchPriority(-103)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling  then return end
            print("挑战精炼石副本")
            if not GameScene:checkopenlevelbyId(207) then
                print("not open")
            elseif aiData.isOpen ~= 1 then
                runGamePrompt({msg = "明天就能打哦~"})
            else
                gameWindows:openWindow("copyacivity",aiData)
            end
        end, CCControlEventTouchUpInside)
    elseif tonumber(aiData["function"]) == 6 then
        if not GameScene:checkopenlevelbyId(389,true) then
            ui.addGray("CCSprite",aiCell.bgcoin)
            ui.addGray("CCSprite",aiCell.bgexp)
            ui.addGray("CCSprite",aiCell.bgFrogeStone)
            ui.addGray("CCSprite",aiCell.bgEquipStarStone)
            ui.addGray("CCSprite",aiCell.bgZhenfu)
            ui.addGray("CCSprite",aiCell.bgForging)
            ui.addGray("CCLabelTTF",aiCell.opentext)
            aiCell.times:setVisible(false)
            aiCell.timestext:setVisible(false)
            aiCell.button:setTouchEnabled(true)
        end
        aiCell.bgexp:setVisible(false)
        aiCell.bgcoin:setVisible(false)
        aiCell.bgFrogeStone:setVisible(false)
        aiCell.bgEquipStarStone:setVisible(false)
        aiCell.bgZhenfu:setVisible(false)
        aiCell.bgForging:setVisible(true)
        ui.setLabelString(aiCell.opentext,s,14)
        aiCell.button:setTouchPriority(-103)
        aiCell.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling  then return end
            print("挑战注灵石副本")
            if not GameScene:checkopenlevelbyId(389) then
                print("not open")
            elseif aiData.isOpen ~= 1 then
                runGamePrompt({msg = "明天就能打哦~"})
            else
                gameWindows:openWindow("copyacivity",aiData)
            end
        end, CCControlEventTouchUpInside)
    end 
end
function copyChapter.reloadnormalData(self,data,isnewmap)
    if data then
        self.normaldata = data
    end
    self:reloaddata(isnewmap)
end

function copyChapter.reloadbraveData(self,data,isnewmap)
    if data then
        self.bravedata = data
    end
    self:reloaddata(isnewmap)
end
--zzx添加
--处理活动界面数据
function copyChapter.reloadactivityData( self,data,isnewmap)
    if data then
        self.activitydataused= data
    end
    -- self:createActivityData()
    if self.activityListTableView == nil then
        self:createActivityList()
    else
        self.activityListTableView:reloadData()
    end
    
end
--zzx添加
function copyChapter.createActivityData( self)
    self.activitydataused = {}
    local vip = gamedata.config.vip
    for k,v in pairs(self.activityDailyConfigureData) do
        local t = {}
        if v["function"] == 1 then
            t.times = vip[tostring(GameScene.vip.vip)].exp_copy_times
        elseif  v["function"] == 2 then
            t.times = vip[tostring(GameScene.vip.vip)].coin_copy_times
        elseif  v["function"] == 3 then
            t.times = vip[tostring(GameScene.vip.vip)].stone_copy_times
        elseif  v["function"] == 4 then
            t.times = vip[tostring(GameScene.vip.vip)].upstar_times
        elseif  v["function"] == 5 then
            t.times = vip[tostring(GameScene.vip.vip)].zhenfu_times
        elseif  v["function"] == 6 then
            t.times = vip[tostring(GameScene.vip.vip)].forging_copy_times
        end
        for m,n in pairs(v) do
            t[m] = n
        end
        table.insert(self.activitydataused,t)
    end
    for k,v in ipairs(self.activitydataused) do
        for m,n in pairs(self.activitydata) do
            if tonumber(v.id) == tonumber(n.aid) then
                for i,j in pairs(n) do
                    v[i] = j
                end
                v.isOpen = true
                break
            end
        end
    end
    for k,v in ipairs(self.activitydataused) do
        if v.isOpen == nil then
            v.isOpen = false
            v.aid = v.id
            v.usedTimes = -1
        end
    end
    table.sort(self.activitydataused,function(a,b)
        if a.isOpen == true and b.isOpen == false then
            return true
        elseif  a.isOpen == false and b.isOpen == true then
            return false
        else
            if a.id > b.id then
                return true
            else
                return false
            end
        end
    end)
    printT(vip)
    print("self.activitydataused ==========")
    printT(self.activitydataused)
end
--role.level
function copyChapter.battleCoinData( self,aiData )
    print("copyChapter.battleCoinData")
    -- printT(aiData)
    self.activitydataused = aiData
    gameWindows:closeWindow("copyacivityitem")

    self.activityListTableView:reloadData()
end
function copyChapter.battleExpData( self,aiData )
    print("copyChapter.battleExpData")
    -- printT(aiData)
    gameWindows:closeWindow("copyacivityitem")
    self.activitydataused = aiData
    self.activityListTableView:reloadData()
end
function copyChapter.battleStoneData(self,aiData)
    print("copyChapter.battleStoneData")
    -- printT(aiData)
    gameWindows:closeWindow("copyacivityitem")
    self.activitydataused = aiData
    self.activityListTableView:reloadData()
end
function copyChapter.battleEquipStarData(self,aiData)
    print("copyChapter.battleEquipStarData")
    -- printT(aiData)
    gameWindows:closeWindow("copyacivityitem")
    self.activitydataused = aiData
    self.activityListTableView:reloadData()
end
function copyChapter.battleZhenfuData(self,aiData)
    print("copyChapter.battleZhenfuData")
    -- printT(aiData)
    gameWindows:closeWindow("copyacivityitem")
    self.activitydataused = aiData
    self.activityListTableView:reloadData()
end
function copyChapter.battleForgingData(self,aiData)
    print("copyChapter.battleForgingData")
    -- printT(aiData)
    gameWindows:closeWindow("copyacivityitem")
    self.activitydataused = aiData
    self.activityListTableView:reloadData()
end

--hellcopy
function copyChapter.reloadHellCopyData(self, data)
    if data then
        self.helldata = data
    end
    --深渊副本跳转
    --todo
    if true then
        GameScene:shiftLayer("hellcopy","up",self.helldata)
    else
        runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","weikaiqi")})
    end
end

--starcopy
function copyChapter.reloadStarCopyData( self,data,isnewmap)
    if data then
        self.stardata = data.starcopy
    end
    self:reloaddata(isnewmap)
end

function copyChapter.setStarCopyData(self)


end

function copyChapter.reloadHadesCopyData( self,data,isnewmap)

    if data then
        self.hadesdata = data.hadescopy
    end

    printT(self.hadesdata,"地狱副本")
    -- self:reloaddata(isnewmap)
    print("reloadHadesCopyData_s",os.clock())
    self:setPageHadesCopy()
    print("reloadHadesCopyData_e",os.clock())
end


function copyChapter.setPageHadesCopy(self)

    local sectionData = self.hadesdata.sections[tostring(table.getTableLength(self.hadesdata.sections))]
    local curSectionData = sectionData[tostring(table.getTableLength(sectionData))]

    -- curSectionData.mapid = 42130
    -- curSectionData.points = {
    --     ["1"] = {
    --         pointid = 1,
    --         pointstatus = 1,
    --     },
    --     ["2"] = {
    --         pointid = 2,
    --         pointstatus = 1,
    --     },
    --     ["3"] = {
    --         pointid = 3,
    --         pointstatus = 1,
    --     },
    --     ["4"] = {
    --         pointid = 4,
    --         pointstatus = 1,
    --     },
    --     ["5"] = {
    --         pointid = 5,
    --         pointstatus = 1,
    --     },
    -- }
    local curMapId = curSectionData.mapid
    local curPoint = table.getTableLength(curSectionData.points)
    printT(curSectionData,"curSectionData")

    if not self.hadesCCB then
        local node,items = CCBReaderLoad("yuangushenyuan/yuangushenyuan", nil, true, "yuangushenyuan")
        self.rootItems.hades:addChild(node)

        local node2,items2 = CCBReaderLoad("yuangushenyuan/yuangushenyuan_map", nil, true, "yuangushenyuan_map")
        items.generalNode:addChild(node2)

        self.hadesCCB = {node = node,items = items,generalNode = node2,generalItems = items2}
        self.hadesCCB.items.topnode:setPositionY(self.toppos - 100)
    end


    self.bgAnimationManager = getAnimationManager(self.hadesCCB.generalItems)
    self.bgAnimationManager:runAnimationsForSequenceNamed("free")


    self.hadesCCB.items.powerNode:setVisible(true)

    self.hadesCCB.items.buzhenBtn:setSwallowsTouch(true)
    self.hadesCCB.items.buzhenBtn:setTouchPriority(-103)
    self.hadesCCB.items.buzhenBtn:addHandleOfControlEvent(function()
        if gameConfig:checkBuildOpen(198) and GameScene:checkopenlevelbyId(198,true) then
            GameScene:shiftLayer("deployment","up")
        else
            gameWindows:openWindow("slotarrange")
        end
    end, CCControlEventTouchUpInside)


    self.hadesCCB.items.ruleBtn:setSwallowsTouch(true)
    self.hadesCCB.items.ruleBtn:setTouchPriority(-103)
    self.hadesCCB.items.ruleBtn:addHandleOfControlEvent(function()
        ui.popCommonRule(430)
    end, CCControlEventTouchUpInside)
    

    ui.setLabelString(self.hadesCCB.items.doLab,nil,19)

    local func = function ()
        if curSectionData.points[tostring(curPoint)].pointstatus == -1 then
            if self.hadesdata.attacknum >= tonumber(gamedata.config.global_kv.hades_copy_times.value) then
               runGamePrompt({msg = "今日挑战次数已用完"})
            else
                gameWindows:openWindow("copyhadesInfo",{ mapid = curMapId, pointid = curPoint, pointstatus = curSectionData.points[tostring(curPoint)].pointstatus },nil)
            end
        else
            runGamePrompt({msg = "已通过本关卡挑战"})
        end 
    end


    if self.hadesdata.attacknum >= tonumber(gamedata.config.global_kv.hades_copy_times.value) then
        ui.addGray("CCControlButton",self.hadesCCB.items.doBtn)
        ui.addGray("CCLabelTTF",self.hadesCCB.items.doLab)
    else
        ui.removeGray("CCControlButton",self.hadesCCB.items.doBtn)
        ui.removeGray("CCLabelTTF",self.hadesCCB.items.doLab)
    end

    self.hadesCCB.items.doBtn:setSwallowsTouch(true)
    self.hadesCCB.items.doBtn:setTouchPriority(-105)
    self.hadesCCB.items.doBtn:addHandleOfControlEvent(function()
        func()
    end, CCControlEventTouchUpInside)

    self.hadesCCB.generalItems.battleBtn2:setSwallowsTouch(true)
    self.hadesCCB.generalItems.battleBtn2:setTouchPriority(-105)
    self.hadesCCB.generalItems.battleBtn2:addHandleOfControlEvent(function()
        func()
    end, CCControlEventTouchUpInside)

    --挑战次数
    ui.setLabelString(self.hadesCCB.items.fixed1,"挑战次数",1009,38)

    ui.setLabelString(self.hadesCCB.items.times,(gamedata.config.global_kv.hades_copy_times.value-self.hadesdata.attacknum).."/"..gamedata.config.global_kv.hades_copy_times.value)

    for i = 1,5 do

        local point = (curPoint + i - 1) % 5
        if point == 0 then
            point = 5
        end
        local mapId = (curPoint + i - 1) > 5 and (curMapId + 1) or curMapId

        print("mapId",mapId,point)
        if gamedata.config.hades_copy[tostring(mapId)] and gamedata.config.hades_copy[tostring(mapId)][tostring(point)] then
            
            local config = gamedata.config.hades_copy[tostring(mapId)][tostring(point)]
            if not self.hadesGenerals[i] then
                addDelayUpdateFunc(function()
                    local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(config.icon).animationid)].name
                    local _general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
                    _general:setScale(2)
                    _general:setPosition(0,0)
                    _general:setAnimation("stand",false,0)
                    self.hadesCCB.generalItems["generalNode"..i]:addChild(_general)
                    self.hadesGenerals[i] = _general

                    if i == 1 then
                        if curSectionData.points[tostring(curPoint)].pointstatus == -1 then
                            ui.removeGray("CCNode", _general.root or _general)
                            _general:setAnimation("stand",true,0)
                        else
                            ui.addGray("CCNode", _general.root or _general)
                            _general:setAnimation("stand",false,0)
                        end
                    end
                    
                end,"copyhades"..i)
            end

            if i == 1 then
                
            end
        else
            self.hadesCCB.generalItems["generalNode"..i]:removeAllChildrenWithCleanup(true)
            self.hadesGenerals[i] = nil
        end
    end

    addDelayUpdateFunc(function()
        local config = gamedata.config.hades_copy[tostring(curMapId)][tostring(curPoint)]
        --名字
        ui.setLabelString(self.hadesCCB.items.nameTxt1,"第"..((curMapId-42100-1)*5+curPoint).."关",1010,38)
        ui.setLabelString(self.hadesCCB.items.nameTxt2,config.name,1008,38)
        --推荐战斗力
        ui.setLabelString(self.hadesCCB.items.powerTxt1,"推荐战斗力:",1010,38)
        ui.setLabelString(self.hadesCCB.items.powerTxt2,config.power,1008,38)
        --奖励
        local rewards = ui.getIDandNUMs(config.reward)
        self:hadesCopyRewardList(rewards)
    end,"copyhadesReward")

    --通关奖励
    addDelayUpdateFunc(function()
        self:hadesCopyReward()
    end,"copyhadesReward")

end

function copyChapter.hadesCopyReward(self)
     --通关奖励
    local curRewardMap = nil
    local findCanReward = false
    for i=1,table.getTableLength(self.hadesdata.sections) do
        local sectionData = self.hadesdata.sections[tostring(i)]
        for j=1,table.getTableLength(sectionData) do
            curRewardMap = sectionData[tostring(j)]
            if curRewardMap.mapbox == 1 then
                findCanReward = true
                break
            end
        end

        if findCanReward then
            break
        end
    end

    if curRewardMap then
        self.hadesCCB.items.rewardNode:setVisible(true)
        local mapboxreward = ui.getIDandNUMs(gamedata.config.hades_map[tostring(curRewardMap.mapid)].reward) or {}

        ui.setNewIcon(self.hadesCCB.items, mapboxreward[1])
        if curRewardMap.mapbox == 1 then
            self.hadesCCB.items.rewardEffect:setVisible(true)
            self.hadesCCB.items.rewardDes:setVisible(false)
            self.hadesCCB.items.rewardDes2:setVisible(true)
        else
            self.hadesCCB.items.rewardEffect:setVisible(false)
            self.hadesCCB.items.rewardDes:setVisible(true)
            self.hadesCCB.items.rewardDes2:setVisible(false)
        end

        self.hadesCCB.items["i_button"]:setSwallowsTouch(true)
        self.hadesCCB.items["i_button"]:setTouchPriority(-103)
        self.hadesCCB.items["i_button"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            local mapboxstatus = curRewardMap.mapbox or 0
            local mapid = curRewardMap.mapid
            gameWindows:openWindow("hadesAllReward",{mapboxreward = mapboxreward,mapboxstatus = mapboxstatus, mapid = mapid, },nil)
        end, CCControlEventTouchUpInside)

        ui.setLabelString(self.hadesCCB.items.rewardDes2,nil,26)
        self.hadesCCB.items.rewardDes:setString(((curRewardMap.mapid - 42100)*5).."关奖励")

    else
        self.hadesCCB.items.rewardNode:setVisible(false)
    end

end

function copyChapter.hadesCopyBattleCallback(self,t)

    if not self.bgAnimationManager then
        UIRequest({type = 1370})
        return
    end


    local isMax = false
    local curMapId = t.params.mapid
    local curPoint = t.params.pointid

    --先创建出最后一个任务动画，保证切换时候不卡顿
    self.hadesCCB.generalItems.tempNode:removeAllChildrenWithCleanup(true)
    self.tempGeneral = nil

    local point = (curPoint + 5) % 5
    if point == 0 then
        point = 5
    end
    local mapId = (curPoint + 5) > 5 and (curMapId + 1) or curMapId

    if gamedata.config.hades_copy[tostring(mapId)] and gamedata.config.hades_copy[tostring(mapId)][tostring(point)] then
        local config = gamedata.config.hades_copy[tostring(mapId)][tostring(point)]
        local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(config.icon).animationid)].name
        local _general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        _general:setScale(2)
        _general:setAnimation("stand",false,0)
        print("aaaaaaa")
        self.hadesCCB.generalItems.tempNode:addChild(_general)
        self.tempGeneral = _general
    end

    if ((curMapId - 42100) == table.getTableLength(gamedata.config.hades_map)) and (curPoint == 5) then
        isMax = true
    end

    if t.result == 1 and not isMax then
        self.bgAnimationManager:setAnimationCompletedCallback(function()
            -- self.bgAnimationManager:runAnimationsForSequenceNamed("free")
            
            if self.hadesGenerals[1] then
               self.hadesGenerals[1]:removeFromParentAndCleanup(true)
               self.hadesGenerals[1] = nil
            end

            for i=2,5 do
                if self.hadesGenerals[i] then
                    print("bbbbbbb")
                    self.hadesGenerals[i]:retain()
                    self.hadesGenerals[i]:removeFromParentAndCleanup(false)
                    self.hadesCCB.generalItems["generalNode"..(i-1)]:addChild(self.hadesGenerals[i])
                    self.hadesGenerals[i]:release()
                    -- self.hadesCCB.generalItems["generalNode"..(i-1)]:removeAllChildrenWithCleanup(true)
                    
                    
                    self.hadesGenerals[i - 1] = self.hadesGenerals[i]
                end
            end

            if self.tempGeneral then
                print("ccccccc")
                self.hadesGenerals[5] = self.tempGeneral
                self.hadesGenerals[5]:retain()
                self.hadesGenerals[5]:removeFromParentAndCleanup(false)
                self.hadesCCB.generalItems["generalNode5"]:addChild(self.hadesGenerals[5])
                self.hadesGenerals[5]:release()
                self.tempGeneral = nil
                -- self.hadesCCB.generalItems["generalNode5"]:removeAllChildrenWithCleanup(true)
                
                
            else
                self.hadesGenerals[table.getTableLength(self.hadesGenerals)] = nil
            end

            if self.hadesGenerals[1] then
                self.hadesGenerals[1]:setAnimation("stand",true,0)
            end
            
            UIRequest({type = 1370})
        end)
        self.bgAnimationManager:runAnimationsForSequenceNamed("next")
    else
        UIRequest({type = 1370})
    end
    
end


function copyChapter.hadesCopyAwardCallback(self)
    
end


function copyChapter.hadesCopyRewardList(self,rewards)
    self.hadesCCB.items.rewardList:removeAllChildrenWithCleanup(true)

    local celldict = {}

    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(150, 200)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ui.setNewIcon(ccbDocumentControler, rewards[a1+1])
            ccbDocumentControler["i_button"]:setTouchPriority(-103)
            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(rewards[a1+1].cid)
            end, CCControlEventTouchUpInside)

            cellCCB:setScale(0.8)
            cellCCB:setPosition(150/2, 200/2)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then 
            r = table.getTableLength(rewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local rewardList = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.hadesCCB.items.rewardList:getContentSize().width,
        viewheight = self.hadesCCB.items.rewardList:getContentSize().height,
        dire = 0
    })
    self.hadesCCB.items.rewardList:addChild(rewardList)
    rewardList:setTouchPriority(-102)

end

function copyChapter.setHadesCopyData(self)


end


function copyChapter.UIUpdateData(self, isreset)
    if isreset then
        self:shiftPage(self.selectpage)
    end
end

return copyChapter
