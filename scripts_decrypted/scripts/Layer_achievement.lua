--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/3
-- Time: 下午1:31
-- To change this template use File | Settings | File Templates.
--


local task = {

    rootNode = nil,
    rootItems = nil,

    normaltableview = nil,
    dailytableview = nil,

    dailydata = {},
    datarewards = {},
    itemdata = {},
    rewarddata = {},


    normaldata = {},

    activennum = 0,
    isscrolltouched = false,

}


function task.init(self,parent,toppos)

    self.rootNode,self.rootItems = CCBReaderLoad("achievements/achievements", nil, true, "achievements")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.normalScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-200))
    -- self.rootItems.dailyScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-200))

    -- --成就的全部领取
    ui.setLabelString(self.rootItems.allbuttontext, "一键领取" ,18)
    self.rootItems.allbutton:setSwallowsTouch(true)
    self.rootItems.allbutton:setTouchPriority(-102)
    self.rootItems.allbutton:addHandleOfControlEvent(function()
        if self.activennum > 0 then
            UIRequest({type = 2401, })
        else
            -- runGamePrompt({msg = "无可领取的奖励"})
            runGamePrompt({msg = gameConfig.strings:string_common("task",3)})
        end
    end, CCControlEventTouchUpInside)

    

    self.rootItems.button_back:setSwallowsTouch(true)
    self.rootItems.button_back:setTouchPriority(-121)
    self.rootItems.button_back:addHandleOfControlEvent(function()
        GameScene:shiftLayer("main","down")
    end, CCControlEventTouchUpInside)


    ui.setLabelString(self.rootItems.numText, nil, 18)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","achievement",touchbegin)
    local function touchend(pos)
        if self.rootItems.normalScroll and ui.isTouched(self.rootItems.normalScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","achievement",touchend)
    UIRequest({type =2400})
end

function task.clear(self)
    gameTouch:UnrigistFunc("begin","achievement")
    gameTouch:UnrigistFunc("end","achievement")
    self.isscrolltouched = false
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.firstdata = 0

    self.normaldata = {}
    self.normaltableview = nil
    self.activennum = 0
end


function task.setCell(self,item,data)
    print("data.cid ======"..data.cid)
    local config = gamedata.config.task[tostring(data.cid)]
    --setSpriteFrameByName(item.i_icon,  config.icon)
    --ui.setSpriteTextureRect(item.i_icon,0,0,150,150)
    ui.setNewIcon(item,{cid = config.award1})

    item.i_button:setTouchPriority(-102)
    item.i_button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        ui.setPopwindowByCid(config.award1)
    end, CCControlEventTouchUpInside)


    --item.i_soulsprite:setVisible(false)

    ui.setLabelString(item.rewardText,nil,21)


    ui.setLabelString(item.rewardnumLabel,"X"..config.award1num,21)
    -- local strname = "X"..config.award1num
    -- item.rewardnumLabel:setString(strname)
    local idconfig = ui.IDconfig(config.award1)
    setSpriteFrameByName(item.rewardIcon, idconfig.icon)

    item.rewardIcon:setScale(0.4)


    item.rewardnumLabel:setPositionX(item.rewardIcon:getPositionX() + item.rewardIcon:getContentSize().width * item.rewardIcon:getScale()/2 + 3)

    -- if (idconfig.staffType == "iconBox" or idconfig.staffType == "title") then
    --     item.rewardIcon:setScale(0.35)
    -- else
    --     item.rewardIcon:setScale(0.4)
    -- end

    item.des:setString(config.desc)
    -- local reward = "获得"..ui.IDconfig(config.award1).name.."X"..config.award1num
    local reward = gameConfig.strings:getAward(ui.IDconfig(config.award1).name,config.award1num)

    item.content:setString(reward)

    if data.now then
        item.targetnode:setVisible(true)
        if config.state == 0 then
            if data.status == 1 or data.status == -1 then
                ui.setLabelString(item.target, "1/1",13)
                -- ui.setSpriteTextureRect2(item.progressbar,0,0,844*(self.xianchidata.xc_dayprogress < allmilestone and self.xianchidata.xc_dayprogress/allmilestone or 1),31)
                ui.setSpriteTextureRect2(item.progressbar,0,0,844*(1),31)
            elseif data.status == 0 then
                ui.setLabelString(item.target, "0/1",13)
                ui.setSpriteTextureRect2(item.progressbar,0,0,844*(0),31)              
            end
        elseif string.find(config.target,",") then
            local i = string.find(config.target,",")
            local j = string.sub(config.target, i+1, string.len(config.target))
            if data.status ~= -1 then
                ui.setLabelString(item.target, (tonumber(data.now) <= tonumber(j) and (tonumber(data.now) < 0 and 0 or tonumber(data.now) )  or j) .."/"..j,13)
                ui.setSpriteTextureRect2(item.progressbar,0,0,844*(tonumber(data.now) < tonumber(j) and (tonumber(data.now) < 0 and 0 or tonumber(data.now) )  /tonumber(j) or 1),31)
            else--增加已完成显示
                ui.setLabelString(item.target, j .."/"..j,13)
                ui.setSpriteTextureRect2(item.progressbar,0,0,844,31)                
            end
        -- elseif config.type == "athletics" then --已经变成 0 1 了，直接有stata 判断
        --     ui.setLabelString(item.target, (tonumber(data.now) <= tonumber(config.target) and data.now or config.target).."/"..config.target,13)
        --     if data.now > 0 then
        --         ui.setSpriteTextureRect2(item.progressbar,0,0,844*(tonumber(config.target) < tonumber(data.now) and tonumber(config.target)/tonumber(data.now) or 1),31)
        --     else
        --         ui.setSpriteTextureRect2(item.progressbar,0,0,0,31)
        --     end
        else
            if data.status ~= -1 then
                ui.setLabelString(item.target, (tonumber(data.now) <= tonumber(config.target) and (tonumber(data.now) < 0 and 0 or tonumber(data.now) )  or config.target).."/"..config.target,13)
                ui.setSpriteTextureRect2(item.progressbar,0,0,844*(tonumber(data.now) < tonumber(config.target) and (tonumber(data.now) < 0 and 0 or tonumber(data.now) ) /tonumber(config.target) or 1),31)
            else
                ui.setLabelString(item.target, config.target.."/"..config.target,13)
                ui.setSpriteTextureRect2(item.progressbar,0,0,844,31)                
            end
        end
        ui.setLabelString(item.targetText,nil,13)
        
    else
        item.targetnode:setVisible(false)
    end


    if data.status == 0 then
        ui.addGray("CCControlButton",item.button)
        ui.addGray("CCLabelTTF",item.buttontext)
        -- ui.setLabelString(item.buttontext, "未达成" ,18)
        ui.setLabelString(item.buttontext, gameConfig.strings:string_common("task",4) ,18)
        item.button:setTouchPriority(-102)
            -- if not self.isscrolltouched then return end
            -- if gameTouch.isScrollling then return end
        item.button:addHandleOfControlEvent(function()

        end, CCControlEventTouchUpInside)
    elseif data.status == 1 then
        ui.removeGray("CCControlButton",item.button)
        ui.removeGray("CCLabelTTF",item.buttontext)
        -- ui.setLabelString(item.buttontext, "领 取" ,18)
        ui.setLabelString(item.buttontext, gameConfig.strings:string_common("moreCommon",6) ,18)
        item.button:setTouchPriority(-102)
        item.button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
             UIRequest({type = 2401, id = data.cid})
        end, CCControlEventTouchUpInside)
    else
        ui.addGray("CCControlButton",item.button)
        ui.addGray("CCLabelTTF",item.buttontext)
        -- ui.setLabelString(item.buttontext, "未达成" ,18)
        ui.setLabelString(item.buttontext, gameConfig.strings:string_common("task",8) ,18)
        item.button:setTouchPriority(-102)
        item.button:addHandleOfControlEvent(function()
            -- if not self.isscrolltouched then return end
            -- if gameTouch.isScrollling then return end
        end, CCControlEventTouchUpInside)       
    end

