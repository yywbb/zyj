--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local wingcolorset = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    index = 1,
    wing = {},
    protagonist = {},
    wingcolor = {},
    colorindex = {},
}

function wingcolorset.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    print("i...am...wingcolor")
    self.rootNode, self.rootItems = CCBReaderLoad("wing/wing_ranse.ccbi", nil, true, "wingranse")
    self.root:addChild(self.rootNode)


    --
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            return true
        end
    end

    local function ccTouchMoved(x, y)

    end

    local function ccTouchEnded(x, y)
        if x-self.touchX > 20 then
            gameTouch:clickprofbytime(1)
            if self.index > 1 then
                self.index = self.index-1
                self:showcolor()
            end
        elseif self.touchX-x > 20 then
            gameTouch:clickprofbytime(1)
            if self.index < #self.colorindex then
                self.index = self.index+1
                self:showcolor()
            end
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end
    if self.rootItems.touchLayer then
        self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority, false)
        self.rootItems.touchLayer:setTouchPriority(self.touchPriority)
        self.rootItems.touchLayer:setTouchEnabled(true)
    end
    --


    UIRequest({type = 3744})

    return self.root
end


--
function wingcolorset.reloadData(self,data)

    if data then
        self.wing = data.wing
        self.protagonist = data.protagonist
        self.wingcolor = data.wingcolor
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("wingcolorset")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)

    self.index = 1

    self.colorindex = {}
    table.insert(self.colorindex,0)
    for i = 1,10 do
        if self.wingcolor[tostring(i)] and self.wingcolor[tostring(i)] > 0 then
            table.insert(self.colorindex,i)
        end
    end

    for k,v in ipairs(self.colorindex) do
        if self.wing.colortype and self.wing.colortype == v then
            self.index = tonumber(k)
        end
    end

    self:showcolor()

    self.rootItems.left:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.index > 1 then
            self.index = self.index-1
            self:showcolor()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.left:setSwallowsTouch(true)
    self.rootItems.left:setTouchPriority(self.touchPriority-1)

    self.rootItems.right:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.index < #self.colorindex then
            self.index = self.index+1
            self:showcolor()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.right:setSwallowsTouch(true)
    self.rootItems.right:setTouchPriority(self.touchPriority-1)

end

