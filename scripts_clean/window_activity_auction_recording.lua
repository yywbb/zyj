auctionRecording = {
    
}

function auctionRecording.close(self)
	self.listTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function auctionRecording.open(self, touchPriority, data, callback)
	self:initNode(touchPriority)
	self:initConfig()
	self:initEventBtn()

	UIRequest({type = 5412})

    return self.rootNode
end

function auctionRecording.initNode(self, touchPriority)
	self.rootNode, self.rootItems = CCBReaderLoad("activitygudong/gudong_rizhi", nil, true, "gudong_rizhi")
	self.touchPriority = touchPriority
end

function auctionRecording.initConfig(self)
	self.antiqueNpcAnimation = gamedata.config.antique_npc_animation
	self.antiqueItem = gamedata.config.antique_item
	self.props = gamedata.config.props
end

function auctionRecording.initEventBtn(self)
	self:initCloseBtn()
end

function auctionRecording.initCloseBtn(self)
	local _cb = function()
		gameWindows:closeWindow("activityAuctionRecording")
	end

	self:commonBtn(self.rootItems, "closeButton", _cb)
end

function auctionRecording.reloadData(self, data)
	self.data = data.recordingTable

	self:getSizeTable()

	if self.data and next(self.data) then
        if not self.listTableView then
            self:creatList()
        else
            self.listTableView:reloadData()
        end
	end
end

function auctionRecording.getSizeTable(self)
	self.sizeTable = {}
	local _label = ui.createLabel({
        fontsize = 34,
        font = "Helvetica-Bold",
    })

	for i = 1, table.getTableLength(self.data) do
		local _height = 0
		local _auctionId = self.data[tostring(i)].auctionId
		local _str = self.props[tostring(_auctionId)].name
		local _resultType = self.antiqueItem[tostring(_auctionId)].coinID
		_label:setString(_str)
		_height = _label:getContentSize().height
		
		local _recording = self.data[tostring(i)].recording or {}
		_str = ""


        if table.getTableLength(_recording) <= 0 then
           _str = "一键拍卖\n拍啥\n"
        else
			for j = 1, table.getTableLength(_recording) do
				if j ~= table.getTableLength(_recording) then
					_str = _str..gameConfig.strings:activityAuctionResult1(j, self.antiqueNpcAnimation[tostring(_recording[tostring(j)].npcId)].npcname, _recording[tostring(j)].price, _resultType)
				else
					_str = _str..gameConfig.strings:activityAuctionResult1(j, self.antiqueNpcAnimation[tostring(_recording[tostring(j)].npcId)].npcname, _recording[tostring(j)].price, _resultType)

					if _recording[tostring(j)].npcId ~= 0 then
						_str = _str..gameConfig.strings:activityAuctionResult2(_recording[tostring(j)].price, _resultType)
					elseif _recording[tostring(j)].npcId == 0 then
						local _result = ""

						if self.data[tostring(i)].trueOrFalse == 0 then
							_result = gameConfig.strings:string_common("activityAuction", 3)
						elseif self.data[tostring(i)].trueOrFalse == 1 then
							_result = gameConfig.strings:string_common("activityAuction", 4)
						end

						_str = _str..gameConfig.strings:activityAuctionResult3(_result, _recording[tostring(j)].price, _resultType)
					end
				end
			end
        end 	


		

		_label:setString(_str)
		_height = _height + _label:getContentSize().height

		table.insert(self.sizeTable, _height)
	end

	printT(self.sizeTable)
end

function auctionRecording.creatList(self)
    local _celldict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r

        if fn == "cellSize" then
            
        elseif fn == "hasFixedCellSize" then
            _r = false
        elseif fn == "cellSizeForIndex" then
        	_r = CCSizeMake(930, self.sizeTable[a1+1])
        elseif fn == "isRecycle" then
            return false
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = 0, 0
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("activitygudong/cell_recording", nil, true, "cell_recording")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end

            self:setCell(_ccbDocumentControler, self.data[tostring(a1 + 1)], a1 + 1)

          	_cellCCB:setPosition(0, 0)

            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems["scrollList"]:getContentSize().width,
        viewheight = self.rootItems["scrollList"]:getContentSize().height,
        dire = 1
    })
    self.rootItems["scrollList"]:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority - 1)
