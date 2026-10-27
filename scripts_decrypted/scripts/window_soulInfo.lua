--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/5
-- Time: 16:05
-- To change this template use File | Settings | File Templates.
--


local soulInfo = {
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"info","up"},
    pagetype = "info",

    hasup = 0,
}

function soulInfo.open(self,touchPriority,data,callback)

    self.root = ui.createNode()

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.root
end

function soulInfo.reload(self,data,callback)
    self.callback = callback
    self.data = data

    self.pagetype = data.pagetype or self.pagetype

    self:showPage(self.pagetype)

end

function soulInfo.reloaddata(self,data)
    if self.data and data.level > self.data.level then
        self.hasup = 1
    else
        self.hasup = 0
    end
    self.data = data or {}
    self.pagetype = data.pagetype or self.pagetype
    self:showPage(self.pagetype)

end

function soulInfo.close(self)
    self.hasup = 0
    self.pagetype = "info"
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function soulInfo.showPage(self,type)
    self.pagetype = type

    if self.pagetype == "info" then
        self.rootNode, self.infoItems = CCBReaderLoad("soul/soul_info", nil, true, "soul_info")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_info()
    elseif self.pagetype == "up" then
        self.rootNode, self.upItems = CCBReaderLoad("soul/soul_up", nil, true, "soul_up")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_up()
    end

end


