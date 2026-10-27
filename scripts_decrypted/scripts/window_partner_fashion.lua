
local partner_fashion = {
    rootNode = nil,
    rootItems = nil,
    scrollNode = nil,
    scrollItems = nil,
    scroll_animationManager = nil,
    index = 1,

    data = {},

    general_iid = 0,  --当前武将iid
    general_cid = 0,  --当前武将cid
    partner_id = 0,   --武将时装对应武将id 
    fashion_id = 0,   --武将时装id
    fashionlist = {},

    partnerfashion = {},

    ccbext = {
    [1] = {"_4"},
    [2] = {"_3","_5"},
    [3] = {"_2","_6"},
    [4] = {"_1","_7"},
    [5] = {"","_8"},
    },

}

function partner_fashion.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("wujiangshizhuang/tc_wujiangshizhuang", nil, true, "wujiangshizhuang")
    self.touchPriority = touchPriority
    self.callback = callback

    self.data = data
    self.general_iid = data and data.iid or 0
    self.general_cid = data and data.cid or 0

    if data and data.opt and data.opt == 2 then
        if self.rootItems.optNode then
            self.rootItems.optNode:setVisible(false)
        end    
    end    

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(980,560))
    self.rootItems.container:setContentSize(CCSize(980,560))
    --
    self.scrollNode, self.scrollItems = CCBReaderLoad("wujiangshizhuang/shizhuanginfo_zhuan", nil, true, "shizhuanginfo_zhuan")
    self.scrollNode:setPosition(490,280)
    self.rootItems.container:addChild(self.scrollNode)
    self.scroll_animationManager = getAnimationManager(self.scrollItems)
    --
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("partner_fashion")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)
    --
    ui.setLabelString(self.rootItems.title,nil,14)
    ui.setLabelString(self.rootItems.fixstr1,nil,14)
    --
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y           
            return true
        end
    end

    local function ccTouchMoved(x, y)
        
    end

    local function ccTouchEnded(x, y)
        if self.touchX-x > 30 then
            if self.index < #self.fashionlist then
                self.index = self.index+1
                gameTouch:clickprofbytime(0.5)
                self.scroll_animationManager:runAnimationsForSequenceNamed((self.index-1).."-"..self.index)
                --todo datashow
                self:setpage()
            end 
        elseif x-self.touchX > 30 then  
            if self.index > 1 then
                self.index = self.index-1
                gameTouch:clickprofbytime(0.5)
                self.scroll_animationManager:runAnimationsForSequenceNamed((self.index+1).."-"..self.index)
                --todo datashow
                self:setpage()
            end    
        elseif ui.isTouched(self.rootItems.leftButton,x,y) then
            if self.index > 1 then
                self.index = self.index-1
                gameTouch:clickprofbytime(0.5)
                self.scroll_animationManager:runAnimationsForSequenceNamed((self.index+1).."-"..self.index)
                --todo datashow
                self:setpage()
            end    
        elseif ui.isTouched(self.rootItems.rightButton,x,y) then
            if self.index < #self.fashionlist then
                self.index = self.index+1
                gameTouch:clickprofbytime(0.5)
                self.scroll_animationManager:runAnimationsForSequenceNamed((self.index-1).."-"..self.index)
                --todo datashow
                self:setpage()
            end    
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
    --
    UIRequest({type = 10023})
    self:reloadgeneral(data)
    --

    return self.rootNode
end

