--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
--

local favoritegeneral = {
    

    resource = nil,

    rootFavorNode = nil,
    rootItems = nil,

    giftsTableView = nil,

    favoriteTableView = nil,

    data = {},
    selectData = {},
    giftsData = {},
    favoriteData = {},
    favoritegeneralconfig = {},
    levelchangeNum = 0,

    listdata = {},
    firstnum = 0,

    giftsIndex = nil,
    giftsIndexPos = {x = 0,y = 0}
}

function favoritegeneral.init(self,parent,toppos)
    self.rootFavorNode,self.rootItems = CCBReaderLoad("love/love", nil, true, "love")
    self.rootFavorNode:setPosition(0,0)
    parent:addChild(self.rootFavorNode)

    if self.rootItems.topnode then
        self.rootItems.topnode:setPositionY(toppos)
    end

    ui.setLabelString(self.rootItems.expdescText, nil, 21)

    self.rootItems.exchange:setTouchPriority(-101)
    self.rootItems.exchange:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("favoritetransfer",{source = self.favoriteData,listdata = self.listdata})
    end, CCControlEventTouchUpInside)
    

    ui.setLabelString(self.rootItems.generalsListText, nil, 46)
    self.rootItems.generalsListBtn:setTouchPriority(-101)
    self.rootItems.generalsListBtn:addHandleOfControlEvent(function()
        -- print("i...generalsListBtn:")
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("favoriteList","generallist")
        -- UIRequest({type = 3671})
    end, CCControlEventTouchUpInside)



    ui.setLabelString(self.rootItems.achievementText, nil, 46)
    self.rootItems.achievementBtn:setTouchPriority(-101)
    self.rootItems.achievementBtn:addHandleOfControlEvent(function()
        -- print("i...achievementBtn:")
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("favoriteList","achievement")
        -- UIRequest({type = 3673})
    end, CCControlEventTouchUpInside)


    ui.setLabelString(self.rootItems.onekeyText, nil, 19)


    local phoName = CCSprite:create("public/publicsprite/spr_56.png")

    self.rootItems.expbarprogress = CCProgressTimer:create(phoName)
    self.rootItems.expbarprogress:setAnchorPoint(ccp(0.0, 0.5))
    self.rootItems.expbarprogress:setType(kCCProgressTimerTypeBar)
    self.rootItems.expbarprogress:setMidpoint(ccp(0, 0.5))
    self.rootItems.expbarprogress:setBarChangeRate(ccp(1, 0))
    self.rootItems.expbarprogress:setPosition(ccp(-494.0, 0.2))
    self.rootItems.expbarprogress:setPercentage(0)
    self.rootItems.expbarprogress:setScaleX(0.995)
    self.rootItems.expNode:addChild(self.rootItems.expbarprogress)
    
    -- 请求可以被送礼的伙伴列表
    UIRequest({type = 3671})
    -- 请求成就系统信息 用于设置红点
    UIRequest({type = 3673})
    
    guide.controller:addComplete(138,function()
        UIRequest({type = 2882,opt=1,sysID=138})
    end)
    self:initTouch()
end


function favoritegeneral.initTouch(self)

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer2,x,y) then
            self.autoTouchX = x
            self.autoTouchY = y
            return true
        else
            self.autoTouchX = 0
            self.autoTouchY = 0
        end
    end

    local function ccTouchMoved(x, y)
        print("ccTouchMoved",x,y)

        self.autoTouchX = x
        self.autoTouchY = y
    end

    local function ccTouchEnded(x, y)
        print("ccTouchEnded",x,y)

        self.autoTouchX = 0
        self.autoTouchY = 0
        
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

    self.rootItems.touchLayer2:registerScriptTouchHandler(onTouch, false, -105, false)
    self.rootItems.touchLayer2:setTouchPriority(-105)
    self.rootItems.touchLayer2:setTouchEnabled(true)
end

function favoritegeneral.achievementReload(self,data)
    self.achievementdata = data
    local hasHit = false
    for k,v in pairs(self.achievementdata) do
        if v.status == 1 then
            hasHit = true
            break
        end
    end
    print("hashit===",hasHit)
    ui.sethint(self.rootItems["f_achivement_hint"],hasHit)
