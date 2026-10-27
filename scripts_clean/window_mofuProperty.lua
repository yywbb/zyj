--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/12/17
-- Time: 15:52
-- To change this template use File | Settings | File Templates.
--



local mofuproperty = {
    rootNode = nil,
    rootItems = nil,
    callback = nil,
    infodata = {}, --被强化物品信息
    samemofunum = 0,
    canlevelup = true,
}

function mofuproperty.open(self,touchPriority,data,callback)
    print("mofuproperty..open")
    printT(data)
    
    self.rootNode, self.rootItems = CCBReaderLoad("mofu/mofu_info", nil, true, "mofu_info")

    self.touchPriority = touchPriority

    self.callback = callback

    self:reload(data)

    UIRequest({type = 10029,param = "change_gemnum_type",param2 = data.infodata.cid })


    UIRequest({type = 1142,data = data.infodata })

    return self.rootNode
end

function mofuproperty.getSameMofuNum(self,num)
    print("getSameMofuNum==",num)
    if num then
        self.samemofunum = num
    end
    
end

function mofuproperty.slotGemsReload(self,data)
    self.mofuslotdata = data
end

function mofuproperty.setCanLevelUpGemsReload(self,data)

    printT(data,"data=====")
    self.ison = data.ison
    self.canlevelup = data.canlevelup

    -- 设置状态按钮
    -- if self.ison and self.ison ~= 0 then
    --     ui.removeGray("CCControlButton",self.rootItems.levelupBtn)
    --     if self.canlevelup == 0 then 
    --         ui.addGray("CCControlButton",self.rootItems.levelupBtn)
    --     end

    -- else
    --     ui.addGray("CCControlButton",self.rootItems.levelupBtn)
    -- end
end

