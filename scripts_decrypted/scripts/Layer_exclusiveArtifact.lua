--
-- Author: songyibo
-- Date: 2021-03-19 15:11:27
--

local exclusiveArtifact = {

    rootNode = nil,
    rootItems = nil,
    data = {},
    pageconfig = {"intensify","inlay"},
    pagename = {gameConfig.strings:string_common("exclusiveArtifactNew",5),gameConfig.strings:string_common("exclusiveArtifactNew",6)},
    selectpage = "intensify",
    generalindex = 1,
    generalcid = nil,
    touchPriority = -102,

    titleCellSize = {x=180,y=180},
    generalListTableView = nil,
    props = {},

    xili_names = {
        [1] = "zhuanshushenqi_guangzhixili",
        [2] = "zhuanshushenqi_anzhixili",
        [3] = "zhuanshushenqi_leizhixili",
    }
}

function exclusiveArtifact.reloadHint(self)

    local hint_intensify = false
    for i,v in ipairs(self.data) do
        if v.general.hashint_exclusiveIntensify then
            hint_intensify = true
            break
        end
    end

    local hint_inlay = false
    for i,v in ipairs(self.data) do
        for k2,v2 in pairs(v.general.hashint_exclusiveQiling or {}) do
            if v2 > 0 then
                hint_inlay = true
                break
            end
        end

        if hint_inlay then
            break
        end
    end

    ui.sethint(self.rootItems.hint_title1,hint_intensify)
    ui.sethint(self.rootItems.hint_title2,hint_inlay)
end

function exclusiveArtifact.makeData(self)
    self.data = {}
    for k,v in pairs(GameScene.layers["slotsInfo"].module.exclusiveArtifactData) do
        local exclusiveArtifact = table.copy(v)
        --判断伙伴是否在阵
        local general = GameScene.layers["slotsInfo"].module:getGeneralIson(exclusiveArtifact.generalIid)
        if general then
            exclusiveArtifact.ison = 1
            exclusiveArtifact.general = general
        else
            exclusiveArtifact.ison = 0
            for k2,v2 in pairs(GameScene.layers["generals"].module.generalsdata) do
                if v2.iid == exclusiveArtifact.generalIid then
                    exclusiveArtifact.general = v2
                    break
                end
            end
        end

        if exclusiveArtifact.general and exclusiveArtifact.general.quality >= 7 then
            table.insert(self.data,exclusiveArtifact)
        end
    end
    gamedata.sortData(self.data,"ison","quality","cid")

    if self.generalcid then
        for i,v in ipairs(self.data) do
            if v.general and v.general.cid == self.generalcid then
                self.generalindex = i
                break
            end
        end
        self.generalcid = nil
    end


    printT(self.data,"makeData")
    print("generalindex",self.generalindex)
    
    return self.data
end

function exclusiveArtifact.init(self,parent,toppos,param)
    printT(param,"exclusiveArtifact__")
    self.rootNode,self.rootItems = CCBReaderLoad("zhuanshushenqi/zhuanshushenqi_up", nil, true, "zhuanshushenqi_up")
    self.animationManager = getAnimationManager(self.rootItems)

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.shenqinode:setPositionY(toppos/2)

    self.rootItems.qilingbagBtn:setSwallowsTouch(true)
    self.rootItems.qilingbagBtn:setTouchPriority(self.touchPriority - 1)
    self.rootItems.qilingbagBtn:addHandleOfControlEvent(function()
    	GameScene:shiftLayer("qiLingBag")
    end, CCControlEventTouchUpInside)
    
    self.rootItems.common_back_btn:setTouchPriority(self.touchPriority)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        print("sid",self.sid)
        GameScene:shiftLayer(GameScene.priorLayer,"up",{sid = self.sid or 1})
    end, CCControlEventTouchUpInside)

    if param and param.cid then
        self.generalcid = param.cid
    end

    if param and param.sid then
        self.sid = param.sid
    end

    self.animationManager:runAnimationsForSequenceNamed(self.selectpage)
    self:reload()
end

