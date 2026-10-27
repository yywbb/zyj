--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/30
-- Time: 上午10:10
-- To change this template use File | Settings | File Templates.
--

local zhuxiantaiboss = {
    rootNode = nil,
    rootItems = nil,
}

function zhuxiantaiboss.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuxiantai2/zhuxiantai_zhenrong", nil, true, "slotarrange")

    self.touchPriority = touchPriority

    self:reload(data,callback)

    return self.rootNode
end

function zhuxiantaiboss.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("zhuxiantaiboss")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems["allstar"]:setString("X "..data.mieshendian.star or "")
    self.rootItems["xnumall"]:setString("X 0")

    local attrconfig = gamedata.config.mieshendian_attr[tostring(data.mieshendian.floor)] or {}
    for i = 1,3 do
        self.rootItems["desc"..i]:setString(attrconfig["desc"..i] or "")
        self.rootItems["xnum"..i]:setString("X "..attrconfig["star"..i] or "")
    end
    --
    local select = { [1] = 0, [2] = 0, [3] = 0, }

    local function setLabColor()
        for i = 1,3 do
            if select[i] == 1 then
                self.rootItems["desc"..i]:setColor(ccc3(249,208,88))
            elseif (select[1]*attrconfig["star1"]+select[2]*attrconfig["star2"]+select[3]*attrconfig["star3"]+attrconfig["star"..i]) > data.mieshendian.star+0 then
                self.rootItems["desc"..i]:setColor(ccc3(146,146,146))
            else
                self.rootItems["desc"..i]:setColor(ccc3(255,255,255))
            end
        end
    end

    setLabColor()

    for i = 1,3 do
        self.rootItems["selected"..i]:setVisible(select[i] == 1 and true or false)

        self.rootItems["select"..i]:addHandleOfControlEvent(function()

            if select[i] == 0 and (select[1]*attrconfig["star1"]+select[2]*attrconfig["star2"]+select[3]*attrconfig["star3"]+attrconfig["star"..i]) > data.mieshendian.star+0 then
                runGamePrompt({msg = "累计星数不够"})
            else
                select[i] = (select[i] == 1) and 0 or 1
                self.rootItems["selected"..i]:setVisible(select[i] == 1 and true or false)
                self.rootItems["xnumall"]:setString("X "..(select[1]*attrconfig["star1"]+select[2]*attrconfig["star2"]+select[3]*attrconfig["star3"]))
                self.rootItems["allstar"]:setString("X "..(data.mieshendian.star-(select[1]*attrconfig["star1"]+select[2]*attrconfig["star2"]+select[3]*attrconfig["star3"])))
                setLabColor()
            end
        end, CCControlEventTouchUpInside)
        self.rootItems["select"..i]:setSwallowsTouch(true)
        self.rootItems["select"..i]:setTouchPriority(self.touchPriority)

    end

    --
    local monster = gamedata.config.mieshendian_monster_param[tostring(data.mieshendian.floor)]["1"] or {}
    for i=1,7 do
        if monster["p"..i] and monster["p"..i] > 0 then
            self.rootItems["d_general"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems,{cid = monster["p"..i] },i+6)
            self.rootItems["i_button_"..i+6]:addHandleOfControlEvent(function()
                gameWindows:openWindow("zhuxiantaibosstips",{cid = monster["p"..i], level = monster["level"] },nil)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button_"..i+6]:setSwallowsTouch(true)
            self.rootItems["i_button_"..i+6]:setTouchPriority(self.touchPriority)

        else
            self.rootItems["d_general"..i]:setVisible(false)
        end
    end


    local requesttable = {}
    local postable = {}

    --
    local generalsdata = {}
    if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
        generalsdata = table.copy(GameScene.layers["generals"].module.generalsdata)
    end

    for i=1,7 do
        if data.slots[tostring(i)] and data.slots[tostring(i)].generalcid then
            -- 设置头像
            local generalData = data.slots[tostring(i)]
            local configGeneral = gamedata.config.general[tostring(generalData.generalcid)]
            local selsecData = {}
            for k,v in pairs(generalsdata) do
                local cid = v.illusionGeneralCid or v.cid
                if generalData.generalcid == cid then
                    selsecData = v
                    break
                end
            end
            if next(selsecData) then
                if selsecData.illusionGeneralCid then
                    local gdata = ui.getConfigGeneralSion(selsecData)
                    if next(gdata) and configGeneral.fashion_id == 0 then
                        ui.setNewIcon(self.rootItems,{cid = data.slots[tostring(i)].generalcid },i-1,nil,gdata)
                    else
                        ui.setNewIcon(self.rootItems,{cid = data.slots[tostring(i)].generalcid },i-1)
                    end
                else
                    local gdata = ui.getConfigGeneral(selsecData)
                    if next(gdata) and configGeneral.fashion_id == 0 then
                        ui.setNewIcon(self.rootItems,{cid = data.slots[tostring(i)].generalcid },i-1,nil,gdata)
                    else
                        ui.setNewIcon(self.rootItems,{cid = data.slots[tostring(i)].generalcid },i-1)
                    end
                end
            else
                ui.setNewIcon(self.rootItems,{cid = data.slots[tostring(i)].generalcid },i-1)
            end
            --

            postable[i] = {x = self.rootItems["general"..i]:getPositionX(),y = self.rootItems["general"..i]:getPositionY()}
            requesttable[i] = i
            self.rootItems["general"..i]:setVisible(true)
        else
            self.rootItems["general"..i]:setVisible(false)
        end
    end

    local touchedGeneral = nil

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchlayer,x,y) then
            for k,v in pairs(requesttable) do
                if self.rootItems["general"..v]:isVisible() and ui.isTouched(self.rootItems["general"..v],x,y) then
                    print(k,v)
                    touchedGeneral = {node = self.rootItems["general"..v], sid = k,touchx = x, touchy = y }
                    touchedGeneral.node:setZOrder(1)
                    return true
                end
            end
        end
    end

    local function ccTouchMoved(x, y)
        if touchedGeneral then
            touchedGeneral.node:setPosition(postable[touchedGeneral.sid].x+x-touchedGeneral.touchx,postable[touchedGeneral.sid].y+y-touchedGeneral.touchy)
        end
    end

    local function ccTouchEnded(x, y)
        if touchedGeneral then
            local haschange = false
            for k,v in pairs(requesttable) do
                if k ~= touchedGeneral.sid and self.rootItems["general"..v]:isVisible() and ui.iscontendbynode(self.rootItems["general"..v],touchedGeneral.node:getPositionX(),touchedGeneral.node:getPositionY()) then
                    haschange = true
                    print(v,touchedGeneral.sid)
                    local moveto =  CCMoveTo:create(0.2, ccp(postable[k].x,postable[k].y))
                    touchedGeneral.node:runAction(moveto)
                    local moveto2 =  CCMoveTo:create(0.2, ccp(postable[touchedGeneral.sid].x,postable[touchedGeneral.sid].y))
                    self.rootItems["general"..v]:runAction(moveto2)
                    local postemp = requesttable[k]
                    requesttable[k] = requesttable[touchedGeneral.sid]
                    requesttable[touchedGeneral.sid] = postemp
                    --                    touchedGeneral.node:setPosition(postable[i].x,postable[i].y)
                    --                    self.rootItems["general"..i]:setPosition(postable[touchedGeneral.sid].x,postable[touchedGeneral.sid].y)
                    break
                end
            end
            if not haschange then
                local moveto2 =  CCMoveTo:create(0.2, ccp(postable[touchedGeneral.sid].x,postable[touchedGeneral.sid].y))
                touchedGeneral.node:runAction(moveto2)
            end
            touchedGeneral.node:setZOrder(0)
            touchedGeneral = nil
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

    self.rootItems.touchlayer:registerScriptTouchHandler(onTouch, false, self.touchPriority, false)
    self.rootItems.touchlayer:setTouchPriority(self.touchPriority)
    self.rootItems.touchlayer:setTouchEnabled(true)
    --

    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("zhuxiantaiboss")
        UIRequest({type = 3622,select = select, arrange = requesttable})
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
end

function zhuxiantaiboss.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return zhuxiantaiboss   �&  