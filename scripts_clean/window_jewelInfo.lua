--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/6
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local jewelInfo = {
    rootNode = nil,
    rootItems = nil,
    jewelUpUseId = 20680,
    props = {},
}

function jewelInfo.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("duanzaoshenqi/baoshiinfo", nil, true, "baoshiinfo")
    self:initFixedString()
    --
    self.touchPriority = touchPriority
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("jewelInfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.callback = callback
    self.data = data
    if data.isUp then
        self:getUseIdNum()
    else
        self:reload()
    end
    return self.rootNode
end

function jewelInfo.initFixedString(self)
    ui.setLabelString(self.rootItems.upLab,gameConfig.strings:string_common("equips",7),19)
    self.rootItems.title:setString(gameConfig.strings:string_common("artifact",4))
    ui.setLabelString(self.rootItems.downLab,gameConfig.strings:string_common("artifact",5),19)
    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("battleScene",3),19)
end

function jewelInfo.reload(self)

    ui.setNewIcon(self.rootItems,{cid = self.data.cid,},0)
    local config =  gamedata.config.trump_gem[tostring(self.data.cid)]
    ui.setLabelString(self.rootItems.name,config.name,1)
    ui.setAttrStr(self.rootItems["attr"],self.data)

    if self.data.isUp then
        self.rootItems.doNode:setVisible(false)
        if not self.data.artifact then
            self.rootItems.upNode:setPositionX(self.rootItems.doNode:getPositionX())
            self.rootItems.downNode:setVisible(false)
        else
            self.rootItems.downButton:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                UIRequest({type = 5505,iid = self.data.artifact.iid,jewelCid = 0,pos = self.data.pos})
                gameWindows:closeWindow("jewelInfo")
            end, CCControlEventTouchUpInside)
            self.rootItems.downButton:setSwallowsTouch(true)
            self.rootItems.downButton:setTouchPriority(self.touchPriority)
        end
        local isOk = 1
        local useTable = {}
        local config = gamedata.config.trump_gem[tostring(self.data.cid)]
        local jewelData = GameScene.layers["artifactList"].module.jewelData.primeData
        if config.per_cid <= 0 then
            isOk = -1
        end
        local usePropNum = 0
        local useJewelNum = 0
        local configN
        if isOk == 1 then
            configN = gamedata.config.trump_gem[tostring(config.per_cid)]
            if GameScene.roleinfo.level < configN.gem_lvbet then
                isOk = -1
            end
            useTable = ui.getIDandNUMs(config.gem_lv) 
            for k,v in ipairs(useTable) do
                if v.cid == self.data.cid then
                    useJewelNum = v.num
                    if not jewelData[tostring(v.cid)] or jewelData[tostring(v.cid)].num + 1 < v.num then
                        isOk = 2
                    end
                else
                    usePropNum = v.num
                    if self.props[tostring(v.cid)] < v.num then
                        isOk = 3
                    end
                end
            end
        end
        
        if isOk ~= 1 then
            ui.addGray("CCControlButton",self.rootItems.upButton)
        end
        self.rootItems.upButton:addHandleOfControlEvent(function()
            if self.data.artifact then
                if config.per_cid <= 0 then
                    return runGamePrompt({msg = gameConfig.strings:string_common("artifact",2)})
                end
                if GameScene.roleinfo.level < configN.gem_lvbet then
                    return runGamePrompt({msg = gameConfig.strings:string_format({"artifact",100},{configN.gem_lvbet})})
                end
                gameWindows:openWindow("artifactOpenPos",{artifact = self.data.artifact,pos = self.data.pos},function ()
                    gameWindows:closeWindow("jewelInfo")
                end)
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.upButton:setSwallowsTouch(true)
        self.rootItems.upButton:setTouchPriority(self.touchPriority)
    else
        self.rootItems.upNode:setVisible(false)
        self.rootItems.downNode:setVisible(false)
        self.rootItems.doNode:setVisible(true)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            self.callback = nil
            gameWindows:closeWindow("jewelInfo")
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority)
    end
   
    
end

function jewelInfo.getUseIdNum(self,t)
    self.props = t or self.props
    if not self.props[tostring(self.jewelUpUseId)] then
        UIRequest({type = 12001, order = 33014, cids = {self.jewelUpUseId}})
        return
    end
    self:reload()
end

function jewelInfo.close(self)
    self.pagetype = "info"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
    self.props = {}
end

return jewelInfo