end

function favoritegeneral.listdataReload(self,data)

    
    self.listdata = {}
    for k,v in pairs(data) do
        if v.ison then
            table.insert(self.listdata, v)
        end
        
    end
    local generalconfig = gamedata.config.general
    local sortFunc = function( a,b )
        print("a.ison===",a.ison,b.ison)
        if a.ison > b.ison then
            return true
        elseif a.ison < b.ison then
            return false
        else
            return generalconfig[tostring(a.cid)]["quality"] > generalconfig[tostring(b.cid)]["quality"]
        end
    end
    table.sort(self.listdata,sortFunc)

    -- 请求当前武将好感度信息
    if self.favoriteData and next(self.favoriteData) then
        UIRequest({type = 3670,cid = self.favoriteData.cid})  
    else
        UIRequest({type = 3670})        
    end

end

function favoritegeneral.executeGifts(self,index)

    local celldata = self.giftsData[tonumber(index)] or {}
    if self.favoriteData.ison == -1 then
        runGamePrompt({msg = "伙伴已消失，不能赠送礼物了。"})
        self.giftsIndex = nil
        return
    end

    if celldata.num == 0 then
        -- print("物品不足获取途径")
        if self.giftsIndex then
            shortPropById(celldata.cid)
        else
            gameWindows:openWindow("dropTips",celldata,nil)
        end
        self.giftsIndex = nil
        return
    end
    
    local favoritegeneralconfig = gamedata.config:getConfigByName("favorable")[tostring(self.favoriteData.cid)]
    -- printT(favoritegeneralconfig)
    if self.favoriteData.level >= favoritegeneralconfig["level"] then
        runGamePrompt({msg = "他已经对你足够死心塌地了！"})
        self.giftsIndex = nil
        return
    else

        print("self.data.favorite.generallevel----------",self.data.favorite.generallevel)
        if self.data.favorite.generallevel < gamedata.config:getConfigByName("favorable_level")[tostring(self.favoriteData.level+1)].general_lv then
            runGamePrompt({msg = "该伙伴等级需达到"..gamedata.config:getConfigByName("favorable_level")[tostring(self.favoriteData.level+1)].general_lv.."才能升级好感度"})
            self.giftsIndex = nil
            return
        end

    end

    
    local props = {}
    table.insert(props, {cid=self.giftsData[tonumber(index)]["cid"],num=1 })

    self.giftsIndex = index
    UIRequest({type = 3672, cid = self.favoriteData.cid, props=props})
end

function favoritegeneral.giftsCreateList(self)
    -- print("giftsCreateList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(200, 260)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_Icon_chong2.ccbi", nil, true, "Icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
                    --
                    local celldata = self.giftsData[tonumber(a1+1)] or {}
                   
                    ui.setNewIconName(ccbDocumentControler,{cid = celldata.cid, num = celldata.num})

                    local itemconfig = gamedata.config.props[tostring(celldata.cid)]
                    ui.setLabelString(ccbDocumentControler.in_name,("好感度＋"..itemconfig.param1),((itemconfig.quality and itemconfig.quality ~= 0) and itemconfig.quality or 1)*2)

                    -- ccbDocumentControler["i_select"]:setVisible(false)

                    if celldata.num == 0 then
                        ccbDocumentControler.hasNode:setVisible(true)
                    else
                        ccbDocumentControler.hasNode:setVisible(false)
                    end
                    
                    

                    if ccbDocumentControler.i_button then

                        ccbDocumentControler.i_button:removeAllChildrenWithCleanup(true)
                        local eventFunc = function ( donum)
                        end

                        local beginFunc = function (  )
                            if gameTouch.isScrollling then return end
                            print("beginFunc")

                            self.giftsIndexPos = ccbDocumentControler.i_button:convertToWorldSpace(ccp(0,0))

                            self:executeGifts(a1+1)
                        end

                        local endFunc = function ()
                            print("endFunc")
                            self.giftsIndex = nil
                        end

                        ui.creatDelayButton(ccbDocumentControler.i_button,-105,eventFunc,beginFunc,endFunc,1)

                        ccbDocumentControler.i_button:setSwallowsTouch(true)
                        ccbDocumentControler.i_button:setTouchPriority(-104)
                        ccbDocumentControler.i_button:addHandleOfControlEvent(function()
                        end, CCControlEventTouchUpInside)
                    end
                    
                    local favoritegeneralconfig = gamedata.config.favorable[tostring(self.favoriteData.cid)]
                    if self.favoriteData.level >= favoritegeneralconfig["level"] then
                        ui.addGray("CCControlButton",ccbDocumentControler.i_button)
                    else
                        ui.removeGray("CCControlButton",ccbDocumentControler.i_button)

                    end
                    --

                cellCCB:setPosition(100,160)

                if first then
                    a2:addChild(cellCCB)
                end


            r = a2
        elseif fn == "numberOfCells" then
            r =  table.getTableLength(self.giftsData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            -- gameTouch.isScrollling = true
        end
        return r
    end)

    self.giftsTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 0,
    })
    self.giftsTableView:setTouchPriority(-102)
    self.rootItems.listnode:addChild(self.giftsTableView)
