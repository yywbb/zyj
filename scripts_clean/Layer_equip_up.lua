--装备详情  包换装备强化 装备洗练
--zhangzhixin

local equipUp= {
	rootNode = nil,
	rootItems = nil,

    titleCellSize = {x = 180, y = 180},

    pageconfig = {"up","xilian","cast","shengxing","jinjie"},
    -- pagename = {"强 化","洗 炼","升 星","进 阶"},
    pagename = {gameConfig.strings:string_common("equipUp",1),
                gameConfig.strings:string_common("equipUp",2),
                gameConfig.strings:string_common("equipUp",14),
                gameConfig.strings:string_common("equipUp",3),
                gameConfig.strings:string_common("equipUp",15),
            },

    pagebuild = {1,53,384,199,150},
         
    selectpage = "up",
    touchPriority =  -103,
    xlselect = 1,
    bottomHight = 160,--底边条高度
    xiliansStoneNum = 0,
    rolecoin = 0,

    equips = {},
    slotequips = {},    -- 阵容武将、武将对应装备信息
    generalsData = {},
    generalListTableView = nil,

    equippos = {},  -- 装备位置
    equiptype = {
        weapon = 1,
        head = 2,
        armor = 3,
        accessory = 4,
        [1] = "weapon",
        [2] = "head",
        [3] = "armor",
        [4] = "accessory",
    },              -- 装备类型与对应id

    frontid = 1,    -- 当前显示的装备类型id
    pi = math.pi,
    R = 300,
    rotaAngle = 0,
    angle = 2*math.pi/4,
    Scale = 0.7,
    ScaleY = math.sin(math.pi/6.5),

    sid = 1,
    jj_spendpropsdata = nil, --消耗物品数据
    xilianLimit = 2, -- 洗练限制品质
    shengxingLimit = 3, -- 升星限制品质

    data =nil,
    dotimes = 10,
   
}


