--
-- Author: songyibo
-- Date: 2020-02-28 15:10:17
--

local awaken = {
    touchPriority  = -101
}

function awaken.init(self,parent,toppos,param)

    printT(GameScene.protagonist,"awaken")
    
    self.rootNode,self.rootItems = CCBReaderLoad("devil/juexing", nil, true, "juexing")
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.data = table.copy(GameScene.protagonist)
    self:setPage_awaken()
    self:loadGeneral()
    self:initFixedString()
end


function awaken.refreshFunc(self)
    print("refreshFunc_awaken")
    
    local hasdata = false
    local haschange = false
    if self.data.level2 and self.data.level2 > 0 then
        hasdata = true
        
        if GameScene.protagonist.train ~= self.data.train then
            haschange = true
        end
        if GameScene.protagonist.general and GameScene.protagonist.general.cid and ( GameScene.protagonist.general.cid ~= self.data.general.cid ) then
            haschange = true
        end

        if GameScene.protagonist.w_l ~= self.data.w_l or GameScene.protagonist.w_c ~= self.data.w_c then
            haschange = true
        end

        if GameScene.protagonist.general and GameScene.protagonist.general.level2 and ( GameScene.protagonist.general.level2 ~= self.data.general.level2 ) then
            haschange = true
        end

    end

    self.data = table.copy(GameScene.protagonist)
    self:setPage_awaken()

    local _str = CCUserDefault:sharedUserDefault():getStringForKey("useWingEffect"..GameScene.roleinfo.id)
    print("jkp-_str juexing == ",_str)
    if _str == "0" or _str == "1" then
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.data.general.cid)].animationid)].name
        if string.find(generalName,"zhujue") or string.find(generalName,"shizhuang") then
            hasdata = true
            haschange = true
        end
    end
    
    if (not hasdata) or haschange then
        self:loadGeneral()
    end

    printT(self.data)
end



function awaken.initFixedString(self)
    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("generalInfo",27),19) 
end

function awaken.loadGeneral(self)
    
    self.rootItems.generalNode:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.data.general.cid)].animationid)].name
    local wing = {level = self.data.w_l, illusionLevel = self.data.w_i, color = self.data.w_c}
    local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1.6)
    Gneral1:setPosition(0,0)
    self.rootItems.generalNode:addChild(Gneral1.root or Gneral1)


    if self.rootItems.name then
        self.rootItems.name:setString(ui.leadName(GameScene.protagonist.level2))
        if gamedata.config.general[tostring(self.data.general.cid)].quality and gamedata.config.general[tostring(self.data.general.cid)].quality >= 7 then
            ui.setLabelString(self.rootItems.name,nil, 213)
        else    
            ui.setLabelString(self.rootItems.name,nil, gamedata.config.general[tostring(self.data.general.cid)].quality~=0 and 2*gamedata.config.general[tostring(self.data.general.cid)].quality-1 or 1)
        end
    end
end

function awaken.setPage_awaken( self )
	self.awakenConfig = gamedata.config.protagonist_awaken
    if not self.data then return end
    local awakenConfig = self.awakenConfig[tostring(self.data.general.skilllevel + 1)]
    if awakenConfig ~= nil then
        self.rootItems.juexingcontrolnode:setPositionX(0)
        self.rootItems.juexing_title:setString(gameConfig.strings:string_common("general",36))
    else
        self.rootItems.juexingcontrolnode:setPositionX(9999)
        self.rootItems.juexing_title:setString(gameConfig.strings:string_common("general",35))
    end

    self:setAwakenNext()
 end

function awaken.setAwakenNext(self)

    local currentConfig = {}
    local nextConfig = {}

    local awakenConfig =  self.awakenConfig[tostring(self.data.general.skilllevel + 1)]

    if self.awakenConfig[tostring(self.data.general.skilllevel)] and self.data.general.skilllevel > 0 then
        table.insert(currentConfig ,{"atk",self.awakenConfig[tostring(self.data.general.skilllevel)].atk})

        table.insert(currentConfig ,{"def",self.awakenConfig[tostring(self.data.general.skilllevel)].def})

        table.insert(currentConfig ,{"hp",self.awakenConfig[tostring(self.data.general.skilllevel)].hp})

        table.insert(currentConfig ,{"adddmgpct",self.awakenConfig[tostring(self.data.general.skilllevel)].adddmgpct})

        table.insert(currentConfig ,{"subdmgpct",self.awakenConfig[tostring(self.data.general.skilllevel)].subdmgpct})
    end
    
    if awakenConfig then
    	table.insert(nextConfig ,{"atk",awakenConfig.atk})

        table.insert(nextConfig ,{"def",awakenConfig.def})

        table.insert(nextConfig ,{"hp",awakenConfig.hp})

        table.insert(nextConfig ,{"adddmgpct",awakenConfig.adddmgpct})

        table.insert(nextConfig ,{"subdmgpct",awakenConfig.subdmgpct})
    end

    local materialData = {}
    if awakenConfig then
    	local materialData =  ui.getIDandNUMs(awakenConfig.consume)  --需要的材料
    	local t = {}
    	for i,v in pairs(materialData) do
	        table.insert(t,tonumber(v.cid))  
	    end
	    UIRequest({type = 12001, order = 33018, cids = t})
    end

    
    if self.data.general.skilllevel <= 0 then
        self.rootItems.juexing:setVisible(false)
    else
        self.rootItems.juexing:setVisible(true)
        setSpriteFrameByName(self.rootItems.juexing_icon, self.awakenConfig[tostring(self.data.general.skilllevel)].icon )
        ui.setLabelString(self.rootItems.juexing_name, self.awakenConfig[tostring(self.data.general.skilllevel)].stage,18)    
    end


    if not  next(currentConfig) then
        self.rootItems.juexingattnode:setVisible(false) 
    else
        self.rootItems.juexingattnode:setVisible(true)

        self.rootItems.juexing_level:setString(self.awakenConfig[tostring(self.data.general.skilllevel)].name)
        
        for i=1,5 do
        	if currentConfig[i] then
        		ui.setLabelString( self.rootItems["juexing_attname"..i],gameConfig.strings:string_common("attr_type",currentConfig[i][1])..":",122)
	            ui.setLabelString( self.rootItems["juexing_att"..i],ui.getAttrValue(currentConfig[i][2]),14) 
	        else
	        	ui.setLabelString(self.rootItems["juexing_attname"..i],"",122)
	            ui.setLabelString(self.rootItems["juexing_att"..i],"",14) 
        	end
        end

    end
    if not next(nextConfig) then
        self.rootItems.juexingnextattnode:setVisible(false)    
    else
        self.rootItems.juexingnextattnode:setVisible(true)   
        self.rootItems.juexing_next_level:setString(awakenConfig.name)   
    
        for i=1,5 do
        	if nextConfig[i] then
        		ui.setLabelString( self.rootItems["juexing_next_attname"..i],gameConfig.strings:string_common("attr_type",nextConfig[i][1])..":",122)
	            ui.setLabelString( self.rootItems["juexing_next_att"..i],ui.getAttrValue(nextConfig[i][2]),23) 
	        else
	        	ui.setLabelString(self.rootItems["juexing_next_attname"..i],"",122)
	            ui.setLabelString(self.rootItems["juexing_next_att"..i],"",23) 
        	end
        end      
    end
    
