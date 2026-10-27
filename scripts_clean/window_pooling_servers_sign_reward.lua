local signReward = {
    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,
}

-- 关闭界面
function signReward.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    
    self.rootNode = nil
    self.rootItems = nil
end

-- 打开界面
function signReward.open(self,touchPriority,data,callback)
    self.day = data.day
    self:initNode(touchPriority)
    self:initConfig()
    self:initEventBtn()
    self:initReward()

    return self.rootNode
end

-- 初始化界面
function signReward.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("activityhefu/hefuhaoli_yulan", nil, true, "hefuhaoli_yulan")
    self.touchPriority = touchPriority
end

function signReward.initConfig(self)
    self.suitSignConfig = gamedata.config.suit_sign
end

function signReward.initEventBtn(self)
    self:setCloseBtn()
end

function signReward.setCloseBtn(self)
    local _cb = function()
        gameWindows:closeWindow("poolingServersSignReward")
    end

    self:commonBtn(self.rootItems, "closeButton", _cb)
end

function signReward.initReward(self)
    _reward = self.suitSignConfig[tostring(self.day)].reward

    local _t = ui.Split(_reward, ";")
    local _usedata = {}

    for k,v in pairs(_t) do
        if v ~= "" or v == nil then
            table.insert(_usedata, ui.Split(v, ","))
        end
    end

    local _len = table.getTableLength(_usedata)

    for i = 1, 8 do
        if i <= _len then
            local _key_Ex = ""
            
            if i == 1 then
                _key_Ex = ""
            else
                _key_Ex = "_"..(i - 1)
            end

            self.rootItems["reward"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems, {cid = _usedata[i][1], num = _usedata[i][2]}, i - 1)
            
            local _cb = function()
                if _usedata[i][1] and _usedata[i][1] ~="" then
                    ui.setPopwindowByCid(_usedata[i][1])
                end
            end

            self:commonBtn(self.rootItems, "i_button".._key_Ex, _cb)
        else
            self.rootItems["reward"..i]:setVisible(false)
        end
    end
end

-- 通用按钮
function signReward.commonBtn(self, item, btnName, callback, touchPriority, isSwallows)
    print(btnName)
    if isSwallows == false then
        item[btnName]:setSwallowsTouch(isSwallows)
    else
        item[btnName]:setSwallowsTouch(true)
    end

    item[btnName]:setTouchPriority(touchPriority or (self.touchPriority - 1))
    item[btnName]:addHandleOfControlEvent(callback, CCControlEventTouchUpInside)
end

return signReward