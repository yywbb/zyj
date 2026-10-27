--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local gamestar = {

    resource = nil,
    m_iRunCellIndex = nil, -- 第几关
    m_iRunNowsIndex = nil, -- 第几个位置
    up_needprops = {},
}

local QRIL_STAGE_AD = {1,2,3,4,2,3,4,1,3,2,1,4}
local QRIL_COLOR_BASE = {"","绿色","蓝色","紫色","橙色","红色"}
-- local QRIL_STAGE_AD = {2,2,2,2,2,2,2,2,2,2,2,2}
local QRIL_CELL_TAG = 10086
local QRIL_GIRL_TAG = 10010
local QRIL_RUNTIMES = 1

function gamestar.init(self,parent,toppos,param)
    --
    local maxlv = table.getTableLength(gamedata.config.hoshimiya_break or {})
    for i = 1,maxlv do
        if not QRIL_STAGE_AD[i] then
            table.insert(QRIL_STAGE_AD,math.mod(i,4)+1)
        end
    end
    --
    self.layer = CCNode:create()
    local tmpCallBack = {
        changeNextStage = function()
            self:changeNextStages()
        end,
    }
    self.rootNode,self.rootItems = CCBReaderLoad("game/game", nil, true, "gamestar",tmpCallBack)
    self.rootNode:setPosition(0,0)
    self.layer:addChild(self.rootNode)
    parent:addChild(self.layer)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootAnimat = getAnimationManager(self.rootItems)

    local tmpPoint2 = ccp(self.rootItems.topnode:getPosition())
    self.rootItems.m_oGameNode:setPositionY(-tmpPoint2.y/2 - 50)

    ui.setLabelString(self.rootItems.m_oGameOver1,gameConfig.strings:string_common("gamestar",7),3)
    ----
    -- self.rootItems.closeButton:addHandleOfControlEvent(function()
    --     GameScene:shiftLayer(GameScene.priorLayer,"up")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.closeButton:setSwallowsTouch(true)
    -- self.rootItems.closeButton:setTouchPriority(-103)
    ----

    if param and param.page then
        self.selectpage = param.page
    end
    --
    UIRequest({type = 3720})

    guide.controller:addComplete(203,function()
        UIRequest({type = 2882,opt=1,sysID=203})
    end)
end

function gamestar.getSkillColorAndLevel(self,destLevel)
    local tmpReturnLevel = 0
    local growconfig = gamedata.config.protagonist_grow 
    local tmpNeedColor = growconfig[tostring(destLevel)].skillcolor
    for i=destLevel-1,1,-1 do
        if growconfig[tostring(i)] then
            local tmpBiColor = growconfig[tostring(i)].skillcolor
            if tmpNeedColor == tmpBiColor then
                tmpReturnLevel = tmpReturnLevel + 1
            else
                break
            end
        end
    end
    return tmpNeedColor,tmpReturnLevel
end

function gamestar.reloadData(self,data)
    self.m_iRoleLevel = data._selfLevel
    local tmpCanReset = self:updateNowIndex(data._cellIndex,data._nowsIndex)
    if tmpCanReset then
        self:next()
    end
end

function gamestar.next(self)
    self.m_iTotalAtk = 0
    self.m_iTotalDef = 0
    self.m_iTotalHp  = 0
    self.m_iApeendAtk = 0
    self.m_iApeendDef = 0
    self.m_iApeendHp = 0
    self.up_needprops = {}
    local breakconfig = gamedata.config.hoshimiya_break[tostring(self.m_iRunCellIndex)]
    local tmpMaxLevel = 0
    local tmpRoleLevel = 0

    local function dealUpInfo(destNeed,destBoom,destBi)
        self.rootItems.coin_sprite:setVisible(false)
        ui.setLabelString(self.rootItems.up_coin,"",14)
        self.rootItems.up_propnode1:setVisible(false)
        self.rootItems.up_propnode2:setVisible(false)
        if destBi then
            self.rootItems.m_oDownNode:setVisible(false)
            ui.setLabelString(self.rootItems["up_need_info"],"",26)
            ui.setLabelString(self.rootItems["upLab"],"",19)
        else
            self.rootItems.m_oDownNode:setVisible(true)
            if destBoom then
                local tmpColors,tmpLv = self:getSkillColorAndLevel(tmpRoleLevel)
                tmpColors = string.format(gameConfig.strings:string_common("gamestar",5),QRIL_COLOR_BASE[tmpColors]..(tmpLv >0 and (" +"..tmpLv) or ""))
                if self.m_iRoleLevel < tmpRoleLevel then
                    ui.setLabelString(self.rootItems["up_need_info"],tmpColors,11)
                else
                    ui.setLabelString(self.rootItems["up_need_info"],tmpColors,26)
                end
                ui.setLabelString(self.rootItems["upLab"],gameConfig.strings:string_common("gamestar",4),19)
            else
                ui.setLabelString(self.rootItems["up_need_info"],"",26)
                ui.setLabelString(self.rootItems["upLab"],gameConfig.strings:string_common("gamestar",2),19)
            end
            ----
            self.rootItems.m_oGameButon:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(1.2)
                for k,v in pairs(self.up_needprops) do
                    if v.has < v.num then
                        runGamePrompt({msg = gameConfig.strings:string_common("gamestar",3)})
                        return
                    end
                end
                if destBoom then
                    if self.m_iRoleLevel < tmpRoleLevel then
                        runGamePrompt({msg = string.format(gameConfig.strings:string_common("gamestar",6),tmpRoleLevel-self.m_iRoleLevel)})
                        return
                    end
                    UIRequest({type = 3722,_stage = self.m_iRunCellIndex})
                else
                    UIRequest({type = 3721,_stage = self.m_iRunCellIndex,_step = self.m_iRunNowsIndex})
                end
            end, CCControlEventTouchUpInside)
            self.rootItems.m_oGameButon:setSwallowsTouch(true)
            self.rootItems.m_oGameButon:setTouchPriority(-103)
        end
        ----
        local propnum = 0
        for k,v in pairs(destNeed) do
            if v.cid == 1000 then
                self.rootItems.coin_sprite:setVisible(true)
                if GameScene.roleinfo.coin < v.num then
                    ui.setLabelString(self.rootItems.up_coin,v.num,27)
                else
                    ui.setLabelString(self.rootItems.up_coin,v.num,14)
                end
            elseif  ui.IDconfig(v.cid).staffType == "props" then
                propnum = propnum+1
                if propnum == 1 or propnum == 2 then
                    self.rootItems["up_propnode"..propnum]:setVisible(true)
                    ui.setNewIcon(self.rootItems,{cid = v.cid},propnum-1)
                    ui.setLabelString(self.rootItems["up_propname"..propnum],ui.IDconfig(v.cid).name,1)
                    ui.setLabelString(self.rootItems["up_propnum"..propnum],"",1)
                    self.rootItems["i_button"..((propnum == 2) and "_1" or "")]:addHandleOfControlEvent(function()
                        gameWindows:openWindow("dropTips",{cid = v.cid},nil)
                    end, CCControlEventTouchUpInside)
                    self.rootItems["i_button"..((propnum == 2) and "_1" or "")]:setSwallowsTouch(true)
                    self.rootItems["i_button"..((propnum == 2) and "_1" or "")]:setTouchPriority(-103)
                end
                self.up_needprops[tostring(v.cid)] = {cid = v.cid, num = v.num, index = propnum, has = 0 }
                    UIRequest({type = 12001, order = 10771, cids = {v.cid}})
            end
        end
        -- ui.removeGray("CCControlButton",self.rootItems.m_oGameButon)
        -- for k,v in pairs(self.up_needprops) do
        --     if v.has < v.num then
        --         ui.addGray("CCControlButton",self.rootItems.m_oGameButon)
        --     end
        -- end
    end

    local function dealOnce(destData,_cellIndexs,_nowIndex)
        local tmpCanDoThat = 0
        if _cellIndexs < self.m_iRunCellIndex then
            tmpCanDoThat = 1
        else
            if _nowIndex <= self.m_iRunNowsIndex then
                tmpCanDoThat = 1
            elseif _nowIndex == self.m_iRunNowsIndex + 1 then
                tmpCanDoThat = -1
            end
        end
        if tmpCanDoThat == 1 then
            if destData[1] == "atk" then
                self.m_iTotalAtk = self.m_iTotalAtk + tonumber(destData[2])
            elseif destData[1] == "def" then
                self.m_iTotalDef = self.m_iTotalDef + tonumber(destData[2])
            elseif destData[1] == "hp" then
                self.m_iTotalHp = self.m_iTotalHp + tonumber(destData[2])
            end
        elseif tmpCanDoThat == -1 then
            if destData[1] == "atk" then
                self.m_iApeendAtk = tonumber(destData[2])
            elseif destData[1] == "def" then
                self.m_iApeendDef = tonumber(destData[2])
            elseif destData[1] == "hp" then
                self.m_iApeendHp = tonumber(destData[2])
            end
        end
    end
    if self.m_iRunCellIndex - 1 > 0 then
        for i=1,self.m_iRunCellIndex - 1 do
            local tmpAddIConfig = gamedata.config.hoshimiya_jihuo[""..i]
            for j=1,9 do
                dealOnce(ui.getNeedWithFuhao(tmpAddIConfig[tostring(j)]["activation_add"],":"),i,j)
            end
            dealOnce(ui.getNeedWithFuhao(gamedata.config.hoshimiya_break[""..i]["break_add1"],":"),i,10)
            dealOnce(ui.getNeedWithFuhao(gamedata.config.hoshimiya_break[""..i]["break_add2"],":"),i,10)
            dealOnce(ui.getNeedWithFuhao(gamedata.config.hoshimiya_break[""..i]["break_add3"],":"),i,10)
        end
    end
    if self.m_iRunCellIndex > #QRIL_STAGE_AD then
        dealUpInfo({},nil,true)
    else
        tmpMaxLevel = tonumber(breakconfig.break_cond1)
        tmpRoleLevel = tonumber(breakconfig.break_cond2)
        local tmpNowConfig = gamedata.config.hoshimiya_jihuo[""..self.m_iRunCellIndex]
        for i=1,tmpMaxLevel do
            local tmpDate = ui.getNeedWithFuhao(tmpNowConfig[""..i]["activation_add"],":")
            if i <= self.m_iRunNowsIndex + 1 then
                dealOnce(tmpDate,self.m_iRunCellIndex,i)
            end
            self.m_oCellItem["m_oCellLab"..i]:setString(gameConfig.strings:string_common("attr_type",tmpDate[1]).."+"..tmpDate[2])
        end
        if self.m_iRunNowsIndex >= tmpMaxLevel then
            dealOnce(ui.getNeedWithFuhao(gamedata.config.hoshimiya_break[""..self.m_iRunCellIndex]["break_add1"],":"),self.m_iRunCellIndex,10)
            dealOnce(ui.getNeedWithFuhao(gamedata.config.hoshimiya_break[""..self.m_iRunCellIndex]["break_add2"],":"),self.m_iRunCellIndex,10)
            dealOnce(ui.getNeedWithFuhao(gamedata.config.hoshimiya_break[""..self.m_iRunCellIndex]["break_add3"],":"),self.m_iRunCellIndex,10)
            dealUpInfo(ui.getIDandNUMs(breakconfig.break_cost),true)
        else
            local upconfig = gamedata.config.hoshimiya_jihuo[tostring(self.m_iRunCellIndex)][tostring(self.m_iRunNowsIndex+1)]
            dealUpInfo(ui.getIDandNUMs(upconfig.activation_cost),false)
        end
    end
    local tmpAddAtkStr = gameConfig.strings:string_common("attr_type","atk")..":"..self.m_iTotalAtk
    local tmpAddDefStr = gameConfig.strings:string_common("attr_type","def")..":"..self.m_iTotalDef
    local tmpAddHpStr = gameConfig.strings:string_common("attr_type","hp")..":"..self.m_iTotalHp

    self.rootItems.m_opAtkName:setString(tmpAddAtkStr)
    self.rootItems.m_opDefName:setString(tmpAddDefStr)
    self.rootItems.m_opHpName:setString(tmpAddHpStr)

    if self.m_iApeendAtk > 0 then
        local tmpAtkpoint = ccp(self.rootItems.m_opAtkName:getPosition())
        local tmpAtkSize = self.rootItems.m_opAtkName:getContentSize()
        self.rootItems.m_oAtkttf:setString("("..gameConfig.strings:string_common("gamestar",8).."+"..self.m_iApeendAtk..")")
        self.rootItems.m_oAtkttf:setPosition(tmpAtkpoint.x+tmpAtkSize.width,tmpAtkpoint.y)
    else
        self.rootItems.m_oAtkttf:setString("")
    end
    if self.m_iApeendDef > 0 then
        local tmpDefpoint = ccp(self.rootItems.m_opDefName:getPosition())
        local tmpDefSize = self.rootItems.m_opDefName:getContentSize()
        self.rootItems.m_oDefttf:setString("("..gameConfig.strings:string_common("gamestar",8).."+"..self.m_iApeendDef..")")
        self.rootItems.m_oDefttf:setPosition(tmpDefpoint.x+tmpDefSize.width,tmpDefpoint.y)
    else
        self.rootItems.m_oDefttf:setString("")
    end
    if self.m_iApeendHp > 0 then
        local tmpHppoint = ccp(self.rootItems.m_opHpName:getPosition())
        local tmpHpSize = self.rootItems.m_opHpName:getContentSize()
        self.rootItems.m_oHpttf:setString("("..gameConfig.strings:string_common("gamestar",8).."+"..self.m_iApeendHp..")")
        self.rootItems.m_oHpttf:setPosition(tmpHppoint.x+tmpHpSize.width,tmpHppoint.y)
    else
        self.rootItems.m_oHpttf:setString("")
    end
