--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local favoriteList = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    GeneralListTableView = nil,
    AchievementTableView = nil,

    achievementlist = {},
    isscrolltouched = false,
}


function favoriteList.open(self,touchPriority,data,callback)
    -- print("i...am...open...")
    -- print(data)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.data = data

    if data == "generallist" then
        self.rootNode, self.rootItems = CCBReaderLoad("love/love_general", nil, true, "love_general")
        
        self:generallistinit()
    elseif data == "achievement" then
        -- print("achievement===")
        self.rootNode, self.rootItems = CCBReaderLoad("love/love_chengjiu", nil, true, "love_chengjiu")
        
        self:achievementinit()
    else
        self.rootNode, self.rootItems = CCBReaderLoad("love/love_tishi", nil, true, "love_tishi")
        self:tishiinit()
    end

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","favoriteList",touchbegin)
    local function touchend(pos)
        if self.rootItems.listscroll and ui.isTouched(self.rootItems.listscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","favoriteList",touchend)

    self.root:addChild(self.rootNode)
    return self.root
end

function favoriteList.generallistinit(self)
    -- print("i...am...generallistinit...")


    ui.setLabelString(self.rootItems.decText, nil, 21)
    ui.setLabelString(self.rootItems.favoriteAllLabel, nil, 26)

    ui.setLabelString(self.rootItems.exchangeText, nil, 19)
    self.rootItems.exchangeBtn:addHandleOfControlEvent(function()
        gameWindows:openWindow("favoritetransfer",{listdata = self.generalist})
    end, CCControlEventTouchUpInside)
    self.rootItems.exchangeBtn:setSwallowsTouch(true)
    self.rootItems.exchangeBtn:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.backText, nil, 19)
    self.rootItems.backBtn:addHandleOfControlEvent(function()

        gameWindows:closeWindow("favoriteList")
    end, CCControlEventTouchUpInside)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(self.touchPriority)

    UIRequest({type = 3671})

    -- self:generallistReload()
end

function favoriteList.achievementinit(self)
    -- print("i...am...achievementinit...")

    ui.setLabelString(self.rootItems.backText, nil, 19)
    self.rootItems.backBtn:addHandleOfControlEvent(function()

        gameWindows:closeWindow("favoriteList")
    end, CCControlEventTouchUpInside)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(self.touchPriority)

    UIRequest({type = 3673})
end


