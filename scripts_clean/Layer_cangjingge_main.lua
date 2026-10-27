--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local cangjinggemain = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    isContentScroll = false,

    generalListTableView = nil,

    buttontouch = -1,

    manorrid = 0,
    manorfriends = {},
    showfriends = {},

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                friend = {265},
            },
        },
    },
}

function cangjinggemain.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("cangjingge/cangjingge_zhuye", nil, true, "cangjingge_zhuye")
    parent:addChild(self.rootNode)

    self.topposy = toppos
    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.bgscroll = tolua.cast(self.rootItems.bgscroll, "CCScrollView")
    self.rootItems.bgscroll:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-160))
    self.rootItems.bgscroll:setContentOffsetInDuration(ccp(0,toppos-160-1920),0)
    --
    self.rootItems.backbutton:setSwallowsTouch(true)
    self.rootItems.backbutton:setTouchPriority(self.buttontouch-1)
    self.rootItems.backbutton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        print("back")
        if self.manorrid and self.manorrid > 0 then
            UIRequest({type = 4820})
        else
            GameScene:shiftLayer("main","down")
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.rulebutton:setSwallowsTouch(true)
    self.rootItems.rulebutton:setTouchPriority(self.buttontouch-1)
    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        print("rule")
        gameWindows:openWindow("cangjingge_rule",nil,nil)
    end, CCControlEventTouchUpInside)


    --商店
    self.rootItems.shopbutton:setSwallowsTouch(true)
    self.rootItems.shopbutton:setTouchPriority(self.buttontouch-1)
    self.rootItems.shopbutton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        print("shop")
        GameScene:shiftLayerById(263)
    end, CCControlEventTouchUpInside)

    --

    self.rootItems.building:setSwallowsTouch(true)
    self.rootItems.building:setTouchPriority(self.buttontouch-1)
    self.rootItems.building:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        print("building")
        gameWindows:openWindow("cangjingge_allbuild",{building = self.cangjingge.building or {}},nil)
    end, CCControlEventTouchUpInside)

    --
    self.rootItems.friend:setSwallowsTouch(true)
    self.rootItems.friend:setTouchPriority(self.buttontouch-1)
    self.rootItems.friend:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        gameTouch:clickprofbytime(1)
        print("friend")
        if GameScene.cangjingge.building and GameScene.cangjingge.building["1"] and GameScene.cangjingge.building["1"].level and GameScene.cangjingge.building["1"].level > 0 then
            UIRequest({type = 4821,show = 1})
        else
            runGamePrompt({msg = gameConfig.strings:cangjingge_uplimit(gamedata.config.home_building["1"]["1"].name or "",1)})
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.friend_close:setSwallowsTouch(true)
    self.rootItems.friend_close:setTouchPriority(self.buttontouch-4)
    self.rootItems.friend_close:addHandleOfControlEvent(function()
        self.rootItems.friendNode:setVisible(false)
        self.rootItems.friendNode:setPositionX(9999)
    end, CCControlEventTouchUpInside)

    self.rootItems.addcount:setSwallowsTouch(true)
    self.rootItems.addcount:setTouchPriority(self.buttontouch-4)
    self.rootItems.addcount:addHandleOfControlEvent(function()
        HomeChallengeBuyTimes()
    end, CCControlEventTouchUpInside)


    self.rootItems.notice:setSwallowsTouch(true)
    self.rootItems.notice:setTouchPriority(self.buttontouch-1)
    self.rootItems.notice:addHandleOfControlEvent(function()
        print("notice")
        if self.isContentScroll then return end
        if self.manorrid and self.manorrid > 0 then return end
        local cb = function(text)
            UIRequest({type = 4831,text = text})
        end
        gameWindows:openWindow("setnotice",{title = gameConfig.strings:string_common("popups","gonggao"), msg = self.cangjingge.content or ""},cb)
    end, CCControlEventTouchUpInside)

    --
    local function touchbegin(pos)
        self.isContentScroll = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","cangjinggemain",touchbegin)

    local function touchend(pos)
        if (math.abs(pos.x - self.touchbegin.x) > 20) or (math.abs(pos.y - self.touchbegin.y) > 20) then
            self.isContentScroll = true
        end
    end

    gameTouch:rigistFunc("end","cangjinggemain",touchend)
    --

    self.rootItems.friendNode:setVisible(false)
    self.rootItems.friendNode:setPositionX(9999)

    --self:reloaddata()
    UIRequest({type = 4820})
    guide.controller:addComplete(262,function()
        UIRequest({type = 2882,opt=1,sysID=262})
    end)
