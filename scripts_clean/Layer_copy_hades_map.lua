--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/9/10
-- Time: 上午11:22
-- To change this template use File | Settings | File Templates.
--

local hadescopymap = {

    resource = nil,
    data = {},
    rootNode = nil,
    rootItems = nil,
    config = {},
    touchPriority = -102,
    mapindex = 0,
    section = 0,
    attacknum = 0,
    alldata = {},
    arrangedata = nil,
    lastdata = {},

    isContentScroll = false,
    touchX = 0,
    touchY = 0,
}



function hadescopymap.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("copydiyu/copydiyu_map_container", nil, true, "copydiyu_map_container")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.data = param and param.data or table.copy(self.lastdata.data)
    self.alldata = param and param.alldata or table.copy(self.lastdata.alldata)
    --
    self.rootItems.container:setContentSize(CCSize(1080,2400))
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.mapNode, self.mapItems = CCBReaderLoad("copydiyu/copydiyu_map", nil, true, "copydiyu_map")
    self.mapNode:setPosition(0,0)
    self.rootItems.container:addChild(self.mapNode)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-160))
    --
    for i = 1,5 do
        if self.mapItems["effect_particle"..i] then
            self.mapItems["effect_particle"..i]:setPositionType(kCCPositionTypeGrouped)
        end  
    end  
    --
    self.mapindex = param and param.index or self.lastdata.index
    self.section = self.data.section
    self.attacknum = param and param.attacknum or self.lastdata.attacknum
    --
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems["backBtn"]:setSwallowsTouch(true)
    self.rootItems["backBtn"]:setTouchPriority(self.touchPriority-2)
    self.rootItems["backBtn"]:addHandleOfControlEvent(function()
        print("backBtn")
        GameScene:shiftLayer("copy_chapter","down",{
            datatype= "hades",
            section = self.section,
        })
    end, CCControlEventTouchUpInside)
    --
    self.rootItems.buzhenBtn:setSwallowsTouch(true)
    self.rootItems.buzhenBtn:setTouchPriority(self.touchPriority-2)
    self.rootItems.buzhenBtn:addHandleOfControlEvent(function()
        if self.arrangedata then
          if gameConfig:checkBuildOpen(198) and GameScene:checkopenlevelbyId(198,true) then
              GameScene:shiftLayer("deployment","up",self.arrangedata)
          else
              gameWindows:openWindow("slotarrange",self.arrangedata,nil)
          end
        end
    end, CCControlEventTouchUpInside)
    --
    self.rootItems["nextBtn"]:setSwallowsTouch(true)
    self.rootItems["nextBtn"]:setTouchPriority(self.touchPriority-2)
    self.rootItems["nextBtn"]:addHandleOfControlEvent(function()
        print("nextBtn")

        if self.alldata[tostring(self.section)][tostring(self.mapindex+1)] then
           if self.alldata[tostring(self.section)][tostring(self.mapindex+1)].status and self.alldata[tostring(self.section)][tostring(self.mapindex+1)].status >= 0 then
               self.data = self.alldata[tostring(self.section)][tostring(self.mapindex+1)]
               self.mapindex = self.mapindex+1
               self:reloaddata()
           else
               local mapconfig = gamedata.config.hades_map[tostring(self.alldata[tostring(self.section)][tostring(self.mapindex+1)].mapid)]
               runGamePrompt({msg = "通关普通副本"..gamedata.config.map[tostring(mapconfig.condition)].name.."后开启"})
           end
        elseif self.alldata[tostring(self.section+1)] and self.alldata[tostring(self.section+1)]["1"] then
            if self.alldata[tostring(self.section+1)]["1"].status and self.alldata[tostring(self.section+1)]["1"].status >= 0 then
                self.data = self.alldata[tostring(self.section+1)]["1"]
                self.section = self.section+1
                self.mapindex = 1
                self:reloaddata()
            else
                local mapconfig = gamedata.config.hades_map[tostring(self.alldata[tostring(self.section+1)]["1"].mapid)]
                runGamePrompt({msg = "通关普通副本"..gamedata.config.map[tostring(mapconfig.condition)].name.."后开启"})
            end
        else
            runGamePrompt({msg = "未开启"})
        end

    end, CCControlEventTouchUpInside)
    --
    self.rootItems["preBtn"]:setSwallowsTouch(true)
    self.rootItems["preBtn"]:setTouchPriority(self.touchPriority-2)
    self.rootItems["preBtn"]:addHandleOfControlEvent(function()
        print("preBtn")
        printT(self.alldata)
        if tonumber(self.mapindex) > 1 then
            self.data = self.alldata[tostring(self.section)][tostring(self.mapindex-1)]
            self.mapindex = self.mapindex-1
            self:reloaddata()
        elseif tonumber(self.section) > 1 then
            local mindex = table.getTableLength(self.alldata[tostring(self.section-1)])
            self.data = self.alldata[tostring(self.section-1)][tostring(mindex)]
            self.section = self.section-1
            self.mapindex = mindex
            self:reloaddata()
        end  

    end, CCControlEventTouchUpInside)
    --


    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchX = x
            self.touchY = y
            return true
        end
    end

    local function ccTouchMoved(x, y)

    end

    local function ccTouchEnded(x, y)
        if math.abs(y - self.touchY) > 30 then
            self.isContentScroll = true
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority-1, false)
    self.rootItems.touchLayer:setTouchPriority(self.touchPriority-1)
    self.rootItems.touchLayer:setTouchEnabled(true)

    --
    self:reloaddata()
