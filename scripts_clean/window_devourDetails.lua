--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local devourDetails = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

}


function devourDetails.open(self,touchPriority,data,callback)

    self.root = CCNode:create()
    self.touchPriority = touchPriority


    if data.index == "details" then
        print("details===")
        self.petdata = data.data
        self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochong_info", nil, true, "mochong_info")
        self:detailsReload()

    elseif data.index == "reset" then
        print("reset===")
        self.petskill = data.data
        self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochongskill_chongzhi", nil, true, "mochongskill_chongzhi")
        self:resetReload()
    elseif data.index == "info" then
        print("info===")
        self.petinfodata = data.data
        self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochong_info", nil, true, "mochong_info")
        self:infoReload()
    elseif data.index == "score" then
        self.scoredata = data.data
        self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochongskill_scorerule", nil, true, "mochong_score")
        self:scoreReload()
    elseif data.index == "stageinfo" then
        print("stageinfo===")
        self.petstagedata = table.copy(data.data)

        local nowlevel = self.petstagedata.level
        local config = gamedata.config.pet3_attr[tostring(self.petstagedata.cid)] or {}
        printT(config,"jkp-config")
        self.showdata = {}
        for k,v in pairs(config) do
            v.stagelevel = tonumber(k)
            if self.petstagedata.level == tonumber(k) then
                table.insert(self.showdata,v)
            elseif v.display ~= 0 and v.display ~= nil and v.display ~= "" then
                table.insert(self.showdata,v)
            end
        end
        local sortfunction = function ( a,b )
            return a.stagelevel < b.stagelevel
        end
        table.sort( self.showdata, sortfunction )
        
        self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochong_stageinfo", nil, true, "mochong_info")
        self:stagedetailsReload()
    end
    
    self.root:addChild(self.rootNode)
    return self.root
end

