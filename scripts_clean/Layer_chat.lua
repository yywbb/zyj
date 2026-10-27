--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/1/6
-- Time: 16:34
-- To change this template use File | Settings | File Templates.
--
local chat_manager = require"window_chat_manager"

local chat = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    worldListTableView = nil,
    guildListTableView = nil,
    broadcastListTableView = nil,

    pageconfig = {"world","guild","broadcast"} ,
    -- pagename = {"世界","公会","系统"},
    pagename = {gameConfig.strings:string_common("chat",0),gameConfig.strings:string_common("chat",1),gameConfig.strings:string_common("chat",10)},
    selectpage = "world",

    input = nil,
    playerdata = {},
    chatdata = {},
    sizeT = {},
    totalT = 0,
    selfdata = {rid = 0,name = "???",vip = 1,level = 1,profile = 10101},
    guildplayerdata = {},
    guildchatdata = {},
    guildsizeT = {},
    guildtotalT = 0,

    broadcastplayerdata = {},
    broadcastchatdata = {},
    broadcastsizeT = {},
    broadcasttotalT = 0,

    listheight = 0,
    hasnewguildchat = false,
    guildoffSetY = 0,
    hasnewworldchat = false,
    worldoffSetY = 0,
    chat_freenum = 0,
    labanum = 0,

    hasnewbroadcastchat = false,
    broadcastoffSetY = 0,

    gangid = 0,

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {39},
                title2 = {266},
                title3 = {267},
            },
        },
    },

    isscrolltouched = false,
}


function chat.removehint(self)
    if self.selectpage ==  "world" then
        UIRequest({type = 10321,ids = {39}})
    elseif self.selectpage ==  "guild" then
        UIRequest({type = 10321,ids = {266}})
    elseif self.selectpage ==  "broadcast" then
        UIRequest({type = 10321,ids = {267}})
    end
end

function chat.shiftPage(self,type,notcheck)
    self.selectpage = type
    if type ==  "world" then
        UIRequest({type = 10321,ids = {39}})
        self.rootItems.listworld:setPositionX(0)
        self.rootItems.listguild:setPositionX(-9999)
        self.rootItems.listbroadcast:setPositionX(-9999)
        if self.rootItems.worldnum then
           self.rootItems.worldnum:setVisible(true)
        end
        if self.rootItems.inputchatnode then
            self.rootItems.inputchatnode:setVisible(true)
        end
    elseif type ==  "guild" then
        UIRequest({type = 10321,ids = {266}})
        self.rootItems.listworld:setPositionX(-9999)
        self.rootItems.listguild:setPositionX(0)
        self.rootItems.listbroadcast:setPositionX(-9999)
        if self.rootItems.worldnum then
            self.rootItems.worldnum:setVisible(false)
        end
        if self.rootItems.inputchatnode then
            self.rootItems.inputchatnode:setVisible(true)
        end
        if notcheck then
            print("prepare")
        elseif self.gangid <= 0 then
            -- runGamePrompt({msg = "未加入公会"})
            runGamePrompt({msg = gameConfig.strings:string_common("chat",5)})
        end
    elseif type ==  "broadcast" then
        UIRequest({type = 10321,ids = {267}})
        self.rootItems.listworld:setPositionX(-9999)
        self.rootItems.listguild:setPositionX(-9999)
        self.rootItems.listbroadcast:setPositionX(0)
        if self.rootItems.worldnum then
            self.rootItems.worldnum:setVisible(false)
        end
        if self.rootItems.inputchatnode then
            self.rootItems.inputchatnode:setVisible(false)
        end
    end
end


