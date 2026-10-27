local godcompetition_bossskillinfo = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    bossid = 0,
}

function godcompetition_bossskillinfo.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.rootNode, self.rootItems = CCBReaderLoad("fengshensai/tc_bossinfo", nil, true, "tc_bossinfo")
    self.root:addChild(self.rootNode)

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("godcompetition_bossskillinfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority-1)

    self:reloadData(data)

    return self.root
end

function godcompetition_bossskillinfo.reloadData(self, data)
    local bossConfig = gamedata.config.apex_boss
    for k,v in pairs(bossConfig) do
        if v.id == data.bossIndex then
            self.bossid = v.bossid
        end
    end

    if self.bossid > 0 then
        local bossinfo = bossConfig[tostring(self.bossid)]
        self.rootItems.title:setString(bossinfo.name)
        if bossinfo.breakskill > 0 then --被动技能
            local breakskill = gamedata.config.breakskill[tostring(bossinfo.breakskill)]
            self.rootItems.bossskilltext1:setString(breakskill.desc)
        end
        
        if bossinfo.skill1 > 0 then --技能1
            self.rootItems.skillnode2:setVisible(true)
            local combskill = gamedata.config.combskill[tostring(bossinfo.skill1)]
            self.rootItems.bossskill2:setString(combskill.name)
            self.rootItems.bossskilltext2:setString(combskill.desc)
        else
            self.rootItems.skillnode2:setVisible(false)
        end
        if bossinfo.skill2 > 0 then --技能2
            self.rootItems.skillnode3:setVisible(true)
            local combskill = gamedata.config.combskill[tostring(bossinfo.skill2)]
            self.rootItems.bossskill3:setString(combskill.name)
            self.rootItems.bossskilltext3:setString(combskill.desc)
        else
            self.rootItems.skillnode3:setVisible(false)
        end
        if bossinfo.skill3 > 0 then --技能3
            self.rootItems.skillnode4:setVisible(true)
            local combskill = gamedata.config.combskill[tostring(bossinfo.skill3)]
            self.rootItems.bossskill4:setString(combskill.name)
            self.rootItems.bossskilltext4:setString(combskill.desc)
        else
            self.rootItems.skillnode4:setVisible(false)
        end
    end
    
end
   
function godcompetition_bossskillinfo.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.bossid = 0
end

return godcompetition_bossskillinfo