function wingcolorset.showcolor(self)

    if self.index <= 1 then
        self.rootItems.leftSprite:setVisible(false)
    else
        self.rootItems.leftSprite:setVisible(true)
    end
    if self.index < #self.colorindex then
        self.rootItems.rightSprite:setVisible(true)
    else
        self.rootItems.rightSprite:setVisible(false)
    end


    local nowstageconfig = gamedata.config.wing_stage[tostring((self.wing.stagenum == 0) and 1 or self.wing.stagenum)]
    ui.setLabelString(self.rootItems.generalname,nowstageconfig.name,1)

    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.protagonist.general.cid)].animationid)].name
    local wing = {level = self.wing.stagenum, color = self.colorindex[self.index], show = 1}
    local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1.6)
    Gneral1:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(Gneral1.root or Gneral1)

    self.rootItems.useButton:setTouchPriority(self.touchPriority-1)
    self.rootItems.setButton:setTouchPriority(self.touchPriority-1)

    if self.colorindex[self.index] == self.wing.colortype then
        self.rootItems.used:setVisible(true)
        self.rootItems.setNode:setVisible(false)
        self.rootItems.useNode:setVisible(true)
        self.rootItems.useButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","wing",1)})
        end, CCControlEventTouchUpInside)
        self.rootItems.useButton:setSwallowsTouch(true)
        ui.setLabelString(self.rootItems.useLab,gameConfig.strings:string_common("fixedString","wing",1),19)
        ui.addGray("CCControlButton", self.rootItems.useButton)
    elseif self.colorindex[self.index] == 0 or (self.wingcolor[tostring(self.colorindex[self.index])] and self.wingcolor[tostring(self.colorindex[self.index])] == 2) then
        self.rootItems.used:setVisible(false)
        self.rootItems.setNode:setVisible(false)
        self.rootItems.useNode:setVisible(true)
        self.rootItems.useButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 3743, id = self.colorindex[self.index]})
        end, CCControlEventTouchUpInside)
        self.rootItems.useButton:setSwallowsTouch(true)
        ui.setLabelString(self.rootItems.useLab,gameConfig.strings:string_common("fixedString","wing",2),19)
        ui.removeGray("CCControlButton", self.rootItems.useButton)
    else
        self.rootItems.used:setVisible(false)
        self.rootItems.setNode:setVisible(true)
        self.rootItems.useNode:setVisible(false)

        local cost = {}
        if gamedata.config.wing_coler[tostring(self.colorindex[self.index])] and gamedata.config.wing_coler[tostring(self.colorindex[self.index])].item_id then
            cost.cid = gamedata.config.wing_coler[tostring(self.colorindex[self.index])].item_id
            if gamedata.config.wing_stage[tostring(self.wing.stagenum)] and gamedata.config.wing_stage[tostring(self.wing.stagenum)].cost_return then
                cost.num = tonumber(gamedata.config.wing_stage[tostring(self.wing.stagenum)].cost_return)
            else
                cost.num = 0
            end
        end

        self.rootItems.setButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 3743, id = self.colorindex[self.index], cost = cost})
        end, CCControlEventTouchUpInside)
        self.rootItems.setButton:setSwallowsTouch(true)
        ui.setLabelString(self.rootItems.setLab,gameConfig.strings:string_common("fixedString","wing",3),19)

        -- if cost and next(cost) then
        --     ui.setLabelString(self.rootItems.setnum,"x"..cost.num,14)
        --     setSpriteFrameByName(self.rootItems["propicon"], ui.IDconfig(cost.cid).icon)
        -- else
        --     ui.setLabelString(self.rootItems.setnum,"",14)
        --     setSpriteFrameByName(self.rootItems["propicon"], "alpha")
        -- end
        -- 染色材料数量请求
        local spendcid = {}
        table.insert(spendcid,cost["cid"])
        UIRequest({type = 12001, order = 14007, cids = spendcid})
    end

end

-- 消耗物品个数设置
function wingcolorset.setSpendPropsData(self,data)
    printT(data,"setSpendPropsData===")
    local cost = {}
    if gamedata.config.wing_coler[tostring(self.colorindex[self.index])] and gamedata.config.wing_coler[tostring(self.colorindex[self.index])].item_id then
        cost.cid = gamedata.config.wing_coler[tostring(self.colorindex[self.index])].item_id
        if gamedata.config.wing_stage[tostring(self.wing.stagenum)] and gamedata.config.wing_stage[tostring(self.wing.stagenum)].cost_return then
            cost.num = tonumber(gamedata.config.wing_stage[tostring(self.wing.stagenum)].cost_return)
        else
            cost.num = 0
        end
    end
    printT(cost,"wingcost===")
    if cost and next(cost) then
        if data[tostring(cost.cid)] and data[tostring(cost.cid)] < cost.num then
            ui.setLabelString(self.rootItems.setnum,data[tostring(cost.cid)].."/"..cost.num,27)
        else
            ui.setLabelString(self.rootItems.setnum,data[tostring(cost.cid)].."/"..cost.num,13)
        end
        printT(ui.IDconfig(cost.cid),"IDconfig===")
        print(ui.IDconfig(cost.cid).icon,"icon===")
        -- ui.setLabelString(self.rootItems.setnum,"/"..cost.num,14)
        setSpriteFrameByName(self.rootItems["propicon"], ui.IDconfig(cost.cid).icon)
    else
        ui.setLabelString(self.rootItems.setnum,"",14)
        setSpriteFrameByName(self.rootItems["propicon"], "alpha")
    end

    
end


function wingcolorset.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.index = 1
    self.wing = {}
    self.protagonist = {}
    self.wingcolor = {}

    if self.callback then
        self.callback()
    end
end

return wingcolorset   �'  