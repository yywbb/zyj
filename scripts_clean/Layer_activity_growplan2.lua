--成长计划


local growplan = {
    isscrolltouched = false,
    buttontouch = -103,
    statusconfig = {
        [0] = gameConfig.strings:string_common("moreCommon",6),
        [1] = gameConfig.strings:string_common("moreCommon",6),
        [2] = gameConfig.strings:string_common("moreCommon",5),
    },

    normalCellSize = {x=1080,y=228+14},
    --显示的列表项
    
    --标签显示
    pageconfig = {"growplan","general",},
    pagename = {"成长计划","全民福利",},
    selectpage = "growplan",

    growplantb = {},
    generaltb = {},

}



--成长计划的初始化
function growplan.init(self,size)
    self.contentsize = size
    self.show = true
    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/chengzhangjihua2",nil, true, "activity_growup")
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)

    --成长计划表的位置
    self.coveritems.growplanscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-640))
    --全民福利的表
    self.coveritems.generalscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-490))

    --充值按钮
    self.coveritems.rechargebutton:setTouchPriority(self.buttontouch)
    self.coveritems.rechargebutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)

    local index = 1
    while self.coveritems["desc"..index] do
        ui.setLabelString(self.coveritems["desc"..index],nil,1)
        index = index+1
    end

    --vip等级
    self.coveritems.my_vip:setString("贵族"..GameScene.roleinfo.vip)

    ui.setLabelString(self.coveritems.buyLab,nil,18)

    --全民福利的我也要买按钮的跳转事件
    self.coveritems.buygrowplanBtn:setTouchPriority(self.buttontouch)
    self.coveritems.buygrowplanBtn:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        self.selectpage = "growplan"
        self:shiftPage(self.selectpage)
    end, CCControlEventTouchUpInside)

    --显示页签得按钮
    for k=1,2 do
		self.coveritems["planbutton"..k]:setSwallowsTouch(true)
		self.coveritems["planbutton"..k]:setTouchPriority(self.buttontouch)
		self.coveritems["planbutton"..k]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
			self:shiftPage(self.pageconfig[k])
		end,CCControlEventTouchUpInside)
	end

    --显示的哪个标签的内容和页签得高亮状态
    self:shiftPage(self.selectpage)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","growplan",touchbegin)

    local function touchend(pos)
        if self.coveritems.growplanscroll and ui.isTouched(self.coveritems.growplanscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.coveritems.generalscroll and ui.isTouched(self.coveritems.generalscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","growplan",touchend)
    --


    UIRequest({type = 4000})
    return self.coverccb
end

--按钮高亮状态的显示
function  growplan.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if vm == page then
            setSpriteFrameByName(self.coveritems["btnspr"..km], gameConfig.images.pageButtonON)
            --self.coveritems["buttonnode"..km]:setZOrder(1)
        else
            setSpriteFrameByName(self.coveritems["btnspr"..km], gameConfig.images.pageButtonOFF)
            --self.coveritems["buttonnode"..km]:setZOrder(0)
        end
    end
end

--选择页签按钮的修改
function growplan.shiftPage(self,type)
	self.selectpage = type
    self:shiftlayerpage(self.selectpage)

	for k,v in ipairs(self.pageconfig) do
		if v == type then
			self.coveritems[v.."Node"]:setPosition(ccp(0,0))
			self.coveritems[v.."scroll"]:setPosition(ccp(0,160))
			self.coveritems[v.."Node"]:setVisible(true)
			self.coveritems[v.."scroll"]:setVisible(true)
		else
			self.coveritems[v.."Node"]:setPosition(ccp(0,99999))
			self.coveritems[v.."scroll"]:setPosition(ccp(0,99999))
			self.coveritems[v.."Node"]:setVisible(false)
			self.coveritems[v.."scroll"]:setVisible(false)
		end
	end

	if self.selectpage == "growplan" then
		if not next(self.growplantb) then
			UIRequest({type = 2094})
		end
	else

		--if not next(self.generaltb) then
		--	UIRequest({type = 4000})
		--end
	end
end

--创建成长计划的表
function growplan.createlist(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward2", nil, true, "cell_growup")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- local configdata = self.growplan[tostring(a1+1)]
            -- local data = self.growplantb[tostring(a1+1)]
            local configdata = gamedata.config.growplan[tostring(self.growplantb.rewards[tostring(a1+1)].id)]
            local data = self.growplantb.rewards[tostring(a1+1)].status
            ccbDocumentControler.des1:setString(gameConfig.strings:levelFund(configdata.level))
            ccbDocumentControler.des2:setString(gameConfig.strings:getLvGold(configdata.level,configdata.gold))
            ccbDocumentControler.getbutton:setTouchPriority(-102)
            ccbDocumentControler.nonenode:setVisible(false)
            ccbDocumentControler.getNode:setVisible(true)

            ui.setNewIcon(ccbDocumentControler,{cid = 1001, num = configdata.gold})
             -- 增加弹出窗口
            -- ccbDocumentControler.i_button:addHandleOfControlEvent(function()
            --     ui.setPopwindowByCid(1001)
            -- end, CCControlEventTouchUpInside)
            -- ccbDocumentControler.i_button:setSwallowsTouch(true)
            -- ccbDocumentControler.i_button:setTouchPriority(-102)            
            if data and data == 1 then
                ui.removeGray("CCControlButton",ccbDocumentControler.getbutton)
                ui.removeGray("CCLabelTTF",ccbDocumentControler.gettext)
            else
                ui.addGray("CCControlButton",ccbDocumentControler.getbutton)
                ui.addGray("CCLabelTTF",ccbDocumentControler.gettext)
            end


            if not data or data == 0 then
                ccbDocumentControler.nonenode:setVisible(true)
                ccbDocumentControler.getNode:setVisible(false)
                ccbDocumentControler.hasnode:setVisible(false)
            elseif data == 1 then
                ccbDocumentControler.nonenode:setVisible(false)
                ccbDocumentControler.getNode:setVisible(true)
                ccbDocumentControler.hasnode:setVisible(false)
            elseif data == 2 then
                ccbDocumentControler.nonenode:setVisible(false)
                ccbDocumentControler.getNode:setVisible(false)
                ccbDocumentControler.hasnode:setVisible(true)
            end
            ccbDocumentControler.getbutton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if GameScene.layers["activity"].module.isContentScroll then  return end
                if gameTouch.isScrollling then return end
                if not data or data == 0 then
                    if GameScene.roleinfo.level < configdata.level then
                        runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",8)})
                    else
                        runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",9)})
                    end
                elseif data == 1 then
                    --UIRequest({type = 2096, cid = a1+1})
                    UIRequest({type = 2096, cid = configdata.id})
                elseif data == 2 then
                    runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
                end
            end, CCControlEventTouchUpInside)

            ccbDocumentControler.gettext:setString(self.statusconfig[data or 0])
            ui.setLabelString(ccbDocumentControler.gettext,nil,18)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            --r = table.getTableLength(self.growplan)
            r = table.getTableLength(self.growplantb.rewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.growplanscroll:getContentSize().width,
        viewheight = self.coveritems.growplanscroll:getContentSize().height,
        dire = 1
    })
    self.coveritems.growplanscroll:addChild(self.listview)
    self.listview:setTouchPriority(-101)

end

--创建全名福利表
function growplan.createGeneralList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward2", nil, true, "cell_growup")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local configdata = gamedata.config.growplan_global[tostring(self.generaltb.rewards[tostring(a1+1)].id)]
            local data = self.generaltb.rewards[tostring(a1+1)].status

            local cid,num = ui.getIDandNUM(configdata.awards)
            local propconfig = ui.IDconfig(cid)

            ccbDocumentControler.des1:setString(propconfig.name)
            ccbDocumentControler.des2:setString("购买人数达到"..configdata.num.."可以领取")
            ccbDocumentControler.getbutton:setTouchPriority(-102)
            ccbDocumentControler.nonenode:setVisible(false)
            ccbDocumentControler.getNode:setVisible(true)

            ui.setNewIcon(ccbDocumentControler,{cid = cid, num = num})
            -- 增加弹出窗口
            ccbDocumentControler.i_button:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if GameScene.layers["activity"].module.isContentScroll then  return end
                print("弹出物品详情窗口")
                ui.setPopwindowByCid(cid) 
            end, CCControlEventTouchUpInside)
            ccbDocumentControler.i_button:setSwallowsTouch(true)
            ccbDocumentControler.i_button:setTouchPriority(-102)

            if data and data == 1 then
                 ui.removeGray("CCControlButton",ccbDocumentControler.getbutton)
                 ui.removeGray("CCLabelTTF",ccbDocumentControler.gettext)
            else
                 ui.addGray("CCControlButton",ccbDocumentControler.getbutton)
                 ui.addGray("CCLabelTTF",ccbDocumentControler.gettext)
            end


            if not data or data == 0 then
                 ccbDocumentControler.nonenode:setVisible(true)
                 ccbDocumentControler.getNode:setVisible(false)
                 ccbDocumentControler.hasnode:setVisible(false)
            elseif data == 1 then
                 ccbDocumentControler.nonenode:setVisible(false)
                 ccbDocumentControler.getNode:setVisible(true)
                 ccbDocumentControler.hasnode:setVisible(false)
            elseif data == 2 then
                 ccbDocumentControler.nonenode:setVisible(false)
                 ccbDocumentControler.getNode:setVisible(false)
                 ccbDocumentControler.hasnode:setVisible(true)
            end

            ccbDocumentControler.getbutton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if GameScene.layers["activity"].module.isContentScroll then  return end
                if gameTouch.isScrollling then return end
                if not data or data == 0 then
                     if self.generaltb.totalnum < configdata.num then
                         --级别未到达
                         runGamePrompt({msg = "购买人数未到达"})
                     else
                         --尚未购买成长计划
                         runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",9)})
                     end
                elseif data == 1 then
                     UIRequest({type = 4001, id = configdata.id})
                elseif data == 2 then
                     --已领取
                     runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
                end
            end, CCControlEventTouchUpInside)

            ccbDocumentControler.gettext:setString(self.statusconfig[data or 0])
            ui.setLabelString(ccbDocumentControler.gettext,nil,18)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.generaltb.rewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.generalTab = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.generalscroll:getContentSize().width,
        viewheight = self.coveritems.generalscroll:getContentSize().height,
        dire = 1
    })
    self.coveritems.generalscroll:addChild(self.generalTab)
    self.generalTab:setTouchPriority(-101)
	
