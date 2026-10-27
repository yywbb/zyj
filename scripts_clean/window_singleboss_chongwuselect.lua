--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
--

local chongwuList = {

    rootNode = nil,
    rootItems = nil,

    mochongTableview = nil,


    touchPriority = -102,

    petdata = nil,


    -- pageconfig = {"mochong", "fragment"},
    -- pagename = {"魔宠","魔宠碎片"},

}


function chongwuList.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("slotarrange/tc_mochong", nil, true, "select_list")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end



function chongwuList.reload(self,data,callback)
    self.callback = callback
    self.data = data
    print("chongwuList===")
    printT(data)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("singlebosschongwuselect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self.petdata = {}
    local petextdata = {}
    for k,v in pairs(self.data.pets) do
        v.quality = gamedata.config.pet3_attr[tostring(v.cid)][tostring(v.level)].quality
        table.insert(petextdata,v)
        if data.iid == v.iid then
            table.insert(self.petdata,v)
        end
    end

    local sortFunc = function( a, b )
        if a["quality"] > b["quality"] then
            return true
        elseif a["quality"] <= b["quality"] then
            return false
        else
            if a["cid"]  < b["cid"] then
                return true
            else
                return false
            end
        end    

        -- return  a.quality > b.quality    
    end
    table.sort(petextdata,sortFunc)

    for i,v in ipairs(petextdata) do
        if self.data.iid ~= v.iid then
            table.insert(self.petdata,v)
        end
    end
    

    printT(self.data)
    print("chongwuList,reload")
    printT(self.petdata)

    self:mochongRelaod()
end


function chongwuList.mochongRelaod(self)

    if not self.mochongTableview then
        self:createMochongList()
    else
        self.mochongTableview:reloadData()
    end
end


function chongwuList.createMochongList(self)
    local celldict = {}
    local taskListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(935, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("slotarrange/cell_mochongselect.ccbi", nil, true, "cell_mochong")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.petdata[tonumber(a1+1)]
            local config = gamedata.config.pet3_attr[tostring(celldata.cid)][tostring(celldata.level)]
            
            print("config=====")
            printT(config)

            -- ccbDocumentControler.nameLabel:setString(config.name)
            if config.quality >= 7 then
                ui.setLabelString(ccbDocumentControler.nameLabel,config.name,213)
                ui.setLabelString(ccbDocumentControler.qualityLabel,gameConfig.strings:string_common("quality",tonumber(config.quality)),213)
            else
                ui.setLabelString(ccbDocumentControler.nameLabel,config.name,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
                ui.setLabelString(ccbDocumentControler.qualityLabel,gameConfig.strings:string_common("quality",tonumber(config.quality)),((config.quality and config.quality ~= 0) and config.quality or 1)*2)
            end

            -- ccbDocumentControler.qualityLabel:setString(gameConfig.strings:string_common("quality",tonumber(config.quality)) )
            

            ui.setNewIcon(ccbDocumentControler,{cid=self.petdata.cid})
            setSpriteFrameByName(ccbDocumentControler["i_k_quality"], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
            setSpriteFrameByName(ccbDocumentControler["i_quality"], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
            setSpriteFrameByName(ccbDocumentControler.i_icon,config.icon)
            ui.setSpriteTextureRect(ccbDocumentControler.i_icon,0,0,150,150)


            local battleString = "上阵"
            setControlButtonFrameByName(ccbDocumentControler.battleBtn, "b_s_button1.png", CCControlStateNormal)
            if self.data.iid == celldata.iid then
                battleString = "已上阵"
                setControlButtonFrameByName(ccbDocumentControler.battleBtn, "b_s_button2.png", CCControlStateNormal)
            end

            ccbDocumentControler.battleLabel:setVisible(false)

            ui.setLabelString(ccbDocumentControler.battleText,battleString,18)
            ccbDocumentControler.battleBtn:setSwallowsTouch(true)
            ccbDocumentControler.battleBtn:setTouchPriority(self.touchPriority)
            ccbDocumentControler.battleBtn:addHandleOfControlEvent(function()
                -- if self.data.iid == celldata.iid then
                --     GameScene:shiftLayer("devil","up")
                -- else
                --     UIRequest({type = 1043, iid = celldata.iid})
                -- end

                self.callback(celldata.iid)
                gameWindows:closeWindow("singlebosschongwuselect")

            end, CCControlEventTouchUpInside)
            

            cellCCB:setPosition(935/2, 0)
            cellCCB:setScale(0.96)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.petdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.mochongTableview = ui.createLuaTableView({
        handle = taskListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.mochongTableview:setTouchPriority(self.touchPriority)
    self.rootItems.listscroll:addChild(self.mochongTableview)
end



function chongwuList.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    -- if self.callback then
    --     local data = {}
    --     for k,v in pairs(self.selectedData) do
    --         table.insert(data,v)
    --     end
    --     self.callback(data)
    -- end

    self.mochongTableview = nil

    self.petdata = nil
end


return chongwuList