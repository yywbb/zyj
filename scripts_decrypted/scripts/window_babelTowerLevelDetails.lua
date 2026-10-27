local levelDetails = {
    rootNode = nil,
    rootItems = nil,
    data = {},
    generalListTableView = nil,
    skillListTableView = nil,
    generaldata = {},

    showid = 1,
}

function levelDetails.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("tongtianta/tc_guaiinfo", nil, true, "tc_guaiinfo")

    self.touchPriority = touchPriority
    self.callback = callback
    self.data = data

    if  self.rootItems.leftbutton then
        self.rootItems.leftbutton:addHandleOfControlEvent(function()
            if self.generalListTableView then
                if self.generalListTableView:getLuaContentOffsetX()+200 > 0 then
                    self.generalListTableView:setLuaContentOffset(0 , 0)
                else
                    self.generalListTableView:setLuaContentOffset(self.generalListTableView:getLuaContentOffsetX()+200 , 0)   
                end
            end    
        end, CCControlEventTouchUpInside)
        self.rootItems.leftbutton:setSwallowsTouch(true)
        self.rootItems.leftbutton:setTouchPriority(self.touchPriority)
    end

    if  self.rootItems.rightbutton then
        self.rootItems.rightbutton:addHandleOfControlEvent(function()
            if self.generalListTableView then
                if (self.generalListTableView:getLuaContentOffsetX()-200) < (800-table.getTableLength(self.generaldata)*200) then
                    self.generalListTableView:setLuaContentOffset(800-table.getTableLength(self.generaldata)*200  , 0)
                else
                    self.generalListTableView:setLuaContentOffset(self.generalListTableView:getLuaContentOffsetX()-200 , 0)    
                end
            end    
        end, CCControlEventTouchUpInside)
        self.rootItems.rightbutton:setSwallowsTouch(true)
        self.rootItems.rightbutton:setTouchPriority(self.touchPriority)
    end

    if  self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindowDirect("babelTowerLevelDetails")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    self.rootItems.battleButton:addHandleOfControlEvent(function()
        local levelConfig = gamedata.config.tongtianta_guaiwu[tostring(self.data.mapId)][tostring(self.data.level)]
        if self.data.challengeTime >= levelConfig.challenge then
            runGamePrompt({msg = gameConfig.strings:string_common("babelTower",18)})
        else
            UIRequest({type = 7013,levelId = self.data.level})
            gameWindows:closeWindowDirect("babelTowerLevelDetails")
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.battleButton:setSwallowsTouch(true)
    self.rootItems.battleButton:setTouchPriority(self.touchPriority)




    self.rootItems.skillListScroll = tolua.cast(self.rootItems.skillListScroll, "CCScrollView")
    self.rootItems.skillListScroll:setTouchPriority(self.touchPriority)
    
    ui.setLabelString(self.rootItems.skilltitle,nil,14)


    self.data = data
    printT(self.data,"levelDetails")

    self.config = gamedata.config.tongtianta_guaiwu[tostring(self.data.mapId)][tostring(self.data.level)]
    self:setIcon()
    self:initFixedString()
    addDelayUpdateFunc(function()
        self:reload()
    end,"levelDetailsreload")

    return self.rootNode,true
end

function levelDetails.initFixedString( self )
    ui.setLabelString(self.rootItems.battleLab,gameConfig.strings:string_common("babelTower",14),19)
end

function levelDetails.setIcon(self)
	local reward1 = ui.getIDandNUMs(self.config.reward)
	local reward2 = {}

	for i,v in ipairs(string.split(self.config.daily_reward,";")) do
		print("split",i,v)
		if v and v ~= "" then
			local _r = string.split(v,",")

            if tonumber(_r[2]) == tonumber(_r[3]) then
                table.insert(reward2,{cid = tonumber(_r[1]),num = tonumber(_r[2])})
            else
                table.insert(reward2,{cid = tonumber(_r[1]),num = _r[2].."~".._r[3]})
            end
			
		end
	end

	for i=1,5 do
		if reward1[i] then
			self.rootItems["icon1_"..i]:setVisible(true)
			ui.setNewIcon(self.rootItems, {cid = reward1[i].cid,num = reward1[i].num}, i - 1)

            local id = i - 1
            local key_Ex
            if id == 0 then
                key_Ex = ""
            else
                key_Ex = "_"..id
            end
            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority-1)
            self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(reward1[i].cid)
            end, CCControlEventTouchUpInside)


            if self.data.firstKillStatus == 1 then
                self.rootItems["hasnode"..i]:setVisible(true)
            else
                self.rootItems["hasnode"..i]:setVisible(false)
            end
		else
			self.rootItems["icon1_"..i]:setVisible(false)
            self.rootItems["hasnode"..i]:setVisible(false)
		end
	end

	for i=1,5 do
		if reward2[i] then
			self.rootItems["icon2_"..i]:setVisible(true)
			ui.setNewIcon(self.rootItems, {cid = tonumber(reward2[i].cid),num = reward2[i].num}, 5 + i - 1)

            local id = 5 + i - 1
            local key_Ex
            if id == 0 then
                key_Ex = ""
            else
                key_Ex = "_"..id
            end

            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority-1)
            self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(tonumber(reward2[i].cid))
            end, CCControlEventTouchUpInside)

		else
			self.rootItems["icon2_"..i]:setVisible(false)
		end
	end
