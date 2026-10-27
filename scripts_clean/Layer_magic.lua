--法宝界面
--zhangzhiixn

local magic = {
    rootNode = nil,
    rootItems = nil,
    viewSize = gameConfig.originSize,
    CellSize = {x = 180,y = 180},
    magicNum = 0, --法宝个数
    --显示样式 设置回调函数
    --0 默认样子 1：强化1次 5 强化5次 10 强化10次
    buttonCallBackType = 0, 
    --显示的下面node
    --false 显示属性node  true:显示强化node
    nodeType = false,
    --强化类型
    -- 1 工匠锻造 2 大师锻造 3 匠神锻造
    upType = 1,
    progressSize = 0, --属性条size
    selecetID = 1,--选择的id
    previeState = false,
    stoneID = 20270,
    allDark = true,
    ccbDocument = {},
    listTableView = nil,

    dotimes = 10,
    tuPoStatus = 0,--共三个状态 -1（未开启） 0（开启未突破） level（已经突破等级）
    rolelv = 0,
    maxTupoLevel = 0,
    tupoLevel = 0,
    g_gold = 0,
}

function magic.init(self,parent,toppos,param)
	print("magic.init =============") 
	printT(param)
    self.rootNode,self.rootItems = CCBReaderLoad("magic/magic", nil, true, "magic")
    -- printT(self.rootItems )
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
	self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.bgnode:setPositionY(toppos*(self.rootItems.bgnode:getPositionY()/1920))
    self.artifactConfig = gamedata.config.artifact
    self.artifactConfigxian = gamedata.config.artifact_xian_config
    self.magicNum = table.getTableLength(self.artifactConfig)
    -- print("self.artifactConfig ===========")
    -- printT(self.artifactConfig)
    self.taskConfig = gamedata.config.task
    -- print("self.taskConfig ===========")
    -- printT(self.taskConfig)
    self.globalConfig = gamedata.config.global_kv
    -- self.globalConfigxian = gamedata.config.artifact_xian_config

    -- print("self.globalConfig ===========")
    -- printT(self.globalConfig)
    -- self.rootItems.upNode:setPositionY(self.rootItems.upNode:getPositionY()+50)
    -- self.rootItems.descNode:setPositionY(self.rootItems.descNode:getPositionY()+50)

    if self.globalConfig["artifact_leve_limit"] and tonumber(self.globalConfig["artifact_leve_limit"].value) <= GameScene.roleinfo.level then
        self.dotimes = 50
    end    

    guide.controller:addComplete(149,function()
        UIRequest({type = 2882,opt=1,sysID=149})
    end)
    UIRequest({type = 1360})
end

function magic.clear(self)
    self.dotimes = 10
    self.listTableView = nil
    self.ccbDocument = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.buttonCallBackType = 0
    self.nodeType = false
    self.upType = 1
    self.selectID = 1
    self.previeState = false
    self.allDark = true