end



function cangjinggemain.reloaddata(self,data)
    if data then
        self.cangjingge = data.cangjingge or {}
        self.manorrid = data.manorReqRid or 0

        --
        self.rootItems["monstergeneral1"]:removeAllChildrenWithCleanup(true)
        self.rootItems["monstergeneral2"]:removeAllChildrenWithCleanup(true)
        --
        if self.manorrid > 0 then
            --
            self.rootItems.building1_time:setVisible(false)
            --
            self.rootItems.friendNode:setVisible(false)
            self.rootItems.friendNode:setPositionX(9999)
            --
            self.rootItems.materialNode:setVisible(false)
            self.rootItems.building:setVisible(false)
            --
            self.rootItems.monsternode1:setVisible(true)
            self.rootItems.monsternode2:setVisible(true)
            --
            if self.cangjingge.monster1 and self.cangjingge.monster1 > 0 then
                local gcid = gamedata.config.home_monster[tostring(self.cangjingge.monster1)] and gamedata.config.home_monster[tostring(self.cangjingge.monster1)].monsterid or 10301
                local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(gcid).animationid)].name
                local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
                Gneral1:setAnimation("stand",true,0)
                Gneral1:setScale(1.2)
                Gneral1:setPosition(0,0)
                self.rootItems["monstergeneral1"]:addChild(Gneral1.root or Gneral1)
                --
                self.rootItems["monsterButton1"]:setSwallowsTouch(true)
                self.rootItems["monsterButton1"]:setTouchPriority(self.buttontouch-1)
                self.rootItems["monsterButton1"]:addHandleOfControlEvent(function()
                    if self.isContentScroll then return end
                    if self.manorrid == 0 then return end
                    self.rootItems.friendNode:setVisible(false)
                    self.rootItems.friendNode:setPositionX(9999)
                    gameWindows:openWindow("cangjingge_guai",{rid = self.manorrid, monsterpos = 1, monster = self.cangjingge.monster1, count = self.manorfriends.count or 0},nil)
                end, CCControlEventTouchUpInside)
            else
                --
                self.rootItems["monsterButton1"]:setSwallowsTouch(true)
                self.rootItems["monsterButton1"]:setTouchPriority(self.buttontouch-1)
                self.rootItems["monsterButton1"]:addHandleOfControlEvent(function()
                    if self.isContentScroll then return end
                    if self.manorrid == 0 then return end

                end, CCControlEventTouchUpInside)
            end
            --
            if self.cangjingge.monster2 and self.cangjingge.monster2 > 0 then
                local gcid = gamedata.config.home_monster[tostring(self.cangjingge.monster2)] and gamedata.config.home_monster[tostring(self.cangjingge.monster2)].monsterid or 10301
                local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(gcid).animationid)].name
                local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
                Gneral1:setAnimation("stand",true,0)
                Gneral1:setScale(1.2)
                Gneral1:setPosition(0,0)
                self.rootItems["monstergeneral2"]:addChild(Gneral1.root or Gneral1)
                --
                self.rootItems["monsterButton2"]:setSwallowsTouch(true)
                self.rootItems["monsterButton2"]:setTouchPriority(self.buttontouch-1)
                self.rootItems["monsterButton2"]:addHandleOfControlEvent(function()
                    if self.isContentScroll then return end
                    if self.manorrid == 0 then return end
                    self.rootItems.friendNode:setVisible(false)
                    self.rootItems.friendNode:setPositionX(9999)
                    gameWindows:openWindow("cangjingge_guai",{rid = self.manorrid, monsterpos = 2, monster = self.cangjingge.monster2, count = self.manorfriends.count or 0},nil)
                end, CCControlEventTouchUpInside)
            else
                --
                self.rootItems["monsterButton2"]:setSwallowsTouch(true)
                self.rootItems["monsterButton2"]:setTouchPriority(self.buttontouch-1)
                self.rootItems["monsterButton2"]:addHandleOfControlEvent(function()
                    if self.isContentScroll then return end
                    if self.manorrid == 0 then return end

                end, CCControlEventTouchUpInside)
            end
            --
        else
            self.rootItems.building1_time:setVisible(true)
            self.rootItems.materialNode:setVisible(true)
            self.rootItems.building:setVisible(true)
            self.rootItems.monsternode1:setVisible(false)
            self.rootItems.monsternode2:setVisible(false)
            --time
            if gameTimer.times["manorqualitytime"] and gameTimer.times["manorqualitytime"] > 0 then
                gameTimer:rigistTimeFunc("manorqualitytime",function()
                    if gameTimer.times["manorqualitytime"] <= 0 then
                        gameTimer:UnrigistTimeFunc("manorqualitytime")
                        self:manorchange()
                    end
                end)
            end
            --manormaterialtime
            if gameTimer.times["manormaterialtime"] and gameTimer.times["manormaterialtime"] > 0 then
                gameTimer:rigistTimeFunc("manormaterialtime",function()
                    if gameTimer.times["manormaterialtime"] <= 0 then
                        gameTimer:UnrigistTimeFunc("manormaterialtime")
                        ui.setLabelString(self.rootItems.building1_time,"",23)
                    else
                        ui.setLabelString(self.rootItems.building1_time,gameConfig.strings:string_common("cangjingge",51)..ui.makeTimeDayText(gameTimer.times["manormaterialtime"],"hour"),23)
                    end
                end)
            else
                ui.setLabelString(self.rootItems.building1_time,"",23)
            end
        end

    end

    if not self.cangjingge then return end

    ui.setLabelString(self.rootItems.name,self.cangjingge.name..gameConfig.strings:string_common("cangjingge",12),14)
    ui.setLabelString(self.rootItems.material_num1,self.cangjingge.material1,14)
    ui.setLabelString(self.rootItems.material_num2,self.cangjingge.material2,14)
    self.rootItems.material_name1:setString(ui.IDconfig(20377).name.."：")
    self.rootItems.material_name2:setString(ui.IDconfig(20378).name.."：")
    setSpriteFrameByName(self.rootItems.material_icon1, ui.IDconfig(20377).icon)
    setSpriteFrameByName(self.rootItems.material_icon2, ui.IDconfig(20378).icon)

    if self.cangjingge.content and self.cangjingge.content ~= "" then
        ui.setLabelString(self.rootItems.content,self.cangjingge.content,14)
    else
        ui.setLabelString(self.rootItems.content,gameConfig.strings:string_common("cangjingge",46),14)
    end

    --
    for i = 1,5 do
        if self.cangjingge.building and self.cangjingge.building[tostring(i)] then

            local labelparams = (self.cangjingge.building[tostring(i)].quality > 0) and (self.cangjingge.building[tostring(i)].quality*2+3) or 5
            ui.setLabelString(self.rootItems["building"..i.."_name"],gamedata.config.home_building[tostring(i)][tostring(self.cangjingge.building[tostring(i)].quality > 0 and self.cangjingge.building[tostring(i)].quality or 1)].name,self.cangjingge.building[tostring(i)].quality == 5 and 213 or labelparams)
            if self.cangjingge.building[tostring(i)].level and self.cangjingge.building[tostring(i)].level > 0 then
                if self.rootItems["building"..i.."_status1"] then
                    setSpriteFrameByName(self.rootItems["building"..i.."_status1"],"cangjinggekeshengji")
                end
            else
                if self.rootItems["building"..i.."_status1"] then
                    setSpriteFrameByName(self.rootItems["building"..i.."_status1"],"cangjinggekejianzao")
                end
            end
            for j = 0,5,1 do
                if self.rootItems["building"..i.."_bg"..j] then
                    self.rootItems["building"..i.."_bg"..j]:setVisible(j == self.cangjingge.building[tostring(i)].quality)
                end
                if self.rootItems["building"..i.."_status"..j] then
                    self.rootItems["building"..i.."_status"..j]:setVisible(j == self.cangjingge.building[tostring(i)].status)
                end
            end
            --self.rootItems["building"..i.."_button"]:setSwallowsTouch(true)
            self.rootItems["building"..i.."_button"]:setTouchPriority(self.buttontouch)
            self.rootItems["building"..i.."_button"]:addHandleOfControlEvent(function()
                if self.isContentScroll then return end
                if self.manorrid > 0 then return end
                print("building"..i.."_button")
                if (i == 1) and (self.cangjingge.building[tostring(i)].status == 2) then
                    gameTouch:clickprofbytime(1)
                    UIRequest({type = 4823})
                elseif (i == 2) and (self.cangjingge.building[tostring(i)].level > 0) then
                    gameWindows:openWindow("cangjingge_task",{buildtype = i, buildlevel = self.cangjingge.building[tostring(i)].level, buildquality = self.cangjingge.building[tostring(i)].quality, building = self.cangjingge.building},nil)
                else
                    gameWindows:openWindow("cangjingge_buildup",{buildtype = i, buildlevel = self.cangjingge.building[tostring(i)].level, buildquality = self.cangjingge.building[tostring(i)].quality, material1 = self.cangjingge.material1, material2 = self.cangjingge.material2, levellimit = self.cangjingge.building["1"].level},nil)
                end
            end, CCControlEventTouchUpInside)
        end
    end


