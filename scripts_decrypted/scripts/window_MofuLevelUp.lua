--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/25
-- Time: 下午7:12
-- To change this template use File | Settings | File Templates.
--


local mofulevelup = {
    rootNode = nil,
    rootItems = nil,
    chooseData = {},
    nextidtyep = false, --是否达到最大级状态
    previouslevel = 0,
}

function mofulevelup.open(self,touchPriority,data,callback)
    -- print("mofulevelup.open")
    self.touchPriority = touchPriority
    -- printT(data,"mofulevelup==")

    self.rootNode, self.rootItems = CCBReaderLoad("mofu/mofu_up", nil, true, "mofu_up")

    UIRequest({type = 10029,param = "change_gem_type",param2 = data.mofudata.type ,param3 = data.mofudata.iid,param4 = nil})
    -- UIRequest({type = 10029,param = "change_gem_type",param2 = data.listtype or self.infodata.type,param3 = data.infodata.iid,param4 = data.nolevelup})

    self:reload(data)
    return self.rootNode
end


function mofulevelup.effectAction(self)
    print("effectAction==")
    gameTouch:clickprofbytime(0.5)
    local effectNode, effectItems = CCBReaderLoad("UIEffect/mofu/mofujinjie", nil, true, "mofujinjie")
    self.rootItems.effectNode:addChild(effectNode)

    self.animationManager = getAnimationManager(effectItems)
    self.animationManager:setAnimationCompletedCallback(function()
        print("complete")
        self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
        
    end)
    self.animationManager:runAnimationsForSequenceNamed("mochongjinjie")
end

function mofulevelup.selectdataReload(self,data)
    print("selectdataReload==")
    -- printT(data)
    self.selectlistdata = nil
    self.selectlistdata = {}
    for k,v in pairs(data.data) do
        -- print(i,v)
        if gamedata.config.sigil[tostring(v.cid)]["nextid"] ~= 0 then
            table.insert(self.selectlistdata,v)
        else
            print("have max===",i)
        end
    end
    -- printT(self.selectlistdata)
end

function mofulevelup.setCanLevelUpGemsReload(self,data)
    print("setCanLevelUpGemsReload==")
    printT(data,"data=====")
    self.ison = data.ison
    self.canlevelup = data.canlevelup

end



