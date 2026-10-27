--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/12
-- Time: 下午5:59
-- To change this template use File | Settings | File Templates.
--

local zhuxiantai = {
    rootNode = nil,
    rootItems = nil,

    root = nil,

    -- addConfig = {
    --     [1] = {name = "生命",ext = "%",sprite = "hp"},
    --     [2] = {name = "攻击",ext = "%",sprite = "atk"},
    --     [3] = {name = "防御",ext = "%",sprite = "def"},
    --     [4] = {name = "速度",ext = "",sprite = "speed"},
    --     [5] = {name = "暴击",ext = "%",sprite = "critical"},
    --     [6] = {name = "闪避",ext = "%",sprite = "dodge"},
    --     [7] = {name = "格挡",ext = "%",sprite = "parry"},
    -- },
    addConfig = {
        [1] = {name = gameConfig.strings:string_common("zhuxiantai",0),ext = "%",sprite = "hp"},
        [2] = {name = gameConfig.strings:string_common("zhuxiantai",1),ext = "%",sprite = "atk"},
        [3] = {name = gameConfig.strings:string_common("zhuxiantai",2),ext = "%",sprite = "def"},
        [4] = {name = gameConfig.strings:string_common("zhuxiantai",3),ext = "",sprite = "speed"},
        [5] = {name = gameConfig.strings:string_common("zhuxiantai",4),ext = "%",sprite = "critical"},
        [6] = {name = gameConfig.strings:string_common("zhuxiantai",5),ext = "%",sprite = "dodge"},
        [7] = {name = gameConfig.strings:string_common("zhuxiantai",6),ext = "%",sprite = "parry"},
    },

    jiachengdata = nil,

    starconfig = {3,15,30},

    desconfig = {49,482,},

    attrselect = 0,
}

function zhuxiantai.open(self,touchPriority,data,callback)

    self.root = CCNode:create()

    self.touchPriority = touchPriority
    if data.type == "nandu" then
        self.rootNode, self.rootItems = CCBReaderLoad("zhuxiantai/zhuxiantai_xuanzenandu", nil, true, "zhuxiantai_xuanzenandu")
        self:reloadnandu(data,callback)
    elseif data.type == "jiacheng" then
        self.rootNode, self.rootItems = CCBReaderLoad("zhuxiantai/zhuxiantai_jiacheng", nil, true, "zhuxiantai_jiacheng")
        self:reloadjiacheng(data,callback)
    elseif data.type == "rewardview" then
        self.rootNode, self.rootItems = CCBReaderLoad("zhuxiantai/zhuxiantai_jiangli", nil, true, "zhuxiantai_jiangli")
        self:reloadRewardView(data,callback)
    elseif data.type == "rank" then
        self.rootNode, self.rootItems = CCBReaderLoad("zhuxiantai/zhuxiantai_paihang", nil, true, "zhuxiantai_paihang")
        self:relaodRank(data,callback)
    end
    self.root:addChild(self.rootNode)
    return self.root
end

function zhuxiantai.reloadnandu(self,data,callback)
    self.callback = callback
    self.data = data

    -- ui.setLabelString(self.rootItems.level,"第"..data.data.level.."关",48)
    ui.setLabelString(self.rootItems.level,gameConfig.strings:getLevel(data.data.level),48)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("zhuxiantai")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local config = gamedata.config.zhusendai_monster_param[tostring(data.data.level)]

    for i=1,3 do
        local prestige,coin = ui.getIDandNUM(config["star"..i.."reward"])
        self.rootItems["prestige"..i]:setString(prestige)
        self.rootItems["coin"..i]:setString(coin)
        -- self.rootItems["power"..i]:setString("推荐战斗力: "..math.ceil(data.data.power*(0.9^(3-i))))
        self.rootItems["power"..i]:setString(gameConfig.strings:tjZdl(math.ceil(data.data.power*(0.9^(3-i)))))

        -- ui.setLabelString(self.rootItems["buttontext"..i],"挑 战",18)
        ui.setLabelString(self.rootItems["buttontext"..i],gameConfig.strings:string_common("zhuxiantai",17),18)
        self.rootItems["button"..i]:addHandleOfControlEvent(function()
            gameWindows:closeWindowDirect("zhuxiantai")
            UIRequest({type = 3601,id = i})
        end, CCControlEventTouchUpInside)
        self.rootItems["button"..i]:setSwallowsTouch(true)
        self.rootItems["button"..i]:setTouchPriority(self.touchPriority)
    end
