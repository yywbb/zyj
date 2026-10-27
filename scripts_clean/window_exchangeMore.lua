--
-- 珍品折扣、喷他Q、八戒圆梦有兑换的地方，点击兑换时，弹出购买多次的弹窗。可以一次兑换多个。
-- User: zzx
-- Date: 16/12/1
--

local exchangeMore = {
    rootNode = nil,
    rootItems = nil,
   	callback = nil,
   	exchangeNum = 0,
    isOnce = true,
   	delayButtonStatus = true,

    type = nil,
}
-- data = {}
-- data.max --能兑换最大次数
function exchangeMore.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("windows/tc_more", nil, true, "tc_more")
    
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),19)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),19)
    
	self.touchPriority = touchPriority
    self.isOnce = true

    if data.type and data.type == "buy" then
        self.type = data.type
        self.rootItems.fixedTitle:setString(gameConfig.strings:string_common("fixedString","exchangeMore",4))
        self.rootItems.desc:setString(string.format(gameConfig.strings:string_common("fixedString","exchangeMore",5),data.max))
    else
        self.type = nil
        self.rootItems.fixedTitle:setString(gameConfig.strings:string_common("fixedString","exchangeMore",1))
        self.rootItems.desc:setString(string.format(gameConfig.strings:string_common("fixedString","exchangeMore",2),data.max))
    end

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.buynum,self.touchPriority,function (num)
        self.exchangeNum = 0
        self:numchange(num)
    end)    

    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("exchangeMore")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)
    
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("exchangeMore")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.doButton2:addHandleOfControlEvent(function()
    	if self.data.max < self.exchangeNum then
            runGamePrompt({msg = gameConfig.strings:string_common("exchange",1)})
            return
    	end
        self.callback(self.exchangeNum)
        self.callback = nil
        gameWindows:closeWindow("exchangeMore")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    --
    self.rootItems.add1:addHandleOfControlEvent(function()
    -- self:numchange(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
    -- self:numchange(10)
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)

    self.rootItems.sub1:addHandleOfControlEvent(function()
    -- self:numchange(-1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub10:addHandleOfControlEvent(function()
    -- self:numchange(-10)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)
    --

    self:reload(data,callback)
    self:setAddandReduceBtn()
	return self.rootNode
end

function exchangeMore.reload(self,data,callback)
    self.callback = callback
    self.data = data
    self.exchangeNum = 0
    self:numchange(1)
end


function exchangeMore.relaodData(self,num)
    self.data.max =  self.data.max - num
    if self.data.max < 0 then
        self.data.max = 0
    end
    if self.type and self.type == "buy" then
        self.rootItems.desc:setString(string.format(gameConfig.strings:string_common("fixedString","exchangeMore",5),self.data.max)) 
    else
        self.rootItems.desc:setString(string.format(gameConfig.strings:string_common("fixedString","exchangeMore",2),self.data.max)) 
    end
    if self.data.max <  self.exchangeNum then
        self.exchangeNum = 0
        self:numchange(self.data.max)        
    end
end
-- 增加 减少按钮
function exchangeMore.setAddandReduceBtn( self )

    local beginFunc = function(index)
        print("beginFunc"..index)
    end

    local endFunc = function(index)
        print("endFunc"..index)
    end
    --
    local Func1 = function()
        print("Func1====")
        self:numchange(1)
        self.isOnce = false
    end

    local Func2 = function()
        print("Func2====")
        self:numchange(10)
        self.isOnce = false
    end


    local reduce1 = function()
        print("reduce1====")
        self:numchange(-1)
        self.isOnce = false
    end

    local reduce2 = function()
        print("reduce2====")
        self:numchange(-10)
        self.isOnce = false
    end
    print("aaaaaa====")
    -- printT(self.rootItems)
    if self.delayButtonStatus then
        print("setbtn====")
        ui.creatDelayButton(self.rootItems.add1,self.touchPriority,Func1,beginFunc,endFunc,1)
        ui.creatDelayButton(self.rootItems.add10,self.touchPriority,Func2,beginFunc,endFunc,2)

        ui.creatDelayButton(self.rootItems.sub1,self.touchPriority,reduce1)
        ui.creatDelayButton(self.rootItems.sub10,self.touchPriority,reduce2)
    end
    self.delayButtonStatus = false

end

function exchangeMore.numchange(self,num)

	if  self.exchangeNum + num <= 1 then 
		self.exchangeNum = 1
	elseif  self.data.max <=  self.exchangeNum + num then
		self.exchangeNum = self.data.max 
	else
        if self.exchangeNum == 1 then
            if num == 10 and self.isOnce == true then
                self.exchangeNum = 10
            else
                self.exchangeNum = self.exchangeNum + num
            end
        else
            self.exchangeNum = self.exchangeNum + num
        end
	end
	self.rootItems.buynum:setString(self.exchangeNum)	
end

function exchangeMore.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.isOnce = true
    self.callback = nil
    self.delayButtonStatus = true
end


return exchangeMore