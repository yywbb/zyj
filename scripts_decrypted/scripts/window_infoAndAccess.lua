--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/6
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local infoAndAccess = {
    rootNode = nil,
    rootItems = nil,

    data = nil,
    paramData = nil,

    pageconfig = {"info"},
    pagetype = "info",

    recoveryOpen = false,

    list_config = nil,
    listview = nil,

    limits = {}

}

function infoAndAccess.open(self,touchPriority,data,callback)
    -- printT(data,"jkp-Access")
    self.root = ui.createNode()

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.root
end

function infoAndAccess.reload(self,data,callback)
    self.callback = callback
    self.data = data.prop or {}
    self.paramData = data.prop.param or {}
    self.pagetype = data.pagetype or self.pagetype
    self:showPage(self.pagetype)

end

function infoAndAccess.reloaddata(self,data)

    self.data = data.prop or {}
    self.paramData = data.prop.param or {}
    self.pagetype = data.pagetype or self.pagetype
    self:showPage(self.pagetype)

end

function infoAndAccess.close(self)
    self.pagetype = "info"
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.data = nil
    self.paramData = nil

    self.recoveryOpen = false

    self.list_config = nil
    self.listview = nil
    self.limits = {}

    if self.callback then
        self.callback()
    end
end

function infoAndAccess.showPage(self,type)
    self.pagetype = type

    local configdata = ui.IDconfig(self.data.cid) or {}

    if self.pagetype == "info" then
        if configdata.staffType == "props" then
            local pageSelect = 1
            if configdata.type == "keybox" then
            elseif configdata.type == "box101" then
            elseif configdata.type == "box" then
            elseif configdata.type == "vipbox" then
            elseif configdata.type == "value" then
            elseif self.data.cid == 20018 then
            else
                pageSelect = 2
            end
            if pageSelect == 2 then
                self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_daojuxiangqing2", nil, true, "tc_daojuxiangqing2")
                self.root:removeAllChildrenWithCleanup(true)
                self.root:addChild(self.rootNode)
                self:setPage_info2(self.paramData.data)
            else
                self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_daojuxiangqing", nil, true, "tc_daojuxiangqing")
                self.root:removeAllChildrenWithCleanup(true)
                self.root:addChild(self.rootNode)
                self:setPage_propInfo()
            end
        elseif configdata.staffType == "phantom" then
            self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_daojuxiangqing2", nil, true, "tc_daojuxiangqing")
            self.root:removeAllChildrenWithCleanup(true)
            self.root:addChild(self.rootNode)
            self:setPage_phantom()
        else
            self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_daojuxiangqing", nil, true, "tc_daojuxiangqing")
            self.root:removeAllChildrenWithCleanup(true)
            self.root:addChild(self.rootNode)
            self:setPage_info()
        end
    elseif self.pagetype == "general_fragment" then
        self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_daojuxiangqing", nil, true, "tc_daojuxiangqing")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_general_fragment_info()
    elseif self.pagetype == "general_fragment_other" then
        self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_daojuxiangqing2", nil, true, "tc_daojuxiangqing2")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_general_fragment_other_info()
    elseif self.pagetype == "red_fragment_info" then
        self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_daojuxiangqing2", nil, true, "tc_daojuxiangqing2")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_info2(self.paramData)
    elseif self.pagetype == "currency_info" then
        self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_daojuxiangqing2", nil, true, "tc_daojuxiangqing2")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_info2(self.paramData)
    elseif self.pagetype == "fashion_info" then
        self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_shizhuangxiangqing", nil, true, "shizhuangxiangqing")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)

        if configdata.staffType == "fashion" then
            self:setPage_zhujue(self.paramData)
        end
    elseif self.pagetype == "token"then
        self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_daojuxiangqing2", nil, true, "tc_daojuxiangqing2")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_info2(self.paramData)    
    elseif self.pagetype == "token_fragment" then
        self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_daojuxiangqing", nil, true, "tc_daojuxiangqing")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_token_fragment_info(self.paramData)    
    end

    if self.infoItems.buttontext_info then
        ui.setLabelString(self.infoItems.buttontext_info,nil,19,34)
    end

end

