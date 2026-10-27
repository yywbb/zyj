--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-21
-- Time: 上午10:13
-- To change this template use File | Settings | File Templates.
--

local rob = {

    resource = nil,
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"treasure","horse",}, --"meterial"} ,
    -- pagename = {"典籍抢夺","坐骑抢夺","魂魄抢夺"},
    pagename = {gameConfig.strings:string_common("rob",0),gameConfig.strings:string_common("rob",1),}, --gameConfig.strings:string_common("rob",2)},
    selectpage = "treasure",

--    generalpageconfig = {"all","star5","star4","star3"} ,
--    generalselectpage = "all",

    treasureData = {},
    horseData ={},
    meterialData = {},

--    generalData ={},
--    generalshowData = {},

    presentPage_treasure = 1,
    presentPage_horse = 1,
    presentPage_meterial = 1,

--    presentPage_general = 1,

    listView = nil,
    listdata = {},

    data = {},
    presentPage = 1,
    createdpage={},

    isContentScroll = false,

    selectid = nil,

    titleCellSize = {x=180,y=180},


    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {25},
                title2 = {24},
            },
        },
    },
    amuletID = 20128,--护符id

    isautoXH = false,

    losscid = {},
    currentpage = 0,

    isOpenOneKeyRob =  false,--是否开启一键抢夺 
    kv_rolelv = 1,
    kv_rolevip = 1,

}
function rob.shiftPage(self,type)

    self["presentPage_"..self.selectpage] = self.presentPage
    self.selectpage = type
    self.presentPage =  self["presentPage_"..self.selectpage]

--    if type =="general" then
--        self.rootItems.generaltop:setPosition(0,0)
--        self.rootItems.generaltop:setVisible(true)
--        self.rootItems.equiptop:setPosition(0,9999)
--        self.rootItems.equiptop:setVisible(false)
--        if not GameScene:checkUpdate(11112) then
--            self:shiftGeneralPage(self.generalselectpage)
--        end
--    elseif type =="treasure" or type =="horse" then
--
--        self.rootItems.generaltop:setPosition(0,9999)
--        self.rootItems.generaltop:setVisible(false)
--        self.rootItems.equiptop:setPosition(0,0)
--        self.rootItems.equiptop:setVisible(true)

        self.listdata = self[type.."Data"]
        if not self.listView then
            self:createList()
        else
            --self.listView:setLuaContentOffset(0, self.rootItems.listFragment:getContentSize().height - table.getTableLength(self.fragmentShowData)*self.CellSize.y)
            self.listView:reloadData()
        end

        if not GameScene:checkUpdate(11111) then
            self:reloaddata()
        end
--    end
end

--function rob.shiftGeneralPage(self,type)
--
--    if self.generalselectpage ~= type then
--        self.presentPage_general = 1
--        self.presentPage = 1
--    end
--
--    self.generalselectpage = type
--    self.generalData =  self["generalshowData"][type]
--
--    self:reloaddata()
--
--    for k,v in ipairs(self.generalpageconfig) do
--        if v == type then
--            self.rootItems["general"..v.."Onbg"]:setVisible(true)
--            self.rootItems["general"..v.."Onpoint"]:setVisible(true)
--        else
--            self.rootItems["general"..v.."Onbg"]:setVisible(false)
--            self.rootItems["general"..v.."Onpoint"]:setVisible(false)
--        end
--    end
--end


function rob.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("rub/rub", nil, true, "rub")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode) 
    --printT(self.rootItems)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(-103)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    self.rootItems.toptitle:setPositionY(toppos)
    self.topposy = toppos

    if param then
        if param.cid then
            self.selectCid = param.cid
        end
        if param.page then
            self.selectpage = param.page
        end
    end


    self.rootItems.touchLayer:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-150-gameConfig.labelnodeheight))

