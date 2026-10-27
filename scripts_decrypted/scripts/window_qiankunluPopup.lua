--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/12/17
-- Time: 15:52
-- To change this template use File | Settings | File Templates.
--



local window_qiankunluPopup = {
    rootNode = nil,
    rootItems = nil,
}

function window_qiankunluPopup.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.data = data
    print("window_qiankunluPopup.open")
    if data.index == "lianhua" then
        self.rootNode, self.rootItems = CCBReaderLoad("qiankunlu/lianhua_rule", nil, true, "lianhua_rule")
        self:lianhuaReload()
    elseif data.index == "chongsheng" then
        self.rootNode, self.rootItems = CCBReaderLoad("qiankunlu/chongsheng_rule", nil, true, "chongsheng_rule")
        self:chongshengReload()
    elseif data.index == "huahun" then
        self.rootNode, self.rootItems = CCBReaderLoad("qiankunlu/huahun_rule", nil, true, "huahun_rule")
        self:huahunReload()
    elseif data.index == "queren" then
        self.rootNode, self.rootItems = CCBReaderLoad("qiankunlu/tc_queren", nil, true, "tc_queren")
        self:querenReload(self.data, callback)
    elseif data.index == "fenjie" then
        self.rootNode, self.rootItems = CCBReaderLoad("qiankunlu/fenjie_rule", nil, true, "fenjie_rule")
        self:lianhuaReload()    
    end
    
    self.root:addChild(self.rootNode)

    return self.root
end



function window_qiankunluPopup.lianhuaReload(self)
    
    self.rootItems.closelhButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("qiankunluPopup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closelhButton:setSwallowsTouch(true)
    self.rootItems.closelhButton:setTouchPriority(self.touchPriority)
end

function window_qiankunluPopup.chongshengReload(self)
    
    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("qiankunluPopup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0, 580-1900),0)
    self.rootItems.infoTxt:setString(gamedata.config:getConfigByName("system_intro")["82"].intro)
end

function window_qiankunluPopup.huahunReload(self)
    
    self.rootItems.closehhButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("qiankunluPopup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closehhButton:setSwallowsTouch(true)
    self.rootItems.closehhButton:setTouchPriority(self.touchPriority)
end


function window_qiankunluPopup.querenReload(self,data,callback)
    print("querenReload==")
    -- printT(data)
    ui.setLabelString(self.rootItems.yesLab,nil,19)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        if callback then
            callback()
        end
        gameWindows:closeWindow("qiankunluPopup")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.noLab,nil,19)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("qiankunluPopup")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("qiankunluPopup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    local str = self:ctRichLabel()
    print("str===")
    -- printT(str)
    local container = CCNode:create()
    container:setAnchorPoint(ccp(0,1))
    container:setContentSize(CCSizeMake(800,200))
    self.sizeT = {
        height = ui.createRichLabel(str,container,false)+100,
        container = container
    }

    self.rootItems.descNode:addChild(container)
end

function window_qiankunluPopup.ctRichLabel(self)
    local pagestring = {}
    local endstring = {}
    if self.data.page == "lianhua" then
        pagestring = "您要炼化的是"

        if self.data.labeltype == "generalFragment" then
            endstring = "是否炼化？"
        elseif self.data.labeltype == "equip" then
            endstring = "是否炼化？"
        elseif self.data.labeltype == "treasure" then
            endstring = "是否炼化？"
        end

    elseif self.data.page == "chongsheng" then
        pagestring = "您要重生的是"

        if self.data.basic then
            endstring = "重生当前伙伴,"
        else
            endstring = "确定要重生吗？"
        end

        if self.data.labeltype == "exclusiveArtifact" then
            local str = {}
            table.insert(str,{fontID = 48, content = pagestring})

            local exclusiveArtifact = self.data.data[1]
            local exclusiveArtifactConfig = ui.IDconfig(exclusiveArtifact.cid)

            local generalName = ""
            for k,v in pairs(gamedata.config.general) do
                if v.exclusive and v.exclusive == exclusiveArtifact.cid then
                    generalName = v.name
                    break
                end
            end
            table.insert(str,{fontID = 47, content = generalName})
            table.insert(str,{fontID = 48, content = "专属神器"})
            table.insert(str,{fontID = 213, content = "【"..exclusiveArtifactConfig.name.."】"})
            table.insert(str,{fontID = 48, content = "，重生会卸下所有器灵，确定要重生吗？"})

            return str
        end


    elseif self.data.page == "huahun" then
        pagestring = "您要化魂的是"
        endstring = "确定要化魂吗？"
    elseif self.data.page == "fenjie" then
        pagestring = "您要分解的是"
        endstring = "确定要分解吗？"
    end

    local labeltype = {}
    if self.data.labeltype == "generalFragment" then
        labeltype = "伙伴或魂魄 "
    elseif self.data.labeltype == "equip" then
        labeltype = "装备或装备碎片 "
    elseif self.data.labeltype == "treasure" then
        labeltype = "宝物或宝物碎片 "
    elseif self.data.labeltype == "general" then
        labeltype = "伙伴 "
    elseif self.data.labeltype == "pet" then
        labeltype = "魔宠 "
    elseif self.data.labeltype == "artifact" then
        labeltype = "神器 "
    elseif self.data.labeltype == "redfragment" then
        labeltype = "伙伴精华 "
    end
    
    local str = {}

    table.insert(str,{fontID = 48, content = pagestring})
    if self.data.labeltype == "redfragment" then 
        table.insert(str,{fontID = 11, content = " 红色品质 "})
    else
        table.insert(str,{fontID = 9, content = (self.data.labeltype == "pet" and " 稀有 " or " 橙色以上品质 ")})
    end
    table.insert(str,{fontID = 48, content = labeltype})

    for k,v in pairs(self.data.data) do
        local dataconfig = ui.IDconfig(v.cid)
        print("name====",dataconfig.name)
        -- printT(dataconfig)
        local strtemp = "["..dataconfig.name.."]，"

        if self.data.labeltype == "redfragment" then 
            table.insert(str,{fontID = 11, content = strtemp})
        elseif dataconfig.quality and dataconfig.quality > 6 then
            table.insert(str,{fontID = 213, content = strtemp})
        elseif dataconfig.quality and dataconfig.quality > 5 then
            table.insert(str,{fontID = 11, content = strtemp})
        else    
            table.insert(str,{fontID = 9, content = strtemp})
        end
    end

    
    if self.data.basic then
        local _str = ""

        if self.data.basic == 18 then
            _str = gameConfig.strings:string_common("godSoulTemple", "pageName", 1)
        elseif self.data.basic == 20 then
            _str = gameConfig.strings:string_common("godSoulTemple", "pageName", 2)
        elseif self.data.basic == 23 then
            _str = gameConfig.strings:string_common("godSoulTemple", "pageName", 3)
        end
        table.insert(str,{fontID = 11, content = _str.."会降级并降低属性"})
    end

    if self.data.page == "chongsheng" then
        local general = self.data.data[1]
        if self.data.labeltype == "general" and general.quality and general.quality >= 7 and general.exclusiveArtifactCid and general.exclusiveArtifactCid > 0 then
            table.insert(str,{fontID = 11, content = "，该伙伴专属神器会失效且卸下所有器灵。"})
        end
    end

    table.insert(str,{fontID = 48, content = endstring})
   
    return str
end


function window_qiankunluPopup.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

end


return window_qiankunluPopup
�$  