function equipUp.updateBtnStage(self,backType,nexType )
    if backType == "up" then
        if nexType == "xilian"  then
            if not GameScene:checkopenlevelbyId(53) then
                setSpriteFrameByName(self.rootItems["buttonsprite1"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite2"], gameConfig.images.pageButtonOFF)
                return false
            end
        elseif nexType == "shengxing" then
            if not GameScene:checkopenlevelbyId(199) then
                setSpriteFrameByName(self.rootItems["buttonsprite1"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite4"], gameConfig.images.pageButtonOFF)
                return false
            end
        elseif nexType == "jinjie" then
            if not GameScene:checkopenlevelbyId(150) then
                setSpriteFrameByName(self.rootItems["buttonsprite1"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite5"], gameConfig.images.pageButtonOFF)
                return false
            end
        elseif nexType == "cast" then
            if not GameScene:checkopenlevelbyId(384) then
                setSpriteFrameByName(self.rootItems["buttonsprite1"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite3"], gameConfig.images.pageButtonOFF)
                return false
            end
        end
    elseif backType == "xilian"  then
       if nexType == "shengxing" then
            if not GameScene:checkopenlevelbyId(199) then
                setSpriteFrameByName(self.rootItems["buttonsprite2"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite4"], gameConfig.images.pageButtonOFF)
                return false
            end
        elseif nexType == "jinjie" then
            if not GameScene:checkopenlevelbyId(150) then
                setSpriteFrameByName(self.rootItems["buttonsprite2"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite5"], gameConfig.images.pageButtonOFF)
                return false
            end
        elseif nexType == "cast" then
            if not GameScene:checkopenlevelbyId(384) then
                setSpriteFrameByName(self.rootItems["buttonsprite2"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite3"], gameConfig.images.pageButtonOFF)
                return false
            end
        end
    elseif typelayer == "jinjie" then
        if nexType == "shengxing" then
            if not GameScene:checkopenlevelbyId(199) then
                setSpriteFrameByName(self.rootItems["buttonsprite5"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite4"], gameConfig.images.pageButtonOFF)
                return false
            end
        end
    elseif typelayer == "cast" then
        if nexType == "shengxing" then
            if not GameScene:checkopenlevelbyId(199) then
                setSpriteFrameByName(self.rootItems["buttonsprite2"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite4"], gameConfig.images.pageButtonOFF)
                return false
            end
        elseif nexType == "jinjie" then
            if not GameScene:checkopenlevelbyId(150) then
                setSpriteFrameByName(self.rootItems["buttonsprite2"], gameConfig.images.pageButtonON)
                setSpriteFrameByName(self.rootItems["buttonsprite5"], gameConfig.images.pageButtonOFF)
                return false
            end
        end
    end
    return true
end
function equipUp.shiftPage(self,typelayer)

    print("typelayer ===   ",typelayer)
    local typelayer = typelayer or self.selectpage
    local curState = self:updateBtnStage(self.selectpage,typelayer);

    self.uplevel1 = 1
    self.rootItems.equipShowNode:setPositionX(0)
        -- 强化
    if typelayer == "up" then
        self.selectpage = typelayer
        self:refreshShiftPageNode(0, 99999, 99999, 99999, 99999)
        self:setPage_up()
    -- 洗练
    elseif typelayer == "xilian" then
        if curState == false then
            return;
        end
        self.selectpage = typelayer
        self:refreshShiftPageNode(99999, 0, 99999, 99999, 99999)
        self:setPage_strengthen()

        if (guide.controller == nil or next(guide.controller) ==nil or not guide.controller.isOnGuide) then
            guide.controller:addComplete(53,function()
                UIRequest({type = 2882,opt=1,sysID=53})
            end)
        end

        
    -- 升星
    elseif typelayer == "shengxing" then

        if curState == false then
            return;
        end
        self.selectpage = typelayer
        self:refreshShiftPageNode(99999, 99999, 0, 99999, 99999)
        self:setPage_shengxing()

        if (guide.controller == nil or next(guide.controller) ==nil or not guide.controller.isOnGuide) then
            guide.controller:addComplete(199,function()
                UIRequest({type = 2882,opt=1,sysID=199})
            end)
        end

        
    -- 进阶
    elseif typelayer == "jinjie" then
        if curState == false then
            return;
        end
        
        self.selectpage = typelayer
        self:refreshShiftPageNode(99999, 99999, 99999,0, 99999)
        self:setPage_jinjie()

        if (guide.controller == nil or next(guide.controller) ==nil or not guide.controller.isOnGuide) then
            guide.controller:addComplete(150,function()
                UIRequest({type = 2882,opt=1,sysID=150})
            end)
        end

        
    elseif typelayer == "cast" then
        if curState == false then
            return;
        end
        self.selectpage = typelayer
        self:refreshShiftPageNode(99999, 99999, 99999,99999, 0)
        self:setPage_Cast()
        
        if (guide.controller == nil or next(guide.controller) ==nil or not guide.controller.isOnGuide) then
            guide.controller:addComplete(384,function()
                UIRequest({type = 2882,opt=1,sysID=384})
            end)
        end
        
        
    else
        print("equipUp shiftPage Can not in this else.")
    end

end

function equipUp.refreshShiftPageNode(self, up, strengthen, shengxing, jinjie,cust)
    self.rootItems.upNode:setPositionX(up)
    self.rootItems.strengthenNode:setPositionX(strengthen)
    self.rootItems.shengxingNode:setPositionX(shengxing)
    self.rootItems.castNode:setPositionX(cust)
    for i=1, 4 do
        self.equippos[i].item.starShowNode:setPositionX(shengxing)  
    end

    self.rootItems.jinjieNode:setPositionX(jinjie)
end

function equipUp.initNodePositionY(self, nodeName)
    self.rootItems[nodeName]:setPositionY(self.rootItems[nodeName]:getPositionY() + self.bottomHight)
end

function equipUp.initNode(self, parent, toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("equip_new/equip_up_n", nil, true, "up")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(toppos)

    self:initFixedString()

    self:initNodePositionY("upNode")
    self:initNodePositionY("strengthenNode")
    self:initNodePositionY("shengxingNode")
    self:initNodePositionY("castNode")
    self:initNodePositionY("jinjieNode")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer(GameScene.priorLayer,"up",{selectpage = "equip", sid = self.arrange_sid or 1})
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(-104)  

end

function equipUp.init(self,parent,toppos,param)
    self:initNode(parent, toppos)
	
    print("equipUp.init param ==")
    printT(param)

    if param then
        self.arrange_sid = param.arrange_sid or 1
    else
        self.arrange_sid = 1
    end

    self.rootItems.slotNode:setPositionY(((toppos-1620)/(1920-1620) * 120) - 170) 
    self.rootItems.rotanode:setScale(0.3*(toppos-1620)/(1920-1620)+0.8)
    self.rootItems.effectNode:setScale(0.3*(toppos-1620)/(1920-1620)+0.7)
    self.rootItems.arrNode:setScale(0.3*(toppos-1620)/(1920-1620)+0.7) 

    if (toppos-1620)/(1920-1620) >= 0.82 then
        self.rootItems.effectNode:setPositionY(-200 + 40) 
    elseif (toppos-1620)/(1920-1620) >= 0.72 and (toppos-1620)/(1920-1620) < 0.82 then
        self.rootItems.effectNode:setPositionY(-270 + 40) 
    else
        self.rootItems.effectNode:setPositionY(-330 + 40) 
    end

    --
    if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
        self.generalsData = table.copy(GameScene.layers["generals"].module.generalsdata)
    end
    --

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchX = x     -- 左右滑动
            self.beginX = x
            return true
        end
    end

    local function ccTouchMoved(x, y)
        local disX = (x - self.touchX)/gameConfig.scaleNum
        local abs_disX = math.abs(disX)

        if abs_disX > 20 then
            self.rootItems.arrNode:setVisible(false)
            if self.timer then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
                self.timer = nil
            end
            self.isContentScroll = true
            self:moveslot(x - self.touchX)
            self.touchX = x
        end
    end

    local function ccTouchEnded(x, y)
        if self.isContentScroll then
            self:moveSlotAnimation(x - self.touchX,x>self.beginX)
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -102, false)
    self.rootItems.touchLayer:setTouchPriority(-102)
    self.rootItems.touchLayer:setTouchEnabled(true)

    self.initData = param
    self:createEquipIcons()

    if gamedata.config.global_kv["baptize_leve_limit"] and tonumber(gamedata.config.global_kv["baptize_leve_limit"].value) <= GameScene.roleinfo.level then
        self.dotimes = 50
    end 

    local etype = "weapon" 

    if param then
        etype = param.data and param.data.type or "weapon"
    end
    self.frontid = self.equiptype[etype]
    self.rotaAngle = self.rotaAngle - (self.angle/2)*(self.frontid-1)
    if self.frontid == 4 then
        self.rotaAngle = self.rotaAngle - 1
    end
    self:moveSlotAnimation(-400,false)
    self:reload(param)
    self:clearShow();
    if not GameScene:checkUpdate(10025,"slotequips") then

    end
end

function equipUp.reload(self,data )
    if data and next(data)then
    else
        return
    end
    self.data = data.data or {}
    self.opt = data.opt or 0
    self.sid = data.sid or self.sid

    if not self.slotequips[tostring(self.sid)] then
        for k,v in pairs(self.slotequips) do
            if v.sid == self.sid then
                self.sid = tonumber(k)
                break
            end
        end
    end

    self.selectpage = data.page or self.selectpage
    self.rolecoin = data.coin or GameScene.roleinfo.coin
    if self.opt == 2 then
        self.data.cid = data.cid
        self.data.iid = 0
        self.data.level1 = 1
        self.data.level2 = 0
        self.data.suit = {}
        self.data.suitstage = {}
    end

    if next(self.data) then 
        self.equips[self.data.iid] = self.data
    end

    if not self.generalListTableView then
        self:createGeneralList()
    else
        self.generalListTableView:reloadData()
    end

    self:shiftPage(self.selectpage)
end

function equipUp.setEquipsData(self,slotequips)

    self.slotequips = {}
    for i=1,7 do
        if slotequips[tostring(i)] then
            self.slotequips[tostring(table.getTableLength(self.slotequips) + 1)] = slotequips[tostring(i)]
        end
    end
    printT(self.slotequips,"self.slotequips")

end

function equipUp.createEquipIcons(self)
    self.rootItems.slotNode:setScaleY(self.ScaleY)
    for i=1, 4 do
        if not self.equippos[i] then 
            self.equippos[i] = {}
            self.equippos[i].angle = (i-1)*self.angle
            self.equippos[i].ccb, self.equippos[i].item = CCBReaderLoad("equip_new/equipicon_n", nil, true, "equipicon_n")
            self.rootItems["slot"..i]:addChild(self.equippos[i].ccb)
        end

        self:setOneSlotsEquip(i)
    end
end

function equipUp.setOneSlotsEquip(self,i)
    self.equippos[i].x = self.R*math.sin(self.equippos[i].angle)
    self.equippos[i].y = -self.R*math.cos(self.equippos[i].angle)
    self.equippos[i].sx = 1-(1-self.Scale)*(self.equippos[i].y+self.R)/(2*self.R)
    self.equippos[i].sy = self.equippos[i].sx/self.ScaleY

    self.rootItems["slot"..i]:setPosition(self.equippos[i].x, self.equippos[i].y)
    self.rootItems["slot"..i]:setScaleX(self.equippos[i].sx)
    self.rootItems["slot"..i]:setScaleY(self.equippos[i].sy)

    local Zorder = self:findZorder(self.equippos[i].angle)

    self.rootItems["slot"..i]:setZOrder(Zorder)
end

function equipUp.findZorder(self,angle)
    local pi = self.pi
    if math.abs(angle) > 2*pi then
        angle = math.mod(angle,2*pi)
    end

    if angle<0 then
        angle = angle + 2*self.pi
    end
    if angle> pi/4 and angle<= 3*pi/4 then
        return 4
    elseif angle> 3*pi/4 and angle<= 5*pi/4 then
        return 2
    elseif angle> 5*pi/4 and angle<= 7*pi/4 then
        return 2
    elseif angle> 7*pi/4 and angle<= 9*pi/4 then
        return 3
    elseif angle> 9*pi/4 and angle<= 11*pi/4 then
        return 3
    elseif angle> 11*pi/4 and angle<= 13*pi/4 then
        return 4
    else
        return 5
    end
end


function equipUp.moveslot(self,dis)
    self.rotaAngle = self.rotaAngle + (dis or 0)*(self.pi/1800)
    self:setSlot()
end

function equipUp.setSlot(self)
    self.rootItems.rotanode:setRotation(-math.deg(self.rotaAngle))
    for i=1,4 do
        self.equippos[i].angle = (i-1)*self.angle + self.rotaAngle

        local y = -self.R*math.cos(self.equippos[i].angle)
        self.equippos[i].sx = 1-(1-self.Scale)*(y+self.R)/(2*self.R)
        self.equippos[i].sy = self.equippos[i].sx/self.ScaleY

        self.rootItems["slot"..i]:setRotation(math.deg(self.rotaAngle))
        self.rootItems["slot"..i]:setScaleX(self.equippos[i].sx)
        self.rootItems["slot"..i]:setScaleY(self.equippos[i].sy)
        self.rootItems["slot"..i]:setZOrder(self:findZorder(self.equippos[i].angle))
    end
end

function equipUp.moveSlotAnimation(self,dis,direct)
    if math.abs(self.rotaAngle) > 2*self.pi then
        self.rotaAngle = math.mod(self.rotaAngle,2*self.pi)
    end

    if self.rotaAngle<0 then
        self.rotaAngle = self.rotaAngle + 2*self.pi
    end

    local stepdis = (direct and 1 or -1)*100
    local targetAngle =  self.rotaAngle

    for i=1,4 do
        if self.rotaAngle > (i-1)*self.angle and self.rotaAngle <= i*self.angle then
            if direct then
                targetAngle = i*self.angle
                self.frontid = 5-i
            else
                targetAngle = (i-1)*self.angle
                self.frontid = 6-i
            end

            if self.frontid>4 then
                self.frontid = 1
            elseif self.frontid<0 then
                self.frontid = 4
            end
        end
    end

    self.timer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        local newangle = self.rotaAngle + stepdis*(self.pi/1800)
        if direct then
            if newangle >= targetAngle then
                self.rotaAngle = targetAngle
                self:setSlot()
                self:equipShow()
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
                self.rootItems.arrNode:setVisible(true)
                return
            end
        else
            if newangle <= targetAngle then
                self.rotaAngle = targetAngle
                self:setSlot()
                self:equipShow()
                self.rootItems.arrNode:setVisible(true)
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
                return
            end
        end
        self.rotaAngle = newangle
        self:setSlot()

    end, 0, false)
end

function equipUp.setEquipIcons(self, isStar)
    local equipsData = self.slotequips[tostring(self.sid)].equips

    for k,v in pairs(equipsData) do
        local item = self.equippos[self.equiptype[k]].item
        if next(v) then 
            if self.equips[v.iid] and next(self.equips[v.iid]) then
                ui.setNewIcon(item, {cid = self.equips[v.iid].cid,num = "等级."..self.equips[v.iid].level1})
            else
                ui.setNewIcon(item, {cid = v.cid,num = "等级."..v.level1})
            end
            item.namenode:setVisible(true)
            local config = gamedata.config.equip[tostring(v.cid)]
            item.name:setString(ui.getEquipStageName(v) or "")
            if config.quality >= 7 then
                ui.setLabelString(item.name,nil, 213)
            else
                ui.setLabelString(item.name,nil, (config.quality or 1)*2-1)
            end
        else
            ui.setNewIcon(item, {})
            item.namenode:setVisible(false)
        end
    end

    if isStar then
        for k,v in pairs(self.equiptype) do
            local data = {}
            local equipsdata = self.slotequips[tostring(self.sid)].equips
            if equipsdata[k] then 
                if self.equips[equipsdata[k].iid] and next(self.equips[equipsdata[k].iid]) then 
                    data.data = self.equips[equipsdata[k].iid]
                else
                    data.data = equipsdata[k]
                end
                
                self:setStarShow(self.equiptype[k], data.data)
            end
        end
    end
end


function equipUp.createGeneralList(self,alldata)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("slotsInfo/generalIcon.ccbi", nil, true, "generalIcon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }

                ui.tableviewAnimationH(self.generalListTableView,cellCCB,self.titleCellSize.x, self.titleCellSize.y,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            cellCCB:setScale(0.9)
            ccbDocumentControler.selectEffect:removeAllChildrenWithCleanup(true)

            -- 设置头像
            local slotdata = self.slotequips[tostring(a1+1)]
            local configGeneral = gamedata.config.general[tostring(slotdata.general.cid)]
            local gdata = {}
            if configGeneral.fashion_id == 0 then --非时装
                for k,v in pairs(self.generalsData) do
                    if slotdata.general.cid == v.cid then
                        if v.illusionGeneralCid == nil then
                            gdata = ui.getConfigGeneral(v)
                        end
                        break
                    end
                end
            end
            if next(gdata) then
                ui.setSlotGeneralIcon(slotdata,ccbDocumentControler,0,gdata)
            else
                ui.setSlotGeneralIcon(slotdata,ccbDocumentControler)
            end

            if self.sid == a1+1 then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                ccbDocumentControler.selectEffect:addChild(eccb)
            end

            if self.generalListTableView then
                cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.slotequips)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            self.sid = a1:getIdx()+1
            self:equipShow()
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
    self.generalListTableView:setTouchPriority(-102)
    --
    if self.sid > 5 then
        self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.sid-5) ,0),0.2)
    end
end


function equipUp.reloadEquipsData(self,t)
    if self.data then 
        self:equipShow()
    end
end

function equipUp.equipShow(self)
    print("c",self.sid)
    printT(self.slotequips,"在阵装备")
    for k,v in pairs(self.equiptype) do
        if v == self.frontid then 
            local data = {}
            local equipsdata = self.slotequips[tostring(self.sid)].equips
            printT(equipsdata,"  yyz  要显示的武将信息")

            if equipsdata[k] then 
                if self.equips[equipsdata[k].iid] and next(self.equips[equipsdata[k].iid]) then 
                    data.data = self.equips[equipsdata[k].iid]
                else
                    data.data = equipsdata[k]
                end
            end
            data.sid = self.sid
            self:reload(data)
        end
    end
end

function equipUp.clear(self)
    if self.timer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.timer)
    end
    self.timer = nil
    self.dotimes = 10

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.selectpage = "up"
    self.xlselect = 1
    self.xiliansStoneNum = 0
    self.rolecoin = 0

    self.generalListTableView = nil

    self.data = nil
    self.sid = 1
    self.equips = {}
    self.equippos = {}
    self.generalsData = {}
    self.rotaAngle = 0

    self.jj_spendpropsdata = nil
end


function equipUp.reloaddata(self,data,isStar)
	printT(data,"equipUp.reloaddata =========")

    if isStar then
        if data and next(data) then
            self.data = data
            self.equips[data.iid] = data
        end
    else
        if self.data and (data.equip.level2 > self.data.level2 or data.equip.level1 > self.data.level1) then
           self.hasup = 1
        else
           self.hasup = 0
        end
    
        self.data = data.equip or {}
        
        if data.equip and next(data.equip) and data.equip.iid then
            self.equips[data.equip.iid] = data.equip
        end
    end

    self.criticalnum = data.criticalnum

    self.rolecoin = data.coin or GameScene.roleinfo.coin
    self.selectpage = data.pagetype or self.selectpage
    self:shiftPage(self.selectpage)
end

--显示洗练页面
function equipUp.setPage_strengthen(self)
	print("显示洗练页面")

    self.hasXLPreview = false
    ui.setLabelString(self.rootItems["xl_Lab1"],nil,19)
    ui.setLabelString(self.rootItems["xl_Lab2"],"洗炼 X"..(self.dotimes or 10),19)
    ui.setLabelString(self.rootItems["xl_Lab3"],nil,19)
    ui.setLabelString(self.rootItems["xl_Lab_no"],nil,19)
    ui.setLabelString(self.rootItems["xl_Lab_yes"],nil,19)
    self:setEquipIcons()

    if self.data and self.data.cid and self.data.cid > 0 then
        self.rootItems.strengthenNode:setVisible(true)
    else
        self.rootItems.strengthenNode:setVisible(false)
        runGamePrompt({msg= "请穿戴装备"})
        return
    end

    local equipquality = self.xilianLimit
    if self.data and self.data.cid and gamedata.config.equip[tostring(self.data.cid)] and gamedata.config.equip[tostring(self.data.cid)].quality >= 3 then
        equipquality = gamedata.config.equip[tostring(self.data.cid)].quality
        --self.rootItems.strengthenNode:setVisible(true)
        self.rootItems.xl_nonode1:setVisible(true)
        self.rootItems.xl_nonode2:setVisible(true)
        self.rootItems.xilianblueLimitSpr:setVisible(false)
        self.rootItems.xilianNoneLab:setVisible(false)

        ui.removeGray("CCControlButton",self.rootItems.xl_Button_no)
        ui.removeGray("CCControlButton",self.rootItems.xl_Button_yes)
        ui.removeGray("CCControlButton",self.rootItems.xl_Button1)
        ui.removeGray("CCControlButton",self.rootItems.xl_Button2)
        ui.removeGray("CCControlButton",self.rootItems.xl_Button3)
        ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab1)
        ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab2)
        ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab3)
        ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab_no)
        ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab_yes)

    else
        --self.rootItems.strengthenNode:setVisible(false)
        self.rootItems.xl_nonode1:setVisible(false)
        self.rootItems.xl_nonode2:setVisible(false)
        self.rootItems.xilianblueLimitSpr:setVisible(true)
        self.rootItems.xilianNoneLab:setVisible(true)
        self.rootItems.xl_Node_no:setVisible(false)
        self.rootItems.xl_Node_yes:setVisible(false)
        self.rootItems.xl_Node1:setVisible(true)
        self.rootItems.xl_Node2:setVisible(true)
        self.rootItems.xl_Node3:setVisible(true)
        self.rootItems.xl_Node1:setPositionX(-330)
        self.rootItems.xl_Node2:setPositionX(0)
        self.rootItems.xl_Node3:setPositionX(330)
        runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})

        ui.addGray("CCControlButton",self.rootItems.xl_Button_no)
        ui.addGray("CCControlButton",self.rootItems.xl_Button_yes)
        ui.addGray("CCControlButton",self.rootItems.xl_Button1)
        ui.addGray("CCControlButton",self.rootItems.xl_Button2)
        ui.addGray("CCControlButton",self.rootItems.xl_Button3)
        ui.addGray("CCLabelTTF",self.rootItems.xl_Lab1)
        ui.addGray("CCLabelTTF",self.rootItems.xl_Lab2)
        ui.addGray("CCLabelTTF",self.rootItems.xl_Lab3)
        ui.addGray("CCLabelTTF",self.rootItems.xl_Lab_no)
        ui.addGray("CCLabelTTF",self.rootItems.xl_Lab_yes)
        
        -- self.rootItems.xl_Button_no:addHandleOfControlEvent(function()
        --     runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})
        -- end, CCControlEventTouchUpInside)
        -- self.rootItems.xl_Button_no:setSwallowsTouch(true)
        -- self.rootItems.xl_Button_no:setTouchPriority(self.touchPriority)
        -- --
        -- self.rootItems.xl_Button1:addHandleOfControlEvent(function()
        --     runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})
        -- end, CCControlEventTouchUpInside)
        -- self.rootItems.xl_Button1:setSwallowsTouch(true)
        -- self.rootItems.xl_Button1:setTouchPriority(self.touchPriority)
        -- --
        -- self.rootItems.xl_Button2:addHandleOfControlEvent(function()
        --     runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})
        -- end, CCControlEventTouchUpInside)
        -- self.rootItems.xl_Button2:setSwallowsTouch(true)
        -- self.rootItems.xl_Button2:setTouchPriority(self.touchPriority)
        -- --
        -- self.rootItems.xl_Button3:addHandleOfControlEvent(function()
        --     runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})
        -- end, CCControlEventTouchUpInside)
        -- self.rootItems.xl_Button3:setSwallowsTouch(true)
        -- self.rootItems.xl_Button3:setTouchPriority(self.touchPriority)
        -- --
        -- self.rootItems.xl_Button_yes:addHandleOfControlEvent(function()
        --     runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})
        -- end, CCControlEventTouchUpInside)
        -- self.rootItems.xl_Button_yes:setSwallowsTouch(true)
        -- self.rootItems.xl_Button_yes:setTouchPriority(self.touchPriority)
        --return
    end


    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    if equipConfig.type ~= "horse" and equipConfig.type ~= "treasure" then
        self.rootItems.up_name:setString(ui.getEquipStageName(self.data) or "")
    else
        self.rootItems.up_name:setString(equipConfig.name..(self.data.level2+0 > 0 and " +"..self.data.level2 or "" ))
    end
    if equipConfig.quality >= 7 then
        ui.setLabelString(self.rootItems.up_name,nil,213)
    else
        ui.setLabelString(self.rootItems.up_name,nil,(equipConfig.quality or 1)*2-1)
    end
    
    --
    -- 装备升星星级展示
    ui.setNewIcon(self.rootItems,self.data,nil,self.data)
    if equipConfig.suit and equipConfig.suit > 0 then
        self.isSuit = true
    else
        self.isSuit = false
    end
    --
    local baseY = -100
    for i = 1,4 do
    	print("i === "..i)
        self["xl_max"..i] = false
        self.rootItems["xl_up_max"..i]:setVisible(false)
        self.rootItems["xl_up_node"..i]:setVisible(false)
        self.rootItems["xl_down_node"..i]:setVisible(false)
        if equipConfig["baptize_attr"..i] and equipConfig["baptize_attr"..i] ~= "" then
            self.rootItems["xl_type"..i]:setString(gameConfig.strings.attr_type[equipConfig["baptize_attr"..i]]..":")
            self.rootItems["xl_num"..i]:setString(self.data["x"..equipConfig["baptize_attr"..i]] or 0)
            self.rootItems["xl_max"..i]:setString("( 最大"..(equipConfig["attrlimitup_"..i]*(self.data.level1-1)+equipConfig["attrlimit"..i]).." )")
            ui.setLabelString(self.rootItems["xl_num"..i],nil,22)
            ui.setLabelString(self.rootItems["xl_type"..i],nil,13)
            ui.setLabelString(self.rootItems["xl_max"..i],nil,13)

            if self.data["x"..equipConfig["baptize_attr"..i]] >= (equipConfig["attrlimitup_"..i]*(self.data.level1-1)+equipConfig["attrlimit"..i]) then
                self["xl_max"..i] = true
            end
            --
            self.rootItems["xl_type_node"..i]:setVisible(true)
            self.rootItems["xl_type_node"..i]:setPositionY(baseY)
            baseY = baseY-40
        else
            self["xl_max"..i] = true
            self.rootItems["xl_type_node"..i]:setVisible(false)
        end
    end

    for i = 1,3 do
        self:xlShowBottom(i, equipquality)
        self.rootItems["xl_select_button"..i]:addHandleOfControlEvent(function()
            local callBack = function()
                self.xlselect = i
                for ii = 1,3 do
                    self:xlShowBottom(ii, equipquality)
                end
            end
            if i == 3 and self.xlselect ~= 3 then
                gameWindows:openWindow("confirm",{msg = "高级洗炼需要消耗元宝，是否切换为高级洗炼？"}, callBack)
            else
                callBack()
            end
        end, CCControlEventTouchUpInside)
        self.rootItems["xl_select_button"..i]:setSwallowsTouch(true)
        self.rootItems["xl_select_button"..i]:setTouchPriority(self.touchPriority)
        --
        local xprop = ui.getIDandNUMs(tostring(gamedata.config.global_kv["baptize_consume_"..i].value))
        for k,v in pairs(xprop) do
            if v.cid == 1000 then
                self.xl_coin = v.num or 0
                ui.setLabelString(self.rootItems["xl_coin"],v.num,14)
                ui.setLabelString(self.rootItems["xl_coin_10"],v.num*self.dotimes,14)
            elseif v.cid == 1001 then
                self.xl_gold = v.num or 0
                ui.setLabelString(self.rootItems["xl_gold"],v.num,14)
                ui.setLabelString(self.rootItems["xl_gold_10"],v.num*self.dotimes,14)
            elseif v.cid == 20222 then
                self["xl_stone"..i] = v.num or 0
                ui.setLabelString(self.rootItems["xl_stone"..i],v.num,14)
                ui.setLabelString(self.rootItems["xl_stone"..i.."_10"],v.num*self.dotimes,14)
            end
        end
    end

    self.rootItems["xl_stone_has"]:setString(self.xiliansStoneNum or 0)
    ui.setLabelString(self.rootItems["xl_stone_has"],nil,18)

    UIRequest({type = 12001, order = 11004, cids = {20222}})

    if self.xl_max1 and self.xl_max2 and self.xl_max3 and self.xl_max4 then
        ui.addGray("CCControlButton",self.rootItems.xl_Button1)
        ui.addGray("CCControlButton",self.rootItems.xl_Button2)
        ui.addGray("CCControlButton",self.rootItems.xl_Button3)
    else
        ui.removeGray("CCControlButton",self.rootItems.xl_Button1)
        ui.removeGray("CCControlButton",self.rootItems.xl_Button2)
        ui.removeGray("CCControlButton",self.rootItems.xl_Button3)
    end

    self.rootItems.xl_Button1:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)

        if self.data and self.data.cid and gamedata.config.equip[tostring(self.data.cid)] and gamedata.config.equip[tostring(self.data.cid)].quality >= 3 then
            if self.xl_max1 and self.xl_max2 and self.xl_max3 and self.xl_max4 then
                runGamePrompt({msg = "属性已达当前上限，强化装备可提高上限"})
                return
            end
            self.xlselectbtn = 1
            UIRequest({type = 1120, iid = self.data.iid, method = self.xlselect, xlnum = 1,})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})
            return
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.xl_Button1:setSwallowsTouch(true)
    self.rootItems.xl_Button1:setTouchPriority(self.touchPriority)

    self.rootItems.xl_Button2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)

        if self.data and self.data.cid and gamedata.config.equip[tostring(self.data.cid)] and gamedata.config.equip[tostring(self.data.cid)].quality >= 3 then
            if self.xl_max1 and self.xl_max2 and self.xl_max3 and self.xl_max4 then
                runGamePrompt({msg = "属性已达当前上限，强化装备可提高上限"})
                return
            end
            self.xlselectbtn = 2
            UIRequest({type = 1120, iid = self.data.iid, method = self.xlselect, xlnum = self.dotimes or 10,})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})
            return
        end


    end, CCControlEventTouchUpInside)
    self.rootItems.xl_Button2:setSwallowsTouch(true)
    self.rootItems.xl_Button2:setTouchPriority(self.touchPriority)

    self.rootItems.xl_Button3:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)

        if self.data and self.data.cid and gamedata.config.equip[tostring(self.data.cid)] and gamedata.config.equip[tostring(self.data.cid)].quality >= 3 then
            if self.xl_max1 and self.xl_max2 and self.xl_max3 and self.xl_max4 then
                runGamePrompt({msg = "属性已达当前上限，强化装备可提高上限"})
                return
            end
            local vipopen = ui.getVipLevelByStr("vip_baptize")
            if GameScene.roleinfo.level < tonumber(gamedata.config.global_kv.free_automatic_level.value) and vipopen > GameScene.vip.vip then
                runGamePrompt({msg = "等级不足，"..gamedata.config.global_kv.free_automatic_level.value.."级或VIP"..vipopen.."开启！"})
            else
                local callBack = function()
                    gameWindows:openWindow("equipbaptize",{cid = self.data.cid,iid = self.data.iid, method = self.xlselect},nil)
                end
                if self.xlselect >= 3 then
                    gameWindows:openWindow("confirm",{msg = "本次自动洗练为元宝洗练"}, callBack)
                else
                    callBack();
                end
            end
        else
            runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})
            return
        end
       
    end, CCControlEventTouchUpInside)
    self.rootItems.xl_Button3:setSwallowsTouch(true)
    self.rootItems.xl_Button3:setTouchPriority(self.touchPriority)
    --

    self.rootItems.xl_Button_no:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)

        if self.data and self.data.cid and gamedata.config.equip[tostring(self.data.cid)] and gamedata.config.equip[tostring(self.data.cid)].quality >= 3 then
            if self.hasXLPreview then
                self.hasXLPreview = false
                UIRequest({type = 1121, id = self.data.iid, method = 0,})
            end
        else
            runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})
            return
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.xl_Button_no:setSwallowsTouch(true)
    self.rootItems.xl_Button_no:setTouchPriority(self.touchPriority)

    self.rootItems.xl_Button_yes:addHandleOfControlEvent(function()
        
        gameTouch:clickprofbytime(0.5)
        if self.data and self.data.cid and gamedata.config.equip[tostring(self.data.cid)] and gamedata.config.equip[tostring(self.data.cid)].quality >= 3 then
            if self.hasXLPreview then
                self.hasXLPreview = false
                UIRequest({type = 1121, id = self.data.iid, method = 1,})
            end
        else
            runGamePrompt({msg = gameConfig.strings:string_common("equipUp",23)})
            return
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.xl_Button_yes:setSwallowsTouch(true)
    self.rootItems.xl_Button_yes:setTouchPriority(self.touchPriority)
    --
    self.rootItems.xl_Node_no:setVisible(false)
    self.rootItems.xl_Node_yes:setVisible(false)

    self.rootItems.xl_Node1:setVisible(true)
    self.rootItems.xl_Node2:setVisible(true)
    self.rootItems.xl_Node3:setVisible(true)
    self.rootItems.xl_Node1:setPositionX(-330)
    self.rootItems.xl_Node2:setPositionX(0)
    self.rootItems.xl_Node3:setPositionX(330)
    --

    self.rootItems.xl_Button_yes:setEnabled(true)
    -- ui.removeGray("CCControlButton",self.rootItems.xl_Button_yes)
    -- ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab_yes)
    self.rootItems.xl_Button_no:setEnabled(true)
    -- ui.removeGray("CCControlButton",self.rootItems.xl_Button_no)
    -- ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab_no)
    for i = 1,3 do
        self.rootItems["xl_Button"..i]:setEnabled(true)
        -- ui.removeGray("CCControlButton",self.rootItems["xl_Button"..i])
        -- ui.removeGray("CCLabelTTF",self.rootItems["xl_Lab"..i])
    end

    --
    self.rootItems.xl_addStone:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("dropTips",{cid = 20222,num = self.xiliansStoneNum or 0},nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.xl_addStone:setSwallowsTouch(true)
    self.rootItems.xl_addStone:setTouchPriority(self.touchPriority)	
end

function equipUp.xlShowBottom(self,num, equipquality)
    self.rootItems["xl_select"..num]:setVisible(num == self.xlselect)
    if num == self.xlselect then
        if equipquality > self.xilianLimit then
            self.rootItems["xilian_node"..num.."_1"]:setVisible(true)
            self.rootItems["xilian_node"..num.."_10"]:setVisible(true)
        else
            self.rootItems["xilian_node"..num.."_1"]:setVisible(false)
            self.rootItems["xilian_node"..num.."_10"]:setVisible(false)
        end
    else
        self.rootItems["xilian_node"..num.."_1"]:setVisible(false)
        self.rootItems["xilian_node"..num.."_10"]:setVisible(false)
    end
end


--显示强化页面
function equipUp.setPage_up(self)
	print("显示强化页面")

    ui.setLabelString(self.rootItems.up_addLab,"强化5级",19)
    ui.setLabelString(self.rootItems.up_upLab,"强 化",19)
    self:setEquipIcons()
    
    if self.data and self.data.cid and self.data.cid > 0 then
        self.rootItems.upNode:setVisible(true)
    else
        self.rootItems.upNode:setVisible(false)
        runGamePrompt({msg= "请穿戴装备"})
        return
    end

    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    if equipConfig.type ~= "horse" and equipConfig.type ~= "treasure" then
        self.rootItems.up_name:setString(ui.getEquipStageName(self.data) or "")
    else
        self.rootItems.up_name:setString(equipConfig.name..(self.data.level2+0 > 0 and " +"..self.data.level2 or "" ))
    end
    -- 装备升星属性提升展示
    ui.setEquipStarPropertyshow(self.rootItems,self.data)

    if equipConfig.suit and equipConfig.suit > 0 then
    	self.rootItems.equipType:setString("<套装·"..gameConfig.strings.equipType[equipConfig.type]..">")
        self.rootItems.equipType2:setVisible(true)
        self.isSuit = true
    else
    	self.rootItems.equipType:setString("<"..gameConfig.strings.equipType[equipConfig.type]..">")
        self.rootItems.equipType2:setVisible(false)
        self.isSuit = false
    end

    local maxlv = 0
    maxlv = GameScene.roleinfo.level*tonumber(gamedata.config.global_kv.equip_level.value)
    if equipConfig.maxlevel and (maxlv > (equipConfig.maxlevel+0)) then
       maxlv = equipConfig.maxlevel+0
    end
    ui.setLabelString(self.rootItems["lv1"],self.data.level1.."/"..maxlv,14)

    local type1,num1 = ui.setEquipPromote(self.rootItems["num1"],nil,self.data)
    ui.setLabelString(self.rootItems["num1"],num1,14)
    ui.setLabelString(self.rootItems["type1"],type1,14)

    local effectnum = 0
    if GameScene.guildWarProfit and GameScene.guildWarProfit.effect and GameScene.guildWarProfit.effect > 0 then
        effectnum = GameScene.guildWarProfit.effect
    end

    if self.data.level1 < maxlv then
        ui.setLabelString(self.rootItems["next_lv1"],(self.data.level1+1).."/"..maxlv,23)
        local type1_,num1_,type2_,num2_ = ui.setEquipPromote(nil,nil,{cid=self.data.cid, level1=self.data.level1+1, level2=self.data.level2})
        ui.setLabelString(self.rootItems["next_num1"],num1_,23)
        ui.setLabelString(self.rootItems["x_coinNum2"],math.ceil(gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality]*(100-effectnum)/100) ,14)
        if self.rootItems["next_type1"] then
            ui.setLabelString(self.rootItems["next_type1"],type1_,23)
        end

        if self.rolecoin < math.ceil(gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality]*(100-effectnum)/100) then
            ui.setLabelString(self.rootItems["x_coinNum2"], nil,24)
        else
            ui.setLabelString(self.rootItems["x_coinNum2"], nil,14)
        end
    else
        ui.setLabelString(self.rootItems["next_lv1"],self.data.level1.."/"..maxlv,23)
        ui.setLabelString(self.rootItems["next_num1"],num1,23)
        ui.setLabelString(self.rootItems["x_coinNum2"],0,14)
        if self.rootItems["next_type1"] then
            ui.setLabelString(self.rootItems["next_type1"],type1,23)
        end
    end



    if self.data.level1 >= maxlv then
        ui.addGray("CCControlButton",self.rootItems.up_addButton)
    else
        ui.removeGray("CCControlButton",self.rootItems.up_addButton)
    end

    ui.setLabelString(self.rootItems.up_addLab,"强化5级",19)
    self.rootItems.up_addButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.data.level1+0 >= maxlv then
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",9)})
        elseif self.rolecoin < math.ceil(gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality]*(100-effectnum)/100) then
            shortCoin()
        else
            if equipConfig.type == "horse" or equipConfig.type == "treasure" then
                 runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",11)})
            else
                UIRequest({type = 1101, xcoin = math.ceil(gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality]*(100-effectnum)/100), iid = self.data.iid, method = 1})
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.up_addButton:setSwallowsTouch(true)
    self.rootItems.up_addButton:setTouchPriority(self.touchPriority)

    if self.data.level1 >= maxlv then
        ui.addGray("CCControlButton",self.rootItems.up_upButton)
    else
        ui.removeGray("CCControlButton",self.rootItems.up_upButton)
    end

    ui.setLabelString(self.rootItems.up_upLab,"强 化",19)
    self.rootItems.up_upButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.data.level1+0 >= maxlv then
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",9)})
        elseif self.rolecoin < math.ceil(gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality]*(100-effectnum)/100) then
            shortCoin()
        else
            if equipConfig.type == "horse" or equipConfig.type == "treasure" then
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",11)})
            else
                UIRequest({type = 1101, xcoin = math.ceil(gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality]*(100-effectnum)/100), iid = self.data.iid, method = 0})
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.up_upButton:setSwallowsTouch(true)
    self.rootItems.up_upButton:setTouchPriority(self.touchPriority)

    --effect
    if self.hasup and self.hasup == 1 then
        self.hasup = 0
        self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/qianghua/qianghua", nil, true, "qianghua")
        qianghuaNode:setPosition(0,0)

        if self.criticalnum and next(self.criticalnum) then
            local critical = self.criticalnum[tostring(self.data.iid)] or 0              
            if critical>0 then
                qianghuaItems.criticalnode:setVisible(true)
                qianghuaItems.num:setString("暴击"..critical.."次")
            else
                qianghuaItems.criticalnode:setVisible(false)
            end
        end
        self.rootItems.effectNode:addChild(qianghuaNode)
        self.rootItems.effectNode:setScale(1)
        local animationManager = getAnimationManager(qianghuaItems)
        animationManager:setAnimationCompletedCallback(function()
            self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
            if guide.controller then
                guide.controller:setGuideLayerVisible(true)
            end
        end)
        animationManager:runAnimationsForSequenceNamed("qianghua")
        gamedata.music:PlayOptSound("qh")
    end	