--    for k,v in ipairs(self.generalpageconfig) do
--        self.rootItems["general"..v.."Button"]:setTouchPriority(-103)
--        self.rootItems["general"..v.."Button"]:addHandleOfControlEvent(function()
--            self:shiftGeneralPage(v)
--        end, CCControlEventTouchUpInside)
--    end

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

        if math.abs(x - self.touchX) > 20 then
            local offsetX = self.contentoffsetx + (x - self.touchX)
            self.rootItems.pagenode:setPositionX(offsetX)
        end
    end

    local function ccTouchEnded(x, y)
        if self.touchX - x > 20 then
            if self.presentPage+1 <=table.getTableLength(self.data) then
                self:setPage(self.presentPage+1)
            else
                self:setPage(self.presentPage)
            end
        elseif self.touchX - x < -20 then
            if self.presentPage-1 >0 then
                self:setPage(self.presentPage-1)
            else
                self:setPage(self.presentPage)
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


    self.rootItems.mianzhan:setTouchPriority(-103)
    self.rootItems.mianzhan:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        if self.propnum and self.propnum >0 then
            gameWindows:openWindow("robaddCD",nil,nil)
        else
            -- runGamePrompt({msg = "护符不足"})
            -- runGamePrompt({msg = gameConfig.strings:string_common("rob",3)})
            ui.setPopwindowByCid(self.amuletID)
        end
    end, CCControlEventTouchUpInside)

    if self.rootItems.rubShopButton then
        self.rootItems.rubShopButton:setTouchPriority(-103)
        self.rootItems.rubShopButton:addHandleOfControlEvent(function()
            if self.isContentScroll then return end
            GameScene:shiftLayerById(136)
        end, CCControlEventTouchUpInside)
    end

    local robnum = gamedata.config.loot["2"] and gamedata.config.loot["2"].rob or 0
    self.rootItems.rubShopButton:setVisible(robnum > 0)

    local rolelv = GameScene.roleinfo.level or 1
    local rolevip = GameScene.roleinfo.vip or 1
    local globalconfig = gamedata.config.global_kv
    self.kv_rolelv = globalconfig.artifact_fast_level.value or 1
    self.kv_rolevip = globalconfig.artifact_fast_vip.value or 1
    print("rolelv:"..rolelv.." rolevip:"..rolevip)
     print("kv rolelv:"..self.kv_rolelv.." rolevip:"..self.kv_rolevip)
    if tonumber(self.kv_rolelv) <= tonumber(rolelv) or tonumber(self.kv_rolevip) <= tonumber(rolevip) then
        self.isOpenOneKeyRob = true
    end    


    self:shiftPage(self.selectpage)

    UIRequest({type = 1112})
    UIRequest({type = 12001, order = 11121, cids = {20128}})

    guide.controller:addComplete(25,function()
        UIRequest({type = 2882,opt=1,sysID=25})
    end)
end

function rob.setPropNum(self,data)
    self.propnum = data["20128"] or 0
    ui.setLabelString(self.rootItems.propnum,"x"..self.propnum, 14)

    ui.setMobileShopShow(self.rootItems.mobieshop,-102,4,self.propnum <= 0)

end

function rob.setCD(self)
    if gameTimer.times["robprofCD"] and gameTimer.times["robprofCD"] > 0 then
        gameTimer:rigistTimeFunc("robprofCD",function()
            if gameTimer.times["robprofCD"] ==0 then
                -- ui.setLabelString(self.rootItems.cd,"当前未受保护！！",26)
                ui.setLabelString(self.rootItems.cd,gameConfig.strings:string_common("rob",4),26)
            else
                ui.setLabelString(self.rootItems.cd,ui.makeTimeDes(gameTimer.times["robprofCD"]),26)
            end
        end)
    else
        -- ui.setLabelString(self.rootItems.cd,"当前未受保护！！",26)
        ui.setLabelString(self.rootItems.cd,gameConfig.strings:string_common("rob",4),26)
    end
end

function rob.clear(self)
    self.createdpage = {}

--    self.treasureData = {}
--    self.horseData ={}
--    self.generalData ={}
    gameTimer:UnrigistTimeFunc("robprofCD")
    self.selectCid = nil
    self.selectpage = "treasure"
    self.presentPage = 1
    self.presentPage_treasure = 1
    self.presentPage_horse = 1
    self.presentPage_meterial = 1
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.listView = nil
    self.isOpenOneKeyRob = false