function devourDetails.scoreReload(self)
    local skillpointconfig = gamedata.config.pet3_skillpoints
    self.rootItems.tishiLabel:setString((skillpointconfig[tostring(21)] and skillpointconfig[tostring(21)]["desc"] or ""))

    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("devourDetails")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function devourDetails.detailsReload(self)
    --print("i...am...detailsReload...")
    local iidnum = self.petdata.iid
    local nowcid = self.petdata.pets[tostring(self.petdata.iid)].cid
    local nowlevel = self.petdata.pets[tostring(self.petdata.iid)].level

    local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(self.petdata.iid)].cid)] or {}


    if self.rootItems.mochongNode then
        local mochong = gamedata.config.generalanimation[tostring(config[tostring(nowlevel)].animationid)].name or "mowang_1"
        self.rootItems.mochongNode:removeAllChildrenWithCleanup(true)
        self.Gneral1 = nil
        self.Gneral1 = CCSkeletonAnimation:create(mochong.."/"..mochong..".json",mochong.."/"..mochong..".atlas",1)
        if self.Gneral1 then
            self.Gneral1:setAnimation("stand",true,0)
            self.Gneral1:setScale(1.8*(config[tostring(nowlevel)].scale or 1))
            self.Gneral1:setPosition(0,0)
            self.rootItems.mochongNode:addChild(self.Gneral1)

        end
    end

    local moquality = (config[tostring(nowlevel)].quality and config[tostring(nowlevel)].quality ~= 0) and config[tostring(nowlevel)].quality or 1
    ui.setLabelString(self.rootItems.mochongnameLabel,config[tostring(nowlevel)].name,moquality>=7 and 213 or moquality*2-1)


    local talantskillconfig = gamedata.config.pet3_talentskill

    self.rootItems.talantNumLabel:setString(talantskillconfig[tostring(config[tostring(nowlevel)].talentskill)].number)


    local skillconfig = gamedata.config.combskill or {}

    local skillid = config[tostring(nowlevel)].skillid

    -- print("skillid===",skillid)
    -- printT(skillconfig[tostring(skillid)])

    -- print(skillconfig[tostring(config[tostring(nowlevel)].skillid)]["name"])
    if config[tostring(nowlevel)].skillid and config[tostring(nowlevel)].skillid > 0 then
        if skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality >= 7 then
            ui.setLabelString(self.rootItems.activeSkillNameLabel,skillconfig[tostring(config[tostring(nowlevel)].skillid)]["name"]..": ",213)
        else
            ui.setLabelString(self.rootItems.activeSkillNameLabel,skillconfig[tostring(config[tostring(nowlevel)].skillid)]["name"]..": ",((skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality and skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality ~= 0) and skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality or 1)*2)
        end
        
        if self.rootItems.skillshowButton then
            self.rootItems.activeSkillDescLabel:setString(skillconfig[tostring(config[tostring(nowlevel)].skillid)]["effect-desc"])    
        else    
            self.rootItems.activeSkillDescLabel:setString("                 "..skillconfig[tostring(config[tostring(nowlevel)].skillid)]["effect-desc"])
        end
        -- 主页面设置 主动技能icon
        local stringname = skillconfig[tostring(config[tostring(nowlevel)].skillid)].icon
        -- print("stringname==",stringname)
        setSpriteFrameByName(self.rootItems.i_icon, stringname)
        self.rootItems.i_soulsprite:setVisible(false)

        if self.rootItems.skillshowButton then
            print("skillid = ", skillid)
            self.rootItems.skillshowButton:setVisible((skillid>=12996 and skillid<=12998) or (skillid>=14031 and skillid<=14033))
            self.rootItems.skillshowButton:addHandleOfControlEvent(function()
                if (skillid>=12996 and skillid<=12998) or (skillid>=14031 and skillid<=14033) then
                    ui.skillView(skillid)
                end
            end, CCControlEventTouchUpInside)
            self.rootItems.skillshowButton:setSwallowsTouch(true)
            self.rootItems.skillshowButton:setTouchPriority(self.touchPriority)
        end
    end

    
    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("devourDetails")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab1, "更换魔宠", 19)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        gameWindows:closeWindow("devourDetails")
        -- GameScene:shiftLayer("devourList","up",self.petdata)
        gameWindows:openWindow("devourSelect",{data = self.petdata})

        -- gameWindows:closeWindow("favoriteList")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)


    ui.setLabelString(self.rootItems.doLab2, "进阶", 19)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameWindows:closeWindow("devourDetails")

        if GameScene.layers["devil"].show then
            GameScene.layers["devil"].module:toPage({page = "jinjie"})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.title,"魔宠详情",28)

    -- print("comfirmnode=====")
    self.rootItems.comfirmNode:setVisible(false)
    self.rootItems.comfirmNode:setPositionX(9999)

    --
    self:plusAttr(nowcid,nowlevel)


end