end

function awaken.setAwakenConsume(self,t)

    local awakenConfig = self.awakenConfig[tostring(self.data.general.skilllevel + 1)]

    local goldNum = 0
    local goldCid = 1000

    local consume = ui.getIDandNUMs(awakenConfig["consume"])
    local showConsume = {}
    for i,v in ipairs(consume) do
        if v.cid ~= 1000 and v.cid ~= 1001 then
            table.insert(showConsume,v)
        else
            goldNum = v.num
            goldCid = v.cid
        end
    end

    if goldCid == 1000 then
        ui.setLabelString(self.rootItems.coin,goldNum,GameScene.roleinfo.coin>=goldNum and 14 or 47)
        setSpriteFrameByName(self.rootItems.coinIcon,"obj_s_coin")
    elseif goldCid == 1001 then
        ui.setLabelString(self.rootItems.coin,goldNum,GameScene.roleinfo.gold>=goldNum and 14 or 47)
        setSpriteFrameByName(self.rootItems.coinIcon,"obj_s_gold")
    end

    for i=1,5 do
        if showConsume[i] then
            self.rootItems["Material"..i]:setVisible(true)
            
            local havePropNum = t[tostring(showConsume[i].cid)] or 0
            local needPropNum = showConsume[i].num or 0

            local key_Ex
            if (i-1 == 0) then
                key_Ex = ""
            else
                key_Ex = "_"..(i-1)
            end
            ui.setNewIcon(self.rootItems,{cid =showConsume[i].cid},i-1)
             
            ui.setLabelString(self.rootItems["i_num"..key_Ex],havePropNum.."/"..needPropNum,havePropNum >= needPropNum and 13 or 27)

            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority - 1)
            self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(showConsume[i].cid)
            end, CCControlEventTouchUpInside)
        else
            self.rootItems["Material"..i]:setVisible(false)
        end
    end

    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority - 1)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        
        printT(self.data.general,"feisheng")
        --判断等级
        if self.data.general.level1 < awakenConfig.lv then
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("lead",18), awakenConfig.lv)})
            return
        end

        --判断突破
        if self.data.general.level2 < awakenConfig.breach then
            runGamePrompt({msg = string.format(gameConfig.strings:string_common("lead",19), gameConfig.strings:string_common("leadStageLevel",awakenConfig.breach))})
            return
        end
       
        --判断道具
        for i,v in ipairs(consume) do
            if not (t[tostring(v.cid)] and t[tostring(v.cid)] >= v.num) then
                local propconfig = ui.IDconfig(v.cid)
                runGamePrompt({msg = propconfig.name..gameConfig.strings:string_common("general",49)})
                return
            end
        end
        gameTouch:clickprofbytime(2)
        UIRequest({type = 1058,consume = consume})

    end, CCControlEventTouchUpInside)

end

function awaken.awakenCallback(self,data)
	local effectccb1,effectitem1 = CCBReaderLoad("UIEffect/huobantupo/n_huobantupo", nil, true, "n_huobantupo")

    local animationManager1 = getAnimationManager(effectitem1)
    animationManager1:runAnimationsForSequenceNamed("n_huobantupo")

    if effectitem1.topnode then
        effectitem1.topnode:removeFromParentAndCleanup(false)
        self.rootItems.effectnode_top:addChild(effectitem1.topnode)
    end
    if effectitem1.bottomnode then
        effectitem1.bottomnode:removeFromParentAndCleanup(false)
        self.rootItems.effectnode_bottom:addChild(effectitem1.bottomnode)
    end

    local sequence1 = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        gameWindows:openWindow("protagonistawakenfinish",data,nil)

        self.data = table.copy(GameScene.protagonist)
        self:setPage_awaken()

    end))
    self.rootItems.effectnode_top:runAction(sequence1)
end

function awaken.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

end


return awaken