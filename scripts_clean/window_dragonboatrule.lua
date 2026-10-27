
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local dragonboatrule = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
}


function dragonboatrule.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.rootNode, self.rootItems = CCBReaderLoad("activityduanwu/dragonboat_rule", nil, true, "dragonboat_rule")
    self:tishiinit(data)

    self.root:addChild(self.rootNode)
    return self.root
end

function dragonboatrule.transTableToString(self,destTable)
    local tmpStr = ""
    local function dealTable(destValue,destIndex)
        if type(destValue) == "table" then
            for i,v in ipairs(destValue) do
                dealTable(v,i)
            end
        elseif type(destValue) == "number" and destIndex ~= nil then
            if destIndex == 1 then -- 道具ID
                local tmpItem = ui.IDconfig(destValue)
                tmpStr = tmpStr..tmpItem.name..":"
            elseif destIndex == 2 then -- 最小数目
                tmpStr = tmpStr..destValue.."~"
            else -- 最大数目
                tmpStr = tmpStr..destValue..";"
            end
        end
    end
    dealTable(destTable)
    return tmpStr
end

function dragonboatrule.transTimesToString(self,destTime)
    local tmpReturnStr = ""
    local function nimabiaas(destTimes,destStep)
        destTimes = math.floor(destTimes)
        local stringFen = ""
        if destTimes == 0 then
            stringFen = "00"
        elseif destTimes < 10 then
            stringFen = "0"..destTimes
        else
            stringFen = ""..destTimes
        end
        if destStep ~= 0 then
            stringFen = stringFen..":"
        end
        tmpReturnStr = tmpReturnStr..stringFen
    end
    nimabiaas(destTime[1],1)
    nimabiaas(destTime[2],0)

    return tmpReturnStr
end

function dragonboatrule.tishiinit(self,data)
    self.rootItems.m_owinttf:setString(self:transTableToString(data.windata))
    self.rootItems.m_olosttf:setString(self:transTableToString(data.losdata))
    self.rootItems.m_oTimes1:setString(self:transTimesToString(data.time1[2]).."、"..self:transTimesToString(data.time2[2]))
    self.rootItems.m_oTimes2:setString(self:transTimesToString(data.time1[1]).."~"..self:transTimesToString(data.time1[2]))
    self.rootItems.m_oTimes3:setString(self:transTimesToString(data.time2[1]).."~"..self:transTimesToString(data.time2[2]))


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("dragonboatrule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

end


function dragonboatrule.close(self)  
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return dragonboatrule