function mofulevelup.reload(self,data)
    UIRequest({type = 1142,data = data.mofudata })
    -- print("mofulevelup====reload")
    -- printT(data)
    self.chooseData ={}
    self.data = {}
    -- self.selectlistdata = {}
    self.data = data.mofudata
    self.data.temp = ui.IDconfig(data.mofudata.cid)

    -- for i,v in ipairs(data.selectlistdata) do
    --     -- print(i,v)
    --     if gamedata.config.sigil[tostring(v.cid)]["nextid"] ~= 0 then
    --         table.insert(self.selectlistdata,v)
    --     else
    --         print("have max===",i)
    --     end
    -- end
    
    if self.previouslevel~=0 and tonumber(self.previouslevel) < tonumber(self.data.level) then
        self:effectAction()
    end
    self.previouslevel = self.data.level
    -- print("selectlistdata===")
    -- printT(self.selectlistdata)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("mofulevelup")

    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- 一键添加
    ui.setLabelString(self.rootItems.onekeyAddText, nil, 19)
    self.rootItems.onekeyAddBtn:addHandleOfControlEvent(function()
        -- 不在阵容上 or 魔符之王 周围魔符等级不够的情况
        if self.ison and self.ison ~= 0 then
        else
            -- runGamePrompt({msg = "只有被镶嵌，才能升级"})
            runGamePrompt({msg = gameConfig.strings:string_common("mofulist",9)})

            return
        end

        print("self.type===",self.data.type,self.canlevelup)
        if self.data.type == 6 and self.canlevelup == 0 then
            local levelconfig = gamedata.config.kingofmofu_lv
            
            -- local leveupname = "需要外围5个魔符到达"..levelconfig[tostring(self.data.level)]["limit_lv"].."级，才可升级"
            local leveupname = gameConfig.strings:string_common("mofulist",10)..levelconfig[tostring(self.data.level)]["limit_lv"]..gameConfig.strings:string_common("mofulist",11)
            print("leveupname==",leveupname)
            runGamePrompt({msg = leveupname})
            return
        end

        if self.data.temp.nextid == 0 then
            -- runGamePrompt({msg = "强化等级已达上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("mofulist",3)})

            return
        end
        self:onekeyaddFun()
    end, CCControlEventTouchUpInside)
    self.rootItems.onekeyAddBtn:setSwallowsTouch(true)
    self.rootItems.onekeyAddBtn:setTouchPriority(self.touchPriority)


    -- 升级
    ui.setLabelString(self.rootItems.levelUpText, nil, 19)
    self.rootItems.levelUpBtn:addHandleOfControlEvent(function()
        if self.data.temp.nextid == 0 then
            -- runGamePrompt({msg = "强化等级已达上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("mofulist",3)})
            return
        end
        if #(self.chooseData) == 0 then
            -- runGamePrompt({msg = "请选择魔符"})
            runGamePrompt({msg = gameConfig.strings:string_common("mofulist",6)})
            return
        end


        UIRequest({type = 1140,iid = self.data.iid, choose = self.chooseData, propertytype = self.data.temp.type})
    end, CCControlEventTouchUpInside)
    self.rootItems.levelUpBtn:setSwallowsTouch(true)
    self.rootItems.levelUpBtn:setTouchPriority(self.touchPriority)
    

    if self.data.temp.nextid == 0 then
        ui.addGray("CCControlButton",self.rootItems.onekeyAddBtn)
        ui.addGray("CCControlButton",self.rootItems.levelUpBtn)
    else
        ui.removeGray("CCControlButton",self.rootItems.onekeyAddBtn)
        ui.removeGray("CCControlButton",self.rootItems.levelUpBtn)
    end
    -- 头像
    
    setSpriteFrameByName(self.rootItems.titleIcon, self.data.temp.icon or "alpha")
    -- 属性设置
    ui.setLabelString(self.rootItems.nowNameLabel,self.data.temp.name,((self.data.temp.quality and self.data.temp.quality ~= 0) and self.data.temp.quality or 1)*2-1)
    
    self.rootItems.nextNameLabel:setVisible(false)

    -- 经验进度条
    if self.data.temp.nextid == 0 then
        -- ui.setLabelString(self.rootItems.expBarLabel,"已满级",13)
        ui.setLabelString(self.rootItems.expBarLabel,gameConfig.strings:string_common("mofulist",7),13)
        ui.setSpriteTextureRect2(self.rootItems.expProgressBar,0,0,844*(1),31)
    else
        -- local explablestring = "经验值："..self.data.exp.."/"..self.data.temp.exp
        local explablestring = gameConfig.strings:string_common("mofulist",12)..self.data.exp.."/"..self.data.temp.exp
        ui.setLabelString(self.rootItems.expBarLabel,explablestring,13)
        ui.setSpriteTextureRect2(self.rootItems.expProgressBar,0,0,844*(self.data.exp < self.data.temp.exp and self.data.exp/self.data.temp.exp or 1),31)
    end
    
    -- nowNameLabel
    -- nextNameLabel

    local string = ""
    local nowstring = ""
    local nextstring = ""
    for i=1,4 do
        -- print("attr===",self.data.temp["attr"..i])
        if tonumber(self.data.temp["attr"..i]) ~= 0 and self.data.temp["attr"..i] ~= "" then
            if self.data.temp["attr"..i] ~= "critical" then
                string =  gameConfig.strings:string_common("attr_type",self.data.temp["attr"..i]).."：" or {}
                nowstring = self.data.temp["init"..i]

                -- if tonumber(self.data.temp.nextid) ~= 0 then
                --     local mofuconfig = gamedata.config.sigil
                --     local nextconfig = mofuconfig[tostring(self.data.temp.nextid)]
                --     nextstring = nextconfig["init"..i]
                -- else
                --     nextstring = "Max"
                -- end
            else
                string =  gameConfig.strings:string_common("attr_type",self.data.temp["attr"..i]).."：" or {}
                nowstring = (tonumber(self.data.temp["init"..i])*100).."%"

                -- if tonumber(self.data.temp.nextid) ~= 0 then
                --     local mofuconfig = gamedata.config.sigil
                --     local nextconfig = mofuconfig[tostring(self.data.temp.nextid)]
                --     nextstring = (tonumber(nextconfig["init"..i])*100).."%" 
                -- else
                --     nextstring = "Max"
                -- end
            end

            self.rootItems["nowPropertyDescLabel"..i]:setString(string)
            self.rootItems["nowPropertyLabel"..i]:setString(nowstring)
            self.rootItems["nextPropertyLabel"..i]:setVisible(false)
            -- self.rootItems["nextPropertyLabel"..i]:setString(nextstring)

            -- print("propertynode.is.setVisible.true")
            self.rootItems["propertynode"..i]:setVisible(true)
        else
            -- print("propertynode.is.setVisible.false")
            self.rootItems["propertynode"..i]:setVisible(false)
        end
    end


    self:setShowItems()
end

-- 显示经验 和判断当经验足够升到下一级 显示下一级信息－－－judgeTemp作为判断不显示
function mofulevelup.nextReload(self,judgeTemp)
    --是否达到最大级状态
    self.nextidtyep = false
    local mofuconfig = gamedata.config.sigil
    -- self.chooseData = data  
    local allexpnum = 0
    for k,v in pairs(self.chooseData) do
        allexpnum = allexpnum + tonumber(mofuconfig[tostring(v.cid)].self_exp) + v.exp
    end

    -- 被选择的魔符兑换出的总经验（加上需要强化的魔符 自带经验
    allexpnum = allexpnum + self.data.exp
    -- print("allexpnum===",allexpnum)
    -- printT(self.infodata)
    local nextlevel = 0

    local cidnum = self.data.cid --升级后的cid（一直变化着
    local expnum = 0 --升级后余下来的经验
    for i=1,15 do
        -- print("iiii-==",i,mofuconfig[tostring(cidnum)].nextid)
        if mofuconfig[tostring(cidnum)].nextid == 0 then
            -- print("cidnum===0000",cidnum)
            expnum = allexpnum
            self.nextidtyep = true
            break
        end
        if allexpnum >= mofuconfig[tostring(cidnum)].exp then
            -- print("jianfenshu===",allexpnum,mofuconfig[tostring(cidnum)].exp)
            allexpnum = allexpnum - mofuconfig[tostring(cidnum)].exp
            cidnum = mofuconfig[tostring(cidnum)].nextid
            nextlevel = nextlevel + 1
        else
            expnum = allexpnum
            break
        end
        -- print("cidnum===",cidnum)
    end
    if judgeTemp then
        return
    end

    if nextlevel == 0 then
        self.rootItems.nextNameLabel:setVisible(false)
    else
        self.rootItems.nextNameLabel:setVisible(true)
    end

    -- print("expnum-==",expnum)
    -- 升级后魔符名字
    local nextname = mofuconfig[tostring(cidnum)].name
    ui.setLabelString(self.rootItems.nextNameLabel,nextname,((mofuconfig[tostring(cidnum)].quality and mofuconfig[tostring(cidnum)].quality ~= 0) and mofuconfig[tostring(cidnum)].quality or 1)*2-1)
    

    -- 升级后的属性
    for i=1,4 do
        -- print("attr===",self.data.temp["attr"..i])
        if tonumber(self.data.temp["attr"..i]) ~= 0 and self.data.temp["attr"..i] ~= "" then
            if self.data.temp["attr"..i] ~= "critical" then

                local nextconfig = mofuconfig[tostring(cidnum)]
                nextstring = nextconfig["init"..i]
            else

                local nextconfig = mofuconfig[tostring(cidnum)]
                nextstring = (tonumber(nextconfig["init"..i])*100).."%" 
            end

            -- self.rootItems["nowPropertyDescLabel"..i]:setString(string)
            -- self.rootItems["nowPropertyLabel"..i]:setString(nowstring)
            if nextlevel == 0 then
                self.rootItems["nextPropertyLabel"..i]:setVisible(false)
            else
                self.rootItems["nextPropertyLabel"..i]:setVisible(true)
            end
            
            self.rootItems["nextPropertyLabel"..i]:setString(nextstring)

            -- self.rootItems["propertynode"..i]:setVisible(true)
        else
            self.rootItems["nextPropertyLabel"..i]:setVisible(true)
            -- self.rootItems["propertynode"..i]:setVisible(false)
        end
    end

    
    if mofuconfig[tostring(cidnum)].nextid == 0 then
        -- ui.setLabelString(self.rootItems.expBarLabel,"已满级",13)
        ui.setLabelString(self.rootItems.expBarLabel,gameConfig.strings:string_common("mofulist",7),13)
        ui.setSpriteTextureRect2(self.rootItems.expProgressBar,0,0,844*(1),31)
    else
        -- local explablestring = "经验值："..expnum.."/"..mofuconfig[tostring(cidnum)].exp
        local explablestring = gameConfig.strings:string_common("mofulist",12)..expnum.."/"..mofuconfig[tostring(cidnum)].exp
        ui.setLabelString(self.rootItems.expBarLabel,explablestring,13)
        ui.setSpriteTextureRect2(self.rootItems.expProgressBar,0,0,844*(expnum < mofuconfig[tostring(cidnum)].exp and expnum/mofuconfig[tostring(cidnum)].exp or 1),31)
    end
end

function mofulevelup.onekeyaddFun(self)
    self.chooseData = {}
    for i,v in ipairs(self.selectlistdata) do
        if i > 8  then
            break
        end
        self:nextReload(true)
        if self.nextidtyep then
            -- print("已到最大强化等级")
            break
        else
            table.insert( self.chooseData, v )
        end
    end
    -- print("onekeyaddFu===")
    -- printT(self.chooseData)
    if #(self.chooseData) == 0 then
        -- runGamePrompt({msg = "没有满足条件的魔符"})
        runGamePrompt({msg = gameConfig.strings:string_common("mofulist",8)})
        return
    end

    self:nextReload()
    self:setShowItems()
end

-- 设置展示物品
function mofulevelup.setShowItems(self)

    for i=1,8 do
        if self.chooseData and next(self.chooseData) and i <= #self.chooseData then
            -- print("setHasItems",i)
            self:setHasItems(self.chooseData[tonumber(i)],i)
        else
            -- print("setNothingItems",i)
            self:setNothingItems(i)
        end
    end
end

function mofulevelup.setHasItems(self,data,num)
    local key_Ex
    if num == nil or num == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(num-1)
    end

    ui.setNewIconName(self.rootItems,data,num-1)


    self.rootItems["in_button"..key_Ex]:addHandleOfControlEvent(function()
        -- 不在阵容上 or 魔符之王 周围魔符等级不够的情况
        if self.ison and self.ison ~= 0 then
        else
            -- runGamePrompt({msg = "只有被镶嵌，才能升级"})
            runGamePrompt({msg = gameConfig.strings:string_common("mofulist",9)})
            return
        end
        if self.data.type == 6 and self.canlevelup == 0 then
            local levelconfig = gamedata.config.kingofmofu_lv
             
            -- local leveupname = "需要外围5个魔符到达"..levelconfig[tostring(self.data.level)]["limit_lv"].."级，才可升级"
            local leveupname = gameConfig.strings:string_common("mofulist",10)..levelconfig[tostring(self.data.level)]["limit_lv"]..gameConfig.strings:string_common("mofulist",11)
            runGamePrompt({msg = leveupname})
            return
        end


        if self.data.temp.nextid == 0 then
            -- runGamePrompt({msg = "强化等级已达上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("mofulist",3)})
            return
        end
        -- ui.setPopwindowByCid(data.cid)
        local cb = function( temdata )
            -- print("callback==")
            -- printT(temdata)
            self.chooseData = temdata
            self:setShowItems()
            self:nextReload()
        end

        gameWindows:openWindow("mofuselect",{       listdata = self.selectlistdata, 
                                                    choosedata = self.chooseData,
                                                    infodata = self.data,
                                                    selecttype = 1, 
                                                    listtype = self.data.type,
                                                    },cb)
        -- print("i..am..1",num)
    end, CCControlEventTouchUpInside)
    self.rootItems["in_button"..key_Ex]:setTouchPriority(self.touchPriority)

end

function mofulevelup.setNothingItems(self,num)
    local key_Ex
    if num == nil or num == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(num-1)
    end


    self.rootItems["in_button"..key_Ex]:addHandleOfControlEvent(function()
        -- 不在阵容上 or 魔符之王 周围魔符等级不够的情况
        if self.ison and self.ison ~= 0 then
        else
            -- runGamePrompt({msg = "只有被镶嵌，才能升级"})
            runGamePrompt({msg = gameConfig.strings:string_common("mofulist",9)})
            return
        end

        
        if self.data.type == 6 and self.canlevelup == 0 then
            local levelconfig = gamedata.config.kingofmofu_lv
             
            -- local leveupname = "需要外围5个魔符到达"..levelconfig[tostring(self.data.level)]["limit_lv"].."级，才可升级"
            local leveupname = gameConfig.strings:string_common("mofulist",10)..levelconfig[tostring(self.data.level)]["limit_lv"]..gameConfig.strings:string_common("mofulist",11)
            runGamePrompt({msg = leveupname})
            return
        end

        if self.data.temp.nextid == 0 then
            -- runGamePrompt({msg = "强化等级已达上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("mofulist",3)})
            return
        end
        -- ui.setPopwindowByCid(data.cid)
        local cb = function( temdata )
            -- print("callback2==")
            -- printT(temdata)
            self.chooseData = temdata
            self:setShowItems()
            self:nextReload()
        end

        gameWindows:openWindow("mofuselect",{       listdata = self.selectlistdata, 
                                                    choosedata = self.chooseData,
                                                    infodata = self.data,
                                                    selecttype = 1, 
                                                    listtype = self.data.type,
                                                    },cb)
        -- print("i..am..2",num)
    end, CCControlEventTouchUpInside)
    self.rootItems["in_button"..key_Ex]:setTouchPriority(self.touchPriority)

    setSpriteFrameByName(self.rootItems["in_icon"..key_Ex], "obj_add2")
    setSpriteFrameByName(self.rootItems["in_k_quality"..key_Ex], "b_iconk1")
    setSpriteFrameByName(self.rootItems["in_quality"..key_Ex], "b_iconbg1")
    self.rootItems["in_soulsprite"..key_Ex]:setVisible(false)

    self.rootItems["in_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
    self.rootItems["in_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
    

    ui.setLabelString(self.rootItems["in_num"..key_Ex],"",13)
    ui.setLabelString(self.rootItems["in_name"..key_Ex],"",13)

    
end

function mofulevelup.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil


    self.chooseData = {}
    self.nextidtyep = false
    self.previouslevel = 0
end

return mofulevelup ?L  