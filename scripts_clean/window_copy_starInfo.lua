--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/2/25
-- Time: 13:45
-- To change this template use File | Settings | File Templates.
--

local copystarInfo = {
    rootNode = nil,
    rootItems = nil,
    data = {},
}

function copystarInfo.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("copystar/copystar_info", nil, true, "copystar_info")

    self.touchPriority = touchPriority
    self.callback = callback
    self.data = data

    if  self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindow("copystarInfo")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    self:reload()

    return self.rootNode
end

function copystarInfo.reload(self,data)
    if data then
        self.data = data
    end

    --
    self.config = gamedata.config.star_copy[tostring(self.data.mapid)]
    --
    ui.setLabelString(self.rootItems["generalName"],self.config[tostring(self.data.pointid)].name,1)
    --
    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(self.config[tostring(self.data.pointid)].icon).animationid)].name
    local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(1.5)
    Gneral:setScaleX(1.5)
    Gneral:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(Gneral)
    --
    local key_Ex = ""
    for i = 1,4 do
       local index = i
       if self.config[tostring(self.data.pointid)]["drop_no1"] and self.config[tostring(self.data.pointid)]["drop_no1"] > 0 then
           index = (index-1) > 0 and (index-1) or index
       end

       if i == 1 and self.config[tostring(self.data.pointid)]["drop_no1"] and self.config[tostring(self.data.pointid)]["drop_no1"] > 0 then
           self.rootItems["reward"..i]:setVisible(true)
           ui.setNewIconName(self.rootItems,{cid = self.config[tostring(self.data.pointid)]["drop_no1"], num = self.config[tostring(self.data.pointid)]["drop1number_no1"] or 0},i-1)
       elseif self.config[tostring(self.data.pointid)]["drop"..index] and self.config[tostring(self.data.pointid)]["drop"..index] > 0 then
           self.rootItems["reward"..i]:setVisible(true)
           ui.setNewIconName(self.rootItems,{cid = self.config[tostring(self.data.pointid)]["drop"..index], num = self.config[tostring(self.data.pointid)]["drop"..index.."number"] or 0},i-1)
            if i == nil or i == 1 then
                key_Ex = ""
            else
                key_Ex = "_"..(i-1)
            end
           self.rootItems["i_button" .. key_Ex]:addHandleOfControlEvent(function()
               ui.setPopwindowByCid(self.config[tostring(self.data.pointid)]["drop"..index])
           end, CCControlEventTouchUpInside)
           self.rootItems["i_button" .. key_Ex]:setSwallowsTouch(true)
           self.rootItems["i_button" .. key_Ex]:setTouchPriority(self.touchPriority)   

       else
           self.rootItems["reward"..i]:setVisible(false)
       end
    end
    --
    ui.setLabelString(self.rootItems["lab1"],nil,21)
    ui.setLabelString(self.rootItems["battleLab"],nil,19)
    ui.setLabelString(self.rootItems["times"], "本关卡可战胜次数: "..(self.data.pointstatus > 0 and (self.config[tostring(self.data.pointid)].challenge-self.data.pointstatus) or self.config[tostring(self.data.pointid)].challenge).."/"..self.config[tostring(self.data.pointid)].challenge,14)
    --
    if  self.rootItems.battleButton then
        self.rootItems.battleButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            if self.data.pointstatus >= self.config[tostring(self.data.pointid)].challenge then
                runGamePrompt({msg = "本关卡今日次数已用完"})
            else
                UIRequest({type = 1351, mapid = self.data.mapid, pointid = self.data.pointid, pointstatus = self.data.pointstatus})
                --gameWindows:closeWindowDirect("copystarInfo")
                self:closedelay()
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.battleButton:setSwallowsTouch(true)
        self.rootItems.battleButton:setTouchPriority(self.touchPriority)
    end
    --
end

function copystarInfo.closedelay(self)
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        gameWindows:closeWindowDirect("copystarInfo")
    end))
    self.rootNode:runAction(sequence)
end

function copystarInfo.close(self)
    self.data = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return copystarInfo
