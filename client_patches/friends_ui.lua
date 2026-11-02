-- Keep native windows, but never deliver an old target/window's reply into a new one.
local function page(t)
    local layer=GameScene.layers.friends
    return layer and layer.show and (not t.view or t.view==layer.module.localFriendView)
end

local function window(t,kind)
    local entry=gameWindows.windows.friend
    if not entry or not entry.show then return end
    local module=entry.module
    if module.localFriendKind~=kind or t.generation~=module.localFriendGeneration then return end
    return module
end

local function selected(module,rid)
    local row=module.frinedData and module.frinedData[tostring(module.seleteRid)]
    return row and row.rid==rid
end

for _,name in ipairs({"UIFriendRecommend","UIFriendReq","UIFriendReqQuery","UIFriendRep",
    "UIFriendAllReq","UIFriendAllShield","UIFriendAddShield","UIFriendDeleteShield","UIFriendAllAdd","UIFriendHasChat"}) do
    local original=_G[name]
    _G[name]=function(t)
        if t.localSkip or t.view and not page(t) then return end
        return original(t)
    end
end

function UIFriendQuery(t)
    if t.localSkip or not page(t) then return end
    local module=GameScene.layers.friends.module
    if t.publicRid and t.publicRid>0 then ui.setLabelString(module.rootItems.myid,tostring(t.publicRid),14) end
    module:reloadFriendList(t)
end

function UIFriendSearch(t)
    if t.localSkip then return end
    local module=window(t,"find")
    if module then module:reloadResult(t) end
end

function UIFriendChatQuery(t)
    if t.localSkip then return end
    if t.generation then
        local module=window(t,"chat")
        if not module or not selected(module,t.rid) then return end
        if t.req.new==0 then module:reloadChatView({data=t}) else module:addNewChat(t) end
    elseif t.req.new==0 and page(t) and t.friend then
        local entry=gameWindows.windows.friend
        if not entry or not entry.show then gameWindows:openWindow("friend",{type="chat",data=t},nil) end
    end
end

function UIFriendChat(t)
    if t.localSkip then return end
    local module=window(t,"chat")
    if module and selected(module,t.rid) then module:addNewChat(t) end
end

function UIFriendChatList(t)
    if t.localSkip then return end
    local module=window(t,"chat")
    if module then module:reloadChat(t.players,false) end
end

function UIFriendSendGift(t)
    if not t.localSkip and page(t) then UIRequest({type=2300,view=t.view}) end
end

function UIFriendRecvGift(t)
    if t.localSkip or not page(t) then return end
    UIRequest({type=2300,view=t.view})
    if next(t.reward) then showRewardPopupWindow(t.reward,nil) end
end

function UIFriendDelete(t)
    if not t.localSkip and page(t) then UIRequest({type=2300,view=t.view}) end
end