end

function gamestar.updateNowIndex(self,destCellIndex,destNowIndex)
    local tmpCanReset = false
    if destCellIndex ~= self.m_iRunCellIndex then
        tmpCanReset = true
        self.m_iRunCellIndex = destCellIndex
        if self.rootItems.m_oGameBase:getChildByTag(QRIL_CELL_TAG) ~= nil then
            self.rootItems.m_oGameBase:removeAllChildrenWithCleanup(true)
            self.m_oDevilNode = nil
        end
        if self.m_iRunCellIndex > #QRIL_STAGE_AD then
            self.rootItems.m_oStageNum:setString("")
        else
            self.rootItems.m_oStageNum:setString(string.format(gameConfig.strings:string_common("gamestar",1),gameConfig.strings:string_common("bigNum",destCellIndex)))
            self.m_oCellNode, self.m_oCellItem = CCBReaderLoad("game/cell_gamemap"..QRIL_STAGE_AD[self.m_iRunCellIndex],nil, true, "GameCell")
            self.m_oCellAnimation = getAnimationManager(self.m_oCellItem)

            self.rootItems.m_oGameBase:addChild(self.m_oCellNode,0,QRIL_CELL_TAG)
            if self.m_oDevilNode == nil then
                self.m_oDevilNode = CCNode:create()
                local tmpDevilNode , tmpDevilItem = CCBReaderLoad("game/cell_eatman",nil, true, "eatman")
                self.m_oDevilNode:addChild(tmpDevilNode)
            end
            self.m_oCellItem.m_oEatManNode:addChild(self.m_oDevilNode,100)
        end
    end
    if destNowIndex ~= self.m_iRunNowsIndex then
        tmpCanReset = true
        if self.m_iRunCellIndex > #QRIL_STAGE_AD then
            gamestar:changeAnimation("loop")
        else
            gamestar:changeAnimation("free")
            if self.m_iRunNowsIndex ~= nil and destNowIndex - self.m_iRunNowsIndex == 1 then
                self.m_oCellAnimation:runAnimationsForSequenceNamed(self.m_iRunNowsIndex.."-"..destNowIndex)
            else
                self.m_oCellAnimation:runAnimationsForSequenceNamed(""..destNowIndex)
            end
        end
        self.m_iRunNowsIndex = destNowIndex
    end
    return tmpCanReset