end

-- 注灵
function equipUp.setPage_Cast(self)

    self:setEquipIcons()
    if self.data and self.data.cid and self.data.cid > 0 then
        self.rootItems.castNode:setVisible(true)
    else
        self.rootItems.castNode:setVisible(false)
        runGamePrompt({msg= "请穿戴装备"})
        return
    end


    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    print("self.data.cid =  "..self.data.cid)
    printT(equipConfig,"equipConfig =========")

    self:showAllEquipCast()
    if equipConfig.type ~= "horse" and equipConfig.type ~= "treasure" then
        self.rootItems.up_name:setString(ui.getEquipStageName(self.data) or "")
    else
        self.rootItems.up_name:setString(equipConfig.name..(self.data.level2+0 > 0 and " +"..self.data.level2 or "" ))
    end

    if equipConfig.quality >= 7 then
        ui.setLabelString(self.rootItems.up_name,nil,213)
    else
        ui.setLabelString(self.rootItems.up_name,nil,(equipConfig.quality or 1)*2-1)
    end
  
    ui.setNewIcon(self.rootItems,self.data,nil,self.data)
    
    self.rootItems.fixedc:setString(gameConfig.strings:string_common("equips",28))

    local maxlv = GameScene.roleinfo.level > equipConfig.forging_maxlevel and equipConfig.forging_maxlevel or GameScene.roleinfo.level
    
    ui.setLabelString(self.rootItems["lv1c"],self.data.level4.."/"..maxlv,14)

    local num = "+"..math.floor(equipConfig.forging_grow* self.data.level4 * (equipConfig.method1 == "value" and 1 or 100))..(equipConfig.method1 == "value" and "" or "%")
    ui.setLabelString(self.rootItems["num1c"],num,14)
    ui.setLabelString(self.rootItems["type1c"],gameConfig.strings.attr_type[equipConfig.attr1]..":",14)

    if self.data.level4 < maxlv then
        ui.setLabelString(self.rootItems["next_lv1c"],(self.data.level4+1).."/"..maxlv,23)
        local num1 = "+"..math.floor(equipConfig.forging_grow* (self.data.level4 + 1) * (equipConfig.method1 == "value" and 1 or 100))..(equipConfig.method1 == "value" and "" or "%")
        ui.setLabelString(self.rootItems["next_num1c"],num1,23)
        ui.setLabelString(self.rootItems["next_type1c"],gameConfig.strings.attr_type[equipConfig.attr1]..":",23)
    else
        ui.setLabelString(self.rootItems["next_lv1c"],self.data.level4.."/"..maxlv,23)
        ui.setLabelString(self.rootItems["next_num1c"],num,23)
        ui.setLabelString(self.rootItems["next_type1c"],gameConfig.strings.attr_type[equipConfig.attr1]..":",23)
    end

    if self.hasup and self.hasup == 1 then
        self.hasup = 0
        self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
        self.rootItems.effectNode3:removeAllChildrenWithCleanup(true)
        
        local qianghuaNode2,qianghuaItems2 = CCBReaderLoad("UIEffect/qianghua/qianghua2", nil, true, "qianghua2")
        qianghuaNode2:setPosition(0,0)
        self.rootItems.effectNode3:addChild(qianghuaNode2)
        self.rootItems.effectNode3:setScale(1)
        local animationManager2 = getAnimationManager(qianghuaItems2)
        animationManager2:setAnimationCompletedCallback(function()
            self.rootItems.effectNode3:removeAllChildrenWithCleanup(true)
            local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/qianghua/qianghua", nil, true, "qianghua")
            qianghuaNode:setPosition(0,0)

            qianghuaItems.criticalnode:setVisible(false)
            self.rootItems.effectNode:addChild(qianghuaNode)
            self.rootItems.effectNode:setScale(1)
            local animationManager = getAnimationManager(qianghuaItems)
            animationManager:setAnimationCompletedCallback(function()
                self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
            end)
            animationManager:runAnimationsForSequenceNamed("qianghua")
        end)
        animationManager2:runAnimationsForSequenceNamed("qianghua2")
        --
        gamedata.music:PlayOptSound("qh")
    end	

    if self.data.level4 >= maxlv then
        ui.setLabelString(self.rootItems.castNum1,"0",13)
        ui.setLabelString(self.rootItems.castNum10,"0",13)
    end

    self.rootItems.itemButton:addHandleOfControlEvent(function()
        ui.setPopwindowByCid("20669");
    end, CCControlEventTouchUpInside)

    -- 注灵按钮
    ui.setLabelString(self.rootItems.cast_upLab,gameConfig.strings:string_common("equips",28),19)
    self.rootItems.cast_upButton:addHandleOfControlEvent(function()
        if self.data.level4 >= maxlv then
            if maxlv == 0 then
                runGamePrompt({msg = gameConfig.strings:string_common("equips",36)})
            else
                runGamePrompt({msg = gameConfig.strings:string_common("equips",32)})
            end
            return
        end

        local upconfig = gamedata.config.equip_forgingConsume[tostring(self.data.level4 + 1)]
        local spenddata = upconfig["quality"..self.data.quality] or {}
        local spengtemp = {}
        spengtemp = gamedata.getIDandNUMs(spenddata)
        for i,v in ipairs(spengtemp) do
            if v.cid == 1000 then
                if (self.castProps[tostring(v.cid)] or 0) < v.num then
                    shortCoin()
                    return
                end
            elseif ((self.castProps[tostring(v.cid)] or 0) < v.num) then
                runGamePrompt({msg = gameConfig.strings:string_common("equips",33)})
                return
            end
        end
        gameTouch:clickprofbytime(1.0)
        UIRequest({type = 5521,iid = self.data["iid"],count = 1,props = spengtemp})
    end, CCControlEventTouchUpInside)
    self.rootItems.cast_upButton:setSwallowsTouch(true)
    self.rootItems.cast_upButton:setTouchPriority(self.touchPriority)

    --注灵十次
    if self.rootItems.cast_addButton then
        -- ui.setLabelString(self.rootItems.cast_addLab,gameConfig.strings:string_common("equips",35),19)
        self.rootItems.cast_addButton:addHandleOfControlEvent(function()
            if self.data.level4 >= maxlv then
                if maxlv == 0 then
                    runGamePrompt({msg = gameConfig.strings:string_common("equips",36)})
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("equips",32)})
                end
                return
            end

            local allspend = {}
            local allspenddata = {}
            local allspendtemp = {}
            local allcount = 0
            local isout = false
            for i = 1,10 do
                if (self.data.level4+i) > maxlv then
                    break
                end    
                local upconfig = gamedata.config.equip_forgingConsume[tostring(self.data.level4 + i)]
                local spenddata = upconfig["quality"..self.data.quality] or {}
                local spengtemp = {}
                spengtemp = gamedata.getIDandNUMs(spenddata)
                for i,v in ipairs(spengtemp) do
                    if allspendtemp[tostring(v.cid)] and allspendtemp[tostring(v.cid)].num then
                        allspendtemp[tostring(v.cid)].num = allspendtemp[tostring(v.cid)].num + v.num
                    else
                        allspendtemp[tostring(v.cid)] = {cid = v.cid, num = v.num}
                    end    
                    if v.cid == 1000 then
                        if (self.castProps[tostring(v.cid)] or 0) < allspendtemp[tostring(v.cid)].num then
                            isout = true
                            if allcount > 0 then
                                break
                            else    
                                shortCoin()
                                return
                            end
                        end
                    elseif ((self.castProps[tostring(v.cid)] or 0) < allspendtemp[tostring(v.cid)].num) then
                        isout = true
                        if allcount > 0 then
                            break
                        else   
                            runGamePrompt({msg = gameConfig.strings:string_common("equips",33)})
                            return
                        end
                    end
                end
                if isout then
                    break
                else    
                    allcount = i
                    allspenddata = table.copy(allspendtemp)
                end
            end

            for k,v in pairs(allspenddata) do
                table.insert(allspend,v)
            end

            gameTouch:clickprofbytime(1.0)
            UIRequest({type = 5521,iid = self.data["iid"],count = allcount,props = allspend})
        end, CCControlEventTouchUpInside)
        self.rootItems.cast_addButton:setSwallowsTouch(true)
        self.rootItems.cast_addButton:setTouchPriority(self.touchPriority)
        --
    end
    self.rootItems.zl_minDescText:setVisible(false)
    self.rootItems.zl_maxDescText:setVisible(false)

    -- 注灵满级时
    if self.data.level4 >= maxlv then
        --self.rootItems.castNode:setVisible(true)
        self.rootItems.attNode:setVisible(false);
        self.rootItems.zl_costnode:setVisible(false)
        ui.addGray("CCControlButton",self.rootItems.cast_upButton)
        if self.rootItems.cast_addButton then
            ui.setLabelString(self.rootItems.castNum10,"0",13)
            ui.addGray("CCControlButton",self.rootItems.cast_addButton)
        end 
        if maxlv == 0 then
            --self.rootItems.castNode:setVisible(false)
            runGamePrompt({msg = "蓝色以上装备才可注灵"})
            -- self.rootItems.fixed2c:setString(gameConfig.strings:string_common("equips",36))
            self.rootItems.zl_minDescText:setVisible(true)
        else
            self.rootItems.zl_maxDescText:setVisible(true)
            -- self.rootItems.fixed2c:setString(gameConfig.strings:string_common("equips",32))
        end
    else
        --self.rootItems.castNode:setVisible(true)
        ui.removeGray("CCControlButton",self.rootItems.cast_upButton)
        if self.rootItems.cast_addButton then
            ui.removeGray("CCControlButton",self.rootItems.cast_addButton)
        end 
        self.rootItems.attNode:setVisible(true)
        self.rootItems.zl_costnode:setVisible(true)
    end

    -- 获取消耗物品的数据
    local upconfig = gamedata.config.equip_forgingConsume[tostring(self.data.level4 + 1)]

    if upconfig then
        local spenddata = upconfig["quality"..self.data.quality] or {}
        local spendtemp = {}
        for k,v in pairs(gamedata.getIDandNUMs(spenddata)) do
            table.insert(spendtemp,v.cid)
        end
        UIRequest({type = 12001, order = 14004, cids = spendtemp})

        UIRequest({type = 10025,param = "equips"})
    else
        UIRequest({type = 12001, order = 14004, cids = {20669}})
    end
    