function infoAndAccess.setPage_zhujue(self,paramData)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("infoAndAccess")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)


    local fashionconfig = gamedata.config.fashioncoat or {}
    local roleid
    if GameScene.protagonist and GameScene.protagonist.general and GameScene.protagonist.general.cid and GameScene.protagonist.general.cid > 0 then
        if (GameScene.protagonist.general.cid >= 10101 and GameScene.protagonist.general.cid <= 10115) or (GameScene.protagonist.general.cid >= 10997 and GameScene.protagonist.general.cid <= 10999) or (GameScene.protagonist.general.cid >= 162001 and GameScene.protagonist.general.cid <= 162003) then
            roleid = GameScene.protagonist.general.cid
        else
            for k,v in pairs(fashionconfig) do
                for k1,v1 in pairs(v) do
                    if v1.coat_id == GameScene.protagonist.general.cid then
                        roleid = v1.role_id
                    end
                end
            end
        end
    end

    local config = gamedata.config.fashioncoat[tostring(self.data.cid)][tostring(roleid)]
    printT(config,"setPage_zhujue")
    self.rootNode, self.infoItems = CCBReaderLoad("tanchuang/tc_shizhuangxiangqing", nil, true, "shizhuangxiangqing")
    self.root:addChild(self.rootNode)

    ui.setLabelString(self.infoItems.name,config.name,14,40)
    local upconfig = gamedata.config.fashionintentify[tostring(self.data.cid)]["1"]
    local attr,num = ui.getATTRandNUM(upconfig["intentify_add1"])
    ui.setLabelString(self.infoItems["attr"],gameConfig.strings.attr_type[attr].."+"..num,14,40)

    local generalConfig = gamedata.config.general[tostring(config.coat_id)]
    local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name

    local Gneral = ui.itemcache:loadSkeleton(generalName,{})
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(1.5)
    Gneral:setPosition(0,0)
    self.infoItems["generalNode"]:addChild(Gneral.root or Gneral)

    self.data.general = {}
    self.data.general.cid = config.coat_id
    
    self.data.general.skill = {}
    if generalConfig.skillid and generalConfig.skillid >0 then
        self.data.general.skill.cid = generalConfig.skillid or 0
    elseif generalConfig.passiveskills and generalConfig.passiveskills >0 then
        self.data.general.skill.cid = generalConfig.passiveskills or 0
    end
    if generalConfig.combskillid and generalConfig.combskillid > 0 then
        self.data.general.combskill = {}
        self.data.general.combskill.cid = generalConfig.combskillid
    elseif generalConfig.combskillid2 and generalConfig.combskillid2 > 0 then
        self.data.general.combskill = {}
        self.data.general.combskill.cid = generalConfig.combskillid2
    end

    if next(self.data.general.skill) then
        self.infoItems.skillIcon1:setVisible(true)
        ui.setNewIcon(self.infoItems,self.data.general.skill)
        self.infoItems["i_button"]:addHandleOfControlEvent(function()
            gameWindows:openWindow("generalInfoSkill",{data = self.data , pagetype = "skillinfo",skilltype =  "skill"  })
        end, CCControlEventTouchUpInside)
        self.infoItems["i_button"]:setSwallowsTouch(true)
        self.infoItems["i_button"]:setTouchPriority(self.touchPriority)

    else
        self.infoItems.skillIcon1:setVisible(false)
    end

    if next(self.data.general.combskill) then
        self.infoItems.skillIcon2:setVisible(true)
        ui.setNewIcon(self.infoItems,self.data.general.combskill,1)
        self.infoItems["i_button_1"]:addHandleOfControlEvent(function()
            gameWindows:openWindow("generalInfoSkill",{data = self.data , pagetype = "skillinfo",skilltype =  "combskill"  })
        end, CCControlEventTouchUpInside)
        self.infoItems["i_button_1"]:setSwallowsTouch(true)
        self.infoItems["i_button_1"]:setTouchPriority(self.touchPriority)
    else
        self.infoItems.skillIcon2:setVisible(false)
    end

    -- UIRequest({type = 1070})
    local have = false
    for k,v in pairs(GameScene.fashiondata.fashions) do
        if self.data.cid == v.id then
            have = true
            break
        end
    end

    self.infoItems.weiyongyou:setVisible(not have)
    self.infoItems.yiyongyou:setVisible(have)

    self:setListInfo(self.data,1)
end

