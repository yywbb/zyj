--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/5
-- Time: 16:05
-- To change this template use File | Settings | File Templates.
--


local recruitshop = {
    rootNode = nil,
    rootItems = nil,


    listview = nil,

}

function recruitshop.checkRecruitActivity2( self )
    if gamedata.config.enlist
            and gameConfig:checkBuildOpen(362)
            and GameScene:checkopenlevelbyId(362,true) then

        local now =  gamedata:time()
        local v = gamedata.config.enlist["2"]
        local isactive,resttime = ui.checkDateActive(v.opentime,v.overtime,now)
        if isactive then
            return true, resttime
        end
    end
    return false
end

function recruitshop.open(self,touchPriority,data,callback)

    self.rootNode, self.rootItems = CCBReaderLoad("shop/jifenshop", nil, true, "jifenshop")
    self.show = true
    self.touchPriority = touchPriority

    self.config = gamedata.config.enlist_shop
    self.num = math.ceil(table.getTableLength(self.config)/2)

    --
    if self.rootItems.jifen_time then
        self.rootItems.jifen_time:setVisible(false)
    end
    local pointactive,pointtime = self:checkRecruitActivity2()
    if pointactive then
        gameTimer:rigistTime("w_recruitactivity2",pointtime)
        if gameTimer.times["w_recruitactivity2"] and gameTimer.times["w_recruitactivity2"] > 0 then
            gameTimer:rigistTimeFunc("w_recruitactivity2", function()
                if gameTimer.times["w_recruitactivity2"] <= 0 then
                    if gameTimer.times["w_recruitactivity2"] then
                        gameTimer:UnrigistTimeFunc("w_recruitactivity2")
                    end
                    --
                    if self.rootItems.jifen_time then
                        ui.setLabelString( self.rootItems.jifen_time,"",26)
                    end
                    --
                    gameWindows:closeWindow("recruitshop")
                elseif self.rootItems.jifen_time then
                    ui.setLabelString( self.rootItems.jifen_time,"活动结束倒计时："..ui.makeTimeDayText(gameTimer.times["w_recruitactivity2"],"day"),26)
                end
            end)
        end
        --
        if self.rootItems.jifen_time then
            self.rootItems.jifen_time:setVisible(true)
        end
    end
    --

    if data.data then
        self:reload(data.data)
    else
        UIRequest({type=5321})   
    end

    return self.rootNode
end

function recruitshop.reload(self,data,callback)
    self.callback = callback
    self.data = data

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("recruitshop")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.pointdes,"当前积分: ",14)
    ui.setLabelString(self.rootItems.point,data.points,48)


    if not self.listview then
        self:creatlist()
    else
        self.listview:reloadData()
    end
end

function recruitshop.setProps( self,item,index )
    local id1 = index*2-1
    local id2 = index*2

    local config1 = self.config[tostring(id1)]
    local config2 = self.config[tostring(id2)]
    local data1 = self.data.status[tostring(id1)]
    local data2 = self.data.status[tostring(id2)]

    if config1 then
        item.node1:setVisible(true)
        local rewardid,rewardnum = ui.getIDandNUM(config1.reward)
        ui.setNewIconName(item,{cid =rewardid,num = rewardnum})
        item.resttime:setString("可兑换次数:"..(config1.time-data1))
        item.point:setString("积分:"..config1.integral)

        ui.setLabelString(item.gettext,gameConfig.strings:string_common("buttontext","duihuan"),18)
        --item.getbutton:setSwallowsTouch(true)
        item.getbutton:setTouchPriority(self.touchPriority)
        if config1.time-data1 > 0 then
            ui.removeGray("CCControlButton",item.getbutton)
            item.getbutton:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                if config1.integral > self.data.points then
                    runGamePrompt({msg = "积分不足"})
                else
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 5322,id = id1})
                end
            end, CCControlEventTouchUpInside)
        else
            ui.addGray("CCControlButton",item.getbutton)
            item.getbutton:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                runGamePrompt({msg = "次数已用完"})
            end, CCControlEventTouchUpInside)
        end

        item["in_button"]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(rewardid)
        end, CCControlEventTouchUpInside)
        --item["in_button"]:setSwallowsTouch(true)
        item["in_button"]:setTouchPriority(self.touchPriority)
    else
        item.node1:setVisible(false)
    end

    if config2 then
        item.node2:setVisible(true)
        local rewardid,rewardnum = ui.getIDandNUM(config2.reward)
        ui.setNewIconName(item,{cid =rewardid,num = rewardnum},1)
        item.resttime2:setString("可兑换次数:"..(config2.time-data2))
        item.point2:setString("积分:"..config2.integral)

        ui.setLabelString(item.gettext2,gameConfig.strings:string_common("buttontext","duihuan"),18)
        --item.getbutton2:setSwallowsTouch(true)
        item.getbutton2:setTouchPriority(self.touchPriority)
        if config2.time-data2 > 0 then
            ui.removeGray("CCControlButton",item.getbutton2)
            item.getbutton2:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                if config2.integral > self.data.points then
                    runGamePrompt({msg = "积分不足"})
                else
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 5322,id = id2})
                end
            end, CCControlEventTouchUpInside)
        else
            ui.addGray("CCControlButton",item.getbutton2)
            item.getbutton2:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                runGamePrompt({msg = "次数已用完"})
            end, CCControlEventTouchUpInside)
        end

        item["in_button_1"]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(rewardid)
        end, CCControlEventTouchUpInside)
        --item["in_button_1"]:setSwallowsTouch(true)
        item["in_button_1"]:setTouchPriority(self.touchPriority)
    else
        item.node2:setVisible(false)
    end


end

function recruitshop.creatlist( self )
    local celldict = {}
    local propsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1000, 320)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shop/cell_jifenshop", nil, true, "cell_jifenshop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setProps(ccbDocumentControler,a1+1)

            cellCCB:setPosition(500, 0)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = self.num
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = propsListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end



function recruitshop.close(self)

    if gameTimer.times["w_recruitactivity2"] then
        gameTimer:UnrigistTimeFunc("w_recruitactivity2")
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.listview = nil

    if self.callback then
        self.callback()
    end
end

return recruitshop �"  