end

function equipUp.clearShow(self)
    for i=1,4 do
        ui.setLabelString(self.rootItems["equipName_"..i],"未装备",14)
        ui.setLabelString(self.rootItems["itemLv_"..i],"0/0",14)
    end
end

function equipUp.get10Count(self)

    print("get10Count")
    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    local maxlv = GameScene.roleinfo.level > equipConfig.forging_maxlevel and equipConfig.forging_maxlevel or GameScene.roleinfo.level
    if self.data.level4 >= maxlv then
        return
    end

    local isPropEnoughOne = false
    local num1 = 0
    local upconfig = gamedata.config.equip_forgingConsume[tostring(self.data.level4 + 1)]
    if upconfig then
        local spenddata = upconfig["quality"..self.data.quality] or {}
        local spengtemp = gamedata.getIDandNUMs(spenddata)
        if (self.castProps[tostring(spengtemp[1].cid)] or 0) >= spengtemp[1].num then
            isPropEnoughOne = true
        end
        num1 = spengtemp[1].num
    end


    local allspenddata = {}
    local allspendtemp = {}
    local allcount = 0

    if isPropEnoughOne then
        local isout = false
        for i = 1,10 do
            if (self.data.level4+i) > maxlv then
                break
            end    
            local upconfig = gamedata.config.equip_forgingConsume[tostring(self.data.level4 + i)]
            local spenddata = upconfig["quality"..self.data.quality] or {}
            local spengtemp = {}
            spengtemp = gamedata.getIDandNUMs(spenddata)
            for i,v in ipairs(spengtemp) do
                if allspendtemp[tostring(v.cid)] and allspendtemp[tostring(v.cid)].num then
                    allspendtemp[tostring(v.cid)].num = allspendtemp[tostring(v.cid)].num + v.num
                else
                    allspendtemp[tostring(v.cid)] = {cid = v.cid, num = v.num}
                end    
                if v.cid == 1000 then
                    if (self.castProps[tostring(v.cid)] or 0) < allspendtemp[tostring(v.cid)].num then
                        isout = true
                        if allcount > 0 then
                            break
                        else    
                            return
                        end
                    end
                elseif ((self.castProps[tostring(v.cid)] or 0) < allspendtemp[tostring(v.cid)].num) then
                    isout = true
                    if allcount > 0 then
                        break
                    else   
                        return
                    end
                end
            end
            if isout then
                break
            else    
                allcount = i
                allspenddata = table.copy(allspendtemp)
            end
        end
    else
        for i = 1,10 do
            if (self.data.level4+i) > maxlv then
                break
            end    
            local upconfig = gamedata.config.equip_forgingConsume[tostring(self.data.level4 + i)]
            local spenddata = upconfig["quality"..self.data.quality] or {}
            local spengtemp = {}
            spengtemp = gamedata.getIDandNUMs(spenddata)
            for i,v in ipairs(spengtemp) do
                if allspendtemp[tostring(v.cid)] and allspendtemp[tostring(v.cid)].num then
                    allspendtemp[tostring(v.cid)].num = allspendtemp[tostring(v.cid)].num + v.num
                else
                    allspendtemp[tostring(v.cid)] = {cid = v.cid, num = v.num}
                end
            end
            allcount = i
            allspenddata = table.copy(allspendtemp)
        end
    end
    
    if allcount == 1 then
        allcount = "一"
    elseif allcount == 2 then
        allcount = "二"
    elseif allcount == 3 then
        allcount = "三"
    elseif allcount == 4 then
        allcount = "四"
    elseif allcount == 5 then
        allcount = "五"
    elseif allcount == 6 then
        allcount = "六"
    elseif allcount == 7 then
        allcount = "七"
    elseif allcount == 8 then
        allcount = "八"
    elseif allcount == 9 then
        allcount = "九"
    elseif allcount == 10 then
        allcount = "十"
    end
    local num = allspenddata["20669"] and allspenddata["20669"].num or 0

    ui.setLabelString(self.rootItems.castNum1,num1,isPropEnoughOne and 13 or 24)
    ui.setLabelString(self.rootItems.castNum10,num,isPropEnoughOne and 13 or 24)
    ui.setLabelString(self.rootItems.cast_addLab,"注灵"..allcount.."次",19)