end

function hadescopymap.clear(self)

    self.isContentScroll = false
    self.touchX = 0
    self.touchY = 0

    self.alldata = {}
    self.config = {}
    self.data = {}
    self.mapid = 0
    self.section = 0
    self.attacknum = 0
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil
end

function hadescopymap.reloaddata(self,data,all)

    local olddata = self.data or nil

    if data and all then
        self.alldata = data.sections
        self.data = data.sections[tostring(self.section)][tostring(self.mapindex)]
        self.attacknum = data.attacknum
    elseif data then
        self.data = data
    end
    --
    self.lastdata.data = table.copy(self.data)
    self.lastdata.alldata = table.copy(self.alldata)
    self.lastdata.index = self.mapindex
    self.lastdata.attacknum = self.attacknum
    --
    if olddata then
       local old = false
       local new = false
       for i = 1,5 do
           if self.data.points[tostring(i)] and self.data.points[tostring(i)].pointstatus == -1 then
               new = true
           end
           if olddata.points[tostring(i)] and olddata.points[tostring(i)].pointstatus == -1 then
               old = true
           end
       end
       if old and (not new) then
           self.rootItems.finishEffect:removeAllChildrenWithCleanup(true)
           local finishNode,finishItems = CCBReaderLoad("UIEffect/mingjiang/star_shengli", nil, true, "finish")
           finishNode:setPosition(0,0)
           self.rootItems.finishEffect:addChild(finishNode)
           self.rootItems.finishEffect:setScale(1)
           local animationManager = getAnimationManager(finishItems)
           animationManager:setAnimationCompletedCallback(function()
               self.rootItems.finishEffect:removeAllChildrenWithCleanup(true)
           end)
           animationManager:runAnimationsForSequenceNamed("play")
       end
    end
    --
    ui.setLabelString(self.rootItems.times,"今日可战胜次数: "..(gamedata.config.global_kv.hades_copy_times.value-self.attacknum).."/"..gamedata.config.global_kv.hades_copy_times.value,14)
    --
    if self.rootItems.finish then
        self.rootItems.finish:setVisible(true)
        self.rootItems.nextNode:setVisible(true)
        --self.rootItems.times:setVisible(false)
    end
    --
    ui.setLabelString(self.rootItems.titlename,gamedata.config.hades_map[tostring(self.data.mapid)] and gamedata.config.hades_map[tostring(self.data.mapid)].name or "",19)
    --
    local mapboxreward = ui.getIDandNUMs(gamedata.config.hades_map[tostring(self.data.mapid)].reward) or {}
    self.rootItems.rewardPreviewBtn:setSwallowsTouch(true)
    self.rootItems.rewardPreviewBtn:setTouchPriority(self.touchPriority-2)
    self.rootItems.rewardPreviewBtn:addHandleOfControlEvent(function()
      gameTouch:clickprofbytime(0.5)
      -- if self.data.mapbox and self.data.mapbox == 1 then
      --     UIRequest({type = 1372,mapid = self.data.mapid})
      -- elseif self.data.mapbox and self.data.mapbox == 2 then
      --     gameWindows:openWindow("getStaff",{data = mapboxreward,type = "奖励已领取"},nil)
      -- else
      --     gameWindows:openWindow("getStaff",{data = mapboxreward,type = "奖励预览"},nil)
      -- end  
      --
      local mapboxstatus = self.data.mapbox or 0
      local mapid = self.data.mapid
      gameWindows:openWindow("hadesAllReward",{mapboxreward = mapboxreward,mapboxstatus = mapboxstatus, mapid = mapid, },nil)
      --
    end, CCControlEventTouchUpInside)
    --
    if self.data.mapbox and self.data.mapbox == 1 then
        self.rootItems.hint_reward:setVisible(true)
    else
        self.rootItems.hint_reward:setVisible(false)
    end  
    --
    self.config = gamedata.config.hades_copy[tostring(self.data.mapid)]

    for i = 1,5 do
       if self.config[tostring(i)] then
           self.mapItems["point_"..i]:setVisible(true)
           --
           if table.getTableLength(self.data.points) == i then
               if self.data.points[tostring(i)] and self.data.points[tostring(i)].pointstatus == -1 then
                   self.mapItems["p_duikan"..(i>1 and ("_"..(i-1)) or "")]:setVisible(true)
                   self.mapItems["iskilled"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
                   if self.rootItems.finish then
                       self.rootItems.finish:setVisible(false)
                       self.rootItems.nextNode:setVisible(false)
                       --self.rootItems.times:setVisible(true)
                   end
               else
                   self.mapItems["p_duikan"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
                   self.mapItems["iskilled"..(i>1 and ("_"..(i-1)) or "")]:setVisible(true)
               end
           else
               self.mapItems["p_duikan"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
               self.mapItems["iskilled"..(i>1 and ("_"..(i-1)) or "")]:setVisible(table.getTableLength(self.data.points) > i) 
           end
           --
           if self.data.points[tostring(i)] and self.data.points[tostring(i)].pointstatus == -1 then
               self.mapItems["p_box"..(i>1 and ("_"..(i-1)) or "")]:setVisible(true)
               --self.mapItems["p_boxButton"..(i>1 and ("_"..(i-1)) or "")]:setSwallowsTouch(true)
               self.mapItems["p_boxButton"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.touchPriority)
               self.mapItems["p_boxButton"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                    print("p_boxButton"..i)
                    if self.isContentScroll then return end
                    gameTouch:clickprofbytime(0.5)
                    local reward = ui.getIDandNUMs(self.config[tostring(i)].reward) or {}
                    gameWindows:openWindow("getStaff",{data = reward,type = "奖励预览"},nil)
               end, CCControlEventTouchUpInside)
           else
                self.mapItems["p_box"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
           end
           --
           if self.config[tostring(i+1)] then
              self.mapItems["isboss"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
           else
              self.mapItems["isboss"..(i>1 and ("_"..(i-1)) or "")]:setVisible(true)
           end 
           --
           ui.setLabelString(self.mapItems["p_generalName"..(i>1 and ("_"..(i-1)) or "")],self.config[tostring(i)].name,1)
           
           if self.config[tostring(i)].power and self.config[tostring(i)].power > 0 then
              ui.setLabelString(self.mapItems["p_power"..(i>1 and ("_"..(i-1)) or "")],"推荐战斗力:"..self.config[tostring(i)].power,21)
           else
              ui.setLabelString(self.mapItems["p_power"..(i>1 and ("_"..(i-1)) or "")],"",21)
           end  
           --
           self.mapItems["p_generalNode"..(i>1 and ("_"..(i-1)) or "")]:removeAllChildrenWithCleanup(true)
           local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(self.config[tostring(i)].icon).animationid)].name
           local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
           Gneral:setAnimation("stand",false,0)
           Gneral:setScale(1.2)
           Gneral:setScaleX(1.2)
           Gneral:setPosition(0,0)
           self.mapItems["p_generalNode"..(i>1 and ("_"..(i-1)) or "")]:addChild(Gneral)
           --
           if self.data.points[tostring(i)] and self.data.points[tostring(i)].pointstatus == -1 then
              Gneral:setAnimation("stand",true,0)
              self:setGeneralEffect(Gneral,self.mapItems["p_generalNode"..(i>1 and ("_"..(i-1)) or "")])
           end 
           --
           if self.data.points[tostring(i)]  then
               --self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:setSwallowsTouch(true)
               self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:setTouchEnabled(true)
               self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.touchPriority)
               self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                   print("p_generalButton"..i)
                   if self.isContentScroll then return end
                   -- if self.data.points[tostring(i)] then
                    if self.data.points[tostring(i)] and self.data.points[tostring(i)].pointstatus == -1 then
                       if self.attacknum >= tonumber(gamedata.config.global_kv.hades_copy_times.value) then
                           runGamePrompt({msg = "今日挑战次数已用完"})
                       else
                            gameWindows:openWindow("copyhadesInfo",{ mapid = self.data.mapid, pointid = i, pointstatus = self.data.points[tostring(i)].pointstatus },nil)
                       end
                    else
                      runGamePrompt({msg = "已通过本关卡挑战"})
                    end 
                   -- end
               end, CCControlEventTouchUpInside)
           else
               self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:setSwallowsTouch(false)
               self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:setTouchEnabled(false)
                print("p_generalButton"..i.."没有开启")
           end
           --
           if self.data.points[tostring(i)] and self.data.points[tostring(i)].pointstatus == -1 then
               ui.removeGray("CCNode",Gneral)
           else
               ui.addGray("CCNode",Gneral)
           end
       else
           self.mapItems["point_"..i]:setVisible(false)
           self.mapItems["p_duikan"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
       end
    end
    --
    if (tonumber(self.section) > 1) or (tonumber(self.mapindex) > 1) then
        self.rootItems.preNode:setVisible(true)
    else
        self.rootItems.preNode:setVisible(false)
    end
    --
    local preHint = false
    local nextHint = false
    for k,v in pairs(self.alldata) do
        for kk,vv in pairs(v) do
            if (vv.mapid < tonumber(self.data.mapid)) and (vv.mapbox == 1) then
                preHint = true
            elseif (vv.mapid > tonumber(self.data.mapid)) and (vv.mapbox == 1) then
                nextHint = true
            end  
        end  
    end
    self.rootItems.hint_pre:setVisible(preHint)
    self.rootItems.hint_next:setVisible(nextHint)
    --
end

function hadescopymap.setSlotData(self,slots)
    if slots then
        self.arrangedata = table.copy(slots)
    end
end

function hadescopymap.UIUpdateData(self,isreset)
    if isreset then
        UIRequest({type = 1370})
    end
end

--
function hadescopymap.setGeneralEffect(self,general,generalNode)
    local color1 = CCTintTo:create(1,128,128,128)
    local color2 = CCTintTo:create(1,140,128,128)
    local sq = CCRepeatForever:create(CCSequence:createWithTwoActions(color1,color2))
    self:skeletonTintTo(general,sq)
    --
    -- local ccb,item = CCBReaderLoad("UIEffect/diyueffect/diyueffect2", nil, true, "jie")
    -- ccb:setScale(0.5)
    -- ccb:setPosition(0,0)
    -- generalNode:addChild(ccb)
end
--
function hadescopymap.skeletonTintTo(self,skeleton,TintTo)
    if skeleton.g1 then
        skeleton.g1:runAction(TintTo)
    else
        skeleton:runAction(TintTo)
    end
end

--

return hadescopymap
