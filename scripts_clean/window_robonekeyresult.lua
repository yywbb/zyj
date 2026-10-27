--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local robonekeyresult = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,

    enemy = {},
    cid = 0,
    has_energy = 0,

    isend = false,

    robdata = {},

    energy = 0,
    get = {},
    otherreward = {},

    changeCoin = false,
    changeGold = false,

    isautoxh =  0,
    losscid =  {},

    quality1 = {color = ccc3(249,202,153), size = 2,},    -- quality1
    quality2 = {color = ccc3(93, 227,90 ), size = 2,},    -- quality2
    quality3 = {color = ccc3(121,203,255), size = 2,},   -- quality3
    quality4 = {color = ccc3(226,111,255), size = 2,},    -- quality4
    quality5 = {color = ccc3(255,132,0  ), size = 2,},     -- quality5
    quality6 = {color = ccc3(255,132,0  ), size = 2,},     -- quality6

    quality0 = {color = ccc3(255,211,159  ), size = 2,},     -- quality0


}

function robonekeyresult.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

   
    self.isautoxh = data.isautoXH or false
    self.losscid =  data.losscid or {}
    self.name = data.name or ""

    -- print("isautoxh:"..self.isautoxh)
    printT(self.losscid,"losscid")


    self.rootNode, self.rootItems = CCBReaderLoad("rub/rub_autotenjieguo.ccbi", nil, true, "rub_autotenjieguo")
    self.root:addChild(self.rootNode)

    self.isend = false
    self.robdata = {}
    --self:createList()


    
    self.rootItems.stopNode:setVisible(false)


    ui.setLabelString(self.rootItems.lookRewardBtn_Text,"关闭")
    self.rootItems["lookRewardBtn"]:addHandleOfControlEvent(function()
        --
        if self.otherreward and next(self.otherreward) then 
            showRewardPopupWindow(self.otherreward,nil)
        end
        gameWindows:closeWindowDirect("robonekeyresult")

    end, CCControlEventTouchUpInside)
    self.rootItems["lookRewardBtn"]:setSwallowsTouch(true)
    self.rootItems["lookRewardBtn"]:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.rewardDesc,"",1)


    return self.root,true
end


function robonekeyresult.Reload(self,data)

    self.rewards =  data.rewards or {}
    self.energy = self.energy + data.energy

    self.otherreward = data.otherreward or {}

    self.energy1 = data.energy1
    self.energy2 = data.energy2

    local getcid = 0
    for k,w in pairs(data.get) do
        -- print("get w",w.cid)
        for i,v in ipairs(self.losscid) do
             -- print("loss v",v)
            if w.cid == v  then
                getcid =  getcid+1
            end    
        end
    end
     -- print("getcid ",getcid)
    local losslength = table.getTableLength(self.losscid)
    if getcid >= losslength then
        self.isend = true
    end    

    self.rootItems.stopNode:setVisible(false)
    self.rootItems.lookRewardNode:setVisible(true)
    --
    for i = 1,data.energy do
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5*(i-1)),CCCallFunc:create(function()
            
            table.insert(self.robdata,{coin = self.rewards[tostring(i)] and self.rewards[tostring(i)].coin or 0,rob = self.rewards[tostring(i)] and self.rewards[tostring(i)].rob or 0, get = self.rewards[tostring(i)] and self.rewards[tostring(i)].get or {}, otherreward = self.rewards[tostring(i)] and self.rewards[tostring(i)].otherreward or {} })

            if self.ListTableView then
                self.ListTableView:reloadData()
                self.ListTableView:setLuaContentOffset(0,(self.rootItems.listScroll:getContentSize().height > table.getTableLength(self.robdata)*280) and (self.rootItems.listScroll:getContentSize().height - table.getTableLength(self.robdata)*280) or 0)
            else
                self:createList()
            end

            if i == data.energy then
                if self.isend then
                    self.rootItems.stopNode:setVisible(false)
                    self.rootItems.lookRewardNode:setVisible(true)
                    self.rootItems.rewardDescNode:setVisible(true)
                    -- runGamePrompt({msg = "所有碎片拿到 一键挑战终止"})   
                    self.rootItems.rewardDesc:setString("剩余大精力丹:"..self.energy1.." 精力丹:"..self.energy2)
                    self.rootItems.lookRewardBtn_desc:setString("恭喜您成功获得"..self.name.."全部碎片")
                else
                    self.rootItems.stopNode:setVisible(false)
                    self.rootItems.lookRewardNode:setVisible(true)
                    self.rootItems.rewardDescNode:setVisible(true)
                    self.rootItems.rewardDesc:setString("剩余大精力丹:"..self.energy1.." 精力丹:"..self.energy2)
                    self.rootItems.lookRewardBtn_desc:setString("您的精力值不足，无法继续挑战")
                    -- runGamePrompt({msg = "精力耗尽，一键挑战终止！"})
                end
                -- ui.setLabelString(self.rootItems.lookRewardBtn_Text,"查看奖励")
            end

        end)))
    end


end

