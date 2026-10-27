--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:09
-- To change this template use File | Settings | File Templates.

--与海外版有差异，海外版刷新次数根据vip限制

local activityshop = {

    buttontouch = -103,
    isscrolltouched = false,
}

function activityshop.init(self,size)
    -- print("one========")
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("tanchuang/heishishangdian",nil, true, "heishishangdian")

    local Gneral = CCSkeletonAnimation:create("mengpo/mengpo.json","mengpo/mengpo.atlas",2)
    Gneral:setAnimation("stand",true,0)
    self.coveritems.general:addChild(Gneral)

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    -- self.coveritems.bottomnode:setPositionY((GameScene.topposY-1620)*1+1000)

    local refreshconfig = gamedata.config.blackmarket_refresh
    local nowtime = os.date("*t", gamedata:time())
    local refreshArr = {}

    -- print("refreshconfig====")
    -- printT(refreshconfig)
    local refreshtimestring = "00:00"
    for k,v in pairs(refreshconfig) do
        -- print("refreshtimestring==",v.hour)
        table.insert(refreshArr,tonumber(v.hour))
    end

    local sortfunction = function( a, b )
        return a < b
    end
    table.sort( refreshArr, sortfunction )
    -- print("refreshArr====")
    -- printT(refreshArr)
    for i,v in ipairs(refreshArr) do
        if v > nowtime.hour then
            refreshtimestring = v.."点刷新"
            break
        elseif v == 0 and nowtime.hour >=18 then
            refreshtimestring = v.."点刷新"
            break
        end
    end
    self.coveritems.updatetime:setString(refreshtimestring)



    self.coveritems.scrollnode = tolua.cast(self.coveritems.scrollnode, "CCScrollView")
    self.coveritems.scrollnode:setTouchPriority(self.buttontouch)
    -- self.coveritems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    self.coveritems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-500-180))

    self.coveritems.container:setContentSize(CCSize(1080,1000))

    self.scrollNode, self.scrollItems = CCBReaderLoad("tanchuang/map1", nil, true, "map1")
    self.scrollNode:setPosition(0,0)
    self.scrollNode:setVisible(false)
    self.coveritems.container:addChild(self.scrollNode)

    self.coveritems.scrollnode:setContentOffsetInDuration(ccp(0,self.contentsize.y-180-500-180 - 1000),0)

    self.coveritems.scrollnode_touch:setContentSize(CCSize(gameConfig.originSize.width,self.contentsize.y-180-500-180))

    -- 说明页面
    ui.setLabelString(self.coveritems.tipdes,gameConfig.strings:string_common("buttontext","xinyunzhi"),111)
    self.coveritems.tip:addHandleOfControlEvent(function()
          -- gameWindows:openWindow("tips",{type = "activityshopTip"},nil)
    end, CCControlEventTouchUpInside)
    self.coveritems.tip:setSwallowsTouch(true)
    self.coveritems.tip:setTouchPriority(self.buttontouch)

    --
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","activityblackshop",touchbegin)

    local function touchend(pos)
        if self.coveritems.scrollnode_touch and ui.isTouched(self.coveritems.scrollnode_touch,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","activityblackshop",touchend)
    --

    return self.coverccb
end

function activityshop.setone(self,item,id)
    local key_Ex
    if id == nil or id == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(id-1)
    end
    -- print("numid===",self.data[tostring(id)].id)
    -- printT(gamedata.config.blackmarket_items)

    local configdata = gamedata.config.blackmarket_items[tostring(self.data[tostring(id)].id)]
    -- print("进来几次", self.data[tostring(id)].id, configdata.recommend)
    if not configdata then
        -- print("notid===",self.data[tostring(id)].id)
        return
    end
    -- print("configdata=======")
    -- printT(configdata)
    
    -- local data = self.data.status[tostring(id)]
    local spenddata = ui.getIDandNUMs(configdata.consume) 
    -- print("gooddata=======")
    local gooddata = ui.getIDandNUMs(configdata.good)
    -- printT(gooddata)
    if tonumber(spenddata[1]["cid"]) == 1001 then
        item["goldNode"..key_Ex]:setVisible(true)
        item["coinNode"..key_Ex]:setVisible(false)
    else
        item["coinNode"..key_Ex]:setVisible(true)
        item["goldNode"..key_Ex]:setVisible(false)
    end

    
    ui.setNewIconName(item,{cid = gooddata[1].cid, num = gooddata[1].num},id-1)
    item["i_button"..key_Ex]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        ui.setPopwindowByCid(gooddata[1].cid)
    end, CCControlEventTouchUpInside)
    item["i_button"..key_Ex]:setTouchPriority(self.buttontouch)

    -- item["hotnode"..key_Ex]:setVisible(configdata.hot and configdata.hot == 1)
    -- item["price"..key_Ex]:setString(configdata["price"])
    local aaa = configdata.limit
    local bbb = self.data[tostring(id)].num
    -- print("aaa,bbb===",aaa,bbb)

    if configdata.recommend == 1 then -- 显示推荐
        item["hotnode" .. key_Ex]:setVisible(true)
    else
        item["hotnode" .. key_Ex]:setVisible(false)
    end    
    item["battleNode" .. key_Ex]:setVisible(false) 
    local generalStatus = ui.IDconfig(gooddata[1].cid) or 0
    local generalFrangment = gamedata.config.general_fragment
    if generalStatus.staffType == "general" then
        for k,v in pairs(self.generalTab) do
            if gooddata[1].cid == v then
                -- 显示上阵
                if item["hotnode" .. key_Ex]:isVisible() then
                    item["hotnode" .. key_Ex]:setVisible(false)
                end
                item["battleNode" .. key_Ex]:setVisible(true)
            end
        end
    elseif generalStatus.staffType == "general_fragment" then
        for k,v in pairs(self.generalTab) do
            if generalFrangment[tostring(gooddata[1].cid)] and generalFrangment[tostring(gooddata[1].cid)].general == v then
                -- 显示上阵
                if item["hotnode" .. key_Ex]:isVisible() then
                    item["hotnode" .. key_Ex]:setVisible(false)
                end
                item["battleNode" .. key_Ex]:setVisible(true)
            end
        end
    end    

    ui.setLabelString(item["buyNumText"..key_Ex],nil,14)
    ui.setLabelString(item["buyNumLabel"..key_Ex],configdata.limit-self.data[tostring(id)].num,14)
    ui.setLabelString(item["gold"..key_Ex],spenddata[1]["num"],14)

    ui.setLabelString(item["buttontext"..key_Ex],gameConfig.strings:string_common("buttontext","goumai"),18)

    if self.data[tostring(id)].num < configdata.limit then
        -- print("canbeo===")
        item["soldoutNode"..key_Ex]:setVisible(false)
        ui.removeGray("CCControlButton",item["button"..key_Ex])
        ui.removeGray("CCLabelTTF",item["buttontext"..key_Ex])

        item["button"..key_Ex]:setTouchPriority(self.buttontouch)
        item["button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            --UIRequest({type = 3631,id = id,goodid = self.data[tostring(id)].id})
            local _num = 1
            if spenddata[1].cid and tonumber(spenddata[1].cid) == 1001 then
                if tonumber(spenddata[1].num) > 500 and tonumber(spenddata[1].num) < GameScene.roleinfo.gold then
                    function shopExchangeRequest(num)
                        UIRequest({type = 3631, id = id,goodid = self.data[tostring(id)].id,num = num})            
                    end
                    local exchangeNum = configdata.limit-self.data[tostring(id)].num
                    gameWindows:openWindow("shopExchange",{cid = gooddata[1].cid,num = gooddata[1].num,cost = spenddata,exchangeNum = exchangeNum, ccbtype = 2},shopExchangeRequest)
                else
                    UIRequest({type = 3631, id = id,goodid = self.data[tostring(id)].id,num = _num})
                end
            else
                UIRequest({type = 3631, id = id,goodid = self.data[tostring(id)].id,num = _num})
            end
        end, CCControlEventTouchUpInside)
    else
        -- print("cannotbe===")

        item["soldoutNode"..key_Ex]:setVisible(true)
        ui.addGray("CCControlButton",item["button"..key_Ex])
        ui.addGray("CCLabelTTF",item["buttontext"..key_Ex])

        item["button"..key_Ex]:setTouchPriority(self.buttontouch)
        item["button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","yigoumai")})
        end, CCControlEventTouchUpInside)
    end
