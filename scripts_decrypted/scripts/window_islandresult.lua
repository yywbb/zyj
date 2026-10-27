--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local islandresult = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    configdata = {},

    rewards = {
        [1] = {node=nil,item=nil,state = true},
        [2] = {node=nil,item=nil,state = true},
        [3] = {node=nil,item=nil,state = true},
    },
}

function islandresult.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.configdata = data.data

    print("i...am...islandresult")
    if data.index == "seccess" then
        self.rootNode, self.rootItems = CCBReaderLoad("island2/island_shengli.ccbi", nil, true, "island_shengli")
        self:seccessreload()
    elseif data.index == "fail" then
        self.rootNode, self.rootItems = CCBReaderLoad("island2/island_fuhuo.ccbi", nil, true, "island_fuhuo")
        self:failreload(data)
    elseif data.index == "choose" then
        self.rootNode, self.rootItems = CCBReaderLoad("island2/island_serch1.ccbi", nil, true, "island_serch1")
        self:choosereload()
    elseif data.index == "buffer" then
        self.rootNode, self.rootItems = CCBReaderLoad("island2/island_addbuff.ccbi", nil, true, "island_addbuff")
        self:bufferreload()
    elseif data.index == "ruleview" then
        self.rootNode, self.rootItems = CCBReaderLoad("island2/island_rule.ccbi", nil, true, "island_rule")
        self:rulereload()
    elseif data.index == "complete" then
        self.rootNode, self.rootItems = CCBReaderLoad("island2/tc_xiandaojiesuan.ccbi", nil, true, "tc_xiandaojiesuan")
        self:completereload()
    end
    
    self.root:addChild(self.rootNode)
    return self.root
end

function islandresult.completereload(self)
    ui.setLabelString(self.rootItems.pointtoday,self.configdata.island.PointDay,21)
    
    ui.setLabelString(self.rootItems.todaybuttontext,nil,19)
    self.rootItems.todayButton:setSwallowsTouch(true)
    self.rootItems.todayButton:setTouchPriority(self.touchPriority)
    self.rootItems.todayButton:addHandleOfControlEvent(function()
        print("i..am...todayButton..")
        
        gameWindows:closeWindowDirect("penglaiResult")
        -- GameScene:shiftLayer("daily","up")
    end, CCControlEventTouchUpInside)
end

function islandresult.rulereload(self)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        print("i..am...closeButton..")
        
        gameWindows:closeWindowDirect("penglaiResult")
    end, CCControlEventTouchUpInside)
    
end


function islandresult.choosereload(self)
    print("...i...am...choosereload.....")


    locationpointdata = self.configdata.island.mapStatus[tostring(self.configdata.island.location)]
    local tempdata = gamedata.config.penglai2_monster[tostring(locationpointdata.param)]

    -- printT(tempdata)
    local iddata = ui.IDconfig(tempdata.p1)
    print("didat")
    -- printT(iddata)


    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(iddata.generalid)].animationid)].name
    self.stepGneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    self.stepGneral:setAnimation("stand",true,0)
    self.stepGneral:setScale(2)
    self.rootNode:addChild(self.stepGneral)
    self.stepGneral:setPosition(260,500-80)


    ui.setLabelString(self.rootItems.oktext,nil,19) 
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)
    self.rootItems.okButton:addHandleOfControlEvent(function()
        print("i..am...okButton..")
        
        gameWindows:closeWindowDirect("penglaiResult")
        UIRequest({type = 2112 ,method=0})
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.conceltext,nil,19) 
    self.rootItems.concelButton:setSwallowsTouch(true)
    self.rootItems.concelButton:setTouchPriority(self.touchPriority)
    self.rootItems.concelButton:addHandleOfControlEvent(function()
        print("i..am...concelButton..")

        gameWindows:closeWindowDirect("penglaiResult")
        UIRequest({type = 2112 ,method=1})
    end, CCControlEventTouchUpInside)
end