function infoAndAccess.setPage_propInfo(self)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("infoAndAccess")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local configdata = ui.IDconfig(self.data.cid) or {}

    ui.setPropIcon(self.infoItems,{cid = self.data.cid})

    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(self.infoItems.name,configdata.name, 213)
    else
        ui.setLabelString(self.infoItems.name,configdata.name,((configdata.quality and configdata.quality ~= 0) and configdata.quality or 1)*2-1)
    end
    ui.setLabelString(self.infoItems.desc,configdata.desc,13)
    ui.setLabelString(self.infoItems.has,gameConfig.strings:colNum(self.paramData.data.num or 0),13)
    ui.setLabelString(self.infoItems.get,nil,13)

    self.limits = {}
    if self.infoItems.conditions and configdata.use_limit and configdata.use_limit ~= "" then
        local limitString = "使用条件:"
        local stringSplitTb = string.split(configdata.use_limit,";")
        table.remove(stringSplitTb,#stringSplitTb)
        local relationStr = stringSplitTb[1]
        for i=2,#stringSplitTb do
            local limitStrTb = string.split(stringSplitTb[i],",")
            local cid = tonumber(limitStrTb[1])
            local num = tonumber(limitStrTb[2])

            local limit = {cid = cid,num = num}
            

            if cid == 1 then
                limit.ismeet = GameScene.roleinfo.level >= num
                limit.limitTips = num.."级可使用"
                limitString = limitString.."队伍等级"..num
                table.insert(self.limits,limit)
            elseif cid == 2 and num == 1 then
                limit.ismeet = GameScene.vip.rmb > 0
                limit.limitTips = "未进行首次充值无法使用"
                limitString = limitString.."首冲后"
                table.insert(self.limits,limit)
            elseif cid == 3 then
                local curCopyId = 42101
                local curSectionData = GameScene.layers["copy_chapter"].module.normaldata[tostring(table.getTableLength(GameScene.layers["copy_chapter"].module.normaldata))]
                local curCopyId = curSectionData.maps[tostring(table.getTableLength(curSectionData.maps))].id
                local copyName = gamedata.config.copy[tostring(num)][tostring(table.getTableLength(gamedata.config.copy[tostring(num)]))].name
                limitString = limitString.."通关"..copyName
                limit.ismeet = curCopyId > num
                limit.limitTips = "通关"..copyName.."可使用"
                table.insert(self.limits,limit)
            end
            limitString = limitString..","
        end

        if relationStr == "and" then
            limitString = limitString.."满足以上条件即可使用"
        else
            limitString = limitString.."满足其中一个条件即可使用"
        end

        ui.setLabelString(self.infoItems.conditions,limitString,24,26)
    end

    -- 设置锤子
    if gameConfig:checkBuildOpen(257) then
        self.recoveryOpen = true
    end
    if self.infoItems.recoveryButton then
        if self.recoveryOpen and configdata.labal and configdata.labal == 1 then
            self.infoItems.recoveryButton:setVisible(true)
            if self.paramData.data.num < configdata.props_num then
                ui.addGray("CCControlButton",self.infoItems.recoveryButton)
                self.infoItems.recoveryButton:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)
                    --
                    runGamePrompt({msg = gameConfig.strings:recovery_need_num(configdata.props_num)})
                    --
                    gamedata.music:PlayOptSound("sydj")
                end, CCControlEventTouchUpInside)
            else
                ui.removeGray("CCControlButton",self.infoItems.recoveryButton)
                self.infoItems.recoveryButton:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)
                    --
                    gameWindows:openWindow("propsRecovery",{cid = self.data.cid, num = self.paramData.data.num},nil)
                    gameWindows:closeWindow("infoAndAccess")
                    --
                    gamedata.music:PlayOptSound("sydj")
                end, CCControlEventTouchUpInside)
            end
            self.infoItems.recoveryButton:setSwallowsTouch(true)
            self.infoItems.recoveryButton:setTouchPriority(self.touchPriority)
        else
            self.infoItems.recoveryButton:setVisible(false)
        end
    end
    --

    -- 详情按钮
    self.infoItems.button_info_node:setVisible(false)

    -- 道具使用规则
    self.infoItems.button:setSwallowsTouch(true)
    self.infoItems.button:setTouchPriority(self.touchPriority)
    --limitTime
    if self.infoItems.limitTime then
        if configdata.proptype and configdata.proptype == 1 then
            if gameTimer.times["limitProp_"..self.paramData.data.iid] and gameTimer.times["limitProp_"..self.paramData.data.iid] > 0 then
                --倒计时
                self.rigistTime["limitProp_"..self.paramData.data.iid] = 1
                gameTimer:rigistTimeFunc("limitProp_"..self.paramData.data.iid,function()
                    if gameTimer.times["limitProp_"..self.paramData.data.iid] > 0 then
                        self.infoItems.limitTime:setString(ui.makeTimeText(gameTimer.times["limitProp_"..self.paramData.data.iid],"hour").."后开启")
                        --ui.setLabelString(self.ccbDocument[tostring(index)].ccbDocumentControler.freshtime,gameConfig.strings:string_common("shop_list",7)..ui.makeTimeText(gameTimer.times["newShoplimitTime"..data.id],"hour"),137)
                    end
                    if gameTimer.times["limitProp_"..self.paramData.data.iid] == 0 then
                        self.infoItems.limitTime:setString("")
                        UIRequest({type = 5901})
                        gameTimer:UnrigistTimeFunc("limitProp_"..self.paramData.data.iid)
                    end
                end)
                --按钮
                ui.addGray("CCControlButton",self.infoItems.button)
                ui.addGray("CCLabelTTF",self.infoItems.buttontext)
            else
                --倒计时
                self.infoItems.limitTime:setString("")
                --按钮
                ui.removeGray("CCControlButton",self.infoItems.button)
                ui.removeGray("CCLabelTTF",self.infoItems.buttontext)
            end
        else
            self.infoItems.limitTime:setString("")
            ui.removeGray("CCControlButton",self.infoItems.button)
            ui.removeGray("CCLabelTTF",self.infoItems.buttontext)
        end
    end
    -- 按钮状态
    -- UIRequest({type = 12002, id = data.cid})
    if configdata.type == "keybox" then
        local realnum = math.min(self:findkeynum(configdata),self.paramData.data.num)
        if realnum <= 0 then
            -- "无钥匙"
            ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("equips",11),18)
            self.infoItems.button:addHandleOfControlEvent(function()
                UIRequest({type=3200, mobileShopId=5})
            end, CCControlEventTouchUpInside)
        elseif realnum ==1 then
            -- "打开"
            ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("equips",13),18)
            self.infoItems.button:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                UIRequest({type= 1201, cid = self.paramData.data.cid,num=1})
                gameWindows:closeWindow("infoAndAccess")
                gamedata.music:PlayOptSound("sydj")
            end, CCControlEventTouchUpInside)
        else
            ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("equips",13),18)
            self.infoItems.button:addHandleOfControlEvent(function()
                gameWindows:openWindow("propusebynum",{id = self.paramData.data.cid})
                gameWindows:closeWindow("infoAndAccess")
            end, CCControlEventTouchUpInside)
        end
    elseif configdata.type == "box101" then
        ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("equips",13),18)
        self.infoItems.button:addHandleOfControlEvent(function()
            if self.paramData.data.limitTime > 0 then
                runGamePrompt({msg = "当前时间点不能开启宝箱"})
            else
                gameTouch:clickprofbytime(0.5)
                UIRequest({type= 5902,iid = self.paramData.data.iid,cid = self.paramData.data.cid,num=1})
                gamedata.music:PlayOptSound("sydj")
            end
        end, CCControlEventTouchUpInside)

    elseif configdata.type == "box" then
        -- ui.setLabelString(item.buttontext,"打开",18)
        ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("equips",13),18)
        self.infoItems.button:addHandleOfControlEvent(function()

            if next(self.limits) then
                for i,v in ipairs(self.limits) do
                    if not v.ismeet then
                        runGamePrompt({msg = v.limitTips})
                        return
                    end
                end
            end
            if configdata["function"] and (configdata["function"] == "box3" or configdata["function"] == "box4" ) then
                gameWindows:openWindow("boxselect",{id = self.paramData.data.cid, num = self.paramData.data.num})
            elseif self.paramData.data.num <=1 then
                gameTouch:clickprofbytime(0.5)
                UIRequest({type= 1201, cid =self.paramData.data.cid,num=1})
                gameWindows:closeWindow("infoAndAccess")
                gamedata.music:PlayOptSound("sydj")
            else
                gameWindows:openWindow("propusebynum",{id = self.paramData.data.cid})
                gameWindows:closeWindow("infoAndAccess")
            end
        end, CCControlEventTouchUpInside)
    elseif configdata.type == "vipbox" then
        --ui.setLabelString(item.buttontext,"打开",18)
        ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("equips",13),18)
        self.infoItems.button:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            UIRequest({type= 1201, cid = self.paramData.data.cid,num=1})
            gameWindows:closeWindow("infoAndAccess")
            gamedata.music:PlayOptSound("sydj")
        end, CCControlEventTouchUpInside)
    elseif configdata.type == "value" then
        -- ui.setLabelString(item.buttontext,"使用",18)
        ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("equips",15),18)
        self.infoItems.button:addHandleOfControlEvent(function()
            if self.paramData.data.num <=1 then
                gameTouch:clickprofbytime(0.5)
                UIRequest({type= 1201, cid = self.paramData.data.cid,num=1})
                gameWindows:closeWindow("infoAndAccess")
                gamedata.music:PlayOptSound("sydj")
            else
                gameWindows:openWindow("propusebynum",{id = self.paramData.data.cid})
            end
        end, CCControlEventTouchUpInside)
    elseif self.data.cid == 20018 then
        -- ui.setLabelString(item.buttontext,"使用",18)
        ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("equips",15),18)
        self.infoItems.button:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            -- gameWindows:openWindow("useropt",{type = "rename"},nil)
            UIRequest({type = 12001, order = 33092, cids = {self.paramData.data.cid}})
            gameWindows:closeWindow("infoAndAccess")
            gamedata.music:PlayOptSound("sydj")
        end, CCControlEventTouchUpInside)
    end

    -- 
    self:setListInfo(self.data,2)
