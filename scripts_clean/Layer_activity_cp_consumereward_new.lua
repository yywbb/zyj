--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local consumereward = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    datarewards = {},
    status = {},
    ListTableView = nil,
    normalCellSize = {x=1080,y=282+14},
}


function consumereward.init(self,size)
    self.contentsize = size
    self.show = true

    if gamedata.config.build[tostring(274)] and gamedata.config.build[tostring(274)].switch and gamedata.config.build[tostring(274)].switch == 1 then
        self.coverccb, self.coveritems = CCBReaderLoad("activityqixi/qixi_xiaofeiyouli2",nil, true, "consumereward")
        self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-570))
    else
        self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/xiaofeiyouli2",nil, true, "consumereward")
        self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-570))
    end
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(91)].generalanimation)].name
    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- local Gneral1 = CCSkeletonAnimation:create("yanwang/yanwang.json","yanwang/yanwang.atlas",1)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode"]:addChild(Gneral1)


    ui.setLabelString(self.coveritems.desc1,nil,1)
    ui.setLabelString(self.coveritems.desc2,nil,1)
    ui.setLabelString(self.coveritems.desc3,nil,111)
    ui.setLabelString(self.coveritems.desc4,nil,111)


    --
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","consumereward",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","consumereward",touchend)
    --

    return self.coverccb
end

function consumereward.reloaddata(self,data)
    if not self.show then return end
    --
    self.status = data.status or self.status
    self.time = data.time or self.time
    self.goldNum = data.goldNum or self.goldNum

    self.datarewards = data.status or {}

    --
    -- if self.status["1"] then
    if self.time then
        local time = " "
        -- if self.status["1"] > 0 then
        if self.time > 0 then
            -- time = gameConfig.strings:Day(math.ceil((self.status["1"]+0)/(3600*24)))
            if gameTimer.times["Activityconsumerreward"] and gameTimer.times["Activityconsumerreward"] > 0 then
                gameTimer:rigistTimeFunc("Activityconsumerreward", function()
                    if gameTimer.times["Activityconsumerreward"] <= 0 then
                        if gameTimer.times["Activityconsumerreward"] then
                            gameTimer:UnrigistTimeFunc("Activityconsumerreward")
                        end
                    else
                        self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["Activityconsumerreward"],"day"))
                        ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
                    end
                end)
            end
        end
        --self.coveritems.time:setString(time)
    end
    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)

    if self.goldNum then
        self.coveritems.gold_num:setString(self.goldNum or 0)
    end

    --

    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            if self.ListTableView:getLuaContentOffsetY() < self.coveritems.listnode:getContentSize().height - table.getTableLength(self.datarewards)*self.normalCellSize.y then
                self.ListTableView:setLuaContentOffset(0, self.coveritems.listnode:getContentSize().height - table.getTableLength(self.datarewards)*self.normalCellSize.y)
            end
            self.ListTableView:reloadData()
        end
    end

end

function consumereward.clear(self)
    gameTouch:UnrigistFunc("begin","consumereward")
    gameTouch:UnrigistFunc("end","consumereward")
    --
    if gameTimer.times["Activityconsumerreward"] then
        gameTimer:UnrigistTimeFunc("Activityconsumerreward")
    end
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.datarewards = {}
    self.status = {}
    self.time = 0
    self.goldNum = 0
    self.coverccb = nil
    self.coveritems = nil
end

function consumereward.createList(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward1", nil, true, "cell_reward1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler, self.datarewards[tostring(a1+1)].reward, a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.datarewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.listnode:getContentSize().width,
        viewheight = self.coveritems.listnode:getContentSize().height,
        dire = 1
    })
    self.coveritems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end


function consumereward.setCell(self,item,data,index)
    print("setCell")

    item.doButton:setTouchPriority(-102)
    -- print("状态", )
    if self.status[tostring(index)].status and self.status[tostring(index)].status == 1 then
        item.rechargeNode:setVisible(false)
        item.nonenode:setVisible(false)
        item.doNode:setVisible(true)
        item.hasnode:setVisible(false)
        ui.removeGray("CCControlButton",item.doButton)
        ui.removeGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("buttontext","lingqu"))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(1)
            print("getbutton clicked")
            UIRequest({type = 5040, id = data.id or 1})
        end, CCControlEventTouchUpInside)
    elseif self.status[tostring(index)].status and self.status[tostring(index)].status == 2 then
        item.rechargeNode:setVisible(false)
        item.nonenode:setVisible(false)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(true)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("buttontext","yilingqu"))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","yilingqu")})
        end, CCControlEventTouchUpInside)
    else
        item.nonenode:setVisible(false) -- true
        item.rechargeNode:setVisible(true) -- 
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("buttontext","lingqu"))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","weiwancheng")})
        end, CCControlEventTouchUpInside)

        -- 去消费
        ui.setLabelString(item.rechargeLab, "去消费", 18)
        item.rechargeButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            -- 跳转到商城
            -- GameScene:shiftLayerById(12)
            GameScene:shiftLayer("shopList","up")
        end, CCControlEventTouchUpInside)
        item.rechargeButton:setTouchPriority(self.buttontouch)
    end

    item.title:setString(gameConfig.strings:addGold(data.gold))
    local props = ui.getIDandNUMs(data.reward) or {}

    for i=1, 4 do
        if props[i] and props[i].cid then
            item["reward"..i]:setVisible(true)
            local config = ui.IDconfig(props[i].cid)
            if config then
                ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    if gameTouch.isScrollling then return end
                    ui.setPopwindowByCid(props[i].cid)
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        else
            item["reward"..i]:setVisible(false)
        end
    end

    item.typenode:setVisible(false)
    item.reward4:setVisible(false)


end


return consumereward