
local wudaohui_duanwei = {
    rootNode = nil,
    rootItems = nil,
    rewarddata = {},
}

function wudaohui_duanwei.open(self,touchPriority,data,callback)
    -- printT(data,"pipei_open")
    self.touchPriority = touchPriority
    self.data = data.myallscorenum
    -- self.data = 1600
    self.rootNode, self.rootItems = CCBReaderLoad("wudaohui/wudaohui_duanwei", nil, true, "wudaohui_duanwei")
    

    -- self:reloaddata()
    UIRequest({type = 4107})

 
    
    return self.rootNode
end



function wudaohui_duanwei.reloaddata(self,data,isnoscroll)
    if not data then
        return
    else
        self.rewarddata = data
    end
    if isnoscroll then
        self.isnoscroll = isnoscroll
    end
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("wudaohuiduanwei")
        -- self.data = self.data + 100
        -- self:reloaddata()
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    -- 设置滚动区间


    local duanweiConfig = gamedata.config.wudao_part
    -- self.data.allscore
    self.duanweidata = {}
    for k,v in pairs(duanweiConfig) do
        print(k,v)
        table.insert(self.duanweidata,v)
    end

    local sortfunc = function( a,b )
        return a.id < b.id
    end

    table.sort( self.duanweidata, sortfunc )


    local ccbitemnum = math.ceil(table.getTableLength(self.duanweidata)/6) 
    print("ccbitemnum===",ccbitemnum)

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    if self.scrollNode then
        self.rootItems.container:removeAllChildrenWithCleanup(true)
    end
    -- self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-500-180))
    local containersizehight = (ccbitemnum-1)*1700.0
    self.rootItems.container:setContentSize(CCSize(900,containersizehight))
    self.scrollNode, self.scrollItems = {},{}
    self.scrollNode, self.scrollItems[tostring(1)] = CCBReaderLoad("wudaohui/wudaohui_duanwei_map", nil, true, "wudaohui_duanwei_map")
    self.scrollNode:setPosition(0,0)
    -- self.scrollNode:setVisible(false)
    self.rootItems.container:addChild(self.scrollNode)

    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,self.contentsize.y-180-500-180 - 1000),0)
    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    -- self.rootItems.scrollnode_touch:setContentSize(CCSize(gameConfig.originSize.width,self.contentsize.y-180-500-180))


    if self.scrollItems[tostring(1)] and self.scrollItems[tostring(1)].addNode then
        self.scrollItems[tostring(1)].addNode:removeAllChildrenWithCleanup(true)
    end
    
    for i=1,(ccbitemnum-1) do
        local distance = 1820 + (i-1)*1386
        self.scrollNode, self.scrollItems[tostring(i+1)] = CCBReaderLoad("wudaohui/cell_duanwei_map", nil, true, "cell_duanwei_map")
        self.scrollNode:setPosition(0,distance)
        -- self.scrollNode:setVisible(false)
        self.scrollItems[tostring(1)].addNode:addChild(self.scrollNode)
    end

    -- printT(self.scrollItems,"scrollItems==")
    for i=1,ccbitemnum do
        for ai=1,6 do

            local key_Ex
            if ai == nil or ai == 1 then
                key_Ex = ""
            else
                key_Ex = "_"..(ai-1)
            end

            local itemsconfig = self.duanweidata[tonumber((i-1)*6+ai)]
            if not itemsconfig then
                self.scrollItems[tostring(i)]["scoreText"..key_Ex]:setVisible(false)
                self.scrollItems[tostring(i)]["scoreLabel"..key_Ex]:setVisible(false)
                self.scrollItems[tostring(i)]["stageSprite"..key_Ex]:setVisible(false)
                self.scrollItems[tostring(i)]["levelSprite"..key_Ex]:setVisible(false)

                self.scrollItems[tostring(i)]["backsprite"..key_Ex]:setVisible(false)

                self.scrollItems[tostring(i)]["box"..key_Ex]:setVisible(false)
                self.scrollItems[tostring(i)]["r_button"..key_Ex]:setVisible(false)
            else
                -- printT(itemsconfig,"itemsconfig===")
            -- 
                -- printT(self.scrollItems[tostring(i)],"scrollItems===")

                ui.setLabelString(self.scrollItems[tostring(i)]["scoreText"..key_Ex],nil,14)
                local scoredata = ui.getIDandNUMs(itemsconfig.num)
                ui.setLabelString(self.scrollItems[tostring(i)]["scoreLabel"..key_Ex],(scoredata and scoredata[1] and scoredata[1]["num"] or 0),21)

                setSpriteFrameByName(self.scrollItems[tostring(i)]["stageSprite"..key_Ex], itemsconfig.icon1 and itemsconfig.icon1 or "alpha")
                setSpriteFrameByName(self.scrollItems[tostring(i)]["levelSprite"..key_Ex], itemsconfig.icon2 and itemsconfig.icon2 or "alpha")

                -- 宝箱奖励设置
                local idnum = (i-1)*6 + ai
                print("idnum===",idnum)
                local status = self.rewarddata[tostring(idnum)]
                setSpriteFrameByName(self.scrollItems[tostring(i)]["box"..key_Ex], "box4".."_"..status)

                self.scrollItems[tostring(i)]["r_button"..key_Ex]:setSwallowsTouch(true)
                self.scrollItems[tostring(i)]["r_button"..key_Ex]:setTouchPriority(self.touchPriority)
                self.scrollItems[tostring(i)]["r_button"..key_Ex]:addHandleOfControlEvent(function()
                    -- 双倍活动判断
                    
                    local tempdata = ui.getIDandNUMs(self.duanweidata[tonumber(idnum)].bonus)
                    

                    if status == 0 then
                        -- gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(self.datarewards[tostring(i)].reward),type = gameConfig.strings:string_common("task",6), huodongnum = 1},nil)
                        gameWindows:openWindow("getStaff",{data = tempdata,type = gameConfig.strings:string_common("task",6)},nil)
                    elseif status == 1 then
                        UIRequest({type = 4108, id = idnum})
                    elseif status == 2 then
                        -- gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(self.datarewards[tostring(i)].reward),type = "已领取"},nil)
                        gameWindows:openWindow("getStaff",{data = tempdata,type = gameConfig.strings:string_common("moreCommon",5)},nil)
                    end
                end, CCControlEventTouchUpInside)
            end
            

        end
    end

    self:setMyData()

