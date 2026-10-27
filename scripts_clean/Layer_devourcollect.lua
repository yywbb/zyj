--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
--

local devourcollect = {
    resource = nil,
    rootNode = nil,
    rootItems = nil,

    petconfig = {},
    petsData = {},
    distanceTem = {},
}

function devourcollect.init(self,parent,toppos,param)
    -- self.petsData = param.petsData
    -- print("param===")
    -- printT(param)
    self.petFragmentData = param.petFragmentData
    self.allPetsData = param.petsData

    self.rootNode,self.rootItems = CCBReaderLoad("mochong3/mochong3_tujian.ccbi", nil, true, "mochong3")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    if self.rootItems.topnode then
        self.rootItems.topnode:setPositionY(toppos)
    end

    if self.rootItems.middlenode then
        self.rootItems.middlenode:setPositionY((toppos-160)/2+160-450)

        -- self.rootItems.middlenode:setPositionY(toppos)
    end



    ui.setLabelString(self.rootItems.aboutText,nil,21)
    self.rootItems.aboutBtn:setTouchPriority(-103)
    self.rootItems.aboutBtn:addHandleOfControlEvent(function()
        -- print("宠物图鉴说明")
        -- self:shiftNode("firstNode")
        gameWindows:openWindow("devilTuJian")
    end, CCControlEventTouchUpInside)


    for k,v in pairs(param.petsData.pets) do
        if self.petsData[tostring(v.cid)] == nil then
            self.petsData[tostring(v.cid)] = {}
        end
        self.petsData[tostring(v.cid)] = v
    end
    local configtemp = table.copy(gamedata.config.pet3_attr)
    for k,v in pairs(configtemp) do
        v.cid = tonumber(k)
        table.insert(self.petconfig,v)
    end

    local sortfunc = function( a,b )
        return a.cid < b.cid
    end

    table.sort(self.petconfig,sortfunc)

    print("configpet===")
    printT(self.petconfig)

    local tempNum = table.getTableLength(self.petconfig)-1
    print("tempNum==",template)
    for i=1,tempNum do
        local distanceNum = (i-table.getTableLength(self.petconfig)+1)*540
        print("ii====",i,distanceNum)
        table.insert(self.distanceTem,distanceNum)
        -- distanceTem = {-1620,-1080,-540,0}
    end
    printT(distanceTem,"distanceTem====")

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(-111)
    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,980))

    self.rootItems.container:setContentSize(CCSize(540*table.getTableLength(gamedata.config.pet3_attr),980))
    local index = 1
    for i,v in ipairs(self.petconfig) do
        self["scrollNode"..i], self["scrollItems"..i] = CCBReaderLoad("mochong3/cell_tujian", nil, true, "cell_tujian")
        self["scrollNode"..i]:setPosition(30 + 540*(i-1),0)
        self.rootItems.container:addChild(self["scrollNode"..i])
    end

    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    

    -- 魔宠碎片查询
    -- UIRequest({type = 1044})
    self:reload()
end