function exclusiveArtifact.createGeneralList(self)
    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon.ccbi", nil, true, "generalIcon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }

                ui.tableviewAnimationH(self.generalListTableView,cellCCB,self.titleCellSize.x, self.titleCellSize.y,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            cellCCB:setScale(0.9)

            ccbDocumentControler.i_selectEffect:removeAllChildrenWithCleanup(true)
             -- 设置头像
            local generalData = self.data[a1+1].general
            if generalData.illusionGeneralCid == nil then
                local configGeneral = gamedata.config.general[tostring(generalData.cid)]
                local gdata = ui.getConfigGeneral(generalData)
                if next(gdata) and configGeneral.fashion_id == 0 then
                    ui.setNewIcon(ccbDocumentControler,generalData,0,nil,gdata)
                else
                    ui.setNewIcon(ccbDocumentControler,generalData)
                end
            else
                ui.setNewIcon(ccbDocumentControler,generalData)
            end

            ui.sethint(ccbDocumentControler.i_hint,false)
            if self.selectpage == "intensify" then
                if generalData.hashint_exclusiveIntensify then
                    ui.sethint(ccbDocumentControler.i_hint,true)
                end
            elseif self.selectpage == "inlay" then
                for k,v in pairs(generalData.hashint_exclusiveQiling or {}) do
                    if v > 0 then
                        ui.sethint(ccbDocumentControler.i_hint,true)
                        break
                    end
                end
            end
                        
            if self.generalindex == a1+1 then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                eccb:setScale(1.1)
                ccbDocumentControler.i_selectEffect:addChild(eccb)
            end

            if self.generalListTableView then
                cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            if a1:getIdx()+1<= table.getTableLength(self.data) then
                self:setGeneralIndex(a1:getIdx()+1)
            end

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.generalListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.listscroll:addChild(self.generalListTableView)
    self.generalListTableView:setTouchPriority(self.touchPriority)
    --
    if self.generalindex > 5 then
        self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.generalindex-5) ,0),0.2)
    end
end

function exclusiveArtifact.setGeneralIndex(self,index)
    print("setGeneralIndex",index)
    self.generalindex = index
    self.generalListTableView:reloadData()
    self:reload()
end

function exclusiveArtifact.shiftPage(self,type)
    print("shiftPage",page)
    self.selectpage = type
    gameTouch:clickprofbytime(0.5)
    self.animationManager:runAnimationsForSequenceNamed(self.selectpage)
    self:reload()
end

function exclusiveArtifact.requestPropNum(self)
	UIRequest({type = 12001, order = 33022, cids = {192087,192088,192089,192090,192091}})
end

function exclusiveArtifact.reloadPropNum(self,t)
    self.props = t
    if self.selectpage == "intensify" then
        if self.rootItems.qianghuanode:isVisible() then
            self:set_intensify_spend()
        else
            self:set_baptism_spend()
        end
    end
    gameTouch:clickprofbytime(0.1,true)
end

function exclusiveArtifact.reload(self)
    if GameScene:checkUpdate(10023) or GameScene:checkUpdate(10021) then
        return
    end

    self:makeData()
    if not self.generalListTableView then
        self:createGeneralList()
    else
        self.generalListTableView:reloadData()
    end
    self:reloadHint()
    self:setExclusiveArtifactShow()
    self.rootItems.xili_title:setVisible(false)
    if self.selectpage == "intensify" then
    	self.rootItems.qianghua:setVisible(true)
    	self.rootItems.qianghua:setPositionX(540)
    	self.rootItems.xiangqian:setVisible(false)
    	self.rootItems.xiangqian:setPositionX(9999)
    	-- self.rootItems.qilingNode:setVisible(false)
        self.rootItems.btnNode:setVisible(false)
    	self:set_intensify()
    elseif self.selectpage == "inlay" then
    	self.rootItems.qianghua:setVisible(false)
    	self.rootItems.qianghua:setPositionX(9999)
    	self.rootItems.xiangqian:setVisible(true)
    	self.rootItems.xiangqian:setPositionX(540)
    	-- self.rootItems.qilingNode:setVisible(true)
        self.rootItems.btnNode:setVisible(true)
    	self:set_inlay()
    end

