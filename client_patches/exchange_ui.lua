local exchangeSend = UIRequest
function UIRequest(req,...)
    if tonumber(req.type) == 4016 or tonumber(req.type) == 4017 then
        local page = package.loaded.Layer_activity_treasuresDiscount_x3
        req.exchangeView = page and page.localExchangeGeneration
    end
    return exchangeSend(req,...)
end

for _, entry in ipairs({{4016,"UITitbitDiscountX3Qury"},{4017,"UITitbitDiscountX3Buy"}}) do
    local opcode = entry[1]
    _G[entry[2]] = function(t)
        if t.localExchangeIgnored then return end
        local page = package.loaded.Layer_activity_treasuresDiscount_x3
        if page and page.show and t.exchangeView == page.localExchangeGeneration then
            if opcode == 4017 then showRewardPopupWindow(t.reward,nil,nil) end
            page:reloaddata(t)
        end
        if opcode == 4017 then GameScene:addUpdate(1200) end
    end
end
