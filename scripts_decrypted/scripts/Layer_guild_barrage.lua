

local guildbarrage = {
    rootNode = nil,
    rootItems = nil,

    rolling = 0,   --当前弹幕数
    topposY = 0,   

    rollingLimit = 10,   --弹幕上限
    nodescalemin = 95,   
    nodescalemax = 110,  --随机大小

    color = {"red", "green", "purple"},
    desFontIds = {
        red = 1017, 
        green = 1016, 
        purple = 1018,
    },
    nameFontIds = {
        red = 1020, 
        green = 1019, 
        purple = 1021,
    },

    touchPriority = gameConfig.touchPriority.barrage,
}


function guildbarrage.init(self,parent,topposY)
    self.rootItems = parent
    self.topposY = topposY
    -- self:setBarrage({name = "哥哥", desc = "逼逼赖赖1"})
end

function guildbarrage.setBarrage(self,barragedata)
    if self.rolling >= self.rollingLimit then   -- 达当前滚动上限
        return
    end
    local colorid = ui.randomFromTable(self.color,1)
    local fontIDTable = {}

    local richTable = {}
    if not barragedata.type then
        if barragedata.name then
            table.insert(richTable, {fontID = self.nameFontIds[colorid], content = barragedata.name})
            table.insert(richTable, {fontID = self.desFontIds[colorid], content = " : "})
        end

        if barragedata.desc then
            table.insert(richTable, {fontID = self.desFontIds[colorid], content = barragedata.desc})
        end
    else
        local curChatContent = barragedata.chats["1"].content
        local curChatPlayer = barragedata.players["1"]
        local curChatContent,params = self:cheackBarrageType(curChatContent)
        self.curChatPlayer = curChatPlayer
        self.params = params

        local contentTable = ui.StringToTable(curChatContent)
        local newtContentTable = {}
        local unCheck = {}
        local idx = 1
        for i = 1, #contentTable do
            if not unCheck[i] then
                local _str = contentTable[i]
                if not newtContentTable[idx] then
                    newtContentTable[idx] = {}
                    newtContentTable[idx].type = "text"
                    newtContentTable[idx].content = "" 
                end
                if _str == "[" then
                    local isName = false
                    local _name = ""
                    local nameIdx = 0
                    for ii = i + 1, #contentTable do
                        if contentTable[ii] == "]" then
                            isName = true
                            nameIdx = ii
                            break
                        else
                            _name = _name .. contentTable[ii]
                        end
                    end
                    if isName then
                        for ii = i + 1, nameIdx do
                            unCheck[ii] = true
                        end
                        idx = idx + 1
                        newtContentTable[idx] = {}
                        newtContentTable[idx].type = "name"
                        newtContentTable[idx].content = _name
                        idx = idx + 1
                    end
                else
                    if not newtContentTable[idx] then
                        newtContentTable[idx] = {}
                        newtContentTable[idx].type = "text"
                        newtContentTable[idx].content = "" 
                    end
                    newtContentTable[idx].content = newtContentTable[idx].content .. _str
                end
            end
        end

        print("------newtContentTable-----")
        printT(newtContentTable)

        if params[1] ~= "4" then --升星
            table.insert(richTable, {fontID = self.nameFontIds[colorid], content = curChatPlayer.name})
            table.insert(richTable, {fontID = self.desFontIds[colorid], content = " : "})   
        end

        for i = 1, #newtContentTable do
            if newtContentTable[i].type == "name" then
                table.insert(richTable, {fontID = self.nameFontIds[colorid], content = newtContentTable[i].content})
            else
                table.insert(richTable, {fontID = self.desFontIds[colorid], content = newtContentTable[i].content})
            end
        end
    end

    if self.rolling < self.rollingLimit then   -- 未达当前滚动上限
        self:showOne(richTable,colorid)
    end
end