end

function infoAndAccess.setPage_phantom(self)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("infoAndAccess")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local configdata = ui.IDconfig(self.data.cid) or {}
    -- printT(configdata, "jkp-configdata")

    ui.setNewIcon(self.infoItems,{cid = self.data.cid})

    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(self.infoItems.name,configdata.name, 213)
    else
        ui.setLabelString(self.infoItems.name,configdata.name,((configdata.quality and configdata.quality ~= 0) and configdata.quality or 1)*2-1)
    end
    ui.setLabelString(self.infoItems.desc,configdata.desc,13)
    ui.setLabelString(self.infoItems.has,gameConfig.strings:colNum(self.paramData.num or 0),13)
    
    ui.setLabelString(self.infoItems.get,nil,13)
    -- 设置锤子
    if self.infoItems.recoveryButton then
        self.infoItems.recoveryButton:setVisible(false)
    end

    -- 详情按钮（碎片不限时详情按钮）
    self.infoItems.button_info_node:setVisible(false)

    local illusionData = nil
    if GameScene.layers["illusion"].module.data then
        for k,v in pairs(GameScene.layers["illusion"].module.data) do
            if v.cid == self.data.cid then
                illusionData = v
                break
            end
        end
    end
        
    if illusionData then
        self.infoItems.has:setVisible(true)
        local endtime = os.date("*t", illusionData.endtime - 1)
        ui.setLabelString(self.infoItems.has,string.format(gameConfig.strings:string_common("huanhua",9), endtime.month,endtime.day,24),13)
    else
        self.infoItems.has:setVisible(false)
    end

    -- 
    self:setListInfo(self.data,3)
end

