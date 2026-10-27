--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/4
-- Time: 下午2:25
-- To change this template use File | Settings | File Templates.
--

local bossDetail = {
	rootNode = nil,
	rootItems = nil,
	titleCellSize = {x=923, y=200},
	bossSkillTab = {},
	treasureListTableView = nil,
}

function bossDetail.open(self, touchPriority, data, callback)
	self.rootNode, self.rootItems = CCBReaderLoad("kingman/kingman_skillinfo", nil, true, "bossDetail")
	self.show = true

	self.touchPriority = touchPriority
	self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("bossDetail")
	end, CCControlEventTouchUpInside)
	self.rootItems.closeButton:setSwallowsTouch(true)
	self.rootItems.closeButton:setTouchPriority(self.touchPriority)

	self.rootItems.doButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("bossDetail")
	end, CCControlEventTouchUpInside)
	self.rootItems.doButton:setSwallowsTouch(true)	
	self.rootItems.doButton:setTouchPriority(self.touchPriority)	
	
	ui.setLabelString(self.rootItems.doLab, "关 闭", 19)
	self.rootItems.title:setString("BOSS详情")
	-- 副本名字    id  gamedata.config.personalboss_att
	local num = data.num
	local animationId = gamedata.config.personalboss_att[tostring(num)].animationid
	for i=1,4 do
		if gamedata.config.personalboss_att[tostring(num)]["skill" .. i] ~= 0 then
			local id = gamedata.config.personalboss_att[tostring(num)]["skill" .. i]
			local name = gamedata.config.combskill[tostring(id)].name
			-- local items = gamedata.config.combskill[tostring(id)].icon
			local icon = id
			local desc = gamedata.config.combskill[tostring(id)].desc
			local effect = gamedata.config.combskill[tostring(id)]["effect-desc"]
			self.bossSkillTab[i] = {icon = id, name = name, desc = desc, effect = effect}
		end
	end
	local bossname = gamedata.config.generalanimation[tostring(animationId)].name
	self.slotdata = bossname
    local bossskeleton = CCSkeletonAnimation:create(bossname.."/"..bossname..".json",bossname.."/"..bossname..".atlas",1)
    bossskeleton:setAnimation("stand",true,0)
    bossskeleton:setScale(1.3)
    -- self.rootItems.bossNode:removeAllChildrenWithCleanup(true)
    self.rootItems.bossNode:addChild(bossskeleton)


	self:upMaterialList()
	return self.rootNode
end

----------------------------------------------------------------------------
function bossDetail.upMaterialList(self,data)  -- scrollView ```
	print("boss详情")
	-- printT(self.bossSkillTab)
    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("general_new/g_general_skill_info", nil, true, "itemIcon")
                celldict[a2] = {cellCCB = cellCCB, ccbDocumentControler = ccbDocumentControler}

                -- ui.tableviewAnimationH(self.treasureListTableView, cellCCB, self.titleCellSize.x, self.titleCellSize.y, a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            cellCCB:setScale(0.9)

  			print("说明", self.bossSkillTab[a1+1].name, self.bossSkillTab[a1+1].desc)
  			ccbDocumentControler.s_skill_name:setString(tostring(self.bossSkillTab[a1+1].name or ""))
  			ccbDocumentControler.s_skill_desc:setString(self.bossSkillTab[a1+1].desc or "")
  			ui.setNewIcon(ccbDocumentControler, {cid = self.bossSkillTab[a1+1].icon})
  			ccbDocumentControler.s_skill_lv:setVisible(false)
  			ccbDocumentControler.s_iscombskill:setVisible(false)

            ccbDocumentControler.skilliconButton:addHandleOfControlEvent(function()
            	print("点击第" .. a1+1 .. "个图标技能")
   				-- gameWindows:openWindow("dropTips",{cid = self.bossSkillTab[a1+1].icon},nil)
   				gameWindows:openWindow("bossSkillInfo", self.bossSkillTab[a1+1], nil)
			end, CCControlEventTouchUpInside)
	        ccbDocumentControler.skilliconButton:setSwallowsTouch(true)
	        ccbDocumentControler.skilliconButton:setTouchPriority(self.touchPriority-1)	  			

            ccbDocumentControler.skillshowButton:setVisible(false)
            ccbDocumentControler.skillshowButton:addHandleOfControlEvent(function()
            	print("点击第" .. a1+1 .. "个图标预览")
   				
			end, CCControlEventTouchUpInside)
	        ccbDocumentControler.skillshowButton:setSwallowsTouch(true)
	        ccbDocumentControler.skillshowButton:setTouchPriority(self.touchPriority-1)

            cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.bossSkillTab)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.treasureListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.scroll:getContentSize().width,
        viewheight = self.rootItems.scroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.scroll:addChild(self.treasureListTableView)
    self.treasureListTableView:setTouchPriority(self.touchPriority)
end

----------------------------------------------------------------------------


function bossDetail.close(self, _type) -- 退出
	self.bossSkillTab = {}
	self.treasureListTableView = nil
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
	self.rootNode = nil
	self.rootItems = nil

end

return bossDetail