--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local favoritetransfer = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

}

function favoritetransfer.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.rootNode, self.rootItems = CCBReaderLoad("love/love_chage", nil, true, "love_chage")
    self.root:addChild(self.rootNode)

    self:reload(data)
    return self.root
end

function favoritetransfer.reload(self, data )
    self.data = data or {}

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("favoritetransfer")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.dotext,gameConfig.strings:string_common("favoritegeneral",22),19)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        if self.data.source and self.data.dest then
            local maxlevel = math.max(self.data.source.level, self.data.dest.level)
            local levelconfig = gamedata.config.favorable_level[tostring(maxlevel)]
            local golddes = levelconfig and levelconfig.favor_exchange_price or "1001,0;"
            local id,gold = ui.getIDandNUM(golddes)
            if GameScene.roleinfo.gold<gold then
                shortGold()
            else
                if self.data.source.level == 0  and self.data.dest.level == 0 then
                    runGamePrompt({msg = gameConfig.strings:string_common("favoritegeneral",32)})
                else
                    if self.data.source.level == self.data.dest.level then
                        runGamePrompt({msg = "好感度相同，不可替换"})
                    else
                        UIRequest({type =3675, cid1 = self.data.source.cid,cid2 = self.data.dest.cid})
                        gameWindows:closeWindow("favoritetransfer")
                    end
                    
                end
            end
        else
            runGamePrompt({msg = gameConfig.strings:string_common("favoritegeneral",23)})
        end
        
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)

    local constcid = 0
    if self.data.source then
        self.rootItems.sourcebutton:addHandleOfControlEvent(function()
            runGamePrompt({msg =gameConfig.strings:string_common("favoritegeneral",33)})
        end, CCControlEventTouchUpInside)
        self.rootItems.sourcebutton:setSwallowsTouch(true)
        self.rootItems.sourcebutton:setTouchPriority(self.touchPriority)
        constcid = self.data.source.hascid > 0 and self.data.source.hascid or self.data.source.cid
    else
        self.rootItems.sourcebutton:addHandleOfControlEvent(function()
            local cb = function()
                self:setSource()
                self:setDest()
                self:setgold()
            end
            self.data.source = nil
            gameWindows:openWindow("favoritetransferselect",{listdata = data.listdata,data=self.data,constcid=constcid},cb)
        end, CCControlEventTouchUpInside)
        self.rootItems.sourcebutton:setSwallowsTouch(true)
        self.rootItems.sourcebutton:setTouchPriority(self.touchPriority)
    end


    if self.data.dest then
        self.rootItems.destbutton:addHandleOfControlEvent(function()
            runGamePrompt({msg =gameConfig.strings:string_common("favoritegeneral",33)})
        end, CCControlEventTouchUpInside)
        self.rootItems.destbutton:setSwallowsTouch(true)
        self.rootItems.destbutton:setTouchPriority(self.touchPriority)
        constcid = self.data.dest.hascid > 0 and self.data.dest.hascid or self.data.dest.cid
    else
        self.rootItems.destbutton:addHandleOfControlEvent(function()
            local cb = function()
                self:setSource()
                self:setDest()
                self:setgold()
            end
            self.data.dest = nil
            gameWindows:openWindow("favoritetransferselect",{listdata = data.listdata,data=self.data,constcid=constcid},cb)
        end, CCControlEventTouchUpInside)
        self.rootItems.destbutton:setSwallowsTouch(true)
        self.rootItems.destbutton:setTouchPriority(self.touchPriority)
    end

    self:setSource()
    self:setDest()
    self:setgold()
end

function favoritetransfer.setgold( self )
    local sourcelevel = self.data.source and self.data.source.level or 0
    local destlevel = self.data.dest and self.data.dest.level or 0
    local maxlevel = math.max(sourcelevel,destlevel)
    local levelconfig = gamedata.config.favorable_level[tostring(maxlevel)]
    local golddes = levelconfig and levelconfig.favor_exchange_price or "1001,0;"
    local id,num = ui.getIDandNUM(golddes)
    ui.setLabelString(self.rootItems.gold,num,GameScene.roleinfo.gold<num and 11 or 23)
end

function favoritetransfer.setSource( self )
    self.rootItems.isSelect:setVisible(false)
    if self.data.source then
        self.rootItems.sourseadd:setVisible(false)
        self.rootItems.sourse:setVisible(true)
        --
        local generalsdata = {}
        if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
            generalsdata = table.copy(GameScene.layers["generals"].module.generalsdata)
        end 

        local cid = self.data.source.hascid > 0 and self.data.source.hascid or self.data.source.cid
        -- 设置头像
        local configGeneral = gamedata.config.general[tostring(cid)]
        local gicon = configGeneral.icon
        if configGeneral.fashion_id == 0 then --非时装
            for k,v in pairs(generalsdata) do
                if cid == v.cid then
                    if v.illusionGeneralCid == nil then
                        local gdata = ui.getConfigGeneral(v)
                        gicon = gdata.icon
                    end
                    break
                end
            end
        end
        ui.setNewIconName(self.rootItems,{cid = cid, icon = gicon})
        self.rootItems.onteamNode:setVisible(self.data.source.ison >0)
        self.rootItems.onteamLab:setString(gameConfig.strings:string_common("favoritegeneral",30))
        ui.setLabelString(self.rootItems.favoriteNum,self.data.source.level,22)
    else
        self.rootItems.sourseadd:setVisible(true)
        self.rootItems.sourse:setVisible(false)
        ui.blink(self.rootItems.sourseadd,1)
    end
end

function favoritetransfer.setDest( self )
    self.rootItems.isSelect_1:setVisible(false)
    if self.data.dest then
        self.rootItems.destadd:setVisible(false)
        self.rootItems.dest:setVisible(true)
        --
        local generalsdata = {}
        if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
            generalsdata = table.copy(GameScene.layers["generals"].module.generalsdata)
        end 

        local cid = self.data.dest.hascid > 0 and self.data.dest.hascid or self.data.dest.cid
        -- 设置头像
        local configGeneral = gamedata.config.general[tostring(cid)]
        local gicon = configGeneral.icon
        if configGeneral.fashion_id == 0 then --非时装
            for k,v in pairs(generalsdata) do
                if cid == v.cid then
                    if v.illusionGeneralCid == nil then
                        local gdata = ui.getConfigGeneral(v)
                        gicon = gdata.icon
                    end
                    break
                end
            end
        end
        ui.setNewIconName(self.rootItems,{cid = cid, icon = gicon},1)
        self.rootItems.onteamNode_1:setVisible(self.data.dest.ison >0)
        self.rootItems.onteamLab_1:setString(gameConfig.strings:string_common("favoritegeneral",30))
        ui.setLabelString(self.rootItems.favoriteNum_1,self.data.dest.level,22)
    else
        self.rootItems.destadd:setVisible(true)
        self.rootItems.dest:setVisible(false)
        ui.blink(self.rootItems.destadd,1)
    end
end


function favoritetransfer.close(self)
  
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

end

return favoritetransfer