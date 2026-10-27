--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/16
-- Time: 下午3:55
-- To change this template use File | Settings | File Templates.
--

-- local audioURL = require"audioURL"

local guildchat = {
    rootNode = nil,
    rootItems = nil,
    pageconfig = {"guild"},    

    subconfig = {
        ["guild"] = {
            name = "帮会",
            key = "guild",
            nodekey = "guildList",
            build = 266,
            module = require"window_chat_guildnew",
            chatCD = 5,
        },
    },

    selectpage = "guild",
    isChatFree = false,
    rootContentSize = {x = 1060,y = 1300},
    data = nil,
    inputcontent = "",
    chattimelimite_time = 0.5,
    touchPriority = -1,
    isbath = nil
}

function guildchat.init(self,parent,data,topposY,touchPriority,isbath)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui3/gonghui_chat", nil, true, "gonghui_chat")
    parent:addChild(self.rootNode)
    self.rootNode:setPosition(540,0)

    self.topposY = topposY
    self.data = data
    self.touchPriority = touchPriority
    self.isbath = isbath
    self:initModule()
    self:initUI()
    self:initTouch()
    self:setChat()

    UIRequest({type = 2230, param = "chat"})   -- 帮会
    UIRequest({type = 1031})

    self.selectpage = self.pageconfig[1]
    

    self:shiftPage()
    return self.rootNode
end

function guildchat.initModule(self)
    for k,v in pairs(self.subconfig) do
        if v.module and v.module.init then
            self["module_" .. v.key] = v.module:init(self, self.rootItems[v.nodekey],self.data,self.isbath)
        end
    end
    if self.isbath == "bath" then
        self.rootItems.bg_friend:setContentSize(CCSizeMake(1080,700))
    end
end

function guildchat.clearModule(self)
    for k,v in pairs(self.subconfig) do
        if v.module and v.module.clear then
            v.module:clear()
        end
    end
end
function guildchat.initUI(self)

    local chatlevel = gamedata.config.global_kv.chat_level and tonumber(gamedata.config.global_kv.chat_level.value) or 10

    if GameScene.roleinfo.level >= chatlevel then
        self.rootItems.profButton:setVisible(false)
        ui.commonBtn(self,self.rootItems,"profButton",function()
            if self["chattimelimite" .. self.selectpage] and self["chattimelimite" .. self.selectpage] > 0 then
                --runGamePrompt({msg = string.format("%.2f",self["chattimelimite" .. self.selectpage]) .. "秒后可再次发送消息"})
                runGamePrompt({msg = gameConfig.strings:string_common("chat",9)})
            end
        end,self.touchPriority - 3)
    else
        self.rootItems.profButton:setVisible(true)
        ui.commonBtn(self,self.rootItems,"profButton",function()
             runGamePrompt({msg = gameConfig.strings:chatlevel(chatlevel)})
        end,self.touchPriority - 3)
    end
    
    self.rootItems.profButton:setSwallowsTouch(false)
    -- vip 开启无限发言
    -- if GameScene.roleinfo.vip >= tonumber(gamedata.config.global_kv.chat_free_vip.value) then
    --     self.isChatFree = true
    -- else
    --     self.isChatFree = false
    -- end

    self.isChatFree = true

    for i = 1, #self.pageconfig do
        local page = self.pageconfig[i]
        if self.subconfig[page].chatCD then
            self["chattimelimite" .. page] = 0 
            self["chattimelimitetimer" .. page] = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function(time)
                if self["chattimelimite" .. page] > 0 then
                    self["chattimelimite" .. page] = self["chattimelimite" .. page] - time
                    self.rootItems.profButton:setVisible(true)
                    -- self.rootItems.inputnode:setVisible(false)
                    -- self.rootItems.un_send:setVisible(true)
                    -- self.rootItems.un_send:setString(string.format("%.2f",self["chattimelimite" .. page]) .. "秒后可再次发送消息")
                else
                    self.rootItems.profButton:setVisible(false)
                    -- self.rootItems.inputnode:setVisible(true)
                    -- self.rootItems.un_send:setVisible(false)
                    -- self.rootItems.un_send:setString("")
                end
            end, 0, false)
        end
    end

end