end

function favoritegeneral.favoriteSetLevelup(self, data)
    -- props.param1(道具获得经验)
    local allexp = 0
    for k,v in pairs(data.data) do
        local propsconfig = gamedata.config.props[tostring(v.cid)]
        local expnum = tonumber(propsconfig.param1)
        allexp = allexp + expnum*v.num
    end

    local msgString = ""

    if data.baojinum == 0 then
        msgString = "获得好感度"..allexp
    else
        msgString = msgString.."暴击"..data.baojinum.."次"
    end

    -- print("changelevel11111==",self.levelchangeNum)
    if self.levelchangeNum ~= 0 then
        msgString = msgString.."，提升"..self.levelchangeNum.."级"
    end



    runGamePrompt({msg = msgString})

    if data.baojinum ~= 0 or self.levelchangeNum ~= 0 then
        self:effectAction(1)
    else
        self:effectAction(2)
    end


    local function checkTouch(  )
        if (self.autoTouchX - self.giftsIndexPos.x >= 0) and (self.autoTouchX - self.giftsIndexPos.x <= 150) and (self.autoTouchY - self.giftsIndexPos.y >= 0) and (self.autoTouchY - self.giftsIndexPos.y <= 150) then
            return true
        else
            return false
        end
    end
    

    print("检测继续执行",self.giftsIndex,self.levelchangeNum,checkTouch())
    if self.giftsIndex and  self.levelchangeNum == 0 and checkTouch() then


        self.rootItems.touchLayer2:stopAllActions()
        self.rootItems.touchLayer2:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()

            print("继续执行",self.giftsIndex,checkTouch())
            if self.giftsIndex and checkTouch() then
                self:executeGifts(self.giftsIndex)
            else
                self.giftsIndex = nil
            end
            
        end)))
    end

    if self.levelchangeNum ~= 0 then
        UIRequest({type = 3671})
    end
end

function favoritegeneral.effectAction( self,num )
    if tonumber(num) == 1 then
        local cellCCB, ccbDocumentControler = CCBReaderLoad("UIEffect/love/love_up.ccbi", nil, true, "love_up")
        self.rootItems.effectNode:addChild(cellCCB)

        self.animationManager = getAnimationManager(ccbDocumentControler)
        self.animationManager:setAnimationCompletedCallback(function()
            -- print("complete111")

            self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
            cellCCB = nil
            ccbDocumentControler = nil
        end)
        self.animationManager:runAnimationsForSequenceNamed("Default Timeline")
    else
        local cellCCB, ccbDocumentControler = CCBReaderLoad("UIEffect/love/love_add.ccbi", nil, true, "love_add")
        self.rootItems.effectNode:addChild(cellCCB)
        self.animationManager = getAnimationManager(ccbDocumentControler)
        self.animationManager:setAnimationCompletedCallback(function()
            -- print("complete000")

            self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
            cellCCB = nil
            ccbDocumentControler = nil

        end)
        self.animationManager:runAnimationsForSequenceNamed("Default Timeline")
    end
    
end

