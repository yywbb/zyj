--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/6
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local recharge = {
    rootNode = nil,
    rootItems = nil,
    listview = nil,
    pageconfig = {"info","vip","status"},
    pagetype = "info",
    isscrolltouched = false,

}

function recharge.open(self,touchPriority,data,callback)

    self.root = ui.createNode()

    self.touchPriority = touchPriority
    self:reload(data,callback)

    self.needanimation = true

    return self.root,true
end

function recharge.reload(self,data,callback)
    self.callback = callback
    self.data = data or {}

    self.pagetype = data.pagetype or self.pagetype

    --self:showPage(self.pagetype)
    UIRequest({type = 117})
end

function recharge.reloaddata(self,data)

    self.data = data or {}
    self.pagetype = data.pagetype or self.pagetype
    self:showPage(self.pagetype)

    if self.pagetype == "info" and self.needanimation then
        local animationManager = getAnimationManager(self.infoItems)
        animationManager:runAnimationsForSequenceNamed("play")
        self.needanimation = false
    end
end

function recharge.reloadstatus(self,data)
    self.status = data or {}
    if self.listview and self.pagetype == "info" then
        self.listview:reloadData()
    end

    if self.pagetype == "status" then
        self:setPage_status()
    end

end

function recharge.close(self)
    gameTouch:UnrigistFunc("begin","recharge")
    gameTouch:UnrigistFunc("end","recharge")    
    self.isscrolltouched = false     
    self.listview = nil
    self.pagetype = "info"
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function recharge.showPage(self,type)
    self.pagetype = type

    if self.pagetype == "info" then
        self.rootNode, self.infoItems = CCBReaderLoad("recharge/window_recharge_new", nil, true, "window_recharge_new")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        local function touchbegin(pos)
            self.isscrolltouched = false
        end
        gameTouch:rigistFunc("begin","recharge",touchbegin)
        local function touchend(pos)
            if self.infoItems.scroll and ui.isTouched(self.infoItems.scroll,pos.x,pos.y) then
                self.isscrolltouched = true
            end
        end
        gameTouch:rigistFunc("end","recharge",touchend)
        self:setPage_info()
    elseif self.pagetype == "vip" then
        self.rootNode, self.vipItems = CCBReaderLoad("recharge/window_recharge_vip_new", nil, true, "window_recharge_vip_new")
        self.root:removeAllChildrenWithCleanup(true)
        gameTouch:UnrigistFunc("begin","recharge")
        gameTouch:UnrigistFunc("end","recharge")    
        self.isscrolltouched = false        
        self.root:addChild(self.rootNode)
        self:setPage_vip()
    elseif self.pagetype == "status" then
        self.rootNode, self.statusItems = CCBReaderLoad("recharge/window_recharge_status", nil, true, "window_recharge_status")
        self.root:removeAllChildrenWithCleanup(true)
        gameTouch:UnrigistFunc("begin","recharge")
        gameTouch:UnrigistFunc("end","recharge")    
        self.isscrolltouched = false        
        self.root:addChild(self.rootNode)
        self:setPage_status()
    end

end