function guildchat.initTouch(self)
    local function touchbegin(pos)
        for k,v in pairs(self.subconfig) do
            v.module.isscrolltouched = false
        end
    end
    gameTouch:rigistFunc("begin","guild_chat",touchbegin)

    local function touchend(pos)
        for k,v in pairs(self.subconfig) do
            if self.selectpage == v.key and ui.isTouched(self.rootItems[v.nodekey],pos.x,pos.y) then
                v.module.isscrolltouched = true
            end
        end               
    end
    gameTouch:rigistFunc("end","guild_chat",touchend)
end



function guildchat.shiftPage(self,page)
    if page and page == self.selectpage then
        return
    end

    -- audioURL:clear()

    self.selectpage = page or self.selectpage
    self:reloadInput()
    
    for k,v in pairs(self.subconfig) do
        if v.key == self.selectpage then 
            v.module:reload()
            self.rootItems[v.nodekey]:setVisible(true)
            -- if GameScene.chatNum[tostring(v.build)] then
            --     GameScene.chatNum[tostring(v.build)] = 0
            -- end
            -- if GameScene.hold_chat then
            --     GameScene.hold_chat:updateChatNum()
            -- end
        else
            self.rootItems[v.nodekey]:setVisible(false)
        end
    end

end

function guildchat.reloadData(self,data)
   for k,v in pairs(self.subconfig) do
        if v.key == self.selectpage then 
            v.module:reloadData(data)
        end
    end
end

function guildchat.setChat(self)
    self.inputcontent = ""
    local beginFunc = function()
        self.inputcontent = ""
    end

    local endFunc = function(text)
        self.inputcontent = text
    end

    local chatlevel = gamedata.config.global_kv.chat_level and tonumber(gamedata.config.global_kv.chat_level.value) or 10
    local PlaceHolder = GameScene.roleinfo.level>=chatlevel and gameConfig.strings:string_common("chat",2) or gameConfig.strings:chatlevel(chatlevel)

    self.input = ui.creatInputEditBoxByNode(self.rootItems.inputnode, kEditBoxInputModeSingleLine, beginFunc, endFunc,
        {
            fontSize = 40,
            -- PlaceHolder = "点击输入聊天内容，最多20字",
            PlaceHolder = PlaceHolder,
            length = 100,
            fontColor = ccc3(0,0,0),
            PlaceholderFontColor = ccc3(200,200,200),
            nochecksensitive = true,
        }
    )
    self.input:setTouchPriority(self.touchPriority - 2)
    self.input:setSwallowsTouch(false)

    ui.setLabelString(self.rootItems.chatLab,nil,18)
    self.rootItems.chatButton:addHandleOfControlEvent(function()
        self:sendChat(self.selectpage, self.inputcontent)
    end, CCControlEventTouchUpInside)
    self.rootItems.chatButton:setSwallowsTouch(true)
    self.rootItems.chatButton:setTouchPriority(self.touchPriority - 1)


    local function emojiCallBack(destIndex)
        local tmpEmojiText = "#"..destIndex
        self:sendChat(self.selectpage, tmpEmojiText, true)
    end
    self.rootItems.emojiBt:addHandleOfControlEvent(function()
        local tmpFromLayer = {_from = 0, page = self.selectpage}
        gameWindows:openWindow("chatemoji",tmpFromLayer,emojiCallBack)
    end, CCControlEventTouchUpInside)
    self.rootItems.emojiBt:setSwallowsTouch(true)
    self.rootItems.emojiBt:setTouchPriority(self.touchPriority - 1)

end


function guildchat.sendVoice(self,callback)
    if self.selectpage == "world" then
        if self.module_world.chat_freenum > 0 or self.isChatFree then
        else
            audioURL:endRecord(self.recordID, self.selectpage, true, callback)
            runGamePrompt({msg = gameConfig.strings:string_common("chat",4)})
            return
        end
    elseif self.selectpage == "guild" then
        if self.module_guild.gangid > 0 then
        else
            audioURL:endRecord(self.recordID, self.selectpage, true, callback)
            runGamePrompt({msg = gameConfig.strings:string_common("chat",5)})
            return
        end
    end
    audioURL:endRecord(self.recordID,self.selectpage,false,callback)
end