end

function equipUp.showAllEquipCast( self )
    self:clearShow();
    local curIndex = 1;
    local minLv = 1000;
    local equipsData = self.slotequips[tostring(self.sid)].equips

    for i,v in pairs(equipsData) do
        printT(v,"  v  ");
        if v and v ~= {} then
            if v.type == "weapon" then
                curIndex = 1
                -- 武器1
            elseif v.type == "head" then
                curIndex = 2
                -- 头盔3
            elseif v.type == "accessory" then
                curIndex = 4
                -- 佩饰4
            elseif v.type == "armor" then
                curIndex = 3
                -- 衣服2
            end
            local curLv = v.level4;
            if v.cid == self.data.cid then
                -- 如果当前装备是正在注灵的装备就用当前的数据更新
                curLv = self.data.level4
                v.level4 = curLv
            end
            
            if curLv then
                if curLv and curLv <= minLv then
                    minLv = curLv
                end
                local curItem = self.rootItems["equipNode"..curIndex];
                if curItem then
                    curItem:setVisible(true)
                end
                local equipConfig = gamedata.config.equip[tostring(v.cid)]
                local maxlv = GameScene.roleinfo.level > equipConfig.forging_maxlevel and equipConfig.forging_maxlevel or GameScene.roleinfo.level
                if equipConfig.quality >= 7 then
                    ui.setLabelString(self.rootItems["equipName_"..curIndex],ui.getEquipStageName(v),213)
                else
                    ui.setLabelString(self.rootItems["equipName_"..curIndex],ui.getEquipStageName(v),(equipConfig.quality or 1)*2-1)
                end
                ui.setLabelString(self.rootItems["itemLv_"..curIndex],curLv.."/"..maxlv,14)
        
            end

        else
            minLv = 0;
        end
    end
    local lowStr = 0
    local att1 = 0
    local att2 = 0
    local att3 = 0
     print("  minLv  ",minLv);
    if minLv > 0 then
        local num = math.floor(minLv/5)
        local minNum = num*5
        local costCof = gamedata.config.equip_foringlv[tostring(minNum)]
        if costCof then
            lowStr = costCof.low_lv
            att1 = "+"..costCof.hp
            att2 = "+"..costCof.atk
            att3 = "+"..costCof.def
        else
            lowStr = 0
            att1 = "+"..0
            att2 = "+"..0
            att3 = "+"..0
        end
    else
        lowStr = 0
        att1 = "+"..0
        att2 = "+"..0
        att3 = "+"..0
    end
    ui.setLabelString(self.rootItems.activationlv,lowStr,14)
    ui.setLabelString(self.rootItems.zhulinhpnum,att1,23)
    ui.setLabelString(self.rootItems.zhulinatknum,att2,23)
    ui.setLabelString(self.rootItems.zhulindefnum,att3,23)
end

--显示升星页面
function equipUp.setPage_shengxing(self)
    print("显示升星页面")
    printT(self.data)
    self:setEquipIcons(true)

    if self.data and self.data.cid and self.data.cid > 0 then
        self.rootItems.shengxingNode:setVisible(true)
    else
        self.rootItems.shengxingNode:setVisible(false)
        runGamePrompt({msg= "请穿戴装备"})
        return
    end

    local equipquality = self.shengxingLimit
    if self.data and self.data.cid and gamedata.config.equip[tostring(self.data.cid)] and gamedata.config.equip[tostring(self.data.cid)].up_star then
        equipquality = gamedata.config.equip[tostring(self.data.cid)].quality
        self.rootItems.nowStarNode:setVisible(true)
        self.rootItems.nowStarNode:setPositionX(0)
        self.rootItems.nextStarNode:setVisible(true)
        self.rootItems.starCoinNode:setVisible(true)
        self.rootItems.sx_node5:setVisible(true)
        
        self.rootItems.sx_minDescText:setVisible(false)
        self.rootItems.sx_maxDescText:setVisible(false)
    else
        self.rootItems.nowStarNode:setVisible(false)
        self.rootItems.nowStarNode:setPositionX(-260)
        self.rootItems.nextStarNode:setVisible(false)
        self.rootItems.starCoinNode:setVisible(true)
        self.rootItems.sx_node5:setVisible(false)
        self.rootItems.sx_minDescText:setVisible(false)
        self.rootItems.sx_maxDescText:setVisible(false)

        self.rootItems.sx_upButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("equipUp",18)})
        end, CCControlEventTouchUpInside)
        self.rootItems.sx_upButton:setSwallowsTouch(true)
        self.rootItems.sx_upButton:setTouchPriority(self.touchPriority)
        --
        if self.data and self.data.cid then
            runGamePrompt({msg = gameConfig.strings:string_common("equipUp",13)})
        end
        return
    end

    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    print("self.data.cid =  "..self.data.cid)
    printT(equipConfig,"equipConfig =========")
    -- 星级限制
    local limitstring = (self.data.level3 or 0).."/"..(equipConfig.up_star or 1)
    ui.setLabelString(self.rootItems.sx_limitLabel,limitstring,14)

    ui.setLabelString(self.rootItems.sx_nowpropertyText,gameConfig.strings:string_common("equipUp",6),14)
    ui.setLabelString(self.rootItems.sx_nextpropertyText,gameConfig.strings:string_common("equipUp",6),14)

    -- 升星按钮
    self.rootItems.sx_upButton:addHandleOfControlEvent(function()
        print("装备升星")

        if self.data.level3 >= equipConfig.up_star then
            -- runGamePrompt({msg = "装备升星已达到最高等级"})
            if equipquality > self.shengxingLimit then
                runGamePrompt({msg = gameConfig.strings:string_common("equipUp",4)})
            else
                runGamePrompt({msg = gameConfig.strings:string_common("equipUp",24)}) 
            end
            return
        end

        local needLevel = 0
        if gamedata.config.equip_star[tostring(self.data.level3 + 1)] and gamedata.config.equip_star[tostring(self.data.level3 + 1)].num and gamedata.config.equip_star[tostring(self.data.level3 + 1)].num > 0 then
            needLevel = gamedata.config.equip_star[tostring(self.data.level3 + 1)].num
        end

        if self.data.level1 < needLevel then
            runGamePrompt({msg = "强化等级不足"})
            return
        end

        local equipstarconfig = gamedata.config.equip_star or {}
        local spenddata = equipstarconfig[tostring(self.data.level3+1)]["cost_"..self.data.quality] or {}
        local spengtemp = {}
        spengtemp = gamedata.getIDandNUMs(spenddata)
        for i,v in ipairs(spengtemp) do
            if v.cid == 1000 then
                if (self.spendPropsData[tostring(v.cid)] or 0) < v.num then
                    shortCoin()
                    return
                end
                
            elseif ((self.spendPropsData[tostring(v.cid)] or 0) < v.num) then
                runGamePrompt({msg = gameConfig.strings:string_common("equipUp",5)})
                return
            end
        end

        UIRequest({type = 1123,iid = self.data["iid"],props = spengtemp})
    end, CCControlEventTouchUpInside)
    self.rootItems.sx_upButton:setSwallowsTouch(true)
    self.rootItems.sx_upButton:setTouchPriority(self.touchPriority)
   
    -- 设置基础属性
    local type1,num1 = ui.setEquipPromote(self.rootItems["sx_attr"],nil,self.data)
    ui.setLabelString(self.rootItems.sx_attr,type1..num1,14)

    -- 当前星级属性
    local percntnum1,type1,num1 = ui.setEquipStarUpStatistics(self.data)

    ui.setLabelString(self.rootItems.sx_nowpropertyLabel,(percntnum1 or "0%"),14)
    ui.setLabelString(self.rootItems.sx_nowattrText,((type1.."：") or ""),14)
    ui.setLabelString(self.rootItems.sx_nowattrLabel,num1,14)

    self.rootItems.sx_limitText2:setVisible(false)
    self.rootItems.sx_limitLabel2:setVisible(false)
        
    -- 升星满级时
    if self.data.level3 >= equipConfig.up_star then
        if equipquality > self.shengxingLimit then
            --self.rootItems.shengxingNode:setVisible(true)
            self.rootItems.nowStarNode:setPositionX(0)
            -- self.rootItems.nowStarNode:setVisible(false)
            self.rootItems.nextStarNode:setVisible(false)
            self.rootItems.starCoinNode:setVisible(false)
            ui.setLabelString(self.rootItems.needcoinLabel, "0",13)
            -- self.rootItems.sx_node5:setVisible(false)
            self.rootItems.sx_minDescText:setVisible(false)
            self.rootItems.sx_maxDescText:setVisible(true)

            self.rootItems.nowStarAttrNode:setVisible(true)
            self.rootItems.nextStarAttrNode:setVisible(true)
            self.rootItems.sx_cmaxDesc1:setVisible(false)
            self.rootItems.sx_cmaxDesc2:setVisible(false)
            self.rootItems.sx_limitText:setVisible(true)
            self.rootItems.sx_limitLabel:setVisible(true)
        else
            ui.setLabelString(self.rootItems.needcoinLabel, "0",13)

            self.rootItems.nowStarNode:setPositionX(-265)
            --self.rootItems.shengxingNode:setVisible(false)
            self.rootItems.starCoinNode:setVisible(false)
            self.rootItems.sx_minDescText:setVisible(true)
            -- self.rootItems.sx_node5:setVisible(false)
            self.rootItems.sx_maxDescText:setVisible(false)


            self.rootItems.nowStarAttrNode:setVisible(false)
            self.rootItems.nextStarAttrNode:setVisible(false)
            self.rootItems.sx_cmaxDesc1:setVisible(true)
            self.rootItems.sx_cmaxDesc2:setVisible(true)

            self.rootItems.sx_limitText:setVisible(false)
            self.rootItems.sx_limitLabel:setVisible(false)
            runGamePrompt({msg = "紫色以上装备才可升星"})
        end

        ui.addGray("CCControlButton",self.rootItems.sx_upButton)

        for i=1,4 do
            self.rootItems["needprop"..i]:setVisible(false)
        end
        return
    else
        --self.rootItems.shengxingNode:setVisible(true)
        self.rootItems.nowStarNode:setPositionX(-260)
        self.rootItems.nextStarNode:setVisible(true)
        self.rootItems.starCoinNode:setVisible(true)
        self.rootItems.sx_node5:setVisible(true)
        self.rootItems.sx_maxDescText:setVisible(false)
        self.rootItems.sx_minDescText:setVisible(false)

        self.rootItems.nowStarAttrNode:setVisible(true)
        self.rootItems.nextStarAttrNode:setVisible(true)
        self.rootItems.sx_cmaxDesc1:setVisible(false)
        self.rootItems.sx_cmaxDesc2:setVisible(false)

        self.rootItems.sx_limitText:setVisible(true)
        self.rootItems.sx_limitLabel:setVisible(true)

        ui.removeGray("CCControlButton",self.rootItems.sx_upButton)
    end

    local needLevel = 0
    if gamedata.config.equip_star[tostring(self.data.level3 + 1)] and gamedata.config.equip_star[tostring(self.data.level3 + 1)].num and gamedata.config.equip_star[tostring(self.data.level3 + 1)].num > 0 then
        needLevel = gamedata.config.equip_star[tostring(self.data.level3 + 1)].num
        self.rootItems.sx_limitText2:setVisible(true)
        self.rootItems.sx_limitLabel2:setVisible(true)
        ui.setLabelString(self.rootItems.sx_limitLabel2,needLevel,self.data.level1 >= needLevel and 26 or 27,34)
    else
        self.rootItems.sx_limitText2:setVisible(false)
        self.rootItems.sx_limitLabel2:setVisible(false)
    end

     -- 下一级星级属性
    local nextdata = {cid=self.data.cid,level1=self.data.level1,quality=self.data.quality,level3=(self.data.level3+1)}
    local percntnum2,type2,num2 = ui.setEquipStarUpStatistics(nextdata)

    ui.setLabelString(self.rootItems.sx_nextpropertyLabel,(percntnum2 or "0%"),22)
    ui.setLabelString(self.rootItems.sx_nextattrText,((type2.."：") or ""),14)
    ui.setLabelString(self.rootItems.sx_nextattrLabel,num2,22)
   
    -- 获取消耗物品的数据
    local equipstarconfig = gamedata.config.equip_star or {}
    local spenddata = equipstarconfig[tostring(self.data.level3+1)]["cost_"..self.data.quality] or {}
    local spendtemp = {}
    local spendcoinnum = 0
    for k,v in pairs(gamedata.getIDandNUMs(spenddata)) do
        table.insert(spendtemp,v.cid)
        if v.cid == 1000 then
            spendcoinnum = v.num
        end
    end
    
    UIRequest({type = 12001, order = 14003, cids = spendtemp})

    ui.setLabelString(self.rootItems.needcoinLabel,(spendcoinnum or 0),13)

