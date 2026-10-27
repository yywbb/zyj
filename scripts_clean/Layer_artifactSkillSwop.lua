--
-- Author: songyibo
-- Date: 2019-03-04 13:50:28
--

local artifactSkillSwop = {
    touchPriority  = -101,
    artifactData1 = nil,
    artifactData2 = nil,
}

function artifactSkillSwop.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_huhuan", nil, true, "shenqi_huhuan")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.iconNode:setPositionY(1080 + (self.toppos - 1150)/2)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifact","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self.rootItems["i_button"]:addHandleOfControlEvent(function()
        print("选择1")
        gameWindows:openWindow("artifactSelect",{showType = "checked",isShowAll = true,noInfoLook = true,data = {hasSelect = {self.artifactData2}}},function(artifact)
            if artifact then
                gameTouch:clickprofbytime(1)
                printT(artifact," 选择的神器 ")
                self.artifactData1 = artifact
                self:reload(self.artifactData1,1)
            end
        end)

    end, CCControlEventTouchUpInside)
    self.rootItems["i_button"]:setSwallowsTouch(true)
    self.rootItems["i_button"]:setTouchPriority(self.touchPriority)


    self.rootItems["i_button_1"]:addHandleOfControlEvent(function()
        print("选择2")
        gameWindows:openWindow("artifactSelect",{showType = "checked",isShowAll = true,noInfoLook = true,data = {hasSelect = {self.artifactData1}}},function(artifact)
            if artifact then
                gameTouch:clickprofbytime(1)
                printT(artifact," 选择的神器 ")
                self.artifactData2 = artifact
                self:reload(self.artifactData2,2)
            end
        end)
    end, CCControlEventTouchUpInside)
    self.rootItems["i_button_1"]:setSwallowsTouch(true)
    self.rootItems["i_button_1"]:setTouchPriority(self.touchPriority)

    self.rootItems["closeSkillInfoButton"]:addHandleOfControlEvent(function()
        self.rootItems.selectSkillNode:setVisible(false)
    end, CCControlEventTouchUpInside)
    self.rootItems["closeSkillInfoButton"]:setTouchPriority(self.touchPriority - 1)


    self:reload(nil,1)
    self:reload(nil,2)
    self:initFixedString()
end

function artifactSkillSwop.lockCallback(self,t)

    for i=1,2 do
        if self["artifactData"..i] and self["artifactData"..i].iid == t.artifactSid then
            self["artifactData"..i] = nil
            self:reload(self["artifactData"..i],i)
            break
        end
    end
end

function artifactSkillSwop.swopCallback(self,datas)

    if datas then
        self.artifactData1 = datas["1"]
        self.artifactData2 = datas["2"]
    end

    local effectFunc = function (  )
        
        for i=1,2 do
            local effectNode,effectItem = CCBReaderLoad("UIEffect/shenjihuhuan/shengjiup", nil, true, "shenjiup")
            self.rootItems["effectNode"..i]:addChild(effectNode)

            local animationManager = getAnimationManager(effectItem)
            animationManager:setAnimationCompletedCallback(function()
                effectNode:removeFromParentAndCleanup(true)
                self:reload(self["artifactData"..i],i)
            end)
            animationManager:runAnimationsForSequenceNamed("play")
        end
    end

    --触发共鸣
    local successNode,successItem = CCBReaderLoad("shenqi_new/huhuanchenggong", nil, true, "huhuanchenggong")
    self.rootItems.successNode:addChild(successNode)

    local animationManager = getAnimationManager(successItem)
    animationManager:setAnimationCompletedCallback(function()
        successNode:removeFromParentAndCleanup(true)
        effectFunc()
    end)
    animationManager:runAnimationsForSequenceNamed("success")
    gameTouch:clickprofbytime(3)
end