end


function exclusiveArtifact.setExclusiveArtifactShow(self)
	local artifactData = self.data[self.generalindex]
	if not artifactData then return end

    local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
    if self.skeletonName and self.skeletonName == exclusiveConfig.animation then
        return
    end
    --spine
    self.rootItems.skeleton:removeAllChildrenWithCleanup(true)
    local skeleton = ui.createExclusiveSkeleton(exclusiveConfig.animation)
    self.skeletonName = exclusiveConfig.animation
    if skeleton then
        skeleton:setAnimation("stand",true,0)
        self.rootItems.skeleton:addChild(skeleton)
    end
end

function exclusiveArtifact.set_intensify(self)
	local artifactData = self.data[self.generalindex]
	if not artifactData then return end

    printT(artifactData,"set_intensify")

	local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
	local exclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level)]

    printT(exclusiveIntensifyConfig,"exclusiveIntensifyConfig")
	if exclusiveIntensifyConfig and exclusiveIntensifyConfig.intensify_level == 0 then
		--显示洗礼
		self.rootItems.qianghuanode:setVisible(false)
		self.rootItems.qianghuanode:setPositionX(9999)

		self.rootItems.xilinode:setVisible(true)
		self.rootItems.xilinode:setPositionX(0)
        self:set_page_baptism()
	else
		--显示强化
		self.rootItems.qianghuanode:setVisible(true)
		self.rootItems.qianghuanode:setPositionX(0)

		self.rootItems.xilinode:setVisible(false)
		self.rootItems.xilinode:setPositionX(9999)
		self:set_page_intensify()
	end
end


function exclusiveArtifact.intensifyCallback(self,props)
    local cb = function ()
        self:reload()
    end

    local artifactData = self.data[self.generalindex]
    local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
    local exclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level)]
    if exclusiveIntensifyConfig and exclusiveIntensifyConfig.intensify_level == 0 then
        ui.addEffectAutoRemove(self.rootItems.effectNode,"UIEffect/zhuanshushenqi/"..self.xili_names[exclusiveConfig.type],nil,cb)
    else
        ui.addEffectAutoRemove(self.rootItems.effectNode,"UIEffect/zhuanshushenqi/zhuanshushenqi_up",nil,cb)
    end
    gameTouch:clickprofbytime(10)
end

--强化
function exclusiveArtifact.set_page_intensify(self)
    print("set_page_intensify")
	local artifactData = self.data[self.generalindex]
	local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
	local exclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level)]
	local nextExclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level + 1)]

    --基础属性类型 只有数值类型

    local attrInfos = ui.getSTRandNUMs(exclusiveConfig.attribute)[1]
    if exclusiveIntensifyConfig then
        self.rootItems.upLevel:setString(artifactData.intensify_level)
        self.rootItems.upAttr:setString(gameConfig.strings.attr_type[attrInfos.str].."+"..exclusiveIntensifyConfig.value)
    else
        self.rootItems.upLevel:setString(0)
        self.rootItems.upAttr:setString(gameConfig.strings.attr_type[attrInfos.str].."+0")
    end

    --下一级
    if artifactData.maxlevel == 1 then
        self.rootItems.next_upLevelNode:setVisible(false)
        self.rootItems.next_upAttr:setString("")
    else
        self.rootItems.next_upLevelNode:setVisible(true)
        if nextExclusiveIntensifyConfig.intensify_level == 0 then
            self.rootItems.next_up_levelLab:setString("洗礼等级：")
            self.rootItems.next_upLevel:setString(nextExclusiveIntensifyConfig.baptism_level)
            self.rootItems.next_upAttr:setString("")
        else
            self.rootItems.next_up_levelLab:setString("强化等级：")
            self.rootItems.next_upLevel:setString(nextExclusiveIntensifyConfig.intensify_level)
            self.rootItems.next_upAttr:setString(gameConfig.strings.attr_type[attrInfos.str].."+"..nextExclusiveIntensifyConfig.value)
        end
    end
    self:requestPropNum()
