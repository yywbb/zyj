-- 荣耀之战布阵

local honorBattleArray = {
    resource = nil,
    rootNode = nil,
    rootItems = nil,
    
    generalListTableView = nil,
    titleCellSize = {x=180,y=180},
    buttontouch = -103,
    selectpage = 1,
    cheerPage = {},
    arrayData = nil,
    slotData = nil,
    xiaohuobanListTableView = nil,
    celldict = {},

    desconfig = {"1v1","2v2","4v4"},

    isTouchMove = false,
}

function honorBattleArray.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_buzhen", nil, true, "rongyaozhizhan_buzhen")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topNode:setPositionY(toppos)
    self.rootItems.midNode:setPositionY((GameScene.topposY-1920)*0.5+150)

    self.isCanArray = true

    if param and param.resttime and param.resttime>0 then
        gameTimer:rigistTime("hornorwararray",param.resttime)
        gameTimer:rigistTimeFunc("hornorwararray",function()
            if gameTimer.times["hornorwararray"] <= 0 then
                self.isCanArray = false
                -- runGamePrompt({msg = "布阵时间已过"})
                -- GameScene:shiftLayer(GameScene.priorLayer,"up")
            end
        end)
    end

    self.rootItems.closeButton:setTouchPriority(-103)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        if self.ischanged then
            gameWindows:openWindow("confirm",{msg = "阵容变化未保存，是否放弃？"},function( )
                GameScene:shiftLayer(GameScene.priorLayer,"up")
            end)
        else
            GameScene:shiftLayer(GameScene.priorLayer,"up")
        end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.arraydesc,"拖动头像移动至下列布阵框内可进行布阵",59)
    ui.setLabelString(self.rootItems.powerdesc1,"战力: ",48)
    ui.setLabelString(self.rootItems.powerdesc2,"战力: ",48)
    ui.setLabelString(self.rootItems.powerdesc3,"战力: ",48)
    --保存阵容
    ui.setLabelString(self.rootItems.arrayLab,"保存阵容",18)
    self.rootItems.arrayButton:setTouchPriority(-103)
    self.rootItems.arrayButton:addHandleOfControlEvent(function()
        local request = {}
        local petid = 0
        local nums = {0,0,0}
        --处理列表中的装备上的id
        for i=1,3 do
            for j=1,7 do
                local posid = self:getPosId(i,j)
                if posid >=0 then
                    table.insert(request,posid)
                    if posid>0 then nums[i]=nums[i]+1 end
                end
            end
            --宠物id
            local petid_ = self:getPetId(i)
            if petid_ >=0 then
                petid = petid_
            end
        end
        table.insert(request,petid)

        if nums[1]<=0 or nums[2]<=0 or nums[3]<=0 then
            runGamePrompt({msg = gameConfig.strings:string_common("honorBattle2",40)})
            return
        --判断魔宠是否上阵
        elseif petid<= 0 and next(self.petdata) then
            gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("honorBattle2",41)},function( )
                UIRequest({type = 6702,request = request})
            end)
            return
        elseif not self.isCanArray then --判断当前是否处于布阵阶段 then
            runGamePrompt({msg = gameConfig.strings:string_common("honorBattle2",38)})
            return
        end
        UIRequest({type = 6702,request = request})
    end, CCControlEventTouchUpInside)

    --小伙伴
    self.rootItems.partnerButton:setTouchPriority(-103)
    self.rootItems.partnerButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("honorBattleCheer")
    end, CCControlEventTouchUpInside)


    --触摸的处理
    local touchedGeneral = nil
    local touchX, touchY = 0,0
    local  isEquip = false
    local function ccTouchBegan(x, y)
        touchX, touchY = x, y
        self.isTouchMove = false
        if ui.isTouched(self.rootItems.touchlayer,x,y) then
            --点击的是布阵的区域
            if ui.isTouched(self.rootItems.midgeneralNode,x,y) then
                for i=1,3 do
                    for j=1,7 do
                        if ui.isTouched(self.rootItems["general"..i.."_"..j],x,y) then
                            local posid = self:getPosId(i,j) 
                            if posid>0 then 
                                isEquip = true
                                touchedGeneral = {slottype = i,pos = j,posid = self:getPosId(i,j)}
                                return true
                            else
                                return false
                            end
                        end
                    end
                end
                --点击的是上边的列表数据
            elseif ui.isTouched(self.rootItems.generalListScroll,x,y) then
                for k,v in pairs(self.celldict) do
                    if ui.isTouched(v.cellCCB,x,y) then
                        local slotdata = self.arrayData[(v.index)]
                        --original
                       --[[ if slotdata and slotdata.general 
                            --TODO  此处改为不管有没有status 都可以拖动 有status的数据给布阵区域的数据
                            and not self.generalStatus[slotdata.general.iid].status then
                            touchedGeneral = {posid = slotdata.general.iid}
                            return true
                        end
                        --]]
                        ----modify
                        if slotdata and slotdata.general then
                            --TODO  此处改为不管有没有status 都可以拖动 有status的数据给布阵区域的数据
                            if not self.generalStatus[slotdata.general.iid].status then
                                touchedGeneral = {posid = slotdata.general.iid}
                                return true
                            else
                                for i=1,3 do
                                    for j=1,7 do   
                                        local posid = self:getPosId(i,j) 
                                        if posid == slotdata.general.iid then
                                            if posid>0 then 
                                                touchedGeneral = {slottype = i,pos = j,posid = self:getPosId(i,j)}
                                                return true
                                            else
                                                return false
                                            end
                                        end
                                        
                                    end
                                end
                                return false
                            end
                        end--

                        ---
                             
                ----------
                    end
                end
            end
        end
        return false
    end

    local function ccTouchMoved(x, y)
        --没有选中的元素
        if not touchedGeneral then return end
        --判断位移距离
        if self.isTouchMove or (math.abs(touchX-x)>50  and isEquip) or math.abs(touchY-y)>50 then
            self.isTouchMove = true
            --显示选中的图标  (加数据后)
            self.rootItems.touchgeneral:setVisible(true)
            -- 设置头像
            local generaldata = self.generalStatus[touchedGeneral.posid].data
            if gamedata:illusionsLimite("k_pvp") then
                if generaldata.illusion and generaldata.illusion.illusionGeneralCid then
                    local configdata = gamedata.config.general[tostring(generaldata.illusion.illusionGeneralCid)]
                    local gdata = ui.getConfigGeneralSion(generaldata)
                    if next(gdata) and configdata.fashion_id == 0 then
                        ui.setNewIcon(self.rootItems, generaldata,0,nil,gdata)
                    else
                        ui.setNewIcon(self.rootItems, generaldata)
                    end
                else
                    local configdata = gamedata.config.general[tostring(generaldata.cid)]
                    local gdata = ui.getConfigGeneral(generaldata)
                    if next(gdata) and configdata.fashion_id == 0 then
                        ui.setNewIcon(self.rootItems, generaldata,0,nil,gdata)
                    else
                        ui.setNewIcon(self.rootItems, generaldata)
                    end
                end
            else
                if generaldata.illusion and generaldata.illusion.illusionGeneralCid then
                    ui.setNewIcon(self.rootItems, generaldata)
                else
                    local configdata = gamedata.config.general[tostring(generaldata.cid)]
                    local gdata = ui.getConfigGeneral(generaldata)
                    if next(gdata) and configdata.fashion_id == 0 then
                        ui.setNewIcon(self.rootItems, generaldata,0,nil,gdata)
                    else
                        ui.setNewIcon(self.rootItems, generaldata)
                    end
                end
            end
            
            self.rootItems.touchgeneral:setPosition((x)/GameScene.scaleNum,(y/GameScene.scaleNum)-(gameConfig.fixH or 0))
            --隐藏掉当前选中的这个
            if touchedGeneral.slottype then
                self.rootItems["general"..touchedGeneral.slottype.."_"..touchedGeneral.pos]:setVisible(false)
            end
            --TODO是否需要设置当前不能放的置灰处理或者显示不能放的字？
        end
    end

    local function ccTouchEnded(x, y)
        if touchedGeneral then
            isEquip = false
            local ischanged = false
            for i=1,3 do
                for j=1,7 do
                    --碰到了下方列表中的某个
                    if ui.isTouched(self.rootItems["general"..i.."_"..j],x,y) then
                        local posid = self:getPosId(i,j) 
                        if posid>=0 then
                            --如果之前拖动的也是下方列表中的某一个（i值是有的）之前的用的现在的
                            if touchedGeneral.slottype then
                                if posid == touchedGeneral.posid then 
                                    self.rootItems["general"..touchedGeneral.slottype.."_"..touchedGeneral.pos]:setVisible(true)
                                else
                                    self:setOneSlot(touchedGeneral.slottype,touchedGeneral.pos,posid)
                                    ischanged = true
                                end

                            else
                                --如果不是的话   是上方拖下来的  但是posid大于等于0说明原来有数据  要更新这个的上方列表选中
                                if  posid ~=0 then
                                    if self.generalStatus[posid].status then
                                        self.generalStatus[posid].status = nil
                                    end
                                end 
                                ischanged = true
                                
                            end
                            --现在的用之前选中的posid数据
                            self:setOneSlot(i,j,touchedGeneral.posid)
                            
                            
                            break
                        end

                    end
                end
            end
            if not ischanged and touchedGeneral.slottype then
                self.rootItems["general"..touchedGeneral.slottype.."_"..touchedGeneral.pos]:setVisible(true)
                self:setOneSlot(touchedGeneral.slottype,touchedGeneral.pos,touchedGeneral.posid)
            end
            --按道理讲  不管是否交换  都要刷新上方的列表 
            if ischanged then
                self:reloadGeneral()
            end
            --设置拖动的对象
            touchedGeneral = nil
            self.rootItems.touchgeneral:setVisible(false)
            self.rootItems.touchgeneral:setPosition(0,0)
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

    local touchPriority = self.buttontouch-1

    self.rootItems.touchlayer:registerScriptTouchHandler(onTouch, false, touchPriority, false)
    self.rootItems.touchlayer:setTouchPriority(touchPriority)
    self.rootItems.touchlayer:setTouchEnabled(true)

    GameScene:checkUpdate(10021)
    UIRequest({type = 6701})