function devourcollect.reload(self,data)
    -- self:setPet()
    -- self.petdata = data
    ui.setLabelString(self.rootItems.descText1,nil,21)
    ui.setLabelString(self.rootItems.descText2,nil,26)
    
    -- 主界面
    self.rootItems.movetoLeftBtn:setTouchPriority(-103)
    self.rootItems.movetoLeftBtn:addHandleOfControlEvent(function()
        -- print("movetoLeftBtn==")

        local distanceNum = self.rootItems.scrollnode:getContentOffset().x
        -- print("distanceNum===",distanceNum)
        local gotoNum = 0
        if distanceNum == self.distanceTem[table.getTableLength(self.distanceTem)] then
            return
        end
        for i,v in ipairs(self.distanceTem) do
            if distanceNum < v then
                gotoNum = v
                break
            elseif distanceNum == v then
                gotoNum = self.distanceTem[i+1]
                break
            end
        end
        self.rootItems.scrollnode:setContentOffsetInDuration(ccp(gotoNum,0),0.2)
        -- self:shiftNode("firstNode")
        -- gameWindows:openWindow("devilSkill","explain")
    end, CCControlEventTouchUpInside)

    -- 图鉴
    self.rootItems.movetoRightBtn:setTouchPriority(-103)
    self.rootItems.movetoRightBtn:addHandleOfControlEvent(function()
        -- print("movetoRightBtn===")

        local distanceNum = self.rootItems.scrollnode:getContentOffset().x
        -- print("distanceNum===",distanceNum)
        if distanceNum == self.distanceTem[1] then
            return
        end
        local gotoNum = 0
        for i,v in ipairs(self.distanceTem) do
            if distanceNum > v then
                gotoNum = v
            elseif distanceNum == v then
                gotoNum = self.distanceTem[i-1]
                break
            end
        end
        self.rootItems.scrollnode:setContentOffsetInDuration(ccp(gotoNum,0),0.2)
        -- self:shiftNode("firstNode")
        -- gameWindows:openWindow("devilSkill","explain")
    end, CCControlEventTouchUpInside)

    self.rootItems.button_back:setTouchPriority(-103)
    self.rootItems.button_back:addHandleOfControlEvent(function()
        -- print("背包")
        -- self:shiftNode("mainNode")
        GameScene:shiftLayer("devil","up")
    end, CCControlEventTouchUpInside)

    self:setPetProperty()
end