end

--成长计划的数据
function growplan.reloaddata(self,data)
    if not self.show then return end
    local oldshowtable =  table.getTableLength(self.growplantb.rewards)
    self.growplantb = data
   
    self.coveritems.buyNode:setVisible(true)
    if self.growplantb.hasbuy<=0 then
        if  self.coveritems.buyLab then
            ui.removeGray("CCControlButton",self.coveritems.buybutton)
            ui.removeGray("CCLabelTTF",self.coveritems.buyLab)
        end
        self.coveritems.buybutton:setTouchPriority(self.buttontouch)
        self.coveritems.buybutton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if GameScene.roleinfo.vip < 1 then
                shortVip()
                --runGamePrompt({msg = "vip等级不足"})
            elseif GameScene.roleinfo.gold <1000 then
                shortGold()
            else
                UIRequest({type = 2095})
            end
        end, CCControlEventTouchUpInside)
    else
        if  self.coveritems.buyLab then
            ui.addGray("CCControlButton",self.coveritems.buybutton)
            ui.addGray("CCLabelTTF",self.coveritems.buyLab)
        end
        self.coveritems.buybutton:setTouchPriority(self.buttontouch)
        self.coveritems.buybutton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",10)})
        end, CCControlEventTouchUpInside)
    end

    local newshowtable = table.getTableLength(self.growplantb.rewards)
    printT(self.growplantb ,"adfasfdfffdddddddd")
    if not self.listview then
        self:createlist()
    else
        self.listview:reloadData()
        self.listview:setLuaContentOffset(0, self.listview:getLuaContentOffsetY() - (newshowtable - oldshowtable)*242 )
    end

    --hint
    if self.coveritems.hint1 then
        ui.sethint(self.coveritems.hint1,false)
        for k,v in pairs(self.growplantb.rewards or {}) do
            if v.status and v.status == 1 then
                ui.sethint(self.coveritems.hint1,true)
            end
        end
    end
