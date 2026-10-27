--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:09
-- To change this template use File | Settings | File Templates.
--

local activityshop = {
    isscrolltouched = false,
    buttontouch = -103,

}

function activityshop.init(self,size)
    print("one========")
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("tanchuang/duobaoshangdian",nil, true, "duobaoshangdian")

    local Gneral = CCSkeletonAnimation:create("mengpo/mengpo.json","mengpo/mengpo.atlas",2)
    Gneral:setAnimation("stand",true,0)
    self.coveritems.general:addChild(Gneral)

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    -- self.coveritems.bottomnode:setPositionY((GameScene.topposY-1620)*1+1000)

    

    self.coveritems.scrollnode = tolua.cast(self.coveritems.scrollnode, "CCScrollView")
    self.coveritems.scrollnode:setTouchPriority(self.buttontouch)
    -- self.coveritems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    self.coveritems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-500-180))

    self.coveritems.container:setContentSize(CCSize(1080,1000))

    self.scrollNode, self.scrollItems = CCBReaderLoad("tanchuang/map3", nil, true, "map3")
    self.scrollNode:setPosition(0,0)

    self.coveritems.container:addChild(self.scrollNode)

    self.coveritems.scrollnode:setContentOffsetInDuration(ccp(0,self.contentsize.y-180-500-180 - 1000),0)

    self.coveritems.scrollnode_touch:setContentSize(CCSize(gameConfig.originSize.width,self.contentsize.y-180-500-180))

    -- 去夺宝页面
    ui.setLabelString(self.coveritems.gotoText,nil,18)
    self.coveritems.gotoBtn:addHandleOfControlEvent(function()
        print("it..is..gotoBtn")
        
        GameScene:shiftLayerById(25)

    end, CCControlEventTouchUpInside)
    self.coveritems.gotoBtn:setSwallowsTouch(true)
    self.coveritems.gotoBtn:setTouchPriority(self.buttontouch)


    ui.setLabelString(self.coveritems.dbpointText,nil,14)
    ui.setLabelString(self.coveritems.dbpointLabel,nil,14)
    print("init...end")

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","robshop",touchbegin)

    local function touchend(pos)
        if self.coveritems.scrollnode_touch and ui.isTouched(self.coveritems.scrollnode_touch,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","robshop",touchend)
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

    local configdata = gamedata.config.rob_shop[tostring(id)]
    if not configdata then
        print("notid===",self.data[tostring(id)].id)
        return
    end
    print("configdata=======")
    -- printT(configdata)
    
    -- local data = self.data.status[tostring(id)]
    local spenddata = ui.getIDandNUMs(configdata.consume) 
    -- printT(spenddata)
    print("gooddata=======")
    local gooddata = ui.getIDandNUMs(configdata.good)
    -- printT(gooddata)
    if tonumber(spenddata[1]["cid"]) == 1001 then
        item["goldNode"..key_Ex]:setVisible(true)
        item["duobaoNode"..key_Ex]:setVisible(false)
    else
        item["duobaoNode"..key_Ex]:setVisible(true)
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
    print("aaa,bbb===",aaa,bbb)

    ui.setLabelString(item["buyNumText"..key_Ex],nil,14)
    ui.setLabelString(item["buyNumLabel"..key_Ex],self.data[tostring(id)].buynum,14)
    ui.setLabelString(item["gold"..key_Ex],spenddata[1]["num"],14)

    ui.setLabelString(item["buttontext"..key_Ex],nil,18)

    if self.data[tostring(id)].buynum > 0 then
        print("canbeo===")
        item["soldoutNode"..key_Ex]:setVisible(false)
        ui.removeGray("CCControlButton",item["button"..key_Ex])
        ui.removeGray("CCLabelTTF",item["buttontext"..key_Ex])

        item["button"..key_Ex]:setTouchPriority(self.buttontouch)
        item["button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end

            UIRequest({type = 3661,id = id,goodid = self.data[tostring(id)].cid})
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
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","shouqing")})
        end, CCControlEventTouchUpInside)
    end
end

function activityshop.reloaddata(self,data)
    -- self:updatetimeFunc()
    
    if not self.show then return end
    self.data = data.data.itemsdata

 
    ui.setLabelString(self.coveritems.dbpointLabel,data.diaobaoCoin,14)
    -- self.heishiSton = data.heishiSton
    print("reloaddata===")
    -- printT(self.data)
    
    for i=1, 6 do
        self:setone(self.scrollItems,i)
    end
end



function activityshop.clear(self)
    gameTouch:UnrigistFunc("begin","robshop")
    gameTouch:UnrigistFunc("end","robshop")
    print("two========")
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
end


return activityshop