end


-- 升星 星级展示
function equipUp.setStarShow(self, id, data)
    print("  equipUp.setStarShow  ")

    if data and data.level3 and data.level3 > 0 then
    else
        for i=1,5 do
            setSpriteFrameByName(self.equippos[id].item["star"..i], "alpha")
        end
        return
    end

    print("  self.data.level3  ",data.level3)
    local starnum = math.mod(data.level3,5) 

    print("starnum==",starnum)
    if starnum == 0 then
        starnum = 5
    end
    local numtemp = math.floor(data.level3/5)
    local frontpic = "shengxing_"..numtemp
    local starconfig = gamedata.config.equip_star
    for i=1,5 do
        if i <= starnum then
            setSpriteFrameByName(self.equippos[id].item["star"..i], starconfig[tostring(data.level3)]["icon"] or "alpha")
        else
            setSpriteFrameByName(self.equippos[id].item["star"..i], frontpic or "alpha")
        end
    end
end

-- 升星消耗物品数据
function equipUp.setSpendPropsData(self,data)
    print("spendPropsData")
    printT(data)
    self.spendPropsData = {}
    self.spendPropsData = data

    local equipstarconfig = gamedata.config.equip_star or {}
    local spenddata = ""
    if equipstarconfig[tostring(self.data.level3 + 1)] then
        spenddata = equipstarconfig[tostring(self.data.level3 + 1)]["cost_"..self.data.quality]
    end
    local spengtemp = {}
    if spenddata ~= "" then
        spengtemp = gamedata.getIDandNUMs(spenddata)
    end
    local spendcoin = 0
    for i,v in ipairs(spengtemp) do
        if v.cid == 1000 then
            spendcoin = v.num
        end
    end
    if (self.spendPropsData[tostring(1000)] or 0) < spendcoin then
        ui.setLabelString(self.rootItems["needcoinLabel"], nil,24)
    else
        ui.setLabelString(self.rootItems["needcoinLabel"], nil,14)
    end

    self:setNeedItems()
end

function equipUp.setStageUpSpendPropsData(self,data)
    print("jj_spendpropsdata")
    printT(data)
    self.jj_spendpropsdata = {}
    self.jj_spendpropsdata = data

    local spengtemp = self:getSpendPropsNum(true)

    local spendcoinnum = 0
    for i,v in ipairs(spengtemp) do
        print("cid==",v.cid,v.num)
        if v.cid == 1000 then
            spendcoinnum = v.num
            break
        end
    end

    if (self.jj_spendpropsdata[tostring(1000)] or 0) < spendcoinnum then
        ui.setLabelString(self.rootItems.jj_needcoinLabel,spendcoinnum,24)
    else
        ui.setLabelString(self.rootItems.jj_needcoinLabel,spendcoinnum,13)
    end

    self:setStageUpNeedItems()
end

-- 设置进阶消耗物品
function equipUp.setStageUpNeedItems(self)
    local spengtemp = self:getSpendPropsNum(true,true)
    printT(spengtemp,"spengtemp===setStageUpNeedItems")

    for i=1,5 do
        if spengtemp and next(spengtemp) and (i) <= #spengtemp then
            
            self:setjjHasItems(spengtemp[tonumber(i)],i,true)
            self.rootItems["jj_needprop"..(i)]:setVisible(true)
        else
            self.rootItems["jj_needprop"..(i)]:setVisible(false)
        end
    end
end


-- 注灵消耗物品数据
function equipUp.setCSpendPropsData(self,data)
    print("castSpendPropsData")
    printT(data)

    ui.setLabelString(self.rootItems["zhulinlimitnum"],data["20669"],14)
    self.castProps = data or {}
    if self.data then
        local upconfig = gamedata.config.equip_forgingConsume[tostring(self.data.level4 + 1)]
        if not upconfig then
            return
        end
    end
    self:get10Count()
end

-- 设置升星消耗物品
function equipUp.setNeedItems(self)

    local equipstarconfig = gamedata.config.equip_star
    local spendtemp = {}
    -- printT(equipstarconfig)
    -- printT(self.data,"data====")
    -- printT(equipstarconfig[tostring(self.data.level3+1)],"config===")
    -- print("spend===",equipstarconfig[tostring(self.data.level3+1)]["cost_"..self.data.quality])
    local spenddata = ""
    if equipstarconfig[tostring(self.data.level3 + 1)] then
        spenddata = equipstarconfig[tostring(self.data.level3 + 1)]["cost_"..self.data.quality]
    end
    local getData = {}
    if spenddata ~= "" then
        getData = gamedata.getIDandNUMs(spenddata)
    end
    for k,v in pairs(getData) do
        if v.cid ~= 1000 then
            table.insert(spendtemp,v)
        end
    end

    for i=1,4 do
        if spendtemp and next(spendtemp) and i <= #spendtemp then
            print("setHasItems",i)
            self:setHasItems(spendtemp[tonumber(i)],i,self.spendPropsData)
            self.rootItems["needprop"..(i)]:setVisible(true)
        else
            self.rootItems["needprop"..(i)]:setVisible(false)
        end
    end
end

-- 升星消耗物品显示
function equipUp.setHasItems(self,data,num,spendPropsData)
    print("setHasItems===num",num)
    printT(data)
    local key_Ex
    if num == nil or num == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(num-1)
    end

    self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(data.cid)
        print("setHasItems...button",num)
    end, CCControlEventTouchUpInside)
    

    ui.setNewIcon(self.rootItems,{cid=data.cid,num=((spendPropsData[tostring(data.cid)] or 0).."/"..data.num)},num-1)
    if (spendPropsData[tostring(data.cid)] or 0) >= data.num then
        ui.setLabelString(self.rootItems["i_num"..key_Ex],nil,13)
    else
        ui.setLabelString(self.rootItems["i_num"..key_Ex],nil,24)
    end
end

function equipUp.setXilianNum(self,data)
    self.xiliansStoneNum = data["20222"] or 0
    self.rootItems["xl_stone_has"]:setString(self.xiliansStoneNum or 0)
    ui.setLabelString(self.rootItems["xl_stone_has"],nil,18)
end

function equipUp.setXilianPreview(self,data)
    if not data then return end
    self.hasXLPreview = true
    local hasup = false
    local hasdown = false
    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    for i = 1,4 do
        self.rootItems["xl_up_max"..i]:setVisible(false)
        self.rootItems["xl_up_node"..i]:setVisible(false)
        self.rootItems["xl_down_node"..i]:setVisible(false)
        if equipConfig["baptize_attr"..i] and equipConfig["baptize_attr"..i] ~= "" then

            if self.data["x"..equipConfig["baptize_attr"..i]] < data["x"..equipConfig["baptize_attr"..i]] then
                hasup = true
                self.rootItems["xl_up_node"..i]:setVisible(true)
                self.rootItems["xl_up_num"..i]:setString("+"..(data["x"..equipConfig["baptize_attr"..i]]-self.data["x"..equipConfig["baptize_attr"..i]]))
                ui.setLabelString(self.rootItems["xl_up_num"..i],nil,22)
            elseif self.data["x"..equipConfig["baptize_attr"..i]] > data["x"..equipConfig["baptize_attr"..i]] then
                hasdown = true
                self.rootItems["xl_down_node"..i]:setVisible(true)
                self.rootItems["xl_down_num"..i]:setString("-"..(self.data["x"..equipConfig["baptize_attr"..i]]-data["x"..equipConfig["baptize_attr"..i]]))
                ui.setLabelString(self.rootItems["xl_down_num"..i],nil,24)
            elseif self["xl_max"..i] then
                self.rootItems["xl_up_max"..i]:setVisible(true)
                ui.setLabelString(self.rootItems["xl_up_max"..i],nil,22)
            end
            --
            self.rootItems["xl_type_node"..i]:setVisible(true)
        else
            self.rootItems["xl_type_node"..i]:setVisible(false)
        end
    end

    self.rootItems.xl_Node_no:setVisible(true)
    self.rootItems.xl_Node_yes:setVisible(true)
    self.rootItems.xl_Node1:setVisible(self.xlselectbtn == 1)
    self.rootItems.xl_Node2:setVisible(self.xlselectbtn == 2)
    self.rootItems.xl_Node3:setVisible(self.xlselectbtn == 3)
    self.rootItems["xl_Node"..self.xlselectbtn]:setPositionX(0)

    UIRequest({type = 12001, order = 11004, cids = {20222}})
    --
    if not hasup then
        self.rootItems.xl_Button_yes:setEnabled(false)
        ui.addGray("CCControlButton",self.rootItems.xl_Button_yes)
        ui.addGray("CCLabelTTF",self.rootItems.xl_Lab_yes)
    else
        self.rootItems.xl_Button_yes:setEnabled(true)
        ui.removeGray("CCControlButton",self.rootItems.xl_Button_yes)
        ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab_yes)
    end

    if not hasdown then
        self.rootItems.xl_Button_no:setEnabled(false)
        self.rootItems["xl_Button"..self.xlselectbtn]:setEnabled(false)
        ui.addGray("CCControlButton",self.rootItems.xl_Button_no)
        ui.addGray("CCLabelTTF",self.rootItems.xl_Lab_no)
        ui.addGray("CCControlButton",self.rootItems["xl_Button"..self.xlselectbtn])
        ui.addGray("CCLabelTTF",self.rootItems["xl_Lab"..self.xlselectbtn])
    else
        self.rootItems.xl_Button_no:setEnabled(true)
        self.rootItems["xl_Button"..self.xlselectbtn]:setEnabled(true)
        ui.removeGray("CCControlButton",self.rootItems.xl_Button_no)
        ui.removeGray("CCLabelTTF",self.rootItems.xl_Lab_no)
        ui.removeGray("CCControlButton",self.rootItems["xl_Button"..self.xlselectbtn])
        ui.removeGray("CCLabelTTF",self.rootItems["xl_Lab"..self.xlselectbtn])
    end