function infoAndAccess.setPage_info(self)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("infoAndAccess")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local configdata = ui.IDconfig(self.data.cid) or {}
    -- printT(configdata, "jkp-configdata")

    ui.setPropIcon(self.infoItems,{cid = self.data.cid})

    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(self.infoItems.name,configdata.name, 213)
    else
        ui.setLabelString(self.infoItems.name,configdata.name,((configdata.quality and configdata.quality ~= 0) and configdata.quality or 1)*2-1)
    end
    ui.setLabelString(self.infoItems.desc,configdata.desc,13)
    ui.setLabelString(self.infoItems.has,gameConfig.strings:colNum(self.paramData.num or 0),13)
    ui.setLabelString(self.infoItems.get,nil,13)

    --limitTime
    if self.infoItems.limitTime then
        self.infoItems.limitTime:setString("")
    end

    -- 设置锤子
    if self.infoItems.recoveryButton then
        self.infoItems.recoveryButton:setVisible(false)
    end

    -- 详情按钮（碎片不限时详情按钮）
    self.infoItems.button_info_node:setVisible(false)

    -- 合成按钮
    if self.infoItems.button_node then
        self.infoItems.button:setSwallowsTouch(true)
        self.infoItems.button:setTouchPriority(self.touchPriority)
        if configdata.staffType == "equip_fragment"  then
            -- ui.setLabelString(item.num, data.num.."/"..configdata.num, 14)

            ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("buttontext","hecheng"),18)
            if self.paramData.num < configdata.num then
                setControlButtonFrame(self.infoItems.button,"b_s_button2","b_s_button2_h","b_s_button2")
                ui.addGray("CCLabelTTF",self.infoItems.buttontext)
                ui.addGray("CCControlButton",self.infoItems.button)
                self.infoItems.button:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)
                    -- runGamePrompt({msg = "碎片不足"})
                    runGamePrompt({msg = gameConfig.strings:string_common("equips",9)})
                end, CCControlEventTouchUpInside)
            else
                setControlButtonFrame(self.infoItems.button,"b_s_button2","b_s_button2_h","b_s_button2")
                ui.removeGray("CCLabelTTF",self.infoItems.buttontext)
                ui.removeGray("CCControlButton",self.infoItems.button)
                self.infoItems.button:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)

                    local total = math.floor(self.paramData.num/configdata.num)

                    local cb = function(usenum)
                        UIRequest({type = 1108, ids = {configdata.equip,usenum,self.paramData.cid}})
                    end
                    if total>1 then
                        gameWindows:openWindow("equipbynum",{id = self.paramData.cid,total=total},cb)
                    else
                        cb(total)
                    end
                    gamedata.music:PlayOptSound("hc")
                end, CCControlEventTouchUpInside)
            end
        elseif configdata.staffType == "treasure_fragment"  then
            -- ui.setLabelString(item.num, data.num, 14)

            ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("equips",10),18)
            ui.removeGray("CCLabelTTF",self.infoItems.buttontext)
            ui.removeGray("CCControlButton",self.infoItems.button)
            setControlButtonFrame(self.infoItems.button,"b_s_button1","b_s_button1_h","b_s_button1")
            self.infoItems.button:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                --todo 去抢夺
                GameScene:shiftLayer("rob","up",{page = configdata.type, cid = configdata.id})
            end, CCControlEventTouchUpInside)
        elseif configdata.staffType == "meterial_fragment"  then
            local type = "horse"
            if configdata.equip >= 20039 and configdata.equip >= 20041 then
                type = "treasure"
            end
        
            ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("equips",10),18)
            ui.removeGray("CCLabelTTF",self.infoItems.buttontext)
            ui.removeGray("CCControlButton",self.infoItems.button)
            setControlButtonFrame(self.infoItems.button,"b_s_button1","b_s_button1_h","b_s_button1")
            self.infoItems.button:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                --todo 去抢夺
                GameScene:shiftLayer("rob","up",{page = configdata.type, cid = configdata.id})
            end, CCControlEventTouchUpInside)
        end
    end

    -- 
    self:setListInfo(self.data,4)
end

function infoAndAccess.setPage_info2(self, data)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("infoAndAccess")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local configdata = ui.IDconfig(self.data.cid) or {}
    -- printT(configdata, "jkp-configdata")

    ui.setPropIcon(self.infoItems,{cid = self.data.cid})

    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(self.infoItems.name,configdata.name, 213)
    else
        ui.setLabelString(self.infoItems.name,configdata.name,((configdata.quality and configdata.quality ~= 0) and configdata.quality or 1)*2-1)
    end
    ui.setLabelString(self.infoItems.desc,configdata.desc,13)
    ui.setLabelString(self.infoItems.has,gameConfig.strings:colNum(data.num or 0),13)
    ui.setLabelString(self.infoItems.get,nil,13)

    local _config = ui.IDconfig(self.data.cid)
    if _config.staffType == "championpoint" or _config.staffType == "gangpoint" or _config.staffType == "passkillcoin" or _config.staffType == "point" or _config.staffType == "xiandou" then
        UIRequest({type = 1203, id = self.data.cid})
    else
        UIRequest({type = 12002, id = self.data.cid})
    end

    if _config.staffType == "platformcurrency" then
        self.infoItems.has:setVisible(false)
    end

    -- 设置锤子
    if gameConfig:checkBuildOpen(257) then
        self.recoveryOpen = true
    end

    if self.infoItems.recoveryButton then
        if data.num then
            if self.recoveryOpen and configdata.labal and configdata.labal == 1 then
                self.infoItems.recoveryButton:setVisible(true)
                local props_num =  0
                if configdata.props_num then props_num = configdata.props_num end
                if configdata.mix_num then  props_num = configdata.mix_num end
                if data.num < props_num then
                    ui.addGray("CCControlButton",self.infoItems.recoveryButton)
                    self.infoItems.recoveryButton:addHandleOfControlEvent(function()
                        gameTouch:clickprofbytime(0.5)
                        --
                        runGamePrompt({msg = gameConfig.strings:recovery_need_num(props_num)})
                        --
                        gamedata.music:PlayOptSound("sydj")
                    end, CCControlEventTouchUpInside)
                else
                    ui.removeGray("CCControlButton",self.infoItems.recoveryButton)
                    self.infoItems.recoveryButton:addHandleOfControlEvent(function()
                        gameTouch:clickprofbytime(0.5)
                        --
                        gameWindows:closeWindow("infoAndAccess")
                        if self.pagetype and  self.pagetype == "token"then
                            gameWindows:openWindow("tokenRecovery",{cid = self.data.cid, num = data.num},nil)
                        else    
                            gameWindows:openWindow("propsRecovery",{cid = self.data.cid, num = data.num},nil)
                        end    
                        --
                        gamedata.music:PlayOptSound("sydj")
                    end, CCControlEventTouchUpInside)
                end
                self.infoItems.recoveryButton:setSwallowsTouch(true)
                self.infoItems.recoveryButton:setTouchPriority(self.touchPriority)
            else
                self.infoItems.recoveryButton:setVisible(false)
            end 
        else 
            self.infoItems.recoveryButton:setVisible(false)
        end
    end
    --

    -- 详情按钮
    self.infoItems.button_info_node:setVisible(false)
    -- if configdata.staffType == "props" then
    --     self.infoItems.button_info_node:setVisible(false)
    -- else
    --     self.infoItems.button_info:setVisible(true)
    --     self.infoItems.button_info:addHandleOfControlEvent(function()
    --         gameWindows:openWindow("generalInfoRole",{cid = configdata.red_id, opt = 2, pagetype = "info"})
    --     end, CCControlEventTouchUpInside)
    --     self.infoItems.button_info:setSwallowsTouch(true)
    --     self.infoItems.button_info:setTouchPriority(self.touchPriority)
    -- end

    -- 途径列表
    self:setListInfo(self.data,5)