end

function auctionRecording.setCell(self, item, data, index)
	local _auctionId = data.auctionId
	local _resultType = self.antiqueItem[tostring(_auctionId)].coinID



	local _recording = data.recording
	_str = ""

	if table.getTableLength(_recording) <= 0 then
		ui.setLabelString(item.recordingTxt1, gameConfig.strings:activityAuctionResultOnekey(data.startTime), 14)
		ui.setLabelString(item.recordingTxt2, self.props[tostring(_auctionId)].name.."X"..data.num, 23)
		ui.setLabelString(item.recordingTxt3, "", 23)
		_str =  gameConfig.strings:activityAuctionOnekey(data.right,data.wrong,data.chengjiao)..gameConfig.strings:activityAuctionOnekeyCoin(data.getgold,_resultType)
	    -- local rich = {
     --            {fontID = 1,content = "其中真品",},
     --            {fontID = 0,content = ""..data.right,},
     --            {fontID = 11,content = "件，赝品",},
     --            {fontID = 1,content = ""..data.wrong},
     --            {fontID = 11,content = "件，成交"},
     --            {fontID = 1,content = ""..data.chengjiao},
     --            {fontID = 1,content = "件\n"},
     --        }
        -- ui.createRichLabel(rich,item.recordingRichTxt4,false,{horizontal = "center",vertical = "center"})
        item.recordingTxt4:setVisible(true)
        -- item.recordingRichTxt4:setVisible(false)
		ui.setLabelString(item.recordingTxt4, _str, 14)

	else	
		ui.setLabelString(item.recordingTxt1, gameConfig.strings:activityAuctionResult(data.startTime), 14)
		ui.setLabelString(item.recordingTxt2, self.props[tostring(_auctionId)].name, 23)
		ui.setLabelString(item.recordingTxt3, "", 23)
		item.recordingTxt4:setVisible(true)
        -- item.recordingRichTxt4:setVisible(false)

		for i = 1, table.getTableLength(_recording) do
			if i ~= table.getTableLength(_recording) then
				_str = _str..gameConfig.strings:activityAuctionResult1(i, self.antiqueNpcAnimation[tostring(_recording[tostring(i)].npcId)].npcname, _recording[tostring(i)].price, _resultType)
			else
				_str = _str..gameConfig.strings:activityAuctionResult1(i, self.antiqueNpcAnimation[tostring(_recording[tostring(i)].npcId)].npcname, _recording[tostring(i)].price, _resultType)
				if _recording[tostring(i)].npcId ~= 0 then
					_str = _str..gameConfig.strings:activityAuctionResult2(_recording[tostring(i)].price, _resultType)
				elseif _recording[tostring(i)].npcId == 0 then
					local _result = ""
					local _price = 0
					if data.trueOrFalse == 0 then
						_result = gameConfig.strings:string_common("activityAuction", 3)
						_price = 0
						ui.setLabelString(item.recordingTxt3, "(".._result..")", 51)
					elseif data.trueOrFalse == 1 then
						_result = gameConfig.strings:string_common("activityAuction", 4)
						_price = _recording[tostring(i)].price
						ui.setLabelString(item.recordingTxt3, "(".._result..")", 52)
					end
					
					_str = _str..gameConfig.strings:activityAuctionResult3(_result, _price, _resultType)
				end
			end
		end
		ui.setLabelString(item.recordingTxt4, _str, 14)
    end		

	local _list = {}
    table.insert(_list, {node = item.recordingTxt1})
    table.insert(_list, {node = item.recordingTxt2})
    table.insert(_list, {node = item.recordingTxt3})
    ui.setCCNodeListRight(_list, 1)


end

-- 通用按钮
function auctionRecording.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return auctionRecording