--
-- Created by IntelliJ IDEA.
-- User: yxf
-- Date: 19/5/13
-- Time: 10:57
-- To change this template use File | Settings | File Templates.
--
--仙窟 福祉仙洞

local blessingCave = {
    rootNode = nil,
    rootItems = nil,
    touchPriority = -103,
    animationManager = nil,
    normalCellSize = {x=1040,y=208+14},
    battleTimes = 0,
    copyInfo = {},
    copyInfoCache = {},
    isfirstload = 0,
    currentcopyPosition = 1,
    maxPositon = 1,
    rolelv = 0,
    isNewOpen = 0,

}


function blessingCave.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("fuzhitiangong/fuzhitiangong", nil, true, "blessingCave")

    self.rootNode:setPosition(-540,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)


    local zhuannode, zhuanItems = CCBReaderLoad("fuzhitiangong/fuzhitiangong_zhuan", nil, true, "blessingzhuan")
    zhuannode:setPosition(540,210)
    -- self.rootItems.copyNode:addChild(zhuannode)

    self.rootItems.copyScrollView = tolua.cast(self.rootItems.copyScrollView, "CCScrollView")
    self.rootItems.copyScrollView:setViewSize(CCSizeMake(1080,480))
    self.rootItems.copyScrollView:setVisible(true)
    self.rootItems.copyScrollView:setTouchEnabled(false)
    self.rootItems.copyScrollView:setPosition(-540,-210)

    self.rootItems.container:setContentSize(CCSize(1080,480))
    self.rootItems.container:addChild(zhuannode)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.touchPriority)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    self.zhuannode = zhuannode
    self.zhuanItems = zhuanItems
    self.animationManager = getAnimationManager(zhuanItems)
    self.animationManager:setAnimationCompletedCallback(function()
    end)

    print(toppos..":toppos")

    self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-151-480-gameConfig.maiscenebottomheight-69))
    self.rootItems.scale9_sp:setPositionY(self.rootItems.listnode:getPositionY()+self.rootItems.listnode:getContentSize().height-self.rootItems.scale9_sp:getContentSize().height-50)



    --初始化关卡名字、关卡图片
    for i=1,10 do
        local key_Ex
        if i-1 == nil or i-1 == 0 then
              key_Ex = ""
        else
             key_Ex = "_"..(i-1)
        end
        local info  = gamedata.config.xianku_guaiwu[tostring(i)][tostring(1)]
        self.zhuanItems["name"..key_Ex]:setString(info.name1)
        if info.open_level <= self.rolelv then
            self.zhuanItems["name2"..key_Ex]:setString("未解锁")
        else   
            self.zhuanItems["name2"..key_Ex]:setString(info.open_level.."级开启")
        end    
        print(info.icon,"info.icon")
        local generalConfig = ui.IDconfig(info.icon)
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        local Gneral1 = ui.itemcache:loadSkeleton(generalName)
        Gneral1:setPosition(0,0)
        self.zhuanItems["rolesprite"..key_Ex]:addChild(Gneral1.root or Gneral1)

        setSpriteFrameByName(self.zhuanItems["zhuanbg"..key_Ex], info.icon_bg or "fuzhitiangong_bg3")
    end

    self.rootItems.buyTime:setSwallowsTouch(true)
    self.rootItems.buyTime:setTouchPriority(self.touchPriority)
    self.rootItems.buyTime:addHandleOfControlEvent(function()
        -- activityBlessingCaveBuyTimes()

         self:buyTimes()
         local nowcount = GameScene.vipstatus.xianku_cishu --已经购买几次
         local totalcount = gamedata.config.vip[tostring(GameScene.vip.vip)].xianku_cishu --共可以买三次
         print("nowcount:"..nowcount.." totalcount:"..totalcount)
        gameWindows:openWindow("blessingCaveBuy",{totalcount = totalcount,challengeTime = self.battleTimes,  alreadybuy = nowcount })



    end, CCControlEventTouchUpInside)


    self.currentcopyPosition = 1
    self.animationManager:runAnimationsForSequenceNamed("1")
    self:setCopyTouch()
    self.isfirstload = 1
    UIRequest({type = 6520})

