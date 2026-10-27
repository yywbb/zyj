--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/30
-- Time: 上午10:10
-- To change this template use File | Settings | File Templates.
--

local examinationrank = {
    rootNode = nil,
    rootItems = nil,
    normalCellSize = {x=880,y=110+14},


    showType = 0,--0周试 1奖励

    answer = {},
    roleid = 0,
    isRequestZhoushi = 0,

    phb = 0,
    jifen = 0,
    showData = {},
    status  = {},
    phtype = 2,--2周排行 3月排行


}

function examinationrank.open(self,touchPriority,data)
    self.rootNode, self.rootItems = CCBReaderLoad("sanjieliankao/tc_paihangbang", nil, true, "examinationrank")

    self.touchPriority = touchPriority
    self.showType = 0
    self.roleid = data.roleid
    self.phtype = data.phtype 

    -- UIRequest( {type = 7005, ranktype = self.phtype } )

    return self.rootNode
end

function examinationrank.initView(self)
    
     self.sanjie_reward = gamedata.config.sanjie_reward
    self.span_sanjie_reward = gamedata.config.span_sanjie_reward


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("examinationrank")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
        
    self.rootItems.tabbutton1:addHandleOfControlEvent(function()
        if self.showType ~= 0 and self.showData then
            self.showType = 0
            self:reloadjifen()
            self:reloadListView(self.showData,0)
            setSpriteFrameByName(self.rootItems.tabon1, gameConfig.images.pageButtonON)
            setSpriteFrameByName(self.rootItems.tabon2, gameConfig.images.pageButtonOFF)
        end    

    end, CCControlEventTouchUpInside)
    self.rootItems.tabbutton1:setSwallowsTouch(true)
    self.rootItems.tabbutton1:setTouchPriority(self.touchPriority)


    self.rootItems.tabbutton2:addHandleOfControlEvent(function()
        if self.showType ~= 1 then
             self.showType = 1
            self:reloadListView(nil,0)
            setSpriteFrameByName(self.rootItems.tabon1, gameConfig.images.pageButtonOFF)
            setSpriteFrameByName(self.rootItems.tabon2, gameConfig.images.pageButtonON)
        end    
    end, CCControlEventTouchUpInside)
    self.rootItems.tabbutton2:setSwallowsTouch(true)
    self.rootItems.tabbutton2:setTouchPriority(self.touchPriority)

    -- ui.addGray("CCSprite",self.rootItems.tabon1)
    -- setSpriteFrameByName(self.rootItems.tabon1, gameConfig.images.pageButtonOFF)
    setSpriteFrameByName(self.rootItems.tabon1, gameConfig.images.pageButtonON)

   
    if self.phtype == 2 then
        self.rootItems.tablab1:setString(gameConfig.strings:string_common("examination", 11))
    else
        self.rootItems.tablab1:setString(gameConfig.strings:string_common("examination", 12))
    end    


end
         


function examinationrank.reload(self,data)
    -- printT(data,"examinationrank reload")
    self:initView()

    self.data = data

    local serverInfo = gameWindows.windows["roleinfo"].module.SelectedServer  --获取服务器的基本数据
    local serverid = serverInfo.id or 0

    local phbdataLength = table.getTableLength(self.data)  
     print("roleid---",self.roleid)
     for i,v in pairs(data) do
        print("reload---",i)
         if i == tostring(phbdataLength)  then--最后一行
             local nNum = v.params["1"].i or 0
            
             local score = nNum / 10;
             print(score," score---")

             self.jifen =  score or 0
         else
            if self.phtype == 2 then
                --周排行
                if v.rid == self.roleid then
                    self.phb =  v.params["4"].i or 0
                end    
            else
                --月排行（跨服 server_id * 1000000 + rid）
                print("serverid:"..serverid)
                -- if v.rid == (serverid* 1000000 + self.roleid) then
                if v.rid == self.roleid then
                    self.phb =  v.params["4"].i or 0
                end
            end    
            table.insert(self.status,v)
         end   
        
    end
    -- printT(self.status,"self.status")
    local zslength = table.getTableLength(self.status)
    if zslength >1 then
         local sortBy = function(a,b) return a.params["4"].i < b.params["4"].i end
         table.sort(self.status, sortBy)
    end   

    self.showData = self.status
    -- printT(self.showData,"self.showData")

    print("table length:",table.getTableLength(self.showData))
    self:reloadjifen()
    self:reloadListView(self.showData,0)

    setSpriteFrameByName(self.rootItems.tabon1, gameConfig.images.pageButtonON)
    setSpriteFrameByName(self.rootItems.tabon2, gameConfig.images.pageButtonOFF)

   
