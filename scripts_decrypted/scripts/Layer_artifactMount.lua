--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 18/6/12
-- Time: 上午10:13
-- To change this template use File | Settings | File Templates.
--

local artifactMount = {

    rootNode = nil,
    rootItems = nil,

    touchPriority  = -101,
   
    artifactSelect = nil,
    artifacts = nil,
    isSetB = false,
    jewelUpUseId = 20680,
    props = {},
    fromLayer = nil,
    returnParam = nil,
    getUseIdNumFunc = nil,
}

function artifactMount.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_xiangqian", nil, true, "shenqi_xiangqian")

    self:initFixedString()
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.middlenode:setPositionY(160 + (toppos - 160)/2 + 100)
    self.rootItems.bottomnode:setPositionY(160 + 20 + 260)
    print("lipurposes you set the isSetB")
    self.isSetB = false
    self.artifactSelect = param and param.artifact
    self.fromLayer = param and param.isFrom
    self.returnParam = param and param.param
    self:setBtnFuncs()
    self:getUseIdNum()
    self.getUseIdNumFunc = function()
        self:setArtifactData()
    end
end

function artifactMount.getUseIdNum(self,t)
    self.props = t or self.props
    if not self.props[tostring(self.jewelUpUseId)] then
        UIRequest({type = 12001, order = 33014, cids = {self.jewelUpUseId}})
        return
    end
    if self.getUseIdNumFunc then
        self.getUseIdNumFunc()
        self.getUseIdNumFunc = nil
    end
end

function artifactMount.setArtifactData(self,t)
    if not GameScene.layers["artifactList"].module.artifactData then 
        GameScene:addUpdate(10032)
    end
    if not GameScene.layers["artifactList"].module.jewelData then 
        GameScene:addUpdate(10031)
    end
    if GameScene:checkUpdate(10031) or GameScene:checkUpdate(10032) then
        return 
    end
    self.artifacts = GameScene.layers["artifactList"].module.artifactData.checked
    if not self.isSetB then
        self:setAttrInfoShow()
    end
end