-- 进阶预览
function devourDetails.stagedetailsReload(self)
    -- print("i...am...detailsReload...")

        local nowcid = self.petstagedata.cid
        local nowlevel = self.petstagedata.level

        local config = gamedata.config.pet3_attr[tostring(self.petstagedata.cid)] or {}
        -- config[tostring(nowlevel)] = config[tostring(nowlevel)]


    -- if self.rootItems.mochongNode then
    --     local mochong = gamedata.config.generalanimation[tostring(config[tostring(nowlevel)].animationid)].name or "mowang_1"
    --     self.rootItems.mochongNode:removeAllChildrenWithCleanup(true)
    --     self.Gneral1 = nil
    --     self.Gneral1 = CCSkeletonAnimation:create(mochong.."/"..mochong..".json",mochong.."/"..mochong..".atlas",1)
    --     if self.Gneral1 then
    --         self.Gneral1:setAnimation("stand",true,0)
    --         self.Gneral1:setScale(1.8*(config[tostring(nowlevel)].scale or 1))
    --         self.Gneral1:setPosition(0,0)
    --         self.rootItems.mochongNode:addChild(self.Gneral1)

    --     end
    -- end

    local moquality = (config[tostring(nowlevel)].quality and config[tostring(nowlevel)].quality ~= 0) and config[tostring(nowlevel)].quality or 1
    ui.setLabelString(self.rootItems.mochongnameLabel,config[tostring(nowlevel)].name, moquality>=7 and 213 or moquality*2-1)


    local talantskillconfig = gamedata.config.pet3_talentskill

    self.rootItems.talantNumLabel:setString(talantskillconfig[tostring(config[tostring(nowlevel)].talentskill)].number)


    local skillconfig = gamedata.config.combskill or {}

    local skillid = config[tostring(nowlevel)].skillid

    -- print("skillid===",skillid)
    -- printT(skillconfig[tostring(skillid)])

    -- print(skillconfig[tostring(config[tostring(nowlevel)].skillid)]["name"])
    if config[tostring(nowlevel)].skillid and config[tostring(nowlevel)].skillid > 0 then
        if skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality >= 7 then
            ui.setLabelString(self.rootItems.activeSkillNameLabel,skillconfig[tostring(config[tostring(nowlevel)].skillid)]["name"]..": ",213)
        else
            ui.setLabelString(self.rootItems.activeSkillNameLabel,skillconfig[tostring(config[tostring(nowlevel)].skillid)]["name"]..": ",((skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality and skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality ~= 0) and skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality or 1)*2)
        end
        
        if self.rootItems.skillshowButton then
            self.rootItems.activeSkillDescLabel:setString(skillconfig[tostring(config[tostring(nowlevel)].skillid)]["effect-desc"])
        else    
            self.rootItems.activeSkillDescLabel:setString("                 "..skillconfig[tostring(config[tostring(nowlevel)].skillid)]["effect-desc"])
        end
        -- 主页面设置 主动技能icon
        local stringname = skillconfig[tostring(config[tostring(nowlevel)].skillid)].icon
        -- print("stringname==",stringname)
        setSpriteFrameByName(self.rootItems.i_icon, stringname)
        self.rootItems.i_soulsprite:setVisible(false)

        if self.rootItems.skillshowButton then
            self.rootItems.skillshowButton:setVisible((skillid>=12996 and skillid<=12998) or (skillid>=14031 and skillid<=14033))
            self.rootItems.skillshowButton:addHandleOfControlEvent(function()
                if (skillid>=12996 and skillid<=12998) or (skillid>=14031 and skillid<=14033) then
                    ui.skillView(skillid)
                end
            end, CCControlEventTouchUpInside)
            self.rootItems.skillshowButton:setSwallowsTouch(true)
            self.rootItems.skillshowButton:setTouchPriority(self.touchPriority)
        end

    end

    
    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("devourDetails")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.doLab1, "更换魔宠", 19)
    -- self.rootItems.doButton1:addHandleOfControlEvent(function()
    --     gameWindows:closeWindow("devourDetails")
    --     -- GameScene:shiftLayer("devourList","up",self.petdata)
    --     gameWindows:openWindow("devourSelect",{data = self.petdata})

    --     -- gameWindows:closeWindow("favoriteList")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.doButton1:setSwallowsTouch(true)
    -- self.rootItems.doButton1:setTouchPriority(self.touchPriority)


    -- ui.setLabelString(self.rootItems.doLab2, "进阶", 19)
    -- self.rootItems.doButton2:addHandleOfControlEvent(function()
    --     gameWindows:closeWindow("devourDetails")

    --     if GameScene.layers["devil"].show then
    --         GameScene.layers["devil"].module:shiftNode("advanceNode")
    --     end
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.doButton2:setSwallowsTouch(true)
    -- self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    --
    if self.rootItems.leftButton then
        self.rootItems.leftButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            self:setActionRightreload()
        end, CCControlEventTouchUpInside)
        --self.rootItems.leftButton:setSwallowsTouch(true)
        self.rootItems.leftButton:setTouchPriority(self.touchPriority)
    end
    --
    if self.rootItems.rightButton then
        self.rootItems.rightButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            self:setActionLeftreload()
        end, CCControlEventTouchUpInside)
        --self.rootItems.rightButton:setSwallowsTouch(true)
        self.rootItems.rightButton:setTouchPriority(self.touchPriority)
    end
    --

    self.rootItems.doLab1:setVisible(false)
    self.rootItems.doButton1:setVisible(false)
    self.rootItems.doLab2:setVisible(false)
    self.rootItems.doButton2:setVisible(false)


    ui.setLabelString(self.rootItems.title,"进阶预览",28)


    ui.setLabelString(self.rootItems.comfirmText, nil, 19)
    self.rootItems.comfirmBtn:addHandleOfControlEvent(function()
        print("comfirmBtn===")
        gameWindows:closeWindow("devourDetails")
       
    end, CCControlEventTouchUpInside)
    self.rootItems.comfirmBtn:setSwallowsTouch(true)
    self.rootItems.comfirmBtn:setTouchPriority(self.touchPriority)

    -- print("comfirmnode=====")
    -- self.rootItems.comfirmNode:setVisible(false)
    -- self.rootItems.comfirmNode:setPositionX(9999)
    self:touchLayerSet()

    --
    self:plusAttr(nowcid,nowlevel)