end

function gamestar.changeAnimation(self,destName)
    if not self.m_bChangeLate then
        self.rootAnimat:runAnimationsForSequenceNamed(destName)
    else
        self.m_bChangeLate = false
    end
end

function gamestar.setUpPropNum(self,pdata)

    for k,v in pairs(pdata) do
        if self.up_needprops[tostring(k)] then
            self.up_needprops[tostring(k)].has = v
        end
    end
    local isEnough = true
    for k,v in pairs(self.up_needprops) do
        if v.has >= v.num then
            ui.setLabelString(self.rootItems["up_propnum"..v.index],v.has.."/"..v.num,3)
        else
            ui.setLabelString(self.rootItems["up_propnum"..v.index],v.has.."/"..v.num,11)
            if v.cid == 20167 or v.cid == 20286 then
                isEnough = false
            end
        end
    end
    print(" ----------- /////// ------")
    printT(self.up_needprops)

    ui.setMobileShopShow(self.rootItems.mobieshop,-103,7,not isEnough)

    -- ui.removeGray("CCControlButton",self.rootItems.m_oGameButon)
    -- for k,v in pairs(self.up_needprops) do
    --     if v.has < v.num then
    --         ui.addGray("CCControlButton",self.rootItems.m_oGameButon)
    --     end
    -- end
