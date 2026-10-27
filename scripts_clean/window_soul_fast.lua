--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/2/9
-- Time: 10:42
-- To change this template use File | Settings | File Templates.
--

local soulfast = {
    rootNode = nil,
    rootItems = nil,

    param1 = 1,
    param2 = 1,
    param3 = 1,

}

function soulfast.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("soul2/soul2_fast", nil, true, "soulfast")
    self.touchPriority = touchPriority

    self.rootItems.title:setString(gameConfig.strings:string_common("soul",17))
    ui.setLabelString(self.rootItems.LabSelect1,nil,3)
    ui.setLabelString(self.rootItems.LabSelect2,nil,5)
    ui.setLabelString(self.rootItems.LabSelect3,nil,7)
    ui.setLabelString(self.rootItems.selectDesc,gameConfig.strings:string_common("soul",18),1)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("soul",19),19)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("soul",20),19)
    ui.setLabelString(self.rootItems.doLab3,gameConfig.strings:string_common("soul",21),19)

    self:reload(data,callback)
    return self.rootNode
end

function soulfast.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("soulfast")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --

    for i = 1,3 do
        if self["param"..i] and self["param"..i] == 1 then
            self.rootItems["isSelect"..i]:setVisible(true)
        else
            self.rootItems["isSelect"..i]:setVisible(false)
        end
        self.rootItems["btnSelect"..i]:addHandleOfControlEvent(function()
            if self["param"..i] and self["param"..i] == 1 then
                self["param"..i] = 0
            else
                self["param"..i] = 1
            end
            self.rootItems["isSelect"..i]:setVisible(self["param"..i] == 1)
        end, CCControlEventTouchUpInside)
        self.rootItems["btnSelect"..i]:setSwallowsTouch(true)
        self.rootItems["btnSelect"..i]:setTouchPriority(self.touchPriority)
    end

    --
    if data and data.hunt and data.hunt == 6 then
        self.rootItems.coinSprite1:setVisible(false)
        self.rootItems.coinSprite2:setVisible(false)
        self.rootItems.coinSprite3:setVisible(false)
        self.rootItems.goldSprite1:setVisible(true)
        self.rootItems.goldSprite2:setVisible(true)
        self.rootItems.goldSprite3:setVisible(true)
        if self.rootItems.doNode3 then
            self.rootItems.doNode3:setVisible(false)
            self.rootItems.doNode1:setPositionX(-200)
            self.rootItems.doNode2:setPositionX(200)
            self.rootItems.doNode3:setPositionX(9999)
        end    
    else
        self.rootItems.coinSprite1:setVisible(true)
        self.rootItems.coinSprite2:setVisible(true)
        self.rootItems.coinSprite3:setVisible(true)
        self.rootItems.goldSprite1:setVisible(false)
        self.rootItems.goldSprite2:setVisible(false)
        self.rootItems.goldSprite3:setVisible(false)
        if self.rootItems.doNode3 then
            self.rootItems.doNode3:setVisible(true)
            self.rootItems.doNode1:setPositionX(-300)
            self.rootItems.doNode2:setPositionX(0)
            self.rootItems.doNode3:setPositionX(300)
        end    
    end

    local id,num10,num100,num1000 = 20617,10,100,1000
    if data.hunt == 6 then
        local config = gamedata.config.gambling_items[tostring(GameScene.layers["soul"].module.systemId)]["1"]
        if config then
            id,num10 = ui.getIDandNUM(config.tenfold2)
            id,num100 = ui.getIDandNUM(config.hundredfold2)
            --id,num1000 = ui.getIDandNUM(config.thousandfold2)
            ui.setLabelString(self.rootItems.xNum1,num10 or 0,14)
            ui.setLabelString(self.rootItems.xNum2,num100 or 0,14)
            ui.setLabelString(self.rootItems.xNum3,num1000 or 0,14)
        end
    else
        ui.setLabelString(self.rootItems.xNum1,data.xnum and data.xnum*10 or 0,14)
        ui.setLabelString(self.rootItems.xNum2,data.xnum and data.xnum*100 or 0,14)
        ui.setLabelString(self.rootItems.xNum3,data.xnum and data.xnum*1000 or 0,14)
    end
   

    --
    local needvip = 0
    for i = 1, table.getTableLength(gamedata.config.vip) do
        if gamedata.config.vip[tostring(i)] and gamedata.config.vip[tostring(i)].hundred_soul_hunt and gamedata.config.vip[tostring(i)].hundred_soul_hunt > 0 then
            needvip = i
            break
        end
    end
    local needlevel = 0
    if gamedata.config.global_kv.hundred_soul_hunt_level_limit and gamedata.config.global_kv.hundred_soul_hunt_level_limit.value then
        needlevel = tonumber(gamedata.config.global_kv.hundred_soul_hunt_level_limit.value)
    end

    --ui.setLabelString(self.rootItems.openDesc,gameConfig.strings:SoulHunt100Limit(needlevel,needvip),3)
    if data.hunt == 6 then
        ui.setLabelString(self.rootItems.openDesc," "..needlevel .. "级或VIP" .. needvip .. "开启猎命百次 ",3)
    else
        ui.setLabelString(self.rootItems.openDesc," "..needlevel .. "级或VIP" .. needvip .. "开启猎命百次和猎命千次 ",3)
    end    
    --

    self.rootItems.doButton1:addHandleOfControlEvent(function()
        if data.hunt == 6 and num10 > GameScene.layers["soul"].module.itemNum then
            gameWindows:openWindow("buyItem",{id = GameScene.layers["soul"].module.itemId or 20612,num = GameScene.layers["soul"].module.itemNum},function (data)
                if data.id == GameScene.layers["soul"].module.itemId then
                    GameScene.layers["soul"].module:setItemNum({[tostring(data.id)] = data.num})
                end
            end)
            return
        end
        gameTouch:clickprofbytime(1)
        UIRequest({type = 2502, param = data.hunt*10, param1 = self.param1, param2 = self.param2,param3 = self.param3,useId = GameScene.layers["soul"].module.itemId,
    useNum = data.hunt == 6 and num10 or 0})
        gameWindows:closeWindowDirect("soulfast")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    if GameScene.roleinfo.level >= needlevel or GameScene.roleinfo.vip >= needvip then
        ui.removeGray("CCControlButton",self.rootItems.doButton2)
        self.rootItems.doButton2:addHandleOfControlEvent(function()
            if data.hunt == 6 and num100 > GameScene.layers["soul"].module.itemNum then
                gameWindows:openWindow("buyItem",{id = GameScene.layers["soul"].module.itemId or 20612,num = GameScene.layers["soul"].module.itemNum},function (data)
                    if data.id == GameScene.layers["soul"].module.itemId then
                        GameScene.layers["soul"].module:setItemNum({[tostring(data.id)] = data.num})
                    end
                end)
                return
            end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 2502, param = data.hunt*100, param1 = self.param1, param2 = self.param2,param3 = self.param3,useId = GameScene.layers["soul"].module.itemId,
            useNum = data.hunt == 6 and num100 or 0})
            gameWindows:closeWindowDirect("soulfast")
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton2:setSwallowsTouch(true)
        self.rootItems.doButton2:setTouchPriority(self.touchPriority)

        ui.removeGray("CCControlButton",self.rootItems.doButton3)
        self.rootItems.doButton3:addHandleOfControlEvent(function()
            if data.hunt == 6 and num1000 > GameScene.layers["soul"].module.itemNum then
                gameWindows:openWindow("buyItem",{id = GameScene.layers["soul"].module.itemId or 20612,num = GameScene.layers["soul"].module.itemNum},function (data)
                    if data.id == GameScene.layers["soul"].module.itemId then
                        GameScene.layers["soul"].module:setItemNum({[tostring(data.id)] = data.num})
                    end
                end)
                return
            elseif gamedata.config.soul_thousand and gamedata.config.soul_thousand["1"].consumption_limit and gamedata.config.soul_thousand["1"].consumption_limit > GameScene.roleinfo.coin then
                runGamePrompt({msg = "持有银币大于"..math.floor(gamedata.config.soul_thousand["1"].consumption_limit/10000).."万可继续猎命"})
                return
            end
            gameTouch:clickprofbytime(1)
            if self.param1 == 1 and self.param2 == 1 and self.param3 == 1 then
                UIRequest({type = 2502, param = data.hunt*1000, param1 = self.param1, param2 = self.param2,param3 = self.param3,useId = GameScene.layers["soul"].module.itemId,
                useNum = data.hunt == 6 and num1000 or 0})
                gameWindows:closeWindowDirect("soulfast")
            else
                runGamePrompt({msg = "需要勾选全部自动分解后猎命"})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton3:setSwallowsTouch(true)
        self.rootItems.doButton3:setTouchPriority(self.touchPriority)

    else
        ui.addGray("CCControlButton",self.rootItems.doButton2)
        self.rootItems.doButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            --runGamePrompt({msg = gameConfig.strings:SoulHunt100Limit(needlevel,needvip)})
            if data.hunt == 6 then
                runGamePrompt({msg = " "..needlevel .. "级或VIP" .. needvip .. "开启猎命百次 "})
            else
                runGamePrompt({msg = " "..needlevel .. "级或VIP" .. needvip .. "开启猎命百次和猎命千次 "})
            end  
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton2:setSwallowsTouch(true)
        self.rootItems.doButton2:setTouchPriority(self.touchPriority)

        ui.addGray("CCControlButton",self.rootItems.doButton3)
        self.rootItems.doButton3:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            --runGamePrompt({msg = gameConfig.strings:SoulHunt100Limit(needlevel,needvip)})
            runGamePrompt({msg = " "..needlevel .. "级或VIP" .. needvip .. "开启猎命百次和猎命千次 "})
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton3:setSwallowsTouch(true)
        self.rootItems.doButton3:setTouchPriority(self.touchPriority)

    end

end

function soulfast.close(self)
    self.param1 = 1
    self.param2 = 1
    self.param3 = 1
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return soulfast