end

function blessingCave.setCopyTouch(self)

   local function ccTouchBegan(x, y)
        self.ismove = false
        if ui.isTouched(self.rootItems.copytouchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            return true
        end
    end

    local function ccTouchMoved(x, y)

    end

    local function ccTouchEnded(x, y)
        if x-self.touchX > 20 then
            self.ismove = true
            gameTouch:clickprofbytime(0.5)
            --右转
            if self.currentcopyPosition ==1 then
                self:setzhuan(1,1)
            else    
                self:setzhuan(self.currentcopyPosition-1,self.currentcopyPosition)
            end    

        elseif self.touchX-x > 20 then
            self.ismove = true
            gameTouch:clickprofbytime(0.5)
             --左转
             if self.currentcopyPosition == 10 then
                self:setzhuan(10,10)
             else   
                self:setzhuan(self.currentcopyPosition+1,self.currentcopyPosition)
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

    self.rootItems.copytouchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority-1, false)
    self.rootItems.copytouchLayer:setTouchPriority(self.touchPriority-1)
    self.rootItems.copytouchLayer:setTouchEnabled(true)

   
end

--设置转动动画 currentPosition 是当前位置，to   --LorR 1为右转 0为左转
function blessingCave.setzhuan(self,to,currentPosition)
    print("setzhuan toposition"..to.." currentPosition:"..currentPosition)

    if to >= self.maxPositon+2 then
       runGamePrompt({msg = "该关卡未解锁"})
       return
    end

    if  currentPosition == to then
         self.animationManager:runAnimationsForSequenceNamed(tostring(to))
         self:reloadcopyDetails(to,self.copyInfo)
         self.currentcopyPosition =  to
    elseif to >currentPosition then --左转
       if to <= 10 then
         self.animationManager:runAnimationsForSequenceNamed((to-1).."-"..to)
         self:reloadcopyDetails(to,self.copyInfo)
         self.currentcopyPosition =  to
       end 

        if self.isNewOpen ==1 then
            self.isNewOpen = 0
            local key_Ex
            if to-1 == nil or to-1 == 0 then
              key_Ex = ""
            else
              key_Ex = "_"..(to-1)
            end

            local ccb,items = CCBReaderLoad("UIEffect/fuzhitiangong/fuzhitiangongeffect", nil, true, "fuzhitiangongeffect")

            self.zhuanItems["effectNode"..key_Ex]:addChild(ccb)
            local animationManager2 = getAnimationManager(items)
            animationManager2:setAnimationCompletedCallback(function()
                ccb:removeFromParentAndCleanup(true)
                self.zhuanItems["effectNode"..key_Ex]:removeChild(ccb,true)

            end)
        end    

    elseif to <currentPosition then --右转    
        if to >=1 then
          self.animationManager:runAnimationsForSequenceNamed((to+1).."-"..to)
         self:reloadcopyDetails(to,self.copyInfo)
         self.currentcopyPosition =  to
        end 
    end

    self.animationManager:setAnimationCompletedCallback(function()

        for i=1,10 do
            local key_Ex
            if i-1 == nil or i-1 == 0 then
                  key_Ex = ""
            else
                 key_Ex = "_"..(i-1)
            end

            if self.currentcopyPosition == (i - 1)  then
                self.zhuanItems["difficultyIcon"..key_Ex]:setVisible(true)
                -- self.zhuanItems["difficultyIcon"..key_Ex]:setPositionX(-20)
            elseif self.currentcopyPosition == (i + 1) then
                self.zhuanItems["difficultyIcon"..key_Ex]:setVisible(true)
                -- self.zhuanItems["difficultyIcon"..key_Ex]:setPositionX(20)
            else
                self.zhuanItems["difficultyIcon"..key_Ex]:setVisible(false)
            end

        end
        print("currentcopyPosition",self.currentcopyPosition)
        self.rootItems.markLeft:setVisible(self.currentcopyPosition > 1)
        self.rootItems.markRight:setVisible(self.currentcopyPosition < 10)
            
    end)
    
end