end

function activityshop.reloaddata(self,data)
    -- print("reloaddatablack===")
    -- printT(data)
    self:updatetimeFunc()
    
    if not self.show then return end
    self.data = data.data.itemsdata
    self.heishiSton = data.heishiSton
    self.generalTab = data.onGenerals
    self.scrollNode:setVisible(true)
    -- print("reloaddata===")
    -- printT(self.data)
    
    -- 刷新按钮

    -- local globalconfig = gamedata.config.global_kv
    local tempconfig = gamedata.config.buycount_price
    -- printT(tempconfig)
    -- printT(globalconfig)
    
    -- 当重置次数大于配置表所配置的数据时 判断
    local resetnum = data.data.resetnum
    if resetnum > 59 then
        resetnum = 59
    end
    -- 元宝以及数量 初始隐藏
    self.coveritems.resetgoldnode:setVisible(true)

    if self.heishiSton > 0 then
        self.coveritems.goldsprite:setVisible(false)
        self.coveritems.heishisprite:setVisible(true)
        ui.setLabelString(self.coveritems.resetgold,self.heishiSton,18)
    else
        -- print("golddata==",globalconfig.blackmarket_refreshgold)
        self.coveritems.goldsprite:setVisible(true)
        self.coveritems.heishisprite:setVisible(false)
        ui.setLabelString(self.coveritems.resetgold,tempconfig[tostring(resetnum+1)].blackmarket_refreshgold,18)
    end

    ui.setLabelString(self.coveritems.resettext,gameConfig.strings:string_common("buttontext","shuaxin"),19)
    self.coveritems.resetbutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        local refresh = activityshop.refreshJudge()
        -- print("refresh===",refresh)
        


        if not refresh then
            runGamePrompt({msg = "马上就要刷新了，请稍等一会儿"})
            return
        end

        if self.heishiSton <= 0 then
            spendnum = tempconfig[tostring(resetnum+1)].blackmarket_refreshgold
            UIRequest({type = 3632, spendnum = spendnum})
            -- gameWindows:openWindow("blackreset",{data = spendnum})
        else
            UIRequest({type = 3632, spendnum = 0})
        end  

        
    end, CCControlEventTouchUpInside)
    self.coveritems.resetbutton:setSwallowsTouch(true)
    self.coveritems.resetbutton:setTouchPriority(self.buttontouch-1)


    for i=1, 6 do
        self:setone(self.scrollItems,i)
    end
