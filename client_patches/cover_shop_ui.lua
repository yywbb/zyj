local function shop(t)
    local module=package.loaded.Layer_activity_safemaskshop
    return module and module.rootNode and t.coverView and module.localCoverGeneration==t.coverView.shop
        and GameScene.layers.activity and GameScene.layers.activity.show
end
local query=UISafeMaskShopQuery
function UISafeMaskShopQuery(t)
    if not t.localCoverIgnored and shop(t) then return query(t) end
end
function UISafeMaskShopReward(t)
    if t.localCoverIgnored then return end
    GameScene:addUpdate(1200)
    if shop(t) then
        showRewardPopupWindow(t.reward,nil,function() if shop(t) then UIRequest({type=3733}) end end)
    end
end