end

function honorBattleArray.ReloadData(self,data)
    self.slotData = data.HonorWarSlot
    self.petdata = data.pets
    self.arrayData = table.copy(GameScene.layers["slotsInfo"].module.slotdata)
    local copyData = {}
    for k,v in pairs(self.arrayData) do
            table.insert(copyData,v)
    end
    self.arrayData = copyData
    self.generalStatus = {}
    for k,v in pairs(self.arrayData) do
        if v.general then
            self.generalStatus[v.general.iid] = {}
            self.generalStatus[v.general.iid].data = v.general
            if v.general then
                if gamedata:illusionsLimite("k_pvp") and v.general.illusionGeneralCid then
                    self.generalStatus[v.general.iid].data.cid = v.general.illusionGeneralCid
                else
                    v.general.illusionGeneralCid = nil
                end
            end
            
        end
    end

    --阵容信息
    self:changeArray()

    self.ischanged = false
end
--排序
function honorBattleArray.ResortArrayData(self)
    local sortfunction_t = function(a,b) 
        a.sortdata = a.general and 1 or -1
        b.sortdata = b.general and 1 or -1
        if a.sortdata>0 and b.sortdata>0 then
        a.sortindex = self.generalStatus[(a.general.iid)] and self.generalStatus[(a.general.iid)].status or 0
        b.sortindex = self.generalStatus[(b.general.iid)] and self.generalStatus[(b.general.iid)].status or 0
        return a.sortindex < b.sortindex
        else
            return a.sortdata >b.sortdata
        end
    end
    table.sort(self.arrayData, sortfunction_t)
