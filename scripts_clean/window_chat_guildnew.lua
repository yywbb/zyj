
--20w元宝

-- local audioURL = require"audioURL"
local chat_guildnew = {
    chatdata = {},
    playerdata = {},
    ListTableView = nil,
    cellSize = {width = 1000, height = 180},

    labanum = 0,
    chat_freenum = 0,
    offSetY = 0,
    listheight = 0,
    totalT = 0,
    sizeT = {},
    hasnewchat = false,

    selfdata = {rid = 0,name = "???",vip = 1,level = 1,profile = 10101},

    gangid = 0,
    isbath = nil
}

function chat_guildnew.init(self,param,listnode,data,isbath)
    self.parent = param
    self.touchPriority = param.touchPriority
    self.listnode = listnode
    self.isbath = isbath
    self.chat_manager = require"window_chat_manager"
    self:createList()
    return self
end

function chat_guildnew.reload(self)
    self.chatdata = {}
    self.playerdata = {}
    UIRequest({type = 3010, opt = 1})
end

function chat_guildnew.addNewChat(self,t)
    self.gangid = t.gangid or self.gangid

    self.parent.rootItems.no_node1:setVisible(false)
    if self.gangid == 0 then
        runGamePrompt({msg = gameConfig.strings:string_common("chat",5)})
        self.parent.rootItems.no_node1:setVisible(true)
        return
    end

    local ismoved = self.offSetY - self.ListTableView:getLuaContentOffsetY()
    self.offSetY = self.ListTableView:getLuaContentOffsetY()

    if self.ListTableView and table.getTableLength(t.chats)>0 then
        for i=1, table.getTableLength(t.chats) do
            self.chatdata[tostring(table.getTableLength(self.chatdata)+1)] = t.chats[tostring(i)]
        end

        for k,v in pairs(t.players) do
            self.playerdata[tostring(v.rid)] = v
        end

        self.selfdata = t.selfdata
        local oldtotal =  self.totalT
        self.sizeT, self.totalT = self.chat_manager:getSizeTable(self.chatdata)
        self.hasnewchat = true
        self.ListTableView:reloadData()
        gamedata.music:PlayOptSound("lt")
    end

    if t.opt and t.opt ==1 then
        self.ListTableView:setContentOffsetInDuration(ccp(0,0),0.1)
        self.hasnewchat = false

    elseif self.ListTableView and self.hasnewchat then
        if self.ListTableView:isTouchMoved() then
        elseif ismoved == 0 then
           self.ListTableView:setContentOffsetInDuration(ccp(0,0),0.1)
           self.hasnewchat = false
        end
    end
end