end

function devourDetails.touchLayerSet(self)
    self.listdata = {}

    self.standdata = {{cid=0,level=0},{cid=0,level=0},{cid=0,level=0}}

    nowlevel = self.petstagedata.level
    local config = gamedata.config.pet3_attr[tostring(self.petstagedata.cid)] or {}
    -- print("CONFIG===")
    -- printT(config)


    for i,v in ipairs(self.showdata) do
        -- print("iii,stagelevel===",i,config[tostring(nowlevel)].stagelevel,v.stagelevel)
        if tonumber(config[tostring(nowlevel)].stagelevel) == tonumber(v.stagelevel) then
            -- print("set11111",i,config[tostring(nowlevel)].stagelevel,v.stagelevel)
            if self.showdata[tonumber(i-1)] then
                self.standdata[1]["cid"] = self.petstagedata.cid
                self.standdata[1]["level"] = self.showdata[tonumber(i-1)].stagelevel
            end
            self.standdata[2]["cid"] = self.petstagedata.cid
            self.standdata[2]["level"] = self.showdata[tonumber(i)].stagelevel

            -- self.standdata[2] = config[tostring(3*(i-1))]

            if self.showdata[tonumber(i+1)] then
                -- self.standdata[3] = config[tostring(3*(i))]
                self.standdata[3]["cid"] = self.petstagedata.cid
                self.standdata[3]["level"] = self.showdata[tonumber(i+1)].stagelevel
            end
            break
        end
    end

    -- print("test000")
    -- printT(self.standdata)

    self.rootItems.markLeft:setVisible(true)
    self.rootItems.markRight:setVisible(true)
    
    if self.standdata[1]["cid"] == 0 then
        self.rootItems.markLeft:setVisible(false)
    end

    if self.standdata[3]["cid"] == 0 then
        self.rootItems.markRight:setVisible(false)
    end

    self.rootItems.mochongNode:removeAllChildrenWithCleanup(true)
    self.stepGneral1 = nil
    self.stepGneral2 = nil
    self.stepGneral3 = nil

    -- local mochong = gamedata.config.generalanimation[tostring(config[tostring(nowlevel)].animationid)].name or "mowang_1"

    if self.standdata[1]["cid"] ~= 0 then
        local generalName = gamedata.config.generalanimation[tostring(config[tostring(self.standdata[1]["level"])].animationid)].name
        self.stepGneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self.stepGneral1:setAnimation("stand",true,0)
        self.stepGneral1:setScale(1.8*(config[tostring(self.standdata[1]["level"])].scale or 1))
        self.stepGneral1:setPosition(-1080,0)
        self.rootItems.mochongNode:addChild(self.stepGneral1)
    end

    
    if self.standdata[2]["cid"] ~= 0 then
        local generalName = gamedata.config.generalanimation[tostring(config[tostring(self.standdata[2]["level"])].animationid)].name
        self.stepGneral2 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self.stepGneral2:setAnimation("stand",true,0)
        self.stepGneral2:setScale(1.8*(config[tostring(self.standdata[2]["level"])].scale or 1))
        self.stepGneral2:setPosition(0,0)
        self.rootItems.mochongNode:addChild(self.stepGneral2)
    end
    

    if self.standdata[3]["cid"] ~= 0 then
        local generalName = gamedata.config.generalanimation[tostring(config[tostring(self.standdata[3]["level"])].animationid)].name
        self.stepGneral3 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self.stepGneral3:setAnimation("stand",true,0)
        self.stepGneral3:setScale(1.8*(config[tostring(self.standdata[3]["level"])].scale or 1))
        self.stepGneral3:setPosition(1080,0)
        self.rootItems.mochongNode:addChild(self.stepGneral3)
    end
    


    local function ccTouchBegan(x, y)
        -- print("began===",x,y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            self.item1 = nil
            self.item2 = nil
            self.item3 = nil
            self.x1,self.y1 = 0,0
            self.x2,self.y2 = 0,0
            self.x3,self.y3 = 0,0

            if self.stepGneral1 then
                self.item1 = tolua.cast(self.stepGneral1,"CCNode")
                self.x1,self.y1 = self.item1:getPosition()
            end

            if self.stepGneral2 then
                self.item2 = tolua.cast(self.stepGneral2,"CCNode")
                self.x2,self.y2 = self.item2:getPosition()
            end
            
            if self.stepGneral3 then
                self.item3 = tolua.cast(self.stepGneral3,"CCNode")
                self.x3,self.y3 = self.item3:getPosition()
            end
            
            return true
        end
    end

    local function ccTouchMoved(x, y)
        -- print("moved,x,y==",x,y)
        local distanceX = x-self.touchX
        -- print("setPosition===",x,y)
        if self.item1 then
            -- print("self.item1.moved")
            self.item1:setPositionX(self.x1+distanceX)
        end
        if self.item2 then
            -- print("self.item2.moved")
            self.item2:setPositionX(self.x2+distanceX)
        end
        if self.item3 then
            -- print("self.item3.moved")
            self.item3:setPositionX(self.x3+distanceX)
        end

        
    end

    local function ccTouchEnded(x, y)
        -- print("touchend===",x,y)
        if x-self.touchX > 20 then
            gameTouch:clickprofbytime(0.5)

            self:setActionRightreload()

        elseif self.touchX-x > 20 then
            gameTouch:clickprofbytime(0.5)

            self:setActionLeftreload()
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
    if self.rootItems.touchLayer then
        self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority, false)
        self.rootItems.touchLayer:setTouchPriority(self.touchPriority)
        self.rootItems.touchLayer:setTouchEnabled(true)
    end