end


function exclusiveArtifact.set_intensify_spend(self)
    local artifactData = self.data[self.generalindex]
    local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
    local exclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level)]
    local nextExclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level + 1)]

    --消耗
    local spendPropInfo = {}
    --强化多少次 最多5次
    local minIntensifyInfo = {num = 1,spendnum = 0}
    local maxIntensifyInfo = {num = 5,spendnum = 0}

    if artifactData.maxlevel == 1 then
        spendPropInfo = gamedata.getIDandNUMs(exclusiveIntensifyConfig.consumption)[1]
    else
        spendPropInfo = gamedata.getIDandNUMs(nextExclusiveIntensifyConfig.consumption)[1]
        
        minIntensifyInfo.num = 1
        minIntensifyInfo.spendnum = spendPropInfo.num

        maxIntensifyInfo.num = 0
        maxIntensifyInfo.spendnum = 0

        local intensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)]
        for i=1,5 do
            if intensifyConfig[tostring(artifactData.level + i)] then
                if  intensifyConfig[tostring(artifactData.level + i)].intensify_level == 0  then
                    break
                end
                local nextSpendPropInfo = gamedata.getIDandNUMs(intensifyConfig[tostring(artifactData.level + i)].consumption)[1]
                maxIntensifyInfo.num = maxIntensifyInfo.num + 1
                maxIntensifyInfo.spendnum = maxIntensifyInfo.spendnum + nextSpendPropInfo.num
            end
        end
    end

    local propConfig = ui.IDconfig(spendPropInfo.cid)
    -- ui.setNewIcon(self.rootItems,{cid = spendPropInfo.cid})

    self.rootItems["up_propBtn"]:setTouchPriority(self.touchPriority)
    self.rootItems["up_propBtn"]:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(spendPropInfo.cid)
    end, CCControlEventTouchUpInside)

    setSpriteFrameByName(self.rootItems["up_propIcon1"],propConfig.icon)
    setSpriteFrameByName(self.rootItems["up_propIcon2"],propConfig.icon)
    setSpriteFrameByName(self.rootItems["up_propIcon3"],propConfig.icon)
    
    local haveNum = self.props[tostring(spendPropInfo.cid)] or 0
    
    ui.setLabelString(self.rootItems.up_propName,propConfig.name,18,36)
    ui.setLabelString(self.rootItems.up_propNum,":"..haveNum,18,36)
    ui.setLabelString(self.rootItems.up_spend1,minIntensifyInfo.spendnum,haveNum >= minIntensifyInfo.spendnum and 18 or 24,36)
    ui.setLabelString(self.rootItems.up_spend2,maxIntensifyInfo.spendnum,haveNum >= maxIntensifyInfo.spendnum and 18 or 24,36)
    
    if haveNum < minIntensifyInfo.spendnum then
        ui.addGray("CCLabelTTF",self.rootItems["up_doLab1"])
        ui.addGray("CCControlButton",self.rootItems["up_doBtn1"])
    elseif artifactData.maxlevel == 1 then
        ui.addGray("CCLabelTTF",self.rootItems["up_doLab1"])
        ui.addGray("CCControlButton",self.rootItems["up_doBtn1"])
    else
        ui.removeGray("CCLabelTTF",self.rootItems["up_doLab1"])
        ui.removeGray("CCControlButton",self.rootItems["up_doBtn1"])
    end

    ui.setLabelString(self.rootItems["up_doLab1"],"强化1次",19)
    self.rootItems["up_doBtn1"]:setTouchPriority(self.touchPriority)
    self.rootItems["up_doBtn1"]:addHandleOfControlEvent(function()
        if artifactData.maxlevel == 1 then
            runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifactNew",7)})
        elseif haveNum < minIntensifyInfo.spendnum then
            runGamePrompt({msg = shortPropById(spendPropInfo.cid)})
        else
            UIRequest({type = 8102, generalIid = artifactData.generalIid,num = 1,spend = {cid = spendPropInfo.cid,num = minIntensifyInfo.spendnum}})
        end
    end, CCControlEventTouchUpInside)

    if haveNum < maxIntensifyInfo.spendnum then
        ui.addGray("CCLabelTTF",self.rootItems["up_doLab2"])
        ui.addGray("CCControlButton",self.rootItems["up_doBtn2"])
    elseif artifactData.maxlevel == 1 then
        ui.addGray("CCLabelTTF",self.rootItems["up_doLab2"])
        ui.addGray("CCControlButton",self.rootItems["up_doBtn2"])
    else
        ui.removeGray("CCLabelTTF",self.rootItems["up_doLab2"])
        ui.removeGray("CCControlButton",self.rootItems["up_doBtn2"])
    end

    ui.setLabelString(self.rootItems["up_doLab2"],"强化"..maxIntensifyInfo.num.."次",19)
    self.rootItems["up_doBtn2"]:setTouchPriority(self.touchPriority)
    self.rootItems["up_doBtn2"]:addHandleOfControlEvent(function()
        if artifactData.maxlevel == 1 then
            runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifactNew",7)})
        elseif haveNum < maxIntensifyInfo.spendnum then
            runGamePrompt({msg = shortPropById(spendPropInfo.cid)})
        else
            UIRequest({type = 8102, generalIid = artifactData.generalIid, num = maxIntensifyInfo.num,spend = {cid = spendPropInfo.cid,num = maxIntensifyInfo.spendnum}})
        end
    end, CCControlEventTouchUpInside)
