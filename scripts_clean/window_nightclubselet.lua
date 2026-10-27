
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local clubselet = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    m_iSeletIndex = nil,
}


function clubselet.open(self,touchPriority,data,callback)
    -- print("data===:",data)
    self.m_iSeletIndex = data
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    local tmpConfig = gamedata.config.tiantingyz_time

    self.rootNode, self.rootItems = CCBReaderLoad("nightclub/nightclub_select", nil, true, "nightclub_select")
    ui.setLabelString(self.rootItems["backlable"],gameConfig.strings:string_common("buttontext","fanhui"),14)
    self.rootItems["backbutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["backbutton"]:setSwallowsTouch(true)
    self.rootItems["backbutton"]:addHandleOfControlEvent(function()
        callback(self.m_iSeletIndex)
        gameWindows:closeWindow("clubselet")
    end, CCControlEventTouchUpInside)

    local tmpNVip = {}
    local tmpLableArray = {}

    self.rootItems["title"]:setString(gameConfig.strings:string_common("nightclub",8))
    for i=1,3 do
        local tmpIndexs = tostring((i-1)*3+1)
        if self.m_iSeletIndex == i then
            self.rootItems["type"..i]:setVisible(true)
        else
            self.rootItems["type"..i]:setVisible(false)
        end
        tmpNVip[tostring(i)] = tmpConfig[tmpIndexs]["vip_level"]
        tmpLableArray[tostring(i)] = tmpConfig[tmpIndexs]["income_time"]
        self.rootItems["lable"..i]:setString(string.format(gameConfig.strings:string_common("nightclub",12),(tmpLableArray[tostring(i)])))
        self.rootItems["selete"..i]:setTouchPriority(self.touchPriority)
        self.rootItems["selete"..i]:setSwallowsTouch(true)
        self.rootItems["selete"..i]:addHandleOfControlEvent(function()
            if GameScene.vip.vip < tonumber(tmpNVip[tostring(i)]) then
                runGamePrompt({msg = gameConfig.strings:string_common("fairycave",11)})
                return 
            end
            self.m_iSeletIndex = i
            callback(self.m_iSeletIndex)
            gameWindows:closeWindow("clubselet")
        end, CCControlEventTouchUpInside)
        if i == 2 and GameScene.vip.vip >= tonumber(tmpNVip[tostring(2)]) then
            self.rootItems.tips2:setVisible(false)
            self.rootItems.tipsnow2:setVisible(false)
        elseif i == 3 and GameScene.vip.vip >= tonumber(tmpNVip[tostring(3)]) then
            self.rootItems.tips3:setVisible(false)
            self.rootItems.tipsnow3:setVisible(false)
        end
    end


    self.root:addChild(self.rootNode)
    return self.root
end


function clubselet.close(self)  
    self.isscrolltouched = false
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return clubselet