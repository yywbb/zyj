--
-- Author: songyibo
-- Date: 2019-05-27 11:09:03
--
local mochonglead = {
	rootNode = nil,
    rootItems = nil,

    --加新页签需要加
    -- pageconfig = {"mochong","shengji","jinjie","tunshi"},
    pageconfig = {"mochong","shengji","jinjie"},
    --加新页签需要加
    pageconfigKey = {
        mochong      = 1,
        shengji     = 2,
        jinjie 	= 3,
        -- tunshi 		= 4,
    },
    --加新页签需要加
    pagename = {
        gameConfig.strings:string_common("devour",21),
        gameConfig.strings:string_common("devour",22),
        gameConfig.strings:string_common("devour",23),
        -- gameConfig.strings:string_common("devour",24),

    },
    --加新页签需要加
    modules = {
		mochong 		= require("Layer_devour5"),
		shengji 	= require("Layer_devourcollect_up"),
		jinjie 	= require("Layer_devourcollect_jinjie"),
		-- tunshi 		= require("Layer_devourcollect"),
    },
    --加新页签需要加
    pageInitStatus = {
    	mochong 		= false,
		shengji 	= false,
		jinjie 	= false,
		-- tunshi 		= false,
    },
    --加新页签需要加
    shiftPageNeedRefresh = {
       mochong      = false,
        shengji     = true,
        jinjie  = true,
        -- tunshi      = true,
    },
    --加新页签需要加
    build = {
        mochong      = 49,
        shengji     = 49,
        jinjie    = 49,
        -- tunshi        = 49,
    },

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            --加新页签需要加
            config = {
                title1 = {},
                title3 = {}
            },
        },
    },

    selectpage = "mochong",
    touchPriority = -102,

    cacheData ={
        mochong  = {},
        shengji  = {},
        jinjie   = {},
        -- tunshi   = {},
   },
    petsData = {},
    isgray = false,
   PromptString ={
       notopen = "吞噬功能未开启！",
       notmochong = "请先上阵魔宠！"
    }
}

function mochonglead.clear(self)
    print("mochonglead.clear")
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

function mochonglead.init(self, parent, toppos, param)
	self:initNode(parent, toppos, param)
	self:initSelectPage(param)
    self:shiftPage()
    self:reloadHint()
end

function mochonglead.initNode(self, parent, toppos, param)
	self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochong_yeqian", nil, true, "mochong")
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
end

function mochonglead.toPage(self,param)
    print("toPage")
    setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonOFF)
    if param and param.page then
        self.selectpage = param.page
    end
    self:shiftPage()
    self:reloadHint()
end
function mochonglead.initSelectPage(self, param)
	if param and param.page then
        self.selectpage = param.page
    end
end

function mochonglead.shiftPage(self, page)
    print("mochonglead.shiftPage",page)
    if page == "shengji" or page == "jinjie" then
        if table.getTableLength(self.petsData) < 1 then
            runGamePrompt({msg = self.PromptString["notmochong"]}) 
            return
        end    
    end    
    if page == "tunshi" then
        runGamePrompt({msg = self.PromptString["notopen"]}) 
        return
    end   

    local page = page or self.selectpage
    if gameConfig:checkBuildOpen(self.build[page]) and GameScene:checkopenlevelbyId(self.build[page]) then
    	-- self[self.pageByRequireName[self.selectpage]]:clear()
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonOFF)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(0)
    	self.selectpage = page
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonON)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(1)
        if not self.pageInitStatus[self.selectpage] then
            print("shiftPage:",self.selectpage)
            if  page == "shengji" then
                local  petcid = self.allPetsData.pets[tostring(self.allPetsData.iid)].cid
                print(petcid,"petcid")
                -- GameScene:shiftLayer("devourcollectup",nil,{petData = table.copy(self.petsData[tostring(v.cid)]), petFragmentData = table.copy(self.petFragmentData),allPetsData = self.allPetsData})
                self.modules[self.selectpage]:init(self.rootItems[self.selectpage.."Node"], self.toppos,{petData = table.copy(self.petsData[tostring(petcid)]),petFragmentData = self.petFragmentData, allPetsData = self.allPetsData})
            elseif page == "jinjie" then
                local  petcid = self.allPetsData.pets[tostring(self.allPetsData.iid)].cid
                print(petcid,"petcid")
                self.modules[self.selectpage]:init(self.rootItems[self.selectpage.."Node"], self.toppos,{petData = table.copy(self.petsData[tostring(petcid)]),petFragmentData = self.petFragmentData, allPetsData = self.allPetsData})
                -- self.modules[self.selectpage]:init(self.rootItems[self.selectpage.."Node"], self.toppos)
                -- if GameScene.layers["devil"].show then
                --     GameScene.layers["devil"].module:pageDataCallback("jinjie","shiftNode","advanceNode")
                -- end  
            elseif page == "tunshi" then
                runGamePrompt({msg = self.PromptString["notopen"]}) 
                return
            else
                self.modules[self.selectpage]:init(self.rootItems[self.selectpage.."Node"], self.toppos)
            end
        	self.pageInitStatus[self.selectpage] = true
        end
    	self:setPageNodeShow()
    else
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[page]], gameConfig.images.pageButtonOFF)
        self.rootItems["buttonnode"..self.pageconfigKey[page]]:setZOrder(0)
        setSpriteFrameByName(self.rootItems["buttonsprite"..self.pageconfigKey[self.selectpage]], gameConfig.images.pageButtonON)
        self.rootItems["buttonnode"..self.pageconfigKey[self.selectpage]]:setZOrder(1)
    end
    
    -- if self.rootItems["buttonsprite"..self.pageconfigKey["tunshi"]] and not self.isgray then
    --     ui.addGray("CCSprite",self.rootItems["buttonsprite"..self.pageconfigKey["tunshi"]])
    --     ui.addGray("CCNode",self.rootItems["buttonnode"..self.pageconfigKey[page]])
    --     self.isgray = true
    -- end    

