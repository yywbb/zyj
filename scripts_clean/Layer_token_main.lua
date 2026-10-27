local tokenMain = {
	rootNode = nil,
    rootItems = nil,
    
    pageconfig = {"token"} ,

    pagebuild = {631},

    pageconfigKey = {
        token = 1,
    },

    pagename = {"天机令"},

    modules = {
    	token = require("page_token"),
    },

    pageInitStatus = {
        token = false,
    },

    shiftPageNeedRefresh = {
        token = false,
    },

    build = {
        token = 631
    },

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {631},
            },
        },
    },

    selectpage = "token",
    touchPriority = -101,
}

function tokenMain.clear(self)
    for k,v in pairs(self.modules) do
        if self["pageInitStatus"][k] then
            v:realClear()
            self["pageInitStatus"][k] = false
        end
    end

    self.selectpage = self.pageconfig[1]
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function tokenMain.init(self, parent, toppos, param)
	self:initNode(parent, toppos)
    self:initSelectPage()
    self:shiftPage(self.selectPage, param)
end

function tokenMain.initSelectPage(self, param)
    if param and param.page then
        self.selectpage = param.page
    end
end

function tokenMain.initNode(self, parent, toppos)
	self.rootNode, self.rootItems = CCBReaderLoad("tianjiling/tianjiling_main", nil, true, "tianjiling_main")
	self.rootNode:setPosition(0,0)
	self.rootItems.topnode:setPosition(-999, toppos)
    self.toppos = toppos


    parent:addChild(self.rootNode)
end

function tokenMain.shiftPage(self, page, param)
    local page = page or self.selectpage

    if gameConfig:checkBuildOpen(self.build[page]) and GameScene:checkopenlevelbyId(self.build[page]) then
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonOFF)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(0)
        self.selectpage = page
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonON)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(1)

        if not self.pageInitStatus[self.selectpage] then
            local _node = self.modules[self.selectpage]:init(self.touchPriority - 1, self.toppos, param or {})

            self.pageInitStatus[self.selectpage] = true
            self.rootItems[self.selectpage.."Node"]:addChild(_node)
        end

        self:setPageNodeShow()
    else
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[page]], gameConfig.images.pageButtonOFF)
        self.rootItems["buttonnode"..self.pageconfigKey[page]]:setZOrder(0)
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonON)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(1)
    end
end

function tokenMain.setPageNodeShow(self)
    for k,v in pairs(self.pageconfig) do
        if v == self.selectpage then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPositionX(0)

            if self.shiftPageNeedRefresh[v] and self.modules[self.selectpage].refreshFunc then
                self.modules[self.selectpage]:refreshFunc()
            end
        else
            -- print("showNode is: "..v.."Node")
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPositionX(99999)
        end
    end
end

function tokenMain.pageDataCallback(self, page, funcName, params)
    if self.pageInitStatus[page] then
        self.modules[page][funcName](self.modules[page], params)
    end
end

return tokenMain