end

--全民福利的数据更新
function growplan.reloadGeneralData(self,data)
	if not self.show then return end
    local oldshowtable =  table.getTableLength(self.generaltb.rewards)
    self.generaltb = data

    for i=1,4 do
        self.coveritems["buypoplenum"..i]:setString(string.sub(tostring(self.generaltb.totalnum > 9999 and 9999 or self.generaltb.totalnum),-i,-i) or 0)
    end

    ui.setLabelString(self.coveritems.nownum,(self.generaltb.totalnum > 9999 and 9999 or self.generaltb.totalnum).."人已购买",1)
    local newshowtable = table.getTableLength(self.generaltb.rewards)
     if self.coveritems then
        if not self.generalTab then
            self:createGeneralList()
        else
            self.generalTab:reloadData()
            self.generalTab:setLuaContentOffset(0, self.generalTab:getLuaContentOffsetY() - (newshowtable - oldshowtable)*242 )
        end
     end

    --hint
    if self.coveritems.hint2 then
        ui.sethint(self.coveritems.hint2,false)
        for k,v in pairs(self.generaltb.rewards or {}) do
            if v.status and v.status == 1 then
                ui.sethint(self.coveritems.hint2,true)
            end
        end
    end
end


function growplan.clear(self)
    gameTouch:UnrigistFunc("begin","growplan")
    gameTouch:UnrigistFunc("end","growplan")
    self.generalTab = nil
    self.listview = nil
    self.show = false
    self.selectpage = "growplan"
    self.generaltb = {}
    self.growplantb = {}
    self.coverccb = nil
    self.coveritems = nil
    gameTouch:UnrigistFunc("begin","growplan")
    gameTouch:UnrigistFunc("end","growplan")     
end

return growplan