end

function rob.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_IconLv.ccbi", nil, true, "new_IconLv")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                cellCCB:setScale(0.89)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ccbDocumentControler.selectEffect:removeAllChildrenWithCleanup(true)

            ui.setIconLv(ccbDocumentControler,{cid = self.listdata[tostring(a1+1)].cid})
            ui.sethint(ccbDocumentControler["il_hint"],self.listdata[tostring(a1+1)].enough and self.listdata[tostring(a1+1)].enough ==1)

            if a1+1 == self.presentPage then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                ccbDocumentControler.selectEffect:addChild(eccb)
            end

            cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.listdata)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            self:setPage(a1:getIdx()+1)
            self.listView:reloadData()
        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.listView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.listscroll:addChild(self.listView)
    self.listView:setTouchPriority(-102)
end

--function rob.setGeneralSlot(self,item,data,id)
--    local key_Ex
--    if id == nil or id == 0 then
--        key_Ex = ""
--    else
--        key_Ex = "_"..id
--    end
--
--    local config = ui.IDconfig(data.cid)
--
--    item["general"..key_Ex]:removeAllChildrenWithCleanup(true)
--    local generalName = gamedata.config.generalanimation[tostring(config.animationid)].name
--    local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
--    Gneral:setAnimation("stand",true,0)
--    item["general"..key_Ex]:addChild(Gneral)
--    item["general"..key_Ex]:setScale(1.3)
--
--    ui.setLabelString(item["name"..key_Ex],config.name, config.quality and 2*config.quality-1 or 1)
--    -- ui.setLabelString(item["num"..key_Ex],"当前拥有: "..data.num, 14)
--    ui.setLabelString(item["num"..key_Ex],gameConfig.strings:colNum(data.num), 14)
--
--    item["button"..key_Ex]:addHandleOfControlEvent(function()
--        print("icon clicked")
--        if not self.isContentScroll then
--            UIRequest({type = 1018,cid = data.cid})
--            self.selectid = id+1
--        end
--    end, CCControlEventTouchUpInside)
--end
--
--function rob.setGeneralPagedata(self,item,data)
--    --print("setPagedata")
--    --printT(data)
--    for i=1,4 do
--        if data[tostring(i)] then
--            item["node"..i]:setVisible(true)
--            self:setGeneralSlot(item,data[tostring(i)],i-1)
--        else
--            item["node"..i]:setVisible(false)
--        end
--    end
--end

