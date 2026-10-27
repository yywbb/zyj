--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/16
-- Time: 下午3:55
-- To change this template use File | Settings | File Templates.
--

local friend = {
    rootNode = nil,
    rootItems = nil,

    root = nil,

    type = "",
    input = nil,

    seleteRid = nil,
    CellSize = {x=210,y=220},
    chatdata = {},
    frinedData = nil, -- 聊天的好友列表
    playerTableView = nil,
    chatTableView = nil,
    sizeT = {},
    totalT = 0,
    m_bNeedZero = nil, -- 需要重置为0
}

function friend.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.m_bNeedZero = false

    self.touchPriority = touchPriority
    if data.type == "find" then
        self.rootNode, self.rootItems = CCBReaderLoad("friends/tc_jingquechazhao", nil, true, "tc_jingquechazhao")
        self:reloadFind(data,callback)
    elseif data.type == "chat" then
        self.rootNode, self.rootItems = CCBReaderLoad("friends/haoyou_chat_n", nil, true, "haoyou_chat")
        if data.data ~= nil then
            local tmpTable = {}
            self.seleteRid = 1
            tmpTable["1"] = data.data.friend
            self:reloadChat(tmpTable,true)
            self:reloadChatView(data)
        else
            UIRequest({type = 2312})
        end
        -- self:reloadChat(data,callback)
    end
    self.root:addChild(self.rootNode)
    return self.root
end

function friend.reloadFind(self,data,callback)

    self.rootItems.findnode:setPosition(500,255)
    self.rootItems.findnode:setVisible(true)
    self.rootItems.resultnode:setPosition(9999,0)
    self.rootItems.resultnode:setVisible(false)
    local rid
    local beginFunc = function()
        rid = 0
    end

    local endFunc = function(text)
        local p = string.find(text,"-") or string.find(text,"_")
        if p then
            if tonumber(string.sub(text,1,p-1)) and tonumber(string.sub(text,p+1)) and tonumber(string.sub(text,p+1))>=0 then
                rid = tonumber(string.sub(text,1,p-1))*1000000 + tonumber(string.sub(text,p+1))
            else
                rid = 0
            end
        else
            rid = tonumber(text)
        end

    end

    self.input = ui.creatInputEditBoxByNode(self.rootItems.inputNode, kEditBoxInputModeAny, beginFunc, endFunc,
        {
            fontSize = 40,
            -- PlaceHolder = "点击输入要查找好友的ID",
            PlaceHolder = gameConfig.strings:string_common("popups","friendID"),
            length = 10
        }
    )

    self.input:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("friend")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    -- ui.setLabelString(self.rootItems.confirmtext,"确 定",18)
    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        if not rid then
            -- runGamePrompt({msg = "请输入ID" })
            runGamePrompt({msg = gameConfig.strings:string_common("popups","enId") })
        elseif rid == 0 or rid > 2147483647 then
            -- runGamePrompt({msg = "ID无效" })
            runGamePrompt({msg = gameConfig.strings:string_common("popups","msId") })
        else
            UIRequest({type = 2307, ids = {rid}})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)

end

function friend.reloadResult(self,data,callback)
    if data.player then
        self.rootItems.findnode:setPosition(9999,0)
        self.rootItems.findnode:setVisible(false)
        self.rootItems.resultnode:setPosition(500,255)
        self.rootItems.resultnode:setVisible(true)

        ui.setIconLv(self.rootItems,{cid = data.player.profile,level = data.player.level})
        -- self.rootItems.name:setString("确定添加“"..data.player.name.."”为好友吗?")
        self.rootItems.name:setString(gameConfig.strings:addFriend(data.player.name))

        -- ui.setLabelString(self.rootItems.buttontext,"确 定",18)
        ui.setLabelString(self.rootItems.buttontext,gameConfig.strings:string_common("popups","queding"),18)
        self.rootItems.button:addHandleOfControlEvent(function()
            self.callback = nil
            gameWindows:closeWindow("friend")
            UIRequest({type = 2302, ids = {data.player.rid}})
        end, CCControlEventTouchUpInside)
        self.rootItems.button:setSwallowsTouch(true)
        self.rootItems.button:setTouchPriority(self.touchPriority)

        -- ui.setLabelString(self.rootItems.conceltext,"取 消",18)
        ui.setLabelString(self.rootItems.conceltext,gameConfig.strings:string_common("popups","quxiao"),18)
        self.rootItems.concel:addHandleOfControlEvent(function()
            self.callback = nil
            gameWindows:closeWindow("friend")
        end, CCControlEventTouchUpInside)
        self.rootItems.concel:setSwallowsTouch(true)
        self.rootItems.concel:setTouchPriority(self.touchPriority)

    else
        -- runGamePrompt({msg = "查无此人，请重新输入" })
        runGamePrompt({msg = gameConfig.strings:string_common("popups","notPer") })
    end
