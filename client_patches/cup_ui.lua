local function localCupPage(t)
    local layer=GameScene.layers.cup
    if t.localSkip or not layer or not layer.show or t.view~=layer.module.localCupView then return false end
    if t.generation then
        local window=gameWindows.windows.cup
        if not window or not window.show or t.generation~=window.module.localCupGeneration
            or not window.module.data or t.id~=window.module.data.id then return false end
    end
    return true
end
for _,name in ipairs({"UICupStatus","UICupTop","UICupRank","UICupTopSee","UICupBattlePlay"}) do
    local original=_G[name]
    _G[name]=function(t) if localCupPage(t) then return original(t) end end
end
local function localCupReward(t)
    if not localCupPage(t) then return end
    reloadstatus(t)
    UIRequest({type=2100,view=t.view})
    if t.reward and next(t.reward) then showRewardPopupWindow(t.reward,nil,nil) end
end
UICupJoinTomorrow=localCupReward
UICupBattleReward=localCupReward
UICupBattleRewardall=localCupReward
