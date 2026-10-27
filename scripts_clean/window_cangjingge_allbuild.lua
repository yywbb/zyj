--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/2/17
-- Time: 11:29
-- To change this template use File | Settings | File Templates.
--


local cangjingge_allbuild = {
    rootNode = nil,
    rootItems = nil,
}

function cangjingge_allbuild.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("cangjingge/cangjingge_allbuild", nil, true, "cangjingge_allbuild")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function cangjingge_allbuild.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("cangjingge_allbuild")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --

    ui.setLabelString(self.rootItems.fixstring1,gameConfig.strings:string_common("cangjingge",38),18)
    ui.setLabelString(self.rootItems.fixstring2,gameConfig.strings:string_common("cangjingge",39),18)

    --
    for i = 1,5 do
        if data.building and data.building[tostring(i)] and data.building[tostring(i)].level > 0 then

            local labelparams = (data.building[tostring(i)].quality > 0) and (data.building[tostring(i)].quality*2+3) or 5
            ui.setLabelString(self.rootItems["name"..i],gamedata.config.home_building[tostring(i)][tostring(data.building[tostring(i)].quality > 0 and data.building[tostring(i)].quality or 1)].name..((i == 2) and "" or ("("..data.building[tostring(i)].level..gameConfig.strings:string_common("cangjingge",6)..")")),data.building[tostring(i)].quality == 5 and 213 or labelparams)
            ui.setLabelString(self.rootItems["quality"..i],gameConfig.strings:string_common("cangjingge",41)..gameConfig.strings:string_common("cangjinggequality",(data.building[tostring(i)].quality > 0 and data.building[tostring(i)].quality or 1)),data.building[tostring(i)].quality == 5 and 213 or labelparams)
            setSpriteFrameByName(self.rootItems["icon"..i], "c_b_jianzhu"..i.."_"..(data.building[tostring(i)].quality > 0 and data.building[tostring(i)].quality or 1))
        else
            ui.setLabelString(self.rootItems["name"..i],gamedata.config.home_building[tostring(i)][tostring(1)].name.."("..gameConfig.strings:string_common("cangjingge",40)..")",5)
            ui.setLabelString(self.rootItems["quality"..i],gameConfig.strings:string_common("cangjingge",41)..gameConfig.strings:string_common("cangjinggequality",1),5)
            setSpriteFrameByName(self.rootItems["icon"..i], "c_b_jianzhu"..i.."_1")
        end
    end

end

function cangjingge_allbuild.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return cangjingge_allbuild

