--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
--

local devourList = {

    rootNode = nil,
    rootItems = nil,

    mochongTableview = nil,


    touchPriority = -102,

    petdata = nil,


    -- pageconfig = {"mochong", "fragment"},
    -- pagename = {"魔宠","魔宠碎片"},
    pageconfig = {"mochong",},
    pagename = {"魔宠"},
    selectpage = "mochong",

}

function devourList.shiftPage(self,page)
    self.selectpage = page
    for k,v in ipairs(self.pageconfig) do
        if v == page then
            self.rootItems[v.."scroll"]:setPositionX(0)
        else
            self.rootItems[v.."scroll"]:setPositionX(9999)
        end
    end

    if self.selectpage == "mochong" then
        self:mochongRelaod()
    elseif self.selectpage == "fragment" then

    end

end


function devourList.init(self,parent,toppos,param)
    print("devourList..init",toppos)
    self.toppos = toppos
    printT(param)
    self.data = param
    self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochongList", nil, true, "mochongList")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    if self.rootItems.topNode then
        self.rootItems.topNode:setPositionY(toppos)
    end

    self.rootItems.mochongscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-180-102))
    self.rootItems.fragmentscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-180-102))



    self:reload()

end


function devourList.reload(self)

    self.rootItems.closeButton:addHandleOfControlEvent(function()

        GameScene:shiftLayer("devil","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self.petdata = {}
    local petextdata = {}
    for k,v in pairs(self.data.pets) do
        v.quality = gamedata.config.pet3_attr[tostring(v.cid)][tostring(v.level)].quality
        table.insert(petextdata,v)
        if self.data.iid == v.iid then
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
    print("devourList,reload")
    printT(self.petdata)


    self:shiftPage(self.selectpage)
end


function devourList.mochongRelaod(self)

    if not self.mochongTableview then
        self:createMochongList()
    else
        self.mochongTableview:reloadData()
    end
end


function devourList.createMochongList(self)
    local celldict = {}
    local taskListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 228)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("mochong3/cell_mochong.ccbi", nil, true, "cell_mochong")
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
            ui.setLabelString(ccbDocumentControler.nameLabel,config.name,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
            ui.setLabelString(ccbDocumentControler.qualityLabel,gameConfig.strings:string_common("quality",tonumber(config.quality)),((config.quality and config.quality ~= 0) and config.quality or 1)*2)

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
                if self.data.iid == celldata.iid then
                    GameScene:shiftLayer("devil","up")
                else
                    UIRequest({type = 1043, iid = celldata.iid})
                end
                
            end, CCControlEventTouchUpInside)
            

            cellCCB:setPosition(1080/2, 0)
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
        viewwidth = self.rootItems.mochongscroll:getContentSize().width,
        viewheight = self.rootItems.mochongscroll:getContentSize().height,
        dire = 1
    })
    self.mochongTableview:setTouchPriority(self.touchPriority)
    self.rootItems.mochongscroll:addChild(self.mochongTableview)
end


function devourList.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.mochongTableview = nil

    self.petdata = nil
end


return devourList