function rob.setEquipPageData(self,item,data)

    item["iconbutton"]:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        ui.setPopwindowByCid(data.cid)
    end, CCControlEventTouchUpInside)
    item["iconbutton"]:setTouchPriority(-135)

    local isenough = true
    print("table.getTableLength(data.fragments) = "..table.getTableLength(data.fragments))
    for ii=1, table.getTableLength(data.fragments) do
        local fragmentdata = data.fragments[tostring(ii)]
        local config = ui.IDconfig(fragmentdata.cid)
        if fragmentdata.num == 0 then
            isenough = false
        end

        item["o_num"..(ii==1 and "" or "_"..(ii-1))]:setString(fragmentdata.num)
        item["o_rub"..(ii==1 and "" or "_"..(ii-1))]:setVisible(fragmentdata.num<=0)
        ui.setNewIcon(item,{cid= fragmentdata.cid},ii-1)

        if fragmentdata.num <=0 then
            ui.addGray("CCSprite",item["i_icon"..(ii==1 and "" or "_"..(ii-1))])
            ui.addGray("CCSprite",item["i_quality"..(ii==1 and "" or "_"..(ii-1))])
            ui.addGray("CCSprite",item["i_k_quality"..(ii==1 and "" or "_"..(ii-1))])
            ui.addGray("CCSprite",item["i_soulsprite"..(ii==1 and "" or "_"..(ii-1))])
        else
            ui.removeGray("CCSprite",item["i_icon"..(ii==1 and "" or "_"..(ii-1))])
            ui.removeGray("CCSprite",item["i_quality"..(ii==1 and "" or "_"..(ii-1))])
            ui.removeGray("CCSprite",item["i_k_quality"..(ii==1 and "" or "_"..(ii-1))])
            ui.removeGray("CCSprite",item["i_soulsprite"..(ii==1 and "" or "_"..(ii-1))])
        end
        item["partical"..ii]:setPositionType(2) --设置粒子发射模式
        item["i_button"..(ii==1 and "" or "_"..(ii-1))]:setTouchPriority(-135)
        item["i_button"..(ii==1 and "" or "_"..(ii-1))]:addHandleOfControlEvent(function()
            print("icon clicked")
            if not self.isContentScroll then
                if fragmentdata.num <= 0 then
                    local cb = function()
                        UIRequest({type = 1110,cid = fragmentdata.cid})
                    end

                    if gameTimer.times["robprofCD"] and gameTimer.times["robprofCD"] > 0 then
                        gameWindows:openWindow("confirm",{msg = "挑战会使保护时间马上结束，是否继续？"},cb)
                    else
                        cb()
                    end
                else
                    -- runGamePrompt({msg = "您已拥有该碎片，不能再抢夺！"})
                    runGamePrompt({msg = gameConfig.strings:string_common("rob",5)})
                end
            end
        end, CCControlEventTouchUpInside)
    end

    setSpriteFrameByName(item.icon,data.icon)
    ui.setLabelString(item.name,data.name, data.quality and 2*data.quality-1 or 1)

    if item["buttoneffect"] then
        item["buttoneffect"]:removeAllChildrenWithCleanup(true)
    end

    item.compond:setTouchPriority(-135)
    -- ui.setLabelString(item.buttontext,"合 成",19)
    ui.setLabelString(item.buttontext,gameConfig.strings:string_common("rob",10),19)
    if not isenough then
        ui.addGray("CCControlButton",item.compond)
        ui.addGray("CCLabelTTF",item.buttontext)
        if not self.isOpenOneKeyRob  then
            ui.addGray("CCControlButton",item.tiaozhanBut)
        else
            ui.removeGray("CCControlButton",item.tiaozhanBut)
        end    

        item.compond:addHandleOfControlEvent(function()
            if not self.isContentScroll then
                gameTouch:clickprofbytime(0.3)
                --runGamePrompt({msg = "碎片不足！"})
                runGamePrompt({msg = gameConfig.strings:string_common("rob",7)})
            end
        end, CCControlEventTouchUpInside)

        item.tiaozhanBut:setTouchPriority(-135)
        item.tiaozhanBut:addHandleOfControlEvent(function()

            if not self.isOpenOneKeyRob  then
                runGamePrompt({ msg = "战队等级"..self.kv_rolelv.."或者VIP等级"..self.kv_rolevip.."可以使用一键挑战功能" })   
                return
            end
            --没有精力 没有选择自动消耗 没有精力丹
            if GameScene.roleinfo.energy <= 0 and not self.isautoXH then
                gameWindows:openWindow("buypower",{props = props,id = 3})
            -- elseif GameScene.roleinfo
            elseif self.isautoXH and self.energy1 and self.energy1<=0 and  self.energy2 and self.energy2<=0 then
                runGamePrompt({ msg = "没有精力丹了！" })   
            else 
                print("isautoXH------",self.isautoXH)
                local cb = function()
                    UIRequest({type = 1125, isautoxh = self.isautoXH,  losscid = self.losscid})  
                    gameWindows:openWindow("robonekeyresult",{isautoXH = self.isautoXH, losscid = self.losscid, name = self.name })
                    -- self.isautoXH = false
                end

                if gameTimer.times["robprofCD"] and gameTimer.times["robprofCD"] > 0 then
                    gameWindows:openWindow("confirm",{msg = "挑战会使保护时间马上结束，是否继续？"},cb)
                else
                    cb()
                end
                
            end    
        end,CCControlEventTouchUpInside)


    else
        ui.removeGray("CCControlButton",item.compond)
        ui.removeGray("CCLabelTTF",item.buttontext)
        ui.addGray("CCControlButton",item.tiaozhanBut)

        item.compond:addHandleOfControlEvent(function()
            if not self.isContentScroll then
                gameTouch:clickprofbytime(0.3)
                UIRequest({type = 1108,ids = {data.cid}})
            end

        end, CCControlEventTouchUpInside)

        local eccb,eitem = CCBReaderLoad("UIEffect/anniu/anniu_hecheng", nil, true, "anniu")
        item["buttoneffect"]:addChild(eccb)

        item.tiaozhanBut:setTouchPriority(-135)
        item.tiaozhanBut:addHandleOfControlEvent(function()
           runGamePrompt({ msg = "已拥有当前法宝所有碎片，不可一键挑战" })   
        end,CCControlEventTouchUpInside)

    end

    -- self.isautoxh = false
    item.doublesprite:setVisible(self.isautoXH)
    item.doublebutton:setTouchPriority(-135)
    item.doublebutton:addHandleOfControlEvent(function()
         if (self.energy1 and self.energy1>0 ) or (self.energy2 and self.energy2>0) then
             self.isautoXH = not self.isautoXH
             item.doublesprite:setVisible(self.isautoXH)
         else

            if self.isautoXH then
                self.isautoXH = false
                item.doublesprite:setVisible(self.isautoXH)
            else
                runGamePrompt({ msg = "没有精力丹了！" })
            end
            
         end   
    end,CCControlEventTouchUpInside)