end



function examinationrank.reloadjifen(self)
    print("phb"..self.phb)

    local _answer = gamedata.config.sanjie_answer
    
    if self.phtype == 2 then
         self.answer = _answer[tostring(2)]
    else
         self.answer = _answer[tostring(3)]
    end    

    if self.phb and self.phb >0 then    
        self.rootItems.wodepaihang:setString(tostring(self.phb))
    else    
        self.rootItems.wodepaihang:setString(gameConfig.strings:string_common("examination", 5))
    end
     self.rootItems.wodejifen:setString(tostring(self.jifen))    
  
end

function examinationrank.reloadListView(self,data)
    self.rootItems.listnode:removeAllChildrenWithCleanup(true)
    self.ListTableView = nil
    local ListHandle = nil

    if data == nil then
        --奖励
        local datas = {}
        local canyu = {} --参与奖
        if self.phtype == 2 then
             for i,v in pairs(self.sanjie_reward) do
                if tonumber(v.rank) > 0 then
                     table.insert(datas,v)
                else
                    canyu = v
                end    
             end
        else
            for i,v in pairs(self.span_sanjie_reward) do
                if tonumber(v.rank) > 0 then
                     table.insert(datas,v)
                else
                    canyu = v
                end    
             end
        end  
        local sortfunc = function (a,b)
            return  a.rank < b.rank 
        end
        -- printT(canyu,"canyu")
        table.sort(datas,sortfunc)
        local celldict = {}
        ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
            local r
            if fn == "cellSize" then
                r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
            elseif fn == "cellAtIndex" then

                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("sanjieliankao/cell_paihangbang_jiangli", nil, true, "cell_paihangbang_jiangli")
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                    cellCCB:setPosition(self.normalCellSize.x/2, 0)
                    -- ui.tableviewAnimation(self.ListTableView,cellCCB,self.normalCellSize.x/2, 0,a1)
                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end
              
                local roledata = {}
                local reward = {}
                roledata = datas[a1+1] or nil



                if roledata == nil and (a1+1 == table.getTableLength(datas)+1 ) then
                   roledata =  canyu
                   print("---参与奖")
                end    
                reward = roledata.reward or {}
                if roledata.rank == 0 then
                    ccbDocumentControler.paimingnum:setString(gameConfig.strings:string_common("examination", 13))
                else
                   if a1 > 0 then
                        local roledatabefore = datas[a1] or nil
                        if roledatabefore ~=nil then
                             if (tonumber(roledata.rank)) > (tonumber(roledatabefore.rank)+1) then
                                local qj =  (roledatabefore.rank+1).."~"..roledata.rank
                                ccbDocumentControler.paimingnum:setString(qj)
                             else
                                ccbDocumentControler.paimingnum:setString(roledata.rank)
                             end

                         else
                            ccbDocumentControler.paimingnum:setString(roledata.rank)
                         end   

                     else
                        ccbDocumentControler.paimingnum:setString(roledata.rank)
                    end                    
                end    
                local cost = ui.getIDandNUMs(reward)

                -- printT(cost," cost")
                self.tupo_needprops = {}
                local propindex = 0
                for i = 1,5 do
                    ccbDocumentControler["needprop"..i]:setVisible(false)
                end
                local cids = {}
                for k,v in pairs(cost) do
                    table.insert(cids,v.cid)
                end
                for k,v in pairs(cost) do
                    if propindex <= 4 then
                        local index = propindex+1
                        ccbDocumentControler["needprop"..index]:setVisible(true)
                        ui.setNewIcon(ccbDocumentControler,v,propindex)
                        self.tupo_needprops[tostring(v.cid)] = {cid = v.cid, num = v.num, index = index, has = 0 }
                        ccbDocumentControler["i_button"..((index == 1) and "" or ("_"..(index-1)))]:addHandleOfControlEvent(function()
                            gameWindows:openWindow("dropTips",{cid = v.cid},nil)
                        end, CCControlEventTouchUpInside)
                        ccbDocumentControler["i_button"..((index == 1) and "" or ("_"..(index-1)))]:setSwallowsTouch(true)
                        ccbDocumentControler["i_button"..((index == 1) and "" or ("_"..(index-1)))]:setTouchPriority(self.touchPriority-1)
                        propindex = propindex+1
                    end
                end
                
                if self.ListTableView then
                    print("setPosition")
                    cellCCB:setPosition(880/2, 0)
                end  
                if first then
                    a2:addChild(cellCCB)
                end

                r = a2

            elseif fn == "numberOfCells" then

                r = table.getTableLength(datas) + 1
    
            elseif fn == "cellTouched" then

            elseif fn == "scrollViewDidScroll" then
            end
            return r
        end)


    else    
        --排行榜
        local datas = {}
        local tablelength = table.getTableLength(data)
        if  tablelength<=0 then
           if self.phtype == 2 then
                 for i,v in pairs(self.sanjie_reward) do
                    if tonumber(v.rank) > 0 then
                         table.insert(datas,v)
                    end    
                 end
           else
                for i,v in pairs(self.span_sanjie_reward) do
                    if tonumber(v.rank) > 0 then
                         table.insert(datas,v)
                    end    
                 end
           end  
            local sortfunc = function (a,b)
                return  a.rank < b.rank 
            end
            table.sort(datas,sortfunc)
            -- printT(datas,"sanjie_reward")
        end          
        -- printT(data,"data")
        -- printT(datas,"datas")
        local celldict = {}
        ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
            local r
            if fn == "cellSize" then
                r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
            elseif fn == "cellAtIndex" then

                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("sanjieliankao/cell_paihangbang", nil, true, "cell_paihangbang")
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                    cellCCB:setPosition(self.normalCellSize.x/2, 0)
                    -- ui.tableviewAnimation(self.ListTableView,cellCCB,self.normalCellSize.x/2, 0,a1)
                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end
                --
                local roledata = {}
                local reward = {}
                local _png = "xuweiyidaizi"
                if tablelength <= 0 then
                     roledata = datas[a1+1] or {}
                    ccbDocumentControler.playername:setString("虚位以待")
                    
                    ccbDocumentControler.rank:setString(a1+1)
                    ccbDocumentControler.jfien:setString("0")
                    reward = roledata.reward or {}
                else

                    roledata = data[a1+1] or nil
                    if  roledata ~= nil then
                        ccbDocumentControler.playername:setString(roledata.name)
                        ccbDocumentControler.rank:setString(a1+1)
                       
                        local nNum =  roledata.params["1"].i or 0
                        local score = nNum / 10;
                        print(score," score---")
                        ccbDocumentControler.jfien:setString(tostring(score))
                    else
                        ccbDocumentControler.rank:setString(a1+1)
                        ccbDocumentControler.playername:setString("虚位以待")
                        ccbDocumentControler.jfien:setString("0")
                    end    
                   
                end    
             
                if self.ListTableView then
                    print("setPosition")
                    cellCCB:setPosition(880/2, 0)
                end  
                if first then
                    a2:addChild(cellCCB)
                end

                r = a2

            elseif fn == "numberOfCells" then
                local tablelength = table.getTableLength(data)
                if  tablelength<=0 then
                    r = 3
                else
                    -- if self.phtype == 2 then
                    --     r = 50
                    -- else
                    --     r = 100    
                    -- end   
                    r = table.getTableLength(data)
                end
            elseif fn == "cellTouched" then

            elseif fn == "scrollViewDidScroll" then
            end
            return r
        end)

    end    
   

    local ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(ListTableView)
    ListTableView:setTouchPriority(self.touchPriority)

end

function examinationrank.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.showType = 0
    self.isRequestZhoushi  = 0
    self.showType = 0
    self.answer = {}
    self.roleid = 0
    self.isRequestZhoushi = 0
    self.phb = 0
    self.jifen = 0
    self.showData = {}
    self.status  = {}
    self.phtype = 2
end

return examinationrank�=  