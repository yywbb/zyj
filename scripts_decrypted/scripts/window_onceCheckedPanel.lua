--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/5
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local onceCheckedPanel = {
    root = nil,

    tenCCB = nil,
    tenItems = nil,
    tendata = nil,

    yulanindex = 0,
    loadindex = 0,
    isscrolltouched = false,
    showType = "1",
}

function onceCheckedPanel.shiftType(self,data)
    self.showType = data.showType
    self.root:removeAllChildrenWithCleanup(true)

    self.tenCCB,self.tenItems = CCBReaderLoad("shenqi_new/shenqi_yijiandazao", nil, true, "shenqi_yijiandazao")

    self.tendata = data.artifactList
    -- printT(self.tendata," onceCheckedPanel.shiftType ")
    self.tenCCB:setAnchorPoint(ccp(0.5,0.5))

    self.root:addChild(self.tenCCB)
    self.rootNode = self.tenCCB
    --
    -- 防止在listnode外还可点击
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","recruit",touchbegin)
    local function touchend(pos)
    end
    gameTouch:rigistFunc("end","recruit",touchend)
    -- 
    self:reloadten()
end

function onceCheckedPanel.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.callback = callback
    self:shiftType(data)
    return self.root
end

function onceCheckedPanel.reload(self,data,callback)
    self.callback = callback
    self:shiftType(data)
end


function onceCheckedPanel.repeataction(self,ccb,item)
    self:setOneyulan(ccb,item,ccp(-446,100))
    local first = CCMoveTo:create(10, ccp(1338, 100))
    ccb:runAction(CCSequence:createWithTwoActions(first, CCCallFunc:create(function()
        self:repeataction(ccb,item)
    end)))
end


function onceCheckedPanel.loadOneOfTen(self)
    self.loadindex = self.loadindex +1
    local len = table.getTableLength(self.tendata)
    if self.loadindex > len then
        self.loadindex = 0
        -- self.tenItems.buttonnode:setVisible(true)
        self.tenItems.closeButton:setVisible(true)
        return
    end
    local curData = self.tendata[tostring(self.loadindex)]["1"]
    self.tenCCB:runAction(CCSequence:createWithTwoActions(CCDelayTime:create( 0.2 ), CCCallFunc:create(function()
        local configdata = ui.IDconfig(curData.cid)
        local ccb,item = nil,nil
        ccb,item = CCBReaderLoad("shenqi_new/shenqi_yijiandazao_ten", nil, true, "shenqi_yijiandazao_ten")

        -- item.noButton
        
        ui.setLabelString(item.noLab, gameConfig.strings:string_common("mail",5),19)
        item.noButton:addHandleOfControlEvent(function()

            --一键打造查看详情
            if curData.isChecked > 0 then
                gameWindows:openWindow("artifactInfo",{artifactData = curData},nil)
            else
                gameWindows:openWindow("artifactSInfo",{title = gameConfig.strings:string_common("artifact",7),artifact = curData},nil)
            end

            -- gameWindows:openWindow("artifactInfo",{artifactData=curData})
        end, CCControlEventTouchUpInside)
        item.noButton:setSwallowsTouch(true)
        item.noButton:setTouchPriority(self.touchPriority)


        local totalLevel = 0
        for i = 1, 4 do
            if curData["jewel"..i] > 0 then
                local config = gamedata.config.trump_gem[tostring(curData["jewel"..i])]
                totalLevel = totalLevel + config.lv
            end
        end
        local config = gamedata.config.trump[tostring(curData.cid)]
        local shenqiSkeletonMeta = require"SkeletonShenqi"
        local skeleton = shenqiSkeletonMeta:init(config,totalLevel)
        skeleton:setPosition(0,-80)
        skeleton:setScale(0.6)
        skeleton:setAnimation("stand",true,0)
        item.general:addChild(skeleton.root or skeleton)
        if curData.level1 > 0 then
            ui.setLabelString(item.name,config.name.."+"..curData.level1,130)
        else
            ui.setLabelString(item.name,config.name,130)
        end
        self.tenItems["g"..self.loadindex]:addChild(ccb)

        item.fragmentNode:setVisible(false)

        if self.showType == "2" then
            item.skillNumNode:setVisible(true)

            ui.showArtifactSkillNum(item,curData)
            -- local count = 0
            -- local curQuality = 1
            -- for i=1,3 do
            --     local curSkill = curData["skill"..i]
            --     if curSkill > 0 then
            --         local skillConfig = gamedata.config.breakskill[tostring(curSkill)]
            --         if skillConfig.quality > curQuality then
            --             curQuality = skillConfig.quality
            --         end
            --         count = count + 1
            --     end
            -- end
            -- for i=1,6 do
            --     item["skillNumBg"..i]:setVisible(false)
            -- end
            -- if count > 0 then
            --     item.skillNumNode:setVisible(true)
            --     item.skillNum:setString(count);
            --     item["skillNumBg"..curQuality]:setVisible(true)
            -- else
            --     item.skillNumNode:setVisible(false)
            -- end
        else
            item.skillNumNode:setVisible(false)
        end

        self:loadOneOfTen()

    end)))