end

function gamestar.changeNextStages(self)
    self:reloadData({_cellIndex = self.m_iRunCellIndex+1,_nowsIndex = 0,_selfLevel = self.m_iRoleLevel})
end

function gamestar.boom(self)
    self.m_bChangeLate = true
    self.rootAnimat:setAnimationCompletedCallback(function()
        self.m_bChangeLate = false
        if self.m_iRunCellIndex > #QRIL_STAGE_AD then
            gamestar:changeAnimation("loop")
        else
            gamestar:changeAnimation("free")
        end
    end)
    self.rootAnimat:runAnimationsForSequenceNamed("play")
    self.m_oCellAnimation:runAnimationsForSequenceNamed("play")
    self.layer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(4.5), CCCallFunc:create(function()
        UIRequest({type = 3720})
    end)))
end

function gamestar.clear(self)
    self.up_needprops = {}
    self.layer:removeAllChildrenWithCleanup(true)
    self.layer:removeFromParentAndCleanup(true)
    self.layer = nil
    self.rootNode = nil
    self.rootItems = nil

    self.m_iRunCellIndex = nil -- 第几关
    self.m_iRunNowsIndex = nil -- 第几个位置
    self.m_oDevilNode = nil
    self.m_oCellNode = nil
    self.m_oCellItem = nil
end


return gamestar
   �B  