function artifactSkillSwop.reload(self,data,index)
	if not data then
		ui.resetNewIcon(self.rootItems,index - 1)

        ui.removeLabelStroke(self.rootItems["name"..index])
        self.rootItems["name"..index]:setString("")
		self.rootItems["addSp"..index]:setVisible(true)
		self.rootItems["score"..index]:setString("0")
		self.rootItems["attr"..index.."_1"]:setString("无")
		self.rootItems["attr"..index.."_2"]:setString("")
		self.rootItems["gongming_"..index]:setString("")

		for i=1,3 do
			ui.removeLabelStroke(self.rootItems["skill_"..index.."_"..i])
			self.rootItems["skill_"..index.."_"..i]:setString("无")
			self.rootItems["skill_"..index.."_"..i]:setColor(ccc3(106,228,108))
			self.rootItems["skillLook_"..index.."_"..i]:setVisible(false)
		end
		self.rootItems.consumeGold:setString("0")
	else
		ui.setNewIcon(self.rootItems,data,index - 1)
		self.rootItems["addSp"..index]:setVisible(false)

		local config = gamedata.config.trump[tostring(data.cid)]

        local nameStr = config.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..config.name or config.name

        if data.level1 > 0 then
        	nameStr = nameStr.."+"..data.level1
        end
        ui.setLabelString(self.rootItems["name"..index],nameStr,59)

		self.rootItems["score"..index]:setString(data.score)

		local type1 = gameConfig.strings.attr_type[config.attr1]
	    local type2 = gameConfig.strings.attr_type[config.attr2]

	    local str1 = type1.."+"..(data.attr1)*(config.attr1Type == "value" and 1 or 1)..(config.attr1Type == "value" and "" or "%")
	    local str2 = type2.."+"..(data.attr2)*(config.attr2Type == "value" and 1 or 1)..(config.attr2Type == "value" and "" or "%")
	    self.rootItems["attr"..index.."_1"]:setString(str1)
		self.rootItems["attr"..index.."_2"]:setString(str2)


        if gameWindows.windows["artifactInfo"].module.isActiveResonance(data) == 2 then
            self.rootItems["gongming_"..index]:setString(gameConfig.strings:artifactResonanceAttr(data))
        else
            self.rootItems["gongming_"..index]:setString("")
        end

		for i=1,3 do
			if data["skill"..i] > 0 then
				local skillConfig = gamedata.config.breakskill[tostring(data["skill"..i])]

				
				-- ui.setLabelString(self.rootItems["skill_"..index.."_"..i],skillConfig.name,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)
				-- self.rootItems["skill_"..index.."_"..i]:setFontSize(34)

                ui.setLabQuality(self.rootItems["skill_"..index.."_"..i],skillConfig.name,(skillConfig.quality > 0 and skillConfig.quality or 1),34)

				self.rootItems["skillLook_"..index.."_"..i]:setVisible(true)
				self.rootItems["skillLook_"..index.."_"..i]:addHandleOfControlEvent(function()
			        self.rootItems.selectSkillNode:setVisible(true)
			        
	                ui.setLabelString(self.rootItems.selectSkillDes,skillConfig.desc,(skillConfig.quality > 0 and skillConfig.quality or 1) * 2)

			    end, CCControlEventTouchUpInside)
			    self.rootItems["skillLook_"..index.."_"..i]:setSwallowsTouch(true)
			    self.rootItems["skillLook_"..index.."_"..i]:setTouchPriority(self.touchPriority)
			else
				self.rootItems["skill_"..index.."_"..i]:setString("无")
				self.rootItems["skill_"..index.."_"..i]:setColor(ccc3(106,228,108))
				ui.removeLabelStroke(self.rootItems["skill_"..index.."_"..i])
				self.rootItems["skillLook_"..index.."_"..i]:setVisible(false)
			end
		end
	end

    self:setButtonStatus()
end


function artifactSkillSwop.setButtonStatus(self)

    if self.artifactData1 and self.artifactData2 then

        local consumeGold = 0
        local skillNum = 0

        for k=1,2 do
            for i=1,3 do
                if self["artifactData"..k]["skill"..i] > 0 then
                    local skillConfig = gamedata.config.breakskill[tostring(self["artifactData"..k]["skill"..i])]

                    if skillConfig.quality > 0 then
                        consumeGold = consumeGold + tonumber(gamedata.config.trump_config["quality_swap_price_"..skillConfig.quality].value)
                    end

                    skillNum = skillNum + 1
                end
            end
        end

        if skillNum > 0 then
            consumeGold = consumeGold + tonumber(gamedata.config.trump_config["number_swap_price_"..skillNum].value)
        end

        ui.removeGray("CCControlButton",self.rootItems.doButton)
        self.rootItems.consumeGold:setString(consumeGold)
        -- 互换
        self.rootItems.doButton:addHandleOfControlEvent(function()
            
            if skillNum <= 0 then
                runGamePrompt({msg = gameConfig.strings:string_common("artifact",193)})
                return
            end

            if self.artifactData1.skill1 == self.artifactData2.skill1 and self.artifactData1.skill2 == self.artifactData2.skill2 and self.artifactData1.skill3 == self.artifactData2.skill3 then
                runGamePrompt({msg = gameConfig.strings:string_common("artifact",188)})
                return
            end

            if consumeGold > GameScene.roleinfo.gold then
                shortGold()
            else
                local executeFunc = function (  )
                    UIRequest({type = 5545,iid1 = self.artifactData1.iid,iid2 = self.artifactData2.iid,consumeGold = consumeGold})
                end
                gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("artifact",189)},executeFunc)
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority)
    else
        ui.addGray("CCControlButton",self.rootItems.doButton)
        self.rootItems.consumeGold:setString(0)
        -- 互换
        self.rootItems.doButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("artifact",187)})
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority)
    end

end

function artifactSkillSwop.initFixedString(self)
    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("artifact",185),19)
end


function artifactSkillSwop.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.artifactData1 = nil
    self.artifactData2 = nil
end

return artifactSkillSwop