end


function wudaohui_duanwei.setMyData(self)
    ui.setLabelString(self.rootItems.nowPositionText,nil,14)
    local posnum= 0
    for i,v in ipairs(self.duanweidata) do
        local scoredata1 = ui.getIDandNUMs(v.num)

        if  table.getTableLength(self.duanweidata) == i and self.data >= scoredata1[1].num then
            posnum = i

            print("iiii-==",i,self.data)
            -- printT(v)
            ui.setLabelString(self.rootItems.nowPositionLabel,(v.name or ""),21)
            setSpriteFrameByName(self.rootItems["stageSprite"], v.icon1 and v.icon1 or "alpha")
            setSpriteFrameByName(self.rootItems["levelSprite"], v.icon2 and v.icon2 or "alpha")
            break
        end


        -- if self.data >= scoredata1[1].num and self.data < scoredata1[2].num then
        if self.data < scoredata1[1].num then
            
            if i == 1 then
                ui.setLabelString(self.rootItems.nowPositionLabel,"无段位",21)
                self.rootItems["stageSprite"]:setVisible(false)
                self.rootItems["levelSprite"]:setVisible(false)
                posnum = 0
                break
            end
            posnum = i-1
            print("iiii-==",i,self.data)
            -- printT(v)

            ui.setLabelString(self.rootItems.nowPositionLabel,(self.duanweidata[i-1].name or ""),21)
            setSpriteFrameByName(self.rootItems["stageSprite"], self.duanweidata[i-1].icon1 and self.duanweidata[i-1].icon1 or "alpha")
            setSpriteFrameByName(self.rootItems["levelSprite"], self.duanweidata[i-1].icon2 and self.duanweidata[i-1].icon2 or "alpha")
            break
        end
    end
    local scrollnum = 440 + (posnum-1)*230
    -- if posnum == 0  then
    --     scrollnum = 0
    -- else

    -- end
    print("posnum==",posnum,scrollnum)
    if self.isnoscroll then

    else
        self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,-scrollnum),0.5)
    end
    

    -- 设置头像位置
    -- local idconfig = ui.IDconfig(GameScene.roleinfo.profile)
    -- printT(GameScene.roleinfo,"roleinfo===")
    ui.setNewIcon(self.scrollItems[tostring(1)],{cid = GameScene.roleinfo.profile})
    local descString = self.data or 0
    ui.setLabelString(self.scrollItems[tostring(1)].myscoreText,nil,14)
    ui.setLabelString(self.scrollItems[tostring(1)].myscoreLabel,descString,3)

    
    

    local icondistance = 0
    print("icondistance===",table.getTableLength(self.duanweidata),posnum)
    if table.getTableLength(self.duanweidata) == posnum then
        icondistance = scrollnum
    elseif posnum == 0 then
        icondistance = scrollnum + self.data/(ui.getIDandNUMs(self.duanweidata[posnum+1].num))[1]["num"] * 230
    else
        local duanweiscore = self.data - (ui.getIDandNUMs(self.duanweidata[posnum].num))[1]["num"]
        local nextduwanweiscore = (ui.getIDandNUMs(self.duanweidata[posnum+1].num))[1]["num"] - (ui.getIDandNUMs(self.duanweidata[posnum].num))[1]["num"]
        icondistance = duanweiscore/nextduwanweiscore*230 + scrollnum
        print("duanweiscore===",duanweiscore,nextduwanweiscore,icondistance)
    end

    self.scrollItems[tostring(1)]["myIconNode"]:setPosition(453,icondistance)
end

function wudaohui_duanwei.close(self)

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.scrollItems = nil
    self.rewarddata = {}
    self.isnoscroll = false
end

return wudaohui_duanwei

   (  