-- 筛选显示弹幕
function guildbarrage.showOne(self,data,colorid)
    if guide.controller and guide.controller.isOnGuide then return end
    local node, items = CCBReaderLoad("barrage/cell_"..colorid , nil, true, "cell_"..colorid)
    local offsetY, offsetX = ui.createRichLabel(data, items.richNode, false, {horizontal = "left", vertical = "center"})
    local headWidth = items.head:getContentSize().width
    local tailWidth = items.tail:getContentSize().width
    local tailPosX = 0 + headWidth
    local bodyNum = math.ceil(offsetX / 24)
    for i = 1, bodyNum do
        local tmpSprite = CCSprite:create("barrage/publicsprite4/" .. colorid .. "_body.png")
        tmpSprite:setAnchorPoint(ccp(0,0))
        tmpSprite:setPosition(headWidth + (i - 1) * 24, 0)
        items.bodyNode:addChild(tmpSprite)
        tailPosX = tailPosX + 24
    end
    items.tail:setPositionX(tailPosX)
    items.richNode:setPositionX(headWidth)

    local btn_gotowidth= items.btn_goto:getContentSize().width
    items.btn_goto:setScaleX((tailPosX + tailWidth + 50) / btn_gotowidth)

    local nodescale = math.random(self.nodescalemin,self.nodescalemax)
    nodescale = nodescale*0.01
    node:setScale(nodescale)   -- 大小随机


    local randomY = math.random(250, self.topposY-300)
    print(gameConfig.d_viewSize.height.."=====setBarrage===="..randomY)
    node:setPosition(100, randomY)
    self.rootItems.barragenode:addChild(node)
    self.rolling = self.rolling + 1 

    local time = math.random(7,10)
    --local sizeW = node:getContentSize().width*nodescale
    local sizeW = (offsetX + headWidth + tailWidth + 100) * nodescale
    local moveTo = CCMoveTo:create(time, ccp(-1080-sizeW, node:getPositionY()))

    local seq = CCSequence:createWithTwoActions(moveTo, CCCallFunc:create(function()
        self.rolling = self.rolling - 1
        node:removeFromParentAndCleanup(true)
    end))
    node:runAction(seq)

    ui.commonBtn(self,items,"btn_goto",function()
        if self.curChatPlayer.rid == GameScene.roleinfo.id then   --自己的弹幕
            return
        end

        if self.params[1] == "4" then
            gameWindows:openWindow(
                "confirm",
                {msg = "是否查看"..self.curChatPlayer.name.."的阵容"},
                function ()
                    GameScene:addtempLayers("other_slotinfo",self.curChatPlayer)
                end
            )
            return
        end

        if self.params[1] == "1" and self.params[3] then   --公会盛宴
            if GameScene.layers["guildfeast"].show then
                runGamePrompt({msg = "正处在公会盛宴中"})
                return
            end
            local feast = tonumber(self.params[3])
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 2272, roomid = feast, controltype = 1})
            -- gameWindows:openWindow(
            --     "confirm",
            --     {msg = "是否前往"..self.curChatPlayer.name.."举办的"..(gamedata.config.gang2_feast_type[tostring(feast)] and gamedata.config.gang2_feast_type[tostring(feast)].name or "公会盛宴")},
            --     function ()
            --         gameTouch:clickprofbytime(0.5)
            --         UIRequest({type = 2267, roomid = feast, controltype = 1})
            --     end
            -- )
            return
        end

        if self.params[1] == "2" and self.params[3] then   --boss战场
            local roomid = tonumber(self.params[3])
            if GameScene.layers["bossfield_map"].show or GameScene.layers["bossfield"].show then
                return
            end
            if gameConfig:checkBuildOpen(574) and GameScene:checkopenlevelbyId(574) then
                gameWindows:openWindow(
                    "confirm",
                    {msg = "是否前往boss战场"},
                    function ()
                        gameTouch:clickprofbytime(0.5)
                        local roomid = tonumber(self.params[3])
                        UIRequest({type = 7830, open = 1, room = roomid})
                    end
                )
            end    
            return
        end

        if self.params[1] == "6" and self.params[3] then   --公会篝火
            if GameScene.layers["gang_xianchi2"].show then
                runGamePrompt({msg = "正处在公会篝火中"})
                return
            end
            local guildbath = tonumber(self.params[3])
            if guildbath and guildbath > 0 then
                gameTouch:clickprofbytime(0.5)
                UIRequest({type = 2282, roomid = guildbath, controltype = 1})
            end
            return
        end

        if self.params[1] == "8" then   --观星
            gameWindows:openWindow(
                "confirm",
                {msg = "是否帮助"..self.curChatPlayer.name .. "增加换星次数"},
                function ()
                    gameTouch:clickprofbytime(0.5)
                    UIRequest({type = 2069, ids = self.curChatPlayer.rid , build = 31})
                end
            )
        end

        if self.params[1] == "10" then   --极乐岛
            gameWindows:openWindow(
                "confirm",
                {msg = "是否帮助"..self.curChatPlayer.name .. "增加极乐岛骰子"},
                function ()
                    gameTouch:clickprofbytime(0.5)
                    UIRequest({type = 2069, ids = self.curChatPlayer.rid , build = 22})
                end
            )
        end

        if self.params[1] == "11" then   --地狱副本
            gameWindows:openWindow(
                "confirm",
                {msg = "是否帮助"..self.curChatPlayer.name .. "增加地狱副本的产量"},
                function ()
                    gameTouch:clickprofbytime(0.5)
                    UIRequest({type = 2069, ids = self.curChatPlayer.rid , build = 19})
                end
            )
        end
    end,self.touchPriority) 
end

function guildbarrage.cheackBarrageType(self,destContent)
    local str = destContent
    local params = {}
    local fuhao = "&"
    local k = string.find(destContent, fuhao, 0)
    if k == nil then
        return str,params
    else
        local fid = string.sub(destContent,k+1, string.len(destContent))
        local params = string.split(fid, ",")
        str = string.sub(destContent,0,k-1)
        return str,params
    end
end

return guildbarrage

 *  