function chat.init(self,parent,toppos,data)
    self.rootNode,self.rootItems = CCBReaderLoad("chat/chat01", nil, true, "chat")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    local chatlevel = gamedata.config.global_kv.chat_level and tonumber(gamedata.config.global_kv.chat_level.value) or 10

    if GameScene.roleinfo.level>=chatlevel then
        self.rootItems.profButton:removeFromParentAndCleanup(true)
    else
        self.rootItems.profButton:addHandleOfControlEvent(function()
             runGamePrompt({msg = gameConfig.strings:chatlevel(chatlevel)})
        end, CCControlEventTouchUpInside)
        self.rootItems.profButton:setSwallowsTouch(true)
        self.rootItems.profButton:setTouchPriority(-105)
    end

    self.rootItems.backButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer(GameScene.priorLayer,"up")
    end, CCControlEventTouchUpInside)
    self.rootItems.backButton:setSwallowsTouch(true)
    self.rootItems.backButton:setTouchPriority(-105)

    self.rootItems.cancelButton:addHandleOfControlEvent(function()
        
        GameScene:shiftLayer("friends","up",{curType="shield"})

    end, CCControlEventTouchUpInside)
    self.rootItems.cancelButton:setSwallowsTouch(true)
    self.rootItems.cancelButton:setTouchPriority(-105)
    

    self.listheight = toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-140

    self.rootItems.listworld:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-140))
    self.rootItems.listguild:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-140))
    self.rootItems.listbroadcast:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-140))

    ui.setLabelString(self.rootItems.chatLab,nil,18)

    self:createlistbroadcast()
    self:createlistguild()
    self:createlistworld()

    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","chat",touchbegin)
    local function touchend(pos)
        if self.rootItems.listworld and ui.isTouched(self.rootItems.listworld,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.listguild and ui.isTouched(self.rootItems.listguild,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.listbroadcast and ui.isTouched(self.rootItems.listbroadcast,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","chat",touchend)

    self:setChat()

    UIRequest({type = 2230, param = "chat"})   -- 公会
    UIRequest({type = 1031})
    UIRequest({type = 3000, opt = 1})
    UIRequest({type = 3010, opt = 1})
    UIRequest({type = 3015, opt = 1})
    --
    if data and data.page then
        self:shiftPage(data.page,true)
    else
        self:shiftPage("world")
    end
end

function chat.clear(self)
    gameTouch:UnrigistFunc("begin","chat")
    gameTouch:UnrigistFunc("end","chat")    
    self.isscrolltouched = false
    self.rootItems = nil
    self.worldListTableView = nil
    self.guildListTableView = nil
    self.broadcastListTableView = nil
    self.selectpage = "world"

    self.input = nil
    self.chatdata = {}
    self.playerdata = {}
    self.sizeT = {}
    self.totalT = 0
    self.selfdata = {rid = 0,name = "???",vip = 1,level = 1,profile = 10101 }
    self.guildplayerdata = {}
    self.guildchatdata = {}
    self.guildsizeT = {}
    self.guildtotalT = 0

    self.broadcastplayerdata = {}
    self.broadcastchatdata = {}
    self.broadcastsizeT = {}
    self.broadcasttotalT = 0

    self.listheight = 0
    self.hasnewbroadcastchat = false
    self.broadcastoffSetY = 0
    self.hasnewguildchat = false
    self.guildoffSetY = 0
    self.hasnewworldchat = false
    self.worldoffSetY = 0
    self.chat_freenum = 0
    self.labanum = 0
    self.gangid = 0

--    if gameTimer.times["UserChat"] then
--        gameTimer:UnrigistTimeFunc("UserChat")
--    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end


function chat.getSizeTable(self,chats)
    local label = ui.createLabel({
        fontsize = 46,
        font = "Helvetica-Bold",
    })

    local sizeTable = {}
    local totalheight = 0

    for i=1, table.getTableLength(chats) do
        label:setString(chats[tostring(i)].content)
        local height = label:getContentSize().height
        local width = label:getContentSize().width

        if width > 700 then
            sizeTable[tostring(i)] = {w = 730, h = math.ceil(width/700)*height+20}
        else
            local tmpContent = chats[tostring(i)].content
            local tmpLen = string.len(tmpContent)
            if self:cheackIsEmoji(tmpContent,tmpLen) ~= 0 then
                sizeTable[tostring(i)] = {w = width+10, h = 200}
            else
                sizeTable[tostring(i)] = {w = width+10, h = height+20}
            end
        end
        totalheight = totalheight + sizeTable[tostring(i)].h +120
    end

    return sizeTable,totalheight
end

function chat.setChat(self)
    local inputcontent = ""
    local beginFunc = function()
        inputcontent = ""
    end

    local endFunc = function(text)
        inputcontent = text
    end

    local chatlevel = gamedata.config.global_kv.chat_level and tonumber(gamedata.config.global_kv.chat_level.value) or 10
    local PlaceHolder = GameScene.roleinfo.level>=chatlevel and gameConfig.strings:string_common("chat",2) or gameConfig.strings:chatlevel(chatlevel)

    self.input = ui.creatInputEditBoxByNode(self.rootItems.inputnode, kEditBoxInputModeAny, beginFunc, endFunc,
        {
            fontSize = 46,
            -- PlaceHolder = "点击输入聊天内容，最多20字",
            PlaceHolder = PlaceHolder,
            length = 100,
            fontColor = ccc3(255,255,255),
            PlaceholderFontColor = ccc3(200,200,200),
        }
    )
    self.input:setTouchPriority(-103)


--    local timefunc = function()
--        if gameTimer.times.UserChat and gameTimer.times.UserChat ==0 then
--
--            if self.selectpage == "world" then
--                UIRequest({type = 3000})
--            elseif self.selectpage == "guild" then
--                UIRequest({type = 3010})
--            elseif self.selectpage == "broadcast" then
--                UIRequest({type = 3015})
--            end
--
--            gameTimer:rigistTime("UserChat",2)
--        end
--    end
--    gameTimer:rigistTime("UserChat",2)
--    gameTimer:rigistTimeFunc("UserChat",timefunc)

    self.rootItems.chatButton:addHandleOfControlEvent(function()
        if gameTimer.times["chattimelimite"] and  gameTimer.times["chattimelimite"] >0 then
            runGamePrompt({msg = gameConfig.strings:string_common("chat",9)})
        else
            if inputcontent == "" then
                -- runGamePrompt({msg = "请输入发言"})
                runGamePrompt({msg = gameConfig.strings:string_common("chat",3)})
            else

                if self.selectpage == "world" then

                    if gamedata.config.global_kv.world_chat_power then
                        if tonumber(gamedata.config.global_kv.world_chat_power.value) ~= -1  then
                            if GameScene.roleinfo.power < tonumber(gamedata.config.global_kv.world_chat_power.value) then
                                runGamePrompt({msg = "战力需达到"..gamedata.config.global_kv.world_chat_power.value.."才可发言"})
                                inputcontent = ""
                                self.input:setText("")
                                return
                            end
                        end
                    end

                    if self.chat_freenum > 0 then
                        UIRequest({type = 3001, content = inputcontent})
                        gameTimer:rigistTime("chattimelimite",3)
                    elseif self.labanum > 0 then
                        UIRequest({type = 3001, content = inputcontent, labaopt = 1})
                        gameTimer:rigistTime("chattimelimite",3)
                    else
                        -- runGamePrompt({msg = "传音符不够,无法发言"})
                        runGamePrompt({msg = gameConfig.strings:string_common("chat",4)})
                    end
                elseif self.selectpage == "guild" then

                    if gamedata.config.global_kv.guild_chat_power then
                        if tonumber(gamedata.config.global_kv.guild_chat_power.value) ~= -1  then
                            if GameScene.roleinfo.power < tonumber(gamedata.config.global_kv.guild_chat_power.value) then
                                runGamePrompt({msg = "战力需达到"..gamedata.config.global_kv.guild_chat_power.value.."才可发言"})
                                inputcontent = ""
                                self.input:setText("")
                                return
                            end
                        end
                    end

                    if self.gangid > 0 then
                        UIRequest({type = 3011, content = inputcontent})
                        gameTimer:rigistTime("chattimelimite",3)
                    else
                        -- runGamePrompt({msg = "未加入公会"})
                        runGamePrompt({msg = gameConfig.strings:string_common("chat",5)})
                    end
                end

                inputcontent = ""
                self.input:setText("")
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.chatButton:setSwallowsTouch(true)
    self.rootItems.chatButton:setTouchPriority(-102)

    local function emojiCallBack(destIndex)
        if gameTimer.times["chattimelimite"] and  gameTimer.times["chattimelimite"] >0 then
            runGamePrompt({msg = gameConfig.strings:string_common("chat",9)})
        else
            local tmpEmojiText = "#"..destIndex
            if self.selectpage == "world" then

                if gamedata.config.global_kv.world_chat_power then
                    if tonumber(gamedata.config.global_kv.world_chat_power.value) ~= -1  then
                        if GameScene.roleinfo.power < tonumber(gamedata.config.global_kv.world_chat_power.value) then
                            runGamePrompt({msg = "战力需达到"..gamedata.config.global_kv.world_chat_power.value.."才可发言"})
                            inputcontent = ""
                            self.input:setText("")
                            return
                        end
                    end
                end

                if self.chat_freenum > 0 then
                    UIRequest({type = 3001, content = tmpEmojiText})
                    gameTimer:rigistTime("chattimelimite",3)
                elseif self.labanum > 0 then
                    UIRequest({type = 3001, content = tmpEmojiText, labaopt = 1})
                    gameTimer:rigistTime("chattimelimite",3)
                else
                    -- runGamePrompt({msg = "传音符不够,无法发言"})
                    runGamePrompt({msg = gameConfig.strings:string_common("chat",4)})
                end
            elseif self.selectpage == "guild" then
                
                if gamedata.config.global_kv.guild_chat_power then
                    if tonumber(gamedata.config.global_kv.guild_chat_power.value) ~= -1  then
                        if GameScene.roleinfo.power < tonumber(gamedata.config.global_kv.guild_chat_power.value) then
                            runGamePrompt({msg = "战力需达到"..gamedata.config.global_kv.guild_chat_power.value.."才可发言"})
                            inputcontent = ""
                            self.input:setText("")
                            return
                        end
                    end
                end

                if self.gangid > 0 then
                    UIRequest({type = 3011, content = tmpEmojiText})
                    gameTimer:rigistTime("chattimelimite",3)
                else
                    -- runGamePrompt({msg = "未加入公会"})
                    runGamePrompt({msg = gameConfig.strings:string_common("chat",5)})
                end
            end
        end
    end
    self.rootItems.emojiBt:addHandleOfControlEvent(function()
        local tmpFromLayer = {_from = 0}
        gameWindows:openWindow("chatemoji",tmpFromLayer,emojiCallBack)
    end, CCControlEventTouchUpInside)
    self.rootItems.emojiBt:setSwallowsTouch(true)
    self.rootItems.emojiBt:setTouchPriority(-102)


end

function chat.cheackIsEmoji(self,destContent,destLen)
    if destLen > 3 then
        return 0
    else
        local fuhao = "#"
        local k = string.find(destContent, fuhao, 0)
        if k == nil or k ~= 1 then
            return 0
        else
            local fid = string.sub(destContent,k+1,destLen)
            local tmpNum = tonumber(fid)
            if tmpNum and tmpNum < 24 and tmpNum > 0 then
                return tmpNum
            else
                return 0
            end
        end
    end
end


function chat.createlistworld(self)
    local celldict = {}
    local celldictself = {}
    local chatListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            local CONST_H_SPACEING = 120
            local tmpContent = self.chatdata[tostring(a1+1)].content
            local tmpLen = string.len(tmpContent)
            local isEmoji = self:cheackIsEmoji(tmpContent,tmpLen)
            if isEmoji == 0 then
                r = CCSizeMake(1060, self.sizeT[tostring(a1+1)].h+CONST_H_SPACEING<180 and 180 or self.sizeT[tostring(a1+1)].h+CONST_H_SPACEING)
            else
                r = CCSizeMake(1060, 250+CONST_H_SPACEING)
            end
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            local isself = false
            local isEmoji = 0 -- 发送的是表情
            if self.chatdata[tostring(a1+1)].rid == self.selfdata.rid then
                isself = true
            end
            if isself and not celldictself[a2] then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("chat/chat_self.ccbi", nil, true, "chatcell_self")
                celldictself[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            elseif not isself and not celldict[a2] then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("chat/chat.ccbi", nil, true, "chatcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                if isself then
                    cellCCB = celldictself[a2].cellCCB
                    ccbDocumentControler = celldictself[a2].ccbDocumentControler
                else
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end
            end
            local tmpContent = self.chatdata[tostring(a1+1)].content
            local tmpLen = string.len(tmpContent)
            isEmoji = self:cheackIsEmoji(tmpContent,tmpLen)
            if isEmoji ~= 0 then
                ccbDocumentControler.emojibg:setVisible(true)
                ccbDocumentControler.emojibody:setVisible(true)
                ccbDocumentControler.bg:setVisible(false)
                ccbDocumentControler.content:setVisible(false)

                ccbDocumentControler.emojibody:removeAllChildrenWithCleanup(true)
                local emojiCCB, emojiDC = CCBReaderLoad("chat/biaoqing_"..isEmoji..".ccbi", nil, true, "emoji"..isEmoji)
                ccbDocumentControler.emojibody:addChild(emojiCCB)
            else
                ccbDocumentControler.bg:setVisible(true)
                ccbDocumentControler.content:setVisible(true)
                ccbDocumentControler.emojibg:setVisible(false)
                ccbDocumentControler.emojibody:setVisible(false)
                ccbDocumentControler.bg = tolua.cast(ccbDocumentControler.bg, "CCScale9Sprite")

                if ccbDocumentControler.content.setDimensionsWithString ~= nil then
                    ccbDocumentControler.content:setDimensionsWithString(CCSizeMake(self.sizeT[tostring(a1+1)].w,
                        self.sizeT[tostring(a1+1)].h),self.chatdata[tostring(a1+1)].content)
                else
                    ccbDocumentControler.content:setString(self.chatdata[tostring(a1+1)].content)
                    ccbDocumentControler.content:setDimensions(CCSizeMake(self.sizeT[tostring(a1+1)].w,self.sizeT[tostring(a1+1)].h))
                end
                

                ccbDocumentControler.bg:setPreferredSize(CCSizeMake(self.sizeT[tostring(a1+1)].w+50<80 and 80 or self.sizeT[tostring(a1+1)].w+50,
                    self.sizeT[tostring(a1+1)].h+30<120 and 120 or self.sizeT[tostring(a1+1)].h+30))
            end

            if ccbDocumentControler.cellNode then
                ccbDocumentControler.cellNode:setPosition(ccp(0,self.sizeT[tostring(a1+1)].h))
            end
            cellCCB:setPosition(ccp(0,-70-(self.sizeT[tostring(a1+1)].h+120)))

--            local t = os.date("*t", self.chatdata[tostring(a1+1)].second);
--            local hour = t.hour<10 and "0"..t.hour  or t.hour
--            local min = t.min<10 and "0"..t.min  or t.min
            ccbDocumentControler.time:setString(ui.makeTimebefore(gamedata:time()-self.chatdata[tostring(a1+1)].second))


            local playerdata = {rid = 0,name = "???",vip = 1,level = 1,profile = 10101}
            local rid = self.chatdata[tostring(a1+1)].rid or 0
            if rid > 0 and rid == self.selfdata.rid then
                playerdata = self.selfdata
            elseif rid >= 0 then
                for k,v in pairs(self.playerdata) do
                    if v.rid == rid then
                        playerdata = v
                    end
                end
            end
            if playerdata.profile < 10101 then
                playerdata.profile = 10101
            end

            ccbDocumentControler.vipnode:setVisible(false)

            -- ccbDocumentControler.type:setString("[世界]")
            ccbDocumentControler.type:setString(gameConfig.strings:string_common("chat",6))
            -- ccbDocumentControler.name:setString(playerdata.name)

            -- 添加段位排名闪烁
            if isself then
                ui.setWudaoDuanweiRankEffect(ccbDocumentControler,playerdata,1,34/34)
            else
                ui.setWudaoDuanweiRankEffect(ccbDocumentControler,playerdata,0,34/34)
            end

            -- if rid == 0 then
            --     ccbDocumentControler.name:setColor(ccc3(255,132,0))
            -- else
            --     ccbDocumentControler.name:setColor(ccc3(36,90,125))
            -- end
            --ccbDocumentControler.vip:setString("VIP"..playerdata.vip)
            --setSpriteFrameByName(ccbDocumentControler.vip,"b_n_vip_"..playerdata.vip)
            local datat = {
                quality = gamedata.config.general[tostring(playerdata.profile)].quality,
                icon = gamedata.config.general[tostring(playerdata.profile)].icon,
            }

            printT(playerdata,"playerdata")
            ui.setNewIcon(ccbDocumentControler,{cid = playerdata.profile,title = playerdata.title,iconBox = playerdata.iconBox})

            if ccbDocumentControler.popButton then
                ccbDocumentControler.popButton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    if playerdata.rid+0 < 1 then return end
                    if playerdata.rid == self.selfdata.rid then return end
                    gameWindows:openWindow("chatpop",playerdata,nil)
                end, CCControlEventTouchUpInside)
                ccbDocumentControler.popButton:setSwallowsTouch(true)
                ccbDocumentControler.popButton:setTouchPriority(-102)
            end

            --todo
            --part
            if ccbDocumentControler.duanNode then
                ui.setWudaoPart(ccbDocumentControler,playerdata.part_point or 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.chatdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.worldListTableView = ui.createLuaTableView({
        handle = chatListHandle,
        viewwidth = self.rootItems.listworld:getContentSize().width,
        viewheight = self.rootItems.listworld:getContentSize().height,
        dire = 1
    })
    self.worldListTableView:setTouchPriority(-101)
    self.rootItems.listworld:addChild(self.worldListTableView)

    if self.totalT>self.listheight then
        self.worldListTableView:setLuaContentOffset(0,0)
    end


end

function chat.addNewChat(self,t)
    self.labanum = t.propnum or 0
    self.chat_freenum = t.freenum or 0
    if self.rootItems.labanum then
        self.rootItems.labanum:setString(t.propnum or 0)
    end
    if self.rootItems.freenum then
        self.rootItems.freenum:setString(self.chat_freenum or 0)
    end

    local ismoved = self.worldoffSetY - self.worldListTableView:getLuaContentOffsetY()
    self.worldoffSetY = self.worldListTableView:getLuaContentOffsetY()

    if self.worldListTableView and table.getTableLength(t.chats)>0 then
        for i=1, table.getTableLength(t.chats) do
            self.chatdata[tostring(table.getTableLength(self.chatdata)+1)] = t.chats[tostring(i)]
        end

        for k,v in pairs(t.players) do
            self.playerdata[tostring(v.rid)] = v
        end

        self.selfdata = t.selfdata

        local oldtotal =  self.totalT
        self.sizeT, self.totalT = self:getSizeTable(self.chatdata)

        self.hasnewworldchat = true
        --if self.totalT>self.listheight then
        --    self.worldListTableView:setLuaContentOffset(0,oldtotal-self.totalT)
            self.worldListTableView:reloadData()
        --    self.worldListTableView:setContentOffsetInDuration(ccp(0,0),0.1)
        --else
        --    self.worldListTableView:setLuaContentOffset(0,self.totalT)
        --end

        gamedata.music:PlayOptSound("lt")
    end

    if t.opt and t.opt ==1 then
       self.worldListTableView:setContentOffsetInDuration(ccp(0,0),0.1)
       self.hasnewworldchat = false

    elseif self.worldListTableView and self.hasnewworldchat then
        if self.worldListTableView:isTouchMoved() then

        elseif ismoved == 0 then
            self.worldListTableView:setContentOffsetInDuration(ccp(0,0),0.1)
            self.hasnewworldchat = false
        end
    end

    --
    self:removehint()
end

function chat.createlistguild(self)
    local celldict = {}
    local celldictself = {}
    local chatListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            local CONST_H_SPACEING = 120
            local tmpContent = self.guildchatdata[tostring(a1+1)].content
            local tmpLen = string.len(tmpContent)
            local isEmoji = self:cheackIsEmoji(tmpContent,tmpLen)
            if isEmoji == 0 then
                r = CCSizeMake(1060, self.guildsizeT[tostring(a1+1)].h+CONST_H_SPACEING<180 and 180 or self.guildsizeT[tostring(a1+1)].h+CONST_H_SPACEING)
            else
                r = CCSizeMake(1060, 250+CONST_H_SPACEING)
            end
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            local isself = false
            local isEmoji = 0 -- 发送的是表情

            --篝火
            local guildbath= nil
            --盛宴
            local feast = nil

            if self.guildchatdata[tostring(a1+1)].rid == self.selfdata.rid then
                isself = true
            end
            if isself and not celldictself[a2] then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("chat/chat_self.ccbi", nil, true, "chatcell_self")
                celldictself[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            elseif not isself and not celldict[a2] then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("chat/chat.ccbi", nil, true, "chatcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                if isself then
                    cellCCB = celldictself[a2].cellCCB
                    ccbDocumentControler = celldictself[a2].ccbDocumentControler
                else
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end
            end
            local tmpContent = self.guildchatdata[tostring(a1+1)].content
            local tmpLen = string.len(tmpContent)
            isEmoji = self:cheackIsEmoji(tmpContent,tmpLen)
            if isEmoji ~= 0 then
                ccbDocumentControler.emojibg:setVisible(true)
                ccbDocumentControler.emojibody:setVisible(true)
                ccbDocumentControler.bg:setVisible(false)
                ccbDocumentControler.content:setVisible(false)

                ccbDocumentControler.emojibody:removeAllChildrenWithCleanup(true)
                local emojiCCB, emojiDC = CCBReaderLoad("chat/biaoqing_"..isEmoji..".ccbi", nil, true, "emoji"..isEmoji)
                ccbDocumentControler.emojibody:addChild(emojiCCB)
            else
                ccbDocumentControler.bg:setVisible(true)
                ccbDocumentControler.content:setVisible(true)
                ccbDocumentControler.emojibg:setVisible(false)
                ccbDocumentControler.emojibody:setVisible(false)
                ccbDocumentControler.bg = tolua.cast(ccbDocumentControler.bg, "CCScale9Sprite")

                --ccbDocumentControler.bg:setSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.chatdata[tostring(a1+1)].rid == self.selfdata.rid and "chatbubleblue.png" or "chatbubleyellow.png"))

                if self.guildchatdata[tostring(a1+1)].content then
                    show_content,guildbath = chat_manager:cheackIsGuildbath(tmpContent,tmpLen)
                    if not guildbath then
                        show_content,feast = chat_manager:cheackIsGuildfeast(tmpContent,tmpLen)
                    end    
                end

                if ccbDocumentControler.content.setDimensionsWithString ~= nil then
                    ccbDocumentControler.content:setDimensionsWithString(CCSizeMake(self.guildsizeT[tostring(a1+1)].w,
                        self.guildsizeT[tostring(a1+1)].h),show_content)
                else
                    ccbDocumentControler.content:setString(show_content)
                    ccbDocumentControler.content:setDimensions(CCSizeMake(self.guildsizeT[tostring(a1+1)].w,
                    self.guildsizeT[tostring(a1+1)].h))
                end
                ccbDocumentControler.bg:setPreferredSize(CCSizeMake(self.guildsizeT[tostring(a1+1)].w+50<80 and 80 or self.guildsizeT[tostring(a1+1)].w+50,
                    self.guildsizeT[tostring(a1+1)].h+30<120 and 120 or self.guildsizeT[tostring(a1+1)].h+30))
            end


            if ccbDocumentControler.cellNode then
               ccbDocumentControler.cellNode:setPosition(ccp(0,self.guildsizeT[tostring(a1+1)].h))
            end
            cellCCB:setPosition(ccp(0,-70-(self.guildsizeT[tostring(a1+1)].h+120)))

            ccbDocumentControler.time:setString(ui.makeTimebefore(gamedata:time()-self.guildchatdata[tostring(a1+1)].second))
            local playerdata = {rid = 0,name = "???",vip = 1,level = 1,profile = 10101}
            local rid = self.guildchatdata[tostring(a1+1)].rid or 0
            if rid > 0 and rid == self.selfdata.rid then
                playerdata = self.selfdata
            elseif rid >= 0 then
                for k,v in pairs(self.guildplayerdata) do
                    if v.rid == rid then
                        playerdata = v
                    end
                end
            end
            if playerdata.profile < 10101 then
                playerdata.profile = 10101
            end


            ccbDocumentControler.vipnode:setVisible(false)


            ccbDocumentControler.type:setString(gameConfig.strings:string_common("chat",7))
            
            ccbDocumentControler.name:setString(playerdata.name)
            -- 添加段位排名闪烁
            if isself then
                ui.setWudaoDuanweiRankEffect(ccbDocumentControler,playerdata,1,34/34)
            else
                ui.setWudaoDuanweiRankEffect(ccbDocumentControler,playerdata,0,34/34)
            end
            
               

            local datat = {
                quality = gamedata.config.general[tostring(playerdata.profile)].quality,
                icon = gamedata.config.general[tostring(playerdata.profile)].icon,
            }
            ui.setNewIcon(ccbDocumentControler,{cid = playerdata.profile,title = playerdata.title,iconBox = playerdata.iconBox})

            if ccbDocumentControler.popButton then
                ccbDocumentControler.popButton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    if playerdata.rid+0 < 1 then return end
                    if playerdata.rid == self.selfdata.rid then return end
                    gameWindows:openWindow("chatpop",playerdata,nil)
                end, CCControlEventTouchUpInside)
                ccbDocumentControler.popButton:setSwallowsTouch(true)
                ccbDocumentControler.popButton:setTouchPriority(-102)
            end

            --todo
            --part
            if ccbDocumentControler.duanNode then
                ui.setWudaoPart(ccbDocumentControler,playerdata.part_point or 0)
            end


            if ccbDocumentControler.shareButton then
                ccbDocumentControler.shareButton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    if playerdata.rid+0 < 1 then return end
                    if playerdata.rid == self.selfdata.rid then return end
                    if guildbath then
                        if guildbath > 0 then
                            gameWindows:openWindow(
                                "confirm",
                                {msg = "是否前往"..playerdata.name.."发起的"..(gamedata.config.gang2_bath_type[tostring(guildbath)] and gamedata.config.gang2_bath_type[tostring(guildbath)].name or "帮会澡堂")},
                                function ()
                                    gameTouch:clickprofbytime(0.5)
                                    UIRequest({type = 2282, roomid = guildbath, controltype = 1})
                                end)
                        end   
                    elseif feast then
                        if feast > 0 then
                            gameWindows:openWindow(
                                "confirm",
                                {msg = "是否前往"..playerdata.name.."举办的"..(gamedata.config.gang2_feast_type[tostring(feast)] and gamedata.config.gang2_feast_type[tostring(feast)].name or "帮会盛宴")},
                                function ()
                                    gameTouch:clickprofbytime(0.5)
                                    UIRequest({type = 2272, roomid = feast, controltype = 1})
                                end)
                        end
                    end    
                end, CCControlEventTouchUpInside)
                -- ccbDocumentControler.shareButton:setSwallowsTouch(true)
                ccbDocumentControler.shareButton:setTouchPriority(-102)
            end


            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.guildchatdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.guildListTableView = ui.createLuaTableView({
        handle = chatListHandle,
        viewwidth = self.rootItems.listguild:getContentSize().width,
        viewheight = self.rootItems.listguild:getContentSize().height,
        dire = 1
    })
    self.guildListTableView:setTouchPriority(-101)
    self.rootItems.listguild:addChild(self.guildListTableView)

    if self.guildtotalT>self.listheight then
        self.guildListTableView:setLuaContentOffset(0,0)
    end


end

function chat.addNewChatguild(self,t)

    self.gangid = t.gangid or self.gangid

    local ismoved = self.guildoffSetY - self.guildListTableView:getLuaContentOffsetY()
    self.guildoffSetY = self.guildListTableView:getLuaContentOffsetY()

    if self.guildListTableView and table.getTableLength(t.chats)>0 then
        for i=1, table.getTableLength(t.chats) do
            self.guildchatdata[tostring(table.getTableLength(self.guildchatdata)+1)] = t.chats[tostring(i)]
        end

        --self.guildplayerdata = t.players
        for k,v in pairs(t.players) do
            self.guildplayerdata[tostring(v.rid)] = v
        end

        self.selfdata = t.selfdata

        local oldtotal =  self.guildtotalT
        self.guildsizeT, self.guildtotalT = self:getSizeTable(self.guildchatdata)

        self.hasnewguildchat = true
        --if self.guildtotalT>self.listheight then
        --    self.guildListTableView:setLuaContentOffset(0,oldtotal-self.guildtotalT)
            self.guildListTableView:reloadData()
        --    self.guildListTableView:setContentOffsetInDuration(ccp(0,0),0.1)
        --else
        --    self.guildListTableView:setLuaContentOffset(0,self.guildtotalT)
        --end

        gamedata.music:PlayOptSound("lt")
    end

    if t.opt and t.opt ==1 then
        self.guildListTableView:setContentOffsetInDuration(ccp(0,0),0.1)
        self.hasnewguildchat = false

    elseif self.guildListTableView and self.hasnewguildchat then
        if self.guildListTableView:isTouchMoved() then

        elseif ismoved == 0 then
           self.guildListTableView:setContentOffsetInDuration(ccp(0,0),0.1)
           self.hasnewguildchat = false
        end
    end

    --
    self:removehint()

end


--
function chat.createlistbroadcast(self)
    local celldict = {}
    local celldictself = {}
    local chatListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            local CONST_H_SPACEING = 120
            local tmpContent = self.broadcastchatdata[tostring(a1+1)].content
            local tmpLen = string.len(tmpContent)
            local isEmoji = self:cheackIsEmoji(tmpContent,tmpLen)
            if isEmoji == 0 then
                r = CCSizeMake(1060, self.broadcastsizeT[tostring(a1+1)].h+CONST_H_SPACEING<180 and 180 or self.broadcastsizeT[tostring(a1+1)].h+CONST_H_SPACEING)
            else
                r = CCSizeMake(1060, 250+CONST_H_SPACEING)
            end
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            local isself = false
            local isEmoji = 0 -- 发送的是表情
            if self.broadcastchatdata[tostring(a1+1)].rid == self.selfdata.rid then
                isself = true
            end
            if isself and not celldictself[a2] then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("chat/chat_self.ccbi", nil, true, "chatcell_self")
                celldictself[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            elseif not isself and not celldict[a2] then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("chat/chat.ccbi", nil, true, "chatcell")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                if isself then
                    cellCCB = celldictself[a2].cellCCB
                    ccbDocumentControler = celldictself[a2].ccbDocumentControler
                else
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end
            end
            local tmpContent = self.broadcastchatdata[tostring(a1+1)].content
            local tmpLen = string.len(tmpContent)
            isEmoji = self:cheackIsEmoji(tmpContent,tmpLen)
            if isEmoji ~= 0 then
                ccbDocumentControler.emojibg:setVisible(true)
                ccbDocumentControler.emojibody:setVisible(true)
                ccbDocumentControler.bg:setVisible(false)
                ccbDocumentControler.content:setVisible(false)

                ccbDocumentControler.emojibody:removeAllChildrenWithCleanup(true)
                local emojiCCB, emojiDC = CCBReaderLoad("chat/biaoqing_"..isEmoji..".ccbi", nil, true, "emoji"..isEmoji)
                ccbDocumentControler.emojibody:addChild(emojiCCB)
            else
                ccbDocumentControler.bg:setVisible(true)
                ccbDocumentControler.content:setVisible(true)
                ccbDocumentControler.emojibg:setVisible(false)
                ccbDocumentControler.emojibody:setVisible(false)
                ccbDocumentControler.bg = tolua.cast(ccbDocumentControler.bg, "CCScale9Sprite")

                --ccbDocumentControler.bg:setSpriteFrame(CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(self.chatdata[tostring(a1+1)].rid == self.selfdata.rid and "chatbubleblue.png" or "chatbubleyellow.png"))

                if ccbDocumentControler.content.setDimensionsWithString ~= nil then
                    ccbDocumentControler.content:setDimensionsWithString(CCSizeMake(self.broadcastsizeT[tostring(a1+1)].w,
                        self.broadcastsizeT[tostring(a1+1)].h),self.broadcastchatdata[tostring(a1+1)].content)
                else
                    ccbDocumentControler.content:setString(self.broadcastchatdata[tostring(a1+1)].content)
                    ccbDocumentControler.content:setDimensions(CCSizeMake(self.broadcastsizeT[tostring(a1+1)].w,
                        self.broadcastsizeT[tostring(a1+1)].h))
                end
                ccbDocumentControler.bg:setPreferredSize(CCSizeMake(self.broadcastsizeT[tostring(a1+1)].w+50<80 and 80 or self.broadcastsizeT[tostring(a1+1)].w+50,
                    self.broadcastsizeT[tostring(a1+1)].h+30<120 and 120 or self.broadcastsizeT[tostring(a1+1)].h+30))
            end




            if ccbDocumentControler.cellNode then
                ccbDocumentControler.cellNode:setPosition(ccp(0,self.broadcastsizeT[tostring(a1+1)].h))
            end
            cellCCB:setPosition(ccp(0,-70-(self.broadcastsizeT[tostring(a1+1)].h+120)))

            ccbDocumentControler.time:setString(ui.makeTimebefore(gamedata:time()-self.broadcastchatdata[tostring(a1+1)].second))
            local playerdata = {rid = 0,name = "???",vip = 1,level = 1,profile = 10101}
            local rid = self.broadcastchatdata[tostring(a1+1)].rid or 0
            if rid > 0 and rid == self.selfdata.rid then
                playerdata = self.selfdata
            elseif rid >= 0 then
                for k,v in pairs(self.broadcastplayerdata) do
                    if v.rid == rid then
                        playerdata = v
                    end
                end
            end
            if playerdata.profile < 10101 then
                playerdata.profile = 10101
            end


            ccbDocumentControler.vipnode:setVisible(false)


            ccbDocumentControler.type:setString(gameConfig.strings:string_common("chat",7))

            ccbDocumentControler.name:setString(playerdata.name)
            -- 添加段位排名闪烁
            if isself then
                ui.setWudaoDuanweiRankEffect(ccbDocumentControler,playerdata,1,34/34)
            else
                ui.setWudaoDuanweiRankEffect(ccbDocumentControler,playerdata,0,34/34)
            end



            local datat = {
                quality = gamedata.config.general[tostring(playerdata.profile)].quality,
                icon = gamedata.config.general[tostring(playerdata.profile)].icon,
            }
            ui.setNewIcon(ccbDocumentControler,{cid = playerdata.profile,title = playerdata.title,iconBox = playerdata.iconBox})

            if ccbDocumentControler.popButton then
                ccbDocumentControler.popButton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    if playerdata.rid+0 < 1 then return end
                    if playerdata.rid == self.selfdata.rid then return end
                    gameWindows:openWindow("chatpop",playerdata,nil)
                end, CCControlEventTouchUpInside)
                ccbDocumentControler.popButton:setSwallowsTouch(true)
                ccbDocumentControler.popButton:setTouchPriority(-102)
            end

            --todo
            --part
            if ccbDocumentControler.duanNode then
                ui.setWudaoPart(ccbDocumentControler,playerdata.part_point or 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.broadcastchatdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.broadcastListTableView = ui.createLuaTableView({
        handle = chatListHandle,
        viewwidth = self.rootItems.listbroadcast:getContentSize().width,
        viewheight = self.rootItems.listbroadcast:getContentSize().height,
        dire = 1
    })
    self.broadcastListTableView:setTouchPriority(-101)
    self.rootItems.listbroadcast:addChild(self.broadcastListTableView)

    if self.broadcasttotalT>self.listheight then
        self.broadcastListTableView:setLuaContentOffset(0,0)
    end


end

function chat.addNewChatbroadcast(self,t)

    local ismoved = self.broadcastoffSetY - self.broadcastListTableView:getLuaContentOffsetY()
    self.broadcastoffSetY = self.broadcastListTableView:getLuaContentOffsetY()

    if self.broadcastListTableView and table.getTableLength(t.chats)>0 then
        for i=1, table.getTableLength(t.chats) do
            self.broadcastchatdata[tostring(table.getTableLength(self.broadcastchatdata)+1)] = t.chats[tostring(i)]
        end

        for k,v in pairs(t.players) do
            self.broadcastplayerdata[tostring(v.rid)] = v
        end

        self.selfdata = t.selfdata

        local oldtotal =  self.broadcasttotalT
        self.broadcastsizeT, self.broadcasttotalT = self:getSizeTable(self.broadcastchatdata)

        self.hasnewbroadcastchat = true

        self.broadcastListTableView:reloadData()

        gamedata.music:PlayOptSound("lt")
    end

    if t.opt and t.opt ==1 then
        self.broadcastListTableView:setContentOffsetInDuration(ccp(0,0),0.1)
        self.hasnewbroadcastchat = false

    elseif self.broadcastListTableView and self.hasnewbroadcastchat then
        if self.broadcastListTableView:isTouchMoved() then

        elseif ismoved == 0 then
            self.broadcastListTableView:setContentOffsetInDuration(ccp(0,0),0.1)
            self.hasnewbroadcastchat = false
        end
    end

    --
    self:removehint()

end



--

function chat.reloadFreeNum(self,t)
    self.chat_freenum = t.someids.chat_freenum or 0
    if self.rootItems.freenum then
       self.rootItems.freenum:setString(self.chat_freenum)
    end
end

return chat