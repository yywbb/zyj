
local peentoGiftPreShow = {
    rootNode = nil,
    rootItems = nil,
}

function peentoGiftPreShow.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("pantaoxianli/activitypantao_yulan", nil, true, "activitypantao_yulan")
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function peentoGiftPreShow.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("peentoGiftPreShow")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    ui.setLabelString(self.rootItems.fixed1,gameConfig.strings:string_common("activity",4),48)

    local config = gamedata.config.peentogiftawards[tostring(data.day)]
    local tableP = {}
    if data.peentoData then
        for k,v in pairs(data.peentoData.getPosition) do
            if v > 0 then
                tableP[v] = 1
            end
        end
    end
    
    for i = 1,8 do
        local id,count
        id,count = ui.getIDandNUM(config["reward"..i])
        --
        if id == 1000 then
            if tableP[i] and tableP[i] > 0 then
                count = data.peentoData.silverNum
            else
                local silverConfig = gamedata.config.peentogift_silver
                local cuP
                local maxSilver = 0
                for k,v in pairs(silverConfig) do
                    local level = tonumber(k)
                    if GameScene.roleinfo.level <= level then
                        if not cuP then
                            cuP = k
                        else
                            if tonumber(cuP) > level then
                                cuP = k
                            end
                        end
                    end
                    if v.silver > maxSilver then
                        maxSilver = v.silver
                    end
                end
                count = cuP and silverConfig[cuP].silver or maxSilver
            end
        end
        --
        local k_add = (i - 1 == 0) and "" or "_"..(i-1)
        ui.setNewIcon(self.rootItems,{cid = id,num = count},i - 1)
        if tableP[tonumber(i)] then
            ui.addGray("CCSprite",self.rootItems["i_quality"..k_add])
            ui.addGray("CCSprite",self.rootItems["i_k_quality"..k_add])
            ui.addGray("CCSprite",self.rootItems["i_icon"..k_add])
            self.rootItems["isGet"..k_add]:setVisible(true)
        else
            self.rootItems["isGet"..k_add]:setVisible(false)
        end
        self.rootItems["i_button"..k_add]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(id)
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button"..k_add]:setTouchPriority(self.touchPriority)
    end
end

function peentoGiftPreShow.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return peentoGiftPreShow