function favoritegeneral.favoriteCreateList(self)
    -- print("favoriteCreateList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(400, 75)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("love/cell_loveinfo.ccbi", nil, true, "loveinfo")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
                local celldata = self.favoritegeneralconfig[a1+1] or {}

                local attribute, attributevalue = gamedata.getIDandData(celldata)
                -- print("attribute==",attribute, attributevalue)

                -- ui.setLabelString(ccbDocumentControler.itemlevelLabel,a1+1,26)
                -- ccbDocumentControler.itemnameLabel:setString(gameConfig.strings.attr_type[attribute])
                -- ui.setLabelString(ccbDocumentControler.itemaddnumLabel,attributevalue,26)
                -- if math.mod(a1+1,2) == 1 then
                    ccbDocumentControler.usedNode:setVisible(false)
                -- else
                --     ccbDocumentControler.usedNode:setVisible(true)
                -- end

                if a1+1 <= self.favoriteData.level then
                    ui.setLabelString(ccbDocumentControler.itemlevelLabel,a1+1,26)
                    ui.setLabelString(ccbDocumentControler.itemnameLabel,gameConfig.strings.attr_type[attribute],1)
                    ui.setLabelString(ccbDocumentControler.itemaddnumLabel,("＋"..attributevalue),26)

                    ui.removeGray("CCSprite",ccbDocumentControler.lovemark)

                else

                    ui.setLabelString(ccbDocumentControler.itemlevelLabel,a1+1,30)
                    ui.setLabelString(ccbDocumentControler.itemnameLabel,gameConfig.strings.attr_type[attribute],29)
                    -- ccbDocumentControler.itemnameLabel:setString(gameConfig.strings.attr_type[attribute])
                    ui.setLabelString(ccbDocumentControler.itemaddnumLabel,("＋"..attributevalue),30)

                    ui.addGray("CCSprite",ccbDocumentControler.lovemark)
                end


                cellCCB:setPosition(400/2,75/2)

                if first then
                    a2:addChild(cellCCB)
                end


            r = a2
        elseif fn == "numberOfCells" then
            r =  table.getTableLength(self.favoritegeneralconfig)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            -- gameTouch.isScrollling = true
        end
        return r
    end)

    self.favoriteTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.favoriteNode:getContentSize().width,
        viewheight = self.rootItems.favoriteNode:getContentSize().height,
        dire = 1,
    })
    self.favoriteTableView:setTouchPriority(-102)
    self.rootItems.favoriteNode:addChild(self.favoriteTableView)
end