end

-- 武将魂魄
function infoAndAccess.setPage_general_fragment_info(self)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("infoAndAccess")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local configdata = ui.IDconfig(self.data.cid) or {}
    -- printT(configdata, "jkp-configdata")

    ui.setPropIcon(self.infoItems,{cid = self.data.cid})
    setSpriteFrameByName(self.infoItems["i_soulsprite"], "b_soulsprite")
    -- self.infoItems.name:setString(gameConfig.strings:hunpo(configdata.name))
    self.infoItems.name:setString(configdata.name)

    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(self.infoItems.name,nil, 213)
    else
        ui.setLabelString(self.infoItems.name,nil,((configdata.quality and configdata.quality ~= 0) and configdata.quality or 1)*2-1)
    end
    ui.setLabelString(self.infoItems.desc,configdata.desc,13)
    ui.setLabelString(self.infoItems.has,gameConfig.strings:colNum(self.paramData.num or 0),13)
    ui.setLabelString(self.infoItems.get,nil,13)

    --limitTime
    if self.infoItems.limitTime then
        self.infoItems.limitTime:setString("")
    end

    -- 设置锤子
    if self.infoItems.recoveryButton then
        self.infoItems.recoveryButton:setVisible(false)
    end
    --

    -- 详情按钮（碎片不限时详情按钮）
    self.infoItems.button_info:addHandleOfControlEvent(function()
        gameWindows:openWindow("generalInfoRole",{cid = configdata.generalid, opt = 2, pagetype = "info"})
    end, CCControlEventTouchUpInside)
    self.infoItems.button_info:setSwallowsTouch(true)
    self.infoItems.button_info:setTouchPriority(self.touchPriority)

     -- 合成按钮
    if self.infoItems.button_node then
        self.infoItems.button:setSwallowsTouch(true)
        self.infoItems.button:setTouchPriority(self.touchPriority)
        -- 合成
        ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("buttontext","hecheng"),18)
        if self.paramData.status == 2 then
            self.infoItems.button:setVisible(false)
            ui.setLabelString(self.infoItems.buttontext,"已拥有此伙伴",3)
        else
            self.infoItems.button:setVisible(true)
            if self.paramData.neednum > self.paramData.num then
                ui.addGray("CCLabelTTF",self.infoItems.buttontext)
                ui.addGray("CCControlButton",self.infoItems.button)
                self.infoItems.button:addHandleOfControlEvent(function()
                    -- 魂魄不足
                    runGamePrompt({msg = gameConfig.strings:string_common("general",7)})
                end, CCControlEventTouchUpInside)
            else
                ui.removeGray("CCLabelTTF",self.infoItems.buttontext)
                ui.removeGray("CCControlButton",self.infoItems.button)
                self.infoItems.button:addHandleOfControlEvent(function()
                    UIRequest({type = 1016, ids = {self.paramData.cid}})
                    gameWindows:closeWindow("infoAndAccess")
                end, CCControlEventTouchUpInside)
            end
        end
    end

    -- 
    self:setListInfo(self.paramData,6)

end

-- 武将魂魄
function infoAndAccess.setPage_general_fragment_other_info(self)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("infoAndAccess")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local configdata = ui.IDconfig(self.data.cid) or {}
    -- printT(configdata, "jkp-configdata")

    ui.setPropIcon(self.infoItems,{cid = self.data.cid})
    setSpriteFrameByName(self.infoItems["i_soulsprite"], "b_soulsprite")
    self.infoItems.name:setString(gameConfig.strings:hunpo(configdata.name))

    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(self.infoItems.name,nil, 213)
    else
        ui.setLabelString(self.infoItems.name,nil,((configdata.quality and configdata.quality ~= 0) and configdata.quality or 1)*2-1)
    end
    ui.setLabelString(self.infoItems.desc,configdata.desc,13)
    ui.setLabelString(self.infoItems.has,gameConfig.strings:colNum(self.paramData.num or 0),13)
    ui.setLabelString(self.infoItems.get,nil,13)

    -- 获取数量
    UIRequest({type = 12002, id = self.data.cid})

    --limitTime
    if self.infoItems.limitTime then
        self.infoItems.limitTime:setString("")
    end

    -- 设置锤子
    if self.infoItems.recoveryButton then
        self.infoItems.recoveryButton:setVisible(false)
    end
    --

    -- 详情按钮（碎片不限时详情按钮）
    self.infoItems.button_info:addHandleOfControlEvent(function()
        gameWindows:openWindow("generalInfoRole",{cid = configdata.generalid, opt = 2, pagetype = "info"})
    end, CCControlEventTouchUpInside)
    self.infoItems.button_info:setSwallowsTouch(true)
    self.infoItems.button_info:setTouchPriority(self.touchPriority)

    -- 
    self:setListInfo(self.paramData,7)