end
--初始化
function magic.load( self,aiData )
    self.data = aiData.data
    self.stoneNum = aiData.stoneNum
    self.g_gold =  aiData.g_goldNum
    self.selectID = (aiData.id > 0) and  aiData.id  or (self.selectID or 1)
    self.rolelv = aiData.rolelv

    if self.data.unlock[tostring(self.selectID)] and self.data.unlock[tostring(self.selectID)]["istupo"]then
        self.tuPoStatus =  self.data.unlock[tostring(self.selectID)]["istupo"] or 0
    else
       self.tuPoStatus = 0    
    end 

    self.globalData = {{},{},{},{},{},{},{}}
    for i = 1,3 do
        local t1 = ui.Split(self.globalConfig["artifact_consume_"..i].value,";")
        for k,v in pairs(t1) do
            if v ~= nil and v ~= "" then
                local t = ui.Split(v,",")
                self.globalData[i][t[1]] = tonumber(t[2])
                if i == 1 then self.stoneID = t[1] end
            end
        end     
    end

    
    for i = 4,7 do
        local t1
        local currenttupolv  = self.tuPoStatus
        if currenttupolv <= 0 then
            currenttupolv  = 1
        end    
        print("index:"..i)
        if i == 4 then
            printT(self.artifactConfigxian,"artifactConfigxian")
            print(currenttupolv,"currenttupolv")
            t1 = ui.Split(self.artifactConfigxian[tostring(self.selectID)][tostring(currenttupolv)].breach_consume,";")
        else
            t1 = ui.Split(self.artifactConfigxian[tostring(self.selectID)][tostring(currenttupolv)]["forging_consume"..(i-4)],";")
        end  

        printT(t1,"t1")
        for k,v in pairs(t1) do
            if v ~= nil and v ~= "" then
                local t = ui.Split(v,",")
                self.globalData[i][t[1]] = tonumber(t[2])
                if i == 1 then self.stoneID = t[1] end
            end
        end     
    end

    printT(self.globalData,"self.globalData")

    self.maxTupoLevel = table.getTableLength(self.artifactConfigxian[tostring(self.selectID)])
    print("maxTupoLevel:",self.maxTupoLevel)


    self.rootItems.upOneButton:addHandleOfControlEvent(function()

    	if self.allDark == true and self.tuPoStatus >= 1  then --强化满级
            runGamePrompt({msg = "锻造属性已满，无法锻造"})
        elseif self.buttonCallBackType == 0 then --仙或凡锻造

            local  xiaohao = self.globalData[self.upType]
            if self.tuPoStatus >=1 then
                xiaohao = self.globalData[4+self.upType]

            end    
            printT(xiaohao,"one xiaohao")
            UIRequest({
            type = 1362,
            id = self.selectID,
            typeIndex = self.upType,
            times = 1,
            num =   xiaohao,
            tuPoStatus = self.tuPoStatus
            })

    	else
            UIRequest({type = 1363,typeIndex = 0})
    	end 

    end, CCControlEventTouchUpInside)
    self.rootItems.upOneButton:setSwallowsTouch(true)
    self.rootItems.upOneButton:setTouchPriority(-101 )

    self.rootItems.upFiveButton:addHandleOfControlEvent(function()

        local  xiaohao = self.globalData[self.upType]
        if self.tuPoStatus >=1 then
            xiaohao = self.globalData[4+self.upType]

        end    
         printT(xiaohao,"ten xiaohao")
        if self.allDark == true and self.tuPoStatus >= 1  then --强化满级
            runGamePrompt({msg = "锻造属性已满，无法锻造"})
        elseif self.buttonCallBackType == 0 or self.buttonCallBackType == 5 then
    		UIRequest({type = 1362,id = self.selectID,typeIndex = self.upType,times = self.dotimes or 10,num = xiaohao, tuPoStatus = self.tuPoStatus})
    	elseif self.buttonCallBackType == 1 then   		
    		UIRequest({type = 1362,id = self.selectID,typeIndex = self.upType,times = 1,num = xiaohao,tuPoStatus = self.tuPoStatus})
		elseif self.buttonCallBackType == 10 then			
			UIRequest({type = 1362,id = self.selectID,typeIndex = self.upType,times = 10,num = xiaohao,tuPoStatus = self.tuPoStatus})
    	elseif self.buttonCallBackType == 50 then           
            UIRequest({type = 1362,id = self.selectID,typeIndex = self.upType,times = 50,num = xiaohao,tuPoStatus = self.tuPoStatus})
        else
    	end 

    end, CCControlEventTouchUpInside)
    self.rootItems.upFiveButton:setSwallowsTouch(true)
    self.rootItems.upFiveButton:setTouchPriority(-101 )

    self.rootItems.upTenButton:addHandleOfControlEvent(function()

        if self.allDark == true and self.tuPoStatus >= 1  then --强化满级
            runGamePrompt({msg = "锻造属性已满，无法锻造"})
        elseif self.buttonCallBackType == 0 then    		
    		--UIRequest({type = 1362,id = self.selectID,typeIndex = self.upType,times = 10,num = self.globalData[self.upType]})
            --todo
            --if self.upType > 1 then
                local vipopen = ui.getVipLevelByStr("vip_automatic_forging")
                if GameScene.roleinfo.level < tonumber(gamedata.config.global_kv.automatic_forging.value) and vipopen > GameScene.vip.vip then
                    runGamePrompt({msg = "等级不足，"..gamedata.config.global_kv.automatic_forging.value.."级或VIP"..vipopen.."开启！"})
                else
                    gameWindows:openWindow("instrumentForgeAutomatic",{iid = self.selectID, method = self.upType, tuPoStatus = self.tuPoStatus, g_gold = self.g_gold},nil)
                end
            --else
            --    runGamePrompt({msg = "工匠锻造不可自动锻造"})
            --end
    	else
    		UIRequest({type = 1363,typeIndex = 1})
    	end 

    end, CCControlEventTouchUpInside)
    self.rootItems.upTenButton:setSwallowsTouch(true)
    self.rootItems.upTenButton:setTouchPriority(-101 )

	self:setSpriteShow(self.upType)
    self.rootItems.normalButton:addHandleOfControlEvent(function()
    	self:setSpriteShow(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.normalButton:setSwallowsTouch(true)
    self.rootItems.normalButton:setTouchPriority(-101 )
    self.rootItems.coinButton:addHandleOfControlEvent(function()
    	self:setSpriteShow(2)
    end, CCControlEventTouchUpInside)
    self.rootItems.coinButton:setSwallowsTouch(true)
    self.rootItems.coinButton:setTouchPriority(-101 )
    self.rootItems.goldButton:addHandleOfControlEvent(function()    	
        local callBack = function()
            self:setSpriteShow(3)
        end
        if self.upType ~= 3 then
            local message = "匠神锻造需要消耗元宝，是否切换为匠神锻造？"
            if self.tuPoStatus>0 then
                message =  "匠神锻造需要消耗仙元，是否切换为匠神锻造？"
            end    
            gameWindows:openWindow("confirm",{msg = message}, callBack)
        else
            callBack()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.goldButton:setSwallowsTouch(true)
    self.rootItems.goldButton:setTouchPriority(-101 ) 

    self.rootItems.addStone:addHandleOfControlEvent(function()
    	print("弹出获取途径弹窗 等配置表")
        gameWindows:openWindow("dropTips",{cid = tonumber(self.stoneID),num = self.stoneNum},nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.addStone:setSwallowsTouch(true)
    self.rootItems.addStone:setTouchPriority(-101 )

    self.rootItems.addStone2:addHandleOfControlEvent(function()
        print("弹出获取途径弹窗 等配置表")
        gameWindows:openWindow("dropTips",{cid = tonumber(self.stoneID),num = self.stoneNum},nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.addStone2:setSwallowsTouch(true)
    self.rootItems.addStone2:setTouchPriority(-101 )



    --突破按钮
    self.rootItems.breakthrougButton:addHandleOfControlEvent(function()

        local data= self.artifactConfigxian[tostring(self.selecetID)][tostring(self.tuPoStatus+1)]
        if data.level > self.rolelv then
             runGamePrompt({msg = "战队等级达到"..data.level.."级可进行法宝突破"})
        else
            UIRequest({
            type = 1365,
            id = self.selectID,
            consume = data.breach_consume,
            })
        end    
    end, CCControlEventTouchUpInside)
    self.rootItems.upOneButton:setSwallowsTouch(true)
    self.rootItems.upOneButton:setTouchPriority(-101 )

    --总属性加成
    self.rootItems.attributeButton:setVisible(false)
    self.rootItems.attributeButton:addHandleOfControlEvent(function()
    
        gameWindows:openWindow("magicAttribute",{ data = self.data.unlock })

    end, CCControlEventTouchUpInside)
    self.rootItems.attributeButton:setSwallowsTouch(true)
    self.rootItems.attributeButton:setTouchPriority(-101 )



    local isLight = true
    for i = 1,5 do
    	if self.data.lock["task"..i.."Complete"] == 0 then
    		isLight = false
    		ui.addGray("CCControlButton",self.rootItems.lockButton)
    		break
    	end
    end


    self.rootItems.lockButton:addHandleOfControlEvent(function()
    	if isLight == false then
    		runGamePrompt({msg="条件未满足"})  
    	else
    		UIRequest({type = 1361,id = self.data.lock.id})
    	end
    end, CCControlEventTouchUpInside)


    self.rootItems.lockButton:setSwallowsTouch(true)
    self.rootItems.lockButton:setTouchPriority(-101 )
    ui.setLabelString( self.rootItems.tipsText,nil,18)

    ui.setLabelString( self.rootItems.normalStoneNum,self.globalData[1][tostring(self.stoneID)],13)
	ui.setLabelString( self.rootItems.coinStoneNum,self.globalData[2][tostring(self.stoneID)],13)
	ui.setLabelString( self.rootItems.goldStoneNum,self.globalData[3][tostring(self.stoneID)],13)
	ui.setLabelString( self.rootItems.coinNum,self.globalData[2][tostring(1000)],13)
	ui.setLabelString( self.rootItems.goldNum,self.globalData[3][tostring(1001)],13)
	--ui.setLabelString( self.rootItems.stoneNum,self.stoneNum,13)
	ui.setLabelString(self.rootItems.lockText,nil,19)
    self:showHasNum(0)


    if self.rootItems.lockdesc then
        ui.setLabelString(self.rootItems.lockdesc,nil,18)
    end
    --属性预览
    if self.rootItems.viewButtonNode then
        ui.setLabelString(self.rootItems.viewText,nil,19)
        self.rootItems.viewButton:addHandleOfControlEvent(function()
            --
            gameWindows:openWindow("magicViewAttr",{id = self.selectID},nil)
            --
        end, CCControlEventTouchUpInside)
        self.rootItems.viewButton:setSwallowsTouch(true)
        self.rootItems.viewButton:setTouchPriority(-101 )
    end
    --



    if not self.listTableView then
        self:loadTopNode(self.data)
    end

	self:setNodeVisible(self.selectID)

	self:setButtonShowType(0)
end

--初始化上面条的内容
function magic.loadTopNode(self)
    print("loadTopNode")

    local celldict = {}

    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB,ccbDocumentControler = CCBReaderLoad("icons/new_icon", nil, true, "cell_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimationH(self.listTableView, cellCCB,self.CellSize.x, self.CellSize.y,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setCell(ccbDocumentControler,self.artifactConfig[tostring(a1 + 1)])

            ccbDocumentControler.i_selectEffect2:removeAllChildrenWithCleanup(true)
            if self.selectID == a1+1 then
                if  ccbDocumentControler then
                    local selectNode,selectItems = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                    ccbDocumentControler.i_selectEffect2:addChild(selectNode)
                end
            end

            if self.listTableView then
                cellCCB:setPosition(self.CellSize.x/2, self.CellSize.y/2)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
        	-- if self.data.lock.id ~= 0 then
        	-- 	r = table.getTableLength(self.data.unlock)  + 1
        	-- else
         --    	r = table.getTableLength(self.data.unlock) 
        	-- end
            r = table.getTableLength(self.artifactConfig) 
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.listscroll:addChild(self.listTableView)
    self.listTableView:setTouchPriority(-101)	
end
function magic.setCell(self,aiItems,aiConfig)
	aiItems.i_soulsprite:setVisible(false)
	aiItems.i_suitNode:removeAllChildrenWithCleanup(true)
    aiItems.i_selectEffect:removeAllChildrenWithCleanup(true)
	if self.data.lock.id == aiConfig.id then
        ui.addGray("CCSprite",aiItems.i_icon)
    elseif self.data.lock.id ~= 0 and  self.data.lock.id < aiConfig.id then
        local spr = ui.createSprite()
        spr:setScale(0.4)
		aiItems.i_selectEffect:addChild(spr)	
        -- {frame = "public/publicsprite/spr_84" }
        setSpriteFrameByName(spr, "spr_84")
        ui.addGray("CCSprite",aiItems.i_icon)
        ui.addGray("CCSprite",spr)
	else
        ui.removeGray("CCSprite",aiItems.i_icon)

	end
    printT(self.data,"self.data====")
	setSpriteFrameByName(aiItems.i_icon, aiConfig.icon and aiConfig.icon or "alpha")
    aiItems.i_button:addHandleOfControlEvent(function()
    	if gameTouch.isScrollling then return end
        if self.previeState == true and self.selectID ~=  aiConfig.id then
            runGamePrompt({msg = "请先确认是否强化！"})
        -- elseif self.data.lock.id < aiConfig.id and self.data.lock.id ~= 0  then
        --     runGamePrompt({msg = "请先解锁"..self.artifactConfig[tostring(self.data.lock.id)].name})
        elseif self.previeState == false then

		    self:setNodeVisible(aiConfig.id)
        end
    end, CCControlEventTouchUpInside)
    aiItems.i_button:setTouchPriority(-102 )
    --

end
--设置下面node显示内容
function magic.changeNode( self,aiIndex )

    if self.rootItems.lockdesc then
        self.rootItems.lockdesc:setVisible(false)
    end

	local  tData 
    if self.tuPoStatus >0 then
        tData= self.artifactConfigxian[tostring(aiIndex)][tostring(self.tuPoStatus)]
    else
        tData= self.artifactConfig[tostring(aiIndex)]
    end    
    printT(tData,"tData")
    
	if self.data.lock.id == aiIndex then --未解锁法宝
        if self.rootItems.lockButtonNode and self.rootItems.viewButtonNode then
            self.rootItems.lockButtonNode:setVisible(true)
            self.rootItems.lockButtonNode:setPositionX(-200)
            self.rootItems.viewButtonNode:setPositionX(200)
        end    
        --
		for i = 1,5 do
			if i == 1 then
				if self.data.lock["task1Complete"] == 1 then
					self.rootItems["lockSpr"]:setVisible(false) 
					self.rootItems["completeSpr"]:setVisible(true) 
				else
					self.rootItems["lockSpr"]:setVisible(true) 
					self.rootItems["completeSpr"]:setVisible(false) 	
				end
				ui.setLabelString(self.rootItems.descText,self.taskConfig[tostring(tData.task1)].desc ,21) 
				if self.data.lock.task1Complete == 1 and tonumber(self.taskConfig[tostring(tData.task1)].target) ~= nil then
					ui.setLabelString(self.rootItems.compeleNum,self.taskConfig[tostring(tData.task1)].target.."/"..self.taskConfig[tostring(tData.task1)].target,21)
				elseif self.data.lock.task1Complete == 1 and tonumber(self.taskConfig[tostring(tData.task1)].target) == nil then
					ui.setLabelString(self.rootItems.compeleNum, "1/1" ,21)
				elseif  self.data.lock.task1Complete ~= 1 and tonumber(self.taskConfig[tostring(tData.task1)].target) ~= nil then
					ui.setLabelString(self.rootItems.compeleNum,self.data.lock["task1Num"].."/"..self.taskConfig[tostring(tData.task1)].target,21)
				else
					ui.setLabelString(self.rootItems.compeleNum,"0/1",21)
				end
			else
				if self.data.lock["task"..i.."Complete"] == 1 then
					self.rootItems["lockSpr_"..(i-1)]:setVisible(false) 
					self.rootItems["completeSpr_"..(i-1)]:setVisible(true) 
				else
					self.rootItems["lockSpr_"..(i-1)]:setVisible(true) 
					self.rootItems["completeSpr_"..(i-1)]:setVisible(false) 				
				end
				ui.setLabelString(self.rootItems["descText_"..(i-1)],self.taskConfig[tostring(tData["task"..i])].desc ,21) 
				if self.data.lock["task"..i.."Complete"] == 1 and tonumber(self.taskConfig[tostring(tData["task"..i])].target) ~= nil  then
					ui.setLabelString(self.rootItems["compeleNum_"..(i-1)],self.taskConfig[tostring(tData["task"..i])].target.."/"..self.taskConfig[tostring(tData["task"..i])].target,21)
				elseif  self.data.lock["task"..i.."Complete"] == 1 and tonumber(self.taskConfig[tostring(tData["task"..i])].target) == nil  then
					ui.setLabelString(self.rootItems["compeleNum_"..(i-1)],"1/1",21)
				elseif   self.data.lock["task"..i.."Complete"] ~= 1 and tonumber(self.taskConfig[tostring(tData["task"..i])].target) ~= nil  then
					ui.setLabelString(self.rootItems["compeleNum_"..(i-1)],self.data.lock["task"..i.."Num"].."/"..self.taskConfig[tostring(tData["task"..i])].target ,21)
				else
					ui.setLabelString(self.rootItems["compeleNum_"..(i-1)],"0/1",21)
				end			
			end
		end
    elseif (self.data.lock.id > 0) and (self.data.lock.id < aiIndex) then --解锁中法宝
        if self.rootItems.lockdesc then
            self.rootItems.lockdesc:setVisible(true)
        end
        if self.rootItems.lockButtonNode and self.rootItems.viewButtonNode then
            self.rootItems.lockButtonNode:setVisible(false)
            self.rootItems.lockButtonNode:setPositionX(-9999)
            self.rootItems.viewButtonNode:setPositionX(0)
        end
        --fv
        self.rootItems["lockSpr"]:setVisible(true) 
        self.rootItems["completeSpr"]:setVisible(false)  
        ui.setLabelString(self.rootItems.descText,self.taskConfig[tostring(tData.task1)].desc ,21) 
        if tonumber(self.taskConfig[tostring(tData["task1"])].target) ~= nil  then
            --ui.setLabelString(self.rootItems["compeleNum"],"0/"..self.taskConfig[tostring(tData["task1"])].target ,21)
            ui.setLabelString(self.rootItems["compeleNum"],"",21)
        else
            --ui.setLabelString(self.rootItems["compeleNum"],"0/1",21)
            ui.setLabelString(self.rootItems["compeleNum"],"",21)
        end     
        for i = 2,5 do
            self.rootItems["lockSpr_"..(i-1)]:setVisible(true) 
            self.rootItems["completeSpr_"..(i-1)]:setVisible(false)  
            ui.setLabelString(self.rootItems["descText_"..(i-1)],self.taskConfig[tostring(tData["task"..i])].desc ,21) 
            if tonumber(self.taskConfig[tostring(tData["task"..i])].target) ~= nil  then
                --ui.setLabelString(self.rootItems["compeleNum_"..(i-1)],"0/"..self.taskConfig[tostring(tData["task"..i])].target ,21)
                ui.setLabelString(self.rootItems["compeleNum_"..(i-1)],"",21)
            else
                --ui.setLabelString(self.rootItems["compeleNum_"..(i-1)],"0/1",21)
                ui.setLabelString(self.rootItems["compeleNum_"..(i-1)],"",21)
            end     
        end 
	else  --已经解锁的法宝
		for k,v in pairs(self.data.unlock) do
			if v.id == aiIndex then

                self.selecetID = aiIndex
                self:setButtonShowType(0)
                local attr = "attr"
                local init = "init"
                local index = 0 
                if self.tuPoStatus > 0 then
                    index = 4
                    self.rootItems.gold:setVisible(false)
                    self.rootItems.g_gold:setVisible(true)
                    ui.setLabelString( self.rootItems.goldNum,self.globalData[3+index][tostring(1025)],13)
                else
                    self.rootItems.gold:setVisible(true)
                    self.rootItems.g_gold:setVisible(false)  
                    ui.setLabelString( self.rootItems.goldNum,self.globalData[3+index][tostring(1001)],13)
                end    

                ui.setLabelString(self.rootItems.progress1Name,gameConfig.strings:string_common("attr_type",tData[attr..1]),21)
                ui.setLabelString(self.rootItems.progress2Name,gameConfig.strings:string_common("attr_type",tData[attr..2]),21)
                ui.setLabelString(self.rootItems.progress3Name,gameConfig.strings:string_common("attr_type",tData[attr..3]),21)
                ui.setLabelString(self.rootItems.progress4Name,gameConfig.strings:string_common("attr_type",tData[attr..4]),21)
                
                
                ui.setLabelString( self.rootItems.normalStoneNum,self.globalData[1+index][tostring(self.stoneID)],13)
                ui.setLabelString( self.rootItems.coinStoneNum,self.globalData[2+index][tostring(self.stoneID)],13)
                ui.setLabelString( self.rootItems.goldStoneNum,self.globalData[3+index][tostring(self.stoneID)],13)
                ui.setLabelString( self.rootItems.coinNum,self.globalData[2+index][tostring(1000)],13)
                

                for i = 1,4 do
                    if tData[init..i] >= 1 then
                        ui.setLabelString(self.rootItems["text"..i], v[attr..(i+index)],22)
                        ui.setLabelString(self.rootItems["maxText"..i],"最大("..tData[init..i]..")",13)                        
                    else
                        ui.setLabelString(self.rootItems["text"..i],v[attr..(i+index)].."%",22)
                        ui.setLabelString(self.rootItems["maxText"..i],"最大("..self:maybetopercent(tData[init..i])..")",13)                        
                    end

                    if self.allDark == true then
                        ui.setLabelString(self.rootItems["maxText"..i],"   (已满)",13)  
                        self.rootItems["maxText"..i]:setColor(ccc3(255,8,8))
                    end    

                    self.rootItems["addNode"..i]:setVisible(false)
                    self.rootItems["decreaseNode"..i]:setVisible(false)
                end
				break
			end
		end 
	end
end
--初始化锻造界面node
function magic.laodUpNode( self,aiData  )
	self:setSpriteShow(self.upType)
	ui.setLabelString(self.rootItems.normalStoneNum,999,13)
	ui.setLabelString(self.rootItems.coinNum,999,13)
	ui.setLabelString(self.rootItems.coinStoneNum,999,13)
	ui.setLabelString(self.rootItems.goldNum,999,13)
	ui.setLabelString(self.rootItems.goldStoneNum,999,13)
	ui.setLabelString(self.rootItems.stoneNum,999,13)
    ui.setLabelString(self.rootItems.stoneNum2,999,13)

	ui.setLabelString(self.rootItems.haveText,nil,13)
end
--设置强化和属性node显示
function magic.setNodeVisible(self,aiIndex)
	self.selectID = aiIndex

    if self.data.unlock[tostring(self.selectID)] and self.data.unlock[tostring(self.selectID)]["istupo"]then
        self.tuPoStatus =  self.data.unlock[tostring(self.selectID)]["istupo"] or 0
    else
       self.tuPoStatus = 0    
    end 

    self:showHasNum(0)
	local aiBool = true
	if (self.data.lock.id > aiIndex) or (self.data.lock.id == 0) then
		aiBool = false
	end
	if aiBool == true then
		self.rootItems.descNode:setPositionX(self.viewSize.width*0.5)	
		self.rootItems.upNode:setPositionX(99999)	
		self.rootItems.iconLock:setVisible(true)	
	else
		self.rootItems.descNode:setPositionX(99999)	
		self.rootItems.upNode:setPositionX(self.viewSize.width*0.5)		
		self.rootItems.iconLock:setVisible(false)
	end
    ui.setLabelString(self.rootItems.magicName,self.artifactConfig[tostring(aiIndex)].name ,1)
    print("aiIndex =="..aiIndex)
    self.rootItems.iconNode:removeAllChildrenWithCleanup(true)
    local eccb,eitem = CCBReaderLoad("UIEffect/fabao/"..self.artifactConfig[tostring(aiIndex)].icon, nil, true, "fabao")
    self.rootItems.iconNode:addChild(eccb)

    if aiBool == false then
        eitem.aniNode:setVisible(true)
        ui.removeGray("CCSprite",eitem.basicSpr)
    else
        eitem.aniNode:setVisible(false)
        ui.addGray("CCSprite",eitem.basicSpr)
        self.rootItems.breakthrougNode:setVisible(false)

    end

    self.nodeType = aiBool
	self:changeNode(aiIndex)
    --
    self.listTableView:reloadData()
    
    if aiBool == false then
         if self.allDark == true  and self.tuPoStatus< self.maxTupoLevel then    
            self.rootItems.breakthrougNode:setVisible(true)
        end
    end    


end
--设置下面3个按钮显示字
function magic.setButtonShowType( self,aiType,aiData )
	local lightType = 0 --0都亮 1只有替换亮 -1 只有替换不亮

    if type(aiData) == "table" then --法宝锻造预览
        local magic  = nil
        for k,v in pairs(aiData.magicdata.unlock) do
            if v.id  == aiData.requestData.id then
                magic = v
                break
            end
        end 
        for i = 1,4 do
            local attr = "attr"
            local init = "init"
            local index = 0
            if self.tuPoStatus > 0  then
                index = 4
            end 
            printT(aiData,"aiData")   
            if aiData.data[tostring(i)] - magic[attr..(i+index)] > 0 and  lightType >= 0 then
                lightType = 1
            elseif aiData.data[tostring(i)] - magic[attr..(i+index)] > 0 and  lightType < 0 then
                lightType = 0 
                break
            elseif aiData.data[tostring(i)] - magic[attr..(i+index)] < 0  and lightType <= 0 then
                lightType = -1
            elseif aiData.data[tostring(i)] - magic[attr..(i+index)] < 0  and lightType > 0 then
                lightType = 0 
                break                                  
            end

        end
    end

    self.maxTupoLevel = table.getTableLength(self.artifactConfigxian[tostring(self.selecetID)])
    print("maxTupoLevel:",self.maxTupoLevel)

    if self.tuPoStatus> 0 then
        local data= self.artifactConfigxian[tostring(self.selecetID)][tostring(self.tuPoStatus)]
        if data and data.level > self.rolelv then
            self.rootItems.attributeButton:setVisible(false)
        else    
            self.rootItems.attributeButton:setVisible(true)
        end    
    else    
        self.rootItems.attributeButton:setVisible(false)
    end    

	if lightType == 1 then
		ui.addGray("CCControlButton",self.rootItems.upOneButton)
		ui.addGray("CCControlButton",self.rootItems.upFiveButton)
		ui.removeGray("CCControlButton",self.rootItems.upTenButton)
		self.rootItems.upOneButton:setTouchEnabled(false)
		self.rootItems.upFiveButton:setTouchEnabled(false)
		self.rootItems.upTenButton:setTouchEnabled(true)
	elseif lightType == -1 then
		ui.removeGray("CCControlButton",self.rootItems.upOneButton)
		ui.removeGray("CCControlButton",self.rootItems.upFiveButton)
		ui.addGray("CCControlButton",self.rootItems.upTenButton)
		self.rootItems.upOneButton:setTouchEnabled(true)
		self.rootItems.upFiveButton:setTouchEnabled(true)
		self.rootItems.upTenButton:setTouchEnabled(false)		
	else 
        self.allDark = true
        if self.data.unlock[tostring(self.selecetID)] then
            local attr = "attr"
            local init = "init"
            local currentartifactConfig = self.artifactConfig

            local index =0 --属性值不一样
            local max = self.selecetID
            if self.tuPoStatus > 0 then
                currentartifactConfig= self.artifactConfigxian[tostring(self.selecetID)]
                index = 4
                max = self.tuPoStatus
            end 
            printT(currentartifactConfig,"currentartifactConfig")
            print(self.selecetID)  

            for i = 1,4 do
                if self.data.unlock[tostring(self.selecetID)][attr..(index+i)]  < currentartifactConfig[tostring(max)][init..i] and currentartifactConfig[tostring(max)][init..i] >= 1 then
                    self.allDark = false
                    break
                elseif self.data.unlock[tostring(self.selecetID)][attr..(index+i)]  < currentartifactConfig[tostring(max)][init..i]*100 and currentartifactConfig[tostring(max)][init..i] < 1 then
                    self.allDark = false
                    break                
                end                    
            end


        end

        print("setButtonShowType ========")
        if self.allDark == false then
    		ui.removeGray("CCControlButton",self.rootItems.upOneButton)
    		ui.removeGray("CCControlButton",self.rootItems.upFiveButton)
    		ui.removeGray("CCControlButton",self.rootItems.upTenButton)
        else
            ui.addGray("CCControlButton",self.rootItems.upOneButton)
            ui.addGray("CCControlButton",self.rootItems.upFiveButton)
            ui.addGray("CCControlButton",self.rootItems.upTenButton)
        end
        self.rootItems.upOneButton:setTouchEnabled(true)
        self.rootItems.upFiveButton:setTouchEnabled(true)
        self.rootItems.upTenButton:setTouchEnabled(true)	
	end
	self.buttonCallBackType = aiType
	if aiType == 1 then
		ui.setLabelString(self.rootItems.upOneText,gameConfig.strings:string_common("magic", 1),19) 
		ui.setLabelString(self.rootItems.upFiveText,gameConfig.strings:string_common("magic", 3),19) 
		ui.setLabelString(self.rootItems.upTenText,gameConfig.strings:string_common("magic", 2),19) 
	elseif aiType == 10 then
		ui.setLabelString(self.rootItems.upOneText,gameConfig.strings:string_common("magic", 1),19) 
		ui.setLabelString(self.rootItems.upFiveText,gameConfig.strings:string_common("magic", 5),19)
		ui.setLabelString(self.rootItems.upTenText,gameConfig.strings:string_common("magic", 2),19) 
    elseif aiType == 50 then
        ui.setLabelString(self.rootItems.upOneText,gameConfig.strings:string_common("magic", 1),19) 
        ui.setLabelString(self.rootItems.upFiveText,"锻造 X50",19)
        ui.setLabelString(self.rootItems.upTenText,gameConfig.strings:string_common("magic", 2),19)     
--	elseif aiType == 10 then
--		ui.setLabelString(self.rootItems.upOneText,gameConfig.strings:string_common("magic", 1),19)
--		ui.setLabelString(self.rootItems.upFiveText,gameConfig.strings:string_common("magic", 5),19)
--		ui.setLabelString(self.rootItems.upTenText,gameConfig.strings:string_common("magic", 2),19)
	else
		ui.setLabelString(self.rootItems.upOneText,gameConfig.strings:string_common("magic", 3),19) 
        if self.dotimes and self.dotimes == 50 then
            ui.setLabelString(self.rootItems.upFiveText,"锻造 X50",19)
        else    
		    ui.setLabelString(self.rootItems.upFiveText,gameConfig.strings:string_common("magic", 5),19)
        end
		ui.setLabelString(self.rootItems.upTenText,"自动锻造",19)
	end

    if self.allDark == true then
        ui.addGray("CCControlButton",self.rootItems.upOneButton)
        ui.addGray("CCControlButton",self.rootItems.upFiveButton)
        ui.addGray("CCControlButton",self.rootItems.upTenButton)
    end



    -- if self.tuPoStatus == 0 then
    if self.allDark == true  and self.tuPoStatus< self.maxTupoLevel then    
        self.rootItems.attributeNode:setVisible(false)
        self.rootItems.breakthrougNode:setVisible(true)
        self.rootItems.upOneNode:setVisible(false)  
        self.rootItems.upFiveNode:setVisible(false) 
        self.rootItems.upTenNode:setVisible(false)  

        local data= self.artifactConfigxian[tostring(self.selecetID)][tostring(self.tuPoStatus+1)]
        if data.level > self.rolelv then
            ui.addGray("CCControlButton",self.rootItems.breakthrougButton)
        else
            ui.removeGray("CCControlButton",self.rootItems.breakthrougButton)    
        end    
        printT(self.artifactConfigxian)
        print("self.selecetID:"..self.selecetID.." self.tuPoStatus:"..self.tuPoStatus)
        local coststr = self.artifactConfigxian[tostring(self.selecetID)][tostring(self.tuPoStatus+1)].breach_consume
        print(coststr," coststr")
        local cost = ui.getIDandNUMs(coststr)
        print(cost," cost")
        self.tupo_needprops = {}
        local propindex = 0
        for i = 1,4 do
            self.rootItems["needprop"..i]:setVisible(false)
        end
        local cids = {}
        for k,v in pairs(cost) do
            table.insert(cids,v.cid)
        end
        UIRequest({type = 12001, order = 32007, cids = cids})

        for k,v in pairs(cost) do
            if propindex <= 4 then
                local index = propindex+1
                self.rootItems["needprop"..index]:setVisible(true)
                ui.setNewIcon(self.rootItems,v,propindex)
                self.tupo_needprops[tostring(v.cid)] = {cid = v.cid, num = v.num, index = index, has = 0 }
                self.rootItems["i_button"..((index == 1) and "" or ("_"..(index-1)))]:addHandleOfControlEvent(function()
                    gameWindows:openWindow("dropTips",{cid = v.cid},nil)
                end, CCControlEventTouchUpInside)
                self.rootItems["i_button"..((index == 1) and "" or ("_"..(index-1)))]:setSwallowsTouch(true)
                self.rootItems["i_button"..((index == 1) and "" or ("_"..(index-1)))]:setTouchPriority(-103)
                propindex = propindex+1
            end
        end

    else
        self.rootItems.attributeNode:setVisible(true)
        self.rootItems.breakthrougNode:setVisible(false)  
        self.rootItems.upOneNode:setVisible(true)  
        self.rootItems.upFiveNode:setVisible(true) 
        self.rootItems.upTenNode:setVisible(true)   
    end

end
--选择锻造种类
function magic.setSpriteShow(self,aiUpType)
	self.upType = aiUpType
	if aiUpType == 1 then
		self.rootItems.normalSpr:setVisible(true)
		self.rootItems.coinSpr:setVisible(false)
		self.rootItems.goldSpr:setVisible(false)
	elseif  aiUpType == 2 then
		self.rootItems.normalSpr:setVisible(false)
		self.rootItems.coinSpr:setVisible(true)
		self.rootItems.goldSpr:setVisible(false)
	else
		self.rootItems.normalSpr:setVisible(false)
		self.rootItems.coinSpr:setVisible(false)
		self.rootItems.goldSpr:setVisible(true)
	end
end
--1361解锁回调
function magic.unlock( self,aiData )
	self.data =  aiData.data
	--播放动画
	self.rootItems.iconLock:setVisible(false)

    local eccb,eitem = CCBReaderLoad("UIEffect/jiesuo/jiesuo", nil, true, "jiesuo")
    self.rootItems.iconNode:addChild(eccb)
    local animationManager = getAnimationManager(eitem)
    animationManager:setAnimationCompletedCallback(function()
        eccb:removeFromParentAndCleanup(true)
        self:setNodeVisible(aiData.id)
        self.listTableView:reloadData()
        self.listTableView:setLuaContentOffset(0 ,0)
    end)
    animationManager:runAnimationsForSequenceNamed("jiesuo")
end
--1362回调 匠造预览
function  magic.preview(self,aiData)
    self.previeState = true
	self:setButtonShowType(aiData.requestData.times,aiData)

    self.stoneNum = aiData.num
    self.g_gold =  aiData.g_goldNum

    self:showHasNum(aiData.num)
    -- ui.setLabelString(self.rootItems.stoneNum,aiData.num,13)
   
	-- self.rootItems.progress1Node:removeAllChildrenWithCleanup(true)
	-- self.rootItems.progress2Node:removeAllChildrenWithCleanup(true)
	-- self.rootItems.progress3Node:removeAllChildrenWithCleanup(true)
	-- self.rootItems.progress4Node:removeAllChildrenWithCleanup(true)

    local tConfig = self.artifactConfig[tostring(aiData.requestData.id)]
    local startindex = 0
    if self.tuPoStatus>0 then
       -- tConfig = self.artifactConfigxian[tostring(self.selecetID)][self.tuPoStatus]
       tConfig= self.artifactConfigxian[tostring(aiData.requestData.id)][tostring(self.tuPoStatus)]

       startindex = 4
    end   

    print(self.tuPoStatus,"self.tuPoStatus")

    printT(tConfig,"preview tConfig---------")


	local t = nil
	for k,v in pairs(aiData.magicdata.unlock) do
		if v.id == aiData.requestData.id then
			t = v
            break
		end
	end	
	local function resetLable(index,startin)
        -- local arg = {}
        -- --and  < t["attr"..index]
        -- if aiData.data[tostring(index)]   <= tConfig["init"..index] and tConfig["init"..index] >= 1 then
        --     if  aiData.data[tostring(index)] - t["attr"..index] >= 0 and t["attr"..index]  < tConfig["init"..index]  then
        --         table.insert(arg,{fontID = 13,content = tostring(t["attr"..index])})
        --         table.insert(arg,{fontID = 4,content = "+"..aiData.data[tostring(index)] - t["attr"..index] })
        --         table.insert(arg,{fontID = 13,content = "/"..tConfig["init"..index]})
        --     elseif  aiData.data[tostring(index)] - t["attr"..index] < 0 then
        --         table.insert(arg,{fontID = 13,content = tostring(t["attr"..index])})
        --         table.insert(arg,{fontID = 24,content = tostring(aiData.data[tostring(index)] - t["attr"..index])})
        --         table.insert(arg,{fontID = 13,content = "/"..tConfig["init"..index]})
        --     else
        --         table.insert(arg,{fontID = 13,content = tostring(t["attr"..index])})
        --         table.insert(arg,{fontID = 13,content = "/"..tConfig["init"..index]})                
        --     end
        -- elseif  aiData.data[tostring(index)]   <= tConfig["init"..index]*100 and tConfig["init"..index] < 1 then
        --     if  aiData.data[tostring(index)] - t["attr"..index]>= 0 and  t["attr"..index]  < tConfig["init"..index] *100 then
        --         table.insert(arg,{fontID = 13,content = tostring(self:maybetopercent(t["attr"..index]/100))})
        --         table.insert(arg,{fontID = 4,content = "+"..self:maybetopercent( (aiData.data[tostring(index)] - t["attr"..index])/100 )})
        --         table.insert(arg,{fontID = 13,content = "/"..self:maybetopercent(tConfig["init"..index])})                
        --     elseif   aiData.data[tostring(index)] - t["attr"..index]<0  then
        --         table.insert(arg,{fontID = 13,content = tostring(self:maybetopercent(t["attr"..index]/100))})
        --         table.insert(arg,{fontID = 24,content = tostring(self:maybetopercent((aiData.data[tostring(index)] - t["attr"..index])/100))})
        --         table.insert(arg,{fontID = 13,content = "/"..self:maybetopercent(tConfig["init"..index])})                
        --     else
        --         table.insert(arg,{fontID = 13,content = tostring(self:maybetopercent(t["attr"..index]/100))})
        --         table.insert(arg,{fontID = 13,content = "/"..self:maybetopercent(tConfig["init"..index])})                  
        --     end
        -- else
        --     table.insert(arg,{fontID = 13,content =self:maybetopercent(tConfig["init"..index]).. "/"..self:maybetopercent(tConfig["init"..index])})
        -- end
        -- ui.createRichLabel(arg,self.rootItems["progress"..index.."Node"])
        -- self:setRichLablePositionX(self.rootItems["progress"..index.."Node"],arg)

        print(aiData.data[tostring(index)] - t["attr"..startin],"差值")
        if aiData.data[tostring(index)] - t["attr"..startin] > 0 then
            self.rootItems["addNode"..index]:setVisible(true)
            self.rootItems["addSpr"..index]:setVisible(true)
            self.rootItems["decreaseNode"..index]:setVisible(false)
            if tConfig["init"..index] < 1 then
                ui.setLabelString(self.rootItems["addNumText"..index],"+"..tostring(aiData.data[tostring(index)] - t["attr"..startin]) .. "%",22)
            else
                ui.setLabelString(self.rootItems["addNumText"..index],"+"..(aiData.data[tostring(index)] - t["attr"..startin]),22)
            end
            self.rootItems["addSpr"..index]:setVisible(true)
        elseif  aiData.data[tostring(index)] - t["attr"..startin] < 0  then
            self.rootItems["addNode"..index]:setVisible(false)
            self.rootItems["addSpr"..index]:setVisible(false)
            self.rootItems["decreaseNode"..index]:setVisible(true)
            if tConfig["init"..index] < 1 then
                ui.setLabelString(self.rootItems["decreaseNumText"..index],tostring(aiData.data[tostring(index)] - t["attr"..startin]).."%",24)
            else
                ui.setLabelString(self.rootItems["decreaseNumText"..index],aiData.data[tostring(index)] - t["attr"..startin],24)
            end
        else
            if tConfig["init"..index] > 1 and tConfig["init"..index] ~= aiData.data[tostring(index)] then
                self.rootItems["addNode"..index]:setVisible(false)
                self.rootItems["decreaseNode"..index]:setVisible(false)                
            elseif tConfig["init"..index] < 1 and tConfig["init"..index]*100 ~= aiData.data[tostring(index)] then
                self.rootItems["addNode"..index]:setVisible(false)
                self.rootItems["decreaseNode"..index]:setVisible(false)
            else
                ui.setLabelString(self.rootItems["addNumText"..index],"最大",22)
                self.rootItems["addNode"..index]:setVisible(true)
                self.rootItems["addSpr"..index]:setVisible(false)
                self.rootItems["decreaseNode"..index]:setVisible(false)                
            end
        end


	end

    printT(aiData,"aiData")

	for i = 1,4 do
		if aiData.data[tostring(i)] ~= nil then  
			resetLable(i,i+startindex) 
		end
	end

end
--1363回调 匠造确定
function magic.changeAttr(self,aiData)
    self.previeState = false
    self.data =  aiData.magicdata
	self:setButtonShowType(0)
    self.rootItems.upOneButton:setTouchEnabled(true)
    self.rootItems.upFiveButton:setTouchEnabled(true)
    self.rootItems.upTenButton:setTouchEnabled(true)     
    self:changeNode(aiData.requestData.id)
    -- self.rootItems.progress1Node:removeAllChildrenWithCleanup(true)
    -- self.rootItems.progress2Node:removeAllChildrenWithCleanup(true)
    -- self.rootItems.progress3Node:removeAllChildrenWithCleanup(true)
    -- self.rootItems.progress4Node:removeAllChildrenWithCleanup(true)
    -- local tConfig = self.artifactConfig[tostring(aiData.requestData.id)]
    local tConfig = self.artifactConfig[tostring(aiData.requestData.id)]
    local startindex = 0
    if self.tuPoStatus>0 then
       -- tConfig = self.artifactConfigxian[tostring(self.selecetID)][self.tuPoStatus]
       tConfig= self.artifactConfigxian[tostring(aiData.requestData.id)][tostring(self.tuPoStatus)]
       startindex = 4
    end   

    print(self.tuPoStatus,"self.tuPoStatus")
    printT(tConfig,"changeAttr tConfig---------")

    local t = nil
    for k,v in pairs(aiData.magicdata.unlock) do
        if v.id == aiData.requestData.id then
            t = v
            break
        end
    end 
	local function resetLable(index,startin)
     --    local arg = {}
     --    if aiData.data[tostring(index)] <= tConfig["init"..index] and tConfig["init"..index] >= 1 then
     --        table.insert(arg,{fontID = 13,content = t["attr"..index].."/"..tConfig["init"..index]})
     --    elseif aiData.data[tostring(index)] <= tConfig["init"..index]*100 and tConfig["init"..index] < 1 then
     --        table.insert(arg,{fontID = 13,content = self:maybetopercent( t["attr"..index]/100).."/"..self:maybetopercent(tConfig["init"..index])})
	    -- else
     --        table.insert(arg,{fontID = 13,content = self:maybetopercent(tConfig["init"..index]).."/"..self:maybetopercent(tConfig["init"..index])})
     --    end
     --    ui.createRichLabel(arg,self.rootItems["progress"..index.."Node"])
     --    self:setRichLablePositionX(self.rootItems["progress"..index.."Node"],arg)  

        self.rootItems["decreaseNode"..index]:setVisible(false) 
        if tConfig["init"..index] >= 1 then 
            ui.setLabelString(self.rootItems["text"..index],t["attr"..startin],22)
            if aiData.data[tostring(index)] <= tConfig["init"..index] then
                self.rootItems["addNode"..index]:setVisible(false)  
            else
                self.rootItems["addNode"..index]:setVisible(true)  
                ui.setLabelString(self.rootItems["addNumText"..index],"Max",22)
                self.rootItems["addSpr"..index]:setVisible(false)
            end
        else
            ui.setLabelString(self.rootItems["text"..index],t["attr"..startin].."%",22)
            if aiData.data[tostring(index)] <= tConfig["init"..index]*100 then
                self.rootItems["addNode"..index]:setVisible(false)  
            else
                self.rootItems["addNode"..index]:setVisible(true)  
                ui.setLabelString(self.rootItems["addNumText"..index],"Max",22)
                self.rootItems["addSpr"..index]:setVisible(false)
            end            
        end  

    end

    printT(aiData,"aiData")

    for i = 1,4 do
        if aiData.data[tostring(i)] ~= nil then  
            resetLable(i,i+startindex) 
        end
    end
end
--小数变百分数 整数不变
function magic.maybetopercent( self , aiNum )
    if aiNum < 1 and aiNum >0 then
        return aiNum * 100 .."%"
    elseif aiNum > -1 and aiNum < 0 then
        return aiNum * 100 .."%"
    else
        return aiNum
    end
end


function magic.setTupoPropNum( self, t)
    for k,v in pairs(t) do
        if self.tupo_needprops[tostring(k)] then
            self.tupo_needprops[tostring(k)].has = v
        end
    end
    for k,v in pairs(self.tupo_needprops) do
        if v.has >= v.num then
            ui.setLabelString(self.rootItems["i_num"..((v.index == 1) and "" or ("_"..(v.index-1)))],v.has.."/"..v.num,13)
        else
            ui.setLabelString(self.rootItems["i_num"..((v.index == 1) and "" or ("_"..(v.index-1)))],v.has.."/"..v.num,24)
        end
    end
end

function magic.showHasNum(self,num)
    local stonenums = self.stoneNum
    if num > 0 then
        stonenums = num
    end    
    if self.tuPoStatus > 0  then --判断仙或者凡锻造
         self.rootItems.xilianxiaohao2:setVisible(true)
         self.rootItems.xilianxiaohao:setVisible(false)
         ui.setLabelString(self.rootItems.stoneNum2,stonenums,13)
         ui.setLabelString(self.rootItems.xianyuanNum,self.g_gold,13)
    else
         ui.setLabelString(self.rootItems.stoneNum,stonenums,13)
         self.rootItems.xilianxiaohao2:setVisible(false)
         self.rootItems.xilianxiaohao:setVisible(true)
    end    
end

return magic