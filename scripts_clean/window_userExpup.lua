--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/10/10
-- Time: 15:42
-- To change this template use File | Settings | File Templates.
--

local userexpup = {
    rootNode = nil,
    rootItems = nil,
}

function userexpup.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/expup", nil, true, "expup")
    self.touchPriority = touchPriority

    --
    local expSpr = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("obj_processbar2.png"))
    self.rootItems.up_expSprite = CCProgressTimer:create(expSpr);
    self.rootItems.up_expSprite:setAnchorPoint(ccp(0,0.5))
    self.rootItems.up_expSprite:setType(kCCProgressTimerTypeBar)
    self.rootItems.up_expSprite:setMidpoint(ccp(0,0.5))
    self.rootItems.up_expSprite:setBarChangeRate(ccp(1,0))
    self.rootItems.up_expSprite:setPosition(ccp(0,0))
    self.rootItems.up_expSprite:setScaleX(1)
    self.rootItems.up_expSprite:setScaleY(1)
    self.rootItems.up_expSprite:setPercentage(0)
    self.rootItems.posnode:addChild(self.rootItems.up_expSprite)
    --

    self:reload(data,callback)
    return self.rootNode
end

function userexpup.reload(self,data,callback)
    self.callback = callback

    ui.setLabelString(self.rootItems.closeLab,nil,19)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("userexpup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    if not (data and data.roleinfo) then
        return
    end

    --
    if not gameConfig:checkBuildOpen(154) then
        self.rootItems.vipnode:setVisible(false)
    else
        self.rootItems.vipnode:setVisible(true)
    end
    --
    setSpriteFrameByName(self.rootItems["VIP"],"b_n_vip_"..data.roleinfo.vip)
    ui.setLabelString(self.rootItems.username,data.roleinfo.name,46)
    setSpriteFrameByName(self.rootItems.usericon, gamedata.config.general[tostring(data.roleinfo.profile)].icon)
    ui.setSpriteTextureRect(self.rootItems.usericon,0,0,150,150)
    --
    ui.setLabelString(self.rootItems.userexp,"",13)
    ui.setLabelString(self.rootItems.userlevel,"等级:"..data.roleinfo.level,46)
    --

    local processNum = 100*((data.roleinfo.exp >= data.roleinfo.nextexp) and 1 or (data.roleinfo.exp / data.roleinfo.nextexp))
    local expTo = CCProgressFromTo:create(0,0,processNum)
    self.rootItems.up_expSprite:runAction(expTo)
    --

    local lv = data.roleinfo.level or 1
    local exp = data.roleinfo.exp or 0

    if data.expup and data.expup > 0 and lv < table.getTableLength(gamedata.config.role_exp) then
        exp = exp + data.expup
        while exp >= gamedata.config.role_exp[tostring(lv)].nextexp do
            if lv < table.getTableLength(gamedata.config.role_exp) then
                exp = exp-gamedata.config.role_exp[tostring(lv)].nextexp
                lv = lv+1
            else
                break
            end
        end
        --
        local processNumEnd = 100*((exp >= gamedata.config.role_exp[tostring(lv)].nextexp) and 1 or (exp / gamedata.config.role_exp[tostring(lv)].nextexp))
        if lv > data.roleinfo.level then
            --
            local lvup = {
                rolegetexp = data.expup,
                oldexp = data.roleinfo.exp,
                newexp =  exp,
                oldlevel = data.roleinfo.level,
                newlevel = lv,
            }
            --
            self.callback = function()
                if guide.controller then
                    guide.controller:LevelUp(lvup,callback)
                else
                    if callback then
                        callback()
                    end
                end
            end
            --
            expTo = CCProgressFromTo:create(1,processNum,100)
            self.rootItems.up_expSprite:runAction(expTo)
            --
            self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
                ui.setLabelString(self.rootItems.userlevel,"等级:"..lv,46)
                local expTo2 = CCProgressFromTo:create(1,0,processNumEnd)
                self.rootItems.up_expSprite:runAction(expTo2)
                --
                self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
                    ui.setLabelString(self.rootItems.userexp,exp.."/"..gamedata.config.role_exp[tostring(lv)].nextexp,13)
                end)))
            end)))
        else
            expTo = CCProgressFromTo:create(1,processNum,processNumEnd)
            self.rootItems.up_expSprite:runAction(expTo)
            --
            self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
                ui.setLabelString(self.rootItems.userexp,exp.."/"..gamedata.config.role_exp[tostring(lv)].nextexp,13)
            end)))
        end

    end
end

function userexpup.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return userexpup

