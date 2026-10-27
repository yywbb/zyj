--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/6
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local artifactOpenPos = {
    rootNode = nil,
    rootItems = nil,
    props = nil,
    useProps = {},
    centerP = {x = 540,y = 280}
}

function artifactOpenPos.open(self,touchPriority,data,callback)

    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/tc_xiangqian", nil, true, "tc_xiangqian")
    self:initFixedString()
    self.touchPriority = touchPriority

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactOpenPos")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.noButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactOpenPos")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    self.rootItems.yesButton:addHandleOfControlEvent(function()
        if self.artifact["jewel"..self.pos] < 0 then
            gameTouch:clickprofbytime(1)
            UIRequest({type = 5504,iid = self.artifact.iid,pos = self.pos})
        else
            if not self.props then
                return
            end
            for k,v in ipairs(self.useProps) do
                if v.cid == self.artifact["jewel"..self.pos] then
                    local jewelData = GameScene.layers["artifactList"].module.jewelData.primeData
                    local haveN = jewelData[tostring(v.cid)] and jewelData[tostring(v.cid)].num or 0
                    if haveN + 1 < v.num then
                        return runGamePrompt({msg = gameConfig.strings:string_common("artifact",54)})
                    end
                else
                    if not self.props[tostring(v.cid)] or self.props[tostring(v.cid)] < v.num then
                        local idConfig = ui.IDconfig(v.cid)
                        return runGamePrompt({msg = gameConfig.strings:string_format({"fixedStringA",82},{idConfig.name})})
                    end
                end
            end
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 5506,cid = self.artifact["jewel"..self.pos],iid = self.artifact.iid,pos = self.pos})
        end
        gameWindows:closeWindow("artifactOpenPos")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

    self:reload(data,callback)

    return self.rootNode
end

function artifactOpenPos.initFixedString(self)
    ui.setLabelString(self.rootItems.noLab,gameConfig.strings:string_common("buttontext","fanhui"),19)
    ui.setLabelString(self.rootItems.yesLab,gameConfig.strings:string_common("buttontext","queding"),19)
end

function artifactOpenPos.reload(self,data,callback)
    self.callback = callback
    self.artifact = data.artifact
    self.pos = data.pos

    local config = gamedata.config.trump[tostring(self.artifact.cid)]
    local useTable
    if data.artifact["jewel"..self.pos] > 0 then
        local jewelCid = data.artifact["jewel"..self.pos]
        local jewelConfig = gamedata.config.trump_gem[tostring(jewelCid)]
        
        useTable = ui.getIDandNUMs(jewelConfig.gem_lv)
    else
        useTable = ui.getIDandNUMs(config["hole_cost"..self.pos])
    end
    
    self.useProps = useTable
    local anS = " "
    local toS = 0
    for k,v in pairs(useTable) do
        local itemCconfig = ui.IDconfig(v.cid)
        local idname = itemCconfig.name
        if v.cid == data.artifact["jewel"..self.pos] then
            anS = anS..gameConfig.strings:string_format({"artifact",136},{v.num - 1,idname}).." "
        else
            anS = anS..gameConfig.strings:string_format({"artifact",105},{v.num,idname}).." "
        end
       
        ui.setNewIconName(self.rootItems,{cid=v.cid},toS)
        local key_E = toS == 0 and "" or "_"..toS
        self.rootItems["i_button"..key_E]:setTouchPriority(self.touchPriority)
        self.rootItems["i_button"..key_E]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(v.cid)
        end, CCControlEventTouchUpInside)

        self.rootItems["getBtn"..key_E]:addHandleOfControlEvent(function()
            gameWindows:openWindow("dropTips",{cid = v.cid},nil)
        end, CCControlEventTouchUpInside)
        self.rootItems["getBtn"..key_E]:setSwallowsTouch(true)
        self.rootItems["getBtn"..key_E]:setTouchPriority(self.touchPriority)
        toS = toS + 1
        
    end
    if #useTable > 0 then
        self.rootItems.tipNode:setVisible(true)
        self.rootItems.tipStr2:setVisible(false)
        if data.artifact["jewel"..self.pos] > 0 then
            self.rootItems.tipStr1:setString(gameConfig.strings:string_format({"artifact",140},{anS}))
        else
            self.rootItems.tipStr1:setString(gameConfig.strings:string_format({"artifact",21},{anS}))
        end
        if #useTable == 1 then
            self.rootItems.tipNode2:setVisible(false)
            self.rootItems.tipNode1:setPositionX(self.centerP.x)
        end
    else
        self.rootItems.tipNode:setVisible(false)
        self.rootItems.tipStr2:setVisible(true)
        self.rootItems.tipStr2:setString(gameConfig.strings:string_common("artifact",70))
    end
    if #useTable > 0 then
        self:getUseIdNum()
    end
end

function artifactOpenPos.getUseIdNum(self,t)
    self.props = t or self.props
    if not self.props then
        local cids = {}
        for k,v in ipairs(self.useProps) do
            if v.cid ~= self.artifact["jewel"..self.pos] then
                cids[#cids + 1] = v.cid
            end
        end
        UIRequest({type = 12001, order = 33016, cids = cids})
        return
    end
    for k,v in ipairs(self.useProps) do
        local key_E = k == 1 and "" or "_"..(k - 1)
        if v.cid == self.artifact["jewel"..self.pos] then
            local jewelData = GameScene.layers["artifactList"].module.jewelData.primeData
            local haveN = jewelData[tostring(v.cid)] and jewelData[tostring(v.cid)].num or 0
            local labeN = haveN + 1 >= v.num and 13 or 27
            ui.setLabelString(self.rootItems["in_name"..key_E],""..haveN.."/"..(v.num - 1),labeN)
        else
            local labeN = self.props[tostring(v.cid)] >= v.num and 13 or 27
            ui.setLabelString(self.rootItems["in_name"..key_E],""..self.props[tostring(v.cid)].."/"..v.num,labeN)
        end
    end
end

function artifactOpenPos.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.props = nil
    self.artifact = nil
    self.useProps = {}
    if self.callback then
        self.callback()
    end
    self.callback = nil
end


return artifactOpenPos