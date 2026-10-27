--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local safemask = {

    resource = nil,

    titleCellSize = {x=180,y=180},
    generalListTableView = nil,

    rootNode = nil,
    rootItems = nil,

    pageconfig = {"up","stage","feisheng"},
    pagename = {"升 级","进 阶","飞 升"},
    pagebuild = {382,330,462},

    selectpage = "up",

    sid = 1,
    generalindex = 1,
    generalcid = nil,
    slotdata = {},
    safemask = {},
    safemaskmaster = {},
    up_needprops = {},
    evolve_needprops = {},

    minlv = 0,

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title3 = {462},
            },
        },
    },
}

function safemask.shiftPage(self,type)


    self.selectpage = type
    self.rootItems.isjinjie:setVisible(false)
    self.rootItems.upnode:setVisible(false)
    self.rootItems.feishengnode:setVisible(false)
    self.rootItems.up_bg:setVisible(false)
    self.rootItems.feisheng_bg:setVisible(false)

    if self.selectpage == "stage" then
        self.rootItems.isjinjie:setVisible(true)
        self.rootItems.upnode:setVisible(true)
        self:setPage_stage()

        guide.controller:addComplete(330,function()
            self:reloadHint()
            UIRequest({type = 2882,opt=1,sysID=330})
        end)
    elseif self.selectpage == "up" then
        self.rootItems.up_bg:setVisible(true)
        self.rootItems.upnode:setVisible(true)
        self:setPage_up()

        guide.controller:addComplete(209,function()
            UIRequest({type = 2882,opt=1,sysID=209})
        end)
    else
        self.rootItems.feisheng_bg:setVisible(true)
        self.rootItems.feishengnode:setVisible(true)
        self:setPage_feisheng()

        guide.controller:addComplete(462,function()
            self:reloadHint()
            UIRequest({type = 2882,opt=1,sysID=462})
        end)
    end
end


function safemask.init(self,parent,toppos,param)
    printT(param,"param")
    self.rootNode,self.rootItems = CCBReaderLoad("safemask/safemask", nil, true, "safemask")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    if not gameConfig:checkBuildOpen(330)  then
        self.rootItems.buttonnode2:setVisible(false)
        self.rootItems.button2:setTouchEnabled(false)

        self.rootItems.buttonnode3:setPositionX(410)
    else
        self.rootItems.buttonnode2:setVisible(true)
        self.rootItems.button2:setTouchEnabled(true)
    end

    if not gameConfig:checkBuildOpen(462)  then
        self.rootItems.buttonnode3:setVisible(false)
        self.rootItems.button3:setTouchEnabled(false)
    else
        self.rootItems.buttonnode3:setVisible(true)
        self.rootItems.button3:setTouchEnabled(true)
    end

    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer(GameScene.priorLayer,"up",{sid = self.slotdata[tostring(self.generalindex)].sid or 1})
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(-103)
    --

    self.rootItems.achButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("safemaskmaster",self.safemaskmaster)
    end, CCControlEventTouchUpInside)
    self.rootItems.achButton:setSwallowsTouch(true)
    self.rootItems.achButton:setTouchPriority(-103)

    self.rootItems.ruleButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("safemaskRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.ruleButton:setSwallowsTouch(true)
    self.rootItems.ruleButton:setTouchPriority(-103)
    --

    self.rootItems.shopButton:addHandleOfControlEvent(function()

        GameScene:shiftLayerById(210)
    end, CCControlEventTouchUpInside)
    self.rootItems.shopButton:setSwallowsTouch(true)
    self.rootItems.shopButton:setTouchPriority(-103)

    if param and param.sid then
        self.sid = param.sid
    else
        self.sid = 1
    end

    local safeSlotdata = {}
    if param and param.slotdata then
        safeSlotdata = param.slotdata
    else
        safeSlotdata = GameScene.layers["slotsInfo"].module.slotdata
    end

    if safeSlotdata and next(safeSlotdata) then
        local temp = table.copy(safeSlotdata)
        local indexs = {}
        for k,v in pairs(temp) do
            if v.general then
                table.insert(indexs,k)
            end
        end
        local sortfunc = function (a,b)
            return tonumber(a) < tonumber(b)
        end
        table.sort(indexs,sortfunc)
        --
        self.slotdata = {}
        for i = 1, #indexs do
            self.slotdata[tostring(i)] = temp[tostring(indexs[i])]
        end
    end

    if param and param.safemask then
        self.safemask = param.safemask
    else
        self.safemask = GameScene.layers["slotsInfo"].module.safemask
    end

    --
    for k,v in pairs(self.slotdata) do
        if self.sid and v.sid and v.sid == self.sid then
            self.generalindex = tonumber(k)
        end
    end
    --

    self:ReloadData()
    --
    UIRequest({type = 3732})
    --
    self:initFixedString()
end

function safemask.reloadHint(self)
    if guide.controller:isNewSystemByid(462) and GameScene:checkopenlevelbyId(462,true) then
        ui.sethint(self.rootItems.hint_title3,true)
    else
        if GameScene:checkopenlevelbyId(462,true) and GameScene.hintdata[tostring(462)] and GameScene.hintdata[tostring(462)] ~=0 then
            ui.sethint(self.rootItems.hint_title3,true)
        else
            ui.sethint(self.rootItems.hint_title3,false)
        end
    end
end

function safemask.reloadSlotData(self)
    local safeSlotdata = GameScene.layers["slotsInfo"].module.slotdata

    if safeSlotdata and next(safeSlotdata) then
        local temp = table.copy(safeSlotdata)
        local indexs = {}
        for k,v in pairs(temp) do
            if v.general then
                table.insert(indexs,k)
            end
        end
        local sortfunc = function (a,b)
            return tonumber(a) < tonumber(b)
        end
        table.sort(indexs,sortfunc)
        --
        self.slotdata = {}
        for i = 1, #indexs do
            self.slotdata[tostring(i)] = temp[tostring(indexs[i])]
        end

        self.generalListTableView:reloadData()
    end
end

function safemask.clear(self)
    self.minlv = 0
    self.selectpage = "up"
    self.evolve_needprops = {}
    self.up_needprops = {}
    self.sid = 1
    self.generalindex = 1
    self.generalcid = nil
    self.generalListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end



----------------------------------------------------------------------------
function safemask.reloadGeneralList(self,alldata)
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
            if self.slotdata[tostring(a1+1)] and self.slotdata[tostring(a1+1)].general then
                -- 设置头像
                if self.slotdata[tostring(a1+1)].general.illusionGeneralCid == nil then
                    local generalData = self.slotdata[tostring(a1+1)].general
                    local configGeneral = gamedata.config.general[tostring(generalData.cid)]
                    local gdata = ui.getConfigGeneral(generalData)
                    if next(gdata) and configGeneral.fashion_id == 0 then
                        generalData.icon = gdata.icon
                        ui.setNewIcon(ccbDocumentControler,generalData)
                    else
                        ui.setNewIcon(ccbDocumentControler,generalData)
                    end
                else
                    ui.setNewIcon(ccbDocumentControler,self.slotdata[tostring(a1+1)].general)
                end
            end

            ui.sethint(ccbDocumentControler.i_ext,self.slotdata[tostring(a1+1)].hashint_safemaskFeiSheng)
            ccbDocumentControler.i_ext:setPosition(160,160)

            ccbDocumentControler["i_num"]:setVisible(false)
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
            r = table.getTableLength(self.slotdata)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)

            if a1:getIdx()+1<= table.getTableLength(self.slotdata) then
                self:setGeneralIndex(a1:getIdx()+1,true)
            else

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
    self.generalListTableView:setTouchPriority(-102)
    --
    if self.generalindex > 5 then
        self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.generalindex-5) ,0),0.2)
    end