function recharge.setPage_info(self)

    --self.recharge = gamedata.config.recharge
    --
    self.recharge = {}
    for k,v in pairs(gamedata.config.recharge) do
        if (not v.show) or (v.show == 1) then
            if (v.id == 9) and (gamedata.device.platform == "ios") then
                --ios没有1元档
            else
                if not v.seq then
                    v.seq = v.id 
                end
                table.insert(self.recharge,v)
            end
        end
           
    end
    local sortfunc = function (a,b)
        return a.seq < b.seq
    end
    table.sort(self.recharge,sortfunc)
    --

    -- ui.setLabelString(self.infoItems.doLab,gameConfig.strings:string_common("popups","lookPriv"),18)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("recharge")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    self.infoItems.rechargeStatusNode:setVisible(gameConfig:checkBuildOpen(590))
    self.infoItems.statusButton:addHandleOfControlEvent(function()
        self:showPage("status")
    end, CCControlEventTouchUpInside)
    self.infoItems.statusButton:setSwallowsTouch(true)
    self.infoItems.statusButton:setTouchPriority(self.touchPriority)

    self.infoItems.doButton:addHandleOfControlEvent(function()
        if gameConfig:checkBuildOpen(154) then
            self:showPage("vip")
        end
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton:setSwallowsTouch(true)
    self.infoItems.doButton:setTouchPriority(self.touchPriority)

    if not gameConfig:checkBuildOpen(154) then
        self.infoItems.vipnode:setVisible(false)
    end

    --

    printT(self.data)
    setSpriteFrameByName(self.infoItems.selfvip, "b_n_vip_"..self.data.vip)

    if self.data.rmb < self.data.nextrmb then
        -- self.infoItems.goldneed:setString((self.data.nextrmb-self.data.rmb).."元")
        self.infoItems.goldneed:setString(gameConfig.strings:money((self.data.nextrmb-self.data.rmb)))
        self.infoItems.vipnext:setString("贵族"..(self.data.vip+1))
        ui.setSpriteTextureRect2(self.infoItems.process,0,0,501 * self.data.rmb / self.data.nextrmb,42)

        ui.setLabelString(self.infoItems.exp,self.data.rmb.."/"..self.data.nextrmb,13)
    else
        -- self.infoItems.goldneed:setString("0元")
        self.infoItems.goldneed:setString(gameConfig.strings:string_common("popups","yuan"))
        self.infoItems.vipnext:setString("贵族"..(self.data.vip))
        ui.setSpriteTextureRect2(self.infoItems.process,0,0,501,42)

        ui.setLabelString(self.infoItems.exp,self.data.rmb.."/"..self.data.nextrmb,13)
    end


    self:createlist()

    UIRequest({type = 2099})
end

function recharge.createlist(self)

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(810, 190)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("recharge/cell_recharge_info_new", nil, true, "cell_recharge_info_new")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local data = self.recharge[a1+1] or self.recharge[tostring(a1+1)]

            if self.status and self.status[tostring(data.id)] == 0 and data.isdouble ~= 0 then
                ccbDocumentControler.isfirst:setVisible(true)
                ccbDocumentControler.desc1:setVisible(true)

                setSpriteFrameByName(ccbDocumentControler.isfirst, data.isdouble ==2 and "obj_double" or "obj_triple")
            else
                ccbDocumentControler.isfirst:setVisible(false)
                ccbDocumentControler.desc1:setVisible(false)
            end
            ui.setNewIcon(ccbDocumentControler,{cid = 1001})

            if ccbDocumentControler.giftButton1 and ccbDocumentControler.giftButton2 then
                ccbDocumentControler.giftButton1:setVisible(false)   
                ccbDocumentControler.giftButton2:setVisible(false)  
            end    

            if data.id > 2 then

--                if data.id and data.id <= 8 then
--                    setSpriteFrameByName(ccbDocumentControler.i_icon, data.id-2 == 2 and "propgold" or "yuanbao"..data.id-2)
--                else
--                    setSpriteFrameByName(ccbDocumentControler.i_icon, "propgold")
--                end
                -- ccbDocumentControler.rmb:setString(data.rmb.."元")
                ccbDocumentControler.rmb:setString(gameConfig.strings:money(data.rmb))
                ccbDocumentControler.name_gold:setString((data.rmb*10))
                ccbDocumentControler.name_ka:setString("")
                -- ccbDocumentControler.desc:setString("充值可得"..(data.rmb*10).."元宝，另送"..(data.gold-data.rmb*10).."元宝")
                --ccbDocumentControler.desc1:setString("(送"..(data.gold*2).."元宝)")
                ccbDocumentControler.desc:setString(gameConfig.strings:changeGold((data.rmb*10),(data.gold-data.rmb*10)))
                ccbDocumentControler.desc1:setString(gameConfig.strings:sendGold((data.gold*(data.isdouble-1))))
                ui.setLabelString(ccbDocumentControler.name_gold,nil,21)
                ui.setLabelString(ccbDocumentControler.rmb,nil,48)

            else
                --setSpriteFrameByName(ccbDocumentControler.i_icon, a1+1 ==2 and "obj_yueka_big" or "obj_yueka_small")
                -- ccbDocumentControler.rmb:setString(data.rmb.."元")
                ccbDocumentControler.rmb:setString(gameConfig.strings:money(data.rmb))
                ccbDocumentControler.name_gold:setString("")
                ccbDocumentControler.name_ka:setString(data.id ==2 and tostring(data.gold) or (data.rmb*10+data.daygold*30))
                ccbDocumentControler.desc:setString("立即获得"..(data.rmb*10).."元宝，"..(data.id ==2 and "永久" or "连续30天").."每天可领取"..data.daygold.."元宝")


                ccbDocumentControler.desc1:setString(data.id ==2 and (gameConfig:checkBuildOpen(165) and "(高级月卡)" or "(终身卡)") or "(月卡)")
                ccbDocumentControler.desc1:setVisible(true)
                ui.setLabelString(ccbDocumentControler.name_gold,nil,21)
                ui.setLabelString(ccbDocumentControler.rmb,nil,48)

                if (data.id == 1) and ccbDocumentControler.giftButton1 and gamedata.config.recharge["1"] and gamedata.config.recharge["1"].daygift then
                    local gift1 = ui.getIDandNUMs(gamedata.config.recharge["1"].daygift) or {}
                    if gamedata.config.recharge["1"].daygold and gamedata.config.recharge["1"].daygold > 0 then
                        table.insert(gift1,{cid = 1001,num = gamedata.config.recharge["1"].daygold})
                    end
                    ccbDocumentControler.giftButton1:setTouchPriority(self.touchPriority-1)
                    ccbDocumentControler.giftButton1:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                        gameWindows:openWindow("getStaff",{data = gift1,type = "超值礼包"},nil)
                    end, CCControlEventTouchUpInside)
                    ccbDocumentControler.giftButton1:setVisible(true) 
                end
                --    
                if (data.id == 2) and ccbDocumentControler.giftButton2 and gamedata.config.recharge["2"] and gamedata.config.recharge["2"].daygift then
                    local gift2 = ui.getIDandNUMs(gamedata.config.recharge["2"].daygift) or {}
                    if gamedata.config.recharge["2"].daygold and gamedata.config.recharge["2"].daygold > 0 then
                        table.insert(gift2,{cid = 1001,num = gamedata.config.recharge["2"].daygold})
                    end
                    ccbDocumentControler.giftButton2:setTouchPriority(self.touchPriority-1)
                    ccbDocumentControler.giftButton2:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                        gameWindows:openWindow("getStaff",{data = gift2,type = "豪华礼包"},nil)
                    end, CCControlEventTouchUpInside)
                    ccbDocumentControler.giftButton2:setVisible(true) 
                end   

            end
            -- todo
            if data.desc and data.desc ~= "" then
                ccbDocumentControler.desc:setString(data.desc)
            end
            if data.icon and data.icon ~= "" then
                local icon = (data.icon == "obj_yueka_big" and gameConfig:checkBuildOpen(165)) and "obj_yueka_big_" or data.icon
                setSpriteFrameByName(ccbDocumentControler.i_icon,icon)
            end
            --
            if data.id ==2 and self.monthcard and self.monthcard["2"].restday>0 then
                ui.addGray("CCControlButton",ccbDocumentControler.doButton)
                ui.setLabelString(ccbDocumentControler.doLab,"已购买",18)
                ccbDocumentControler.doButton:setTouchPriority(self.touchPriority-1)
                ccbDocumentControler.doButton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    runGamePrompt({msg = "已购买"})
                end, CCControlEventTouchUpInside)
            else
                ui.removeGray("CCControlButton",ccbDocumentControler.doButton)
                -- ccbDocumentControler.doLab:setString("充 值")
                ccbDocumentControler.doLab:setString(gameConfig.strings:string_common("popups","change"))
                ui.setLabelString(ccbDocumentControler.doLab,nil,18)
                ccbDocumentControler.doButton:setTouchPriority(self.touchPriority-1)
                ccbDocumentControler.doButton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    print("idCardStatus",gamedata.sdk.idCardStatus)
                    if gameConfig:checkBuildOpen(364) and gamedata.sdk.idCardStatus then 
                        if gamedata.sdk.idCardStatus==0 then
                            gameWindows:openWindow("shiming",{page = "renzheng"})
                            return
                        elseif gamedata.sdk.idCardStatus == 1 then
                            if  RechargeLimit(data.rmb) then
                                return
                            end
                        end
                    end
                    if sdk:isValid() then
                        UIRequest({type = 115, cid = data.id})
                        gamedata.music:PlayOptSound("czcg")
                    else
                        -- runGamePrompt({msg = "未接入充值渠道"})
                        runGamePrompt({msg = gameConfig.strings:string_common("popups","change_qudao")})
                    end

                end, CCControlEventTouchUpInside)
            end

            cellCCB:setPosition(810/2+10, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.recharge)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.infoItems.scroll:getContentSize().width,
        viewheight = self.infoItems.scroll:getContentSize().height,
        dire = 1
    })
    self.infoItems.scroll:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)