end

--洗礼
function exclusiveArtifact.set_page_baptism(self)
    print("set_page_baptism")
    local artifactData = self.data[self.generalindex]
    printT(artifactData,"artifactData")
    local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
    local exclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level)]
    local nextExclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level + 1)]

    if not nextExclusiveIntensifyConfig then
        return
    end
    print(self.xili_names[exclusiveConfig.type])
    self.rootItems.xili_title:setVisible(true)
    setSpriteFrameByName(self.rootItems["xili_title"],self.xili_names[exclusiveConfig.type])
    if exclusiveIntensifyConfig then
        self.rootItems.xiliLevel:setString(artifactData.baptism_level)
    else
        self.rootItems.xiliLevel:setString(0)
    end

    printT(nextExclusiveIntensifyConfig,"nextExclusiveIntensifyConfig")
    self.rootItems.next_xiliLevel:setString(nextExclusiveIntensifyConfig.baptism_level)

    self.rootItems.xilidesc:setString(string.format(gameConfig.strings:string_common("exclusiveArtifactNew",8), nextExclusiveIntensifyConfig.baptism_level))
    local breakskill = gamedata.config.breakskill[tostring(exclusiveConfig["skill"..nextExclusiveIntensifyConfig.baptism_level])]
    self.rootItems.xili_breakskill:setString(breakskill.desc)
    self:requestPropNum()
end

