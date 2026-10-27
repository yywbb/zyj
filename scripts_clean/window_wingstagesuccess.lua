--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local wingstagesuccess = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
}

function wingstagesuccess.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    if data.index == "stagesuccess" then
        print("i...am...wingstagesuccess")
        self.wingdata = data.wing
        self.generaldata = data.protagonist
        self.rootNode, self.rootItems = CCBReaderLoad("wing/wingup.ccbi", nil, true, "wingup")
        self:seccessreload(callback)
    else  
        self.rootNode, self.rootItems = CCBReaderLoad("wing/wing_tishi.ccbi", nil, true, "wing_tishi")
        self:tishireload(callback)
    end
    
    
    
    self.root:addChild(self.rootNode)
    return self.root
end

-- 提示面板
function wingstagesuccess.tishireload(self,callback)
    
    -- self.rootItems.tishiText:setString("您未使用［太虚神印］，进阶失败会使翅膀星级-1，是否继续？")
    self.rootItems.tishiText:setString(gameConfig.strings:string_common("fixedString","wing",25))

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("wingstagesuccess")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)


    ui.setLabelString(self.rootItems.noLab,gameConfig.strings:string_common("buttontext","fanhui"),19)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("wingstagesuccess")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority-1)


    ui.setLabelString(self.rootItems.yesLab,gameConfig.strings:string_common("buttontext","queding"),19)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        self.callback = callback
        gameWindows:closeWindowDirect("wingstagesuccess")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority-1)
end

-- 属性设置
function wingstagesuccess.seccessreload(self,callback)

    self.callback = callback

    -- self.rootItems.descText:setString("点击屏幕继续")
    self.rootItems.descText:setString(gameConfig.strings:string_common("fixedString","wing",26))

    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("wingstagesuccess")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)


    local nowstagenum = self.wingdata.stagenum
    local nowstarnum = self.wingdata.starnum
    if nowstagenum == 0 then
        nowstagenum = 1
        nowstarnum = 0
    end
    -- 当前属性
    local uplvconfig = gamedata.config.wing_uplv[tostring(nowstagenum)]
    local nowlvconfig = uplvconfig[tostring(nowstarnum)]
    if nowstarnum == 0 then
        nowlvconfig = gamedata.config.wing_stage[tostring(nowstagenum)]
    end

    -- 下一级属性
    local nextstagenum = nowstagenum
    local nextstarnum = nowstarnum + 1

    if (table.getTableLength(uplvconfig)) == self.wingdata.starnum then
        nextstagenum = nextstagenum + 1
        nextstarnum = 0
    end
    local nextuplvconfig = gamedata.config.wing_uplv[tostring(nextstagenum)]
    local nextlvconfig = nextuplvconfig[tostring(nextstarnum)]
    if nextstarnum == 0 then
        nextlvconfig = gamedata.config.wing_stage[tostring(nextstagenum)]
    end

    -- printT(nowlvconfig,"nowlvconfig==")
    -- printT(nextlvconfig,"nextlvconfig==")
    -- 前4属性设置
    for i=1,4 do
        print("effect===",nowlvconfig["effect"..i],nextlvconfig["effect"..i])
        local attr1,num1 = ui.getATTRandNUM2(nowlvconfig["effect"..i])
        local attr2,num2 = ui.getATTRandNUM2(nextlvconfig["effect"..i])
        local addnum = num2-num1

        ui.setLabelString(self.rootItems["attrText"..i],gameConfig.strings.attr_type[attr1] or "",48)
        ui.setLabelString(self.rootItems["attrLab"..i],num1,14)

        ui.setLabelString(self.rootItems["next_attrLab"..i],num2,14)

        if addnum == 0 then
            self.rootItems["addnode"..i]:setVisible(false)
        else
            self.rootItems["addnode"..i]:setVisible(true)
            ui.setLabelString(self.rootItems["addnum"..i],addnum,23)
        end
    end

    -- 资质设置
    local num3 = nowlvconfig["effect"..5]
    local num4 = nextlvconfig["effect"..5]
    local addnum2 = num4-num3
    -- ui.setLabelString(self.rootItems["attrText"..5],"资质",48)
    ui.setLabelString(self.rootItems["attrText"..5],gameConfig.strings:string_common("fixedString","wing",9),48)
    ui.setLabelString(self.rootItems["attrLab"..5],num3,14)
    ui.setLabelString(self.rootItems["next_attrLab"..5],num4,14)

    if addnum2 == 0 then
        self.rootItems["addnode"..5]:setVisible(false)
    else
        self.rootItems["addnode"..5]:setVisible(true)
        ui.setLabelString(self.rootItems["addnum"..5],addnum2,23)
    end

    --
    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.generaldata.general.cid)].animationid)].name
    local wing = {level = nextstagenum, color = 0}
    local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1.6)
    Gneral1:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(Gneral1.root or Gneral1)


end


function wingstagesuccess.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.stepGneral = nil

    if self.callback then
        self.callback()
    end
end

return wingstagesuccess