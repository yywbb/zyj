hellAllReward = {
	root = nil,
	rootNode = nil,
    rootItems = nil,
}

-- 打开弹窗
function hellAllReward.open(self, touchPriority, data, callback)
	self.root = CCNode:create()
    self.rewardConfig = gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]["finalDrop"]
    self.touchPriority = touchPriority
    self:initNode()
    self:initEvent()
    self:reloadData(data)

    return self.root
end

-- 初始化ccb
function hellAllReward.initNode(self)
	self.rootNode, self.rootItems = CCBReaderLoad("copyhell/copyhell_allfinish", nil, true, "copyhell_allfinish")
    self.rootNode:setPosition(0, 0)
    self.root:addChild(self.rootNode)
end

-- 初始化点击按钮
function hellAllReward.initEvent(self)
	self:initRewardBtn()
end

-- 初始奖励预览按钮
function hellAllReward.initRewardBtn(self)
	local _callback = function()
        if self.isAllClear == 0 then
        	runGamePrompt({msg = gameConfig.strings:string_common("hell", 21)})
        elseif self.isAllClear == 1 then
        	UIRequest({type = 6114})
       	elseif self.isAllClear == 2 then
       		runGamePrompt({msg = gameConfig.strings:string_common("hell", 22)})
       	end
    end

    self:commonBtn("rewardBtn", _callback)
end

function hellAllReward.reloadData(self, data)
	self.isAllClear = data
	local _t = ui.Split(self.rewardConfig, ";")
	local _usedata = {}

    for k,v in pairs(_t) do
        if v ~= "" or v == nil then
            table.insert(_usedata, ui.Split(v, ","))
        end
    end

    local _len = table.getTableLength(_usedata)

    for i = 1, 4 do
        if i <= _len then
            local _key_Ex = ""
            
            if i == 1 then
                _key_Ex = ""
            else
                _key_Ex = "_"..(i-1)
            end

            self.rootItems["reward"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems, {cid = _usedata[i][1], num = _usedata[i][2]}, i - 1)
            
            local _cb = function()
                if _usedata[i][1] and _usedata[i][1] ~="" then
                    ui.setPopwindowByCid(_usedata[i][1])
                end
            end

            self:commonBtn("i_button".._key_Ex, _cb)
        else
            self.rootItems["reward"..i]:setVisible(false)
        end
    end

    self:refreshButton(data)
end

function hellAllReward.refreshButton(self)
	if self.isAllClear == 0 then
		ui.addGray("CCControlButton", self.rootItems["rewardBtn"])
		ui.setLabelString(self.rootItems.rewardTxt, gameConfig.strings:string_common("hell", 18), 17)
	elseif self.isAllClear == 1 then
		ui.removeGray("CCControlButton", self.rootItems["rewardBtn"])
		ui.setLabelString(self.rootItems.rewardTxt, gameConfig.strings:string_common("hell", 19), 17)
	elseif self.isAllClear == 2 then
		ui.addGray("CCControlButton", self.rootItems["rewardBtn"])
		ui.setLabelString(self.rootItems.rewardTxt, gameConfig.strings:string_common("hell", 20), 17)
	end
end

function hellAllReward.close(self)
	self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
end

function hellAllReward.commonBtn(self, btnName, callback)
    self.rootItems[btnName]:setSwallowsTouch(true)
    self.rootItems[btnName]:setTouchPriority(self.touchPriority - 1)
    self.rootItems[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return hellAllReward