end

function zhuxiantai.setJiacheng(self,id,location)
    --printT(self.jiachengdata)
    -- if self.jiachengdata.data.data.leftstar < (self.starconfig[location] or 0) then runGamePrompt({msg = "当前可用星数不足"})  return end
    if self.jiachengdata.data.data.leftstar < (self.starconfig[location] or 0) then runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",18)})  return end
    self.attrselect = id or 0

    ui.setLabelString(self.rootItems.atk,"+"..self.jiachengdata.data.data.atk.."%",26)
    ui.setLabelString(self.rootItems.def,"+"..self.jiachengdata.data.data.def.."%",26)
    ui.setLabelString(self.rootItems.hp,"+"..self.jiachengdata.data.data.hp.."%",26)
    ui.setLabelString(self.rootItems.speed,"+"..self.jiachengdata.data.data.speed,26)
    ui.setLabelString(self.rootItems.critical,"+"..self.jiachengdata.data.data.critical.."%",26)
    ui.setLabelString(self.rootItems.dodge,"+"..self.jiachengdata.data.data.dodge.."%",26)
    ui.setLabelString(self.rootItems.parry,"+"..self.jiachengdata.data.data.parry.."%",26)

    for i=1,3 do
        local key_Ex
        if i == nil or i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end

        setSpriteFrameByName(self.rootItems["s_sprite"..key_Ex], "obj_zxt_"..self.addConfig[self.jiachengdata.data.attr[tostring(i)].attr].sprite)
        self.rootItems["s_des"..key_Ex]:setString(self.addConfig[self.jiachengdata.data.attr[tostring(i)].attr].name)
        ui.setLabelString(self.rootItems["s_num"..key_Ex],"+"..self.jiachengdata.data.attr[tostring(i)].add..self.addConfig[self.jiachengdata.data.attr[tostring(i)].attr].ext,26)

        self.rootItems["s_star"..key_Ex]:setString(self.starconfig[i])

        self.rootItems["s_shadow"..key_Ex]:setVisible(self.jiachengdata.data.data.leftstar < self.starconfig[i])
        self.rootItems["s_select"..key_Ex]:setVisible(location == i )
        if location == i then
            local index= self.addConfig[self.jiachengdata.data.attr[tostring(i)].attr].sprite
            ui.setLabelString(self.rootItems[index],"+"..self.jiachengdata.data.data[index]+self.jiachengdata.data.attr[tostring(i)].add..self.addConfig[self.jiachengdata.data.attr[tostring(i)].attr].ext,26)
        end
    end
end

function zhuxiantai.reloadjiacheng(self,data,callback)
    if data.data then
        self.jiachengdata = data
    end
    -- self.rootItems.title:setString("选择加成")
    self.rootItems.title:setString(gameConfig.strings:string_common("zhuxiantai",19))
    for i = 1, 2 do
        local index = 1
        while self.rootItems["des"..i.."_"..index] do
            ui.setLabelString(self.rootItems["des"..i.."_"..index],nil,self.desconfig[i])
            index = index+1
        end
    end

    -- ui.setLabelString(self.rootItems.reststar,"当前可用："..self.jiachengdata.data.data.leftstar,14)
    ui.setLabelString(self.rootItems.reststar,gameConfig.strings:useBf(self.jiachengdata.data.data.leftstar),14)

    -- ui.setLabelString(self.rootItems["buttontext"],"继续挑战",18)
    ui.setLabelString(self.rootItems["buttontext"],gameConfig.strings:string_common("zhuxiantai",20),18)
    self.rootItems["button"]:addHandleOfControlEvent(function()
        if self.attrselect ==0 then
            -- runGamePrompt({msg = "请选择加成"})
            runGamePrompt({msg = gameConfig.strings:string_common("zhuxiantai",24)})
        else
            self.jiachengdata = nil
            UIRequest({type = 3604,id = self.attrselect})
            gameWindows:closeWindowDirect("zhuxiantai")
        end
    end, CCControlEventTouchUpInside)
    self.rootItems["button"]:setSwallowsTouch(true)
    self.rootItems["button"]:setTouchPriority(self.touchPriority)


    for i=1,3 do
        local key_Ex
        if i == nil or i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end

        self.rootItems["s_button"..key_Ex]:addHandleOfControlEvent(function()
            self:setJiacheng(self.jiachengdata.data.attr[tostring(i)].attr,i)
        end, CCControlEventTouchUpInside)
        self.rootItems["s_button"..key_Ex]:setSwallowsTouch(true)
        self.rootItems["s_button"..key_Ex]:setTouchPriority(self.touchPriority)
    end

    self:setJiacheng(0,0)