end

function cangjinggemain.clear(self)
    gameTimer:UnrigistTimeFunc("manormaterialtime")
    gameTimer:UnrigistTimeFunc("manorqualitytime")
    gameTouch:UnrigistFunc("begin","cangjinggemain")
    gameTouch:UnrigistFunc("end","cangjinggemain")
    self.isContentScroll = false
    self.generalListTableView = nil
    self.manorrid = 0
    self.manorfriends = {}
    self.showfriends = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

function cangjinggemain.showfriend(self,data)

    self.rootItems.friendNode:setPositionX(0)
    self.rootItems.friendNode:setVisible(true)

    self.manorfriends = data.manorfriends or {}

    --local killcount = gamedata.config.global_kv.home_monster_kill_limit and tonumber(gamedata.config.global_kv.home_monster_kill_limit.value) or 0
    ui.setLabelString(self.rootItems.count_lab,gameConfig.strings:string_common("cangjingge",34),1)
    --ui.setLabelString(self.rootItems.count,killcount+(GameScene.vipstatus.home_challenge_times or 0)-(self.manorfriends.count or 0),14)
    ui.setLabelString(self.rootItems.count,self.manorfriends.count or 0,14)

    if not self.manorfriends.friends then return end

    self.showfriends = {}
    for k,v in pairs(self.manorfriends.friends) do
        table.insert(self.showfriends,v)
    end

    if not self.generalListTableView then
        self:reloadGeneralList()
    else
        self.generalListTableView:reloadData()
    end