end
function honorBattleArray.getPosId( self,i,j )
    local slotdata = self.slotData[tostring(i)]
    return slotdata.pos[tostring(j)] 
end

function honorBattleArray.getPetId( self,i )
    return self.slotData[tostring(i)].pet
end

function honorBattleArray.reloadGeneral(self)
    --伙伴图像显示
    self:ResortArrayData()
    if not self.generalListTableView then
        self:createGeneralList()
    else
        self.generalListTableView:setContentOffsetInDuration(ccp(0,0),0)
        --self:ResortArrayData()
        self.generalListTableView:reloadData()
    end
end
--s设置上方列表数据
function honorBattleArray.setIconList( self,item,data )
    -- 设置头像
    if data.general then
        local generaldata = data.general
        if gamedata:illusionsLimite("k_pvp") then
            if generaldata.illusion and generaldata.illusion.illusionGeneralCid then
                local configdata = gamedata.config.general[tostring(generaldata.illusion.illusionGeneralCid)]
                local gdata = ui.getConfigGeneralSion(generaldata)
                if next(gdata) and configdata.fashion_id == 0 then
                    ui.setSlotGeneralIcon(data,item,0,gdata)
                else
                    ui.setSlotGeneralIcon(data,item)
                end
            else
                local configdata = gamedata.config.general[tostring(generaldata.cid)]
                local gdata = ui.getConfigGeneral(generaldata)
                if next(gdata) and configdata.fashion_id == 0 then
                    ui.setSlotGeneralIcon(data,item,0,gdata)
                else
                    ui.setSlotGeneralIcon(data,item)
                end
            end
        else
            if generaldata.illusion and generaldata.illusion.illusionGeneralCid then
                ui.setSlotGeneralIcon(data,item)
            else
                local configdata = gamedata.config.general[tostring(generaldata.cid)]
                local gdata = ui.getConfigGeneral(generaldata)
                if next(gdata) and configdata.fashion_id == 0 then
                    ui.setSlotGeneralIcon(data,item,0,gdata)
                else
                    ui.setSlotGeneralIcon(data,item)
                end
            end
        end
    end
    
    ui.sethint(item["g_hint"],false)
    if not data.general then
        item.statusnode:setVisible(false)
        return
    end

    local status = self.generalStatus[data.general.iid].status
    if status then
        item.statusnode:setVisible(true)
        item.statuslab:setString(self.desconfig[status])
    else
        item.statusnode:setVisible(false)
    end
