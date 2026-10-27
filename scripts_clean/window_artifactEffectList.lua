--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/6
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local artifactEffectList = {
    rootNode = nil,
    rootItems = nil,
    CellSize = {x=920,y=10},
    canTouch = false,
    labelH = 48,
    primeP = 4,
}

function artifactEffectList.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("duanzaoshenqi/tc_fujiaxiaoguo", nil, true, "tc_fujiaxiaoguo")
    --
    self.touchPriority = touchPriority
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactEffectList")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self:createList()
    return self.rootNode
end


function artifactEffectList.setlistCell(self,items,skillConfig)
    items.desc:removeAllChildrenWithCleanup(true)
    items.skillName:removeAllChildrenWithCleanup(true)
    items.desc:setDimensions(CCSizeMake(690,skillConfig.desc_param * self.labelH))
    items.desc:setPositionY(self.primeP + skillConfig.desc_param * self.labelH)
    items.skillName:setPositionY(self.primeP + skillConfig.desc_param * self.labelH)
    ui.setLabelString(items.skillName,skillConfig.name,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2 - 1)
    ui.setLabelString(items.desc,":"..skillConfig.desc,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2 - 1)
end



function artifactEffectList.createList(self)
    local skillConfig = gamedata.config.trump_skillRnd
    local skills = {}
    for i = 1,3 do
        for k,v in pairs(skillConfig[tostring(i)]) do
            for i = 1,6 do
                skills[v["skill"..i]] = true
            end
        end
    end
    local showSkill = {}
    for k,v in pairs(skills) do
        showSkill[#showSkill + 1] = gamedata.config.breakskill[tostring(k)]
    end
    
    table.sort(showSkill,function (a,b)
        if a.integral == b.integral then
            return a.id < b.id
        else
            return a.integral > b.integral
        end
    end)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
        
        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            local skillConfig = showSkill[a1 + 1]
            r = CCSizeMake(self.CellSize.x,skillConfig.desc_param * self.labelH + self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("duanzaoshenqi/cell_fujiaxiaoguozi", nil, true, "cell_fujiaxiaoguozi")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                a2:addChild(cellCCB)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local config = showSkill[a1 + 1]
            local sHeight = config.desc_param * self.labelH + self.CellSize.y
            cellCCB:setPosition(self.CellSize.x/2, -sHeight)
            --cellCCB:setContentSize(CCSizeMake(910,sHeight))
            self:setlistCell(ccbDocumentControler,config)

            r = a2

        elseif fn == "numberOfCells" then
            r = #showSkill
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
           
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.scrollList:getContentSize().width,
        viewheight = self.rootItems.scrollList:getContentSize().height,
        dire = 1
    })
    self.rootItems.scrollList:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)

end

function artifactEffectList.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return artifactEffectList