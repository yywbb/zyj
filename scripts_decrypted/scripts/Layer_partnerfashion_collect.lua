--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/3
-- Time: 下午1:31
-- To change this template use File | Settings | File Templates.
--


local partnerfashion_collect = {

    rootNode = nil,
    rootItems = nil,

    normaltableview = nil,
    normaldata = {},

    partnerfashion = {},

    isscrolltouched = false,
}


function partnerfashion_collect.init(self,parent,toppos)

    self.rootNode,self.rootItems = CCBReaderLoad("wujiangshizhuang/wujiangshizhuang_tujian", nil, true, "wujiangshizhuang")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.normalScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-150-160))


    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(-102)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("main","down")
    end, CCControlEventTouchUpInside)


    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","partnerfashion_collect",touchbegin)

    local function touchend(pos)
        if self.rootItems.normalScroll and ui.isTouched(self.rootItems.normalScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","partnerfashion_collect",touchend)
    --

    UIRequest({type = 10023})
    gameTouch:clickprofbytime(1)
    UIRequest({type = 6911})

end

function partnerfashion_collect.clear(self)

    gameTouch:UnrigistFunc("begin","partnerfashion_collect")
    gameTouch:UnrigistFunc("end","partnerfashion_collect")

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.partnerfashion = {}
    self.normaldata = {}
    self.normaltableview = nil
    self.rootNode = nil
    self.rootItems = nil
end


function partnerfashion_collect.createnormalListview(self)
    local celldict = {}
    local normalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080,400)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("wujiangshizhuang/cell_wujiangshizhuang_tujian", nil, true, "cell_wujiangshizhuang_tujian")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            for i = 1,3 do
                if self.normaldata[a1*3+i] then
                    ccbDocumentControler["node"..i]:setVisible(true)
                    local showgeneral = gamedata.config.general[tostring(self.normaldata[a1*3+i].orange_partner > 0 and self.normaldata[a1*3+i].orange_partner or self.normaldata[a1*3+i].red_partner)] or {}
                    setSpriteFrameByName(ccbDocumentControler["icon"..i],showgeneral.fashion_map~="" and showgeneral.fashion_map or "alpha")
                    if ccbDocumentControler["name"..i] then
                        ui.setLabelString(ccbDocumentControler["name"..i],self.normaldata[a1*3+i].name or "",14)
                    end    
                    --ccbDocumentControler["button"..i]:setSwallowsTouch(true)
                    ccbDocumentControler["button"..i]:setTouchPriority(-101)
                    ccbDocumentControler["button"..i]:addHandleOfControlEvent(function()
                        if gameTouch.isScrollling then return end
                        if not self.isscrolltouched then return end
                        local generalsdata = {}
                        if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
                            generalsdata = table.copy(GameScene.layers["generals"].module.generalsdata)
                        end 
                        local showpartnercid = (self.normaldata[a1*3+i].orange_partner > 0 and self.normaldata[a1*3+i].orange_partner or self.normaldata[a1*3+i].red_partner)
                        for k,v in pairs(generalsdata) do
                            if (v.cid == self.normaldata[a1*3+i].gold_partner) or (v.cid == self.normaldata[a1*3+i].gold_partner2) then
                                showpartnercid = self.normaldata[a1*3+i].gold_partner
                            elseif (v.cid == self.normaldata[a1*3+i].red_partner) or (v.cid == self.normaldata[a1*3+i].red_partner2) then
                                showpartnercid = self.normaldata[a1*3+i].red_partner
                            end    
                        end
                        gameWindows:openWindow("partner_fashion",{cid = showpartnercid, iid = 0, opt = 2},nil)
                    end, CCControlEventTouchUpInside)
                    --
                    if self.normaldata[a1*3+i].has and self.normaldata[a1*3+i].has == 1 then
                        ui.removeGray("CCSprite",ccbDocumentControler["icon"..i]) 
                    else    
                        ui.addGray("CCSprite",ccbDocumentControler["icon"..i]) 
                    end   
                    --
                    if ccbDocumentControler["shizhuang_hint"..i] then
                        if getPartnerfashionOnceFromSqlite(self.normaldata[a1*3+i].fashion_id) == 1 then
                            ccbDocumentControler["shizhuang_hint"..i]:setVisible(true)
                        else
                            ccbDocumentControler["shizhuang_hint"..i]:setVisible(false)
                        end    
                    end    
                else    
                    ccbDocumentControler["node"..i]:setVisible(false)
                    setSpriteFrameByName(ccbDocumentControler["icon"..i],"alpha")
                    --ccbDocumentControler["button"..i]:setSwallowsTouch(true)
                    ccbDocumentControler["button"..i]:setTouchPriority(-101)
                    ccbDocumentControler["button"..i]:addHandleOfControlEvent(function()
                        --
                    end, CCControlEventTouchUpInside)
                end   
            end 

            cellCCB:setPosition(540, 200)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.normaldata)/3)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.normaltableview = ui.createLuaTableView({
        handle = normalListHandle,
        viewwidth = self.rootItems.normalScroll:getContentSize().width,
        viewheight = self.rootItems.normalScroll:getContentSize().height,
        dire = 1
    })
    self.normaltableview:setTouchPriority(-101)
    self.rootItems.normalScroll:addChild(self.normaltableview)
end


function partnerfashion_collect.reloaddata(self,data)
  
    if data and data.partnerfashion then
        self.partnerfashion = table.copy(data.partnerfashion)
    end    

    self.normaldata = {}
    for k,v in pairs(gamedata.config.partner_fashion) do
        v.has = 0
        if self.partnerfashion[tostring(v.fashion_id)] and self.partnerfashion[tostring(v.fashion_id)].time ~= 0 then
            v.has = 1
        end    
        table.insert(self.normaldata,v)
    end 
    --
    local sortfunc = function (a,b)
        if a.has == b.has then
            if a["sort"] == b["sort"] then
                return a.fashion_id < b.fashion_id
            else
                return a["sort"]< b["sort"]
            end 
        else 
            return a.has > b.has
        end  
    end
    table.sort(self.normaldata,sortfunc)
    --

    if self.normaltableview then
        self.normaltableview:reloadData()
    else
        self:createnormalListview()
    end

end

return partnerfashion_collect


 +   