function chat_guildnew.createList(self)
    local idxDict = {}
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
            local isEmoji = self.chat_manager:cheackIsEmoji(tmpContent,tmpLen)
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

            --篝火
            local guildbath= nil
            --盛宴
            local feast = nil

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
            isEmoji = self.chat_manager:cheackIsEmoji(tmpContent,tmpLen)
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

                if self.chatdata[tostring(a1+1)].content then
                    show_content,guildbath = self.chat_manager:cheackIsGuildbath(tmpContent,tmpLen)
                    if not guildbath then
                        show_content,feast = self.chat_manager:cheackIsGuildfeast(tmpContent,tmpLen)
                    end    
                end

                if ccbDocumentControler.content.setDimensionsWithString ~= nil then
                    ccbDocumentControler.content:setDimensionsWithString(CCSizeMake(self.sizeT[tostring(a1+1)].w,
                        self.sizeT[tostring(a1+1)].h),show_content)
                else
                    ccbDocumentControler.content:setString(show_content)
                    ccbDocumentControler.content:setDimensions(CCSizeMake(self.sizeT[tostring(a1+1)].w,
                    self.sizeT[tostring(a1+1)].h))
                end
                ccbDocumentControler.bg:setPreferredSize(CCSizeMake(self.sizeT[tostring(a1+1)].w+50<80 and 80 or self.sizeT[tostring(a1+1)].w+50,
                    self.sizeT[tostring(a1+1)].h+30<120 and 120 or self.sizeT[tostring(a1+1)].h+30))
            end


            if ccbDocumentControler.cellNode then
               ccbDocumentControler.cellNode:setPosition(ccp(0,self.sizeT[tostring(a1+1)].h))
            end
            cellCCB:setPosition(ccp(0,-70-(self.sizeT[tostring(a1+1)].h+120)))

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

                            if GameScene.layers["gang_xianchi2"].show then
                                runGamePrompt({msg = "正处在公会篝火中"})
                                return
                            end

                            gameWindows:openWindow(
                                "confirm",
                                {msg = "是否前往"..playerdata.name.."发起的"..(gamedata.config.gang2_bath_type[tostring(guildbath)] and gamedata.config.gang2_bath_type[tostring(guildbath)].name or "公会篝火")},
                                function ()
                                    gameTouch:clickprofbytime(0.5)
                                    UIRequest({type = 2282, roomid = guildbath, controltype = 1})
                                end)
                        end   
                    elseif feast then
                        if feast > 0 then

                            if GameScene.layers["guildfeast"].show then
                                runGamePrompt({msg = "正处在公会盛宴中"})
                                return
                            end
                            
                            gameWindows:openWindow(
                                "confirm",
                                {msg = "是否前往"..playerdata.name.."举办的"..(gamedata.config.gang2_feast_type[tostring(feast)] and gamedata.config.gang2_feast_type[tostring(feast)].name or "公会盛宴")},
                                function ()
                                    gameTouch:clickprofbytime(0.5)
                                    UIRequest({type = 2272, roomid = feast, controltype = 1})
                                end)
                        end
                    end    
                end, CCControlEventTouchUpInside)
                -- ccbDocumentControler.shareButton:setSwallowsTouch(true)
                ccbDocumentControler.shareButton:setTouchPriority(self.touchPriority - 1)
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

    print("======self.isbath======")
    print(self.isbath)
    if self.isbath == "bath" then
        self.ListTableView = ui.createLuaTableView({
            handle = chatListHandle,
            viewwidth = self.listnode:getContentSize().width,
            viewheight = self.listnode:getContentSize().height*2,
            dire = 1
        })
    else
        self.ListTableView = ui.createLuaTableView({
            handle = chatListHandle,
            viewwidth = self.listnode:getContentSize().width,
            viewheight = self.listnode:getContentSize().height,
            dire = 1
        })
    end
    
    self.ListTableView:setTouchPriority(self.touchPriority - 1)
    self.listnode:addChild(self.ListTableView)

    if self.totalT>self.listheight then
        self.ListTableView:setLuaContentOffset(0,0)
    end

end

function chat_guildnew.updatePlayStatus(self,isself,idxDict,celldict,celldictself,idx,url)
    local item = nil

    if isself then
        item = celldictself[idxDict[idx]]
    else
        item = celldict[idxDict[idx]]
    end
    if not item then return end 
    if not audioURL then return end 

    -- if audioURL.playid and audioURL.playid == url then
    --     item.animationManager:runAnimationsForSequenceNamed("play")
    --     item.ccbDocumentControler.audiohint:setVisible(false)
    -- else
    --     item.animationManager:runAnimationsForSequenceNamed("stay")
    -- end
end

function chat_guildnew.setCell(self, item, data, i)
   
end

function chat_guildnew.clear(self)
    -- audioURL:clear()

    self.chatdata = {}
    self.playerdata = {}
    self.ListTableView = nil

    self.labanum = 0
    self.chat_freenum = 0
    self.offSetY = 0
    self.hasnewchat = false
    self.listheight = 0
    self.totalT = 0
    self.sizeT = {}
    self.isbath = nil

    self.selfdata = {rid = 0,name = "???",vip = 1,level = 1,profile = 10101 }

    self.gangid = 0
end

return chat_guildnew