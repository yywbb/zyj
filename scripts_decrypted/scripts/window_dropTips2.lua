--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/7/24
-- Time: 上午10:32
-- To change this template use File | Settings | File Templates.
--


local drop = {
    rootNode = nil,
    rootItems = nil,

    root = nil,

    listview = nil

}

function drop.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/tc_huodetujing", nil, true, "tc_huodetujing")

    self.touchPriority = touchPriority
    self.data = data
    print("drop==-=")
    -- printT(self.data)

    if  self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindow("dropTips")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    self:reload(data,callback)
    return self.rootNode
end

function drop.createlist(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 170)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tanchuang/cell_huoqutujing", nil, true, "cell_huoqutujing")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.configsort[a1+1]

            ui.setLabelString(ccbDocumentControler.titleLabel,celldata.title,21)
            ccbDocumentControler.desLabel:setString(celldata.desc)

            if celldata.systemid and celldata.systemid ~= 0 then
                local isopen = true
                local buildconfig = gamedata.config.build[tostring(celldata.systemid)]

                if buildconfig.level > GameScene.roleinfo.level then
                    isopen = false
                    -- ccbDocumentControler.des:setString(buildconfig.level.."级开启")
                    ccbDocumentControler.des:setString(gameConfig.strings:lvOpen(buildconfig.level))
                else
                    if buildconfig.type == "copy_chapter" or  buildconfig.type == "copy_map" then
                        local map,point  = 0,0
                        if celldata.param and celldata.param ~= "" then
                            local i = string.find(celldata.param,",")
                            if i then
                                map,point = ui.getIDandNUM(celldata.param)
                            else
                                map = tonumber(celldata.param)
                            end
                        end
                        if celldata.systemid == 12 or celldata.systemid == 13 then
                            if not self.mapmaxN then
                                self.mapmaxN,self.pointmaxN = ui.getCopyProcess("normal")
                            end
                            isopen = ui.isCopyOpen(map,point,self.mapmaxN,self.pointmaxN)
                        elseif celldata.systemid == 15 or celldata.systemid == 16 then
                            if not self.mapmaxB then
                                self.mapmaxB,self.pointmaxB = ui.getCopyProcess("brave")
                            end
                            isopen = ui.isCopyOpen(map,point,self.mapmaxB,self.pointmaxB)
                        elseif celldata.systemid == 148 then
                            if not self.mapmaxS then
                                self.mapmaxS,self.pointmaxS = ui.getCopyProcess("star")
                            end
                            isopen = ui.isCopyOpen(map,point,self.mapmaxS,self.pointmaxS)
                        end
                        -- ccbDocumentControler.des:setString("未到达")
                        ccbDocumentControler.des:setString(gameConfig.strings:string_common("popups","weidadao"))
                    end
                end

                ccbDocumentControler.in_goto:setVisible(isopen)
                ccbDocumentControler.des:setVisible(not isopen)
                ccbDocumentControler.in_button:setSwallowsTouch(true)
                ccbDocumentControler.in_button:setTouchPriority(self.touchPriority-1)
                ccbDocumentControler.in_button:addHandleOfControlEvent(function()
                    GameScene:shiftLayerById(celldata.systemid,celldata.param)
                end, CCControlEventTouchUpInside)
            else
                ccbDocumentControler.in_goto:setVisible(false)
                ccbDocumentControler.des:setVisible(false)
            end

            cellCCB:setPosition(920/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.configsort)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end