end

function devourDetails.setActionRightreload(self)
    -- -1080
    -- 600

    if self.item1 then
        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item1:runAction(backOut)

        self.petstagedata.cid = self.standdata[1]["cid"]
        self.petstagedata.level = self.standdata[1]["level"]


        self.item1:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.3),CCCallFunc:create(function()
            -- UIRequest({type = 3670,cid = self.standdata[1]})
            self:stagedetailsReload()
        end)))
        
    else
        -- local moveTo = CCMoveTo:create(0.5, ccp(-1080, 0))
        -- local backOut = CCEaseExponentialOut:create(moveTo)
        -- self.item1:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(1080, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item3:runAction(backOut)

        return
    end
    if self.item2 then
        local moveTo = CCMoveTo:create(0.5, ccp(1080, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
    end
end

function devourDetails.setActionLeftreload(self)
    if self.item3 then
        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item3:runAction(backOut)

        self.petstagedata.cid = self.standdata[3]["cid"]
        self.petstagedata.level = self.standdata[3]["level"]

        self.item3:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.3),CCCallFunc:create(function()
            self:stagedetailsReload()
            -- UIRequest({type = 3670,cid = self.standdata[3]})
        end)))
    else
        local moveTo = CCMoveTo:create(0.5, ccp(-1080, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item1:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)

        -- local moveTo = CCMoveTo:create(0.5, ccp(600, 0))
        -- local backOut = CCEaseExponentialOut:create(moveTo)
        -- self.item3:runAction(backOut)

        return
    end

    if self.item2 then
        local moveTo = CCMoveTo:create(0.5, ccp(-1080, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
    end

end

function devourDetails.infoReload(self)
    --print("i...am...detailsReload...")
    --printT(self.petinfodata,"lipurposes")
    -- self.petinfodata
    local nowcid = self.petinfodata.cid
    local nowlevel = self.petinfodata.level

    local config = gamedata.config.pet3_attr[tostring(self.petinfodata.cid)] or {}


    if self.rootItems.mochongNode then
        local mochong = gamedata.config.generalanimation[tostring(config[tostring(nowlevel)].animationid)].name or "mowang_1"
        self.rootItems.mochongNode:removeAllChildrenWithCleanup(true)
        self.Gneral1 = nil
        self.Gneral1 = CCSkeletonAnimation:create(mochong.."/"..mochong..".json",mochong.."/"..mochong..".atlas",1)
        if self.Gneral1 then
            self.Gneral1:setAnimation("stand",true,0)
            self.Gneral1:setScale(1.8*(config[tostring(nowlevel)].scale or 1))
            self.Gneral1:setPosition(0,0)
            self.rootItems.mochongNode:addChild(self.Gneral1)

        end
    end

    local moquality = (config[tostring(nowlevel)].quality and config[tostring(nowlevel)].quality ~= 0) and config[tostring(nowlevel)].quality or 1
    ui.setLabelString(self.rootItems.mochongnameLabel,config[tostring(nowlevel)].name,moquality>=7 and 213 or moquality*2-1)

    local talantskillconfig = gamedata.config.pet3_talentskill

    self.rootItems.talantNumLabel:setString(talantskillconfig[tostring(config[tostring(nowlevel)].talentskill)].number)


    local skillconfig = gamedata.config.combskill or {}

    local skillid = config[tostring(nowlevel)].skillid

    -- print("skillid===",skillid)
    -- printT(skillconfig[tostring(skillid)])

    -- print(skillconfig[tostring(config[tostring(nowlevel)].skillid)]["name"])
    if config[tostring(nowlevel)].skillid and config[tostring(nowlevel)].skillid > 0 then
        if skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality >= 7 then
            ui.setLabelString(self.rootItems.activeSkillNameLabel,skillconfig[tostring(config[tostring(nowlevel)].skillid)]["name"]..": ",213)
        else
            ui.setLabelString(self.rootItems.activeSkillNameLabel,skillconfig[tostring(config[tostring(nowlevel)].skillid)]["name"]..": ",((skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality and skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality ~= 0) and skillconfig[tostring(config[tostring(nowlevel)].skillid)].quality or 1)*2)
        end
        
        self.rootItems.activeSkillDescLabel:setString("                 "..skillconfig[tostring(config[tostring(nowlevel)].skillid)]["effect-desc"])
        -- 主页面设置 主动技能icon
        local stringname = skillconfig[tostring(config[tostring(nowlevel)].skillid)].icon
        -- print("stringname==",stringname)
        setSpriteFrameByName(self.rootItems.i_icon, stringname)
        self.rootItems.i_soulsprite:setVisible(false)

    end

    
    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("devourDetails")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self.rootItems.doLab1:setVisible(false)
    self.rootItems.doButton1:setVisible(false)
    self.rootItems.doLab2:setVisible(false)
    self.rootItems.doButton2:setVisible(false)

    self.rootItems.doLab1:setPositionX(9999)
    self.rootItems.doButton1:setPositionX(9999)
    self.rootItems.doLab2:setPositionX(9999)
    self.rootItems.doButton2:setPositionX(9999)


    
    
    ui.setLabelString(self.rootItems.comfirmText, nil, 19)
    self.rootItems.comfirmBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("devourDetails")
        
    end, CCControlEventTouchUpInside)
    self.rootItems.comfirmBtn:setSwallowsTouch(true)
    self.rootItems.comfirmBtn:setTouchPriority(self.touchPriority)

    
    -- ui.setLabelString(self.rootItems.doLab1, "更换魔宠", 19)
    -- self.rootItems.doButton1:addHandleOfControlEvent(function()

    --     GameScene:shiftLayer("devourList","up",self.petdata)

    --     -- gameWindows:closeWindow("favoriteList")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.doButton1:setSwallowsTouch(true)
    -- self.rootItems.doButton1:setTouchPriority(self.touchPriority)


    -- ui.setLabelString(self.rootItems.doLab2, "进阶", 19)
    -- self.rootItems.doButton2:addHandleOfControlEvent(function()
    --     gameWindows:closeWindow("devourDetails")

    --     if GameScene.layers["devil"].show then
    --         GameScene.layers["devil"].module:shiftNode("advanceNode")
    --     end
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.doButton2:setSwallowsTouch(true)
    -- self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.title,"魔宠详情",28)

    --
    self:plusAttr(nowcid,nowlevel)
    
end

function devourDetails.resetReload(self)
    local locknum = 0
    local hasType = false
    -- print("resetReload====")
    -- printT(self.petskill)
    for k,v in pairs(self.petskill) do
        if v.lock ~= 0 then
            locknum = locknum + 1
        end

        if v.cid ~= 0 and v.lock == 0 and gamedata.config.pet3_passiveskill[tostring(v.cid)].quality >= 5 then
            hasType = true
        end
    end
    local spendnum = 0

    local globalconfig = gamedata.config.global_kv
    if locknum == 0 then
        spendnum =  tonumber(globalconfig.pet3_passiveskill_cost.value or 0)
    else
        spendnum =  tonumber(globalconfig.pet3_passiveskill_cost.value or 0) + tonumber(globalconfig["pet3_passiveskill_cost"..locknum].value or 0)
    end
    
    self.rootItems.locknameLabel:setString(locknum)
    self.rootItems.spendLabel:setString(spendnum)

    if hasType then
        self.rootItems.tishiNode:setVisible(true)
        ui.setLabelString(self.rootItems.tishiupLabel,nil,144)
        ui.setLabelString(self.rootItems.tishidownLabel,nil,144)
        self.rootItems.desNode:setPositionY(0)
    else
        self.rootItems.tishiNode:setVisible(false)
        self.rootItems.desNode:setPositionY(-60)
    end

    -- 返回
    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("devourDetails")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)



    -- 返回
    ui.setLabelString(self.rootItems.backText, nil, 19)
    self.rootItems.backBtn:addHandleOfControlEvent(function()

        gameWindows:closeWindow("devourDetails")
    end, CCControlEventTouchUpInside)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(self.touchPriority)

    -- 重置
    ui.setLabelString(self.rootItems.lockText, nil, 19)
    self.rootItems.lockBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("devourDetails")

        UIRequest({type = 1061,spend = spendnum})
    end, CCControlEventTouchUpInside)
    self.rootItems.lockBtn:setSwallowsTouch(true)
    self.rootItems.lockBtn:setTouchPriority(self.touchPriority)
end


function devourDetails.plusAttr(self,nowcid,nowlevel)

    local nowlevel = nowlevel
    local config = gamedata.config.pet3_attr[tostring(nowcid)] or {}

    local plusattr = {
        attr1 = "",
        num1 = 0,
        attr2 = "",
        num2 = 0,
        attr3 = "",
        num3 = 0,
    }
    for k,v in pairs(config) do
        if (tonumber(k) > 0) and (tonumber(k) <= nowlevel) then
            if v.attr1 and v.attr1 ~= "" then
                plusattr.attr1 = v.attr1
                plusattr.num1 = plusattr.num1+v.init1
            end
            if v.attr2 and v.attr2 ~= "" then
                plusattr.attr2 = v.attr2
                plusattr.num2 = plusattr.num2+v.init2
            end
            if v.attr3 and v.attr3 ~= "" then
                plusattr.attr3 = v.attr3
                plusattr.num3 = plusattr.num3+v.init3
            end
        end
    end
    --
    if plusattr.num1+plusattr.num2+plusattr.num3 > 0.00001 then      --float   todo
        self.rootItems.plusAttrNode:setVisible(true)
        if plusattr.num1 > 0.00001 then
            self.rootItems.plusAttr1:setString(gameConfig.strings:string_common("attr_type",plusattr.attr1).." +"..plusattr.num1)
        end
        if plusattr.num2 > 0.00001 then
            self.rootItems.plusAttr2:setString(gameConfig.strings:string_common("attr_type",plusattr.attr2).." +"..plusattr.num2)
        end
        if plusattr.num3 > 0.00001 then
            self.rootItems.plusAttr3:setString(gameConfig.strings:string_common("attr_type",plusattr.attr3).." +"..plusattr.num3)
        end
    else
        self.rootItems.plusAttrNode:setVisible(false)
    end


end


function devourDetails.close(self)

    if self.rootItems.mochongNode then
        self.rootItems.mochongNode:removeAllChildrenWithCleanup(true)
        self.Gneral1 = nil
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.petdata = {}

    self.showdata = {}


end

return devourDetails