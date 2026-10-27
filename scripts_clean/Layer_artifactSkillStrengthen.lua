--
-- Author: songyibo
-- Date: 2019-03-04 13:50:28
--

local artifactSkillStrengthen = {
    touchPriority  = -101,
    artifactData1 = nil,
    artifactData2 = nil,
    selectcid = nil,
    selectiid = nil,
    selectAllListData = nil,
}

function artifactSkillStrengthen.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_huhuan_stren", nil, true, "shenqi_huhuan_stren")
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
        -- self:selcetbyType(1)
        print("selectcid",self.selectcid)
         gameWindows:openWindow("artifactSelect",{showType = "checked",isShowAll = true,noInfoLook = true,data = {hasSelect = hasSelects, selectcid =  self.selectcid}},function(artifact)
            if artifact then
                gameTouch:clickprofbytime(1)
                printT(artifact," 选择的神器 ")
                if artifact.isLockState == 1 then
                    runGamePrompt({msg = "神器已被锁定"})
                    if artifact.iid == self.selectiid then
                        self.selectcid = nil
                        self.selectiid = nil
                        self.artifactData1 = nil
                        self.artifactData2 = nil
                        self:reload(nil,1)
                        self:reload(nil,2)
                    end    
                    return
                end    
                self.selectcid = artifact.cid
                self.selectiid = artifact.iid
                self.artifactData1 = artifact
                self.artifactData2 = nil
                self:reload(self.artifactData1,1)
                self:reload(nil,2)

                GameScene:addUpdate(10032)
                if GameScene:checkUpdate(10032) then
                end
            end
        end)
       

    end, CCControlEventTouchUpInside)
    self.rootItems["i_button"]:setSwallowsTouch(true)
    self.rootItems["i_button"]:setTouchPriority(self.touchPriority)


    self.rootItems["i_button_1"]:addHandleOfControlEvent(function()
        print("选择2")
        print("selectcid",self.selectcid)

       
       if self.selectcid ~= nil then
            local selecttable = {}
            if self.artifactData2 then
                table.insert(selecttable,self.artifactData2)
            end
            gameWindows:openWindow("onceAddStrengthen",{num = 1,data = self.selectAllListData,selectList = selecttable, isstreng = 1},function(artifact)
                    if artifact then
                        gameTouch:clickprofbytime(1)   
                        local artifact1 = artifact[1] or nil
                        if artifact1 and artifact1.isLockState == 1 then
                            runGamePrompt({msg = "神器已被锁定"})
                            if self.artifactData2 and artifact1.iid == self.artifactData2.iid then
                                self.artifactData2 = nil
                                self:reload(nil,2)
                            end    
                            return
                        end    
                        if artifact1 ~=nil  and next(artifact1)~=nil then
                            printT(artifact1," 选择的神器!! 1")
                            self.artifactData2 = artifact1
                            if  not self:checkedisSame()  then
                                -- self.selectcid = artifact1.cid
                                -- self.selectiid = artifact1.iid
                                self:reload(self.artifactData2,2)
                                GameScene:addUpdate(10032)
                                if GameScene:checkUpdate(10032) then
                                end
                            else
                                runGamePrompt({msg = gameConfig.strings:string_common("artifact",196)})   
                                self.artifactData2 = nil
                                self:reload(nil,2)
                            end  
                        else    
                            self.artifactData2 = nil
                            self:reload(nil,2)
                        end    
                        
                    end
            end)
        else
           runGamePrompt({msg = gameConfig.strings:string_common("artifact",197)})    
       end 

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

-- 设置神器数据
function artifactSkillStrengthen.setArtifactData(self,t)
    -- self:orderArtifactData(t.data)
    -- printT(self.artifactData,"  artifactStrengthen.setArtifactData  ")
    if self.selectcid then
        local listData = {}
        for k,v in pairs(t.data) do
            --and not v.generalcid
            if v.isChecked == 1 and self.selectiid ~= v.iid then
                local config1 = gamedata.config:getConfigByName("trump")[tostring(self.selectcid)]
                local config2 = gamedata.config:getConfigByName("trump")[tostring(v.cid)]

                --相同神器 金光对金光
                if config1.goldTrump == config2.goldTrump then
                    if (v.cid == self.selectcid) or (v.cid == config1.consumption) then
                        v.consumeStatus = self:consumeStatus(v)
                        table.insert(listData,v)
                    end
                end
            end
        end

        self.selectAllListData = listData
        gameWindows.windows["artifactSelect"].module.consumeSort(self.selectAllListData,1)
    end
end



--0 可消耗 1 锁定 2 强化 3 点化 4 镶嵌有宝石 5 宝石孔>1
function artifactSkillStrengthen.consumeStatus(artifact)

    if artifact.isLockState == 1 then
        return 1
    end

    return 0
end



function artifactSkillStrengthen.lockCallback(self,t)

    for i=1,2 do
        if self["artifactData"..i] and self["artifactData"..i].iid == t.artifactSid then
            if t.artifactSid == self.selectiid  then
                 self["artifactData1"] = nil
                 self["artifactData2"] = nil
                 self.selectcid = nil
                 self.selectiid = nil
                 self:reload(self["artifactData1"],1)
                 self:reload(self["artifactData2"],2)
                 break
            else
                self["artifactData"..i] = nil
                self:reload(self["artifactData"..i],i)
                break
            end    
           
        end
    end
end

function artifactSkillStrengthen.swopCallback(self,datas)

    if datas then
        self.artifactData1 = datas["1"]
        self.artifactData2 = datas["2"]
        self.selectcid = self.artifactData1.cid
        self.selectiid = self.artifactData1.iid
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

function artifactSkillStrengthen.checkedisSame(self)

    local islevelok = true
    local issuccessok = true
    if self.artifactData1 and self.artifactData2  then

       
        -- if self.artifactData1.levelAttack ~= self.artifactData2.levelAttack then
        --     return false
        -- elseif self.artifactData1.levelDef ~= self.artifactData2.levelDef then  
        --     return false
        -- elseif self.artifactData1.levelHP ~= self.artifactData2.levelHP then    
        --     return false
        if self.artifactData1.level1 == self.artifactData2.level1 then 
             print("checkedisSame 1") 
             islevelok = false
        end  
         
            
        local artifactConfig = gamedata.config:getConfigByName("trump")[tostring(self.artifactData1.cid)]
        local nextCof = gamedata.config:getConfigByName("trump_strengthen")[tostring(artifactConfig.type)][tostring(self.artifactData1.level1+1)]
        if artifactConfig.goldTrump == 1 then
            nextCof = gamedata.config:getConfigByName("trump_Godstrengthen")[tostring(artifactConfig.type)][tostring(self.artifactData1.level1+1)]
        end

        local artifactConfig2 = gamedata.config:getConfigByName("trump")[tostring(self.artifactData2.cid)]
        local nextCof2 = gamedata.config:getConfigByName("trump_strengthen")[tostring(artifactConfig2.type)][tostring(self.artifactData2.level1+1)]
        if artifactConfig2.goldTrump == 1 then
            nextCof2 = gamedata.config:getConfigByName("trump_Godstrengthen")[tostring(artifactConfig2.type)][tostring(self.artifactData2.level1+1)]
        end

        if nextCof and nextCof2 then
             print("checkedisSame 22") 
            local persert1 = math.min(nextCof.basics_success/10+self.artifactData1.levelProbs/10,100) 
            local persert2 = math.min(nextCof2.basics_success/10+self.artifactData2.levelProbs/10,100)

             print("checkedisSame persert1"..persert1) 
             print("checkedisSame persert2"..persert2) 

            if persert1 == persert2 then
                 print("checkedisSame 2") 
                issuccessok = false
            end  
        else
          
          if not nextCof and not nextCof2 then
             print("checkedisSame 33") 
             print("checkedisSame 3") 
             issuccessok = false
          end  
        end  


         print("checkedisSame 4")
        if issuccessok==true or islevelok==true then
             return false    
        else
             return true    
        end    

    else
          return true
    end  
end

function artifactSkillStrengthen.reload(self,data,index)
	if not data then
		ui.resetNewIcon(self.rootItems,index - 1)

        ui.removeLabelStroke(self.rootItems["name"..index])
        self.rootItems["name"..index]:setString("")
		self.rootItems["addSp"..index]:setVisible(true)
		self.rootItems["score"..index]:setString("0")
		self.rootItems["attr"..index.."_1"]:setString("无")
		self.rootItems["attr"..index.."_2"]:setString("")
        self.rootItems["skill_"..index.."_1"]:setString("无")
        self.rootItems["skill_"..index.."_2"]:setString("")
        self.rootItems["skill_"..index.."_3"]:setString("")
        self.rootItems["success_num"..index]:setString("无")

		self.rootItems.consumeGold:setString("0")
	else
        
        local isattrSame = false
        --判断2个神器是否属性一致,如果一直提示一下
		ui.setNewIcon(self.rootItems,data,index - 1)
		self.rootItems["addSp"..index]:setVisible(false)

		local config = gamedata.config:getConfigByName("trump")[tostring(data.cid)]

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

        self.rootItems["skill_"..index.."_1"]:setString(gameConfig.strings:string_common("artifact",198)..tostring(data.levelAttack).."%")
        self.rootItems["skill_"..index.."_2"]:setString(gameConfig.strings:string_common("artifact",199)..tostring(data.levelDef).."%")
        self.rootItems["skill_"..index.."_3"]:setString(gameConfig.strings:string_common("artifact",200)..tostring(data.levelHP).."%")
        
        local artifactConfig = gamedata.config:getConfigByName("trump")[tostring(data.cid)]
        local nextCof = gamedata.config:getConfigByName("trump_strengthen")[tostring(artifactConfig.type)][tostring(data.level1+1)]

        if artifactConfig.goldTrump == 1 then
            nextCof = gamedata.config:getConfigByName("trump_Godstrengthen")[tostring(artifactConfig.type)][tostring(data.level1+1)]
        end

        if nextCof then
            -- local artifactConfig = gamedata.config:getConfigByName("trump")[tostring(data.cid)]
            -- local nextCof = gamedata.config:getConfigByName("trump_strengthen")[tostring(artifactConfig.type)][tostring(data.level1)]
            self.rootItems["success_num"..index]:setString(math.min(nextCof.basics_success/10+data.levelProbs/10,100).."%")
        else
            self.rootItems["success_num"..index]:setString("0%")
        end    

	end

    self:setButtonStatus()
end


function artifactSkillStrengthen.setButtonStatus(self)



    if self.artifactData1 and self.artifactData2 then

        local consumeGold = 0
        local finallevel = 0
        local level1 = self.artifactData1.level1 or 0
        local level2 = self.artifactData2.level1 or 0
        if level1>level2 then 
            finallevel = level1 
        else 
            finallevel = level2 
        end
        print(finallevel,"finallevel")
        local config = gamedata.config:getConfigByName("trump_transfer")[tostring(finallevel)]
        if config and config.price then
            consumeGold =  config.price
            ui.removeGray("CCControlButton",self.rootItems.doButton)
            self.rootItems.consumeGold:setString(consumeGold)
            consumeGold = tonumber(consumeGold)

            -- 互换
            self.rootItems.doButton:addHandleOfControlEvent(function()  
                if consumeGold > GameScene.roleinfo.gold then
                    shortGold()
                else
                    local executeFunc = function (  )
                        UIRequest({type = 5546,iid1 = self.artifactData1.iid,iid2 = self.artifactData2.iid,consumeGold = consumeGold or 0})
                    end
                    gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("artifact",195)},executeFunc)
                end
            end, CCControlEventTouchUpInside)
            self.rootItems.doButton:setSwallowsTouch(true)
            self.rootItems.doButton:setTouchPriority(self.touchPriority)
        end   

    
         

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

function artifactSkillStrengthen.initFixedString(self)
    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("artifact",185),19)
end


function artifactSkillStrengthen.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.artifactData1 = nil
    self.artifactData2 = nil
    self.selectcid = nil
    self.selectiid = nil
    self.selectAllListData = nil
end

return artifactSkillStrengthen