--所有剩余次数
function blessingCave.setcopyInfo(self,times)
     if tonumber(times) >0 then
            self.rootItems.challengeTime:setColor(ccc3(84,255,8))
        else
            self.rootItems.challengeTime:setColor(ccc3(255,8,8))
     end    
     self.rootItems.challengeTime:setString(tostring(times))


end

function blessingCave.setCopyClick(self,isfirstload)
     for i=1,10 do
        local key_Ex
        if i-1 == nil or i-1 == 0 then
              key_Ex = ""
        else
             key_Ex = "_"..(i-1)
        end

        if isfirstload  then
            self.zhuanItems["saodangbtn"..key_Ex]:addHandleOfControlEvent(function()

                if self.ismove then return end

                print("setCopyClick:"..i.." self.maxPositon:"..self.maxPositon)
                if self.currentcopyPosition > i then
                   self:setzhuan(self.currentcopyPosition-1,self.currentcopyPosition)
                elseif self.currentcopyPosition <i then
                   self:setzhuan(self.currentcopyPosition+1,self.currentcopyPosition)
                end    

            end, CCControlEventTouchUpInside)

            local info  = gamedata.config.xianku_guaiwu[tostring(i)][tostring(1)]
            if info.open_level <= self.rolelv then
               self.zhuanItems["name2"..key_Ex]:setString("未解锁")
            else   
               self.zhuanItems["name2"..key_Ex]:setString(info.open_level.."级开启")
            end    
        end  
        if i<= self.maxPositon then
           self.zhuanItems["zhuanbgLock"..key_Ex]:setVisible(false)
           self.zhuanItems["name2"..key_Ex]:setVisible(false)
        else    
           self.zhuanItems["zhuanbgLock"..key_Ex]:setVisible(true)
           self.zhuanItems["name2"..key_Ex]:setVisible(true)
        end
        local curlevel = -100
        for k=1,4 do
            if self.copyInfoCache[(i-1)*4+k] and self.copyInfoCache[(i-1)*4+k].status == 2 then
                curlevel = k
            end
        end
        if curlevel ~= -100 then
            local difficulty = gamedata.config.xianku_guaiwu[tostring(i)][tostring(curlevel)].difficulty
            setSpriteFrameByName(self.zhuanItems["difficultyIcon"..key_Ex],"fuzhi_icon"..difficulty)
        end

    end
end