function devourcollect.setPetProperty(self)
    -- print("setPetProperty")
    -- printT(self.petconfig)
    for i,v in ipairs(self.petconfig) do
        -- print("item====")
        -- printT(v)
        local upconfig = gamedata.config.pet3_illustrated and gamedata.config.pet3_illustrated[tostring(v.cid)] or {}
        local level = 0
        local labelfont = 13
        local hasNum = 0
        if self.petsData[tostring(v.cid)] then
            level = self.petsData[tostring(v.cid)].level
            self["scrollItems"..i].nogetMark:setVisible(false)
            hasNum = 1
        else
            labelfont = 30
            self["scrollItems"..i].nogetMark:setVisible(true)
        end

        local itemconfig = v[tostring(level)]
        local basicconfig = v[tostring(0)]
        
        if itemconfig.quality >= 7 then
            ui.setLabelString(self["scrollItems"..i].petnameLabel,itemconfig.name,213)
        else
            ui.setLabelString(self["scrollItems"..i].petnameLabel,itemconfig.name,((itemconfig.quality and itemconfig.quality ~= 0) and itemconfig.quality or 1)*2-1)
        end

        ui.setLabelString(self["scrollItems"..i].styleLabel,itemconfig.type,21)

        ui.setLabelString(self["scrollItems"..i].propertynameLevel,"等级:",labelfont)
        ui.setLabelString(self["scrollItems"..i].propertyNumLevel,self.petsData[tostring(v.cid)] and self.petsData[tostring(v.cid)].collectlevel or 1,labelfont)


        self["scrollItems"..i].gotogetBtn:setTouchPriority(-103)
        self["scrollItems"..i].gotogetBtn:addHandleOfControlEvent(function()
            -- print("gotogetBtn===")
            -- self:shiftNode("firstNode")
            -- gameWindows:openWindow("devilSkill","explain")
            -- print("gotoscroll===",gamedata.config.pet3_attr[tostring(v.cid)][tostring(0)]["debris"])


            gameWindows:openWindow("dropTips",{cid=basicconfig.debris,num=(self.petFragmentData[tostring(gamedata.config.pet3_attr[tostring(v.cid)][tostring(0)]["debris"])] and self.petFragmentData[tostring(gamedata.config.pet3_attr[tostring(v.cid)][tostring(0)]["debris"])]["num"] or 0)},nil)
        end, CCControlEventTouchUpInside)

        local upnum1,upnum2,upnum3 = 0,0,0
        if hasNum == 1 then
            upnum1 = upconfig[tostring(self.petsData[tostring(v.cid)].collectlevel)]["attr1"]
            upnum2 = upconfig[tostring(self.petsData[tostring(v.cid)].collectlevel)]["attr2"]
            upnum3 = upconfig[tostring(self.petsData[tostring(v.cid)].collectlevel)]["attr3"]
        end

        ui.setLabelString(self["scrollItems"..i].propertynameLabel1,(gameConfig.strings:string_common("attr_type",basicconfig.attr1)..":"),labelfont)
        local attrnum = 0
        if basicconfig.method1 == "value" then
            attrnum = basicconfig.init1 + upnum1
        else
            attrnum = (tonumber(basicconfig.init1 + upnum1)*100).."%"
        end
        ui.setLabelString(self["scrollItems"..i].propertyNumLabel1,attrnum,labelfont)
        -- self["scrollItems"..i].propertynameLabel1
        -- self["scrollItems"..i].propertyNumLabel1

        ui.setLabelString(self["scrollItems"..i].propertynameLabel2,(gameConfig.strings:string_common("attr_type",basicconfig.attr2)..":"),labelfont)
        local attrnum = 0
        if basicconfig.method2 == "value" then
            attrnum = basicconfig.init2 + upnum2
        else
            attrnum = (tonumber(basicconfig.init2 + upnum2)*100).."%"
        end
        ui.setLabelString(self["scrollItems"..i].propertyNumLabel2,attrnum,labelfont)
        -- self["scrollItems"..i].propertynameLabel2
        -- self["scrollItems"..i].propertyNumLabel2

        ui.setLabelString(self["scrollItems"..i].propertynameLabel3,(gameConfig.strings:string_common("attr_type",basicconfig.attr3)..":"),labelfont)
        local attrnum = 0
        if basicconfig.method3 == "value" then
            attrnum = basicconfig.init3 + upnum3
        else
            attrnum = (tonumber(basicconfig.init3 + upnum3)*100).."%"
        end
        ui.setLabelString(self["scrollItems"..i].propertyNumLabel3,attrnum,labelfont)
        -- self["scrollItems"..i].propertynameLabel3
        -- self["scrollItems"..i].propertyNumLabel3
        printT(itemconfig,"itemconfig===")
        printT(gamedata.config.generalanimation[tostring(itemconfig.animationid)],"generalanimation====")
        print("name===",gamedata.config.generalanimation[tostring(itemconfig.animationid)].name)
        local mochong = gamedata.config.generalanimation[tostring(itemconfig.animationid)].name or "mowang_1"
        self["scrollItems"..i].petstandNode:removeAllChildrenWithCleanup(true)
        self.Gneral1 = nil
        self.Gneral1 = CCSkeletonAnimation:create(mochong.."/"..mochong..".json",mochong.."/"..mochong..".atlas",1)
        if self.Gneral1 then
            self.Gneral1:setAnimation("stand",true,0)
            self.Gneral1:setScale(1.8*(basicconfig.scale or 1))
            self.Gneral1:setPosition(0,0)
            self["scrollItems"..i].petstandNode:addChild(self.Gneral1)
        end
        if hasNum == 0 then
            ui.addGray("CCNode",self.Gneral1)
            if self["scrollItems"..i].upNode then
                self["scrollItems"..i].upNode:setVisible(false)
            end
        else
            ui.removeGray("CCNode",self.Gneral1)
            if self["scrollItems"..i].upNode then
                self["scrollItems"..i].upNode:setVisible(false)
            end
        end

        --
        if self["scrollItems"..i].upLab then
            ui.setLabelString(self["scrollItems"..i].upLab,nil,18)
        end
        --
        if self["scrollItems"..i].upButton then
            self["scrollItems"..i].upButton:setTouchPriority(-103)
            self["scrollItems"..i].upButton:addHandleOfControlEvent(function()
            print("upButton")
            GameScene:shiftLayer("devourcollectup",nil,{petData = table.copy(self.petsData[tostring(v.cid)]), petFragmentData = table.copy(self.petFragmentData),allPetsData = self.allPetsData})
            end, CCControlEventTouchUpInside)
        end

        -- self["scrollItems"..i].petstandNode:addChild()
    end
end

function devourcollect.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootItems = nil
    self.rootNode = nil

    self.petconfig = {}
    self.petsData = {}
end


return devourcollect