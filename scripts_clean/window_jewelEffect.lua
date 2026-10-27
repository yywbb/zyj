--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/6/14
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local jewelEffect = {
    rootNode = nil,
    rootItems = nil,
    cellSize = {x = 690,y = 800}
}

function jewelEffect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_baoshixiaoguo", nil, true, "tc_baoshixiaoguo")
    self:initFixedString()
    --
    self.touchPriority = touchPriority
    --
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("jewelEffect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)
    --
    self:reloadData(data)
    self:setListView()
    self.maxLength = self.cellSize.x * 6 - 690
    self.listTableView:setLuaContentOffset(-self.cellSize.x * (self.level - 1),0)
    self:setBtnFunc()
    return self.rootNode
end

function jewelEffect.initFixedString(self)
    ui.setLabelString(self.rootItems.titleTxt,gameConfig.strings:string_common("artifact",81),65)
end

function jewelEffect.setBtnFunc(self)
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("jewelEffect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

    self.rootItems.right:addHandleOfControlEvent(function()
        local xP = self.listTableView:getLuaContentOffsetX()
        if xP > 0 then
            self.listTableView:setLuaContentOffsetInDuration(0,0,0.2)
        else
            xP = -xP
            if (xP % 690 < 5) or (xP % 690 > 685) then
                xP = xP + 690
            end
            if xP >= self.maxLength then
                self.listTableView:setLuaContentOffsetInDuration(-self.maxLength,0,0.2)
            else
                self.listTableView:setLuaContentOffsetInDuration(-(math.floor((xP + 689)/690) * 690),0,0.2)
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.right:setSwallowsTouch(true)
    self.rootItems.right:setTouchPriority(self.touchPriority)

    self.rootItems.left:addHandleOfControlEvent(function()
        local xP = self.listTableView:getLuaContentOffsetX()
        if xP > 0 then
            self.listTableView:setLuaContentOffsetInDuration(0,0,0.2)
        else
            xP = -xP
            if (xP % 690 < 5) or (xP % 690 > 685) then
                xP = xP - 690
            end
            if xP < 0 then
                self.listTableView:setLuaContentOffsetInDuration(0,0,0.2)
            else
                self.listTableView:setLuaContentOffsetInDuration(-(math.floor(xP/690) * 690),0,0.2)
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.left:setSwallowsTouch(true)
    self.rootItems.left:setTouchPriority(self.touchPriority)
end


function jewelEffect.reloadData(self,data)
    self.data = data
    self.level = 0
    for i = 1,4 do
        if data["jewel"..i] > 0 then
            local config = gamedata.config.trump_gem[tostring(data["jewel"..i])]
            self.level = self.level + config.lv
        end
    end
    self.level =  math.floor(math.min(6,self.level/8 + 1))
    self.config = gamedata.config.trump[tostring(data.cid)]
end

function jewelEffect.setListView(self)
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.x, self.cellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            if not a2 then
                a2 = CCTableViewCell:create()
            end
            self:setCell(a2,a1 + 1)

            r = a2
        elseif fn == "numberOfCells" then
            r = 6
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

function jewelEffect.setCell(self,item,index)
    item:removeAllChildrenWithCleanup(true)
    local shenqiSkeletonMeta = require"SkeletonShenqi"
    local skeleton = shenqiSkeletonMeta:init(self.config,(index - 1) * 8)
    skeleton:setAnimation("stand",true,0)
    skeleton:setPosition(self.cellSize.x/2,self.cellSize.y/2 - 130)
    item:addChild(skeleton.root or skeleton)

    local label = CCLabelTTF:create(gameConfig.strings:string_format({"artifact",82},{(index - 1) * 8}),"Helvetica-Bold",30)
    label:setPosition(self.cellSize.x/2,80)
    ui.setLabelString(label,nil,23)
    item:addChild(label)
end

function jewelEffect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return jewelEffect