end

function onceCheckedPanel.reloadten(self)
    -- self.tenItems.buttonnode:setVisible(false)
    self.tenItems.closeButton:setVisible(false)
    self.tenItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("onceCheckedPanel")
    end, CCControlEventTouchUpInside)
    self.tenItems.closeButton:setSwallowsTouch(true)
    self.tenItems.closeButton:setTouchPriority(self.touchPriority+1)

    if self.showType == "1" then
        ui.setLabelString(self.tenItems.doLab,"继续打造",18)
        ui.setLabelString(self.tenItems.generalButtontext,"去鉴定",18)
    elseif self.showType == "2" then
        ui.setLabelString(self.tenItems.doLab,"继续鉴定",18)
        ui.setLabelString(self.tenItems.generalButtontext,"关闭",18)
    elseif self.showType == "3" then
        ui.setLabelString(self.tenItems.doLab,"继续重铸",18)
        ui.setLabelString(self.tenItems.generalButtontext,"关闭",18)
    end
    -- ui.setLabelString(self.tenItems.doLab,gameConfig.strings:string_common("recruit",4),18)
    self.tenItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        print("继续打造",self.showType)
        if self.showType == "1" then
            -- 继续打造
            if GameScene.layers["artifactCreate"].show then
                GameScene.layers["artifactCreate"].module:openOnecCreate()
            end
        elseif self.showType == "2" then
            if GameScene.layers["artifactCheck"].show then
                GameScene.layers["artifactCheck"].module:showOnceCheckedPanel()
            end
        elseif self.showType == "3" then
            gameWindows:openWindow("onceRecoin");
        end
        -- gameWindows:closeWindowDirect("onceCheckedPanel")
    end, CCControlEventTouchUpInside)
    self.tenItems.doButton:setSwallowsTouch(true)
    self.tenItems.doButton:setTouchPriority(self.touchPriority-1)

    
    -- ui.setLabelString(self.tenItems.generalButtontext,gameConfig.strings:string_common("recruit",5),18)
    self.tenItems.generalButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("onceCheckedPanel")
        if self.showType == "1" then
            -- 去鉴定打开鉴定面板
            GameScene:shiftLayer("artifactCheck","up")
        end
    end, CCControlEventTouchUpInside)
    self.tenItems.generalButton:setSwallowsTouch(true)
    self.tenItems.generalButton:setTouchPriority(self.touchPriority-1)


    -- self.tenItems.checknode:setPositionX(0)
    -- self.tenItems.donode:setPositionX(330)


    local ccb,item = CCBReaderLoad("UIEffect/guanxing/liuxing.ccbi",nil, true, "liuxing")
    self.tenCCB:addChild(ccb)
    self.tenCCB:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5), CCCallFunc:create(function()
        self.loadindex = 0
        self:loadOneOfTen()
    end)))
    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
   
    end)
    animationManager:runAnimationsForSequenceNamed("liuxing")

end


function onceCheckedPanel.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.loadindex = 0
    setTriggerGiftEnable(true)
    gameTouch:UnrigistFunc("begin","recruit")
    gameTouch:UnrigistFunc("end","recruit")
    if self.callback then
        self.callback()
    end
end

return onceCheckedPanel"  