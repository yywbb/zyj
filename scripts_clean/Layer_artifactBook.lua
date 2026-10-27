--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
--

local artifactBook = {
    cellSize = {x=300,y=800},
    touchPriority = -101,
    artifactType = {"gongji","fangyu","fuzhu"}
}

function artifactBook.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_tujian", nil, true, "shenqi_tujian")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    --self.rootItems.tip:setString(gameConfig.strings:string_common("artifact",80))
    if self.rootItems.topnode then
        self.rootItems.topnode:setPositionY(toppos)
    end

    if self.rootItems.middlenode then
        self.rootItems.middlenode:setPositionY(toppos/2)
    end
    self:reloadData()
    self:setListView()
    self.maxLength = self.cellSize.x * #self.data - 900
    self:setBtnFunc()
end

function artifactBook.setBtnFunc(self)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifact","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.right:addHandleOfControlEvent(function()
        local xP = self.listTableView:getLuaContentOffsetX()
        if xP > 0 then
            self.listTableView:setLuaContentOffsetInDuration(0,0,0.2)
        else
            xP = -xP
            if (xP % 300 < 5) or (xP % 300 > 295) then
                xP = xP + 900
            end
            if xP >= self.maxLength then
                self.listTableView:setLuaContentOffsetInDuration(-self.maxLength,0,0.2)
            else
                self.listTableView:setLuaContentOffsetInDuration(-(math.floor((xP + 299)/300) * 300),0,0.2)
            end
        end
        
        self.rootItems.right:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.2), CCCallFunc:create(function()
            self.listTableView:reloadData()
        end)))
    end, CCControlEventTouchUpInside)
    self.rootItems.right:setSwallowsTouch(true)
    self.rootItems.right:setTouchPriority(self.touchPriority)

    self.rootItems.left:addHandleOfControlEvent(function()
        local xP = self.listTableView:getLuaContentOffsetX()
        if xP > 0 then
            self.listTableView:setLuaContentOffsetInDuration(0,0,0.2)
        else
            xP = -xP
            if (xP % 300 < 5) or (xP % 300 > 295) then
                xP = xP - 900
            end
            if xP < 0 then
                self.listTableView:setLuaContentOffsetInDuration(0,0,0.2)
            else
                self.listTableView:setLuaContentOffsetInDuration(-(math.floor(xP/300) * 300),0,0.2)
            end
        end
        self.rootItems.left:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.2), CCCallFunc:create(function()
            self.listTableView:reloadData()
        end)))
    end, CCControlEventTouchUpInside)
    self.rootItems.left:setSwallowsTouch(true)
    self.rootItems.left:setTouchPriority(self.touchPriority)
end


function artifactBook.reloadData(self,data)
    local configs = gamedata.config.trump
    self.data = {}
    for k,v in pairs(configs) do
        if v.goldTrump == 0 and v.id < 110100 then
            self.data[#self.data + 1] = v
        end
    end

    table.sort(self.data,function(a,b)
        return a.id < b.id
    end)
end

function artifactBook.setListView(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.x, self.cellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shenqi_new/cell_shenqitujian", nil, true, "cell_shenqitujian")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.data[a1+1])

            if first then
                a2:addChild(cellCCB)
                cellCCB:setPosition(self.cellSize.x/2,self.cellSize.y/2)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = #self.data
        elseif fn == "cellTouched" then
            
        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.artifactList:getContentSize().width,
        viewheight = self.rootItems.artifactList:getContentSize().height,
        dire = 0
    })
    self.rootItems.artifactList:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority)
end


function artifactBook.setCell(self,items,config)
    ui.setLabelString(items.name,config.name,87)
    local shenqiSkeletonMeta = require"SkeletonShenqi"
    local skeleton = shenqiSkeletonMeta:init(config,0)
    skeleton:setScale(0.6)
    skeleton:setAnimation("stand",true,0)
    items.artifactNode:removeAllChildrenWithCleanup(true)
    items.artifactNode:addChild(skeleton.root or skeleton)

    setSpriteFrameByName(items.artifactType,"shenqi_"..self.artifactType[config.type])
    items.desc:setString(config.desc)
end



function artifactBook.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootItems = nil
    self.rootNode = nil

end


return artifactBook