function exclusiveArtifact.set_baptism_spend(self)
    local artifactData = self.data[self.generalindex]
    local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
    local exclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(artifactData.level)]
    --消耗
    local spendPropInfo = gamedata.getIDandNUMs(exclusiveIntensifyConfig.consumption)[1]

    local propConfig = ui.IDconfig(spendPropInfo.cid)
    -- ui.setNewIcon(self.rootItems,{cid = spendPropInfo.cid},1)

    self.rootItems["xili_propBtn"]:setTouchPriority(self.touchPriority)
    self.rootItems["xili_propBtn"]:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(spendPropInfo.cid)
    end, CCControlEventTouchUpInside)

    setSpriteFrameByName(self.rootItems["xili_propIcon1"],propConfig.icon)
    setSpriteFrameByName(self.rootItems["xili_propIcon2"],propConfig.icon)
    
    local haveNum = self.props[tostring(spendPropInfo.cid)] or 0
    ui.setLabelString(self.rootItems.xili_propName,propConfig.name,18,36)
    ui.setLabelString(self.rootItems.xili_propNum,":"..haveNum,18,36)
    ui.setLabelString(self.rootItems.xili_spend,spendPropInfo.num,haveNum >= spendPropInfo.num and 18 or 24,36)


    if haveNum < spendPropInfo.num then
        ui.addGray("CCLabelTTF",self.rootItems["xiliLab"])
        ui.addGray("CCControlButton",self.rootItems["xiliBtn"])
    elseif artifactData.maxlevel == 1 then
        ui.addGray("CCLabelTTF",self.rootItems["xiliLab"])
        ui.addGray("CCControlButton",self.rootItems["xiliBtn"])
    else
        ui.removeGray("CCLabelTTF",self.rootItems["xiliLab"])
        ui.removeGray("CCControlButton",self.rootItems["xiliBtn"])
    end

    ui.setLabelString(self.rootItems["xiliLab"],"洗 礼",19)
    self.rootItems["xiliBtn"]:setTouchPriority(self.touchPriority)
    self.rootItems["xiliBtn"]:addHandleOfControlEvent(function()
        if haveNum < spendPropInfo.num then
            runGamePrompt({msg = shortPropById(spendPropInfo.cid)})
        elseif artifactData.maxlevel == 1 then
            runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifactNew",7)})
        else
            UIRequest({type = 8102, generalIid = artifactData.generalIid,num = 0,spend = {cid = spendPropInfo.cid,num = spendPropInfo.num}})
        end
    end, CCControlEventTouchUpInside)
end

function exclusiveArtifact.inlayCallback(self,activeSuitId)
    print("inlayCallback")
    -- local cb = function ()
    --     self:reload()
    -- end

    -- local artifactData = self.data[self.generalindex]
    -- local special_effects = nil
    
    -- if activeSuitId and gamedata.config.exclusive_device_spirit_suit[tostring(activeSuitId)] then
    --    local suitConfig = gamedata.config.exclusive_device_spirit_suit[tostring(activeSuitId)]
    --    if suitConfig.special_effects ~= "" then
    --        special_effects = suitConfig.special_effects
    --    end
    -- end

    -- if special_effects then
    --     ui.addEffectAutoRemove(self.rootItems.effectNode,"UIEffect/zhuanshushenqi/"..special_effects,nil,cb)
    --     gameTouch:clickprofbytime(1.5)
    -- else
    --     cb()
    -- end

    self:reload()
end

