local godSoulTemple = {
	rootNode = nil,
    rootItems = nil,

    --伙伴
    pageconfig = {"gold", "tortoise", "none", "huolingshi"},

    --加新页签需要加
    modules = {
    	gold = require("page_god_soul_temple_gold"),
    	tortoise = require("page_god_soul_temple_tortoise"),
    	none = require("page_god_soul_temple_none"),
        huolingshi = require("page_god_soul_temple_huolingshi"),
    },
	
    --加新页签需要加
    pageconfigKey = {
        gold = 1,
        tortoise = 2,
        none = 3,
        huolingshi = 4,
    },
    --加新页签需要加
    pagename = {
        gameConfig.strings:string_common("godSoulTemple", "pageName", 1),
        gameConfig.strings:string_common("godSoulTemple", "pageName", 2),
        gameConfig.strings:string_common("godSoulTemple", "pageName", 3),
        gameConfig.strings:string_common("godSoulTemple", "pageName", 4),
    },
    
    --加新页签需要加
    pageInitStatus = {
    	gold = false,
    	tortoise = false,
    	none = false,
        huolingshi = false,
    },
    --加新页签需要加
    build = {
        gold = 526,
        tortoise = 527,
        none = 528,
        huolingshi = 602,
    },

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            --加新页签需要加
            config = {
                title1 = {526},
                title2 = {527},
                title3 = {528},
                title4 = {602},
            },
        },
    },

    selectpage = "gold",
    touchPriority = -102,

    generals = {},
    hintdata = {},
}

function godSoulTemple.clear(self)
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

function godSoulTemple.init(self, parent, toppos, param)
	self:initNode(parent, toppos, param)
	self:initConfig()
	self:initSelectPage(param)
    self:shiftPage()
end

function godSoulTemple.initNode(self, parent, toppos, param)
	self.rootNode, self.rootItems = CCBReaderLoad("shenhundian/shenhundian", nil, true, "shenhundian")
    self.rootNode:setPosition(-540,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
end

function godSoulTemple.initConfig(self)
	self.generalConfig = gamedata.config.general
end

function godSoulTemple.initSelectPage(self, param)
	if param and param.page then
        self.selectpage = param.page
    end
    if param and param.hintdata then
        self.hintdata = param.hintdata
        for k,v in pairs(self.hintdata) do
            printT(v,k)
            if v["isshowHint"] == 1 then
                local pageid = v["id"] or 1
                local page = 0
                if pageid == "18" then
                    page = 1
                elseif pageid == "20" then
                    page = 2
                elseif pageid == "23" then
                    page = 3
                elseif pageid == "44" then
                    page = 4
                end   
                print("showHint:"..page)
                self:setHint(page,true)
            end  
        end

    end
end

function godSoulTemple.shiftPage(self, page)
    local page = page or self.selectpage

    if gameConfig:checkBuildOpen(self.build[page]) and GameScene:checkopenlevelbyId(self.build[page]) then
    	self.modules[self.selectpage]:clear()
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonOFF)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(0)
    	self.selectpage = page
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonON)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(1)

    	if not self.pageInitStatus[self.selectpage] then
    		-- self.modules[self.selectpage]:setData(self.genralsLevel2ByBasic)
        	local _ccbNode = self.modules[self.selectpage]:init(self.touchPriority, self.toppos)
        	self.rootItems[self.selectpage.."Node"]:addChild(_ccbNode)
        	self.pageInitStatus[self.selectpage] = true
        end

    	self:setPageNodeShow()
    else
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[page]], gameConfig.images.pageButtonOFF)
        self.rootItems["buttonnode"..self.pageconfigKey[page]]:setZOrder(0)
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonON)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(1)
    end
end

function godSoulTemple.setPageNodeShow(self)
	for k,v in pairs(self.pageconfig) do
		if v == self.selectpage then
			self.rootItems[v.."Node"]:setVisible(true)
			self.rootItems[v.."Node"]:setPositionX(0)
		else
			self.rootItems[v.."Node"]:setVisible(false)
			self.rootItems[v.."Node"]:setPositionX(99999)
		end
	end
end

function godSoulTemple.pageDataCallback(self,page,funcName,params)
	if self.pageInitStatus[page] then
		self.modules[page][funcName](self.modules[page], params)
	end
end

function godSoulTemple.setHint(self,page,ishint)
    if page then
        print("setHint",page)
        ui.sethint(self.rootItems["hint_title"..page],ishint)
        print("setHint hashit",ishint)
    end    
end

return godSoulTemple