end

function activityshop.refreshJudge( self )
    local refreshconfig = gamedata.config.blackmarket_refresh
    local nowtime = os.date("*t", gamedata:time())

    -- print("refreshstatus==")
    -- printT(nowtime)
    local refreshstatus = true

    for k,v in pairs(refreshconfig) do
        if (nowtime.hour+1) == v.hour and nowtime.min >= 57 then
            refreshstatus = false
            break
        elseif v.hour == 0 and nowtime.hour == 23  and nowtime.min >= 57 then
            refreshstatus = false
            break
        end
    end

    return refreshstatus
end

function activityshop.updatetimeFunc(self)

    local refreshconfig = gamedata.config.blackmarket_refresh
    local refreshArr = {}

    -- print("refreshconfig====")
    -- printT(refreshconfig)
    -- local refreshtimestring = "00:00"
    for k,v in pairs(refreshconfig) do
        if v.hour == 0 then
            v.hour = 24
        end
        print("refreshtimestring==",v.hour)
        table.insert(refreshArr,tonumber(v.hour))
    end

    local sortfunction = function( a, b )
        return a < b
    end
    table.sort( refreshArr, sortfunction )
    -- print("refreshArr====")
    -- printT(refreshArr)




    local nowtime = os.date("*t", gamedata:time())
    -- print("nowtime===")
    -- printT(nowtime)


    -- print("refreshArr====")
    -- printT(refreshArr)

    local addtime = 0

    for i,v in ipairs(refreshArr) do
        -- print(i,v)
        if nowtime.hour < v then
            addtime = v
            break
        end
    end

    local remaintime = addtime*3600-nowtime.hour*3600-nowtime.min*60-nowtime.sec
    -- print("remaintime==",remaintime)

    gameTimer:rigistTime("activity_blackshop", remaintime)
    gameTimer:rigistTimeFunc("activity_blackshop",function()
    
        if gameTimer.times["activity_blackshop"] >= 0 then
            -- ui.setLabelString(self.coveritems.updatetime,ui.makeTimeText(gameTimer.times["activity_blackshop"],"hour"),14)
            -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
        end
        if gameTimer.times["activity_blackshop"] == 0 then
            -- print("activity_blackshop===",0)
            UIRequest({type=3630,update = true})
            gameTimer:UnrigistTimeFunc("activity_blackshop")
        end
    end)
    
end

function activityshop.clear(self)
    -- print("two========")
    gameTouch:UnrigistFunc("begin","activityblackshop")
    gameTouch:UnrigistFunc("end","activityblackshop")

    if self.show then   
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
    end
    if self.scrollNode then
        self.scrollNode = nil
        self.scrollItems = nil
    end

    gameTimer:UnrigistTimeFunc("activity_blackshop")
    self.show = false
    self.data = nil
    self.generalTab = nil
end

-- function activityshop.setPage(self)
--     -- UIRequest({type = 2000,page = GameScene.layers["activity"].module.type})
--     UIRequest({type = 3630}) 
-- end

-- function activityshop.UIUpdateData(self, isreset)
--     if isreset then
--         self.data = nil
--         self.heishiSton = nil
--         self:setPage()
--     end
-- end

return activityshop