function mofuproperty.reload(self,data)
    -- if data.canlevelup then
    --     self.canlevelup = data.canlevelup
    -- end
    
    self.infodata = data.infodata
    self.infodata.temp = ui.IDconfig(self.infodata.cid)
    if data.page == "list" then
        self.selectlistdata = data.selectlistdata
        self.rootItems.changeNode:setVisible(false)
        self.rootItems.levelupNode:setPositionX(540)
    elseif data.page == "slot" then
        self.selectlistdata = {}
        for k,v in pairs(data.selectlistdata) do
            v.temp = ui.IDconfig(v.cid)
            if self.infodata.temp.type == v.temp.type and self.infodata.iid ~= v.iid then
                table.insert(self.selectlistdata,v)
            end
        end

        local sortfunc = function( a,b )
            return a.temp.order > b.temp.order
        end
        table.sort(self.selectlistdata,sortfunc)

        self.rootItems.changeNode:setVisible(false)
        self.rootItems.levelupNode:setPositionX(540)
    elseif data.page == "other" then
        self.rootItems.changeNode:setVisible(false)
        self.rootItems.levelupNode:setVisible(false)
        self.rootItems.getNode:setVisible(false)
    elseif data.page == "info" then
        self.rootItems.changeNode:setVisible(false)
        self.rootItems.levelupNode:setVisible(false)
    end


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("mofuproperty")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- 去掉更换功能
    -- ui.setLabelString(self.rootItems.changeText,nil,19)
    -- self.rootItems.changeBtn:addHandleOfControlEvent(function()
    --     -- print("更换魔符")
    --     if self.callback then
    --         self.callback(1)
    --         gameWindows:closeWindowDirect("mofuproperty")
    --     end
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.changeBtn:setSwallowsTouch(true)
    -- self.rootItems.changeBtn:setTouchPriority(self.touchPriority)

    -- printT(self.infodata,"infodata===")
    -- if self.infoself.ison and self.infoself.ison ~= 0 then
    --     ui.removeGray("CCControlButton",self.rootItems.levelupBtn)
    -- else
    --     ui.addGray("CCControlButton",self.rootItems.levelupBtn)
    -- end

    -- if self.infoself.ison and self.infoself.ison ~= 0 then
    --     ui.removeGray("CCControlButton",self.rootItems.levelupBtn)
    --     if self.canlevelup == false then 
    --         ui.addGray("CCControlButton",self.rootItems.levelupBtn)
    --     end

    -- else
    --     ui.addGray("CCControlButton",self.rootItems.levelupBtn)
    -- end

    printT(self.rootItems,"self.rootItems===")
    if self.infodata.type == 6 then
        self.rootItems.levellimitLabel:setVisible(true)

        local levelconfig = gamedata.config.kingofmofu_lv
        -- local propertystrings = "需要外围5个魔符到达"..levelconfig[tostring(self.infodata.level)]["limit_lv"].."级，可升级"
        local propertystrings = gameConfig.strings:string_common("mofulist",10)..levelconfig[tostring(self.infodata.level)]["limit_lv"]..gameConfig.strings:string_common("mofulist",11)

        ui.setLabelString(self.rootItems.levellimitLabel,propertystrings,12)
    else
         self.rootItems.levellimitLabel:setVisible(false)
    end


    ui.setLabelString(self.rootItems.levelupText,nil,19)
    self.rootItems.levelupBtn:addHandleOfControlEvent(function()
        -- print("魔符强化")


        if self.infodata.temp.nextid == 0 then
            -- runGamePrompt({msg = "强化等级已达上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("mofulist",3)})
            return
        end


        -- 不在阵容上 or 魔符之王 周围魔符等级不够的情况
        if self.ison and self.ison ~= 0 then
        else
            -- runGamePrompt({msg = "只有被镶嵌，才能升级"})
            runGamePrompt({msg = gameConfig.strings:string_common("mofulist",9)})
            return
        end


        
        if self.infodata.type == 6 and self.canlevelup == 0 then
            local levelconfig = gamedata.config.kingofmofu_lv
             
            
            -- local propertystrings = "需要外围5个魔符到达"..levelconfig[tostring(self.infodata.level)]["limit_lv"].."级，可升级"
            local propertystrings = gameConfig.strings:string_common("mofulist",10)..levelconfig[tostring(self.infodata.level)]["limit_lv"]..gameConfig.strings:string_common("mofulist",11)
            runGamePrompt({msg = propertystrings})
            return
        end


       
        local infodata = self.infodata
        -- printT(self.mofuslotdata)
        -- print("end====")
        -- printT(self.selectlistdata)
        gameWindows:closeWindowDirect("mofuproperty")

        gameWindows:openWindow("mofulevelup",{mofudata = infodata},nil)

    end, CCControlEventTouchUpInside)
    self.rootItems.levelupBtn:setSwallowsTouch(true)
    self.rootItems.levelupBtn:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.getText,nil,19)
    self.rootItems.getBtn:addHandleOfControlEvent(function()
        -- print("去获取")
        -- if gameTouch.isScrollling then return end
        gameWindows:openWindow("dropTips",{cid = self.infodata.cid,num = self.samemofunum},nil)

    end, CCControlEventTouchUpInside)
    -- self.rootItems.getBtn:setSwallowsTouch(true)
    self.rootItems.getBtn:setTouchPriority(self.touchPriority)


    ui.setLabelString(self.rootItems.titilenameLabel,nil,18)
    


    -- 设置选择个数显示
    self:setProperty()

end

function mofuproperty.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.callback = nil
    self.infodata = {}
    self.samemofunum = 0
    self.canlevelup = true
end



function mofuproperty.setProperty(self)
    -- icon设置
    ui.setNewIcon(self.rootItems,{cid=self.infodata.cid})
    -- 魔符名字
    ui.setLabelString(self.rootItems.nameLabel,self.infodata.temp.name,((self.infodata.temp.quality and self.infodata.temp.quality ~= 0) and self.infodata.temp.quality or 1)*2-1)
    
    local string = ""
    for i=1,4 do
        if tonumber(self.infodata.temp["attr"..i]) ~= 0 and self.infodata.temp["attr"..i] ~= "" then
            if self.infodata.temp["attr"..i] ~= "critical" then
                string =  gameConfig.strings:string_common("attr_type",self.infodata.temp["attr"..i]).."＋"..self.infodata.temp["init"..i] or {}
            else
                string =  gameConfig.strings:string_common("attr_type",self.infodata.temp["attr"..i]).."＋"..(tonumber(self.infodata.temp["init"..i])*100).."%" or {}
            end
            self.rootItems["propertyLabel"..i]:setString(string)
            self.rootItems["propertyLabel"..i]:setVisible(true)
        else
            self.rootItems["propertyLabel"..i]:setVisible(false)
        end
    end


    if self.infodata.temp.nextid == 0 then
        -- ui.setLabelString(self.rootItems.expBarLabel,"已满级",13)
        ui.setLabelString(self.rootItems.expBarLabel,gameConfig.strings:string_common("mofulist",7),13)

        ui.setSpriteTextureRect2(self.rootItems.expProgressBar,0,0,280*(1),36)
        -- 最高等级按钮置灰
        ui.addGray("CCControlButton",self.rootItems.levelupBtn)
    else
        local explablestring = self.infodata.exp.."/"..self.infodata.temp.exp
        ui.setLabelString(self.rootItems.expBarLabel,explablestring,13)
        ui.setSpriteTextureRect2(self.rootItems.expProgressBar,0,0,280*(self.infodata.exp < self.infodata.temp.exp and self.infodata.exp/self.infodata.temp.exp or 1),36)
        
        ui.removeGray("CCControlButton",self.rootItems.levelupBtn)
    end
   
end




return mofuproperty