function guildchat.sendChat(self, page, content, isVoice)
    if self["chattimelimite" .. page] and  self["chattimelimite" .. page] > 0 then
        runGamePrompt({msg = gameConfig.strings:string_common("chat",9)})
    else
        if content == "" then
            runGamePrompt({msg = gameConfig.strings:string_common("chat",3)})   -- 请输入发言
        else
            local finalStr = content
            if page == "world" then
                if self.isChatFree then
                    print("免费发言")
                end

                if self.module_world.chat_freenum > 0 or self.isChatFree then
                    UIRequest({type = 3001, content = finalStr})
                    self:setChattimelimite()
                elseif self.labanum > 0 then
                    UIRequest({type = 3001, content = finalStr, labaopt = 1})
                    self:setChattimelimite()
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("chat",4)})   -- 传音符不够,无法发言
                end
            elseif page == "guild" then
                if self.module_guild.gangid > 0 then
                    UIRequest({type = 3011, content = finalStr})
                    self:setChattimelimite()
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("chat",5)})   -- 未加入帮会
                end
            elseif page == "friend" then
                if self.module_friend.selectRid ~= nil then
                    if content == "" then
                        runGamePrompt({msg = gameConfig.strings:string_common("popups","fayan")})   -- 请输入发言
                    elseif self.module_friend.selectRid == -999 then
                        runGamePrompt({msg = "请先选择好友"})
                    elseif not self.module_friend.data.friend then
                        runGamePrompt({msg = "已经不是好友"})
                    else
                        UIRequest({type = 2306, rid = self.module_friend.selectRid,content = finalStr})
                    end
                else
                    runGamePrompt({msg = "请先选择好友"})
                end
            end

            content = ""
            self.input:setText("")
        end
    end
end

function guildchat.setChattimelimite(self)
    self["chattimelimite".. self.selectpage] = self.chattimelimite_time
    self.rootItems.profButton:setVisible(true)
    -- self.rootItems.inputnode:setVisible(false)
    -- self.rootItems.un_send:setVisible(true)
    -- self.rootItems.un_send:setString(string.format("%.2f",self["chattimelimite".. self.selectpage]) .. "秒后可再次发送消息")
end

function guildchat.reloadInput(self)
    if self["chattimelimite".. self.selectpage] and self["chattimelimite".. self.selectpage] > 0 then
        self.rootItems.profButton:setVisible(true)
        -- self.rootItems.inputnode:setVisible(false)
        -- self.rootItems.un_send:setVisible(true)
        -- self.rootItems.un_send:setString(string.format("%.2f",self["chattimelimite".. self.selectpage]) .. "秒后可再次发送消息")
    else
        local chatlevel = gamedata.config.global_kv.chat_level and tonumber(gamedata.config.global_kv.chat_level.value) or 10
        if GameScene.roleinfo.level>=chatlevel then
            self.rootItems.profButton:setVisible(false)
            -- self.rootItems.inputnode:setVisible(true)
            -- self.rootItems.un_send:setVisible(false)
            -- self.rootItems.un_send:setString("")
        else
            self.rootItems.profButton:setVisible(true)
            -- self.rootItems.inputnode:setVisible(true)
            -- self.rootItems.un_send:setVisible(false)
            -- self.rootItems.un_send:setString("")
        end
    end
    self.inputcontent = ""
    self.input:setText("")
end

function guildchat.setChatListShow(self,isshow)
    for k,v in pairs(self.subconfig) do
        if self.rootItems[v.nodekey] then

            self.rootItems[v.nodekey]:setPositionX(isshow and 500 or 99999)
            self.rootItems.bg_friend:setPositionX(isshow and 500 or 99999)
        end
    end
end

function guildchat.close(self)
    -- audioURL:clear()
    self:clearModule()
    gameTimer:UnrigistTimeFunc("voiceTimeLimit")
    gameTouch:UnrigistFunc("begin","guild_chat")
    gameTouch:UnrigistFunc("end","guild_chat")    


    for i = 1, #self.pageconfig do
        local page = self.pageconfig[i]
        if self["chattimelimitetimer" .. page] then
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self["chattimelimitetimer" .. page])
            self["chattimelimitetimer" .. page] = nil
        end
    end

    -- self.rootNode:removeAllChildrenWithCleanup(true)
    -- self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.data = nil
    self.inputcontent = ""
    self.isbath = nil

    if self.callback then
        self.callback()
    end
end

return guildchat�5  