end


function friend.getSizeTable(self,chats)
    local label = ui.createLabel({
        fontsize = 36,
        font = "Helvetica-Bold",
    })

    local sizeTable = {}
    local totalheight = 0

    for i=1, table.getTableLength(chats) do
        label:setString(chats[tostring(i)].content)
        local height = label:getContentSize().height
        local width = label:getContentSize().width

        if width > 500 then
            sizeTable[tostring(i)] = {w = 500+10, h = math.ceil(width/500)*height+20}
        else
            local tmpContent = chats[tostring(i)].content
            local tmpLen = string.len(tmpContent)
            if self:cheackIsEmoji(tmpContent,tmpLen) ~= 0 then
                sizeTable[tostring(i)] = {w = width+10, h = 200}
            else
                sizeTable[tostring(i)] = {w = width+10, h = height+20}
            end
        end
        totalheight = totalheight + sizeTable[tostring(i)].h+100
    end

    return sizeTable,totalheight
end

function friend.addNewChat(self,t)
    if self.chatTableView then
        for i=1, table.getTableLength(t.chats) do
            self.chatdata[tostring(table.getTableLength(self.chatdata)+1)] = t.chats[tostring(i)]
        end

        local oldtotal =  self.totalT
        self.sizeT, self.totalT = self:getSizeTable(self.chatdata)

        self.chatTableView:reloadData()
        if self.m_bNeedZero then
            self.m_bNeedZero = false
            self.chatTableView:setLuaContentOffset(0,0)
        end

        if table.getTableLength(t.chats) > 0 then
            gamedata.music:PlayOptSound("lt")
        end
    end
end

function friend.setfriendCell(self,data,items)
-- printT(data,"设置一个玩家")
    if self.frinedData[tostring(self.seleteRid)].rid == data.rid then
        items.noSeleteBg:setVisible(false)
        items.seleteBg:setVisible(true)
    else
        items.noSeleteBg:setVisible(true)
        items.seleteBg:setVisible(false)
    end
    ui.setIconLv(items,{cid = data.profile,level = data.level,title = data.title,iconBox = data.iconBox})
    -- ui.setLabelString(items.name,data.name,48)
    -- 添加段位排名闪烁
    ui.setWudaoDuanweiRankEffect(items,data,0.5,35/34,48)

    if items.vipnode then
        items.vipnode:setVisible(false)
        -- items.vipnode:setVisible(gameConfig:checkBuildOpen(154))
        -- local vipnum = data.vip or (data.params["4"] and data.params["4"].i or 1)
        -- setSpriteFrameByName(items.vip,"b_n_vip_"..(vipnum or 1))
    end
    items.button:setTouchPriority(self.touchPriority-2)
end