end

--固定字符串处理
function equipUp.initFixedString( self )

    self.rootItems.sx_basic_attr:setString(gameConfig.strings:string_common("equipUp",8))
    self.rootItems.sx_nowleveltext:setString(gameConfig.strings:string_common("equipUp",9))
    self.rootItems.sx_nextleveltext:setString(gameConfig.strings:string_common("equipUp",10))
    self.rootItems.sx_needgoods:setString(gameConfig.strings:string_common("equipUp",11))
    ui.setLabelString(self.rootItems.sx_limitText,gameConfig.strings:string_common("equipUp",12),14)
    ui.setLabelString(self.rootItems.sx_limitText2,gameConfig.strings:string_common("equipUp",25),14)
    ui.setLabelString(self.rootItems.up_lab2,"消耗银币：",14)
    ui.setLabelString(self.rootItems.fixed4,"花费：",14)
    ui.setLabelString(self.rootItems.fixed5,"花费：",14)
    ui.setLabelString(self.rootItems.fixed6,"花费：",14)
    ui.setLabelString(self.rootItems.fixed7,"花费：",14)
    ui.setLabelString(self.rootItems.fixed8,"花费：",14)
    ui.setLabelString(self.rootItems.fixed9,"花费：",14)
    ui.setLabelString(self.rootItems["xilianlab2"],"剩余：",14)
    ui.setLabelString(self.rootItems["zhulindefLab"],"防御",14)
    ui.setLabelString(self.rootItems["zhulinatkLab"],"攻击",14)
    ui.setLabelString(self.rootItems["zhulinhpLab"],"生命",14)
    ui.setLabelString(self.rootItems["zhulinLvLab"],"灵气等级",14)
    self.rootItems["zhulinDesLab"]:setString("所有装备每注灵5级，灵气等级提升1级")
    ui.setLabelString(self.rootItems["zhulinLimitLab"],"剩余：",14)
    ui.setLabelString(self.rootItems.sx_upLab,"升 星",19)
    ui.setLabelString(self.rootItems.jj_upLab,"进 阶",19)
    self.rootItems.xilianNoneLab:setString("无")
    ui.setLabelString(self.rootItems["jjcostcoinLab"],"消耗银币：",13)
    ui.setLabelString(self.rootItems.needcoinText, gameConfig.strings:string_common("equipUp",7),13)

end