function favoriteList.tishiinit(self)
    -- print("i...am...achievementinit...")

    ui.setLabelString(self.rootItems.noLab, nil, 19)
    self.rootItems.noButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("favoriteList")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    
    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("favoriteList")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.yesLab, nil, 19)
    self.rootItems.yesButton:addHandleOfControlEvent(function()

        -- gameWindows:closeWindow("favoriteList")
        gameWindows:closeWindowDirect("favoriteList")

        UIRequest({type = 3672, cid = self.data.cid, props=self.data.props})
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

end

function favoriteList.listdataReload(self,data)
    self.generalist = {}
    for k,v in pairs(data) do
        if v.ison then
            table.insert(self.generalist, v)
        end
        
    end
    local generalconfig = gamedata.config.general
    local sortFunc = function( a,b )
        if a.ison > b.ison then
            return true
        elseif a.ison < b.ison then
            return false
        else
            return generalconfig[tostring(a.hascid > 0 and a.hascid or a.cid)]["quality"] > generalconfig[tostring(b.hascid > 0 and b.hascid or b.cid)]["quality"]
        end
    end
    table.sort(self.generalist,sortFunc)
    self:generallistReload()
end

function favoriteList.generallistReload(self)
    -- print("i...am...generallistReload...")

    local allfavoritenum = 0
    for k,v in pairs(self.generalist) do
        allfavoritenum = allfavoritenum + v.level
    end

    ui.setLabelString(self.rootItems.favoriteAllLabel, allfavoritenum, 26)

    if self.GeneralListTableView == nil then
        self:createGeneralList()
    else
        self.GeneralListTableView:reloadData()
    end
end



function favoriteList.achievementReload(self,data)
    -- print("i...am...achievementReload")
    -- printT(data)
    --if data == nil then return end
    -- printT(gamedata.config.favorable_task)

    -- self.achievementconfig = {}
    -- for k,v in pairs(gamedata.config.favorable_task) do
    --     table.insert(self.achievementconfig,v)
    -- end
    -- local sortById = function(a,b) return a.id < b.id end
    -- table.sort(self.achievementconfig, sortById)

    if self.data ~= "achievement" then return end

    self.achievementlist = {}
    local hasdata = {}
    local nodata = {}
    for k,v in pairs(data) do
        -- print(k,v)
        if v.status ~= 2 then
            table.insert(hasdata,v)
        else
            table.insert(nodata,v)
        end
    end
    local sortFunc = function(a,b) 
        if a.status > b.status then
            return true
        elseif a.status < b.status then
            return false
        else
            -- print("a...b...=",a.cid,b.cid)
            if (tonumber(a.cid) or 2000) < (b.cid or 2000) then
                -- print("return true")
                return true
            elseif (a.cid or 2000) > (b.cid or 2000) then
                -- print("return false")
                return false
            end
        end
    end
    table.sort(hasdata, sortFunc)

    local sortnoFunc = function( a,b )
        return a.cid < b.cid
    end

    table.sort(nodata, sortnoFunc)


    -- printT(hasdata)
    -- print("hasdata===")
    -- printT(nodata)

    for i,v in ipairs(hasdata) do
        table.insert(self.achievementlist,v)
    end
    for i,v in ipairs(nodata) do
        table.insert(self.achievementlist,v)
    end


    -- printT(self.achievementconfig)
    -- print("self.achievementconfig===")
    -- printT(self.achievementlist)

    if self.AchievementTableView == nil then
        self:createAchievementList()
    else
        self.AchievementTableView:reloadData()
    end

end

function favoriteList.setGeneralsIcon(self,ccb,num)

    -- print("setGeneralsIcon===")
    -- printT(ccb)

    --
    local generalsdata = {}
    if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
        generalsdata = table.copy(GameScene.layers["generals"].module.generalsdata)
    end 

    for i=1,5 do
        local key_Ex
        if i == nil or i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end

        if self.generalist[(num-1)*5+i] and next(self.generalist[(num-1)*5+i]) then
            ccb["generalccb"..i]:setVisible(true)
            -- 设置头像
            local generalData = self.generalist[(num-1)*5+i]
            local showCid = generalData.hascid > 0 and generalData.hascid or generalData.cid
            local configGeneral = gamedata.config.general[tostring(showCid)]
            local gicon = configGeneral.icon
            if configGeneral.fashion_id == 0 then --非时装
                for k,v in pairs(generalsdata) do
                    if showCid == v.cid then
                        if v.illusionGeneralCid == nil then
                            local gdata = ui.getConfigGeneral(v)
                            gicon = gdata.icon
                        end
                        break
                    end
                end
            end
            ui.setNewIconName(ccb,{cid = showCid, icon = gicon},i-1)

            ccb["isSelect"..key_Ex]:setVisible(false)
            
            if self.generalist[(num-1)*5+i].ison == -1 then
                ui.addGray("CCSprite",ccb["in_icon"..key_Ex])
            else
                ui.removeGray("CCSprite",ccb["in_icon"..key_Ex])
            end
            

            ccb["i_button"..key_Ex]:addHandleOfControlEvent(function()
                -- print("itemgeneral...i_button")
                -- print("itemgeneral.cid===",self.generalist[(num-1)*5+i]["cid"])
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                UIRequest({type = 3670,cid = self.generalist[(num-1)*5+i]["cid"]})
                gameWindows:closeWindow("favoriteList")
                -- ui.setPopwindowByCid(gooddata[1].cid)
            end, CCControlEventTouchUpInside)
            ccb["i_button"..key_Ex]:setTouchPriority(self.touchPriority)
            -- print("test00000000",self.generalist[(num-1)*5+i]["level"])
            -- printT(self.generalist[(num-1)*5+i])
            -- print("key_Ex==",key_Ex)
            if ccb["favoriteNum"..key_Ex] then
                -- print("favoriteNum..is..true")
            end
            ui.setLabelString(ccb["favoriteNum"..key_Ex], self.generalist[(num-1)*5+i]["level"], 22)
            -- print("test111111111")
            if self.generalist[(num-1)*5+i]["ison"] == 2 then
                -- print("visible==true")
                ccb["onteamNode"..key_Ex]:setVisible(true)
                ccb["onteamLab"..key_Ex]:setString("已上阵")
            elseif self.generalist[(num-1)*5+i]["ison"] == 1 then
                -- print("visible==true")
                ccb["onteamNode"..key_Ex]:setVisible(true)
                ccb["onteamLab"..key_Ex]:setString("已上阵")
            else
                ccb["onteamNode"..key_Ex]:setVisible(false)
            end
            -- print("test222222222")
        else
            ccb["generalccb"..i]:setVisible(false)
        end
    end

end

function favoriteList.createGeneralList(self)
    local celldict = {}
    local taskListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(900, 300)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("love/cell_love_general_5.ccbi", nil, true, "cell_love_general_5")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setGeneralsIcon(ccbDocumentControler,a1+1)
            -- local celldata = self.data[tostring(a1+1)]

            

            -- ui.setNewIcon(ccbDocumentControler,{cid = prop[1].cid})

            -- ui.setLabelString(ccbDocumentControler.buttontext,"领 取",18)
           
            -- ui.addGray("CCControlButton",ccbDocumentControler.button)
            -- ui.addGray("CCLabelTTF",ccbDocumentControler.buttontext)
            -- ccbDocumentControler.button:addHandleOfControlEvent(function()
            --     if gameTouch.isScrollling then return end
            --     -- runGamePrompt({msg = "未达成"})
            --     runGamePrompt({msg = gameConfig.strings:string_common("penglaiReward",11)})
            -- end, CCControlEventTouchUpInside)

            cellCCB:setScale(0.94)
            cellCCB:setPosition(900/2, 300/2)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.generalist)/5)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.GeneralListTableView = ui.createLuaTableView({
        handle = taskListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.GeneralListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listscroll:addChild(self.GeneralListTableView)
end


function favoriteList.createAchievementList(self)
    local celldict = {}
    local totalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(900, 190)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("love/cell_lovechengjiu.ccbi", nil, true, "cell_lovechengjiu")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end


            -- print("achievementlist:=",a1+1)
            local cellconfig = self.achievementlist[a1+1]
            local celldata = gamedata.config.favorable_task[tostring(cellconfig.cid)]
            
            

            ccbDocumentControler.name:setString(celldata.name or "")
            ccbDocumentControler.desc:setString((celldata.favorable or "").." 好感度")
            ccbDocumentControler.reward:setString(celldata.txt or "")

            local prop = ui.getIDandNUMs(celldata.task)
            if prop and prop[1] then
                ui.setNewIcon(ccbDocumentControler,prop[1],0)
            end
            local iconP = celldata.icon
            -- print("iconP==",iconP)
            setSpriteFrameByName(ccbDocumentControler.i_icon, iconP)

            ccbDocumentControler.i_soulsprite:setVisible(false)

            ui.removeGray("CCControlButton",ccbDocumentControler.doButton)
            ui.removeGray("CCLabelTTF",ccbDocumentControler.doLab)

            if self.achievementlist[tonumber(a1+1)]["status"] == 0 then

                ui.addGray("CCControlButton",ccbDocumentControler.doButton)
                ui.addGray("CCLabelTTF",ccbDocumentControler.doLab)

                ccbDocumentControler.finishnode:setVisible(false)
                ui.setLabelString(ccbDocumentControler.doLab, "未达成", 19)
            elseif self.achievementlist[tonumber(a1+1)]["status"] == 1 then
                ui.setLabelString(ccbDocumentControler.doLab, "领 取", 19)
                ccbDocumentControler.finishnode:setVisible(false)
            elseif self.achievementlist[tonumber(a1+1)]["status"] == 2 then
                ui.setLabelString(ccbDocumentControler.doLab, "领 取", 19)
                ccbDocumentControler.finishnode:setVisible(true)
            end


            ccbDocumentControler.doButton:setTouchPriority(self.touchPriority)
            ccbDocumentControler.doButton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                -- print("doButton===is")
                if self.achievementlist[tonumber(a1+1)]["status"] == 0 then
                    runGamePrompt({msg = "成就未达成，不能领取"})

                elseif self.achievementlist[tonumber(a1+1)]["status"] == 1 then
                    -- runGamePrompt({msg = "成就已达成，可以领取"})

                    UIRequest({type = 3674, cid = self.achievementlist[tonumber(a1+1)]["cid"], text = celldata.txt})

                elseif self.achievementlist[tonumber(a1+1)]["status"] == 2 then
                    -- runGamePrompt({msg = "成就已完成"})
                end
            end, CCControlEventTouchUpInside)

            
            cellCCB:setScale(0.93)
            cellCCB:setPosition(900/2, 190/2)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.achievementlist)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.AchievementTableView = ui.createLuaTableView({
        handle = totalListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.AchievementTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listscroll:addChild(self.AchievementTableView)
end


function favoriteList.close(self)
    gameTouch:UnrigistFunc("begin","favoriteList")
    gameTouch:UnrigistFunc("end","favoriteList")    
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.GeneralListTableView = nil
    self.AchievementTableView = nil

    self.achievementlist = {}
end

return favoriteList  �H  