function  artifactMount.setBtnFuncs(self)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        if self.fromLayer then
            --GameScene:shiftLayer("slotsInfo","up")
            GameScene:shiftLayer(self.fromLayer,"up",self.returnParam)
        else
            GameScene:shiftLayer("artifact","up")
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.jewelCmdBtn:addHandleOfControlEvent(function()
        gameWindows:openWindow("jewelUp",{selectId = nil},nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.jewelCmdBtn:setSwallowsTouch(true)
    self.rootItems.jewelCmdBtn:setTouchPriority(self.touchPriority)

    self.rootItems.jewelEftBtn:addHandleOfControlEvent(function()
        if self.artifactSelect then
            gameWindows:openWindow("jewelEffect",self.artifactSelect,nil)
        else
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",63)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.jewelEftBtn:setSwallowsTouch(true)
    self.rootItems.jewelEftBtn:setTouchPriority(self.touchPriority)

    self.rootItems.artifactAddBtn:addHandleOfControlEvent(function()
        if not self.artifacts then
            return
        end
        
        gameWindows:openWindow("artifactSelect",{data= {artifacts = self.artifacts,hasSelect = {self.artifactSelect}},showType = "checked1"},function (selectArtifact)
            print("lipurpose set selectArtifact call")
            if selectArtifact then
                self.artifactSelect = selectArtifact
                self:setAttrInfoShow()
            end
        end)
    end, CCControlEventTouchUpInside)
    self.rootItems.artifactAddBtn:setSwallowsTouch(true)
    self.rootItems.artifactAddBtn:setTouchPriority(self.touchPriority)

    for i = 1,4 do
        self.rootItems["jewelBtn"..i]:addHandleOfControlEvent(function()
            if not self.artifactSelect then
                runGamePrompt({msg = gameConfig.strings:string_common("artifact",63)})
                return
            end
            if self.artifactSelect["jewel"..i] > 0 then
                gameWindows:openWindow("jewelInfo",{cid = self.artifactSelect["jewel"..i],artifact = self.artifactSelect,isUp = true,pos = i},nil)
            elseif self.artifactSelect["jewel"..i] == 0 then
                gameWindows:openWindow("jewelSelect",{artifact = self.artifactSelect,pos = i},nil)
            else
                local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
                if GameScene.roleinfo.level < config["hole_lv"..i] then
                    runGamePrompt({msg = gameConfig.strings:lvOpen(config["hole_lv"..i])})
                else
                    gameWindows:openWindow("artifactOpenPos",{artifact = self.artifactSelect,pos = i},nil)
                end
            end
        end, CCControlEventTouchUpInside)
        self.rootItems["jewelBtn"..i]:setSwallowsTouch(true)
        self.rootItems["jewelBtn"..i]:setTouchPriority(self.touchPriority)
    end

    for i = 1,4 do
        self.rootItems["upBtn"..i]:addHandleOfControlEvent(function()
            if  self.artifactSelect and self.artifactSelect["jewel"..i] > 0 then
                local isOk = 1
                local config = gamedata.config.trump_gem[tostring(self.artifactSelect["jewel"..i])]
                local jewelData = GameScene.layers["artifactList"].module.jewelData.primeData
                if config.per_cid <= 0 then
                    return runGamePrompt({msg = gameConfig.strings:string_common("artifact",2)})
                end
                local configN = gamedata.config.trump_gem[tostring(config.per_cid)]
                if GameScene.roleinfo.level < configN.gem_lvbet then
                    return runGamePrompt({msg = gameConfig.strings:string_format({"artifact",100},{configN.gem_lvbet})})
                end
                local useTable = ui.getIDandNUMs(config.gem_lv)
                local usePropNum = 0
                local useJewelNum = 0
                for k,v in ipairs(useTable) do
                    if v.cid == self.artifactSelect["jewel"..i] then
                        useJewelNum = v.num
                        if not jewelData[tostring(v.cid)] or jewelData[tostring(v.cid)].num + 1 < v.num then
                            isOk = 2
                        end
                    else
                        usePropNum = v.num
                        if self.props[tostring(v.cid)] < v.num then
                            isOk = 3
                        end
                    end
                end
                local function callFunc()
                    if isOk ~= 1 then
                        if isOk == 2 then
                            return runGamePrompt({msg = gameConfig.strings:string_common("artifact",54)})
                        else
                            local idConfig = ui.IDconfig(self.jewelUpUseId)
                            return runGamePrompt({msg = gameConfig.strings:string_format({"fixedStringA",82},{idConfig.name})})
                        end
                    end
                    gameTouch:clickprofbytime(0.5)
                    UIRequest({type = 5506,iid = self.artifactSelect.iid,pos = i})
                end
                local addStr = ""
                if usePropNum > 0 then
                    local idConfig = ui.IDconfig(self.jewelUpUseId)
                    addStr = ","..usePropNum..idConfig.name
                end
                
                gameWindows:openWindow("artifactOpenPos",{artifact = self.artifactSelect,pos = i},nil)
                --gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_format({"artifact",71},{useJewelNum - 1,config.name,addStr}),fontId = (isOk == 1) and 3 or 47},callFunc)
            end
        end, CCControlEventTouchUpInside)
        self.rootItems["upBtn"..i]:setSwallowsTouch(true)
        self.rootItems["upBtn"..i]:setTouchPriority(self.touchPriority)

        self.rootItems["equipBtn"..i]:addHandleOfControlEvent(function()
            if not self.artifactSelect then
                runGamePrompt({msg = gameConfig.strings:string_common("artifact",63)})
            end
            if self.artifactSelect["jewel"..i] < 0 then
                local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
                if GameScene.roleinfo.level < config["hole_lv"..i] then
                    runGamePrompt({msg = gameConfig.strings:lvOpen(config["hole_lv"..i])})
                else
                    gameWindows:openWindow("artifactOpenPos",{artifact = self.artifactSelect,pos = i},nil)
                end
            elseif self.artifactSelect["jewel"..i] == 0 then
                gameWindows:openWindow("jewelSelect",{artifact = self.artifactSelect,pos = i},nil)
            end
        end, CCControlEventTouchUpInside)
        self.rootItems["equipBtn"..i]:setSwallowsTouch(true)
        self.rootItems["equipBtn"..i]:setTouchPriority(self.touchPriority)

    end
end

function artifactMount.setAttrInfoShow(self)
    self.isSetB = true
    local config = self.artifactSelect and gamedata.config.trump[tostring(self.artifactSelect.cid)] or nil
    self.totalLevel = 0
    for i = 1,4 do
        self:setJewelInfo(i,config)
        if self.artifactSelect and self.artifactSelect["jewel"..i] > 0 then
            local config = gamedata.config.trump_gem[tostring(self.artifactSelect["jewel"..i])]
            self.totalLevel = self.totalLevel + config.lv
        end
    end

    if self.artifactSelect then
        self.rootItems.addSp:setVisible(false)
        self:setArtifactShow(self.totalLevel)
    else
        self.rootItems.addSp:setVisible(true)
    end
end

function artifactMount.upDateJewel(self,t)
    self.props = {}
    self.artifacts = nil
    self:setArtifactData()
    self.getUseIdNumFunc = function ()
        for i = 1,4 do
            if t.artifact["jewel"..i] ~= self.artifactSelect["jewel"..i] then
                if self.artifactSelect["jewel"..i] > 0 then
                    local config = gamedata.config.trump_gem[tostring(self.artifactSelect["jewel"..i])]
                    self.totalLevel = self.totalLevel - config.lv
                end
                if t.artifact["jewel"..i] > 0 then
                    local config = gamedata.config.trump_gem[tostring(t.artifact["jewel"..i])]
                    self.totalLevel = self.totalLevel + config.lv
                end
                self.artifactSelect = t.artifact
                local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
                self:setArtifactShow(self.totalLevel)
                return self:setJewelInfo(i,config)
            else
                local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
                self:setJewelInfo(i,config)
            end
        end
    end
    self:getUseIdNum()
end

function artifactMount.jewelUpdate(self,t)
    if not self.artifactSelect then
        return
    end
    local config = self.artifactSelect and gamedata.config.trump[tostring(self.artifactSelect.cid)] or nil
    for i = 1,4 do
        self:setJewelInfo(i,config)
    end
end

function artifactMount.reloadData(self,t)
    self:setArtifactData()
    self.props = {}
    self.getUseIdNumFunc = function ()
        for i = 1,4 do
            if t.artifact["jewel"..i] ~= self.artifactSelect["jewel"..i]  then
                if self.artifactSelect["jewel"..i] < 0 then
                    runGamePrompt({msg = {color = ui.greenColor,str = gameConfig.strings:string_common("artifact",102)}})
                else
                    -- if t.artifact["jewel"..i] == 0 then
                    --     runGamePrompt({msg = {color = ui.greenColor,str = gameConfig.strings:string_common("artifact",118)}})
                    -- else
                    --     runGamePrompt({msg = {color = ui.greenColor,str = gameConfig.strings:string_common("artifact",103)}})
                    -- end
                end
                if self.artifactSelect["jewel"..i] > 0 then
                    local config = gamedata.config.trump_gem[tostring(self.artifactSelect["jewel"..i])]
                    self.totalLevel = self.totalLevel - config.lv
                end
                if t.artifact["jewel"..i] > 0 then
                    local config = gamedata.config.trump_gem[tostring(t.artifact["jewel"..i])]
                    self.totalLevel = self.totalLevel + config.lv
                end
                self.artifactSelect = t.artifact
                local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
                self:setArtifactShow(self.totalLevel)
                self:setJewelInfo(i,config)
            elseif t.artifact["jewel"..i] < 0 then
                local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
                self:setJewelInfo(i,config)
            end
        end
    end
    self:getUseIdNum()
end

function artifactMount.setJewelInfo(self,pos,config)
    if self.artifactSelect and self.artifactSelect["jewel"..pos] > 0 then
        self.rootItems["jewelNameBg"..pos]:setVisible(true)
        local jewelConfig = gamedata.config.trump_gem[tostring(self.artifactSelect["jewel"..pos])]
        self.rootItems["jewel"..pos]:setVisible(true)
        setSpriteFrameByName(self.rootItems["jewel"..pos],jewelConfig.icon)
        --self.rootItems["jewel"..pos]:setScale(0.5)

        self.rootItems["jewelAdd"..pos]:setVisible(false)
        self.rootItems["suo"..pos]:setVisible(false)
        ui.setLabelString(self.rootItems["openLevel"..pos],jewelConfig.name,jewelConfig.quality * 2)

        self.rootItems["i_button"..((pos > 1) and ("_"..(pos-1)) or "")]:addHandleOfControlEvent(function()
            if self.artifactSelect["jewel"..pos] and self.artifactSelect["jewel"..pos] > 0 then
                gameWindows:openWindow("jewelInfo",{cid = self.artifactSelect["jewel"..pos],isUp = false},nil)
            end
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button"..((pos > 1) and ("_"..(pos-1)) or "")]:setTouchPriority(self.touchPriority)

        local type,num = "",""
        type = gameConfig.strings.attr_type[jewelConfig.attr]
        num = "+"..(jewelConfig.attrValue)*(jewelConfig.attrType == "value" and 1 or 1)..(jewelConfig.attrType == "value" and "" or "%")
        ui.setLabelString(self.rootItems["jewelDes"..pos],type..num,80)
        self.rootItems["jewelDesN"..pos]:removeAllChildrenWithCleanup(true)
        self.rootItems["upNode"..pos]:setVisible(true)
        self.rootItems["equipNode"..pos]:setVisible(false)

        
        if CheckCanUpgrade(self.artifactSelect["jewel"..pos],1,self.props[tostring(self.jewelUpUseId)],true) then
            ui.removeGray("CCControlButton",self.rootItems["upBtn"..pos])
        else
            ui.addGray("CCControlButton",self.rootItems["upBtn"..pos])
        end
    else
        self.rootItems["jewel"..pos]:setVisible(false)
        self.rootItems["jewelDesN"..pos]:removeAllChildrenWithCleanup(true)
        if not self.artifactSelect or self.artifactSelect["jewel"..pos] < 0 then
            self.rootItems["jewelAdd"..pos]:setVisible(false)
            self.rootItems["suo"..pos]:setVisible(true)
            if not self.artifactSelect then
                self.rootItems["jewelNameBg"..pos]:setVisible(false) 
                ui.setLabelString(self.rootItems["openLevel"..pos],"",14)
                ui.setLabelString(self.rootItems["jewelDes"..pos],gameConfig.strings:string_common("artifact",65),80)
                ui.addGray("CCControlButton",self.rootItems["equipBtn"..pos])
            else
                self.rootItems["jewelNameBg"..pos]:setVisible(true)
                if GameScene.roleinfo.level < config["hole_lv"..pos] then
                    ui.setLabelString(self.rootItems["openLevel"..pos],gameConfig.strings:lvOpen(config["hole_lv"..pos]),14)
                    ui.setLabelString(self.rootItems["jewelDes"..pos],gameConfig.strings:string_format({"artifact",66},{config["hole_lv"..pos]}),80)
                    ui.addGray("CCControlButton",self.rootItems["equipBtn"..pos])
                else
                    ui.setLabelString(self.rootItems["openLevel"..pos],gameConfig.strings:string_common("artifact",22),14)
                    local useTable = ui.getIDandNUMs(config["hole_cost"..pos])
                    local anS = " "
                    local icon
                    for k,v in pairs(useTable) do
                        local itemCconfig = ui.IDconfig(v.cid)
                        useId = v.cid
                        useNum = v.num
                        local idname = itemCconfig.name
                        icon = itemCconfig.icon
                        anS = anS..v.num
                    end
                    if #useTable > 0 then
                        ui.setLabelString(self.rootItems["jewelDes"..pos],"",80)
                        ui.createRichLabel({
                            {fontID = 80,content = gameConfig.strings:string_format({"artifact",97},{""})},
                            {fontID = (self.props[tostring(useTable[1].cid)] and self.props[tostring(useId)] >= useTable[1].num and 80 or 126),content = anS},
                            {fontID = 0,content = icon,scale = 0.4},
                        },self.rootItems["jewelDesN"..pos],false)
                    else
                        ui.setLabelString(self.rootItems["jewelDes"..pos],gameConfig.strings:string_common("artifact",67),80)
                    end
                    
                    ui.removeGray("CCControlButton",self.rootItems["equipBtn"..pos])
                end
            end
            ui.setLabelString(self.rootItems["equipLab"..pos],gameConfig.strings:string_common("artifact",69),19)
            setControlButtonFrame(self.rootItems["equipBtn"..pos],"b_n_button1","b_n_button1","b_n_button1")
        else
            self.rootItems["jewelAdd"..pos]:setVisible(true)
            self.rootItems["suo"..pos]:setVisible(false)
            ui.setLabelString(self.rootItems["openLevel"..pos],gameConfig.strings:string_common("artifact",23),14)
            ui.setLabelString(self.rootItems["jewelDes"..pos],gameConfig.strings:string_common("artifact",68),80)
            ui.setLabelString(self.rootItems["equipLab"..pos],gameConfig.strings:string_common("artifact",6),19)
            ui.removeGray("CCControlButton",self.rootItems["equipBtn"..pos])
            setControlButtonFrame(self.rootItems["equipBtn"..pos],"b_n_button2","b_n_button2","b_n_button2")
        end

        self.rootItems["upNode"..pos]:setVisible(false)
        self.rootItems["equipNode"..pos]:setVisible(true)
    end
    self:setJewelIcon(self.rootItems,(self.artifactSelect and self.artifactSelect["jewel"..pos] or -1),pos)
end

function artifactMount.setJewelIcon(self,items,jewelData,number)
    print("lipurposes you set this this this")
    local key_Ex = number <= 1 and "" or "_"..(number - 1)
    items["toMount"..key_Ex]:setVisible(false)
    items["goToMount"..key_Ex]:setVisible(false)
    items["suo"..key_Ex]:setVisible(jewelData < 0)
    items["i_notice"..key_Ex]:setVisible(false)
    items["in_name"..key_Ex]:setVisible(false)
    if jewelData > 0 then
        local config = gamedata.config.trump_gem[tostring(jewelData)]
        setSpriteFrameByName(items["i_k_quality"..key_Ex], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(items["i_quality"..key_Ex], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(items["i_icon"..key_Ex], config.icon and config.icon or "alpha")
        ui.setSpriteTextureRect(items["i_icon"..key_Ex],0,0,150,150)
        --ui.setLabelString(items["in_name"..key_Ex],config.name,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
    else
        setSpriteFrameByName(items["i_k_quality"..key_Ex], "b_s_iconk1")
        setSpriteFrameByName(items["i_quality"..key_Ex], "b_iconbg8")
        setSpriteFrameByName(items["i_icon"..key_Ex], "alpha")
        -- if jewelData == 0 then
        --     ui.setLabelString(items["in_name"..key_Ex],gameConfig.strings:string_common("fixedString","mofu",1),28)
        -- else
        --     ui.setLabelString(items["in_name"..key_Ex],gameConfig.strings:string_common("moreCommon","weikaiqi"),28)
        -- end
    end
    
end

function artifactMount.setArtifactShow(self,level)
    local config = gamedata.config.trump[tostring(self.artifactSelect.cid)]
    local shenqiSkeletonMeta = require"SkeletonShenqi"
    local skeleton = shenqiSkeletonMeta:init(config,level)
    skeleton:setPosition(0,0)
    skeleton:setAnimation("stand",true,0)
    self.rootItems.artifactNode:removeAllChildrenWithCleanup(true)
    self.rootItems.artifactNode:addChild(skeleton.root or skeleton)
end




function artifactMount.initFixedString(self)
    ui.setLabelString(self.rootItems.fixed1,gameConfig.strings:string_common("artifact",57),18)
    for i = 1,4 do
        ui.setLabelString(self.rootItems["upLab"..i],gameConfig.strings:string_common("general",3),19)
    end
end




function artifactMount.clear(self)
    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil

    self.artifacts = nil
    self.artifactSelect = nil
    self.fromLayer = nil
    self.returnParam = nil
    self.getUseIdNumFunc = nil
    self.props = {}
end


return artifactMount   U  