end

function recharge.setPage_vip(self)

    -- self.vipItems.doLab:setString("充 值")
    self.vipItems.doLab:setString(gameConfig.strings:string_common("popups","change"))
    ui.setLabelString(self.vipItems.doLab,nil,18)

    self.vipItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("recharge")
    end, CCControlEventTouchUpInside)
    self.vipItems.closeButton:setSwallowsTouch(true)
    self.vipItems.closeButton:setTouchPriority(self.touchPriority)

    self.vipItems.doButton:addHandleOfControlEvent(function()
        self:showPage("info")
    end, CCControlEventTouchUpInside)
    self.vipItems.doButton:setSwallowsTouch(true)
    self.vipItems.doButton:setTouchPriority(self.touchPriority)

    --

    -- setSpriteFrameByName(self.vipItems.selfvip, "b_n_vip_"..self.data.vip)

    -- if self.data.rmb < self.data.nextrmb then
    --     -- self.vipItems.goldneed:setString((self.data.nextrmb-self.data.rmb).."元")
    --     self.vipItems.goldneed:setString(gameConfig.strings:money((self.data.nextrmb-self.data.rmb)))
    --     self.vipItems.vipnext:setString("VIP"..(self.data.vip+1))
    --     ui.setSpriteTextureRect2(self.vipItems.process,0,0,415 * self.data.rmb / self.data.nextrmb,37)
    --     self.vipItems.exp:setString(self.data.rmb.."/"..self.data.nextrmb)
    --     ui.setLabelString(self.vipItems.exp,nil,13)
    -- else
    --     -- self.vipItems.goldneed:setString("0元")
    --     self.vipItems.goldneed:setString(gameConfig.strings:string_common("popups","yuan"))
    --     self.vipItems.vipnext:setString("VIP"..(self.data.vip))
    --     ui.setSpriteTextureRect2(self.vipItems.process,0,0,415,37)
    --     self.vipItems.exp:setString("Max")
    --     ui.setLabelString(self.vipItems.exp,nil,13)
    -- end

    local vipindex = self.data.vip
    if vipindex < 1 then vipindex = 1 end
    self:setVipBag(vipindex)
    self.vipItems.forward:addHandleOfControlEvent(function()
        if vipindex < (table.getTableLength(gamedata.config.vip)-1) then
            vipindex = vipindex + 1
            self:setVipBag(vipindex)
        end
    end, CCControlEventTouchUpInside)
    self.vipItems.forward:setSwallowsTouch(true)
    self.vipItems.forward:setTouchPriority(self.touchPriority)

    self.vipItems.back:addHandleOfControlEvent(function()
        if vipindex > 1 then
            vipindex = vipindex - 1
            self:setVipBag(vipindex)
        end
    end, CCControlEventTouchUpInside)
    self.vipItems.back:setSwallowsTouch(true)
    self.vipItems.back:setTouchPriority(self.touchPriority)