function friend.reloadChatView(self,data)
    local timefunc = function()
        if gameTimer.times.friendChat and gameTimer.times.friendChat ==0 then
            UIRequest({type = 2305, rid = data.data.friend.rid,new = 1})
            gameTimer:rigistTime("friendChat",5)
        end
    end
    gameTimer:rigistTime("friendChat",5)
    gameTimer:rigistTimeFunc("friendChat",timefunc)

    self.chatdata = data.data.chats
    self.sizeT, self.totalT = self:getSizeTable(self.chatdata)

    local celldict = {}
    local celldictself = {}
    local CONST_H_SPACEING = 100
    local chatListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            local tmpContent = self.chatdata[tostring(a1+1)].content
            local tmpLen = string.len(tmpContent)
            local isEmoji = self:cheackIsEmoji(tmpContent,tmpLen)
            if isEmoji == 0 then
                r = CCSizeMake(690, self.sizeT[tostring(a1+1)].h+CONST_H_SPACEING)
            else
                r = CCSizeMake(690, 200+CONST_H_SPACEING)
            end
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            local isself = false
            if self.chatdata[tostring(a1+1)].rid == data.data.selfRid then
                isself = true
            end
            if isself and not celldictself[a2] then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("friends/chat_me.ccbi", nil, true, "chat_me")
                celldictself[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            elseif not isself and not celldict[a2] then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("friends/chat_player.ccbi", nil, true, "chat_player")
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
                ccbDocumentControler.emojibody:removeAllChildrenWithCleanup(true)
                ccbDocumentControler.emojibody:setVisible(true)
                ccbDocumentControler.content:setVisible(false)
                local emojiCCB, emojiDC = CCBReaderLoad("chat/biaoqing_"..isEmoji..".ccbi", nil, true, "emoji"..isEmoji)
                ccbDocumentControler.emojibody:addChild(emojiCCB)
            else
                ccbDocumentControler.content:setVisible(true)
                ccbDocumentControler.emojibody:setVisible(false)
                if ccbDocumentControler.content.setDimensionsWithString ~= nil then
                    ccbDocumentControler.content:setDimensionsWithString(CCSizeMake(self.sizeT[tostring(a1+1)].w,
                        self.sizeT[tostring(a1+1)].h),self.chatdata[tostring(a1+1)].content)
                else
                    ccbDocumentControler.content:setString(self.chatdata[tostring(a1+1)].content)
                    ccbDocumentControler.content:setDimensions(CCSizeMake(self.sizeT[tostring(a1+1)].w,
                        self.sizeT[tostring(a1+1)].h))
                end
            end

            ccbDocumentControler.time:setString(ui.makeTimebefore(gamedata:time()-self.chatdata[tostring(a1+1)].second))
            
            if not isself then
                -- ccbDocumentControler.name:setString(data.data.friend.name)
                -- 添加段位排名闪烁
                ui.setWudaoDuanweiRankEffect(ccbDocumentControler,data.data.friend,0,34/34)

            end
           

            cellCCB:setPosition(ccp(345, 0))


            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.chatdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)
    if self.chatTableView then
        self.chatTableView:removeFromParentAndCleanup(true)
        self.chatTableView = nil
    end

    self.chatTableView = ui.createLuaTableView({
        handle = chatListHandle,
        viewwidth =  self.rootItems.chatScroll:getContentSize().width,
        viewheight =  self.rootItems.chatScroll:getContentSize().height,
        dire = 1
    })
    self.chatTableView:setTouchPriority(self.touchPriority)
    self.rootItems.chatScroll:addChild(self.chatTableView)

    if self.totalT>640 then
        self.chatTableView:setLuaContentOffset(0,0)
    end
end

function friend.createPlayerList(self)
    local celldict = {}
    local cellIndex = {}
    local shieldListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("friends/cell_chat.ccbi", nil, true, "cell_chat")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                cellIndex[a1+1] = a2
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setfriendCell(self.frinedData[tostring(a1+1)],ccbDocumentControler)
            ccbDocumentControler.button:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                if self.seleteRid ~= a1 + 1 then
                    celldict[cellIndex[self.seleteRid]].ccbDocumentControler.noSeleteBg:setVisible(true)
                    celldict[cellIndex[self.seleteRid]].ccbDocumentControler.seleteBg:setVisible(false)
                    gameTimer:UnrigistTimeFunc("friendChat")
                    self.seleteRid = a1 + 1
                    UIRequest({type = 2305, rid = self.frinedData[tostring(self.seleteRid)].rid,new = 0})
                    ccbDocumentControler.noSeleteBg:setVisible(false)
                    ccbDocumentControler.seleteBg:setVisible(true)
                end
             end, CCControlEventTouchUpInside)
            -- self:setfriendCell(self.frinedData[a1+1],ccbDocumentControler)

            cellCCB:setPosition(self.CellSize.x/2, self.CellSize.y/2)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.frinedData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.playerTableView = ui.createLuaTableView({
        handle = shieldListHandle,
        viewwidth = self.rootItems.cellScroll:getContentSize().width,
        viewheight = self.rootItems.cellScroll:getContentSize().height,
        dire = 1
    })
    self.playerTableView:setTouchPriority(self.touchPriority-1)
    self.rootItems.cellScroll:addChild(self.playerTableView)