function favoritegeneral.reloadData(self,data,touchLayerSet)
    -- print("reloadgeneral")
    --printT(data)
    self.data = data

    if next(self.favoriteData) then
        self.levelchangeNum = data.favorite.level - self.favoriteData.level
        -- print("changelevel22222==",self.levelchangeNum)
    end

    self.favoriteData = data.favorite

    self.giftsData = {}
    for k,v in pairs(data.gifts) do
        table.insert(self.giftsData,v)
    end
    local function sortfun(a,b )
        return a.cid <b.cid
    end
    table.sort(self.giftsData,sortfun)


    -- local hasdata = {}
    -- local nodata = {}
    -- for k,v in pairs(data.gifts) do
    --     if v.num == 0 then
    --         table.insert(nodata,v)
    --     else
    --         table.insert(hasdata,v)
    --     end
    -- end

    -- local function sortfun(a,b )
    --     return a.cid <b.cid
    -- end
    -- table.sort(hasdata,sortfun)

    -- table.sort(nodata,sortfun)

    -- self.giftsData = {}

    -- for i,v in ipairs(hasdata) do
    --     table.insert(self.giftsData,v)
    -- end
    -- for i,v in ipairs(nodata) do
    --     table.insert(self.giftsData,v)
    -- end

    -- printT(hasdata)
    -- print("giftsdata===")
    -- printT(self.giftsData)
    local showcid = data.favorite.cid

    for i,v in ipairs(self.listdata) do
        if v.cid == self.favoriteData.cid and v.ison > 0 then
            self.rootItems.onTeamMark:setVisible(true)
            break
        else
            self.rootItems.onTeamMark:setVisible(false)
        end
    end
    for i,v in ipairs(self.listdata) do
        if v.cid == self.favoriteData.cid then
            v.level = self.favoriteData.level
            self.favoriteData.ison = v.ison
            self.favoriteData.hascid = v.hascid or 0
            if v.hascid and v.hascid > 0 then
                showcid = v.hascid
            end
        end
    end

    if gamedata.config.general[tostring(showcid)] and gamedata.config.general[tostring(showcid)]["quality"] and gamedata.config.general[tostring(showcid)]["quality"] >= 7 then
        ui.setLabelString(self.rootItems.generalNameLabel,gamedata.config.general[tostring(showcid)]["name"],213)
    else
        ui.setLabelString(self.rootItems.generalNameLabel,gamedata.config.general[tostring(showcid)]["name"],(gamedata.config.general[tostring(showcid)] and gamedata.config.general[tostring(showcid)]["quality"])*2-1)
    end

    ui.setLabelString(self.rootItems.generalLevelLabel, data.favorite.level,26)

    -- 加成属性列表属性（配置表获取
    self.favoritegeneralconfig = {}
    local favoritegeneralconfig = gamedata.config.favorable[tostring(data.favorite.cid)]
    for i=1,favoritegeneralconfig.level do
        if favoritegeneralconfig[tostring("att"..i)] and favoritegeneralconfig[tostring("att"..i)] ~= "" then
            table.insert(self.favoritegeneralconfig,favoritegeneralconfig[tostring("att"..i)])
        else
            break
        end
    end


    -- self.rootItems["partical"]:setPosition(-494,0)

    -- 达到最大等级时设置
    print("reload next==")
    -- if self.item1 then
    --     self.item1:stopAllActions()
    -- end
    -- if self.item2 then
    --     self.item2:stopAllActions()
    -- end
    -- if self.item3 then
    --     self.item3:stopAllActions()
    -- end
    if self.rootFavorNode then
        print("rootFavorNode.stopAllActions")
        self.rootFavorNode:stopAllActions()
    end
    
    
    if tonumber(self.favoriteData.level) >= tonumber(favoritegeneralconfig.level) then
        ui.setLabelString(self.rootItems.exppercentLabel, "100%",26)
        
        ui.setLabelString(self.rootItems.expLabel, "Max",13)
        -- ui.setSpriteTextureRect2(self.rootItems.expbar,0,0,988,32)


        local greento = CCProgressFromTo:create(0.2,self.firstnum,100)
        self.rootItems.expbarprogress:runAction(greento)

        local effectMoveto = CCMoveTo:create(0.2, ccp(494,0))
        self.rootItems["partical"]:runAction(effectMoveto)

        print("action.max==")

        self.rootItems.expdescText:setVisible(false)
        self.rootItems.exppercentLabel:setVisible(false)
    else
        
        self.rootItems.expdescText:setVisible(true)
        self.rootItems.exppercentLabel:setVisible(true)

        local favoritelevelconfig = gamedata.config.favorable_level[tostring(self.favoriteData.level+1)]
        local generalsconfig = gamedata.config.general[tostring(self.favoriteData.cid)]
        local baojifirst = favoritelevelconfig["probability"..generalsconfig["quality"]]
        -- print("baojifirst==",baojifirst)
        -- print("exp==",favoritelevelconfig["exp"..generalsconfig["quality"]])

        -- 经验条
        ui.setLabelString(self.rootItems.expLabel, data.favorite.exp.."/"..favoritelevelconfig["exp"..generalsconfig["quality"]],13)
        -- ui.setSpriteTextureRect2(self.rootItems.expbar,0,0,988 * data.favorite.exp / favoritelevelconfig["exp"..generalsconfig["quality"]],32)
        if self.levelchangeNum ~= 0 then
            self.firstnum = 0
            self.rootItems["partical"]:setPosition(-494,0)

            -- 请求成就系统信息 用于设置红点
            UIRequest({type = 3673})
        end



        local processNum = 100*(data.favorite.exp < favoritelevelconfig["exp"..generalsconfig["quality"]] and data.favorite.exp/favoritelevelconfig["exp"..generalsconfig["quality"]] or 1)
        local greento = CCProgressFromTo:create(0.2,self.firstnum,processNum)
        self.rootItems.expbarprogress:runAction(greento)
        self.firstnum = processNum

        local beiNum = data.favorite.exp/favoritelevelconfig["exp"..generalsconfig["quality"]]
        local baojinNum = baojifirst + favoritelevelconfig["critical_level"..generalsconfig["quality"]]*math.floor(beiNum*10)

        print("beiNum==",beiNum)
        -- print("baojinNum==",baojinNum)

        -- 进度条顶端特效
        print("moveTo==",988*data.favorite.exp/favoritelevelconfig["exp"..generalsconfig["quality"]],data.favorite.exp,favoritelevelconfig["exp"..generalsconfig["quality"]])
        local effectMoveto = CCMoveTo:create(0.2, ccp((data.favorite.exp < favoritelevelconfig["exp"..generalsconfig["quality"]] and 988*data.favorite.exp/favoritelevelconfig["exp"..generalsconfig["quality"]]-494 or 494),0))
        self.rootItems["partical"]:runAction(effectMoveto)

        ui.setLabelString(self.rootItems.exppercentLabel, (baojinNum*100).."%",26)
    end
    

    -- local next_level = 1
    -- prob = next_level_config["probability"+squality] + favorite_general.exp/next_level_config["percentage"+squality]*next_level_config["critical_level"+squality]

    
    

    -- print("att====")
    -- printT(self.favoritegeneralconfig)
    

    
    -- print("reloadData===")
    -- printT(self.giftsData)

    if self.giftsTableView then
        self.giftsTableView:reloadData()
    else
        self:giftsCreateList()
    end


    if self.favoriteTableView then
        self.favoriteTableView:reloadData()
    else
        self:favoriteCreateList()
    end
    if self.favoriteData.level == 0 then
        self.favoriteTableView:setLuaContentOffset(0, self.rootItems.favoriteNode:getContentSize().height - (table.getTableLength(self.favoritegeneralconfig)-self.favoriteData.level)*75)
    else
        self.favoriteTableView:setLuaContentOffset(0, self.rootItems.favoriteNode:getContentSize().height - (table.getTableLength(self.favoritegeneralconfig)-self.favoriteData.level+1)*75)
    end






    
    -- 一键添加
    self.rootItems.onekeyBtn:setTouchPriority(-101)
    self.rootItems.onekeyBtn:addHandleOfControlEvent(function()
        -- print("i...onekeyBtn:")
        if self.favoriteData.ison == -1 then
            runGamePrompt({msg = "伙伴已消失，不能赠送礼物了。"})
            return
        end

        local addnum = 0

        local props = {}

        if self.favoriteData.level >= favoritegeneralconfig["level"] then
            
            runGamePrompt({msg = "他已经对你足够死心塌地了！"})
            return
        else
            if data.favorite.generallevel < gamedata.config.favorable_level[tostring(self.favoriteData.level+1)].general_lv then
                runGamePrompt({msg = "该伙伴等级需达到"..gamedata.config.favorable_level[tostring(self.favoriteData.level+1)].general_lv.."才能升级好感度"})
                return
            end
        end


        local giftnum = 0
        for k,v in pairs(self.giftsData) do
            if v.num ~= 0 then
                giftnum = giftnum + v.num
                if giftnum < 50 then
                    table.insert(props, {cid=v["cid"],num=v["num"] })
                elseif giftnum == 50 then
                    table.insert(props, {cid=v["cid"],num=v["num"] })
                    break
                else
                    table.insert(props, {cid=v["cid"],num= 50-(giftnum - v["num"]) })
                    break
                end
            end
        end

        if giftnum == 0 then
            runGamePrompt({msg = "礼物数量为0，无法赠送"})
            return
        end
        -- print("giftnum-==",giftnum)
        -- printT(props)
        
        
        
        gameWindows:openWindow("favoriteList",{props= props, cid = self.favoriteData.cid, index = "tishi"})
    end, CCControlEventTouchUpInside)


    if self.favoriteData.level >= favoritegeneralconfig["level"] then
        ui.addGray("CCControlButton",self.rootItems.onekeyBtn)

    else
        if data.favorite.generallevel < gamedata.config.favorable_level[tostring(self.favoriteData.level+1)].general_lv then
            ui.addGray("CCControlButton",self.rootItems.onekeyBtn)
        else
            ui.removeGray("CCControlButton",self.rootItems.onekeyBtn)
        end
    end

    if (not touchLayerSet) then
        self:touchLayerSet()
    end