end

function levelDetails.reload(self,data)
    self.generaldata = {}
    for i = 1,7 do
        if self.config["p"..i] and self.config["p"..i] > 0 and gamedata.config.copy_monster[tostring(self.config["p"..i])] then

            local cid = gamedata.config.copy_monster[tostring(self.config["p"..i])].generalid
            local breakskill = {}
            local breaklevel = self.config["break"..i.."-correct"] or 0
            local generalconfig = gamedata.config.general[tostring(cid)] or {} 
            for i = 1,breaklevel do
                if generalconfig["break"..i] and generalconfig["break"..i] > 0 then
                    table.insert(breakskill,generalconfig["break"..i])
                end    
            end
            table.insert(self.generaldata,{cid = cid, breakskill = breakskill })
        end    
    end
    self:freshChallengeTimes()
    self:setPage()
end


function levelDetails.freshChallengeTimes(self,times)
    
    if times then
        self.data.challengeTime = times
    end

    local canChallengeTime = self.config.challenge - self.data.challengeTime
    self.rootItems.challengeTime:setString(canChallengeTime)
    self.rootItems.challengeMaxTime:setString("/"..self.config.challenge)
    if canChallengeTime > 0 then
        self.rootItems.challengeTime:setColor(ccc3(255,255,255))
    else
        self.rootItems.challengeTime:setColor(ccc3(255,0,0))
    end
    


    if self.config.challenge - self.data.challengeTime <= 0 then
        ui.addGray("CCControlButton", self.rootItems["battleButton"])
        ui.addGray("CCLabelTTF", self.rootItems["battleLab"])
    else
        ui.removeGray("CCControlButton", self.rootItems["battleButton"])
        ui.removeGray("CCLabelTTF", self.rootItems["battleLab"])
    end

end

function levelDetails.close(self)
    self.generaldata = {}
    self.data = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.generalListTableView = nil
    self.skillListTableView = nil
    self.showid = 1

    if self.callback then
        self.callback()
    end
end

function levelDetails.reloadGeneralList(self,alldata)
    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(200,200)
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

            cellCCB:setScale(1)
            ccbDocumentControler.i_selectEffect:removeAllChildrenWithCleanup(true)

            ui.setNewIcon(ccbDocumentControler,self.generaldata[a1+1])
            -- setSpriteFrameByName(ccbDocumentControler["i_icon"], ui.IDconfig(self.generaldata[a1+1].cid).icon and ui.IDconfig(self.generaldata[a1+1].cid).icon or "alpha")
            -- ui.setSpriteTextureRect(ccbDocumentControler["i_icon"],0,0,150,150)

            if self.showid == a1+1 then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                eccb:setScale(1.1)
                ccbDocumentControler.i_selectEffect:addChild(eccb)
            end

            cellCCB:setPosition(100,100)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.generaldata)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            self.showid = a1:getIdx()+1
            self:setPage()

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.generalListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.generalListScroll:getContentSize().width,
        viewheight = self.rootItems.generalListScroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.generalListScroll:addChild(self.generalListTableView)
    self.generalListTableView:setTouchPriority(self.touchPriority)
