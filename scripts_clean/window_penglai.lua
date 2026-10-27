--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/19
-- Time: 下午3:54
-- To change this template use File | Settings | File Templates.
--

local penglai = {
    rootNode = nil,
    rootItems = nil,

    root = nil,
}

function penglai.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    if data.type == "rule" then
        self.rootNode, self.rootItems = CCBReaderLoad("island/island_rule", nil, true, "island_rule")
        self:reloadRule(data,callback)
    elseif data.type == "confirm" then
        self.rootNode, self.rootItems = CCBReaderLoad("island/island_levelconfirm", nil, true, "island_levelconfirm")
        self:reloadLevelConfirm(data,callback)
    elseif data.type == "serch3" then
        self.rootNode, self.rootItems = CCBReaderLoad("island/island_serch3", nil, true, "island_serch3")
        self:reloadSerch3(data,callback)
    elseif data.type == "serch2" then
        self.rootNode, self.rootItems = CCBReaderLoad("island/island_serch2", nil, true, "island_serch2")
        self:reloadSerch2(data,callback)
    elseif data.type == "serch1" then
        self.rootNode, self.rootItems = CCBReaderLoad("island/island_serch1", nil, true, "island_serch1")
        self:reloadSerch1(data,callback)
    end

    self.root:addChild(self.rootNode)
    return self.root
end

function penglai.reloadRule(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("penglai")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function penglai.reloadLevelConfirm(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("penglai")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.conceltext,"取 消",18)
    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.concel:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("penglai")
    end, CCControlEventTouchUpInside)
    self.rootItems.concel:setSwallowsTouch(true)
    self.rootItems.concel:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.confirmtext,"确 定",18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        UIRequest({type = 2041, difficulty = data.difficulty})
        gameWindows:closeWindowDirect("penglai")
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)
end

function penglai.reloadSerch3(self,data,callback)
    self.callback = callback

    local config = ui.IDconfig(data.data.profile)

    local generalName = gamedata.config.generalanimation[tostring(config.animationid)].name
    local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    general:setAnimation("stand",true,0)
    general:setScale(2)
    self.rootItems.generalnode:addChild(general)

    ui.setLabelString(self.rootItems.level,data.data.level,14)
    ui.setLabelString(self.rootItems.name,data.data.name,1)

    -- ui.setLabelString(self.rootItems.oktext,"迎 战",18)
    ui.setLabelString(self.rootItems.oktext,gameConfig.strings:string_common("popups","against"),18)
    self.rootItems.okButton:addHandleOfControlEvent(function()
        UIRequest({type = 2043, method = 1})
        gameWindows:closeWindowDirect("penglai")
        if GameScene.layers["penglai"].show then
            GameScene.layers["penglai"].module:setnowstepdisappear()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.conceltext,"投 降",18)
    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","define"),18)
    self.rootItems.concelButton:addHandleOfControlEvent(function()
        UIRequest({type = 2043, method = 0})
        gameWindows:closeWindowDirect("penglai")
        if GameScene.layers["penglai"].show then
            GameScene.layers["penglai"].module:setnowstepdisappear()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.concelButton:setSwallowsTouch(true)
    self.rootItems.concelButton:setTouchPriority(self.touchPriority)

end

function penglai.reloadSerch2(self,data,callback)
    self.callback = callback

    local Gneral = CCSkeletonAnimation:create("kulou/kulou.json","kulou/kulou.atlas",2.7)
    Gneral:setAnimation("stand",true,0)
    self.rootItems.generalnode:addChild(Gneral)


    -- ui.setLabelString(self.rootItems.oktext,"迎 战",18)
    ui.setLabelString(self.rootItems.oktext,gameConfig.strings:string_common("popups","against"),18)
    self.rootItems.okButton:addHandleOfControlEvent(function()
        UIRequest({type = 2043, method = 1,})
        gameWindows:closeWindowDirect("penglai")
        if GameScene.layers["penglai"].show then
            GameScene.layers["penglai"].module:setnowstepdisappear()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)
end

function penglai.reloadSerch1(self,data,callback)
    self.callback = callback

    local Gneral = CCSkeletonAnimation:create("niumowang/niumowang.json","niumowang/niumowang.atlas",2.7)
    Gneral:setAnimation("stand",true,0)
    self.rootItems.generalnode:addChild(Gneral)


    -- ui.setLabelString(self.rootItems.oktext,"迎 战",18)
    ui.setLabelString(self.rootItems.oktext,gameConfig.strings:string_common("popups","against"),18)
    self.rootItems.okButton:addHandleOfControlEvent(function()
        UIRequest({type = 2043, method = 1,})
        gameWindows:closeWindowDirect("penglai")
        if GameScene.layers["penglai"].show then
            GameScene.layers["penglai"].module:setnowstepdisappear()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.conceltext,"投 降",18)
    ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","define"),18)
    self.rootItems.concelButton:addHandleOfControlEvent(function()
        UIRequest({type = 2043, method = 0})
        gameWindows:closeWindowDirect("penglai")
        if GameScene.layers["penglai"].show then
            GameScene.layers["penglai"].module:setnowstepdisappear()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.concelButton:setSwallowsTouch(true)
    self.rootItems.concelButton:setTouchPriority(self.touchPriority)
end

function penglai.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return penglai