end

function cangjinggemain.reloadGeneralList(self)
    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(250, 250)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("cangjingge/friend_iconName.ccbi", nil, true, "friend_iconName")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            cellCCB:setPosition(0, 40)
            --
            ui.setLabelString(ccbDocumentControler.fin_name,self.showfriends[a1+1].name or "",14)
            setSpriteFrameByName(ccbDocumentControler.fin_icon, ui.IDconfig(self.showfriends[a1+1].profile) and ui.IDconfig(self.showfriends[a1+1].profile).icon or "alpha")
            ui.setSpriteTextureRect(ccbDocumentControler.fin_icon,0,0,150,150)
            if (self.showfriends[a1+1].monster1 > 0) or (self.showfriends[a1+1].monster2 > 0) then
                ccbDocumentControler.fin_monster:setVisible(true)
            else
                ccbDocumentControler.fin_monster:setVisible(false)
            end
            --
            ccbDocumentControler.fin_button:setTouchPriority(self.buttontouch-4)
            ccbDocumentControler.fin_button:addHandleOfControlEvent(function()
                print("fin_button")
                if self.isContentScroll then return end
                gameTouch:clickprofbytime(1)
                UIRequest({type = 4820,rid = self.showfriends[a1+1].rid})

            end, CCControlEventTouchUpInside)
            --

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showfriends or {})
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.generalListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.friendlist:getContentSize().width,
        viewheight = self.rootItems.friendlist:getContentSize().height,
        dire = 0
    })
    self.rootItems.friendlist:addChild(self.generalListTableView)
    self.generalListTableView:setTouchPriority(self.buttontouch-3)
end

function cangjinggemain.manorchange(self)
    if self.manorrid == 0 then
        UIRequest({type = 4820})
    end
end

function cangjinggemain.manorchangebyrid(self)

     UIRequest({type = 4820,rid = self.manorrid or 0})
end


return cangjinggemain