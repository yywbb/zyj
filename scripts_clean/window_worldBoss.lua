--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/25
-- Time: 下午7:12
-- To change this template use File | Settings | File Templates.
--


local worldbossrank = {
    rootNode = nil,
    rootItems = nil,

    ListTableView = nil,
    rewardListTableView = nil,
    isscrolltouched = false,
    callback = nil,
}

function worldbossrank.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.data = data.data
    self.selectpage = data.selectpage 
    print("worldbossrank.open")
    printT(self.data)
    if data.index == "rank" then
        self.rootNode, self.rootItems = CCBReaderLoad("worldboss2/n_worldboss_zhankuang", nil, true, "n_worldboss_zhankuang")
        self:reload(callback)
    elseif data.index == "reward" then
        -- UIRequest({type = 3706})
        self.rootNode, self.rootItems = CCBReaderLoad("worldboss2/n_worldboss_jiangliyulan", nil, true, "n_worldboss_jiangliyulan")
        self.callback  = callback
        self:rewardReload(callback)
    end

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","worldbossrank",touchbegin)
    local function touchend(pos)
        if self.rootItems.listscroll and ui.isTouched(self.rootItems.listscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","worldbossrank",touchend) 

    self.root:addChild(self.rootNode)
    return self.root
end

function worldbossrank.reload(self,callback)
    
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("worldbossrank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 180)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("worldboss2/cell_n_worldboss_zhankuang", nil, true, "cell_n_worldboss_zhankuang")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end



            ui.setLabelString(ccbDocumentControler.levelNumText,nil, 7)

            if tonumber(self.data.kill.rid) ~= 0 then
                if (a1+1) == 1 then
                    ccbDocumentControler.rankNode:setVisible(false)
                    ccbDocumentControler.killerNode:setVisible(true)
                    ui.setLabelString(ccbDocumentControler.ranknameLabel,self.data.kill.name, 7)
                    ui.setLabelString(ccbDocumentControler.levelNumLable,self.data.kill.level, 7)
                    ccbDocumentControler.ranDamageLabel:setString(self.data.kill.param)

                    --todo
                    --part
                    if ccbDocumentControler.duanNode then
                        ui.setWudaoPart(ccbDocumentControler,self.data.kill.part_point or 0)
                    end
                else
                    -- ccbDocumentControler.killerNode:setPosition(ccp(9999,90))
                    ccbDocumentControler.rankNode:setVisible(true)
                    ccbDocumentControler.killerNode:setVisible(false)
                    ccbDocumentControler.rankNumLabel:setVisible(false)
                    if (a1+1) == 2 then
                        setSpriteFrameByName(ccbDocumentControler.ranksprite, "b_n_zxt_1")
                    elseif (a1+1) == 3 then
                        setSpriteFrameByName(ccbDocumentControler.ranksprite, "b_n_zxt_2")
                    elseif (a1+1) == 4 then
                        -- ccbDocumentControler.ranksprite:setVisible(false)
                        setSpriteFrameByName(ccbDocumentControler.ranksprite, "b_n_zxt_3")
                    else
                        ccbDocumentControler.rankNumLabel:setVisible(true)
                        setSpriteFrameByName(ccbDocumentControler.ranksprite, "alpha")
                    end

                    ccbDocumentControler.rankNumLabel:setString(a1)

                    ui.setLabelString(ccbDocumentControler.ranknameLabel,self.data.ranks[tostring(a1)].name, 7)
                    ui.setLabelString(ccbDocumentControler.levelNumLable,self.data.ranks[tostring(a1)].level, 7)
                    ccbDocumentControler.ranDamageLabel:setString(self.data.ranks[tostring(a1)].param)

                    --todo
                    --part
                    if ccbDocumentControler.duanNode then
                        ui.setWudaoPart(ccbDocumentControler,self.data.ranks[tostring(a1)].part_point or 0)
                    end
                end
            else
                
                -- ccbDocumentControler.killerNode:setPosition(ccp(9999,90))
                ccbDocumentControler.rankNode:setVisible(true)
                ccbDocumentControler.killerNode:setVisible(false)
                ccbDocumentControler.rankNumLabel:setVisible(false)
                if (a1+1) == 1 then
                    
                    setSpriteFrameByName(ccbDocumentControler.ranksprite, "b_n_zxt_1")
                elseif (a1+1) == 2 then
                    setSpriteFrameByName(ccbDocumentControler.ranksprite, "b_n_zxt_2")
                elseif (a1+1) == 3 then
                    setSpriteFrameByName(ccbDocumentControler.ranksprite, "b_n_zxt_3")
                else
                   -- ccbDocumentControler.ranksprite:setVisible(false) 
                   setSpriteFrameByName(ccbDocumentControler.ranksprite, "alpha")
                   ccbDocumentControler.rankNumLabel:setVisible(true)
                end

                ccbDocumentControler.rankNumLabel:setString(a1+1)

                ui.setLabelString(ccbDocumentControler.ranknameLabel,self.data.ranks[tostring(a1+1)].name, 7)
                ui.setLabelString(ccbDocumentControler.levelNumLable,self.data.ranks[tostring(a1+1)].level, 7)
                ccbDocumentControler.ranDamageLabel:setString(self.data.ranks[tostring(a1+1)].param)

                --todo
                --part
                if ccbDocumentControler.duanNode then
                    ui.setWudaoPart(ccbDocumentControler,self.data.ranks[tostring(a1+1)].part_point or 0)
                end
            end

            -- ui.setLabelString(ccbDocumentControler.killerBtntext,nil,18)
            -- ccbDocumentControler.killerBtn:setTouchPriority(self.touchPriority-1)
            -- ccbDocumentControler.killerBtn:addHandleOfControlEvent(function()
                    -- if not self.isscrolltouched then return end
                    -- if gameTouch.isScrollling then return end
            --     print("i...am..killerBtn")
            --     printT(self.data)
            --     GameScene:addtempLayers("other_slotinfo",self.data.kill,nil,2)
            -- end, CCControlEventTouchUpInside)


            ui.setLabelString(ccbDocumentControler.buttontext,nil,18)
            ccbDocumentControler.button:setTouchPriority(self.touchPriority-1)
            ccbDocumentControler.button:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end

                if tonumber(self.data.kill.rid) == 0 then

                    local data = {}
                    if tonumber(self.data.kill.rid) ~= 0 then
                        data = self.data.ranks[tostring(a1)]
                    else
                        data = self.data.ranks[tostring(a1+1)]
                    end
                    print("i...am..buttonBtn")
                    printT(data)
                    GameScene:addtempLayers("other_slotinfo",data,nil,2)
                else
                    if (a1+1) == 1 then
                        print("i...am..killerBtn")
                        printT(self.data)
                        GameScene:addtempLayers("other_slotinfo",self.data.kill,nil,2)
                    else
                        local data = self.data.ranks[tostring(a1)]
                        print("i...am..buttonBtn")
                        printT(data)
                        GameScene:addtempLayers("other_slotinfo",data,nil,2)
                    end
                    
                end

                
            end, CCControlEventTouchUpInside)

            cellCCB:setPosition(920/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            if tonumber(self.data.kill.rid) ~= 0 then
                r = table.getTableLength(self.data.ranks) +1
            else
                r = table.getTableLength(self.data.ranks)
            end
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function worldbossrank.rewardReload(self)
    
    local time = gamedata:time()
    
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("worldbossrank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    print("i...rewardReload:")
    -- printT(gamedata.config.boss2_rewards)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 264)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("worldboss2/cell_n_worldboss_jiangliyulan", nil, true, "cell_n_worldboss_jiangliyulan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local configname = ""
            if self.selectpage and self.selectpage == "onepage" then
                configname = "boss2_rewards1"
            else
                configname = "boss2_rewards2"
            end
            print("item========")
            printT(gamedata.config[configname])
            local configTem = gamedata.config[configname][tostring(a1+1)]

            if (a1+1) == 1 then
                ccbDocumentControler.rankLabel:setVisible(false)
                ccbDocumentControler.rankText:setVisible(false)
                ccbDocumentControler.killerText:setVisible(true)
            else
                ccbDocumentControler.killerText:setVisible(false)
                ccbDocumentControler.rankLabel:setVisible(true)
                ccbDocumentControler.rankText:setVisible(true)
            end

            ccbDocumentControler.rankLabel:setVisible(false)
            local levelstring = "伤害第 "..configTem.rank.." 名"
            if (a1+1) > 4 then
                local oldconfigTem = gamedata.config[configname][tostring(a1)]
                levelstring = "伤害第 "..(oldconfigTem.rank+1).."~"..configTem.rank.." 名"
                
            end

            ccbDocumentControler.rankText:setString(levelstring)

            local otherReward = ""
            if configTem["begin"] and configTem["begin"]~= "" and configTem["end"] and configTem["end"]~= ""  then
                local now =  time or 1 --GameScene.roleinfo.servertime
                local b_year,b_month,b_day,b_hour,b_minute,b_second = self:getDate(configTem["begin"])
                local e_year,e_month,e_day,e_hour,e_minute,e_second = self:getDate(configTem["end"])
                local begint = os.time({year=tonumber(b_year), month=tonumber(b_month),day=tonumber(b_day),hour=tonumber(b_hour),min=tonumber(b_minute),sec=tonumber(b_second)})
                local endt = os.time({year=tonumber(e_year), month=tonumber(e_month),day=tonumber(e_day),hour=tonumber(e_hour),min=tonumber(e_minute),sec=tonumber(e_second)})
                print("now"..now)
                print("begint"..begint)
                print("endt"..endt)
                if now>= begint and  now< endt then
                  --在时间范围内返回true
                  print("在时间范围内")
                   otherReward = configTem.additional_drop or ""
                end
            end   
            print("otherReward:"..otherReward)

            local prop = ui.getIDandNUMs(otherReward..configTem.reward)
            print("i...am..prop")
            printT(prop)


            for i=1,4 do
                -- if ccbDocumentControler["ccbitem"..i] then
                    if i < #prop or i == #prop then
                        ccbDocumentControler["ccbitem"..i]:setVisible(true)
                        print("key=",i)
                        printT(prop[tonumber(i)])
                        ui.setNewIcon(ccbDocumentControler,prop[tonumber(i)],i-1)

                        print("out a1: "..a1+1)
                        print("out i:"..i)
                    else
                        ccbDocumentControler["ccbitem"..i]:setVisible(false)
                    end

                    local _key = ui.getKey(i)

                    local _cb = function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                        print("cid-=-",prop[tonumber(i)].cid)
                        ui.setPopwindowByCid(prop[tonumber(i)].cid)
                    end

                    ui.commonBtn(self, ccbDocumentControler, "i_button".._key, _cb, self.touchPriority - 2,false)
                -- end
            end



            

            print("i...am..prop2")
            printT(ccbDocumentControler)

            cellCCB:setPosition(920/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                local configname = ""
                if self.selectpage and self.selectpage == "onepage" then
                    configname = "boss2_rewards1"
                else
                    configname = "boss2_rewards2"
                end

                r = table.getTableLength(gamedata.config[configname])
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.rewardListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.rewardListTableView)
    self.rewardListTableView:setTouchPriority(self.touchPriority-1)
end

function worldbossrank.getDate(self,date)
    print("date:"..date)
    return string.sub(date,1,4),string.sub(date,5,6),string.sub(date,7,8),string.sub(date,9,10),string.sub(date,11,12),string.sub(date,13,14)
end

function worldbossrank.close(self)
    gameTouch:UnrigistFunc("begin","worldbossrank")
    gameTouch:UnrigistFunc("end","worldbossrank")    
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.ListTableView = nil
    self.rewardListTableView = nil

    if self.callback then
        self.callback()
    end
end

return worldbossrank