end
--设置下方阵容中的图标  和关闭的事件处理
function honorBattleArray.setIconSlot( self,item,data,slottype,pos )
    -- 设置头像
    if gamedata:illusionsLimite("k_pvp") then
        if data.illusion and data.illusion.illusionGeneralCid then
            local configdata = gamedata.config.general[tostring(data.illusion.illusionGeneralCid)]
            local gdata = ui.getConfigGeneralSion(data)
            if next(gdata) and configdata.fashion_id == 0 then
                ui.setNewIcon(item,data,0,nil,gdata)
            else
                ui.setNewIcon(item,data)
            end
        else
            local configdata = gamedata.config.general[tostring(data.cid)]
            local gdata = ui.getConfigGeneral(data)
            if next(gdata) and configdata.fashion_id == 0 then
                ui.setNewIcon(item,data,0,nil,gdata)
            else
                ui.setNewIcon(item,data)
            end
        end
    else
        local configdata = gamedata.config.general[tostring(data.cid)]
        if data.illusion and data.illusion.illusionGeneralCid then
            ui.setNewIcon(item,data)
        else
            local gdata = ui.getConfigGeneral(data)
            if next(gdata) and configdata.fashion_id == 0 then
                ui.setNewIcon(item,data,0,nil,gdata)
            else
                ui.setNewIcon(item,data)
            end
        end
    end
    
    item.i_button:setTouchEnabled(false)
    item.closeButton:setSwallowsTouch(true)
    item.closeButton:setTouchPriority(-105)
    item.closeButton:addHandleOfControlEvent(function()
        self:setOneSlot(slottype,pos,0)
        self:reloadGeneral()
    end, CCControlEventTouchUpInside)
end

function honorBattleArray.setOneSlot( self,i,j,iid )
    local posid = self:getPosId(i,j)   
    local topIid
    if iid then
        if posid == -1 then return end
        if posid>0 and posid == iid then return end
        topIid = self.slotData[tostring(i)].pos[tostring(j)]
        print("=======topID:"..topIid)
        posid = iid
        self.slotData[tostring(i)].pos[tostring(j)] = iid
        self.ischanged = true
    end
    --原来位置的node 显示出来  全部清理掉  重新更数据
    local posnode = self.rootItems["general"..i.."_"..j]
    posnode:setVisible(true)
    posnode:removeAllChildrenWithCleanup(true)

    local posbg = self.rootItems["obz"..i.."_"..j]

    if posid == -1 then
        local suo = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("suo4.png"))
        suo:setPosition(81,81)
        posnode:addChild(suo) 
        setSpriteFrameByName(posbg, "rongyaozhizhan_houpai")
    elseif posid == 0 then
        --print("======="..topIid)
        if topIid and topIid ~=-1 then
            if self.generalStatus[topIid].status then
                self.generalStatus[topIid].status = nil
            end
        end
        local ccb,item = CCBReaderLoad("rongyaozhizhan/generalIconNone.ccbi", nil, true, "generalIcon")
        ccb:setPosition(81,81)
        posnode:addChild(ccb)
        setSpriteFrameByName(posbg, "rongyaozhizhan_qianpai")
    elseif posid >0 then
        self.generalStatus[posid].status = i
        local ccb,item = CCBReaderLoad("rongyaozhizhan/generalIcon.ccbi", nil, true, "generalIcon")
        ccb:setPosition(81,81)
        posnode:addChild(ccb)
        self:setIconSlot(item,self.generalStatus[posid].data,i,j)
    end
    topIid = nil