end


function levelDetails.reloadSkillList(self)
    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(880,120)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("tongtianta/cell_tuposkill.ccbi", nil, true, "cell_tuposkill")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local breakskill = self.generaldata[self.showid].breakskill[a1+1]

            if breakskill and breakskill > 0 then
                ccbDocumentControler.skill:setString(gamedata.config.breakskill[tostring(breakskill)].name.."：")
                ccbDocumentControler.skilldesc:setString(gamedata.config.breakskill[tostring(breakskill)].desc)
            else
                ccbDocumentControler.skill:setString("")
                ccbDocumentControler.skilldesc:setString("")
            end
            cellCCB:setPosition(880/2,0)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = self.generaldata[self.showid] and #self.generaldata[self.showid].breakskill or 0
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.skillListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.skillListScroll:getContentSize().width,
        viewheight = self.rootItems.skillListScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.skillListScroll:addChild(self.skillListTableView)
    self.skillListTableView:setTouchPriority(self.touchPriority)
end

function levelDetails.setPage(self)

    if not self.generalListTableView then
        self:reloadGeneralList()
    else
        self.generalListTableView:reloadData()
    end


    -- if not self.skillListTableView then
    --     self:reloadSkillList()
    -- else
    --     self.skillListTableView:reloadData()
    --     local skillNum = self.generaldata[self.showid] and #self.generaldata[self.showid].breakskill or 0
    --     self.skillListTableView:setLuaContentOffset(0, 290 - skillNum*120)
    -- end

    --

    local breakskill = self.generaldata[self.showid].breakskill


    -- local breakskill = {}
    -- local breaklevel = self.generaldata[self.showid] and self.generaldata[self.showid].breaklevel or 0
    -- local generalcid = self.generaldata[self.showid] and self.generaldata[self.showid].cid or 0
    -- local generalconfig = gamedata.config.general[tostring(generalcid)] or {} 
    -- for i = 1,breaklevel do
    --     if generalconfig["break"..i] and generalconfig["break"..i] > 0 then
    --         table.insert(breakskill,generalconfig["break"..i])
    --     end    
    -- end
    --
    for i = 1,12 do
        if self.rootItems["skill"..i] and self.rootItems["skilldesc"..i] then
            if breakskill[i] and breakskill[i] > 0 and gamedata.config.breakskill[tostring(breakskill[i])] then
                ui.setLabelString(self.rootItems["skill"..i],gamedata.config.breakskill[tostring(breakskill[i])].name.."：",13)
                ui.setLabelString(self.rootItems["skilldesc"..i],gamedata.config.breakskill[tostring(breakskill[i])].desc,2)
            else
                ui.setLabelString(self.rootItems["skill"..i],"",13)
                ui.setLabelString(self.rootItems["skilldesc"..i],"",2)
            end
        end
    end 
    --
    -- if #breakskill > 2 then
    --     local fixh = (#breakskill-2)*120+340
    --     self.rootItems.container:setContentSize(CCSize(880,fixh))
    --     self.yuanNode:setPosition(440,fixh)
    --     self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,340-fixh),0)
    --     self.rootItems.ismore:setVisible(true)
    -- else
    --     self.rootItems.container:setContentSize(CCSize(880,700))
    --     self.rootItems.breakNode:setPosition(440,260)
    --     self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    --     self.rootItems.ismore:setVisible(false)
    -- end

    
    local fixh = #breakskill*120 + 420 + 40
    self.rootItems.container:setContentSize(CCSize(880,fixh))
    self.rootItems.breakNode:setPositionY(#breakskill*120)
    self.rootItems.iconNode:setPositionY(#breakskill*120 + 40)
    self.rootItems.container:setPositionY(700 - fixh)
    -- self.rootItems.skillListScroll:setContentOffsetInDuration(ccp(0,700 - fixh),0)
    -- self.rootItems.ismore:setVisible(false)

end

return levelDetails
 '<  