function robonekeyresult.createList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 280)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("rub/cell_tenjiesuan2", nil, true, "cell_tenjiesuan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            --
            if self.robdata[(a1+1)] and self.robdata[(a1+1)].rob > 0 then
                setSpriteFrameByName(ccbDocumentControler.getCoinTenSprite, "duobaobi")
                ui.setLabelString(ccbDocumentControler.getCoinNumLabel,self.robdata[(a1+1)].rob or 0,13)
            else
                setSpriteFrameByName(ccbDocumentControler.getCoinTenSprite, "propcoin")
                ui.setLabelString(ccbDocumentControler.getCoinNumLabel,self.robdata[(a1+1)].coin or 0,13)
                self.changeCoin = true
            end
            -- printT(self.robdata[(a1+1)],"robdata-"..(a1+1))

            local isget = false
            if self.robdata[(a1+1)] and self.robdata[(a1+1)].get  and table.getTableLength(self.robdata[(a1+1)].get)>0 then
                 -- print("get---------")
                 isget = true
                 ccbDocumentControler.rewardUpName:setColor(self["quality0"].color)

                 if  self.robdata[(a1+1)].get and self.robdata[(a1+1)].get["1"] then
                    local other = self.robdata[(a1+1)].get["1"].cid or 0

                    local quality = self.robdata[(a1+1)].get["1"].quality or 1

                     local props = gamedata.config.treasure2_fragment[tostring(other)] or {}
                     local name =  props.name or ""
                     if name ~= "" then
                        ccbDocumentControler.gongxiTxt:setVisible(true)
                        ccbDocumentControler.rewardUpName:setVisible(true)
                        ccbDocumentControler.rewardUpName:setString(name)
                        for i,v in ipairs(self.losscid) do
                            if other == v  then
                                ccbDocumentControler.rewardUpName:setColor(self["quality"..quality].color)
                            end    
                        end
                    else    
                        ccbDocumentControler.gongxiTxt:setVisible(false)
                        ccbDocumentControler.rewardUpName:setVisible(false)
                    end    
                end  

                if self.robdata[(a1+1)] and self.robdata[(a1+1)].otherreward and  table.getTableLength(self.robdata[(a1+1)].otherreward)>0 then
                    if  self.robdata[(a1+1)].otherreward and self.robdata[(a1+1)].otherreward["1"] then
                        local other = self.robdata[(a1+1)].otherreward["1"].cid or 0
                        print("other:"..other)
                    end
                end    


            end

            if self.robdata[(a1+1)] and self.robdata[(a1+1)].otherreward and  table.getTableLength(self.robdata[(a1+1)].otherreward)>0 then
                -- print("otherreward---------")
                ccbDocumentControler.rewardUpName2:setColor(self["quality0"].color)

                if  self.robdata[(a1+1)].otherreward and self.robdata[(a1+1)].otherreward["1"] then
                    local other = self.robdata[(a1+1)].otherreward["1"].cid or 0
                    local props = gamedata.config.props[tostring(other)] or {}
                    local name =  props.name or ""
                    if name ~= "" then
                        ccbDocumentControler.rewardUpName2:setVisible(true)
                        ccbDocumentControler.rewardUpName2:setString(name)  
                    else    
                        local treasure2 = gamedata.config.treasure2_fragment[tostring(other)] or {}
                        name =  treasure2.name or ""
                        -- local quality = self.robdata[(a1+1)].otherreward["1"].quality or 0
                        if name ~= "" then
                            ccbDocumentControler.rewardUpName2:setVisible(true)
                            ccbDocumentControler.rewardUpName2:setString(name)
                            -- ccbDocumentControler.rewardUpName:setColor(self["quality"..quality].color)
                        else
                            ccbDocumentControler.rewardUpName2:setVisible(false)
                        end    
                       
                    end    

                    if not isget then
                        ccbDocumentControler.gongxiTxt:setVisible(false)
                        ccbDocumentControler.rewardUpName:setVisible(false)
                        ccbDocumentControler.weihuodeTxt:setVisible(true)

                    else
                        ccbDocumentControler.weihuodeTxt:setVisible(false)
    
                    end    
                end    
            else    
                ccbDocumentControler.weihuodeTxt:setVisible(true)
                ccbDocumentControler.gongxiTxt:setVisible(false)
                ccbDocumentControler.rewardUpName2:setVisible(false)
                ccbDocumentControler.rewardUpName:setVisible(false)
            end    

            -- local numString = "第"..(a1+1).."次"
            local numString = gameConfig.strings:numci(a1+1)
            ccbDocumentControler.lineNumLabel:setString(numString)


            cellCCB:setPosition(920/2,280/2)


            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.robdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listScroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function robonekeyresult.close(self)

    if self.changeCoin then
        GameScene:coin_effect(1,540,960,0.5)
    end    

    self.ListTableView = nil
    self.changeCoin = false
    self.changeGold = false
    self.get = {}
    self.otherreward = {}
    self.energy = 0
    self.has_energy = 0
    self.robdata = {}
    self.isend = false
    self.enemy = {}
    self.cid = 0
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    self.isautoXH = false
    self.losscid = {}

    if self.callback then
        self.callback()
    end
end

return robonekeyresult