--镶嵌
function exclusiveArtifact.set_inlay(self)
	local artifactData = self.data[self.generalindex]
    local exclusiveConfig = gamedata.config.exclusive[tostring(artifactData.cid)]
    if not artifactData then return end

    for i=1,6 do
        local qilingId = artifactData["inlayId"..i]
        local qilingData = GameScene.layers["qiLingBag"].module.data[qilingId]
        if qilingId > 0 and qilingData then
            local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(qilingData.cid)]
            setSpriteFrameByName(self.rootItems["qiling"..i],qilingConfig.icon)
        else
            setSpriteFrameByName(self.rootItems["qiling"..i],gameConfig.images.alpha)
        end
    end

    local special_effects = nil
    for i=1,3 do
        if artifactData["suitId"..i] and gamedata.config.exclusive_device_spirit_suit[tostring(artifactData["suitId"..i])] then
           local suitConfig = gamedata.config.exclusive_device_spirit_suit[tostring(artifactData["suitId"..i])]
           if suitConfig.special_effects ~= "" then
               special_effects = suitConfig.special_effects
           end
        end
    end
    
    self.rootItems.qilingEffectNode:removeAllChildrenWithCleanup(true)
    if special_effects then
        local node,items = CCBReaderLoad("UIEffect/zhuanshushenqi/"..special_effects, nil, true, "effect")
        self.rootItems.qilingEffectNode:addChild(node)
    end

    local suitInfos = self.getExclusiveArtifactSuitInfos(artifactData)
    for i=1,3 do
        if suitInfos[i] then
            self.rootItems["suit_desc"..i]:setString(suitInfos[i].suit_desc.."："..suitInfos[i].breakskill_desc)
            self.rootItems["suit_no"..i]:setVisible(false)
        else
            self.rootItems["suit_desc"..i]:setString("")
            self.rootItems["suit_no"..i]:setVisible(true)
        end
    end

    local isinlay = false
    for i=1,6 do

        if artifactData["inlayId"..i] and artifactData["inlayId"..i] > 0 then
            isinlay = true
        end

        if artifactData.general and artifactData.general.hashint_exclusiveQiling and artifactData.general.hashint_exclusiveQiling[tostring(i)] > 0 then
            ui.sethint(self.rootItems["qiling_hint"..i],true)
        else
            ui.sethint(self.rootItems["qiling_hint"..i],false)
        end

        self.rootItems["qilingBtn"..i]:setTouchPriority(self.touchPriority)
        self.rootItems["qilingBtn"..i]:addHandleOfControlEvent(function()
            if artifactData["inlayId"..i] and artifactData["inlayId"..i] > 0 then
                --打开器灵详情
                local qilingData = GameScene.layers["qiLingBag"].module.data[artifactData["inlayId"..i]]
                gameWindows:openWindow("qilingInfo",{iid = qilingData.iid,opt = 2})
            else
                --打开镶嵌
                local cb = function (qiLingData)
                    UIRequest({type=8104,generalIid = artifactData.generalIid,pos = i,qiLingIid = qiLingData.iid})
                end
                gameWindows:openWindow("qilingSelect",{type = i},cb)
            end
        end, CCControlEventTouchUpInside)


    end

    if not isinlay then
        ui.addGray("CCControlButton",self.rootItems["attrBtn"])
    else
        ui.removeGray("CCControlButton",self.rootItems["attrBtn"])
    end

    self.rootItems.attrBtn:setSwallowsTouch(true)
    self.rootItems.attrBtn:setTouchPriority(self.touchPriority - 1)
    self.rootItems.attrBtn:addHandleOfControlEvent(function()
        print("属性总览")
        if isinlay then
            gameWindows:openWindow("exclusiveArtifactAttr",artifactData)
        else
            runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifactNew",9)})
        end
    end, CCControlEventTouchUpInside)


end

function exclusiveArtifact.getExclusiveArtifactSuitInfos(data)
    local suitInfos = {}

    for i=1,3 do
        if data["suitId"..i] and data["suitId"..i] > 0 then
            local suitConfig = gamedata.config.exclusive_device_spirit_suit[tostring(data["suitId"..i])]
            local breakskillConfig = gamedata.config.breakskill[tostring(suitConfig.suit_skill)]

            table.insert(suitInfos,{
                    id              = data["suitId"..i],
                    suitType        = suitConfig.suit,
                    suitNum         = suitConfig.activate_suit,
                    suit_desc       = suitConfig.suit_describe,
                    breakskill_desc = breakskillConfig.desc,
                    order           = suitConfig.sorting,
                    lineNum         = breakskillConfig.desc_param,
                })
        end
    end

    --单件类型 排序放在最前面
    for i=1,3 do
        if suitInfos[i] then
            local suitSingle = true
            local suitInfo = suitInfos[i]
            for j,v in ipairs(suitInfos) do
                if i ~= j  then
                    local config = gamedata.config.exclusive_device_spirit_suit[tostring(v.id)]
                    if config.suit == suitInfo.suitType then
                        suitSingle = false
                        break
                    end
                end
            end
            if suitSingle then
                suitInfo.order = suitInfo.order - 10000
            end
        end
    end
    table.sort(suitInfos,function (a,b )
        return a.order < b.order
    end)

    return suitInfos
end

function exclusiveArtifact.UIUpdateData(self)
    GameScene:checkUpdate(10021)
end

function exclusiveArtifact.clear(self)
    self.selectpage = "intensify"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.generalListTableView = nil
    self.data = {}
    self.props = {}
    self.generalcid = nil
    self.generalindex = 1
    self.skeletonName = nil
end

return exclusiveArtifactXx  