end

----------------------------------------------------------------------------



function safemask.setGeneralIndex(self,index)
    self.generalindex = index
    self.generalcid = self.slotdata[tostring(self.generalindex)].general and self.slotdata[tostring(self.generalindex)].general.cid or nil

    if self.generalListTableView then
        self.generalListTableView:reloadData()
    end
    -- 滑动层设置
    self:touchLayerSet()

    --self:setPage()
    self:shiftPage(self.selectpage)

end


function safemask.ReloadData(self,data)

    if data and data.safemask then
        self.safemask = data.safemask
    end

    self.minlv = self.safemask["1"] and self.safemask["1"].level2 or 0
    for i = 2,7 do
        if self.safemask[tostring(i)] and self.safemask[tostring(i)].level2 then
            if self.safemask[tostring(i)].level2 < self.minlv then
                self.minlv = self.safemask[tostring(i)].level2
            end
        else
            self.minlv = 0
        end
    end

    if not self.generalListTableView then
        self:reloadGeneralList()
    else
        self.generalListTableView:reloadData()
    end

    -- 添加touch层 伙伴左右拖动换位
    self:touchLayerSet()

    --self:setPage()
    self:shiftPage(self.selectpage)


end

-- 添加touch层 伙伴左右拖动换位
function safemask.touchLayerSet(self)

    self.standdata = {{cid=0,index=0},{cid=0,index=0},{cid=0,index=0}}


    if self.slotdata[tostring(self.generalindex-1)] and self.slotdata[tostring(self.generalindex-1)].general then
        self.standdata[1]["cid"] = self.slotdata[tostring(self.generalindex-1)].general.cid or 0
        self.standdata[1]["index"] = self.generalindex-1
    end

    self.standdata[2]["cid"] = self.slotdata[tostring(self.generalindex)].general.cid or 0
    self.standdata[2]["index"] = self.generalindex

    if self.slotdata[tostring(self.generalindex+1)] and self.slotdata[tostring(self.generalindex+1)].general then
        self.standdata[3]["cid"] = self.slotdata[tostring(self.generalindex+1)].general.cid or 0
        self.standdata[3]["index"] = self.generalindex+1
    end

    self.rootItems.markLeft:setVisible(true)
    self.rootItems.markRight:setVisible(true)

    if self.standdata[1]["cid"] == 0 then
        self.rootItems.markLeft:setVisible(false)
    end

    if self.standdata[3]["cid"] == 0 then
        self.rootItems.markRight:setVisible(false)
    end

    self.rootItems.general:removeAllChildrenWithCleanup(true)
    self.stepGneral1 = nil
    self.stepGneral2 = nil
    self.stepGneral3 = nil


    local wing = {level = GameScene.protagonist.w_l, color = GameScene.protagonist.w_c}

    if self.standdata[1]["cid"] ~= 0 then
        printT(self.slotdata[tostring(self.standdata[1].index)],"jkp-self.standdata[1]")
        -- 设置形象
        local generalConfig = gamedata.config.general[tostring(self.standdata[1]["cid"])]
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        if generalConfig.fashion_id == 0 then --非时装
            local generalData = self.slotdata[tostring(self.standdata[1].index)].general
            if generalData.illusionGeneralCid == nil then
                generalName = ui.getGeneralAnimationid(generalName, generalData)
            end
        end
        self.stepGneral1 = CCNode:create()
        local general = ui.itemcache:loadSkeleton(generalName,wing)
        --local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        self.stepGneral1:addChild(general.root or general)
        self.stepGneral1:setPosition(-820,0)
        self.rootItems.general:addChild(self.stepGneral1)
        --
        local mquality1 = gamedata.config.mozhao_break[tostring(self.safemask[tostring(self.slotdata[tostring(self.generalindex-1)].sid)].level)].quality or 2
        if mquality1 < 2 then mquality1 = 2 end
        if mquality1 > 6 then mquality1 = 6 end
        local mNode1,mItems1 = CCBReaderLoad("moqi/loop_moqi_0"..(mquality1-1), nil, true, "moqi")
        mNode1:setPosition(0,0)
        mNode1:setScale(1.6)
        self.stepGneral1:addChild(mNode1)
        --
    end

    ---
    if self.standdata[2]["cid"] ~= 0 then
        printT(self.slotdata[tostring(self.standdata[2].index)],"jkp-self.standdata[2]")
        -- 设置形象
        local generalConfig = gamedata.config.general[tostring(self.standdata[2]["cid"])]
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        if generalConfig.fashion_id == 0 then --非时装
            local generalData = self.slotdata[tostring(self.standdata[2].index)].general
            if generalData.illusionGeneralCid == nil then
                generalName = ui.getGeneralAnimationid(generalName, generalData)
            end
        end
        self.stepGneral2 = CCNode:create()
        local general = ui.itemcache:loadSkeleton(generalName,wing)
        --local general =CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        self.stepGneral2:addChild(general.root or general)
        self.stepGneral2:setPosition(0,0)
        self.rootItems.general:addChild(self.stepGneral2)
        --
        local mquality2 = gamedata.config.mozhao_break[tostring(self.safemask[tostring(self.slotdata[tostring(self.generalindex)].sid)].level)].quality or 2
        if mquality2 < 2 then mquality2 = 2 end
        if mquality2 > 6 then mquality2 = 6 end
        local mNode2,mItems2 = CCBReaderLoad("moqi/loop_moqi_0"..(mquality2-1), nil, true, "moqi")
        mNode2:setPosition(0,0)
        mNode2:setScale(1.6)
        self.stepGneral2:addChild(mNode2)
        --
    end


    if self.standdata[3]["cid"] ~= 0 then
        printT(self.slotdata[tostring(self.standdata[3].index)],"jkp-self.standdata[3]")
        -- 设置形象
        local generalConfig = gamedata.config.general[tostring(self.standdata[3]["cid"])]
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        if generalConfig.fashion_id == 0 then --非时装
            local generalData = self.slotdata[tostring(self.standdata[3].index)].general
            if generalData.illusionGeneralCid == nil then
                generalName = ui.getGeneralAnimationid(generalName, generalData)
            end
        end
        self.stepGneral3 = CCNode:create()
        local general = ui.itemcache:loadSkeleton(generalName,wing)
        --local general =CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        self.stepGneral3:addChild(general.root or general)
        self.stepGneral3:setPosition(820,0)
        self.rootItems.general:addChild(self.stepGneral3)
        --
        local mquality3 = gamedata.config.mozhao_break[tostring(self.safemask[tostring(self.slotdata[tostring(self.generalindex+1)].sid)].level)].quality or 2
        if mquality3 < 2 then mquality3 = 2 end
        if mquality3 > 6 then mquality3 = 6 end
        local mNode3,mItems3 = CCBReaderLoad("moqi/loop_moqi_0"..(mquality3-1), nil, true, "moqi")
        mNode3:setPosition(0,0)
        mNode3:setScale(1.6)
        self.stepGneral3:addChild(mNode3)
        --
    end



    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            self.item1 = nil
            self.item2 = nil
            self.item3 = nil
            self.x1,self.y1 = 0,0
            self.x2,self.y2 = 0,0
            self.x3,self.y3 = 0,0

            if self.stepGneral1 then
                self.item1 = tolua.cast(self.stepGneral1,"CCNode")
                self.x1,self.y1 = self.item1:getPosition()
            end

            if self.stepGneral2 then
                self.item2 = tolua.cast(self.stepGneral2,"CCNode")
                self.x2,self.y2 = self.item2:getPosition()
            end

            if self.stepGneral3 then
                self.item3 = tolua.cast(self.stepGneral3,"CCNode")
                self.x3,self.y3 = self.item3:getPosition()
            end

            return true
        end
    end

    local function ccTouchMoved(x, y)
        local distanceX = x-self.touchX
        if math.abs(distanceX) >20 then
            if self.item1 then
                self.item1:setPositionX(self.x1+distanceX)
            end

            if self.item2 then
                self.item2:setPositionX(self.x2+distanceX)
            end
            if self.item3 then
                self.item3:setPositionX(self.x3+distanceX)
            end
        end

    end

    local function ccTouchEnded(x, y)
        if x-self.touchX > 20 then
            gameTouch:clickprofbytime(0.5)

            self:setActionRightreload()

        elseif self.touchX-x > 20 then
            gameTouch:clickprofbytime(0.5)
            self:setActionLeftreload()
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
    if self.rootItems.touchLayer then
        self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -101, false)
        self.rootItems.touchLayer:setTouchPriority(-101)
        self.rootItems.touchLayer:setTouchEnabled(true)
    end