--显示进阶页面
function equipUp.setPage_jinjie(self)
    print("显示进阶页面")
    printT(self.data);

    self:setEquipIcons()

    if self.data and self.data.cid and self.data.cid > 0 then
        self.rootItems.jinjieNode:setVisible(true)
        --self.rootItems.jj_minDescText:setVisible(false)
    else
        self.rootItems.jinjieNode:setVisible(false)
        --self.rootItems.jj_minDescText:setVisible(true)
        runGamePrompt({msg= "请穿戴装备"})
        return
    end

    --
    if self.data and self.data.cid and gamedata.config.equip[tostring(self.data.cid)] and gamedata.config.equip[tostring(self.data.cid)].evolve and gamedata.config.equip[tostring(self.data.cid)].evolve > 0 then
        self.rootItems.stagePromptLabel:setVisible(true)
        --self.rootItems.jinjieNode:setVisible(true)
        --self.rootItems.jj_node1:setVisible(true)
        self.rootItems.jj_node2:setVisible(true)
        self.rootItems.jj_node3:setVisible(true)
        self.rootItems.jj_btnNode:setVisible(true)
        self.rootItems.jjcostcoinNode:setVisible(true)
        self.rootItems.jj_maxDescText:setVisible(false)
        self.rootItems.jj_minDescText:setVisible(false)
        ui.removeGray("CCControlButton",self.rootItems.stageUpBtn)
        ui.removeGray("CCLabelTTF",self.rootItems.jj_upLab)
    else
        self.rootItems.stagePromptLabel:setVisible(false)
        --self.rootItems.jj_node1:setVisible(false)
        --self.rootItems.jinjieNode:setVisible(false)
        -- self.rootItems.jj_node2:setVisible(false)
        -- self.rootItems.jj_node3:setVisible(false)

        self.rootItems.nowpropertyLabel:setVisible(false)
        self.rootItems.nextpropertyAdd:setVisible(false)
        self.rootItems.nextpropertynode_jinjie:setVisible(false)
        self.rootItems.jj_btnNode:setVisible(true)
        self.rootItems.jjcostcoinNode:setVisible(false)
        self.rootItems.jj_maxDescText:setVisible(false)
        self.rootItems.jj_minDescText:setVisible(true)
        self.rootItems.jj_maxDescLab1:setVisible(true)
        self.rootItems.jj_propnode:setVisible(false)

        ui.addGray("CCControlButton",self.rootItems.stageUpBtn)
        ui.addGray("CCLabelTTF",self.rootItems.jj_upLab)
        --
        self.rootItems.stageUpBtn:addHandleOfControlEvent(function()
            runGamePrompt({msg = "橙色以上装备才可进阶"})
            --runGamePrompt({msg = gameConfig.strings:string_common("equipUp",18)})
        end, CCControlEventTouchUpInside)
        self.rootItems.stageUpBtn:setSwallowsTouch(true)
        self.rootItems.stageUpBtn:setTouchPriority(self.touchPriority)
        --
        if self.data and self.data.cid then
            --runGamePrompt({msg = gameConfig.strings:string_common("equipUp",19)})
            runGamePrompt({msg = "橙色以上装备才可进阶"})
        end
        return
    end

    self.rootItems.jj_maxDescLab1:setVisible(false)
    self.rootItems.nowpropertyLabel:setVisible(true)
    self.rootItems.nextpropertyAdd:setVisible(true)
    self.rootItems.nextpropertynode_jinjie:setVisible(true)
    --
    self.rootItems.stageUpBtn:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        print("装备进阶")
        printT(self.data)
        local spengtemp = {}
        if self.data and self.data.cid  then
            local limitnum = table.getTableLength(gamedata.config.equip_evolvesuffix)
            local stageLevel = self.data.level2+1
            local cidnum = self.data.cid
            local equipconfig = gamedata.config.equip[tostring(cidnum)]
            local equip_evolve = gamedata.config.equip_evolve[tostring(cidnum)]
            if equipconfig.quality < 6 then
                limitnum = 30
            end

            if self.data.level2 >= limitnum then
                if (equip_evolve.evolve ~= nil and equip_evolve.evolve ~= 0 and equip_evolve.evolve ~= "") then
                    equipconfig = gamedata.config.equip[tostring(equip_evolve["evolve"])]
                    stageLevel = 1
                    cidnum = tostring(equip_evolve["evolve"])
                else
                    stageLevel = self.data.level2
                end
            end

            -- 升红的等级限制提示
            if equipconfig.quality == 6 then
                local stagePrompsconfig = gamedata.config.equip_evolvesuffix[tostring(stageLevel)]
                -- -- 装备达到0星，且强化等级不小于0级，才可继续进阶
                if self.data.level3 < stagePrompsconfig.star_lv then
                    -- runGamePrompt({msg = "装备星级等级需要达到"..stagePrompsconfig.star_lv.."级,才可进阶"})
                    runGamePrompt({msg = gameConfig.strings:string_common("equipstage",6)..stagePrompsconfig.star_lv..gameConfig.strings:string_common("equipstage",7)})
                    return
                end
                if self.data.level1 < stagePrompsconfig.intentify_lv then
                    -- runGamePrompt({msg = "装备强化等级需要达到"..stagePrompsconfig.intentify_lv.."级,才可进阶"})
                    runGamePrompt({msg = gameConfig.strings:string_common("equipstage",8)..stagePrompsconfig.intentify_lv..gameConfig.strings:string_common("equipstage",7)})
                    return
                end
            end

            -- 升金的等级限制提示
            if equipconfig.quality == 7 then
                local stagePrompsconfig = gamedata.config.equip_evolvesuffix[tostring(stageLevel)]
                if self.data.level3 < stagePrompsconfig.star1_lv then
                    -- runGamePrompt({msg = "装备星级等级需要达到"..stagePrompsconfig.star_lv.."级,才可进阶"})
                    runGamePrompt({msg = gameConfig.strings:string_common("equipstage",6)..stagePrompsconfig.star1_lv..gameConfig.strings:string_common("equipstage",7)})
                    return
                end

                if self.data.level1 < stagePrompsconfig.intentify1_lv then
                    -- runGamePrompt({msg = "装备强化等级需要达到"..stagePrompsconfig.intentify_lv.."级,才可进阶"})
                    runGamePrompt({msg = gameConfig.strings:string_common("equipstage",8)..stagePrompsconfig.intentify1_lv..gameConfig.strings:string_common("equipstage",7)})
                    return
                end

                -- 28件装备进阶条件
                if self.slotequips then
                    local num = 0
                    for k,v in pairs(self.slotequips) do
                        if v.equips.weapon then
                            local weaponlevel2 = self:getSlotEquipsLevel2(v.equips.weapon.quality,v.equips.weapon.level2)
                            if weaponlevel2 < stagePrompsconfig.evolve_lv then
                                num = num + 1
                            end
                        else
                            num = num + 1
                        end
                        if v.equips.accessory then
                            local accessorylevel2 = self:getSlotEquipsLevel2(v.equips.accessory.quality,v.equips.accessory.level2)
                            if accessorylevel2 < stagePrompsconfig.evolve_lv then
                                num = num + 1
                            end
                        else
                            num = num + 1
                        end
                        if v.equips.armor then
                            local armorlevel2 = self:getSlotEquipsLevel2(v.equips.armor.quality,v.equips.armor.level2)
                            if armorlevel2 < stagePrompsconfig.evolve_lv then
                                num = num + 1
                            end
                        else
                            num = num + 1
                        end
                        if v.equips.head then
                            local headlevel2 = self:getSlotEquipsLevel2(v.equips.head.quality,v.equips.head.level2)
                            if headlevel2 < stagePrompsconfig.evolve_lv then
                                num = num + 1
                            end
                        else
                            num = num + 1
                        end
                    end
                    if num > 0 then
                        local evolveName = self:getEvolvesuffix(stagePrompsconfig.evolve_lv)
                        runGamePrompt({msg = "穿戴的"..(stagePrompsconfig.num or 0).."件装备都进阶到"..evolveName.."，才可进阶"})
                        return
                    end
                else
                    --请穿戴装备
                end
            end

            local spengtemp = self:getSpendPropsNum(true)
            for i,v in ipairs(spengtemp) do
                if v.cid == 1000 then
                    if (self.jj_spendpropsdata[tostring(v.cid)] or 0) < v.num then
                        shortCoin()
                        return
                    end  
                    --runGamePrompt({msg = "银币不足"})
                elseif ((self.jj_spendpropsdata[tostring(v.cid)] or 0) < v.num) then
                    -- runGamePrompt({msg = "进阶材料不足"})
                    runGamePrompt({msg = gameConfig.strings:string_common("equipstage",3)})
                    return
                end
            end

            if  spengtemp == nil or (not next(spengtemp)) then
                -- runGamePrompt({msg = "装备已达到最高阶"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipstage",4)})
            else
                local limilvconfig = gamedata.config.equip_evolvelv
                local evolveconfig = gamedata.config.equip_evolve[tostring(self.data["cid"])]
                if (evolveconfig.evolve == nil or evolveconfig.evolve == 0) and not limilvconfig[tostring(self.data["level2"]+1)] then
                    runGamePrompt({msg = gameConfig.strings:string_common("equipstage",4)})
                    return
                elseif limilvconfig[tostring(self.data["level2"]+1)] and limilvconfig[tostring(self.data["level2"]+1)]["lv"..self.data["quality"]] > GameScene.roleinfo.level then
                    -- local lvstring = "进化到下一阶级，需要战队等级达到"..GameScene.roleinfo.level.."级"
                    local lvstring = gameConfig.strings:string_common("equipstage",1)..limilvconfig[tostring(self.data["level2"]+1)]["lv"..self.data["quality"]]..gameConfig.strings:string_common("equipstage",2)
                    runGamePrompt({msg = lvstring})
                    
                    return
                end
                UIRequest({type = 1122,iid = self.data["iid"],props = spengtemp})
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.stageUpBtn:setSwallowsTouch(true)
    self.rootItems.stageUpBtn:setTouchPriority(self.touchPriority)

    self:setStageUpItems()
    self:setStageUpNeedItems()

    --
    local spengtemp = self:getSpendPropsNum()
    UIRequest({type = 12001, order = 14002, cids = spengtemp})
end

--获取进阶等级
function equipUp.getSlotEquipsLevel2(self,quality,level)
    local level2 = 0
    if quality and level then
        if quality <= 6 then
            level2 = level
        elseif quality == 7 then
            level2 = 50 + level
        end
    end
    return level2
end

function equipUp.setProperty(self,level,cid,trrtype)

    -- self.rootItems.container1:removeAllChildrenWithCleanup(true);
    -- self.rootItems.container1:setContentSize(CCSize(460,400))
    -- self.rootItems.scrollnode1 = tolua.cast(self.rootItems.scrollnode1, "CCScrollView")
    -- self.rootItems.scrollnode1:setTouchPriority(self.touchPriority-3)
    -- self.leftNode, self.leftItems = CCBReaderLoad("equip_new/cell_equipjinjie", nil, true, "equipjinjie")
    -- self.leftNode:setPosition(230,0)
    -- self.rootItems.container1:addChild(self.leftNode)
    --self.rootItems.scrollnode1:setContentOffset(ccp(0,-200))

    -- print("level,cid,type",level,cid,type)
    -- print(" ------- left -------");
    -- printT(self.leftItems);
    -- local propertyString = gameConfig.strings:string_common("attr_type",equip_evolve["attr"]).."＋"..equip_evolve["init"..level] or {}
    -- ui.setLabelString(self.leftItems[type.."propertyLabel"],propertyString,14)
    -- for i=1,8 do
    --     if self.leftItems[type.."propertyAdd"..i] then
    --         if equip_evolve["trigger_attr"..i] and equip_evolve["trigger_attr"..i] ~= "" then
    --             local attrtemp = equip_evolve["trigger_attr"..i]
    --             local attr,num = gamedata.getAttrData(attrtemp)
    --             print("attr,num==",attr,num)
    --             local strings = gameConfig.strings:string_common("attr_type",attr)
    --             -- print("string2,desc==",strings,equip_evolve["desc"..i])
    --             strings = strings..num.."%("..equip_evolve["desc"..i]..")"

    --             local labelnum = 29
    --             if level >= tonumber(equip_evolve["trigger"..i]) then
    --                 labelnum = 14
    --             end
    --             ui.setLabelString(self.leftItems[type.."propertyAdd"..i],strings,labelnum)
    --         else
    --             ui.setLabelString(self.leftItems[type.."propertyAdd"..i],"",29)
    --         end
    --     end
    -- end
   
    local equip_evolve = gamedata.config.equip_evolve[tostring(cid)]
    local propertyString = gameConfig.strings:string_common("attr_type",equip_evolve["attr"]).."＋"..equip_evolve["init"..level] or {}
    ui.setLabelString(self.rootItems[trrtype.."propertyLabel"],propertyString,14)


end

function equipUp.setStageUpItems(self)
    print("setStageUpItems...")

    self.rootItems.stagePromptLabel:setVisible(false)
    if self.data and self.data.cid then
        --self.rootItems.jj_node1:setVisible(true)
        self.rootItems.jj_node2:setVisible(true)
        self.rootItems.jj_node3:setVisible(true)

        -- 进阶前设置
        local cidnum = self.data["cid"]
        local equipconfig = gamedata.config.equip[tostring(cidnum)]
        local nowNameString = equipconfig.name
        local stageLevel = self.data.level2
        local stageNameConfig = gamedata.config.equip_evolvesuffix
        if stageLevel ~= 0 then
            
        end

        local equip_evolve = gamedata.config.equip_evolve[tostring(cidnum)]
        ui.setLabelString(self.rootItems["nextpropertyAdd"],"",28)
        for i=1,13 do
             if equip_evolve["trigger_attr"..i] and equip_evolve["trigger_attr"..i] ~= "" then
                if stageLevel < tonumber(equip_evolve["trigger"..i]) then
                    local attrtemp = equip_evolve["trigger_attr"..i]
                    local attr,num = gamedata.getAttrData(attrtemp)
                    local strings = gameConfig.strings:string_common("attr_type",attr)
                    strings = strings..num.."%("..equip_evolve["desc"..i]..")"
                    ui.setLabelString(self.rootItems["nextpropertyAdd"],strings,28)
                    break
                end
            end   
        end

        -- 进阶前属性
        self:setProperty(stageLevel,cidnum,"now")

        -- 进阶后的icon设置
        local equip_evolve = gamedata.config.equip_evolve[tostring(cidnum)]
        local limitnum = table.getTableLength(gamedata.config.equip_evolvesuffix)
        --limitnum = equip_evolve.level or limitnum
        if equipconfig.quality < 6 then
            limitnum = 30
        end

        local stageLevel = self.data.level2+1

        local stagequality = 0
        if stageLevel >= limitnum then
            if (equip_evolve.evolve ~= nil and equip_evolve.evolve ~= 0 and equip_evolve.evolve ~= "") then
                stagequality = 1
            end
        end
        if self.data.level2 >= limitnum then
            print("changelevel2===",self.data.level2,limitnum,equip_evolve.evolve)
            if (equip_evolve.evolve ~= nil and equip_evolve.evolve ~= 0 and equip_evolve.evolve ~= "") then
                equipconfig = gamedata.config.equip[tostring(equip_evolve["evolve"])]
                stageLevel = 1
                cidnum = tostring(equip_evolve["evolve"])
            else
                stageLevel = self.data.level2
            end
        end
        printT(equipconfig,"equipconfig===")
        local nextNameString = equipconfig.name
        local stageNameConfig = gamedata.config.equip_evolvesuffix

        -- 升红的等级限制提示
        if equipconfig.quality == 6 then
            self.rootItems.stagePromptLabel:setVisible(true)
            local stagePrompsconfig = stageNameConfig[tostring(stageLevel)]
            -- 装备达到0星，且强化等级不小于0级，才可继续进阶
            -- local stagePrompstring = "装备达到"..(stagePrompsconfig.star_lv or 0).."星，且强化等级不小于"..(stagePrompsconfig.intentify_lv or 0).."级，才可继续进阶"
            local stagePrompstring = gameConfig.strings:string_common("equipstage",9)..(stagePrompsconfig.star_lv or 0)..gameConfig.strings:string_common("equipstage",10)..(stagePrompsconfig.intentify_lv or 0)..gameConfig.strings:string_common("equipstage",11)
            ui.setLabelString(self.rootItems.stagePromptLabel,stagePrompstring,12)
        -- 升金的等级限制提示
        elseif equipconfig.quality == 7 then
            self.rootItems.stagePromptLabel:setVisible(true)
            local stagePrompsconfig = stageNameConfig[tostring(stageLevel)]
            local evolveName = self:getEvolvesuffix(stagePrompsconfig.evolve_lv)
            local stagePrompstring = "装备升到"..(stagePrompsconfig.star1_lv or 0).."星，且强化等级不小于"..(stagePrompsconfig.intentify1_lv or 0).."级，".."且穿戴的"..(stagePrompsconfig.num or 0).."件装备都进阶到"..evolveName.."，可继续进阶"
            ui.setLabelString(self.rootItems.stagePromptLabel,stagePrompstring,12)
        end

        -------------------------------Max判断设置-------------------------------
        print(" ----- ----- - --max- ---------------")
        printT(equip_evolve)
        printT(self.data)
        if (equip_evolve.evolve == 0 and equip_evolve.level <= self.data.level2) then
            self.rootItems.jj_maxDescText:setVisible(true)
            -- self.rootItems.jj_node2:setVisible(false)
            -- self.rootItems.jj_node3:setVisible(false)

            ui.setLabelString(self.rootItems.jj_needcoinLabel,"0",13)
            ui.addGray("CCControlButton",self.rootItems.stageUpBtn)
            self.rootItems.jjcostcoinNode:setVisible(false)
            -- self.rootItems.jj_btnNode:setVisible(false)

            self.rootItems.nowpropertyLabel:setAnchorPoint(ccp(0.5,0.5))
            self.rootItems.nowpropertyLabel:setPositionX(0)
            self.rootItems.nextpropertynode_jinjie:setVisible(false)
            self.rootItems.jj_propnode:setVisible(false)
            return
        else
            self.rootItems.nowpropertyLabel:setAnchorPoint(ccp(1,0.5))
            self.rootItems.nowpropertyLabel:setPositionX(-80)
            self.rootItems.nextpropertynode_jinjie:setVisible(true)
            self.rootItems.jj_propnode:setVisible(true)
        end

        

        self.rootItems.jj_maxDescText:setVisible(false)
        ui.removeGray("CCControlButton",self.rootItems.stageUpBtn)
        self.rootItems.jjcostcoinNode:setVisible(true)
        self.rootItems.jj_btnNode:setVisible(true)

        --self.rootItems.stageUpBtn:setVisible(true)
        -------------------------------Max判断设置-------------------------------
        local equipQuality = 0
        if stagequality == 1 then
            equipQuality = equipconfig.quality + 1
        else
            equipQuality = equipconfig.quality
        end
        self:setProperty(stageLevel,cidnum,"next")
    end
end

--获取装备进阶后缀
function equipUp.getEvolvesuffix(self,level)
    local stageNameConfig = gamedata.config.equip_evolvesuffix
    local name = "" 
    if level > 50 then
        name = stageNameConfig[tostring(level-50)].suffix7
    else
        name = stageNameConfig[tostring(level)].suffix6
    end
    return name
end

-- 有物品时设置
function equipUp.setjjHasItems(self,data,num,stutas)
    print("setjjHasItems===num",num)

    if stutas then
        
        local index = 4 + num - 1
        local key_ex
        if index == nil or index == 0 then
            key_ex = ""
        else
            key_ex = "_"..index
        end
        -- if data.cid == 1000 then
        --     ui.setNewIcon(self.rootItems,{cid=data.cid,num=data.num},num-1)
        -- else
        ui.setNewIcon(self.rootItems,{cid=data.cid,num=((self.jj_spendpropsdata and self.jj_spendpropsdata[tostring(data.cid)] or 0).."/"..data.num)},4 + num-1)
        --end
        
        if (self.jj_spendpropsdata and self.jj_spendpropsdata[tostring(data.cid)] or 0) >= data.num then
            ui.setLabelString(self.rootItems["i_num"..key_ex],nil,13)
        else
            ui.setLabelString(self.rootItems["i_num"..key_ex],nil,27)
        end

        self.rootItems["i_button_"..(num + 3)]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(data.cid)
        end, CCControlEventTouchUpInside)

    else
        -- 装备升星星级展示
        --ui.setNewIcon(self.rootItems,{cid=data.cid,num=("LV:"..data.level1)},num-1,data)
    end
end

-- 获取消耗的cid,status1:有值时获取v，没值时获取cid；status2：有值时获取除开金币的材料v（1000），没值时获取材料v
function equipUp.getSpendPropsNum( self,status1,status2)

    local spengtemp = {}
    if self.data and self.data.cid  then
        -- 判断是否橙色升到红色

        local stageLevel = self.data.level2+1
        local cidnum = self.data.cid

        local equip_evolve = gamedata.config.equip_evolve[tostring(cidnum)]
        local limitnum = table.getTableLength(gamedata.config.equip_evolvesuffix)
            
        if gamedata.config.equip[tostring(cidnum)].quality < 6 then
            limitnum = 30
        end   

        --limitnum = equip_evolve.level or limitnum

        if self.data.level2 >= limitnum then
            if (equip_evolve.evolve ~= nil and equip_evolve.evolve ~= 0 and equip_evolve.evolve ~= "") then
                stageLevel = 1
                cidnum = tostring(equip_evolve["evolve"])
            else
                stageLevel = self.data.level2
            end

        end
        print("stageLevel,cidnum===",stageLevel,cidnum)
        local equipconfig = gamedata.config.equip[tostring(cidnum)]
        local spengconfig = gamedata.config.equip_evolveconsume[tostring(cidnum)]
        printT(spengconfig,"spengconfig===")
        print("spendPropsnum===",equipconfig.quality, equip_evolve.evolve, equipconfig.quality, cidnum, spengconfig["consume"..stageLevel])
        if (equipconfig.quality < 6 and self.data.level2 == limitnum and (equip_evolve.evolve == nil or equip_evolve.evolve == 0 or equip_evolve.evolve == "")) or (spengconfig["consume"..stageLevel] == nil or spengconfig["consume"..stageLevel] == "") then

        else
            if spengconfig["equip"..stageLevel] then
                local temp = spengconfig["equip"..stageLevel]
                for k,v in pairs(gamedata.getIDandNUMs(temp)) do
                    if status1 then
                        if status2 == nil then
                            table.insert(spengtemp,v)
                        --elseif v.cid and  v.cid ~= 0 then
                        elseif v.cid and v.cid> 0 and v.cid ~= 1000 then
                            table.insert(spengtemp,v)
                        end
                    else
                        table.insert(spengtemp,v.cid)
                    end

                end
            end
            for k,v in pairs(gamedata.getIDandNUMs(spengconfig["consume"..stageLevel])) do
                if status1 then
                    if status2 == nil then
                        table.insert(spengtemp,v)
                    --elseif v.cid and  v.cid ~= 0 then
                    elseif v.cid and v.cid> 0 and v.cid ~= 1000 then
                        table.insert(spengtemp,v)
                    end
                else
                    table.insert(spengtemp,v.cid)
                end
            end
        end

    end

    return spengtemp
end

return equipUp