end

function recharge.setVipBag(self,index)

    -- self.vipItems.VipBagTitle:setString("VIP"..index.."尊享礼包")
    -- self.vipItems.title:setString("VIP"..index.."特权")
    self.vipItems.VipBagTitle:setString(gameConfig.strings:vipPage(index))
    ui.setLabelString(self.vipItems.title,gameConfig.strings:vipTq(index),21)

    self:initRichLable(index)

    local bagcid = gamedata.config.vip[tostring(index)].gift
    local idnums = ui.getIDandNUMs(gamedata.config.props[tostring(bagcid)].param2)

    for i=1, 4 do
        self.vipItems["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
            if idnums[i] then
                ui.setPopwindowByCid(idnums[i].cid)
            end
        end, CCControlEventTouchUpInside)
        self.vipItems["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority)  
              
        if not idnums[i] then
            self.vipItems["bagnode"..i]:setVisible(false)
        else
            self.vipItems["bagnode"..i]:setVisible(true)
            ui.setNewIcon(self.vipItems,{cid = idnums[i].cid, num = idnums[i].num},i-1)
            --
            -- local config = ui.IDconfig(idnums[i].cid)
            -- self.vipItems["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
            --     ui.setPopwindowByCid(idnums[i].cid)
            -- end, CCControlEventTouchUpInside)
            -- self.vipItems["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority)
            --
        end
    end

    if self.vipItems.gotoNode then
        ui.setLabelString(self.vipItems.gotoLab,nil,18)
        if self.data.vip < index then
            self.vipItems.hasbuynode:setVisible(false)
            self.vipItems.gotoNode:setVisible(true)
            self.vipItems["gotoButton"]:addHandleOfControlEvent(function()
                runGamePrompt({msg = "贵族"..index.."以上可购买该礼包"})
            end, CCControlEventTouchUpInside)
            self.vipItems["gotoButton"]:setTouchPriority(self.touchPriority)  
            ui.addGray("CCControlButton",self.vipItems["gotoButton"])
        elseif GameScene.giftbags and GameScene.giftbags[tostring(bagcid)] then
            self.vipItems.hasbuynode:setVisible(false)
            self.vipItems.gotoNode:setVisible(true)
            self.vipItems["gotoButton"]:addHandleOfControlEvent(function()
                GameScene:shiftLayerById(42)
            end, CCControlEventTouchUpInside)
            self.vipItems["gotoButton"]:setTouchPriority(self.touchPriority)  
            ui.removeGray("CCControlButton",self.vipItems["gotoButton"])
        elseif GameScene.giftbags then    
            self.vipItems.hasbuynode:setVisible(true)
            self.vipItems.gotoNode:setVisible(false)
            self.vipItems["gotoButton"]:addHandleOfControlEvent(function()
                runGamePrompt({msg = "已购买该礼包"})
            end, CCControlEventTouchUpInside)
            self.vipItems["gotoButton"]:setTouchPriority(self.touchPriority)  
            ui.addGray("CCControlButton",self.vipItems["gotoButton"])
        else
            self.vipItems.hasbuynode:setVisible(false)
            self.vipItems.gotoNode:setVisible(false)
            self.vipItems["gotoButton"]:addHandleOfControlEvent(function()
                --
            end, CCControlEventTouchUpInside)
            self.vipItems["gotoButton"]:setTouchPriority(self.touchPriority)  
            ui.addGray("CCControlButton",self.vipItems["gotoButton"])
        end    
    end

end


function recharge.setPage_status(self)
    self.statusItems.doLab:setString(gameConfig.strings:string_common("popups","change"))
    ui.setLabelString(self.statusItems.doLab,nil,18)

    self.statusItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("recharge")
    end, CCControlEventTouchUpInside)
    self.statusItems.closeButton:setSwallowsTouch(true)
    self.statusItems.closeButton:setTouchPriority(self.touchPriority)

    self.statusItems.doButton:addHandleOfControlEvent(function()
        self:showPage("info")
    end, CCControlEventTouchUpInside)
    self.statusItems.doButton:setSwallowsTouch(true)
    self.statusItems.doButton:setTouchPriority(self.touchPriority)

    for i=3,8 do
        if self.status and self.status[tostring(i)] and self.status[tostring(i)] == 1 then
            self.statusItems["lb_status"..(i-2)]:setString("已完成")
            self.statusItems["lb_status"..(i-2)]:setColor(ccc3(81, 147, 51))
        else
            self.statusItems["lb_status"..(i-2)]:setString("未完成")
            self.statusItems["lb_status"..(i-2)]:setColor(ccc3(93, 93, 93))
        end
    end

end

function recharge.initRichLable(self, index)
    local _size = 0
    local _intro = nil
    
    -- if self.config["text_type"] == 1 then
    --     _intro = LoadJsonStringToTable(self.config.intro)
    -- else
        _intro = {[1] = {fontID = 1002, content = gamedata.config.vip[tostring(index)].desc or ""},}
    -- end

    _size = ui.createRichLabel(_intro, self.vipItems.tempNode, false, {horizontal = "left", vertical = "top"})

    self.vipItems.tempNode:removeAllChildrenWithCleanup(ture)
    self.vipItems.container:setContentSize(CCSize(750, _size))
    self.vipItems.scrollNode = tolua.cast(self.vipItems.scrollNode, "CCScrollView")
    self.vipItems.scrollNode:setTouchPriority(self.touchPriority - 500)
    self.vipItems.scrollNode:setViewSize(CCSizeMake(750, 500))
    self.vipItems.scrollNode:setContentOffsetInDuration(ccp(0, -_size + 500), 0)

    ui.createRichLabel(_intro, self.vipItems.container, false, {horizontal = "left", vertical = "top"})
end


return recharge