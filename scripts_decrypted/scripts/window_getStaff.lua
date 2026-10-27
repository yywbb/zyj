--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/18
-- Time: 下午2:45
-- To change this template use File | Settings | File Templates.
--

local get = {
    rootNode = nil,
    rootItems = nil,

    data = {},
    des = nil,

    needcallback = true
}

function get.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    if data.type then
        self.data = data.data
        self.des = data.type
    else
        self.data = data.data or data
    end

    self.tip = data.tip

    self.isrewarddouble = data.isrewarddouble
    printT(data, "恭喜获得==")
    print("名称", data.type)
    if table.getTableLength(self.data) >1 or data.type then
        self.rootNode, self.rootItems = CCBReaderLoad("windows/tc_gongxihuode", nil, true, "tc_gongxihuode")
        self:reloadMany(self.data,callback)

        self.rootItems.timetext1:setString("");
        self.rootItems.timetext2:setString("");
        self.rootItems.timetext3:setString("");
        if guide.controller and guide.controller.isOnGuide == false then
            if not data.type then               
                gameTimer:rigistTime("getStaff_play", 5)
                self.rootItems.timetext1:setString("(");
                self.rootItems.timetext2:setString("5");
                self.rootItems.timetext3:setString(")秒后关闭");
                gameTimer:rigistTimeFunc("getStaff_play",function()
                    if gameTimer.times["getStaff_play"] > 0 then
                        self.rootItems.timetext1:setString("(");
                        self.rootItems.timetext2:setString(gameTimer.times["getStaff_play"]);
                        self.rootItems.timetext3:setString(")秒后关闭");
                    end
                    if gameTimer.times["getStaff_play"] < 1 then
                        gameTimer:UnrigistTimeFunc("getStaff_play")
                        gameWindows:closeWindow("getStaff");
                    end
                end)
            end
        end
        

        self.root:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
            if guide.controller.isOnGuide == true then
                guide.controller:setGuideLayerVisible(true)
            end
        end)))
    else
        local datatmp = {}
        datatmp = self.data["1"] or self.data[1]

        local isspecial = false
        if not data.isspecial then
            isspecial = gamedata.config:getConfigByName("drop_special") and gamedata.config:getConfigByName("drop_special")[tostring(datatmp.cid)]
        else
            isspecial = data.isspecial
        end
        
        local config = ui.IDconfig(datatmp.cid)
        if config.staffType == "title" then
           self.rootNode, self.rootItems = CCBReaderLoad("windows/tc_huodeyigewupin3", nil, true, "zhuxiantai_jiacheng")
        else
            self.rootNode, self.rootItems = CCBReaderLoad("windows/tc_huodeyigewupin"..(isspecial and "2" or ""), nil, true, "zhuxiantai_jiacheng")
        end
        self:reloadOne(self.data,callback)
    end

    if self.rootItems.descstring and data and data.desc then
        self.rootItems.descstring:setVisible(true)
        ui.setLabelString(self.rootItems.descstring,data.desc,13)       
    end    

    self:doubleRewardSet()
    self.root:addChild(self.rootNode)

    --检测称号获得 提示弹窗
    self:checkTitle()
    return self.root
end

function get.checkTitle(self)

    for k,v in pairs(self.data) do
        local config = ui.IDconfig(v.cid)
        if config.staffType == "title" or config.staffType == "iconBox" then
            if v.cid ~= GameScene.roleinfo.title and v.cid ~= GameScene.roleinfo.iconBox then
                saveTitleOnceToSqlite(v.cid,1)
            end

            local isspecial = gamedata.config:getConfigByName("drop_special") and gamedata.config:getConfigByName("drop_special")[tostring(v.cid)]
            if table.getTableLength(self.data) == 1 then
                runGamePromptTitle({type = config.staffType,name = config.name,time = v.time})
            else
                if not isspecial then
                    runGamePromptTitle({type = config.staffType,name = config.name,time = v.time})
                end
            end
        end
    end
end

-- 双倍活动2016年7月活动
function get.doubleRewardSet(self)
    if self.tip then
        self.rootItems.isdouble:setVisible(false)
        self.rootItems.isrewarddouble:setVisible(true)
        ui.setLabelString(self.rootItems.isrewarddouble,self.tip,24)
        return
    end
    if not self.rootItems.isrewarddouble then return end
    if self.isrewarddouble or GameScene.isrewarddouble then
        self.rootItems.isrewarddouble:setVisible(true)
        ui.setLabelString(self.rootItems.isrewarddouble,gameConfig.strings:string_common("doublereward",1),24)
        self.rootItems.isdouble:setVisible(false)
    else
        self.rootItems.isrewarddouble:setVisible(false)
    end