end

function zhuxiantai.reloadRewardView(self,data,callback)
    self.data = data
    -- self.rootItems.title:setString("奖励预览")
    self.rootItems.title:setString(gameConfig.strings:string_common("zhuxiantai",21))

    -- ui.setLabelString(self.rootItems.reststar,"当前: "..self.data.data.leftstar,19)
    ui.setLabelString(self.rootItems.reststar,gameConfig.strings:daqianNum(self.data.data.leftstar),19)

    local index = math.ceil(self.data.data.floor/3)*3

    -- ui.setLabelString(self.rootItems["des"],"第"..(index-2).."-"..index.."关中获得的数量达到下列数量，即可获得:",49)
    ui.setLabelString(self.rootItems["des"],gameConfig.strings:getLevelAward((index-2),index),49)
    --printT(gamedata.config.zhusendai_reward[tostring(index)])
    for i=1,3 do
        self.rootItems["star"..(i==1 and "" or "_"..(i-1))]:setString(9*i)
        local reward = ui.getIDandNUMs(gamedata.config.zhusendai_reward[tostring(index)]["rewards"..i])
        --printT(reward)
        for j=1,3 do
            if reward[j] then

                self.rootItems["i_root"..((j+3*(i-1))==1 and "" or "_"..((j+3*(i-1))-1))]:setVisible(true)
                ui.setNewIcon(self.rootItems,reward[j], (j+3*(i-1))-1)
                --
                self.rootItems["i_button"..((j+3*(i-1))==1 and "" or "_"..((j+3*(i-1))-1))]:addHandleOfControlEvent(function()
                    ui.setPopwindowByCid(reward[j].cid)
                end, CCControlEventTouchUpInside)
                self.rootItems["i_button"..((j+3*(i-1))==1 and "" or "_"..((j+3*(i-1))-1))]:setSwallowsTouch(true)
                self.rootItems["i_button"..((j+3*(i-1))==1 and "" or "_"..((j+3*(i-1))-1))]:setTouchPriority(self.touchPriority)
                --
            else
                self.rootItems["i_root"..((j+3*(i-1))==1 and "" or "_"..((j+3*(i-1))-1))]:setVisible(false)
            end
        end
    end
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("zhuxiantai")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function zhuxiantai.relaodRank(self,data,callback)
    self.data = data
    -- self.rootItems.title:setString("奖励预览")
    self.rootItems.title:setString(gameConfig.strings:string_common("zhuxiantai",21))

    ui.setLabelString(self.rootItems["des"],nil,49)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("zhuxiantai")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- local myrank = "未上榜"
    local myrank = gameConfig.strings:string_common("zhuxiantai",22)

    for k,v in pairs(self.data.players) do
        if v.rid == GameScene.roleinfo.id then
            myrank = k
        end
    end



    local celldict = {}
    local giftListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(930, 180)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhuxiantai/cell_zhuxiantai_paihang", nil, true, "cell_zhuxiantai_paihang")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local cellData = self.data.players[a1+1] or self.data.players[tostring(a1+1)]
            --printT(cellData)
            ccbDocumentControler.name:setString(cellData.name)
            ccbDocumentControler.rank:setString(a1+1)
            ccbDocumentControler.total:setString(cellData.params["1"].i)
            -- ccbDocumentControler.continueday:setString(cellData.params["2"].i.."天")
            ccbDocumentControler.continueday:setString(gameConfig.strings:Day(cellData.params["2"].i))

            ccbDocumentControler.gold:setString(gamedata.config.zhusendai_rankreward[tostring(a1+1)].gold)
            ccbDocumentControler.rank1:setVisible(a1+1 ==1)
            ccbDocumentControler.rank2:setVisible(a1+1 ==2)
            ccbDocumentControler.rank3:setVisible(a1+1 ==3)
            ccbDocumentControler.rankother:setVisible(a1+1 >3)

            cellCCB:setPosition(930/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.players)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView = ui.createLuaTableView({
        handle = giftListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(ListTableView)
    ListTableView:setTouchPriority(self.touchPriority)

    self.rootItems.myrank:setString(myrank)
    self.rootItems.todaystar:setString(self.data.star)
end

function zhuxiantai.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.attrselect = 0

    if self.callback then
        self.callback()
    end
end

return zhuxiantai  �7  