end

function honorBattleArray.setIconPet( self,item,petid,i )
    item.pet_button:setSwallowsTouch(true)
    item.pet_button:setTouchPriority(-105)
    item.pet_button:addHandleOfControlEvent(function()
        --这个id是怎么来的temiid
        local cb = function( temiid )
            if temiid == petid then
            else
                self:setPet(i,temiid)
            end
        end
        gameWindows:openWindow("singlebosschongwuselect",{pets = self.petdata, iid = petid},cb)
    end, CCControlEventTouchUpInside)

    if petid>0 then
        for k,v in pairs(self.petdata) do
            if v.iid == petid then
                -- 设置头像
                ui.setNewIcon(item,v)
                local config = gamedata.config.pet3_attr[tostring(v.cid)][tostring(v.level)]
                setSpriteFrameByName(item["i_quality"], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
                setSpriteFrameByName(item["i_k_quality"], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
                setSpriteFrameByName(item.i_icon,config.icon)
                ui.setSpriteTextureRect(item.i_icon,0,0,150,150)

                break
            end
        end
    end
end

function honorBattleArray.setPet( self,i,iid )
    local petid = self.slotData[tostring(i)].pet

    if iid then
        if petid == -1 then return end
        if petid>0 and petid == iid then return end
        petid = iid
        self.slotData[tostring(i)].pet = iid    
        self.ischanged = true    
    end

    local petnode = self.rootItems["general"..i.."_pet"]
    petnode:setVisible(true)
    petnode:removeAllChildrenWithCleanup(true)

    local petbg = self.rootItems["obz"..i.."_pet"]
    
    if petid == -1 then
        local suo = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("suo4.png"))
        suo:setPosition(81,81)
        petnode:addChild(suo)
        setSpriteFrameByName(petbg, "rongyaozhizhan_houpai")
    elseif petid >= 0 then
        local ccbname = petid==0 and "petIconNone" or "petIconhas"
        local ccb,item = CCBReaderLoad("rongyaozhizhan/"..ccbname..".ccbi", nil, true, ccbname)
        ccb:setPosition(81,81)
        petnode:addChild(ccb)
        self:setIconPet(item,petid,i)
        setSpriteFrameByName(petbg, "rongyaozhizhan_qianpai")
        --setSpriteFrameByName(item["i_quality"..i], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))

    end
end

function honorBattleArray.changeArray(self)

    for i=1,3 do
        for j=1,7 do
            self:setOneSlot(i,j)
        end
        self:setPet(i)

        local slotdata = self.slotData[tostring(i)]

        ui.setLabelString(self.rootItems["power"..i],slotdata.power,61)

        local bufferconfig = gamedata.config.breakskill[tostring(slotdata.buff)]
        self.rootItems["buffer"..i]:setString(bufferconfig and bufferconfig.desc or "???")
    end
    self:reloadGeneral()
end

function honorBattleArray.createGeneralList(self,alldata)
    self.celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("rongyaozhizhan/generalIconlist.ccbi", nil, true, "generalIcon")
                self.celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler,index = a1+1 }
            else
                first = false
                cellCCB = self.celldict[a2].cellCCB
                ccbDocumentControler = self.celldict[a2].ccbDocumentControler
                self.celldict[a2].index = a1+1
            end
            cellCCB:setScale(0.89)    

            if self.arrayData and self.arrayData[(a1+1)] then
                self:setIconList(ccbDocumentControler,self.arrayData[(a1+1)])
            else
                local slotconfig = gamedata.config.general_slot
                local nextlevel = slotconfig[tostring(a1+1)]
                self:setIconList(ccbDocumentControler,{openlevel = nextlevel})
            end

            cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            -- r = 7
            r = table.getTableLength(self.arrayData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.generalListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.generalListScroll:getContentSize().width,
        viewheight = self.rootItems.generalListScroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.generalListScroll:addChild(self.generalListTableView)
    self.generalListTableView:setTouchPriority(self.buttontouch+1)
end

function honorBattleArray.clear(self)
    gameTimer:UnrigistTimeFunc("hornorwararray")
    self.generalListTableView = nil
    self.celldict = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return honorBattleArray