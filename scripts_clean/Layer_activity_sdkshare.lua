--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local sdkshare = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -101,

    sdksharedata = 0,

}



function sdkshare.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("activity_fenxiang/activity_fenxiang", nil, true, "sdkshare")
    -- parent:addChild(self.rootNode)

    -- self.rootItems.topnode:setPositionY(self.contentsize.y-180)


    self.rootItems.shareNode:setPositionY(self.contentsize.y/2-170+160)

    ui.setLabelString(self.rootItems.getDescText,nil,18)
    ui.setLabelString(self.rootItems.getDescLabel,nil,21)

    ui.setLabelString(self.rootItems.shareDescText,nil,18)

    ui.setLabelString(self.rootItems.doLab,nil,19)
    
    
    self.rootItems.isgetrewardMark:setVisible(false)
   

    return self.rootNode
end





function sdkshare.reloaddata(self,data)
    if not self.show then return end
    if not data then return end

    self.sdksharedata = data.rewardstatus or 0

    local goldreward = ""
    if gamedata.config.global_kv.share_reward_1 then
        goldreward = gamedata.config.global_kv.share_reward_1.value
    end
    ui.setLabelString(self.rootItems.getDescLabel,goldreward,21)

    if self.sdksharedata >= 2 then
        self.rootItems.isgetrewardMark:setVisible(true)
    else
        self.rootItems.isgetrewardMark:setVisible(false)
    end

    if self.sdksharedata == 1 then
        ui.setLabelString(self.rootItems.doLab,"领 取",19)
        self.rootItems.doButton:setTouchPriority(self.buttontouch)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)

            UIRequest({type=2087})

        end, CCControlEventTouchUpInside)
    else
        ui.setLabelString(self.rootItems.doLab,"分 享",19)
        self.rootItems.doButton:setTouchPriority(self.buttontouch)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)

            ui.shareSDK()

            --UIRequest({type=2086})

        end, CCControlEventTouchUpInside)
    end
    
end



function sdkshare.clear(self)
    self.show = false

    self.sdksharedata = 0
    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end

end


function sdkshare.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 2085})
    end
end


return sdkshare