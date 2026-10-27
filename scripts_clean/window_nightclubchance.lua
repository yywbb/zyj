
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local clubchance = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    titleCellSize = {x = 1040, y = 230}
}


function clubchance.open(self,touchPriority,data,callback)
    self.up_needprops = {}
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.callback = callback
    self.typeindex = data._typeindex or 0

    local tmpCinfog = gamedata.config.tiantingyz_sjtype[tostring(data._type)]
    -- printT(tmpCinfog,"tmpCinfog====:")

    self.rootNode, self.rootItems = CCBReaderLoad("nightclub/nightclub_event", nil, true, "clubchance")

    self.rootItems.wordlable:setString(tmpCinfog.desc)
    ui.setLabelString(self.rootItems.labelNedo,gameConfig.strings:string_common("nightclub",17),14)
    ui.setLabelString(self.rootItems.labelYes,tmpCinfog.button1,19)
    ui.setLabelString(self.rootItems.labelNo,tmpCinfog.button2,19)


    local tmpEnemyId = tmpCinfog["image"]
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(tmpEnemyId)].animationid)].name
    self.stepGneral1 = CCNode:create()
    local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    general:setAnimation("stand",true,0)
    general:setScale(1.6)
    self.stepGneral1:addChild(general)
    self.stepGneral1:setPosition(0,0)
    self.rootItems.heronode:addChild(self.stepGneral1)

    local tmpGold = nil
    local tmpCoin = nil
    local tmpNeedCid,tmpNeedNum = nil,nil
    if tmpCinfog.cost and tmpCinfog.cost ~= "" then
        tmpNeedCid,tmpNeedNum = ui.getIDandNUM(tmpCinfog.cost)
        if tmpNeedNum > 0 then
            if tmpNeedCid == 1001 then
                tmpGold = tmpNeedNum
                setSpriteFrameByName(self.rootItems.coin_sprite, "obj_s_gold")
                self.rootItems.labelGold:setString(tostring(tmpGold))
                self.rootItems.coin_sprite:setScale(1)
            elseif tmpNeedCid == 1000 then
                tmpCoin = tmpNeedNum
                setSpriteFrameByName(self.rootItems.coin_sprite, "obj_s_coin")
                self.rootItems.labelGold:setString(tostring(tmpCoin))
                self.rootItems.coin_sprite:setScale(1)
            else
                self.up_needprops.cid = tmpNeedCid
                self.up_needprops.num = tmpNeedNum
                local tmpItemConfig = ui.IDconfig(tmpNeedCid)
                setSpriteFrameByName(self.rootItems.coin_sprite, tmpItemConfig.icon)
                self.rootItems.coin_sprite:setScale(0.4)
                self.rootItems.labelGold:setString("")
                UIRequest({type = 12001, order = 14505, cids = {tmpNeedCid}})
            end
            self.rootItems.NodeGold:setVisible(true)
        else
            self.rootItems.NodeGold:setVisible(false)
        end
    else
        self.rootItems.NodeGold:setVisible(false)
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.m_iType = data._type
        self.m_iChoose = 0
        UIRequest({type = 4505,_index = data._index,_choose = 0})
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.okButton:addHandleOfControlEvent(function()
        if tmpNeedCid and tmpNeedCid ~= 1001 and tmpNeedCid ~= 1000 then
            if self.up_needprops.has < self.up_needprops.num then
                runGamePrompt({msg = gameConfig.strings:string_common("gamestar",3)})
                return
            end
        end
        self.m_iType = data._type
        self.m_iChoose = 1
        UIRequest({type = 4505,_index = data._index,
                               _choose = 1,
                               _gold = tmpGold,
                               _coin = tmpCoin,
                               _item = self.up_needprops.cid,
                               _nums = self.up_needprops.num})
    end, CCControlEventTouchUpInside)
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)

    self.root:addChild(self.rootNode)
    return self.root
end

function clubchance.reload(self,data)
    
    gameWindows:openWindow("clubevent",{_type = self.m_iType,_choose = self.m_iChoose,_typeindex = self.typeindex},self.callback)
    gameWindows.windows["clubevent"].module:reload(data)
    gameWindows:closeWindow("clubchance")
end

function clubchance.setPropNum(self,pdata)

    for k,v in pairs(pdata) do
        self.up_needprops.has = v
    end

    if self.up_needprops.has >= self.up_needprops.num then
        ui.setLabelString(self.rootItems.labelGold,""..self.up_needprops.num,14)
    else
        ui.setLabelString(self.rootItems.labelGold,""..self.up_needprops.num,11)
    end
end

function clubchance.close(self)  
    self.isscrolltouched = false
    -- if self.callback then
    --     self.callback()
    -- end
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return clubchance