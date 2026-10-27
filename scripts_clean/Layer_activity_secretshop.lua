--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:09
-- To change this template use File | Settings | File Templates.
--

--与海外版有差异，海外版刷新次数根据vip限制，刷新时间走配置表

local activity_secretshop = {
    isscrolltouched = false,
    buttontouch = -103,

}

function activity_secretshop.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("tanchuang/shenmishangdian",nil, true, "shenmishangdian")

--    local Gneral = CCSkeletonAnimation:create("mengpo/mengpo.json","mengpo/mengpo.atlas",2)
--    Gneral:setAnimation("stand",true,0)
--    self.coveritems.general:addChild(Gneral)

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    -- self.coveritems.bottomnode:setPositionY(self.contentsize.y-180-500)
    -- self.coveritems.bottomnode:setPositionY((GameScene.topposY-1620)*1+1000 )



    self.coveritems.scrollnode = tolua.cast(self.coveritems.scrollnode, "CCScrollView")
    self.coveritems.scrollnode:setTouchPriority(self.buttontouch)
    -- self.coveritems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    self.coveritems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))

    self.coveritems.container:setContentSize(CCSize(1080,1000))

    self.scrollNode, self.scrollItems = CCBReaderLoad("tanchuang/map1", nil, true, "map1")
    self.scrollNode:setPosition(0,0)
    self.scrollNode:setVisible(false)
    self.coveritems.container:addChild(self.scrollNode)

    self.coveritems.scrollnode:setContentOffsetInDuration(ccp(0,self.contentsize.y-520-462 - 1000),0)

    self.coveritems.scrollnode_touch:setContentSize(CCSize(gameConfig.originSize.width,self.contentsize.y-520-462))

    -- 说明页面
    if self.coveritems.descMoreText then
        -- ui.setLabelString(self.coveritems.descMoreText,nil,14)
    end

    -- ui.setLabelString(self.coveritems.hundanText,nil,150)
    print("text01")
    -- ui.setLabelString(self.coveritems.hundan_Label,nil,31)
    print("text012")
    ui.setLabelString(self.coveritems.refreshText,nil,19)
    print("text013")
    -- ui.setLabelString(self.coveritems.refresh_Label,nil,31)
    print("text014")
    -- ui.setLabelString(self.coveritems.shuaxindescText,nil,150)
    globalconfig = gamedata.config.global_kv
    -- ui.setLabelString(self.coveritems.shuaxindescLabel,globalconfig.mysteryshop_refreshgold.value,150)
    self.coveritems.shuaxindescLabel:setString(globalconfig.mysteryshop_refreshgold.value)

    

    print("text015")

    ui.setLabelString(self.coveritems.gotolianhuaText,nil,18)
    self.coveritems.gotolianhuaBtn:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        print("lianhua")
        GameScene:shiftLayer("qiankunlu","up")
    end, CCControlEventTouchUpInside)
    self.coveritems.gotolianhuaBtn:setSwallowsTouch(true)
    self.coveritems.gotolianhuaBtn:setTouchPriority(self.buttontouch)

    -- ui.setLabelString(self.coveritems.tipdes,gameConfig.strings:string_common("buttontext","xinyunzhi"),111)
    -- self.coveritems.tip:addHandleOfControlEvent(function()
    --       -- gameWindows:openWindow("tips",{type = "activity_secretshopTip"},nil)
    -- end, CCControlEventTouchUpInside)
    -- self.coveritems.tip:setSwallowsTouch(true)
    -- self.coveritems.tip:setTouchPriority(self.buttontouch)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","activity_secretshop",touchbegin)

    local function touchend(pos)
        if self.coveritems.scrollnode_touch and ui.isTouched(self.coveritems.scrollnode_touch,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","activity_secretshop",touchend)
    --

    return self.coverccb
end

function activity_secretshop.updatetimeFunc(self)

    local nowtime = os.date("*t", gamedata:time())
    print("nowtime===")
    -- printT(nowtime)

    local refreshArr = {2,4,6,8,10,12,14,16,18,20,22,24}

    print("refreshArr====")
    -- printT(refreshArr)

    local addtime = 0

    for i,v in ipairs(refreshArr) do
        print(i,v)
        if nowtime.hour < v then
            addtime = v
            break
        end
    end

    local remaintime = addtime*3600-nowtime.hour*3600-nowtime.min*60-nowtime.sec
    print("remaintime==",remaintime)

    gameTimer:rigistTime("activity_secretshop", remaintime)
    gameTimer:rigistTimeFunc("activity_secretshop",function()
    
        if gameTimer.times["activity_secretshop"] >= 0 then
            -- ui.setLabelString(self.coveritems.refresh_Label,ui.makeTimeText(gameTimer.times["activity_secretshop"],"hour"),31)
            self.coveritems.refresh_Label:setString(ui.makeTimeText(gameTimer.times["activity_secretshop"],"hour"))
            -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
        end
        if gameTimer.times["activity_secretshop"] == 0 then
            print("activity_secretshop===",0)
            UIRequest({type=3650,update = true})
            print("removeUpdata====1111")
            gameTimer:UnrigistTimeFunc("activity_secretshop")
        end
    end)
    
end


function activity_secretshop.setone(self,item,id)
    local key_Ex
    if id == nil or id == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(id-1)
    end
    -- print("item==id=") 
    -- printT(self.data.itemsdata[tostring(id)])
    local configdata = gamedata.config.mystery_shop[tostring(self.data.itemsdata[tostring(id)].id)]
    print("configdata=======")
    -- printT(configdata)
    if not configdata then
        print("notid===",self.data.itemsdata[tostring(id)].id)
        return
    end
    
    -- local data = self.data.status[tostring(id)]
    local spenddata = ui.getIDandNUMs(configdata.consume) 
    -- printT(spenddata)
    print("gooddata=======")
    local gooddata = ui.getIDandNUMs(configdata.good)
    -- printT(gooddata)
    if tonumber(spenddata[1]["cid"]) == 1001 then
        item["goldNode"..key_Ex]:setVisible(true)
        item["hundanNode"..key_Ex]:setVisible(false)
        ui.setLabelString(item["buttontext"..key_Ex],gameConfig.strings:string_common("buttontext","goumai"),18)
    else
        item["hundanNode"..key_Ex]:setVisible(true)
        item["goldNode"..key_Ex]:setVisible(false)
        ui.setLabelString(item["buttontext"..key_Ex],gameConfig.strings:string_common("buttontext","duihuan"),18)
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
    local bbb = self.data.itemsdata[tostring(id)].num
    -- print("aaa,bbb===",aaa,bbb)

    if configdata.recommend == 1 then  -- 显示推荐
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

    -- ui.setLabelString(item["buyNumText"..key_Ex],nil,14)
    -- ui.setLabelString(item["buyNumLabel"..key_Ex],configdata.limit-self.data.itemsdata[tostring(id)].num,14)
    item["buyNumLabel"..key_Ex]:setString(configdata.limit-self.data.itemsdata[tostring(id)].num)
    ui.setLabelString(item["gold"..key_Ex],spenddata[1]["num"],14)
    -- item["buyNumLabel"..key_Ex]:setString(configdata.limit-self.data.itemsdata[tostring(id)].num)
    -- item["gold"..key_Ex]:setString(spenddata[1]["num"])


    if self.data.itemsdata[tostring(id)].num < configdata.limit then
        print("canbeo===")
        item["soldoutNode"..key_Ex]:setVisible(false)
        ui.removeGray("CCControlButton",item["button"..key_Ex])
        ui.removeGray("CCLabelTTF",item["buttontext"..key_Ex])

        item["button"..key_Ex]:setTouchPriority(self.buttontouch)
        item["button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 3651,id = id,goodid = self.data.itemsdata[tostring(id)].id,num = 1})

            -- function shopExchangeRequest(num)
            --     UIRequest({type = 3651, id = id,goodid = self.data.itemsdata[tostring(id)].id,num = num})            
            -- end
            -- local exchangeNum = configdata.limit-self.data.itemsdata[tostring(id)].num
            -- gameWindows:openWindow("shopExchange",{cid = gooddata[1].cid,num = gooddata[1].num,cost = spenddata,exchangeNum = exchangeNum},shopExchangeRequest)
       
        end, CCControlEventTouchUpInside)
    else
        print("cannotbe===")

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

function activity_secretshop.reloadData(self,data)

    if not self.show then return end

    self.data = data.data
    self.datafirst = data
    self.generalTab = data.onGenerals
    self.scrollNode:setVisible(true)
    print("reloaddata===")
    -- printT(self.data)
    self:updatetimeFunc()

    
    local spendtype = {}
    -- ui.setLabelString(self.coveritems.hundan_Label,data.hundanNum,31)
    self.coveritems.hundan_Label:setString(data.hundanNum)
    if self.data.freshnum ~= 0 then
        spendtype = "free"
        self.coveritems.freeNumNode:setVisible(true)
        self.coveritems.spendGoldNode:setVisible(false)
        self.coveritems.spendlingpaiNode:setVisible(false)

        ui.setLabelString(self.coveritems.freeNumText,nil,14)
        ui.setLabelString(self.coveritems.freeNum_Label,self.data.freshnum,23)
    elseif self.data.freshnum == 0 and data.lingpaiNum ~= 0 then
        spendtype = "lingpai"
        self.coveritems.freeNumNode:setVisible(false)
        self.coveritems.spendGoldNode:setVisible(false)
        self.coveritems.spendlingpaiNode:setVisible(true)

        ui.setLabelString(self.coveritems.spendlingpaiText,nil,13)
        ui.setLabelString(self.coveritems.spendlingpai_Label,data.lingpaiNum,23)
    elseif self.data.freshnum == 0 and data.lingpaiNum == 0 then
        spendtype = "gold"
        self.coveritems.freeNumNode:setVisible(false)
        self.coveritems.spendGoldNode:setVisible(true)
        self.coveritems.spendlingpaiNode:setVisible(false)

        local globalconfig = gamedata.config.global_kv

        ui.setLabelString(self.coveritems.spendGoldText,nil,14)
        ui.setLabelString(self.coveritems.spendGold_Label,globalconfig.mysteryshop_refreshgold.value,14)
    end

    -- lingpaiNum
    -- spendGoldNode
    -- ui.setLabelString(self.coveritems.spendGoldText,nil,14)
    -- ui.setLabelString(self.coveritems.spendGold_Label,nil,14)

    -- freeNumNode
    -- ui.setLabelString(self.coveritems.freeNumText,nil,14)
    -- ui.setLabelString(self.coveritems.freeNum_Label,nil,23)

    -- spendlingpaiNode
    -- ui.setLabelString(self.coveritems.spendlingpaiText,nil,14)
    -- ui.setLabelString(self.coveritems.spendlingpai_Label,nil,23)

    
    -- 刷新按钮

    -- ui.setLabelString(self.coveritems.resettext,gameConfig.strings:string_common("buttontext","shuaxin"),19)
    self.coveritems.resetbutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        -- local refresh = activity_secretshop.refreshJudge()
        -- local refresh = false
        -- print("refresh===",refresh)
        -- if not refresh then
        --     runGamePrompt({msg = "马上就要刷新了，请稍等一会儿"})
        --     return
        -- end
        print("spendtype==",spendtype)
        UIRequest({type = 3652,spend = spendtype})
    end, CCControlEventTouchUpInside)
    self.coveritems.resetbutton:setSwallowsTouch(true)
    self.coveritems.resetbutton:setTouchPriority(self.buttontouch-1)


    for i=1, 6 do
        self:setone(self.scrollItems,i)
    end
end

function activity_secretshop.clear(self)
            print("removeUpdata====2222")

    gameTouch:UnrigistFunc("begin","activity_secretshop")
    gameTouch:UnrigistFunc("end","activity_secretshop")
    gameTimer:UnrigistTimeFunc("activity_secretshop")
    if self.coverccb then
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
    end

    if self.scrollNode then
        self.scrollNode = nil
        self.scrollItems = nil
    end
    
    self.show = false
    self.data = nil
    self.generalTab = nil
end

-- function activity_secretshop.setPage(self)
--     -- UIRequest({type = 2000,page = GameScene.layers["activity"].module.type})
--     UIRequest({type = 3650}) 
-- end

-- function activity_secretshop.UIUpdateData(self, isreset)
--     if isreset then
--         self.data = nil
--         self.datafirst = nil
--         self:setPage()
--     end
-- end

return activity_secretshop