function islandresult.failreload(self,data)
    print("...i...am...failreload.....")
    ui.setLabelString(self.rootItems.fuhuoText,nil,19) 
    self.rootItems.fuhuo_comfimBtn:setSwallowsTouch(true)
    self.rootItems.fuhuo_comfimBtn:setTouchPriority(self.touchPriority)
    self.rootItems.fuhuo_comfimBtn:addHandleOfControlEvent(function()
        print("i..am...fuhuo_comfimBtn..")
        
        gameWindows:closeWindowDirect("penglaiResult")
        UIRequest({type = 2112 ,method=0})
    end, CCControlEventTouchUpInside)

    
    ui.setLabelString(self.rootItems.fuhuo_cancleBtn_text,nil,19) 
    self.rootItems.fuhuo_cancleBtn:setSwallowsTouch(true)
    self.rootItems.fuhuo_cancleBtn:setTouchPriority(self.touchPriority)
    self.rootItems.fuhuo_cancleBtn:addHandleOfControlEvent(function()
        print("i..am...fuhuo_cancleBtn..")
        
        gameWindows:closeWindowDirect("penglaiResult")
    end, CCControlEventTouchUpInside)
end

function islandresult.seccessreload(self)
    ui.setLabelString(self.rootItems.desText,nil,19)
    -- printT(self.configdata)
    print("seccessreload+")
    local nowdata = self.configdata.island.mapStatus[tostring(self.configdata.island.location)]
    -- printT(nowdata)
    print("type = ",nowdata.type)
    -- printT(gamedata.config.penglai2_type)

    local typedata = gamedata.config.penglai2_type[tostring(nowdata.type)]
    -- self.rootItems.getpointNum:setString(typedata.point)
    ui.setLabelString(self.rootItems.getpointNum,typedata.point,23)
    self.rootItems.getpointNum:setScale(1.3)

    self:createList()

end

function islandresult.bufferreload( self )
    self.rootItems.bufferspend_Label:setString(gamedata.config.global_kv.penglai_buff.value)

    ui.setLabelString(self.rootItems.comfirmBtn_text,nil,19)
    self.rootItems.comfirmBtn:setSwallowsTouch(true)
    self.rootItems.comfirmBtn:setTouchPriority(self.touchPriority)
    self.rootItems.comfirmBtn:addHandleOfControlEvent(function()
        print("i..am...comfirmBtn..")
        
        UIRequest({type = 2112 ,method=1})
        gameWindows:closeWindowDirect("penglaiResult")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.cancleBtn_text,nil,19)
    self.rootItems.cancleBtn:setSwallowsTouch(true)
    self.rootItems.cancleBtn:setTouchPriority(self.touchPriority)
    self.rootItems.cancleBtn:addHandleOfControlEvent(function()
        print("i..am...cancleBtn..")
        
        UIRequest({type = 2112 ,method=0})
        gameWindows:closeWindowDirect("penglaiResult")
    end, CCControlEventTouchUpInside)
end