--某一关卡刷新
function blessingCave.reloadcopyDetails(self,currentPosition,data)
    -- printT(data,"reloadcopyDetails")
    print(currentPosition,"currentPosition")
    self.rootItems.listnode:removeAllChildrenWithCleanup(true)
    if self.currentcopyPosition ~= currentPosition then
       self.ListTableView = nil
    end    

    self.copyInfoCache = {}
    for i=0,39 do --23
      local copyindex = math.modf( i / 4 ) + 1 --取整
      local currentcopy = gamedata.config.xianku_guaiwu[tostring(copyindex)] or {}
      local fewe = math.modf( i / 4 ) --取整
      if data[tostring(i+3+fewe)]then
        table.insert(self.copyInfoCache,{ status = data[tostring(i+3+fewe)] })
      else  
        table.insert(self.copyInfoCache,{ status = 0 })
      end  

    end
    -- printT(self.copyInfoCache,"copyInfoCache")
    local length = table.getTableLength(data)

    local maxcopy = math.modf( length / 5 ) --开启副本的最高限制 5
     self.currentCopyInfo = {}
    if currentPosition > maxcopy then --只显示一个未开启的
        table.insert(self.currentCopyInfo,gamedata.config.xianku_guaiwu[tostring(currentPosition)]["1"]) 
    else --显示所有
       local nopen = false
       for i=1,4 do
          local status = self.copyInfoCache[(currentPosition-1)*4+i].status
          -- print("status:"..i..":"..status)
          if status == 1 or  status == 2 then
            table.insert(self.currentCopyInfo,gamedata.config.xianku_guaiwu[tostring(currentPosition)][tostring(i)]) 
          else
             if nopen then
                 print("已经有一个不可挑战的了")
             else
                table.insert(self.currentCopyInfo,gamedata.config.xianku_guaiwu[tostring(currentPosition)][tostring(i)]) 
                nopen = true
             end   
          end  
       end
       -- printT(self.currentCopyInfo,"currentCopyInfo")
    end    

    local sortfunc = function (a,b)
        return  a.difficulty > b.difficulty 
    end
    table.sort(self.currentCopyInfo,sortfunc)
    -- printT(self.currentCopyInfo,"currentCopyInfosort")

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("fuzhitiangong/cell_fuzhi", nil, true, "cell_fuzhi")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimationSlow(self.ListTableView,cellCCB,self.normalCellSize.x/2, 0,a1)

            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end


             -- printT(self.currentCopyInfo,"self.currentCopyInfo")
             local copy = self.currentCopyInfo[a1+1] or {}
            -- printT(copy,"copy")

             local index =  copy.difficulty
            setSpriteFrameByName(ccbDocumentControler.cell_namesprite,"fuzhi_icon"..index)

             -- ccbDocumentControler.cell_namesprite:setString(copy.name2 or "")
             
             -- ccbDocumentControler.name:setString(copy.name2 or "")
             --难度1按钮状态(0不可挑战，1攻打，2扫荡)
            local  stindex = 4*(currentPosition-1)+tonumber(index)
             -- print("stindex:"..stindex.." currentPosition:"..currentPosition)
             local tatus = "0"
             if self.copyInfoCache[stindex] then
                 tatus = self.copyInfoCache[stindex].status 
             end
            -- print("tatus:"..tatus)
            local openlv = copy.open_level or ""
             local btnstatus = tonumber(tatus)

             ccbDocumentControler.heidi:setVisible(btnstatus==0  or false )
             ccbDocumentControler.battleNum:setVisible(btnstatus~=0  or false )
             ccbDocumentControler.saodangnode:setVisible(btnstatus==2 or false )
             ccbDocumentControler.tiaozhanNode:setVisible(btnstatus==1 or false )

             ccbDocumentControler.recommendPower:setString(copy.power or "12")


             local isfirstcopy = table.getTableLength(self.currentCopyInfo)
            --  if btnstatus==0 then
            --      local names = ""
            --     if index ==2 then
            --         names = "简单"
            --     elseif index ==3 then
            --         names = "普通"
            --     elseif index ==4 then 
            --         names = "困难"
            --      end 
            --     if currentPosition == 1 then
            --         ccbDocumentControler.lab1:setString("通关"..names.."难度")
            --     elseif currentPosition >1 then
            --         local beforecopyinfo = gamedata.config.xianku_guaiwu[tostring(currentPosition-1)]["1"] or {}
            --         if isfirstcopy <=1 then
            --             ccbDocumentControler.lab1:setString("通关"..beforecopyinfo.name1..beforecopyinfo.name2.."难度")
            --         else    
            --             ccbDocumentControler.lab1:setString("通关"..beforecopyinfo.name1..copy.name2.."难度和本层"..names.."难度")
            --         end 
            --     end   
            -- end

                if isfirstcopy <=1 then
                    local positon  = 1
                    if currentPosition ==1 then
                       positon = 1
                    elseif currentPosition>1 then
                       positon = currentPosition-1
                    end    
                    local beforecopyinfo = gamedata.config.xianku_guaiwu[tostring(positon)]["1"] or {}
                    ccbDocumentControler.lab1:setString("通关"..beforecopyinfo.name1..beforecopyinfo.name2.."难度")
                 else   
                  local names = ""
                   if index ==2 then
                     names = "简单"
                   elseif index ==3 then
                     names = "普通"
                   elseif index ==4 then 
                     names = "困难"
                   end 
                    ccbDocumentControler.lab1:setString("通关"..names.."难度")
                end   
             -- end   

             ui.setLabelString(ccbDocumentControler.tiaozhantext,nil,19)
             ui.setLabelString(ccbDocumentControler.saodangtext,nil,19)


             ccbDocumentControler.p_boxButton:setSwallowsTouch(true)
             ccbDocumentControler.p_boxButton:setTouchPriority(self.touchPriority)
             ccbDocumentControler.p_boxButton:addHandleOfControlEvent(function()
               local reward = {}
               local _str = ""
               for i=1,4 do
                   _str = _str..copy["reward"..i]
               end
                local _reward = ui.getIDNUMChances(_str)
                
                for i = 1, #_reward do
                    _reward[i].num = _reward[i].num.."~".._reward[i].chance
                end
                gameWindows:openWindow("getStaff",{data = _reward,type = "掉落预览"},nil)

             end, CCControlEventTouchUpInside)

              ccbDocumentControler.tiaozhanBtn:setSwallowsTouch(true)
             ccbDocumentControler.tiaozhanBtn:setTouchPriority(self.touchPriority)
             ccbDocumentControler.tiaozhanBtn:addHandleOfControlEvent(function()
                 print("挑战 id:"..currentPosition.." difficulty:"..copy.difficulty)
                 --关卡ID 和 难度 
                 if self.battleTimes <=0 then
                    runGamePrompt({msg = "挑战次数不足"})
                   self:buyTimes()
                 else   
                    UIRequest({type = 6521, id = currentPosition , difficulty = copy.difficulty})
                 end   

             end, CCControlEventTouchUpInside)
              ccbDocumentControler.saodangbtn:setSwallowsTouch(true)
             ccbDocumentControler.saodangbtn:setTouchPriority(self.touchPriority)
             ccbDocumentControler.saodangbtn:addHandleOfControlEvent(function()

                 print("扫荡 id:"..currentPosition.." difficulty:"..copy.difficulty)
                 --关卡ID 和 难度 
                 if self.battleTimes <=0 then
                    runGamePrompt({msg = "挑战次数不足"})
                   self:buyTimes()
                 else  
                     UIRequest({type = 6522, id = currentPosition , difficulty = copy.difficulty})
                 end
             end, CCControlEventTouchUpInside)

              if self.ListTableView then
                  cellCCB:setPosition(1040/2, 0)
              end  

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.currentCopyInfo)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-102)

    -- if isfirstload then
    --     self.ListTableView:setLuaContentOffset(0, self.rootItems.listnode:getContentSize().height - 1*self.normalCellSize.y)
    -- end    