end

function safemask.setActionRightreload(self)

    if self.item1 then
        local moveTo = CCMoveTo:create(0.8, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item1:runAction(backOut)
        self.item1:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
            self.generalindex = self.standdata[1]["index"]
            self.generalcid = self.slotdata[tostring(self.generalindex)].general.cid or nil
            self.generalListTableView:reloadData()

            self:touchLayerSet()

            --self:setPage()
            self:shiftPage(self.selectpage)

            if self.standdata[2]["index"] == table.getTableLength(self.slotdata) then
                if  self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]) < 0  then
                    self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]),0),0.2)
                end
            elseif  self.titleCellSize.x * self.standdata[2]["index"] >  self.rootItems.listscroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * self.standdata[2]["index"],0),0.2)
            elseif self.titleCellSize.x * (self.standdata[2]["index"]-1) < -self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.standdata[2]["index"]-1) ,0),0.2)
            end

        end)))


    else

        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(820, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item3:runAction(backOut)

        return
    end
    if self.item2 then
        local moveTo = CCMoveTo:create(1, ccp(820, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
    end
end

function safemask.setActionLeftreload(self)

    if self.item3 then
        local moveTo = CCMoveTo:create(0.8, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item3:runAction(backOut)
        self.item3:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
        -- 移动后刷新页面
            self.generalindex = self.standdata[3]["index"]
            self.generalcid = self.slotdata[tostring(self.generalindex)].general.cid or nil
            self.generalListTableView:reloadData()

            self:touchLayerSet()

            --self:setPage()
            self:shiftPage(self.selectpage)

            if self.standdata[2]["index"] == table.getTableLength(self.slotdata) then
                if  self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]) < 0  then
                    self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]),0),0.2)
                end
            elseif  self.titleCellSize.x * self.standdata[2]["index"] >  self.rootItems.listscroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * self.standdata[2]["index"],0),0.2)
            elseif self.titleCellSize.x * (self.standdata[2]["index"]-1) < -self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.standdata[2]["index"]-1) ,0),0.2)
            end

        end)))

    else
        local moveTo = CCMoveTo:create(0.5, ccp(-820, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item1:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)

        return
    end

    if self.item2 then
        local moveTo = CCMoveTo:create(1, ccp(-820, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
    end

end
-----------------------------------------------------------------------------



function safemask.setPage_up(self)
    local config = gamedata.config.mozhao_break or {}
    local safemask = {sid = 1, level = 0, level2 = 0}
    for k,v in pairs(self.safemask) do
        if v.sid == self.slotdata[tostring(self.generalindex)].sid then
            safemask = v
        end
    end
    --
    self.up_needprops = {}
    if safemask.level < 0 then
        safemask.level = 0
        self.rootItems.propnode:setVisible(false)
        self.rootItems.next_attrnode:setVisible(false)
        self.rootItems.attrnode:setPositionX(0)
    elseif safemask.level >= (table.getTableLength(config)-1) then
        safemask.level = table.getTableLength(config)-1
        self.rootItems.propnode:setVisible(false)
        self.rootItems.next_attrnode:setVisible(false)
        self.rootItems.attrnode:setPositionX(0)
    else
        self.rootItems.propnode:setVisible(true)
        self.rootItems.next_attrnode:setVisible(true)
        self.rootItems.attrnode:setPositionX(-290)
        --
        ui.setLabelString(self.rootItems.fixlab5_2,gameConfig.strings:string_common("rank",1),111)
        ui.setLabelString(self.rootItems.fixlab6_2,gameConfig.strings:string_common("fixedString","safemask",1),111)
        ui.setLabelString(self.rootItems.fixlab7_2,gameConfig.strings:string_common("fixedString","safemask",2),111)
        ui.setLabelString(self.rootItems.fixlab8_2,"",111)
        ui.setLabelString(self.rootItems.next_num3,"",13)
        self.rootItems.upnode3:setVisible(false)
        --
        ui.setLabelString(self.rootItems.next_name,config[tostring(safemask.level+1)].name,config[tostring(safemask.level+1)].quality*2)
        ui.setLabelString(self.rootItems.next_level,(safemask.level+1).."/"..config[tostring(safemask.level+1)].lvup,13)
        ui.setLabelString(self.rootItems.next_num1,config[tostring(safemask.level+1)].value,13)
        ui.setLabelString(self.rootItems.next_num2,config[tostring(safemask.level+1)].percent.."%",13)
        if config[tostring(safemask.level+1)].value - config[tostring(safemask.level)].value > 0 then
            self.rootItems.upnode1:setVisible(true)
            ui.setLabelString(self.rootItems.upnum1,config[tostring(safemask.level+1)].value - config[tostring(safemask.level)].value,22)
        else
            self.rootItems.upnode1:setVisible(false)
        end
        if config[tostring(safemask.level+1)].percent - config[tostring(safemask.level)].percent > 0 then
            self.rootItems.upnode2:setVisible(true)
            ui.setLabelString(self.rootItems.upnum2,(config[tostring(safemask.level+1)].percent - config[tostring(safemask.level)].percent).."%",22)
        else
            self.rootItems.upnode2:setVisible(false)
        end
        --
        local coststr = config[tostring(safemask.level)].lv_cost or nil
        local cost = ui.getIDandNUMs(coststr)
        local propindex = 0
        self.rootItems["coinnode"]:setVisible(false)
        for i = 1,4 do
            self.rootItems["prop"..i]:setVisible(false)
            --
            self.rootItems["i_button"..((i == 1) and "" or ("_"..(i-1)))]:addHandleOfControlEvent(function()
                print("i_button")
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..((i == 1) and "" or ("_"..(i-1)))]:setSwallowsTouch(true)
            self.rootItems["i_button"..((i == 1) and "" or ("_"..(i-1)))]:setTouchPriority(-103)
            --
        end
        for k,v in pairs(cost) do
            if v.cid == 1000 then
                self.rootItems["coinnode"]:setVisible(true)
                if v.num > GameScene.roleinfo.coin then
                    ui.setLabelString(self.rootItems.coin,v.num,24)
                else
                    ui.setLabelString(self.rootItems.coin,v.num,14)
                end
            else
                propindex = propindex+1
                if propindex <= 4 then
                    self.rootItems["prop"..propindex]:setVisible(true)
                    --
                    ui.setNewIcon(self.rootItems,v,propindex-1)
                    self.up_needprops[tostring(v.cid)] = {cid = v.cid, num = v.num, index = propindex, has = 0 }
                    --
                    self.rootItems["i_button"..((propindex == 1) and "" or ("_"..(propindex-1)))]:addHandleOfControlEvent(function()
                        gameWindows:openWindow("dropTips",{cid = v.cid},nil)
                    end, CCControlEventTouchUpInside)
                    self.rootItems["i_button"..((propindex == 1) and "" or ("_"..(propindex-1)))]:setSwallowsTouch(true)
                    self.rootItems["i_button"..((propindex == 1) and "" or ("_"..(propindex-1)))]:setTouchPriority(-103)
                    --
                end
            end
        end
        --
        if safemask.level < 1 then
            ui.setLabelString(self.rootItems.upLab,gameConfig.strings:string_common("devil",5),19)
            setControlButtonFrame(self.rootItems["upButton"],"b_s_button2","b_s_button2_h","b_s_button2")
        elseif safemask.level < config[tostring(safemask.level)].lvup then
            ui.setLabelString(self.rootItems.upLab,gameConfig.strings:string_common("equips",7),19)
            setControlButtonFrame(self.rootItems["upButton"],"b_s_button1","b_s_button1_h","b_s_button1")
        else
            ui.setLabelString(self.rootItems.upLab,gameConfig.strings:string_common("popups","tupo"),19)
            setControlButtonFrame(self.rootItems["upButton"],"b_s_button2","b_s_button2_h","b_s_button2")
        end
        --
        self.rootItems["upButton"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            if config[tostring(safemask.level)] and config[tostring(safemask.level)].battle_lv and config[tostring(safemask.level)].battle_lv > GameScene.roleinfo.level then
                runGamePrompt({msg = gameConfig.strings:safemaskLevelUp(config[tostring(safemask.level)].battle_lv)})
            else
                UIRequest({type = 3731,sid = self.slotdata[tostring(self.generalindex)].sid, cost = cost})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems["upButton"]:setSwallowsTouch(true)
        self.rootItems["upButton"]:setTouchPriority(-103)
        --
        if self.rootItems.needlv then
            self.rootItems.needlv:setVisible(false)
        end
    end
    --
    if self.up_needprops and next(self.up_needprops) then
        local cids = {}
        for k,v in pairs(self.up_needprops) do
            table.insert(cids,v.cid)
        end
        UIRequest({type = 12001, order = 37321, cids = cids})
    end
    --
    ui.setLabelString(self.rootItems.fixlab5_1,gameConfig.strings:string_common("rank",1),111)
    ui.setLabelString(self.rootItems.fixlab6_1,gameConfig.strings:string_common("fixedString","safemask",1),111)
    ui.setLabelString(self.rootItems.fixlab7_1,gameConfig.strings:string_common("fixedString","safemask",2),111)
    ui.setLabelString(self.rootItems.fixlab8_1,"",111)
    ui.setLabelString(self.rootItems.num3,"",13)
    ui.setLabelString(self.rootItems.name,config[tostring(safemask.level)].name,config[tostring(safemask.level)].quality*2)
    ui.setLabelString(self.rootItems.level,(safemask.level).."/"..config[tostring(safemask.level)].lvup,13)
    ui.setLabelString(self.rootItems.num1,config[tostring(safemask.level)].value,13)
    ui.setLabelString(self.rootItems.num2,config[tostring(safemask.level)].percent.."%",13)
    --
end

function safemask.ReloadUpData(self,data)
    local config = gamedata.config.mozhao_break or {}
    local safemask = {sid = 1, level = 1}
    for k,v in pairs(self.safemask) do
        if v.sid == self.slotdata[tostring(self.generalindex)].sid then
            safemask = v
        end
    end
    --
    local effectccb,effectitem = CCBReaderLoad("UIEffect/renwushengji/renwushengji", nil, true, "renwushengji")
    self.rootItems.upeffect:removeAllChildrenWithCleanup(true)
    self.rootItems.upeffect:addChild(effectccb)
    --
    gameTouch:clickprofbytime(1)
    --
    self.rootItems.upeffect:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
        if config[tostring(safemask.level+1)] and config[tostring(safemask.level+1)].quality and (config[tostring(safemask.level+1)].quality > config[tostring(safemask.level)].quality) then
            gameWindows:openWindow("safemaskup",{level = safemask.level},nil)
        end
    end)))
end

function safemask.ReloadMasterData(self,data)
    if data and data.safemaskmaster then
        if next(self.safemaskmaster) then
            local config = gamedata.config.mozhao_liandan or {}
            for k,v in pairs(data.safemaskmaster) do
                if self.safemaskmaster[tostring(v.mastertype)] and self.safemaskmaster[tostring(v.mastertype)].masterid < v.masterid then
                    runGamePrompt({msg = gameConfig.strings:string_common("fixedString","deployment",11).." \""..(config[tostring(v.mastertype)][tostring(v.masterid)].desc or "").."\""})
                end
            end
        end
        self.safemaskmaster = data.safemaskmaster
    end
end

function safemask.setUpPropNum(self,pdata)

    for k,v in pairs(pdata) do
        if self.up_needprops[tostring(k)] then
            self.up_needprops[tostring(k)].has = v
        end
    end

    for k,v in pairs(self.up_needprops) do
        if v.has >= v.num then
            ui.setLabelString(self.rootItems["i_num"..((v.index == 1) and "" or ("_"..(v.index-1)))],v.has.."/"..v.num,13)
        else
            ui.setLabelString(self.rootItems["i_num"..((v.index == 1) and "" or ("_"..(v.index-1)))],v.has.."/"..v.num,24)
        end
    end

end

--
function safemask.setPage_stage(self)
    local config = gamedata.config.mozhao_evolve or {}
    local safemask = {sid = 1, level = 0, level2 = 0}
    for k,v in pairs(self.safemask) do
        if v.sid == self.slotdata[tostring(self.generalindex)].sid then
            safemask = v
        end
    end
    --
    self.evolve_needprops = {}
    local attr_now = {}
    local attr_next = {}
    if safemask.level2 < 0 then
        safemask.level2 = 0
        self.rootItems.propnode:setVisible(false)
        self.rootItems.next_attrnode:setVisible(false)
        self.rootItems.attrnode:setPositionX(0)
    elseif safemask.level2 >= (table.getTableLength(config)) then
        safemask.level2 = table.getTableLength(config)
        self.rootItems.propnode:setVisible(false)
        self.rootItems.next_attrnode:setVisible(false)
        self.rootItems.attrnode:setPositionX(0)
        attr_now = ui.getSTRandNUMs(config[tostring(safemask.level2)].effect)
    else
        self.rootItems.propnode:setVisible(true)
        self.rootItems.next_attrnode:setVisible(true)
        self.rootItems.attrnode:setPositionX(-290)
        --
        attr_next = ui.getSTRandNUMs(config[tostring(safemask.level2+1)].effect)
        if config[tostring(safemask.level2)] then
            attr_now = ui.getSTRandNUMs(config[tostring(safemask.level2)].effect)
        end
        --
        ui.setLabelString(self.rootItems.fixlab5_2,"",111)
        ui.setLabelString(self.rootItems.next_name,"下阶"..(safemask.level2+1).."阶",gamedata.config.mozhao_break[tostring(safemask.level)].quality*2)
        ui.setLabelString(self.rootItems.next_level,"",13)
        for i = 1,3 do
            if attr_next and attr_next[i] then
                ui.setLabelString(self.rootItems["fixlab"..(5+i).."_2"],gameConfig.strings.attr_type[attr_next[i].str],111)
                if attr_next[i].num > 0 and attr_next[i].num < 1 then
                    ui.setLabelString(self.rootItems["next_num"..i],(attr_next[i].num*100).."%",13)
                else
                    ui.setLabelString(self.rootItems["next_num"..i],attr_next[i].num,13)
                end
                if attr_next[i].num > (attr_now[i] and attr_now[i].num or 0) then
                    self.rootItems["upnode"..i]:setVisible(true)
                    if attr_next[i].num < 1 then
                        ui.setLabelString(self.rootItems["upnum"..i],((attr_next[i].num - (attr_now[i] and attr_now[i].num or 0))*100)..("%"),22)
                    else
                        ui.setLabelString(self.rootItems["upnum"..i],attr_next[i].num - (attr_now[i] and attr_now[i].num or 0),22)
                    end
                else
                    self.rootItems["upnode"..i]:setVisible(false)    
                end
            else
                ui.setLabelString(self.rootItems["fixlab"..(5+i).."_2"],"",111)
                ui.setLabelString(self.rootItems["next_num"..i],"",13)
                self.rootItems["upnode"..i]:setVisible(false)
            end
        end
        --
        local coststr = config[tostring(safemask.level2+1)].lv_cost or nil
        local cost = ui.getIDandNUMs(coststr)
        local propindex = 0
        self.rootItems["coinnode"]:setVisible(false)
        for i = 1,4 do
            self.rootItems["prop"..i]:setVisible(false)
            --
            self.rootItems["i_button"..((i == 1) and "" or ("_"..(i-1)))]:addHandleOfControlEvent(function()
                print("i_button")
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..((i == 1) and "" or ("_"..(i-1)))]:setSwallowsTouch(true)
            self.rootItems["i_button"..((i == 1) and "" or ("_"..(i-1)))]:setTouchPriority(-103)
            --
        end
        for k,v in pairs(cost) do
            if v.cid == 1000 then
                self.rootItems["coinnode"]:setVisible(true)
                if v.num > GameScene.roleinfo.coin then
                    ui.setLabelString(self.rootItems.coin,v.num,24)
                else
                    ui.setLabelString(self.rootItems.coin,v.num,14)
                end
            else
                propindex = propindex+1
                if propindex <= 4 then
                    self.rootItems["prop"..propindex]:setVisible(true)
                    --
                    ui.setNewIcon(self.rootItems,v,propindex-1)
                    self.evolve_needprops[tostring(v.cid)] = {cid = v.cid, num = v.num, index = propindex, has = 0 }
                    --
                    self.rootItems["i_button"..((propindex == 1) and "" or ("_"..(propindex-1)))]:addHandleOfControlEvent(function()
                        gameWindows:openWindow("dropTips",{cid = v.cid},nil)
                    end, CCControlEventTouchUpInside)
                    self.rootItems["i_button"..((propindex == 1) and "" or ("_"..(propindex-1)))]:setSwallowsTouch(true)
                    self.rootItems["i_button"..((propindex == 1) and "" or ("_"..(propindex-1)))]:setTouchPriority(-103)
                    --
                end
            end
        end
        --
        if self.rootItems.needlv then
            if config[tostring(safemask.level2+1)] and config[tostring(safemask.level2+1)].mozhao_lv then
                self.rootItems.needlv:setVisible(true)

                local needlv2 = 0
                local arg = {}
                local needstr0 = "进阶要求: "
                local needstr1 = ""
                local needstr2 = ""
                local fixX = 320 
                if config[tostring(safemask.level2+1)] and config[tostring(safemask.level2+1)].mozhao_evolve_lv and config[tostring(safemask.level2+1)].mozhao_evolve_lv > 0 then
                    needstr1 = "1.伙伴魔罩等级达到"..config[tostring(safemask.level2+1)].mozhao_lv.."级 "
                    needstr2 = "2.全体伙伴魔罩阶级达到"..config[tostring(safemask.level2+1)].mozhao_evolve_lv.."阶 "
                    fixX = 140
                    needlv2 = config[tostring(safemask.level2+1)].mozhao_evolve_lv
                else
                    needstr1 = "伙伴魔罩等级达到"..config[tostring(safemask.level2+1)].mozhao_lv.."级 "
                    needstr2 = ""  
                    needlv2 = 0
                    fixX = 320
                end     

                local needfontID0 = 26
                local needfontID1 = 26
                local needfontID2 = 26

                if config[tostring(safemask.level2+1)].mozhao_lv > safemask.level then
                    needfontID0 = 13
                    needfontID1 = 13
                end

                if needlv2 > self.minlv then
                    needfontID0 = 13
                    needfontID2 = 13
                end    

                table.insert(arg,{fontID = needfontID0,content = needstr0})
                table.insert(arg,{fontID = needfontID1,content = needstr1})
                table.insert(arg,{fontID = needfontID2,content = needstr2})

                ui.createRichLabel(arg,self.rootItems.needlv)
                self.rootItems.needlv:setPositionX(fixX)


            else
                self.rootItems.needlv:setVisible(false)
            end
        end
        --
        self.rootItems["upButton"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            if config[tostring(safemask.level2+1)] and config[tostring(safemask.level2+1)].mozhao_lv and config[tostring(safemask.level2+1)].mozhao_lv > safemask.level then
                runGamePrompt({msg = "需要魔罩到达"..config[tostring(safemask.level2+1)].mozhao_lv.."级"})
            elseif config[tostring(safemask.level2+1)] and config[tostring(safemask.level2+1)].mozhao_evolve_lv and config[tostring(safemask.level2+1)].mozhao_evolve_lv > self.minlv then
                runGamePrompt({msg = "需要全体魔罩到达"..config[tostring(safemask.level2+1)].mozhao_evolve_lv.."阶"})
            else
                UIRequest({type = 3735,sid = self.slotdata[tostring(self.generalindex)].sid, cost = cost})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems["upButton"]:setSwallowsTouch(true)
        self.rootItems["upButton"]:setTouchPriority(-103)
        --
    end
    --
    if self.evolve_needprops and next(self.evolve_needprops) then
        local cids = {}
        for k,v in pairs(self.evolve_needprops) do
            table.insert(cids,v.cid)
        end
        UIRequest({type = 12001, order = 37322, cids = cids})
    end
    --
    ui.setLabelString(self.rootItems.fixlab5_1,"",111)
    ui.setLabelString(self.rootItems.name,"当前"..safemask.level2.."阶",gamedata.config.mozhao_break[tostring(safemask.level)].quality*2)
    ui.setLabelString(self.rootItems.level,"",13)
    for i = 1,3 do
        if attr_now and attr_now[i] then
            ui.setLabelString(self.rootItems["fixlab"..(5+i).."_1"],gameConfig.strings.attr_type[attr_now[i].str],111)
            if attr_now[i].num > 0 and attr_now[i].num < 1 then
                ui.setLabelString(self.rootItems["num"..i],(attr_now[i].num*100).."%",13)
            else
                ui.setLabelString(self.rootItems["num"..i],attr_now[i].num,13)
            end
        elseif attr_next and attr_next[i] then
            ui.setLabelString(self.rootItems["fixlab"..(5+i).."_1"],gameConfig.strings.attr_type[attr_next[i].str],111)
            ui.setLabelString(self.rootItems["num"..i],0,13)
        else
            ui.setLabelString(self.rootItems["fixlab"..(5+i).."_1"],"",111)
            ui.setLabelString(self.rootItems["num"..i],"",13)
        end
    end
    --
    ui.setLabelString(self.rootItems.upLab,"进阶",19)
    setControlButtonFrame(self.rootItems["upButton"],"b_s_button2","b_s_button2_h","b_s_button2")
    --
end


function safemask.setEvolvePropNum(self,pdata)

    for k,v in pairs(pdata) do
        if self.evolve_needprops[tostring(k)] then
            self.evolve_needprops[tostring(k)].has = v
        end
    end

    for k,v in pairs(self.evolve_needprops) do
        if v.has >= v.num then
            ui.setLabelString(self.rootItems["i_num"..((v.index == 1) and "" or ("_"..(v.index-1)))],v.has.."/"..v.num,13)
        else
            ui.setLabelString(self.rootItems["i_num"..((v.index == 1) and "" or ("_"..(v.index-1)))],v.has.."/"..v.num,24)
        end
    end

end

function safemask.ReloadEvolveData(self,data)

    local effectccb,effectitem = CCBReaderLoad("UIEffect/renwushengji/renwushengji", nil, true, "renwushengji")
    self.rootItems.upeffect:removeAllChildrenWithCleanup(true)
    self.rootItems.upeffect:addChild(effectccb)
    --
end

--

function safemask.ReloadFeiShengData(self)
    local effectccb,effectitem = CCBReaderLoad("UIEffect/mozhaofeisheng/mozhaofengshengeffect", nil, true, "mozhaofeishengeffect")
    self.rootItems.feisheng_effectNode:removeAllChildrenWithCleanup(true)
    self.rootItems.feisheng_effectNode:addChild(effectccb)
end

function safemask.setPage_feisheng(self)
    local config = gamedata.config.mozhao_soaring or {}
    local safemask = {sid = 1, level = 0, level2 = 0,level3 = 0}
    for k,v in pairs(self.safemask) do
        if v.sid == self.slotdata[tostring(self.generalindex)].sid then
            safemask = v
        end
    end

    self.rootItems.feisheng_bg2 = tolua.cast(self.rootItems.feisheng_bg2, "CCScale9Sprite")
    
    local maxLevel = table.getTableLength(config) - 1
    self.feisheng_needprops = {}
    local attr_now = {}
    local attr_next = {}
    if safemask.level3 >= maxLevel then
        safemask.level3 = maxLevel
        self.rootItems.feisheng_bg2:setPreferredSize(CCSizeMake(1000,180))

        self.rootItems.feishengPropNode:setVisible(false)
        self.rootItems.feishengnextattnode:setVisible(false)
        self.rootItems.feishengattnode:setPositionX(20)
        self.rootItems.feisheng_maxTitle:setVisible(true)
        

        attr_now = ui.getSTRandNUMs(config[tostring(safemask.level3)].effect)

        local curLevelConfig = config[tostring(safemask.level3)]
        self.rootItems.feisheng_level:setString(config[tostring(safemask.level3)].name)
        self.rootItems.feisheng_att1:setString(attr_now[1].num)
        self.rootItems.feisheng_att2:setString(attr_now[2].num)
        return
    else
        self.rootItems.feisheng_bg2:setPreferredSize(CCSizeMake(760,180))
        self.rootItems.feishengPropNode:setVisible(true)
        self.rootItems.feishengnextattnode:setVisible(true)
        self.rootItems.feishengattnode:setPositionX(-230)
        self.rootItems.feisheng_maxTitle:setVisible(false)

        local curLevelConfig = config[tostring(safemask.level3)]
        local nextLevelConfig = config[tostring(safemask.level3 + 1)]


        attr_now = ui.getSTRandNUMs(curLevelConfig.effect)
        attr_next = ui.getSTRandNUMs(nextLevelConfig.effect)

        self.rootItems.feisheng_level:setString(curLevelConfig.name)
        self.rootItems.feisheng_att1:setString(safemask.level3 == 0 and 0 or attr_now[1].num)
        self.rootItems.feisheng_att2:setString(safemask.level3 == 0 and 0 or attr_now[2].num)

        self.rootItems.feisheng_next_level:setString(nextLevelConfig.name)
        self.rootItems.feisheng_next_att1:setString(attr_next[1].num)
        self.rootItems.feisheng_next_att2:setString(attr_next[2].num)

    
        if self.rootItems.feisheng_needlv then
            if nextLevelConfig then
                self.rootItems.feisheng_needlv:setVisible(true)

                local needlv2 = 0
                local arg = {}
                local needstr0 = "飞升要求: "
                local needstr = {}
                local fixX = 320 --140
                if nextLevelConfig and nextLevelConfig.advanced_level and nextLevelConfig.advanced_level > 0 then
                    local ismeet = true
                    if safemask.level2 < nextLevelConfig.advanced_level then
                        ismeet = false
                    end
                    table.insert(needstr,{str = "魔罩进阶等级达到"..nextLevelConfig.advanced_level.."级 ",meet = ismeet})
                end

                if nextLevelConfig and nextLevelConfig.all_soaring_level and nextLevelConfig.all_soaring_level > 0 then

                    local ismeet = true
                    for k,v in pairs(self.safemask) do
                        if v.level3 < nextLevelConfig.all_soaring_level then
                            ismeet = false
                            break
                        end
                    end
                    table.insert(needstr,{str = "全体魔罩飞升等级达到"..nextLevelConfig.all_soaring_level.."级 ",meet = ismeet})
                end
                if #needstr > 0 then
                    local needfontID0 = needstr[1].meet and 26 or 13
                    local needfontID1 = needstr[1].meet and 26 or 13
                    local needfontID2 = 26

                    if needstr[2] then
                        fixX = 140
                    end

                    if needstr[2] and needstr[2].meet then
                    else
                        needfontID2 = 13
                    end

                    local fontIds = {needfontID1,needfontID2}

                    table.insert(arg,{fontID = needfontID0,content = needstr0})
                    for i,v in ipairs(needstr) do
                        table.insert(arg,{fontID = fontIds[i],content = i.."."..v.str})
                    end
                end
                ui.createRichLabel(arg,self.rootItems.feisheng_needlv)
                self.rootItems.feisheng_needlv:setPositionX(fixX)

            else
                self.rootItems.feisheng_needlv:setVisible(false)
            end
        end

        

        local coststr = nextLevelConfig.consume
        local cost = ui.getIDandNUMs(coststr)
        local propindex = 0
        self.rootItems["feisheng_coinnode"]:setVisible(false)
        for i = 1,4 do
            self.rootItems["feisheng_prop"..i]:setVisible(false)
        end

        for k,v in pairs(cost) do
            if v.cid == 1000 then
                self.rootItems["feisheng_coinnode"]:setVisible(true)
                if v.num > GameScene.roleinfo.coin then
                    ui.setLabelString(self.rootItems.feisheng_coin,v.num,24)
                else
                    ui.setLabelString(self.rootItems.feisheng_coin,v.num,14)
                end
            else
                propindex = propindex+1
                if propindex <= 4 then
                    self.rootItems["feisheng_prop"..propindex]:setVisible(true)
                    
                    local index = propindex + 4
                    ui.setNewIcon(self.rootItems,v,4 + propindex-1)
                    self.feisheng_needprops[tostring(v.cid)] = {cid = v.cid, num = v.num, index = index, has = 0 }
                    --
                    self.rootItems["i_button"..((index == 1) and "" or ("_"..(index-1)))]:addHandleOfControlEvent(function()
                        gameWindows:openWindow("dropTips",{cid = v.cid},nil)
                    end, CCControlEventTouchUpInside)
                    self.rootItems["i_button"..((index == 1) and "" or ("_"..(index-1)))]:setSwallowsTouch(true)
                    self.rootItems["i_button"..((index == 1) and "" or ("_"..(index-1)))]:setTouchPriority(-103)
                    --
                end
            end
        end

        self.rootItems["feishengButton"]:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            if nextLevelConfig and nextLevelConfig.advanced_level and nextLevelConfig.advanced_level > safemask.level2 then
                runGamePrompt({msg = "需魔罩进阶等级达到"..nextLevelConfig.advanced_level.."级"})
                return
            elseif nextLevelConfig and nextLevelConfig.all_soaring_level and nextLevelConfig.all_soaring_level > 0 then
                local ismeet = true
                for k,v in pairs(self.safemask) do
                    if v.level3 < nextLevelConfig.all_soaring_level then
                        ismeet = false
                        break
                    end
                end
                if not ismeet then
                    runGamePrompt({msg = "需全体魔罩飞升等级达到"..nextLevelConfig.all_soaring_level.."级"})
                    return
                end
            end
            UIRequest({type = 3736,sid = self.slotdata[tostring(self.generalindex)].sid, cost = cost})
        end, CCControlEventTouchUpInside)
        self.rootItems["feishengButton"]:setSwallowsTouch(true)
        self.rootItems["feishengButton"]:setTouchPriority(-103)


        local cids = {}
        for k,v in pairs(cost) do
            table.insert(cids,v.cid)
        end
        UIRequest({type = 12001, order = 32006, cids = cids})
    end
    --
    
end

function safemask.setFeiShengPropNum(self,t)

    for k,v in pairs(t) do
        if self.feisheng_needprops[tostring(k)] then
            self.feisheng_needprops[tostring(k)].has = v
        end
    end

    for k,v in pairs(self.feisheng_needprops) do
        if v.has >= v.num then
            ui.setLabelString(self.rootItems["i_num"..((v.index == 1) and "" or ("_"..(v.index-1)))],v.has.."/"..v.num,13)
        else
            ui.setLabelString(self.rootItems["i_num"..((v.index == 1) and "" or ("_"..(v.index-1)))],v.has.."/"..v.num,24)
        end
    end
end

function safemask.initFixedString(self)
    self.rootItems.fixlab1:setString(gameConfig.strings:string_common("fixedString","copyFiend",1))
    self.rootItems.up_title:setString(gameConfig.strings:string_common("fixedString","equip",10))
    ui.setLabelString(self.rootItems.feishengLab,gameConfig.strings:string_common("fixedString","safemask",7),19)
end


return safemask
