local change = {
    --加新页签需要加
    pageGeneralChange = require("page_general_change"),
    pageSwapChange = require("page_swap_change"),

	rootNode = nil,
    rootItems = nil,

    --加新页签需要加
    --伙伴
    pageconfig = {"General", "Swap"},
    --加新页签需要加
    pageconfigKey = {
        General = 1,
        Swap = 2,
    },
    --加新页签需要加
    pagename = {
        gameConfig.strings:string_common("change", "pageName", 1),
        gameConfig.strings:string_common("change", "pageName", 2),
    },
    --加新页签需要加
    pageByRequireName = {
        General = "pageGeneralChange",
        Swap = "pageSwapChange",
    },
    --加新页签需要加
    pageNotInitStatus = {
        General = true,
        Swap = true,
    },
    --加新页签需要加
    build = {
        General = 597,
        Swap = 598,
    },

    pagebuild = {597,598},

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            --加新页签需要加
            config = {
                title1 = {597},
                title2 = {598},
            },
        },
    },

    selectpage = "General",
    touchPriority = -102,
}

function change.clear(self)
	for k,v in pairs(self.pageByRequireName) do
    	self[v]:realClear()
        self["pageNotInitStatus"][k] = true
    end
	self.selectpage = self.pageconfig[1]
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function change.init(self, parent, toppos, param)
	self:initNode(parent, toppos, param)
	self:initSelectPage(param)
	self:shiftPage()
end

function change.initNode(self, parent, toppos, param)
	self.rootNode, self.rootItems = CCBReaderLoad("zhuanhuan/wujiangzhuanhuan", nil, true, "wujiangzhuanhuan")
    self.rootNode:setPosition(-540,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
end

function change.initSelectPage(self, param)
	if param and param.page then
        self.selectpage = param.page
    end
end

function change.shiftPage(self, page)

    if self.selectpage == page then return end
    
    local page = page or self.selectpage

    print("page == ", page)
    if gameConfig:checkBuildOpen(self.build[page]) and GameScene:checkopenlevelbyId(self.build[page]) then
    	self[self.pageByRequireName[self.selectpage]]:clear()
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonOFF)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(0)
    	self.selectpage = page
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonON)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(1)

    	if self["pageNotInitStatus"][self.selectpage] then
    		local _node = self[self.pageByRequireName[self.selectpage]]:init(self.touchPriority, self.toppos)
    		self.rootItems[self.pageByRequireName[self.selectpage].."Node"]:addChild(_node)
    	end

    	self:setPageNodeShow()
    else
        print(gameConfig:checkBuildOpen(self.build[page]))
        print(GameScene:checkopenlevelbyId(self.build[page]))

        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[page]], gameConfig.images.pageButtonOFF)
        self.rootItems["buttonnode"..self.pageconfigKey[page]]:setZOrder(0)
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonON)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(1)
    end
end

function change.setPageNodeShow(self)
	for k,v in pairs(self.pageByRequireName) do
		if v == self.pageByRequireName[self.selectpage] then
			self.rootItems[v.."Node"]:setVisible(true)
		else
			self.rootItems[v.."Node"]:setVisible(false)
		end
	end
end

function change.setOffGeneralData(self, data)
    if self.selectpage == "General" then
        self.pageGeneralChange:setOffGeneralData(data)
    elseif self.selectpage == "Swap" then
        self.pageSwapChange:setOffGeneralData(data)
    end
end

function change.setOffGeneralRemoveData(self, data)
    if self.selectpage == "General" then
        self.pageGeneralChange:setOffGeneralRemoveData(data)
        self.pageGeneralChange:refreshNode("init")
    elseif self.selectpage == "Swap" then
        self.pageSwapChange:setOffGeneralRemoveData(data)
        self.pageSwapChange:refreshNode("init")
    end
end

function change.setGeneralChangePropNum(self, data)
    if self.selectpage == "General" then
        self.pageGeneralChange:setGeneralChangePropNum(data)
    elseif self.selectpage == "Swap" then
        self.pageSwapChange:setGeneralChangePropNum(data)
    end
end

function change.generalChange(self, data)
    if self.selectpage == "General" then
        self.pageGeneralChange:generalChange(data)
    elseif self.selectpage == "Swap" then
        self.pageSwapChange:generalChange(data)
    end
end

return change