end

function favoritegeneral.touchLayerSet(self)
    
    self.standdata = {[1]=0,[2]=0,[3]=0 }
    self.showstanddata = {[1]=0,[2]=0,[3]=0}

    for i,v in ipairs(self.listdata) do
        
        if tonumber(self.favoriteData.cid) == tonumber(v.cid) then
            if self.listdata[i-1] then
                self.standdata[1] = self.listdata[i-1].cid
                self.showstanddata[1] = self.listdata[i-1].hascid
            end

            self.standdata[2] = v.cid
            self.showstanddata[2] = v.hascid

            if self.listdata[i+1] then
                self.standdata[3] = self.listdata[i+1].cid
                self.showstanddata[3] = self.listdata[i+1].hascid
            end
        end
    end

    self.rootItems.markLeft:setVisible(true)
    self.rootItems.markRight:setVisible(true)
    
    if self.standdata[1] == 0 then
        self.rootItems.markLeft:setVisible(false)
    end

    if self.standdata[3] == 0 then
        self.rootItems.markRight:setVisible(false)
    end

    self.rootItems.generalNode:removeAllChildrenWithCleanup(true)
    self.stepGneral1 = nil
    self.stepGneral2 = nil
    self.stepGneral3 = nil

    --
    local generalsdata = {}
    if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
        generalsdata = table.copy(GameScene.layers["generals"].module.generalsdata)
    end   

    if self.standdata[1] ~= 0 then
        local showCid = self.showstanddata[1] > 0 and self.showstanddata[1] or self.standdata[1]
        local config = gamedata.config.general[tostring(showCid)]
        local generalName = gamedata.config.generalanimation[tostring(config.animationid)].name
        if config.fashion_id == 0 then --非时装
            for k,v in pairs(generalsdata) do
                if showCid == v.cid then
                    if v.illusionGeneralCid == nil then
                        generalName = ui.getGeneralAnimationid(generalName, v)
                    end
                    break
                end
            end
        end
        self.stepGneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self.stepGneral1:setAnimation("stand",true,0)
        self.stepGneral1:setScale(2)
        self.stepGneral1:setPosition(-1200,0)
        self.rootItems.generalNode:addChild(self.stepGneral1)

        ui.removeGray("CCNode",self.stepGneral1)
        for i,v in ipairs(self.listdata) do
            if v.cid == self.standdata[1] and (v.ison == -1) then
                ui.addGray("CCNode",self.stepGneral1)
                break
            end
        end
    end

    
    if self.standdata[2] ~= 0 then
        local showCid = self.showstanddata[2] > 0 and self.showstanddata[2] or self.standdata[2]
        local config = gamedata.config.general[tostring(showCid)]
        local generalName = gamedata.config.generalanimation[tostring(config.animationid)].name
        if config.fashion_id == 0 then --非时装
            for k,v in pairs(generalsdata) do
                if showCid == v.cid then
                    if v.illusionGeneralCid == nil then
                        generalName = ui.getGeneralAnimationid(generalName, v)
                    end
                    break
                end
            end
        end
        self.stepGneral2 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self.stepGneral2:setAnimation("stand",true,0)
        self.stepGneral2:setScale(2)
        self.stepGneral2:setPosition(0,0)
        self.rootItems.generalNode:addChild(self.stepGneral2)

        ui.removeGray("CCNode",self.stepGneral2)
        for i,v in ipairs(self.listdata) do
            if v.cid == self.standdata[2] and (v.ison == -1) then
                ui.addGray("CCNode",self.stepGneral2)
                break
            end
        end
    end
    

    if self.standdata[3] ~= 0 then
        local showCid = self.showstanddata[3] > 0 and self.showstanddata[3] or self.standdata[3]
        local config = gamedata.config.general[tostring(showCid)]
        local generalName = gamedata.config.generalanimation[tostring(config.animationid)].name
        if config.fashion_id == 0 then --非时装
            for k,v in pairs(generalsdata) do
                if showCid == v.cid then
                    if v.illusionGeneralCid == nil then
                        generalName = ui.getGeneralAnimationid(generalName, v)
                    end
                    break
                end
            end
        end
        self.stepGneral3 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self.stepGneral3:setAnimation("stand",true,0)
        self.stepGneral3:setScale(2)
        self.stepGneral3:setPosition(720,0)
        self.rootItems.generalNode:addChild(self.stepGneral3)

        ui.removeGray("CCNode",self.stepGneral3)
        for i,v in ipairs(self.listdata) do
            if v.cid == self.standdata[3] and (v.ison == -1) then
                ui.addGray("CCNode",self.stepGneral3)
                break
            end
        end
    end
    


    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            self.item1 = nil
            self.item2 = nil
            self.item3 = nil
            self.x1,self.y1 = 0,0
            self.x2,self.y2 = 0,0
            self.x3,self.y3 = 0,0

            if self.stepGneral1 then
                self.item1 = tolua.cast(self.stepGneral1,"CCNode")
                self.x1,self.y1 = self.item1:getPosition()
            end

            if self.stepGneral2 then
                self.item2 = tolua.cast(self.stepGneral2,"CCNode")
                self.x2,self.y2 = self.item2:getPosition()
            end
            
            if self.stepGneral3 then
                self.item3 = tolua.cast(self.stepGneral3,"CCNode")
                self.x3,self.y3 = self.item3:getPosition()
            end
            
            return true
        end
    end

    local function ccTouchMoved(x, y)
        -- print("moved,x,y==",x,y)
        local distanceX = x-self.touchX
        -- print("setPosition===",x,y)
        if self.item1 then
            -- print("self.item1.moved")
            self.item1:setPositionX(self.x1+distanceX)
        end
        if self.item2 then
            -- print("self.item2.moved")
            self.item2:setPositionX(self.x2+distanceX)
        end
        if self.item3 then
            -- print("self.item3.moved")
            self.item3:setPositionX(self.x3+distanceX)
        end

        
    end

    local function ccTouchEnded(x, y)
        if x-self.touchX > 20 then
            gameTouch:clickprofbytime(0.5)

            self:setActionRightreload()

        elseif self.touchX-x > 20 then
            gameTouch:clickprofbytime(0.5)
            self:setActionLeftreload()
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
        self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -101, false)
        self.rootItems.touchLayer:setTouchPriority(-101)
        self.rootItems.touchLayer:setTouchEnabled(true)
    end

