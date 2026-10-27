--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local robautoresult = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,

    enemy = {},
    cid = 0,
    has_energy = 0,

    isend = false,

    robdata = {},

    energy = 0,
    get = {},
    otherreward = {},

    changeCoin = false,
    changeGold = false,

}

function robautoresult.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.enemy = data.enemy or {}
    self.cid = data.cid or 0
    self.has_energy = data.has_energy or 0

    self.rootNode, self.rootItems = CCBReaderLoad("rub/rub_autojieguo.ccbi", nil, true, "rub_autojieguo")
    self.root:addChild(self.rootNode)

    self.isend = false
    self.robdata = {}
    --self:createList()

    ui.setLabelString(self.rootItems.stopBtn_Text,nil,19)
    self.rootItems["stopBtn"]:addHandleOfControlEvent(function()
        if self.isend then
            runGamePrompt({msg = "已停止挑战"})
        else
            self.isend = true
            ui.addGray("CCControlButton",self.rootItems["stopBtn"])
        end
    end, CCControlEventTouchUpInside)
    self.rootItems["stopBtn"]:setSwallowsTouch(true)
    self.rootItems["stopBtn"]:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.lookRewardBtn_Text,nil,19)
    self.rootItems["lookRewardBtn"]:addHandleOfControlEvent(function()
        --
        if self.otherreward and next(self.otherreward) then 
            showRewardPopupWindow(self.otherreward,nil)
        end
        gameWindows:closeWindowDirect("robautoresult")
    end, CCControlEventTouchUpInside)
    self.rootItems["lookRewardBtn"]:setSwallowsTouch(true)
    self.rootItems["lookRewardBtn"]:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.stopdesc,nil,14)
    ui.setLabelString(self.rootItems.rewardDesc,"",1)

    UIRequest({type = 1114, enemy = self.enemy, cid = self.cid})  

    return self.root,true
end


function robautoresult.Reload(self,data)

    self.has_energy = data.has_energy or 0
    self.energy = self.energy + data.energy
    if data.get and next(data.get) then
        table.insert(self.get,data.get)
        self.isend = true
    end  
    if self.has_energy <= 0 then
        self.isend = true
    end    
    if data.otherreward and next(data.otherreward) then
        for k,v in pairs(data.otherreward) do
            if self.otherreward[tostring(v.cid)] then
                self.otherreward[tostring(v.cid)].num = self.otherreward[tostring(v.cid)].num + v.num
            else 
                self.otherreward[tostring(v.cid)] = v
            end   
        end
    end 
    --
    ui.removeGray("CCControlButton",self.rootItems["stopBtn"])
    self.rootItems.stopNode:setVisible(true)
    self.rootItems.lookRewardNode:setVisible(false)
    --
    for i = 1,data.energy do
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5*(i-1)),CCCallFunc:create(function()
            
            table.insert(self.robdata,{coin = data.coin[tostring(i)] and data.coin[tostring(i)].num or 0,rob = data.rob[tostring(i)] and data.rob[tostring(i)].num or 0})

            if self.ListTableView then
                self.ListTableView:reloadData()
                self.ListTableView:setLuaContentOffset(0,(self.rootItems.listScroll:getContentSize().height > table.getTableLength(self.robdata)*260) and (self.rootItems.listScroll:getContentSize().height - table.getTableLength(self.robdata)*260) or 0)
            else
                self:createList()
            end

            if i == data.energy then
                if self.isend then
                    self.rootItems.stopNode:setVisible(false)
                    self.rootItems.lookRewardNode:setVisible(true)
                    --
                    if self.get and next(self.get) then
                        ui.setLabelString(self.rootItems.rewardDesc,"第"..self.energy.."次挑战获得"..ui.IDconfig(self.cid).name.."，一键挑战终止！",1)
                        runGamePrompt({msg = "第"..self.energy.."次挑战获得"..ui.IDconfig(self.cid).name.."，一键挑战终止！"})
                    elseif self.has_energy <= 0 then
                        ui.setLabelString(self.rootItems.rewardDesc,"精力耗尽，一键挑战终止！",1)
                        runGamePrompt({msg = "精力耗尽，一键挑战终止！"})
                    else
                        ui.setLabelString(self.rootItems.rewardDesc,"",1)
                        runGamePrompt({msg = "一键挑战终止"})    
                    end
                else
                    UIRequest({type = 1114, enemy = self.enemy, cid = self.cid})  
                end
            end

        end)))
    end


end

function robautoresult.createList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(920, 260)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("rub/cell_tenjiesuan", nil, true, "cell_tenjiesuan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            --
            if self.robdata[(a1+1)] and self.robdata[(a1+1)].rob > 0 then
                setSpriteFrameByName(ccbDocumentControler.getCoinTenSprite, "duobaobi")
                ui.setLabelString(ccbDocumentControler.getCoinNumLabel,self.robdata[(a1+1)].rob or 0,13)
            else
                setSpriteFrameByName(ccbDocumentControler.getCoinTenSprite, "propcoin")
                ui.setLabelString(ccbDocumentControler.getCoinNumLabel,self.robdata[(a1+1)].coin or 0,13)
                self.changeCoin = true
            end

            ccbDocumentControler.gongxiTxt:setVisible(false)
            ccbDocumentControler.rewardUpName:setVisible(false)
            -- local numString = "第"..(a1+1).."次"
            local numString = gameConfig.strings:numci(a1+1)
            ccbDocumentControler.lineNumLabel:setString(numString)


            cellCCB:setPosition(920/2,260/2)


            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.robdata)
        elseif fn == "cellTouched" then

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

function robautoresult.close(self)

    if self.changeCoin then
        GameScene:coin_effect(1,540,960,0.5)
    end    

    self.ListTableView = nil
    self.changeCoin = false
    self.changeGold = false
    self.get = {}
    self.otherreward = {}
    self.energy = 0
    self.has_energy = 0
    self.robdata = {}
    self.isend = false
    self.enemy = {}
    self.cid = 0
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return robautoresult

