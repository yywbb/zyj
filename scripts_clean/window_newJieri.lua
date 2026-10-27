--
--

local newJieri = {
    rootNode = nil,
    rootItems = nil,

}

function newJieri.open(self,touchPriority,data,callback)

    if GameScene.layers["main"].module.holidaytype and GameScene.layers["main"].module.holidaytype == 1 then 
        self.rootNode, self.rootItems = CCBReaderLoad("activityjieri/activityshengdanliwu", nil, true, "activityshengdanliwu")
    else
        self.rootNode, self.rootItems = CCBReaderLoad("activityjieri/activityshengdanliwu", nil, true, "activityshengdanliwu")
    end

    self.touchPriority = touchPriority

    if self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindow("newJieri")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    for i = 1,5 do
        self.rootItems["dobutton"..i]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            if GameScene.holidaynum and (GameScene.holidaynum < gamedata.config.holiday_time[tostring(GameScene.layers["main"].module.holidaytype)].num) then
                UIRequest({type = 6502, id = i})
            else
                runGamePrompt({msg = "今日领取次数已用完"})
            end 
        end, CCControlEventTouchUpInside)
        self.rootItems["dobutton"..i]:setSwallowsTouch(true)
        self.rootItems["dobutton"..i]:setTouchPriority(self.touchPriority)
    end

    return self.rootNode
end

function newJieri.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end


return newJieri