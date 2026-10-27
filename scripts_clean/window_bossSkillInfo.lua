--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/14
-- Time: 下午2:54
-- To change this template use File | Settings | File Templates.
--
local bossSkillInfo = {
	rootNode = nil,
	rootItems = nil,
	bossSkillTab = {},
}

function bossSkillInfo.open(self, touchPriority, data, callback)
	self.rootNode, self.rootItems = CCBReaderLoad("general_new/skill_info", nil, true, "bossSkill")
	self.bossSkillTab = data
	self.touchPriority = touchPriority
	self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("bossSkillInfo")
	end, CCControlEventTouchUpInside)
	self.rootItems.closeButton:setSwallowsTouch(true)
	self.rootItems.closeButton:setTouchPriority(self.touchPriority)

	self.rootItems.doButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("bossSkillInfo")
	end, CCControlEventTouchUpInside)
	self.rootItems.doButton:setSwallowsTouch(true)	
	self.rootItems.doButton:setTouchPriority(self.touchPriority)	
	
	ui.setLabelString(self.rootItems.doLab, "确 定", 19)
	self.rootItems.title:setString("技能详情")

	self:onBossSkillShow()
	return self.rootNode	
end

function bossSkillInfo.onBossSkillShow(self)
	self.rootItems.xiaoguo:setString(tostring(self.bossSkillTab.effect or ""))
	self.rootItems.s_skill_name:setString(tostring(self.bossSkillTab.name or ""))
	self.rootItems.s_skill_desc:setString(self.bossSkillTab.desc or "")
	ui.setNewIcon(self.rootItems, {cid = self.bossSkillTab.icon})
	self.rootItems.s_skill_lv:setVisible(false)
  	self.rootItems.s_iscombskill:setVisible(false)
  	self.rootItems.skillshowButton:setVisible(false)
    self.rootItems.skillshowButton:addHandleOfControlEvent(function()
    	print("点击图标预览")
			
	end, CCControlEventTouchUpInside)
    self.rootItems.skillshowButton:setSwallowsTouch(true)
    self.rootItems.skillshowButton:setTouchPriority(self.touchPriority-1)	
end

function bossSkillInfo.close(self, _type) -- 退出
	self.bossSkillTab = {}
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
	self.rootNode = nil
	self.rootItems = nil

end

return bossSkillInfo