end

function mochonglead.setPageNodeShow(self)
	for k,v in pairs(self.pageconfig) do
		if v == self.selectpage then
			self.rootItems[v.."Node"]:setVisible(true)
			self.rootItems[v.."Node"]:setPositionX(540)
            print("setPageNodeShow1") 
            if self.shiftPageNeedRefresh[v] and self.modules[self.selectpage].refreshFunc then
                print("setPageNodeShow2")
                if self.selectpage == "shengji" then
                    local  petcid = self.allPetsData.pets[tostring(self.allPetsData.iid)].cid
                    print(petcid,"petcid")
                    self.modules[self.selectpage]:refreshFunc(table.copy(self.petsData[tostring(petcid)]))
                elseif self.selectpage == "jinjie" then
                    local  petcid = self.allPetsData.pets[tostring(self.allPetsData.iid)].cid
                    print(petcid,"petcid")
                    self.modules[self.selectpage]:refreshFunc(table.copy(self.petsData[tostring(petcid)]))
                    -- if GameScene.layers["devil"].show then
                    --     self.modules[self.selectpage]:refreshFunc()
                    -- end    
                else
                    self.modules[self.selectpage]:refreshFunc()
                end      
            end
            -- if self.selectpage == "jinjie" then
            --     if GameScene.layers["devil"].show then
            --         GameScene.layers["devil"].module:pageDataCallback("jinjie","shiftNode","advanceNode")
            --     end    
            -- end    
		else
			self.rootItems[v.."Node"]:setVisible(false)
			self.rootItems[v.."Node"]:setPositionX(99999)
		end
	end


end

function mochonglead.setHint(self,page,ishint)
    print("setHint",page)
    ui.sethint(self.rootItems["hint_title"..self.pageconfigKey[page]],ishint)
    print("setHint hashit",ishint)
end

function mochonglead.reloadHint(self)
    if not self.petFragmentData or not self.allPetsData then return end
    ui.sethint(self.modules["mochong"].rootItems["hint_bag"], false)
    local fun = function(cid)
        for k, v in pairs(self.allPetsData.pets) do
            if (tonumber(gamedata.config.pet3_fragment[tostring(cid)].petid) == tonumber(v.cid)) then
                return true
            end
        end
        return false
    end
    for k, v in pairs(self.petFragmentData) do
        if (not fun(v.cid)) and v.num >= tonumber(gamedata.config.pet3_fragment[tostring(v.cid)].number) then
            ui.sethint(self.modules["mochong"].rootItems["hint_bag"], true)
        end 
    end
end

function mochonglead.pageDataCallback(self,page,funcName,params)
	if self.pageInitStatus[page] then
		self.modules[page][funcName](self.modules[page],params)
	end
end


function mochonglead.pageDataChange(self,data,witch)
    printT(self.petFragmentData,"pageDataChange")
    if witch == "petFragmentData" then
        for k,v in pairs(data) do
            if self.petFragmentData then
                 for p,w in pairs(self.petFragmentData) do
                    if tonumber(w.cid) == tonumber(k) then
                         print("pageDataChange2 v:",v)
                         self.petFragmentData[tostring(w.cid)].num = v
                    end
                 end
            end    
        end  
    elseif witch == "petsData" then

    end  
    self:reloadHint()  
end


function mochonglead.pageDataSend(self,page,params)
    printT(params,"pageDataSend===")
    if page == "mochongdata" then
        if params.petFragmentData then self.petFragmentData = params.petFragmentData end
        if params.petsData then 
            self.allPetsData = params.petsData 
            self.petsData = {}
            for k,v in pairs(self.allPetsData.pets) do
                if self.petsData[tostring(v.cid)] == nil then
                    self.petsData[tostring(v.cid)] = {}
                end
                self.petsData[tostring(v.cid)] = v
            end
        end
    end    
    self:reloadHint()
    printT(self.petsData,"petsData")
end

return mochonglead  �*  