end

function rob.loadPage(self,page)
    if page>0 and page <= table.getTableLength(self.data) then
        if not self.createdpage[page] then
            self.createdpage[page] = {}

--            if self.selectpage == "general" then
--                self.createdpage[page].ccb, self.createdpage[page].item = CCBReaderLoad("rub/rub_page", nil, true, "rub_page")
--                self.createdpage[page].ccb:setPosition(1080*(page-1),0)
--
--                self.createdpage[page].item.bottom:setPositionY((GameScene.topposY-1620)*0.35+60)
--                self.createdpage[page].item.top:setPositionY((GameScene.topposY-1620)*0.65+600)
--                self.rootItems.pagenode:addChild(self.createdpage[page].ccb)
--                self:setGeneralPagedata(self.createdpage[page].item,self.data[tostring(page)])
--            else
                self.createdpage[page].ccb, self.createdpage[page].item = CCBReaderLoad("rub/qiangduo_"..table.getTableLength(self.data[tostring(page)].fragments)..".ccbi", nil, true, "qiangduo_")
                self.createdpage[page].ccb:setPosition(1080*(page-0.5),(GameScene.topposY-1620)*0.5+600)
                self.rootItems.pagenode:addChild(self.createdpage[page].ccb)
--            end
        end
        if page == self.presentPage then 
            self.losscid = {}
            local data = self.data[tostring(page)]
            self.name = data.name or ""
            for ii=1, table.getTableLength(data.fragments) do
                local fragmentdata = data.fragments[tostring(ii)]
                local config = ui.IDconfig(fragmentdata.cid)
                if fragmentdata.num <=0 then
                    print("setEquipPageData cid:"..fragmentdata.cid)
                    table.insert(self.losscid,fragmentdata.cid)
                end
            end
        end    

        self:setEquipPageData(self.createdpage[page].item,self.data[tostring(page)])
       
    end
end

function rob.removepage(self,page)
   if self.createdpage[page] then
       self.createdpage[page].ccb:removeAllChildrenWithCleanup(true)
       self.createdpage[page].ccb:removeFromParentAndCleanup(true)
       self.createdpage[page] = nil
   end
end


function rob.loadpages(self)
    --ui.setPageCursor(self.cursor,self.presentPage)

    for k,v in pairs(self.createdpage) do
        if k>= self.presentPage-1 and k<= self.presentPage+1 then
        else
            self:removepage(k)
        end
    end
    self:loadPage(self.presentPage)
    self:loadPage(self.presentPage+1)
    self:loadPage(self.presentPage-1)

end

function rob.setPage(self,page)
    self.presentPage = page