function soulInfo.setPage_info(self)

    if not self.data.cid then self.data.cid = self.data.id end
    if not self.data.level then self.data.level = 1 end

    local config = ui.IDconfig(self.data.cid)
    ui.setIconLv(self.infoItems,self.data)

    self.infoItems.name:setString(config.name)
    ui.setLabelString(self.infoItems.name,nil,(config.quality or 1)*2-1)

    ui.setLabelString(self.infoItems.changeLab,nil,19)
    ui.setLabelString(self.infoItems.resolveLab,nil,19)
    ui.setLabelString(self.infoItems.upLab,nil,19)

    self.infoItems["type1"]:setString(gameConfig.strings.attr_type[config.attr1])
    self.infoItems["num1"]:setString("+"..(config["attr1_grow"..self.data.level] or 0)*(config.method1 == "value" and 1 or 100)..(config.method1 == "value" and "" or "%"))

    self.infoItems["type3"]:setString("强化等级")
    self.infoItems["num3"]:setString(self.data.level.."/"..config.limit1)

    if config.attr2 and config.attr2 ~= "" then
        self.infoItems["type2"]:setString(gameConfig.strings.attr_type[config.attr2])
        self.infoItems["num2"]:setString("+"..(config["attr2_grow"..self.data.level] or 0)*(config.method2 == "value" and 1 or 100)..(config.method2 == "value" and "" or "%"))
    else
        self.infoItems["type2"]:setString("")
        self.infoItems["num2"]:setString("")
    end

    self.infoItems.resolveButton:addHandleOfControlEvent(function()
        print("disapartButton clicked")
        gameTouch:clickprofbytime(0.5)
        if self.data.generalcid and self.data.generalcid > 0 then
            -- runGamePrompt({msg = "已经装备的物品无法被分解"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","equipfenjie")})
        else
            UIRequest({type = 2506, ids = {self.data.iid}})
            gamedata.music:PlayOptSound("fj")
            self.callback = nil
            gameWindows:closeWindow("soulInfo")
        end
    end, CCControlEventTouchUpInside)
    self.infoItems.resolveButton:setSwallowsTouch(true)
    self.infoItems.resolveButton:setTouchPriority(self.touchPriority)

    self.infoItems.changeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("soulInfo")
        local callback = function(selectedData)
            for k,v in pairs(selectedData) do
                UIRequest({type=1006,slot = self.data.sid, soulpos = self.data.soulpos, soulid = v.iid})
                break
            end
        end
        gameWindows:openWindow("selectlist",{type = "changesoul", param = {sid=self.data.sid,soulpos = self.data.soulpos,iid=self.data.iid}},callback)
    end, CCControlEventTouchUpInside)
    self.infoItems.changeButton:setSwallowsTouch(true)
    self.infoItems.changeButton:setTouchPriority(self.touchPriority)

    self.infoItems.upButton:addHandleOfControlEvent(function()
        self:showPage("up")
    end, CCControlEventTouchUpInside)
    self.infoItems.upButton:setSwallowsTouch(true)
    self.infoItems.upButton:setTouchPriority(self.touchPriority)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("soulInfo")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    if self.data.fromtype == "soullist" then
        self.infoItems.changeNode:setVisible(false)
        self.infoItems.changeButton:setEnabled(false)
    elseif self.data.fromtype == "slot" then
        self.infoItems.resolveNode:setVisible(false)
        self.infoItems.resolveButton:setEnabled(false)
    end

    --
    if self.data.opt and self.data.opt == 2 then
        self.infoItems.upButton:setVisible(false)
        self.infoItems.changeButton:setVisible(false)
        self.infoItems.resolveButton:setVisible(false)
        self.infoItems.upLab:setVisible(false)
        self.infoItems.changeLab:setVisible(false)
        self.infoItems.resolveLab:setVisible(false)
    end
end

function soulInfo.setPage_up(self)
    self.upItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("soulInfo")
    end, CCControlEventTouchUpInside)
    self.upItems.closeButton:setSwallowsTouch(true)
    self.upItems.closeButton:setTouchPriority(self.touchPriority)

    --
    -- self.upItems.title:setString("命格强化")
    self.upItems.title:setString(gameConfig.strings:string_common("popups","minggeqianghua"))

    local config = ui.IDconfig(self.data.cid)
    self.upItems["name"]:setString(config.name)
    self.upItems["lv1"]:setString("等级:"..self.data.level)
    ui.setLabelString(self.upItems.lv1,nil,13)

    ui.setLabelString(self.upItems["name"],nil,(config.quality or 1)*2-1)

    self.upItems["type3"]:setString("强化等级")
    self.upItems["num3"]:setString(self.data.level.."/"..config.limit1)
    self.upItems["next_num3"]:setString((((self.data.level+1)>config.limit1) and gameConfig.strings:string_common("soul",11) or (self.data.level+1).."/"..config.limit1))

    self.upItems["type1"]:setString(gameConfig.strings.attr_type[config.attr1])
    self.upItems["num1"]:setString("+" .. (config["attr1_grow"..self.data.level] or 0)*(config.method1 == "value" and 1 or 100)..(config.method1 == "value" and "" or "%"))
    if self.data.level < config.limit1 then
        self.upItems["next_num1"]:setString("+" .. (config["attr1_grow"..(self.data.level+1)] or 0)*(config.method1 == "value" and 1 or 100)..(config.method1 == "value" and "" or "%"))
    else --1到10 中间增升级了 9次
        self.upItems["next_num1"]:setString(gameConfig.strings:string_common("soul",12))
    end
    if config.attr2 and config.attr2 ~= "" then
        self.upItems.node_type2:setVisible(true)
        self.upItems["type2"]:setString(gameConfig.strings.attr_type[config.attr2])
        self.upItems["num2"]:setString("+" .. (config["attr2_grow"..self.data.level] or 0)*(config.method2 == "value" and 1 or 100)..(config.method2 == "value" and "" or "%"))
        if self.data.level < config.limit1 then
            self.upItems["next_num2"]:setString("+" .. (config["attr2_grow"..(self.data.level+1)] or 0)*(config.method2 == "value" and 1 or 100)..(config.method2 == "value" and "" or "%"))
        else --
            self.upItems["next_num2"]:setString(gameConfig.strings:string_common("soul",12))
        end
    else
        self.upItems.node_type2:setVisible(false)
        self.upItems["type2"]:setString("")
        self.upItems["num2"]:setString("")
        self.upItems["next_num2"]:setString("")
    end
    printT(self.upItems,"  self.upItems  ")
    printT(config,"  self.upItems  ")
    
    ui.setLabelString(self.upItems.num1,nil,13)
    ui.setLabelString(self.upItems.next_num1,nil,23)
    ui.setLabelString(self.upItems.num2,nil,13)
    ui.setLabelString(self.upItems.next_num2,nil,23)
    ui.setLabelString(self.upItems.num3,nil,13)
    ui.setLabelString(self.upItems.next_num3,nil,23)

    self.xupnum = config.upexp*(2^(self.data.level-1)) or 0

    if (self.data.level+1)>config.limit1 then
        self.xupnum = 0
        ui.addGray("CCControlButton",self.upItems.doButton)
        ui.addGray("CCLabelTTF",self.upItems.doLab)
    else
        ui.removeGray("CCControlButton",self.upItems.doButton)
        ui.removeGray("CCLabelTTF",self.upItems.doLab)
    end
    ui.setNewIcon(self.upItems,{cid = self.data.cid},0)
    self.upItems.allnum:setString(self.xupnum)
    ui.setNewIconName(self.upItems,{cid = 20099, numdesc = self.xupnum},0)

    --
    local upconfig = gamedata.config.soul_integrate_lv or {}
    local needlv = 0
    if upconfig[tostring(self.data.level+1)] and upconfig[tostring(self.data.level+1)].battle_lv then
        needlv = upconfig[tostring(self.data.level+1)].battle_lv
    end
    --

    -- self.upItems.doLab:setString("强 化")
    self.upItems.doLab:setString(gameConfig.strings:string_common("popups","qianghua"))
    ui.setLabelString(self.upItems.doLab,nil,19)
    self.upItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if (self.data.level+1)>config.limit1 then
            runGamePrompt({msg = "已强化到最高级"})
        elseif needlv > GameScene.roleinfo.level then
            runGamePrompt({msg = "需要队伍等级达到"..needlv.."级"})
        elseif self.uppropnum and self.uppropnum >= self.xupnum then
            UIRequest({type = 2504, iid = self.data.iid, prop = self.xupnum})
        else
            -- runGamePrompt({msg = "强化道具不足"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","qianghuadj")})
        end
    end, CCControlEventTouchUpInside)
    self.upItems.doButton:setSwallowsTouch(true)
    self.upItems.doButton:setTouchPriority(self.touchPriority)

    --
    --effect
    if self.hasup and self.hasup == 1 then
        self.hasup = 0
        self.upItems.effectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/jinglian/jinglian", nil, true, "jinglian")
        qianghuaNode:setPosition(0,0)
        self.upItems.effectNode:addChild(qianghuaNode)
        self.upItems.effectNode:setScale(1)
        local animationManager = getAnimationManager(qianghuaItems)
        animationManager:setAnimationCompletedCallback(function()
            self.upItems.effectNode:removeAllChildrenWithCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("jinglian")
        gamedata.music:PlayOptSound("xlshjhtp")
    end
    if self.uppropnum then
        self.upItems.allnum:setString(self.uppropnum)
    end
    UIRequest({type = 12001,cids = {20099},order = 25061})
end

function soulInfo.setUpPropNum(self,pdata)
    -- print("   soulInfo.setUpPropNum    ")
    self.uppropnum = pdata["20099"] or 0

    ui.setNewIconName(self.upItems,{cid = 20099, numdesc = self.xupnum},0)
    self.upItems.allnum:setString(self.uppropnum)
    if self.uppropnum > self.xupnum then
        self.upItems.allnum:setColor(ccc3(134,83,32));
    else 
        self.upItems.allnum:setColor(ccc3(255,0,0));
    end
end

return soulInfo  �/  