function drop.reload(self,data,callback)
    self.callback = callback
    ui.setNewIconName(self.rootItems,{cid = data.cid})

    self.config = gamedata.config.drop[tostring(data.cid)]
    print("config=")
    -- printT(self.config)


    -- 设置拥有个数
    -- printT(data)
    if ui.IDconfig(data.cid) and ui.IDconfig(data.cid).staffType and (ui.IDconfig(data.cid).staffType == "general" or ui.IDconfig(data.cid).staffType == "championpoint" or ui.IDconfig(data.cid).staffType == "gangpoint" or ui.IDconfig(data.cid).staffType == "passkillcoin" or ui.IDconfig(data.cid).staffType == "point" or ui.IDconfig(data.cid).staffType == "xiandou" or ui.IDconfig(data.cid).staffType == "platformcurrency" or ui.IDconfig(data.cid).staffType == "qiling") then
        ui.setLabelString(self.rootItems.has,"",14)

    elseif not data.num then
        UIRequest({type = 12002, id = tonumber(data.cid)})
    else
        -- ui.setLabelString(self.rootItems.has,"当前拥有: "..data.num,14)
        ui.setLabelString(self.rootItems.has,gameConfig.strings:colNum(data.num),14)
    end
    

    ui.setLabelString(self.rootItems.get,nil,14)

    if self.config then
        self.mapmaxN,self.pointmaxN = getNormalCopyProcess()
        self.mapmaxB,self.pointmaxB = getBraveCopyProcess()
        self.mapmaxS,self.pointmaxS = getStarCopyProcess()
        print("getNormalCopyProcess=",getNormalCopyProcess())
        print("getBraveCopyProcess=",getBraveCopyProcess())
        print("getStarCopyProcess=",getStarCopyProcess())

        self.rootItems.des:setPosition(9999,365)
        self.rootItems.des:setVisible(false)
        -- ui.setLabelString(self.rootItems.des,droplist[1].param,18)

        --
        self.configsort = {}
        for k,v in pairs(self.config) do
            v.order = v.page
            local map,point  = 0,0
            if v.param and v.param ~= "" then
                local i = string.find(v.param,",")
                if i then
                    map,point = ui.getIDandNUM(v.param)
                else
                    map = tonumber(v.param)
                end
            end
            if v.systemid == 12 or v.systemid == 13 then
                if not self.mapmaxN then
                    self.mapmaxN,self.pointmaxN = ui.getCopyProcess("normal")
                end
                local isopen = ui.isCopyOpen(map,point,self.mapmaxN,self.pointmaxN)
                if not isopen then
                    v.order = 1000-v.order
                elseif not ui.hasCopyChallenge("normal",map,point) then
                    v.order = 500-v.order
                end
            elseif v.systemid == 15 or v.systemid == 16 then
                if not self.mapmaxB then
                    self.mapmaxB,self.pointmaxB = ui.getCopyProcess("brave")
                end
                local isopen = ui.isCopyOpen(map,point,self.mapmaxB,self.pointmaxB)
                if not isopen then
                    v.order = 1000-v.order
                end
            elseif v.systemid == 148 then
                if not self.mapmaxS then
                    self.mapmaxS,self.pointmaxS = ui.getCopyProcess("star")
                end
                local isopen = ui.isCopyOpen(map,point,self.mapmaxS,self.pointmaxS)
                if not isopen then
                    v.order = 1000-v.order
                end
            end
            table.insert(self.configsort,v)
            local sortfunc = function (a,b)
                return a.order < b.order
            end
            table.sort(self.configsort,sortfunc)

        end



        --
        if self.listview then
            self.listview:reloadData()
        else
            self:createlist()
        end

    else
        self.rootItems.des:setVisible(true)
        ui.setLabelString(self.rootItems.des,nil,18)
        -- runGamePrompt({msg = "掉落配置出错！"})
        --runGamePrompt({msg = gameConfig.strings:string_common("popups","dlpp")})
    end

end

function drop.setOwnNum(self,data)
    ui.setLabelString(self.rootItems.has,gameConfig.strings:colNum(data.num or 0),14)
end

function drop.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.listview = nil
    self.mapmaxN = nil
    self.pointmaxN = nil
    self.mapmaxB = nil
    self.pointmaxB = nil

    if self.callback then
        self.callback()
    end
end

return drop  �'  