end


-- 天机令碎片
function infoAndAccess.setPage_token_fragment_info(self)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("infoAndAccess")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local configdata = ui.IDconfig(self.data.cid) or {}
    -- printT(configdata, "jkp-configdata")

    UIRequest({type = 12002, id = self.data.cid})

    ui.setPropIcon(self.infoItems,{cid = self.data.cid})
    setSpriteFrameByName(self.infoItems["i_soulsprite"], "b_sprite1")
    -- self.infoItems.name:setString(gameConfig.strings:hunpo(configdata.name))
    self.infoItems.name:setString(configdata.name)

    if configdata.quality and configdata.quality >= 7 then
        ui.setLabelString(self.infoItems.name,nil, 213)
    else
        ui.setLabelString(self.infoItems.name,nil,((configdata.quality and configdata.quality ~= 0) and configdata.quality or 1)*2-1)
    end
    ui.setLabelString(self.infoItems.desc,configdata.desc,13)
    ui.setLabelString(self.infoItems.has,gameConfig.strings:colNum(self.paramData.num or 0),13)
    ui.setLabelString(self.infoItems.get,nil,13)

    --limitTime
    if self.infoItems.limitTime then
        self.infoItems.limitTime:setString("")
    end

    -- 设置锤子
    if self.infoItems.recoveryButton then
        self.infoItems.recoveryButton:setVisible(false)
    end
    --

    -- 详情按钮（碎片不限时详情按钮）
    self.infoItems.button_info:setVisible(false)
    self.infoItems.buttontext_info:setVisible(false)
     -- 合成按钮
    if self.infoItems.button_node then
        self.infoItems.button:setSwallowsTouch(true)
        self.infoItems.button:setTouchPriority(self.touchPriority)
        -- 合成
        ui.setLabelString(self.infoItems.buttontext,gameConfig.strings:string_common("buttontext","hecheng"),18)
        if configdata and self.paramData and table.getTableLength(self.paramData)>0 and self.paramData.num then
            printT(configdata,"jkp-configdata")
            printT(self.paramData,"paramData")
            self.infoItems.button:setVisible(true)
            if configdata.neednum > self.paramData.num then
                ui.addGray("CCLabelTTF",self.infoItems.buttontext)
                ui.addGray("CCControlButton",self.infoItems.button)
                self.infoItems.button:addHandleOfControlEvent(function()
                    -- 碎片不足
                    runGamePrompt({msg = gameConfig.strings:string_common("token",3)})
                end, CCControlEventTouchUpInside)
            else
                ui.removeGray("CCLabelTTF",self.infoItems.buttontext)
                ui.removeGray("CCControlButton",self.infoItems.button)
                self.infoItems.button:addHandleOfControlEvent(function()


                    gameTouch:clickprofbytime(0.5)
                    local num = 0
                    if configdata.num then 
                        num = configdata.num
                    elseif  configdata.neednum then
                        num = configdata.neednum
                    end    
                    local total = math.floor(self.paramData.num/num)
                    local cb = function(usenum)
                         --单次合成
                         print("paramData.cid == ",self.paramData.cid)
                         UIRequest({type= 8242, cid = self.paramData.cid,num= usenum, totaluse = num*usenum})
                         gameWindows:closeWindow("infoAndAccess")
                    end
                    if total>1 then
                        gameWindows:openWindow("equipbynum",{id = self.paramData.cid,total=total},cb)
                    else
                        cb(total)
                    end
                end, CCControlEventTouchUpInside)
            end
        else
            self.infoItems.button_node:setVisible(false)
        end    
    end

    -- 
    self:setListInfo(self.paramData,8)

end