end

function friend.reloadChat(self,data,notUpdate)
    self.frinedData = data
    local inputcontent = ""
    local beginFunc = function()
        inputcontent = ""
    end

    local endFunc = function(text)
        inputcontent = text
    end

    self.input = ui.creatInputEditBoxByNode(self.rootItems.inputnode, kEditBoxInputModeAny, beginFunc, endFunc,
        {
            fontSize = 40,
            -- PlaceHolder = "点击输入聊天内容，最多20字",
            PlaceHolder = gameConfig.strings:string_common("popups","enterNum"),
            length = 40,
            fontColor = ccc3(255,255,255),
            PlaceholderFontColor = ccc3(200,200,200),
        }
    )
    self.input:setTouchPriority(self.touchPriority)

    local function emojiCallBack(destIndex)
        local tmpEmojiText = "#"..destIndex
        self.m_bNeedZero = true
        UIRequest({type = 2306, rid = self.frinedData[tostring(self.seleteRid)].rid,content = tmpEmojiText})
    end

    self.rootItems.emojibt:addHandleOfControlEvent(function()
        if self.seleteRid ~= nil then
            local tmpFromLayer = {_from = 1}
            gameWindows:openWindow("chatemoji",tmpFromLayer,emojiCallBack)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.emojibt:setSwallowsTouch(true)
    self.rootItems.emojibt:setTouchPriority(self.touchPriority-2)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameTimer:UnrigistTimeFunc("friendChat")
        gameWindows:closeWindow("friend")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.rootItems.chatButtontext,"发 送",18)
    ui.setLabelString(self.rootItems.chatButtontext,gameConfig.strings:string_common("popups","fasong"),18)
    self.rootItems.chatButton:addHandleOfControlEvent(function()
        if self.seleteRid ~= nil then
            if inputcontent == "" then
                -- runGamePrompt({msg = "请输入发言"})
                runGamePrompt({msg = gameConfig.strings:string_common("popups","fayan")})
            else
                self.m_bNeedZero = true
                UIRequest({type = 2306, rid = self.frinedData[tostring(self.seleteRid)].rid,content = inputcontent})
                inputcontent = ""
                self.input:setText("")
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.chatButton:setSwallowsTouch(true)
    self.rootItems.chatButton:setTouchPriority(self.touchPriority)

    if not notUpdate and self.frinedData["1"] ~= nil then
        -- printT(self.frinedData["1"],"哈哈哈哈")
        self.seleteRid = 1
        UIRequest({type = 2305, rid = self.frinedData[tostring(self.seleteRid)].rid,new = 0})
    end
    self:createPlayerList()
end

function friend.cheackIsEmoji(self,destContent,destLen)
    if destLen > 3 then
        return 0
    else
        local fuhao = "#"
        k = string.find(destContent, fuhao, 0)
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

function friend.close(self)
    gameTimer:UnrigistTimeFunc("friendChat")
    UIRequest({type = 2313})
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    self.seleteRid = nil

    if self.input then
        --ui.removeInputEditBox(self.input)
        self.input = nil
    end

    self.chatdata = {}
    self.frinedData = nil
    self.chatTableView = nil
    self.playerTableView = nil
    self.sizeT = {}
    self.totalT = 0

    if self.callback then
        self.callback()
    end
end

return friend  �M  