end


function favoritegeneral.setActionRightreload(self)
    -- -1200
    -- 720

    if self.item1 then
        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item1:runAction(backOut)
        -- self.item1:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
            UIRequest({type = 3670,cid = self.standdata[1]})
        -- end)))
        
    else
        -- local moveTo = CCMoveTo:create(0.5, ccp(-1200, 0))
        -- local backOut = CCEaseExponentialOut:create(moveTo)
        -- self.item1:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(720, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item3:runAction(backOut)

        return
    end
    if self.item2 then
        local moveTo = CCMoveTo:create(0.5, ccp(720, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
    end
end

function favoritegeneral.setActionLeftreload(self)
    if self.item3 then
        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item3:runAction(backOut)
        -- self.item3:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
            UIRequest({type = 3670,cid = self.standdata[3]})
        -- end)))
    else
        local moveTo = CCMoveTo:create(0.5, ccp(-1200, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item1:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)

        -- local moveTo = CCMoveTo:create(0.5, ccp(720, 0))
        -- local backOut = CCEaseExponentialOut:create(moveTo)
        -- self.item3:runAction(backOut)

        return
    end

    if self.item2 then
        local moveTo = CCMoveTo:create(0.5, ccp(-1200, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
    end

end


function favoritegeneral.clear(self)

    self.rootFavorNode:removeAllChildrenWithCleanup(true)
    self.rootFavorNode:removeFromParentAndCleanup(true)
    self.rootFavorNode = nil
    self.rootItems = nil

    self.giftsTableView = nil
    self.favoriteTableView = nil

    self.stepGneral2 = nil

    self.favoriteData = {}
    self.giftsData = {}
    self.data = {}

    self.favoritegeneralconfig = {}
    self.levelchangeNum = 0
    self.listdata = {}

    self.giftsIndex = nil
    self.giftsIndexPos = {x = 0,y = 0}
end

return favoritegeneral