--    if self.selectpage == "general" then
--        self.rootItems.pagedes:setString(self.presentPage.."/"..table.getTableLength(self.data))
--    else
--        self.rootItems.pagedes:setString("")
--    end
    if not next(self.createdpage) then
        self.rootItems.pagenode:setPosition(ccp(-1080*(self.presentPage-1), 0))
        self:loadpages()
    else
        local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.presentPage-1), 0))
        self.rootItems.pagenode:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
            self:loadpages()
        end)))
    end

    self.listView:reloadData()
    if  self.titleCellSize.x * self.presentPage >  self.rootItems.listscroll:getContentSize().width - self.listView:getLuaContentOffsetX() then
        self.listView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * self.presentPage,0),0.2)
    elseif self.titleCellSize.x * (self.presentPage-1) < -self.listView:getLuaContentOffsetX() then
        self.listView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.presentPage-1) ,0),0.2)
    end

end

function rob.reloaddata(self)
    self.data = self[self.selectpage.."Data"]
    --printT(self.data,"reloaddata")
    self.createdpage={}
    self.rootItems.pagenode:removeAllChildrenWithCleanup(true)

    if self.selectCid then
        if self.selectpage =="treasure" or self.selectpage =="horse" then
            for k,v in pairs(self.data) do
                if self.selectCid == v.cid then
                    self.presentPage = tonumber(k)
                end
            end
        else

        end
        self.selectCid = nil
    end


    if table.getTableLength(self.data) >0 then
        self:setPage(self.presentPage)
    end

end

--function rob.robGeneralSucess(self)
--    self.data[tostring(self.presentPage)][tostring(self.selectid)].num = self.data[tostring(self.presentPage)][tostring(self.selectid)].num +1
--    self:setGeneralSlot(self.createdpage[self.presentPage].item,self.data[tostring(self.presentPage)][tostring(self.selectid)],self.selectid-1)
--end

function rob.robTreasureSucess(self,reward)
    if not reward then return end
    local nowdata = self.data[tostring(self.presentPage)]
    for i=1, table.getTableLength(nowdata.fragments) do
        if nowdata.fragments[tostring(i)].cid == reward.cid then
            nowdata.fragments[tostring(i)].num = nowdata.fragments[tostring(i)].num + 1
            break
        end
    end
    self.selectCid = nowdata.cid
    self:setEquipPageData(self.createdpage[self.presentPage].item,nowdata)

    --刷新一键挑战上传参数
    self.losscid = {}
    self.name = nowdata.name or ""
    for ii=1, table.getTableLength(nowdata.fragments) do
        local fragmentdata = nowdata.fragments[tostring(ii)]
        local config = ui.IDconfig(fragmentdata.cid)
        if fragmentdata.num <=0 then
            print("setEquipPageData cid:"..fragmentdata.cid)
            table.insert(self.losscid,fragmentdata.cid)
        end
    end
end


--精力丹更新
function rob.robTreasureEnergy(self,energy1,energy2)
    if energy1 and energy2 then
        print("energy1 energy2:"..energy1.."  "..energy2)
        self.energy1 = energy1
        self.energy2 = energy2
    end   
end



function rob.robOneKeyTreasureSucess(self,reward)
    if not reward then return end
    local nowdata = self.data[tostring(self.presentPage)]
    for i=1, table.getTableLength(nowdata.fragments) do
        for k,v in pairs(reward) do
            if nowdata.fragments[tostring(i)].cid == v.cid then
                nowdata.fragments[tostring(i)].num = nowdata.fragments[tostring(i)].num + 1
            end
        end
    end
    self.selectCid = nowdata.cid
    self:setEquipPageData(self.createdpage[self.presentPage].item,nowdata)
end


function rob.setshiftPage(self)
    self:shiftPage(self.selectpage)
end

function rob.compond(self,t)
--    for i=1,5 do
--        if self.createdpage[self.presentPage].item["partical"..i]:
--    end
    gameTouch:clickprofbytime(1.5)

    local animationManager = getAnimationManager(self.createdpage[self.presentPage].item)
    if animationManager then
        animationManager:setAnimationCompletedCallback(function()
            showRewardPopupWindow(t.reward,nil,nil,true)
            UIRequest({type = 11111})
        end)
        animationManager:runAnimationsForSequenceNamed("Default Timeline")
    end
end


return rob