end

function task.createnormalListview(self)
    local celldict = {}
    local normalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1020,260)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("achievements/cell_achievements.ccbi", nil, true, "cell_achievements")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.normaltableview,cellCCB,1080/2,260/2,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.normaldata[a1+1])

            if self.normaltableview then
                cellCCB:setPosition(1080/2, 260/2)
            end
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.normaldata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.normaltableview = ui.createLuaTableView({
        handle = normalListHandle,
        viewwidth = self.rootItems.normalScroll:getContentSize().width,
        viewheight = self.rootItems.normalScroll:getContentSize().height,
        dire = 1
    })
    self.normaltableview:setTouchPriority(-101)
    self.rootItems.normalScroll:addChild(self.normaltableview)
end


function task.reloaddata(self,data)
    local oldnumnormal =  table.getTableLength(self.normaldata)
    printT(data,"activennum")

    self.normaldata = {}
    self.activennum = 0
    for k,v in pairs(data.task) do
        table.insert(self.normaldata,v)
        if v.status == 1 then self.activennum = self.activennum +1  end
    end
    local sortbyid = function(a,b) return a.status == b.status and a.cid< b.cid or a.status > b.status end

    table.sort(self.normaldata,sortbyid)
    -- self.rootItems.num:setString(self.activennum.."/"..table.getTableLength(data.task))

    ui.setLabelString(self.rootItems.num, self.activennum.."/"..table.getTableLength(data.task), 18)

    local newnumnormal =  table.getTableLength(self.normaldata)

    if self.normaltableview then
        self.normaltableview:reloadData()
        self.normaltableview:setLuaContentOffset(0, self.normaltableview:getLuaContentOffsetY() - (newnumnormal - oldnumnormal)*260 )
    else
        self:createnormalListview()
    end
    if self.activennum > 0 then
        ui.removeGray("CCControlButton",self.rootItems.allbutton)
    else
        ui.addGray("CCControlButton",self.rootItems.allbutton)
    end

    --self:shiftPage(self.selectpage)
end
--设置按钮位置
function task.setGetButtonX(self,aiType)
    if aiType == 1 then
        self.getNode:setPositionX(-999999)
    else
        self.getNode:setPositionX(870)
    end
end

return task �.  