end


function blessingCave.buyTimes( self )

    local nowcount = GameScene.vipstatus.xianku_cishu --已经购买几次
    local totalcount = gamedata.config.vip[tostring(GameScene.vip.vip)].xianku_cishu --共可以买三次
    print("nowcount:"..nowcount.." totalcount:"..totalcount)
    gameWindows:openWindow("blessingCaveBuy",{totalcount = totalcount,challengeTime = self.battleTimes,  alreadybuy = nowcount })
 
end
function blessingCave.reload(self,data)    
    self.battleTimes = data.times or 0
    self.copyInfo = data.copyInfo or {}
    printT(self.copyInfo,"copyInfo")
    self.copyInfoCache = nil
    self.currentCopyInfo = nil
    self.rolelv = data.rolelv or 0

    self:setcopyInfo(self.battleTimes)
    local length = table.getTableLength(self.copyInfo)
    local toposition = math.modf( length / 5 ) --开启副本的最高限制 5
    --首次加载，显示最高挑战项目
    if self.isfirstload == 1 then
       self.maxPositon = toposition
       print("self.maxPositon first:".. self.maxPositon)
       self:setzhuan(toposition,self.currentcopyPosition)
       self:setCopyClick(true)
       self.isfirstload = 0 
    else
    --刷新原则 1、有新开启的 ，直接转到新的  2、无新开启的刷新本界面
        if self.maxPositon < toposition then
            self.isNewOpen =  1
            self.maxPositon = toposition
            self:setzhuan(toposition,toposition-1)
        else    
            self:setzhuan(self.currentcopyPosition,self.currentcopyPosition)
        end    
        print("self.maxPositon second:".. self.maxPositon)
        self:setCopyClick(false)

    end  
end

function blessingCave.reloadTimes( self,data)
    printT(data,"reloadTimes")
    local datatimes = data.buyTime or 0
    self.battleTimes = self.battleTimes + datatimes
    self:setcopyInfo(self.battleTimes)

    -- body
end
function blessingCave.clear(self)
    -- body
    print("blessingCave clear")
    self.copyInfo = nil
    self.copyInfoCache = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

    

return blessingCave
  j[  