--获取途径展示
function infoAndAccess.setListInfo(self,data,index)
    print("index == ",index)
    printT(data,"setListInfo")
    if self.pagetype == "general_fragment" or self.pagetype == "general_fragment_other"then
        self.list_config = gamedata.config.drop[tostring(data.fragmentCid)]
    else
        self.list_config = gamedata.config.drop[tostring(data.cid)]
    end

    if self.list_config then
        self.mapmaxN,self.pointmaxN = getNormalCopyProcess()
        self.mapmaxB,self.pointmaxB = getBraveCopyProcess()
        self.mapmaxS,self.pointmaxS = getStarCopyProcess()
        print("getNormalCopyProcess=",getNormalCopyProcess())
        print("getBraveCopyProcess=",getBraveCopyProcess())
        print("getStarCopyProcess=",getStarCopyProcess())

        self.infoItems.des:setPosition(9999,360)
        self.infoItems.des:setVisible(false)
        --
        self.configsort = {}
        for k,v in pairs(self.list_config) do
            v.order = v.page
            local map,point  = 0,0
            if v.param and v.param ~= "" then
                local i = string.find(v.param,",")
                if i then
                    map,point = ui.getIDandNUM(v.param)
                else
                    map = tonumber(v.param)
                end
            end
            if v.systemid == 12 or v.systemid == 13 then
                if not self.mapmaxN then
                    self.mapmaxN,self.pointmaxN = ui.getCopyProcess("normal")
                end
                local isopen = ui.isCopyOpen(map,point,self.mapmaxN,self.pointmaxN)
                if not isopen then
                    v.order = 1000-v.order
                elseif not ui.hasCopyChallenge("normal",map,point) then
                    v.order = 500-v.order
                end
            elseif v.systemid == 15 or v.systemid == 16 then
                if not self.mapmaxB then
                    self.mapmaxB,self.pointmaxB = ui.getCopyProcess("brave")
                end
                local isopen = ui.isCopyOpen(map,point,self.mapmaxB,self.pointmaxB)
                if not isopen then
                    v.order = 1000-v.order
                end
            elseif v.systemid == 148 then
                if not self.mapmaxS then
                    self.mapmaxS,self.pointmaxS = ui.getCopyProcess("star")
                end
                local isopen = ui.isCopyOpen(map,point,self.mapmaxS,self.pointmaxS)
                if not isopen then
                    v.order = 1000-v.order
                end
            end
            table.insert(self.configsort,v)
            local sortfunc = function (a,b)
                return a.order < b.order
            end
            table.sort(self.configsort,sortfunc)

        end

        --
        if self.listview then
            self.listview:reloadData()
        else
            self:createlist()
        end

    else
        self.infoItems.des:setVisible(true)
        ui.setLabelString(self.infoItems.des,nil,18)
    end
end

function infoAndAccess.createlist(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 170)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tanchuang/cell_huoqutujing", nil, true, "cell_huoqutujing")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.configsort[a1+1]

            ui.setLabelString(ccbDocumentControler.titleLabel,celldata.title,21)
            ccbDocumentControler.desLabel:setString(celldata.desc)

            if celldata.systemid and celldata.systemid ~= 0 then
                local isopen = true
                local buildconfig = gamedata.config.build[tostring(celldata.systemid)]

                if buildconfig.level > GameScene.roleinfo.level then
                    isopen = false
                    -- ccbDocumentControler.des:setString(buildconfig.level.."级开启")
                    ccbDocumentControler.des:setString(gameConfig.strings:lvOpen(buildconfig.level))
                else
                    if buildconfig.type == "copy_chapter" or  buildconfig.type == "copy_map" then
                        local map,point  = 0,0
                        if celldata.param and celldata.param ~= "" then
                            local i = string.find(celldata.param,",")
                            if i then
                                map,point = ui.getIDandNUM(celldata.param)
                            else
                                map = tonumber(celldata.param)
                            end
                        end
                        if celldata.systemid == 12 or celldata.systemid == 13 then
                            if not self.mapmaxN then
                                self.mapmaxN,self.pointmaxN = ui.getCopyProcess("normal")
                            end
                            isopen = ui.isCopyOpen(map,point,self.mapmaxN,self.pointmaxN)
                        elseif celldata.systemid == 15 or celldata.systemid == 16 then
                            if not self.mapmaxB then
                                self.mapmaxB,self.pointmaxB = ui.getCopyProcess("brave")
                            end
                            isopen = ui.isCopyOpen(map,point,self.mapmaxB,self.pointmaxB)
                        elseif celldata.systemid == 148 then
                            if not self.mapmaxS then
                                self.mapmaxS,self.pointmaxS = ui.getCopyProcess("star")
                            end
                            isopen = ui.isCopyOpen(map,point,self.mapmaxS,self.pointmaxS)
                        end
                        -- ccbDocumentControler.des:setString("未到达")
                        ccbDocumentControler.des:setString(gameConfig.strings:string_common("popups","weidadao"))
                    end
                end

                ccbDocumentControler.in_goto:setVisible(isopen)
                ccbDocumentControler.des:setVisible(not isopen)
                ccbDocumentControler.in_button:setSwallowsTouch(true)
                ccbDocumentControler.in_button:setTouchPriority(self.touchPriority-1)
                ccbDocumentControler.in_button:addHandleOfControlEvent(function()
                    GameScene:shiftLayerById(celldata.systemid,celldata.param)
                end, CCControlEventTouchUpInside)
            else
                ccbDocumentControler.in_goto:setVisible(false)
                ccbDocumentControler.des:setVisible(false)
            end

            cellCCB:setPosition(920/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.configsort)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.infoItems.listnode:getContentSize().width,
        viewheight = self.infoItems.listnode:getContentSize().height,
        dire = 1
    })
    self.infoItems.listnode:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end

function infoAndAccess.findkeynum(self,boxconfig)
    local num = 0
    for k,v in pairs(self.paramData.propsData) do
        if tostring(v.cid) == boxconfig.param1 then
            num = v.num
            break
        end
    end
    return num
end

function infoAndAccess.setPropNum(self,data)

    local configdata = ui.IDconfig(data.cid) or {}
    if self.pagetype == "info" then
        if configdata.staffType == "props" then
            if self.paramData.data.num then
                self.paramData.data.num = data.num
            end
    
            if data.num <= 0 then 
                gameWindows:closeWindow("infoAndAccess")
            end
        elseif configdata.staffType == "equip_fragment" then
            if self.paramData.num then
                self.paramData.num = data.num
            end
    
            local total = math.floor(self.paramData.num/configdata.num)
            if total <= 0 then
                gameWindows:closeWindow("infoAndAccess")
            end
        end
    end

    ui.setLabelString(self.infoItems.has,gameConfig.strings:colNum(data.num),13)
    
end


return infoAndAccess   y�  