end

function get.reloadMany(self,data,callback)
    self.callback = callback
    if self.des then
        self.rootItems.des:setString(self.des)
    end
    print("弹窗的名称", self.rootItems.des:getString())
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("getStaff")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local shareshow =  self.des and gameConfig:checkBuildOpen(153) and (not guide.controller or not guide.controller.isOnGuide)

    -- ui.setLabelString(self.rootItems.confirmtext,"确 定",18)
    if shareshow then
        self.rootItems.shareNode:setVisible(true)
        ui.setLabelString(self.rootItems.shareText, "分 享", 19)
        self.rootItems.shareBtn:addHandleOfControlEvent(function()
            print("分享")
            gameWindows:closeWindow("getStaff")
        end, CCControlEventTouchUpInside)
        self.rootItems.shareBtn:setSwallowsTouch(true)
        self.rootItems.shareBtn:setTouchPriority(self.touchPriority)    
        self.rootItems.confirmNode:setPositionX(700)
    else
        self.rootItems.shareNode:setVisible(false)
        self.rootItems.confirmNode:setPositionX(504)
    end

    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),19)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        guide:setGuideProlayer(true)
        gameWindows:closeWindow("getStaff")
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)

    local datatmp = {}
    datatmp = self.data["1"] or self.data[1]
    if self.rootItems.isdouble and datatmp.double and datatmp.double == 1 then
        self.rootItems.isdouble:setVisible(true)
        --ui.setLabelString(self.rootItems.isdouble,nil,14)
    else
        self.rootItems.isdouble:setVisible(false)
    end


    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(850, 300)
        elseif fn == "cellAtIndex" then

            local CCB,item = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                for i=1,4 do
                    CCB[i],item[i] = CCBReaderLoad("icons/new_iconName2.ccbi", nil, true, "new_iconName2")
                end
                celldict[a2] = {CCB=CCB,item=item }
            else
                first = false

                CCB = celldict[a2].CCB
                item = celldict[a2].item
            end

            for i =1, 4 do
                local data1 = self.data[tostring(4*(a1) +i)] or self.data[(4*(a1) +i)]
                if data1 then
                    CCB[i]:setVisible(true)
                    ui.setNewIconName(item[i],data1)

                    item[i].in_button:setTouchPriority(self.touchPriority)
                    item[i].in_button:addHandleOfControlEvent(function()
                        local config = ui.IDconfig(data1.cid)
                        if config.staffType and config.staffType == "qiling" then
                            gameWindows:openWindow("qilingInfo",{iid = data1.iid,opt = 3})
                        else
                            ui.setPopwindowByCid(data1.cid)
                        end
                    end, CCControlEventTouchUpInside)

                    if data1.probability and data1.probability ~= 100 then
                        item[i].in_extranode:setVisible(true)
                    else
                        item[i].in_extranode:setVisible(false)
                    end

                else
                    CCB[i]:setVisible(false)
                end

                CCB[i]:setPosition(200*(i-0.5)+25, 200)
                if first then
                    a2:addChild(CCB[i])
                end
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.data)/4)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    ListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listScroll:addChild(ListTableView)

end

function get.reloadOne(self,data,callback)
    self.callback = callback
    ui.setNewIconName(self.rootItems,self.data["1"] or self.data[1])

    local datatmp = {}
    datatmp = self.data["1"] or self.data[1]

    local config = ui.IDconfig(datatmp.cid)
    if config.staffType == "title" then
        self.rootItems.in_name:setVisible(false)
    else
        self.rootItems.in_name:setVisible(true)
    end


    if self.rootItems.isdouble and datatmp.double and datatmp.double == 1 then
        self.rootItems.isdouble:setVisible(true)
        ui.setLabelString(self.rootItems.isdouble,nil,14)
    else
        self.rootItems.isdouble:setVisible(false)
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.rootNode:stopAllActions()
        gameWindows:closeWindowDirect("getStaff")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

--    self.rootItems.general:removeAllChildrenWithCleanup(true)
--    local ma = CCSkeletonAnimation:create("change/change.json","change/change.atlas",2)
--    ma:setAnimation("stand",true,0)
--    self.rootItems.general:addChild(ma)

    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        gameWindows:closeWindow("getStaff")

    end)))
end

function get.close(self)
    gameTimer:UnrigistTimeFunc("getStaff_play")
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.des = nil

    if guide.controller then
        guide.controller:setGuideLayerVisible(true)
    end

    if self.callback then
        self.callback()
    end
    self.isrewarddouble = false
    GameScene.isrewarddouble = false
end

return get  Z-  