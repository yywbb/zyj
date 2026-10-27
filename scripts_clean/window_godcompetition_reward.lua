--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local godCompetition_reward = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    --伤害排行
    myServiceListTableView = nil,
    allServiceListTableView = nil,
    sevicepages = {"myservice","allservice",},
    sevicechoosepage = "myservice",

    myservice = {},
    allservice = {},
    myserviceHurtNum = 0,
    allserviceHurtNum = 0,
	titleCellSize = {x=180*0.7,y=180*0.7},
}

function godCompetition_reward.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.params = data

    self.rootNode, self.rootItems = CCBReaderLoad("fengshensai/tc_damgereward.ccbi", nil, true, "tc_damgereward")
    gameTouch:clickprofbytime(0.5)
    self.sevicechoosepage = "myservice"
    UIRequest({type = 8261})
    
    self.root:addChild(self.rootNode)

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("godCompetition_reward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority-1)


    return self.root
end



function godCompetition_reward.reloadData(self,data)
    self.myservice = {}
    self.allservice = {}
    local _my_length =  table.getTableLength( gamedata.config.apex_boss_geren_rewards)
    local _all_length =   table.getTableLength(gamedata.config.apex_boss_kuafu_rewards)
    for i=1,table.getTableLength(data.status) do
        local _status = data.status[tostring(i)]
        if _status then
            if i < _my_length + 2 then 
                if i < _my_length + 1 then
                    table.insert(self.myservice, {id= i, status = _status})
                else    
                    self.myserviceHurtNum = _status
                end    
            else    
                if i < _my_length + 2 + _all_length then
                    local _allindex = i-1-_my_length
                    table.insert(self.allservice, {id= _allindex, status = _status})
                else    
                    self.allserviceHurtNum = _status
                end    
            end    
        end   
    end

    local sortFunc = function( a, b )
        if a["status"] == b["status"] then
            if a["id"] <  b["id"] then
                return true
            else 
                return false    
            end        
         else
            if a["status"] == 1 then
                return true
            elseif b["status"] == 1 then
                return false
            elseif a["status"] == 0 then
                 return true
            elseif b["status"] == 0 then
                return false
            else
                if a["id"]  <  b["id"] then
                    return true
                else 
                    return false    
                end   
            end      
         end 
       
    end
    table.sort(self.myservice,sortFunc)
    table.sort(self.allservice,sortFunc)

    -- printT(self.myservice,"reloadData===myservice sort",self.myserviceHurtNum)
    -- printT(self.allservice,"reloadData===allservice sort",self.allserviceHurtNum)

    for i,v in ipairs(self.sevicepages) do
        print("page===",i,v)
        self.rootItems[v.."Btn"]:addHandleOfControlEvent(function()
            print("page===222",i,v)
            self:shiftServiceScoreNode(v)
        end, CCControlEventTouchUpInside)
        self.rootItems[v.."Btn"]:setSwallowsTouch(true)
        self.rootItems[v.."Btn"]:setTouchPriority(self.touchPriority-1)
    end
    print("sevicechoosepage==",self.sevicechoosepage)
    self:shiftServiceScoreNode(self.sevicechoosepage)

end

function godCompetition_reward.setServiceScorePageSprite( self,choose )

    for i,v in ipairs(self.sevicepages) do
        print("setpage===",choose,v)
        if v == choose then
            self.rootItems[v.."Point"]:setVisible(true)
        else
            self.rootItems[v.."Point"]:setVisible(false)
        end
    end

end

function godCompetition_reward.shiftServiceScoreNode(self,type)
    print("i...am..shiftServiceScoreNode",type)

    self.sevicechoosepage = type
    self:setServiceScorePageSprite(self.sevicechoosepage)
    
    for k,v in ipairs(self.sevicepages) do
        if v == self.sevicechoosepage then
            self.rootItems[v.."ListNode"]:setPositionX(50)
            self.rootItems[v.."ListNode"]:setVisible(true)
        else
            self.rootItems[v.."ListNode"]:setPositionX(9999)
            self.rootItems[v.."ListNode"]:setVisible(false)
        end
    end
    if type == "myservice" then
        print("myservice...is....")
        self:myserviceReload()
    elseif type == "allservice" then
        print("allservice...is....")
        self:allserviceReload()
    else
        print("other===")
    end
end
    --todo
function godCompetition_reward.myserviceReload(self)

    if self.myServiceListTableView == nil then
        self:createMyServiceList()
    else
        self.myServiceListTableView:reloadData()
    end
end


function godCompetition_reward.allserviceReload(self)
    if self.allServiceListTableView == nil then
        self:createAllServiceList()
    else
        self.allServiceListTableView:reloadData()
    end
end

-- 个人奖励
function godCompetition_reward.createMyServiceList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(980, 220)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("fengshensai/cell_damgereward", nil, true, "cell_damgereward")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local cell_status = self.myservice[a1+1]
            self:setCellData(ccbDocumentControler,cell_status,true)

            cellCCB:setPosition(980/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(gamedata.config.apex_boss_geren_rewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.myServiceListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.myserviceListNode:getContentSize().width,
        viewheight = self.rootItems.myserviceListNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.myserviceListNode:removeAllChildrenWithCleanup(true)
    self.rootItems.myserviceListNode:addChild(self.myServiceListTableView)
    self.myServiceListTableView:setTouchPriority(self.touchPriority)
end


-- 本服奖励
function godCompetition_reward.createAllServiceList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(980, 220)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("fengshensai/cell_damgereward", nil, true, "cell_damgereward")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local cell_status = self.allservice[a1+1]
            self:setCellData(ccbDocumentControler,cell_status,false)

            cellCCB:setPosition(980/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(gamedata.config.apex_boss_kuafu_rewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.allServiceListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.allserviceListNode:getContentSize().width,
        viewheight = self.rootItems.allserviceListNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.allserviceListNode:removeAllChildrenWithCleanup(true)
    self.rootItems.allserviceListNode:addChild(self.allServiceListTableView)
    self.allServiceListTableView:setTouchPriority(self.touchPriority)
end


function godCompetition_reward.setCellData(self,item,data,isbenfu)
    -- printT(data,"hurtreward setCellData")
    if not data then return end    

    local celldata = {}
    if isbenfu then
        celldata = gamedata.config.apex_boss_geren_rewards[tostring(data.id)] or {}
    else
        celldata = gamedata.config.apex_boss_kuafu_rewards[tostring(data.id)] or {}
    end    

    if celldata.reward then

        local allDrop = ui.getIDandNUMs(celldata.reward)
        local itemLength = table.getTableLength(allDrop)
        local celldict = {}
        local itemListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
            local r
            if fn == "cellSize" then
                r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
            elseif fn == "cellAtIndex" then
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end
                print(a1,"a1")
                local _key_Ex = ""
                if a1 ~= 0 then
                    _key_Ex = "_"..(a1+1)
                end
                local data =  allDrop[a1+1] or nil
                if data then
                    ui.setNewIcon(ccbDocumentControler,allDrop[a1+1])
                    cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2+5)
                   
                    ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                        ui.setPopwindowByCid(data.cid)
                    end, CCControlEventTouchUpInside)
                    ccbDocumentControler["i_button"]:setTouchPriority(self.touchPriority-3)
                    cellCCB:setScale(0.7)
    
                    if first then
                        a2:addChild(cellCCB)
                    end    
                    r = a2
                else 
                    print(a1,"data is nil")
                end    
            elseif fn == "numberOfCells" then
                r =  itemLength
            elseif fn == "cellTouched" then
    
            elseif fn == "scrollViewDidScroll" then
            end
            return r
        end)
    
        local itemListTableView = ui.createLuaTableView({
            handle = itemListHandle,
            viewwidth =  item.rewardListNode:getContentSize().width,
            viewheight =  item.rewardListNode:getContentSize().height,
            dire = 0
        })
        item.rewardListNode:removeAllChildrenWithCleanup(true)
        item.rewardListNode:addChild(itemListTableView)
        if itemLength >5 then
            itemListTableView:setTouchPriority(self.touchPriority-3)
        end   

        local _hurtnumString = ""

        if isbenfu then
            _hurtnumString = ui.makeshortnum2(self.myserviceHurtNum).."/"..ui.makeshortnum2(celldata.damage)
            item.cellTitle:setString(gameConfig.strings:string_common("godCompetition",4))
        else
            _hurtnumString = ui.makeshortnum2(self.allserviceHurtNum).."/"..ui.makeshortnum2(celldata.damage)
            item.cellTitle:setString(gameConfig.strings:string_common("godCompetition",5))
        end    
        local status = data.status or 0
        local no_ishow = false
        local has_ishow = false
        local get_ishow = false
        if status == 0 then --未到达
            no_ishow = true
            ui.setLabelString(item.hurtNum,_hurtnumString,24,38)
        elseif status == 1 then --未领取
            get_ishow = true
            ui.setStringWithStrokeAndShadow(item.getlab,nil,1)
            ui.setLabelString(item.hurtNum,_hurtnumString,22,38)
        elseif status == 2 then --已领取
            has_ishow = true
            ui.setLabelString(item.hurtNum,_hurtnumString,22,38)
        end    
        item.nonenode:setVisible(no_ishow)
        item.hasnode:setVisible(has_ishow)
        item.getNode:setVisible(get_ishow)
        if get_ishow then
            item.getbtn:addHandleOfControlEvent(function()
                print("领取")
                local serverid = 1
                if self.sevicechoosepage == "allservice" then
                    serverid = 2
                end    
                UIRequest({type = 8262,server = serverid, rewardid = data.id})
            end, CCControlEventTouchUpInside)
            item.getbtn:setSwallowsTouch(true)
            item.getbtn:setTouchPriority(self.touchPriority-1)
        end  
    end    
end

function godCompetition_reward.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    self.worldwarstatus = 0


    self.myServiceListTableView = nil
    self.allServiceListTableView = nil

   

    self.myservice = {}
    self.allservice = {}
    self.myserviceHurtNum = 0
    self.allserviceHurtNum = 0

    self.sevicechoosepage = "allservice"
    self.data = {}
end

return godCompetition_reward