function islandresult.createList(self)
    print("createPropsList")
    -- printT(self.configdata)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 160)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("island2/cell_shengli", nil, true, "cell_shengli")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                -- ui.tableviewAnimation(self.ListTableView,cellCCB,920/2,0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local itemdata = gamedata.config.penglai2_next[tostring(a1+1)]
            -- printT(itemdata)

            local nowdata = self.configdata.island.mapStatus[tostring(self.configdata.island.location)]
            -- printT(nowdata)
            print("type = ",nowdata.type)
            -- printT(gamedata.config.penglai2_type)

            local typedata = gamedata.config.penglai2_type[tostring(nowdata.type)]

            print("wo.shi...")

            
            ui.setLabelString(ccbDocumentControler.itemcomfirm_text,nil,18)
            ccbDocumentControler.vipnumLabel:setString(itemdata.vip)
            ccbDocumentControler.timesNumLabel:setString(itemdata.ratio)
            ccbDocumentControler.timesNumLabel:setString(itemdata.ratio)

            local allPointNum = tonumber(itemdata.ratio) * tonumber(typedata.point) --self.configdata.getpoint
            ccbDocumentControler.allpointNumLabel:setString(allPointNum)

            print("price:",itemdata.price)
            if itemdata.price == "" then
                ccbDocumentControler.spendNode:setVisible(false)
                ccbDocumentControler.freeLabel:setVisible(true)

            else
                ccbDocumentControler.spendNode:setVisible(true)
                ccbDocumentControler.freeLabel:setVisible(false)

                local spenddata = ui.getIDandNUMs(itemdata.price)
                -- printT(spenddata)
                if spenddata[1].cid == 1000 then
                    ui.setLabelString(ccbDocumentControler.spendNum,spenddata[1].num,13)
                    -- ccbDocumentControler.spendNum:setString(spenddata[1].num)
                    setSpriteFrameByName(ccbDocumentControler.spendIcon, "obj_s_coin.png")
                    

                elseif spenddata[1].cid == 1001 then
                    ui.setLabelString(ccbDocumentControler.spendNum,spenddata[1].num,13)
                    -- ccbDocumentControler.spendNum:setString(spenddata[1].num)
                    setSpriteFrameByName(ccbDocumentControler.spendIcon, "obj_s_gold.png")
                end
            end

            local rolevipnum = GameScene.roleinfo.vip

            print("rolevip:",rolevipnum)
            if rolevipnum >itemdata.vip or rolevipnum == itemdata.vip then
            else
                ui.addGray("CCControlButton",ccbDocumentControler.comfirmitemBtn)
            end
            
            

            ccbDocumentControler.comfirmitemBtn:setSwallowsTouch(true)
            ccbDocumentControler.comfirmitemBtn:setTouchPriority(self.touchPriority)
            ccbDocumentControler.comfirmitemBtn:addHandleOfControlEvent(function()
                print("i..am...remove..islandresult.a1..=",(a1+1))
                local itemdata = gamedata.config.penglai2_next[tostring(a1+1)]
                local spenddata = ui.getIDandNUMs(itemdata.price)
                printT(gamedata.config.penglai2_next)

                local nowdata = self.configdata.island.mapStatus[tostring(self.configdata.island.location)]
                local typedata = gamedata.config.penglai2_type[tostring(nowdata.type)]

                local allPointNum = tonumber(itemdata.ratio) * tonumber(typedata.point)
                if rolevipnum >itemdata.vip or rolevipnum == itemdata.vip then
                    if itemdata.price == "" then
                        UIRequest({type = 2112 ,method=(a1+1)})
                        -- runGamePrompt({msg = "获得"..allPointNum.."仙元"})
                        runGamePrompt({msg = gameConfig.strings:getYy(allPointNum)})
                        gameWindows:closeWindowDirect("penglaiResult")
                    elseif tonumber(spenddata[1].cid) == 1000 then
                        if GameScene.roleinfo.coin > spenddata[1].num then
                            UIRequest({type = 2112 ,method=(a1+1) ,coin = spenddata[1].num})
                            -- runGamePrompt({msg = "获得"..allPointNum.."仙元"})
                            runGamePrompt({msg = gameConfig.strings:getYy(allPointNum)})
                            gameWindows:closeWindowDirect("penglaiResult")
                        else
                            -- runGamePrompt({msg = "银币不足！"})
                            --runGamePrompt({msg = gameConfig.strings:string_common("popups","coin2bz")})
                            shortCoin()
                        end
                    elseif tonumber(spenddata[1].cid) == 1001 then
                        if GameScene.roleinfo.gold > spenddata[1].num then
                            UIRequest({type = 2112 ,method=(a1+1) ,gold = spenddata[1].num})
                            -- runGamePrompt({msg = "获得"..allPointNum.."仙元"})
                            runGamePrompt({msg = gameConfig.strings:getYy(allPointNum)})
                            gameWindows:closeWindowDirect("penglaiResult")
                        else
                            -- runGamePrompt({msg = "元宝不足！"})
                            runGamePrompt({msg = gameConfig.strings:string_common("popups","goldbz")})
                        end
                    end
                else
                    -- runGamePrompt({msg = "vip等级不足！"})
                    runGamePrompt({msg = gameConfig.strings:string_common("popups","vipbz")})
                end
            end, CCControlEventTouchUpInside)
            


            cellCCB:setPosition(920/2,160/2)


            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(gamedata.config.penglai2_next)
        elseif fn == "cellTouched" then
            -- GameScene:shiftLayerById(self.config[tostring(a1:getIdx()+1)].systemid)
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

function islandresult.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.stepGneral = nil

    if self.callback then
        self.callback()
    end
end

return islandresult �8  