function partner_fashion.reloadgeneral(self,data)
    printT(data,"jkp-data2")
    self.general_cid = data and data.cid
    local general_Data = data and data.general or {}
    if general_Data == nil then
        print("时装界面")
    end
    
    local generalConfig = gamedata.config.general[tostring(self.general_cid)] or {}
    if generalConfig.partner_id and generalConfig.partner_id > 0 then
        -- 时装对应的武将id
        self.partner_id = generalConfig.partner_id
    else
        -- 武将id
        self.partner_id = self.general_cid
    end
    --
    if generalConfig.fashion_id and generalConfig.fashion_id > 0 then
        -- 时装id
        self.fashion_id = generalConfig.fashion_id
    else
        -- 皮肤id
        local g_fashion = generalConfig.quality
        if general_Data.g_fashion and (general_Data.g_fashion > 0 and general_Data.g_fashion < 10) then
            g_fashion = general_Data.g_fashion
        end
        self.fashion_id = g_fashion
    end
    --
    self.fashionlist = {}
    local gdata = gamedata.config.general[tostring(self.partner_id)] or {} --展示的武将信息
    if gdata.quality and gdata.quality == 7 then --金
        local initGeneral = gamedata.config.general[tostring(gdata.init_cid)] or {}
        if initGeneral.quality and initGeneral.quality == 5 then --初始橙将
            table.insert(self.fashionlist,{cid = gdata.init_cid, showpartner = gdata.init_cid, fashion_id = 5, sort = 0})
            table.insert(self.fashionlist,{cid = gdata.red_id, showpartner = gdata.red_id, fashion_id = 6, sort = 0})
            table.insert(self.fashionlist,{cid = self.partner_id, showpartner = self.partner_id, fashion_id = 7, sort = 0})
        elseif initGeneral.quality and initGeneral.quality == 6 then --初始红将
            table.insert(self.fashionlist,{cid = gdata.init_cid, showpartner = gdata.init_cid, fashion_id = 6, sort = 0})
            table.insert(self.fashionlist,{cid = self.partner_id, showpartner = self.partner_id, fashion_id = 7, sort = 0})
        end
    elseif gdata.quality and gdata.quality == 6 then --红
        local initGeneral = gamedata.config.general[tostring(gdata.init_cid)] or {}
        if initGeneral.quality and initGeneral.quality == 5 then --初始橙将
            table.insert(self.fashionlist,{cid = gdata.init_cid, showpartner = gdata.init_cid, fashion_id = 5, sort = 0})
            table.insert(self.fashionlist,{cid = self.partner_id, showpartner = self.partner_id, fashion_id = 6, sort = 0})
            table.insert(self.fashionlist,{cid = gdata.gold_id, showpartner = gdata.gold_id, fashion_id = 7, sort = 0})
        elseif initGeneral.quality and initGeneral.quality == 6 then --初始红将
            table.insert(self.fashionlist,{cid = self.partner_id, showpartner = self.partner_id, fashion_id = 6, sort = 0})
            table.insert(self.fashionlist,{cid = gdata.gold_id, showpartner = gdata.gold_id, fashion_id = 7, sort = 0})
        end
    elseif gdata.quality and gdata.quality == 5 then --橙
        table.insert(self.fashionlist,{cid = self.partner_id, showpartner = self.partner_id, fashion_id = 5, sort = 0})
        if gdata.break_id and gdata.break_id > 0 then
            table.insert(self.fashionlist,{cid = gdata.break_id, showpartner = gdata.break_id, fashion_id = 6, sort = 0})
            table.insert(self.fashionlist,{cid = gamedata.config.general[tostring(gdata.break_id)].gold_id, showpartner = gamedata.config.general[tostring(gdata.break_id)].gold_id, fashion_id = 7, sort = 0})
        end
    end
    
    for k,v in pairs(gamedata.config.partner_fashion) do
        if v.orange_partner2 and v.orange_partner2 > 0 and v.orange_partner2 == self.partner_id then
            v.showpartner = v.orange_partner
            table.insert(self.fashionlist,v)
        elseif v.red_partner2 and v.red_partner2 > 0 and v.red_partner2 == self.partner_id then 
            v.showpartner = v.red_partner
            table.insert(self.fashionlist,v)
        elseif v.gold_partner2 and v.gold_partner2 > 0 and v.gold_partner2 == self.partner_id then 
            v.showpartner = v.gold_partner
            table.insert(self.fashionlist,v)
        end
    end    
    --
    local sortfunc = function (a,b)
        if a["sort"] == a["sort"] then
            return a.fashion_id < b.fashion_id
        else
            return a["sort"]< a["sort"]
        end    
    end
    table.sort(self.fashionlist,sortfunc)

    printT(self.fashionlist,"fashionlist")
    --
    self.index = 1
    for i,v in ipairs(self.fashionlist) do
        if v.fashion_id and v.fashion_id == self.fashion_id then
            self.index = tonumber(i)
        end    
    end
    --
    for i = 1,5 do
        if i <= #self.fashionlist then
            if self.scrollItems["node"..i.."_1"] then
                self.scrollItems["node"..i.."_1"]:setVisible(true)
            end    
            if self.scrollItems["node"..i.."_2"] then
                self.scrollItems["node"..i.."_2"]:setVisible(true)
            end    
            --
            local partner = self.fashionlist[i] or {}
            local showgeneral = gamedata.config.general[tostring(partner.showpartner)]
            for k,v in pairs(self.ccbext[i]) do
                setSpriteFrameByName(self.scrollItems["shizhuang_sprite"..v],showgeneral.fashion_image~="" and showgeneral.fashion_image or "alpha")
                ui.setLabelString(self.scrollItems["shizhuang_name"..v],partner.name or showgeneral.name,14)
                local g_data = {}
                g_data.general = {}
                g_data.general.cid = partner.showpartner
                g_data.general.skill = {}
                if showgeneral.skillid and showgeneral.skillid >0 then
                    g_data.general.skill.cid = showgeneral.skillid or 0
                elseif showgeneral.special_skill_reveal and showgeneral.special_skill_reveal >0 then
                    g_data.general.skill.cid = showgeneral.special_skill_reveal or 0
                end
                if showgeneral.combskillid and showgeneral.combskillid > 0 then
                    g_data.general.combskill = {}
                    g_data.general.combskill.cid = showgeneral.combskillid
                end
                --skill1
                if g_data.general.skill.cid and g_data.general.skill.cid > 0 then
                    self.scrollItems["skill1"..v]:setVisible(true)
                    local skillconfig = ui.IDconfig(g_data.general.skill.cid) or {} 
                    ui.setLabelString(self.scrollItems["skill1_name"..v],skillconfig.name or "",skillconfig.quality and 2*skillconfig.quality or 0)
                    setSpriteFrameByName(self.scrollItems["skill1_icon"..v], skillconfig.icon or "alpha")
                    setSpriteFrameByName(self.scrollItems["skill1_kuang"..v], "b_iconk"..(skillconfig.quality or 1))
                    --
                    self.scrollItems["skill1_button"..v]:addHandleOfControlEvent(function()
                        gameWindows:openWindow("generalInfoSkill",{data = g_data ,sid = 1, pagetype = "skillinfo",skilltype = "skill" })
                    end, CCControlEventTouchUpInside)
                    self.scrollItems["skill1_button"..v]:setSwallowsTouch(true)
                    self.scrollItems["skill1_button"..v]:setTouchPriority(self.touchPriority)
                else    
                    self.scrollItems["skill1"..v]:setVisible(false)
                end 
                --skill2
                if showgeneral.combskillid and showgeneral.combskillid > 0 then
                    self.scrollItems["skill2"..v]:setVisible(true)
                    local skillconfig = ui.IDconfig(showgeneral.combskillid) or {} 
                    ui.setLabelString(self.scrollItems["skill2_name"..v],skillconfig.name or "",skillconfig.quality and 2*skillconfig.quality or 0)
                    setSpriteFrameByName(self.scrollItems["skill2_icon"..v], skillconfig.icon or "alpha")
                    setSpriteFrameByName(self.scrollItems["skill2_kuang"..v], "b_iconk"..(skillconfig.quality or 1))
                    --
                    self.scrollItems["skill2_button"..v]:addHandleOfControlEvent(function()
                        gameWindows:openWindow("generalInfoSkill",{data = g_data ,sid = 1, pagetype = "skillinfo",skilltype = "combskill" })
                    end, CCControlEventTouchUpInside)
                    self.scrollItems["skill2_button"..v]:setSwallowsTouch(true)
                    self.scrollItems["skill2_button"..v]:setTouchPriority(self.touchPriority)
                else    
                    self.scrollItems["skill2"..v]:setVisible(false)
                end   
                --
                --hint
                if self.scrollItems["shizhuang_hint"..v] then
                    if getPartnerfashionOnceFromSqlite(partner.fashion_id) == 1 then
                        self.scrollItems["shizhuang_hint"..v]:setVisible(true)
                    else
                        self.scrollItems["shizhuang_hint"..v]:setVisible(false)
                    end    
                    -- -- 皮肤红点
                    -- if getPartnerfashionOnceFromSqlite(g_data.general.cid) == 1 then
                    --     self.scrollItems["shizhuang_hint"..v]:setVisible(true)
                    -- else
                    --     self.scrollItems["shizhuang_hint"..v]:setVisible(false)
                    -- end    
                end  
                -- 不显示拥有
                if self.data and self.data.opt and self.data.opt == 2 then
                    if self.scrollItems["shizhuang_has"..v] then
                        self.scrollItems["shizhuang_has"..v]:setVisible(false)
                    end
                end
            end    
        else
            if self.scrollItems["node"..i.."_1"] then
                self.scrollItems["node"..i.."_1"]:setVisible(false)
            end    
            if self.scrollItems["node"..i.."_2"] then
                self.scrollItems["node"..i.."_2"]:setVisible(false)
            end    
        end    
    end    

    --
    gameTouch:clickprofbytime(1)
    UIRequest({type = 6911})

