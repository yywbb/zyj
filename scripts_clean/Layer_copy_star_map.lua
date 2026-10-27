--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/9/10
-- Time: 上午11:22
-- To change this template use File | Settings | File Templates.
--

local starcopymap = {

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
}



function starcopymap.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("copystar/copystar_map_container", nil, true, "copystar_map_container")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.data = param.data
    self.alldata = param.alldata or {}
    --
    self.rootItems.container:setContentSize(CCSize(1080,2400))
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.mapNode, self.mapItems = CCBReaderLoad("copystar/copystar_map", nil, true, "copystar_map")
    self.mapNode:setPosition(0,0)
    self.rootItems.container:addChild(self.mapNode)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-160))
    --
    self.mapindex = param.index
    self.section = self.data.section
    self.attacknum = param.attacknum
    --
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems["backBtn"]:setSwallowsTouch(true)
    self.rootItems["backBtn"]:setTouchPriority(self.touchPriority-2)
    self.rootItems["backBtn"]:addHandleOfControlEvent(function()
        print("backBtn")
        GameScene:shiftLayer("copy_chapter","down",{
            datatype= "star",
            section = self.section,
        })
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
               local mapconfig = gamedata.config.star_map[tostring(self.alldata[tostring(self.section)][tostring(self.mapindex+1)].mapid)]
               runGamePrompt({msg = "通关普通副本"..gamedata.config.map[tostring(mapconfig.condition)].name.."后开启"})
           end
        elseif self.alldata[tostring(self.section+1)] and self.alldata[tostring(self.section+1)]["1"] then
            if self.alldata[tostring(self.section+1)]["1"].status and self.alldata[tostring(self.section+1)]["1"].status >= 0 then
                self.data = self.alldata[tostring(self.section+1)]["1"]
                self.section = self.section+1
                self.mapindex = 1
                self:reloaddata()
            else
                local mapconfig = gamedata.config.star_map[tostring(self.alldata[tostring(self.section+1)]["1"].mapid)]
                runGamePrompt({msg = "通关普通副本"..gamedata.config.map[tostring(mapconfig.condition)].name.."后开启"})
            end
        else
            runGamePrompt({msg = "未开启"})
        end

    end, CCControlEventTouchUpInside)
    --
    self:reloaddata()
end

function starcopymap.clear(self)
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

function starcopymap.reloaddata(self,data,all)

    local olddata = self.data or nil

    if data and all then
        self.alldata = data.sections
        self.data = data.sections[tostring(self.section)][tostring(self.mapindex)]
        self.attacknum = data.attacknum
    elseif data then
        self.data = data
    end
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
    ui.setLabelString(self.rootItems.times,"今日可战胜次数: "..(gamedata.config.global_kv.star_copy_times.value-self.attacknum).."/"..gamedata.config.global_kv.star_copy_times.value,14)
    --
    if self.rootItems.finish then
        self.rootItems.finish:setVisible(true)
        self.rootItems.nextNode:setVisible(true)
    end
    --
    self.config = gamedata.config.star_copy[tostring(self.data.mapid)]

    for i = 1,5 do
       if self.config[tostring(i)] then
           self.mapItems["point_"..i]:setVisible(true)
           --
           if table.getTableLength(self.data.points) == i then
               if self.data.points[tostring(i)] and self.data.points[tostring(i)].pointstatus == -1 then
                   self.mapItems["p_duikan"..(i>1 and ("_"..(i-1)) or "")]:setVisible(true)
                   if self.rootItems.finish then
                       self.rootItems.finish:setVisible(false)
                       self.rootItems.nextNode:setVisible(false)
                   end
               else
                   self.mapItems["p_duikan"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
               end
           else
               self.mapItems["p_duikan"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
           end
           --
           if self.data.points[tostring(i)] and self.data.points[tostring(i)].boxstatus == 1 then
               self.mapItems["p_box"..(i>1 and ("_"..(i-1)) or "")]:setVisible(true)
               self.mapItems["p_boxButton"..(i>1 and ("_"..(i-1)) or "")]:setSwallowsTouch(true)
               self.mapItems["p_boxButton"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.touchPriority-1)
               self.mapItems["p_boxButton"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                    print("p_boxButton"..i)
                    gameTouch:clickprofbytime(0.5)
                    UIRequest({type = 1352, mapid = self.data.mapid, pointid = i})
               end, CCControlEventTouchUpInside)
           else
               self.mapItems["p_box"..(i>1 and ("_"..(i-1)) or "")]:setVisible(false)
           end
           --
           ui.setLabelString(self.mapItems["p_generalName"..(i>1 and ("_"..(i-1)) or "")],self.config[tostring(i)].name,1)
           
           ui.setLabelString(self.mapItems["p_power"..(i>1 and ("_"..(i-1)) or "")],"推荐战斗力:"..self.config[tostring(i)].power,21)
           --
           self.mapItems["p_generalNode"..(i>1 and ("_"..(i-1)) or "")]:removeAllChildrenWithCleanup(true)
           local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(self.config[tostring(i)].icon).animationid)].name
           local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
           Gneral:setAnimation("stand",true,0)
           Gneral:setScale(1.2)
           Gneral:setScaleX(1.2)
           Gneral:setPosition(0,0)
           self.mapItems["p_generalNode"..(i>1 and ("_"..(i-1)) or "")]:addChild(Gneral)
           --
           if self.data.points[tostring(i)]  then
             self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:setSwallowsTouch(true)
             self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:setTouchEnabled(true)
             self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:setTouchPriority(self.touchPriority-1)
             self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                 print("p_generalButton"..i)
                 -- if self.data.points[tostring(i)] then
                     if self.attacknum >= tonumber(gamedata.config.global_kv.star_copy_times.value) then
                         runGamePrompt({msg = "今日挑战次数已用完"})
                     else
                          gameWindows:openWindow("copystarInfo",{ mapid = self.data.mapid, pointid = i, pointstatus = self.data.points[tostring(i)].pointstatus },nil)
                     end
                 -- end
             end, CCControlEventTouchUpInside)
           else
             self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:setSwallowsTouch(false)
             self.mapItems["p_generalButton"..(i>1 and ("_"..(i-1)) or "")]:setTouchEnabled(false)
              print("p_generalButton"..i.."没有开启")
           end
           --
           if self.data.points[tostring(i)] then
               ui.removeGray("CCNode",Gneral)
           else
               ui.addGray("CCNode",Gneral)
           end
       else
           self.mapItems["point_"..i]:setVisible(false)
       end
    end

end

function starcopymap.UIUpdateData(self,isreset)
    if isreset then
        UIRequest({type = 1350})
    end
end



return starcopymap
