-- 配置是否显示广告

local adChannel = {
   channelList = {"muyoutest","zuoyaojiapple2","muyoughqnxs"}
}

function adChannel.showOrNot(self)
	if not GameScene:checkopenlevelbyId(591,true) then
		return false
	end

    for i,c in pairs(self.channelList) do
        if c == gamedata.sdk.channelname then
            print("匹配成功,开启广告")
            return true
        end
    end
    print("匹配失败")
    return false
end

return adChannel