end


function partner_fashion.reload(self,data)

    if data and data.partnerfashion then
        self.partnerfashion = table.copy(data.partnerfashion)
    end    

    local gndata = gamedata.config.general[tostring(self.partner_id)] or {}
    for i = 1,6 do
        if self.fashionlist[i] then
            local hasstr = "未拥有"
            if self.fashionlist[i].fashion_id and (self.fashionlist[i].fashion_id == 5 or self.fashionlist[i].fashion_id == 6 or self.fashionlist[i].fashion_id == 7) then
                if self.fashionlist[i].fashion_id <= gndata.quality then
                    hasstr = "已拥有"
                end
            elseif self.partnerfashion[tostring(self.fashionlist[i].fashion_id)] and self.partnerfashion[tostring(self.fashionlist[i].fashion_id)].time ~= 0 then
                hasstr = "已拥有"
            end
            for k,v in pairs(self.ccbext[i]) do
                self.scrollItems["shizhuang_has"..v]:setString(hasstr)
            end  
        end  
    end    

    --todo
    gameTouch:clickprofbytime(0.5)
    self.scroll_animationManager:runAnimationsForSequenceNamed(tostring(self.index))
    self:setpage()
    --

end

function partner_fashion.setpage(self,data)
    print("self.index == ",self.index)
    local fashiondata = table.copy(self.fashionlist[self.index] or {})
    printT(fashiondata,"jkp-fashiondata")
    if fashiondata.fashion_id and fashiondata.fashion_id > 0 then
        self.rootItems.attr1:setString(fashiondata.instructions or "")
    else    
        self.rootItems.attr1:setString("")
    end
 
    local gndata = gamedata.config.general[tostring(self.partner_id)] or {}
    if self.fashion_id == fashiondata.fashion_id then
        --已装备
        self.rootItems.fashion_ison:setVisible(true)
        self.rootItems.doNode:setVisible(false)
        --
        ui.setLabelString(self.rootItems.doLab,"装 备",19)
        self.rootItems.doButton:addHandleOfControlEvent(function()

        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority-1)
    elseif (fashiondata.fashion_id <= gndata.quality) or  (self.partnerfashion[tostring(fashiondata.fashion_id)] and self.partnerfashion[tostring(fashiondata.fashion_id)].time ~= 0) then  
        --已拥有
        self.rootItems.fashion_ison:setVisible(false)
        self.rootItems.doNode:setVisible(true)
        --
        ui.setLabelString(self.rootItems.doLab,"装 备",19)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            local fashionId = fashiondata.fashion_id
            local configGeneral = gamedata.config.general[tostring(self.general_cid)]
            if configGeneral.partner_id and configGeneral.partner_id > 0 then
            else
                if configGeneral.quality == fashionId then
                    fashionId = self.general_cid
                end
            end
            print("fashionId == ",fashionId)
            UIRequest({type = 6912,iid = self.general_iid, id = fashionId or 0})
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority-1)
    else
        --未拥有
        self.rootItems.fashion_ison:setVisible(false)
        self.rootItems.doNode:setVisible(true)
        --
        ui.setLabelString(self.rootItems.doLab,"去获取",19)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            --GameScene:shiftLayerById(443)
            if fashiondata.fashion_id == 5 or fashiondata.fashion_id == 6 or fashiondata.fashion_id == 7 then
                gameWindows:openWindow("dropTips",{cid = fashiondata.cid },nil)
            else
                gameWindows:openWindow("dropTips",{cid = fashiondata.fashion_id },nil)
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority-1)
    end
    
    --hint
    local oldhint = getPartnerfashionOnceFromSqlite(fashiondata.fashion_id)
    savePartnerfashionOnceToSqlite(fashiondata.fashion_id,0)
    --
    for k,v in pairs(self.ccbext[self.index]) do
        if self.scrollItems["shizhuang_hint"..v] then
            self.scrollItems["shizhuang_hint"..v]:setVisible(false) 
        end  
    end 
    --
    if oldhint == 1 then 
        if GameScene.layers["partnerfashion_collect"].show then
            GameScene.layers["partnerfashion_collect"].module:reloaddata()
        end
        --
        GameScene.ext_hint_slotfashion = 0
        --
        UIRequest({type = 10021})   
    end

end

function partner_fashion.close(self)
    self.data = {}

    self.partnerfashion = {}
    self.general_iid = 0
    self.general_cid = 0
    self.fashionlist = {}
    self.partner_id = 0
    self.fashion_id = 0

    self.index = 1

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.scrollNode = nil
    self.scrollItems = nil
    self.scroll_animationManager = nil

    if self.callback then
        self.callback()
    end
end

return partner_fashion

<P  