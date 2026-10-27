
local magicViewAttr = {
    rootNode = nil,
    rootItems = nil,
}

function magicViewAttr.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("magic/magic_nextinfo", nil, true, "magic_nextinfo")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function magicViewAttr.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("magicViewAttr")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    ui.setLabelString(self.rootItems.desc,nil,14)
    local  tData = gamedata.config.artifact[tostring(data.id)]
    for i = 1,4 do
        ui.setLabelString(self.rootItems["progress"..i.."Name"],gameConfig.strings:string_common("attr_type",tData["attr"..i]),21)
        if tData["init"..i] >= 1 then
            ui.setLabelString(self.rootItems["text"..i], tData["initial"..i],22)
            ui.setLabelString(self.rootItems["maxText"..i],"最大("..tData["init"..i]..")",13)                        
        else
            ui.setLabelString(self.rootItems["text"..i],self:maybetopercent(tData["initial"..i]),22)
            ui.setLabelString(self.rootItems["maxText"..i],"最大("..self:maybetopercent(tData["init"..i])..")",13)                        
        end
    end

end
function magicViewAttr.maybetopercent( self , aiNum )
    if aiNum < 1 and aiNum >0 then
        return aiNum * 100 .."%"
    elseif aiNum > -1 and aiNum < 0 then
        return aiNum * 100 .."%"
    else
        return aiNum
    end
end

function magicViewAttr.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return magicViewAttr

