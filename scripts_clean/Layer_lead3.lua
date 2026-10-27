--
-- Author: songyibo
-- Date: 2019-05-27 11:09:03
--
local lead = {
    rootNode = nil,
    rootItems = nil,

    --加新页签需要加
    pageconfig = {"mogong","fashion","gamestar","wing","awaken","feisheng"},

    pagebuild = {467,1,203,213,567,466},

    --加新页签需要加
    pageconfigKey = {
        mogong      = 1,
        fashion     = 2,
        gamestar    = 3,
        wing        = 4,
        awaken      = 5,
        feisheng    = 6,
    },
    --加新页签需要加
    pagename = {
        gameConfig.strings:string_common("lead",12),
        gameConfig.strings:string_common("lead",13),
        gameConfig.strings:string_common("lead",14),
        gameConfig.strings:string_common("lead",15),
        gameConfig.strings:string_common("lead",17),
        gameConfig.strings:string_common("lead",16),
    },
    --加新页签需要加
    modules = {
        mogong      = require("Layer_lead2"),
        fashion     = require("Layer_fashion"),
        gamestar    = require("Layer_gamestar"),
        wing        = require("Layer_wing_main"),
        awaken      = require("Layer_protagonistAwaken"),
        feisheng    = require("Layer_generalFeiSheng"),
    },
    --加新页签需要加
    pageInitStatus = {
        mogong      = false,
        fashion     = false,
        gamestar    = false,
        wing        = false,
        awaken      = false,
        feisheng    = false,
    },
    --加新页签需要加
    shiftPageNeedRefresh = {
        mogong      = true,
        fashion     = false,
        gamestar    = false,
        wing        = true,
        awaken      = true,
        feisheng    = true,
    },
    --加新页签需要加
    build = {
        mogong      = 467,
        fashion     = 192,
        gamestar    = 203,
        wing        = 213,
        awaken      = 1,
        feisheng    = 466
    },

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            --加新页签需要加
            config = {
                title1 = {},
            },
        },
    },

    selectpage = "mogong",
    touchPriority = -102,
}

function lead.clear(self)
    for k,v in pairs(self.modules) do
        if self["pageInitStatus"][k] then
            v:clear()
            self["pageInitStatus"][k] = false
        end
    end

    self.selectpage = self.pageconfig[1]
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function lead.init(self, parent, toppos, param)
    self:initNode(parent, toppos, param)
    self:initSelectPage(param)
    self:shiftPage()
end

function lead.initNode(self, parent, toppos, param)
    self.rootNode, self.rootItems = CCBReaderLoad("devil/devil3", nil, true, "devil")
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)

    if not gameConfig:checkBuildOpen(449) then
        self.rootItems.buttonnode5:setVisible(false)
        self.rootItems.button5:setTouchEnabled(false)
    else
        self.rootItems.buttonnode5:setVisible(true)
        self.rootItems.button5:setTouchEnabled(true)
    end

end

function lead.initSelectPage(self, param)
    if param and param.page then
        self.selectpage = param.page
    end
end

function lead.shiftPage(self, page)
    local page = page or self.selectpage

    if gameConfig:checkBuildOpen(self.build[page]) and GameScene:checkopenlevelbyId(self.build[page]) then
        -- self[self.pageByRequireName[self.selectpage]]:clear()
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonOFF)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(0)
        self.selectpage = page
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonON)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(1)
        if not self.pageInitStatus[self.selectpage] then
            self.modules[self.selectpage]:init(self.rootItems[self.selectpage.."Node"], self.toppos)
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

function lead.setPageNodeShow(self)
    for k,v in pairs(self.pageconfig) do
        if v == self.selectpage then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPositionX(540)

            if self.shiftPageNeedRefresh[v] and self.modules[self.selectpage].refreshFunc then
                self.modules[self.selectpage]:refreshFunc()
            end
        else
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPositionX(99999)
        end
    end


end


function lead.pageDataCallback(self,page,funcName,params)
    if self.pageInitStatus[page] then
        self.modules[page][funcName](self.modules[page],params)
    end
end

return lead
