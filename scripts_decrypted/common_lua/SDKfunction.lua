--
-- Created by IntelliJ IDEA.
-- User: han-joy
-- Date: 14-5-20
-- Time: 下午5:09
-- To change this template use File | Settings | File Templates.
--


local SDK = {
    messageNum = 99
    ,channel = nil
    ,tencentchannel = "qq",

    idCardStatus = -1
}

local deviceApi = require"device"

local config = require"a_config"

local alladdress = {
    --59测试服
    ["59test"] = {   
        gameAddress =     {host = "182.92.161.59", port = 8000},
        resourceAddress = {host = "182.92.161.59", port = 8000},
        updateAddress =       "http://182.92.161.59:18888/getpginformation.php",
        configupdateAddress = "http://182.92.161.59:18888/getconfinfo",
        serverInfoAddress =   "http://182.92.161.59:18888/serverlist",    
    },

    ["muyou39test"] = {   
        gameAddress =     {host = "39.107.27.38", port = 10011},
        resourceAddress = {host = "39.107.27.38", port = 10011},
        updateAddress =       "http://39.107.27.38:3010/getpginformation.php",
        configupdateAddress = "http://39.107.27.38:3010/getconfinfo",
        serverInfoAddress =   "http://39.107.27.38:3010/serverlist",
    },

    --测试环境登android 新
    -- ["59test"] = {   
    --     gameAddress =     {host = "39.106.249.154", port = 10011},
    --     resourceAddress = {host = "39.106.249.154", port = 10011},
    --     updateAddress =       "http://res.zyj.52muyou.com:3010/getpginformation.php",
    --     configupdateAddress = "http://res.zyj.52muyou.com:3010/getconfinfo",
    --     serverInfoAddress =   "http://res.zyj.52muyou.com:3010/serverlist",    
    -- },

    --ios官方
    ["ios"] = {   
        gameAddress =     {host = "ios-acc.zyj.52muyou.com", port = 10011},
        resourceAddress = {host = "ios-acc.zyj.52muyou.com", port = 10011},
        updateAddress =       "https://res.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://res.zyj.52muyou.com/getconfinfo",
        serverInfoAddress =   "https://res.zyj.52muyou.com/serverlist",    
    },

    --android混服
    ["android"] = {  
        gameAddress =     {host = "39.106.249.154", port = 10011},
        resourceAddress = {host = "39.106.249.154", port = 10016},
        updateAddress =       "http://res.zyj.52muyou.com:3010/getpginformation.php",
        configupdateAddress = "http://res.zyj.52muyou.com:3010/getconfinfo",
        serverInfoAddress =   "http://res.zyj.52muyou.com:3010/serverlist",    
    },

    --应用宝
    ["tencent"] = {  
        gameAddress =     {host = "115.159.106.82", port = 10011},
        resourceAddress = {host = "115.159.106.82", port = 10011},
        updateAddress =       "http://res.zyj.52muyou.com:3011/getpginformation.php",
        configupdateAddress = "http://res.zyj.52muyou.com:3011/getconfinfo",
        serverInfoAddress =   "http://res.zyj.52muyou.com:3011/serverlist",    
    },

    --ios越狱
    ["ios_yueyu"] = {  
        gameAddress =     {host = "39.107.53.76", port = 10011},
        resourceAddress = {host = "39.107.53.76", port = 10011},
        updateAddress = "",
        configupdateAddress = "",
        serverInfoAddress = "",    
    },

    --安卓小米
    ["android_xiaomi"] = {  
        gameAddress =     {host = "47.93.76.48", port = 15011},
        resourceAddress = {host = "47.93.76.48", port = 15011},
        updateAddress = "",
        configupdateAddress = "",
        serverInfoAddress = "",    
    },

     --17应用宝
    ["17tencent"] = {  
        gameAddress =     {host = "115.159.69.180", port = 10011},
        resourceAddress = {host = "115.159.69.180", port = 10011},
        updateAddress =       "http://res.zyj.52muyou.com:3012/getpginformation.php",
        configupdateAddress = "http://res.zyj.52muyou.com:3012/getconfinfo",
        serverInfoAddress =   "http://res.zyj.52muyou.com:3012/serverlist",    
    },

    --奇遇
    ["qiyu"] = {  
        gameAddress =     {host = "47.93.76.48", port = 46011},
        resourceAddress = {host = "47.93.76.48", port = 46011},
        updateAddress = "http://lianyun.zyj.52muyou.com:3011/getpginformation.php",
        configupdateAddress = "http://lianyun.zyj.52muyou.com:3011/getconfinfo",
        serverInfoAddress = "http://lianyun.zyj.52muyou.com:3011/serverlist",    
    },

     --奇遇ios
    ["qiyuios"] = {  
        gameAddress =     {host = "acc.zyjiosly.52muyou.com", port = 46011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 46011},
        updateAddress = "https://qiyu.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://qiyu.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://qiyu.zyj.52muyou.com/serverlist",    
    },

}

local addressconfig = {
    ["muyoutest"] = alladdress["59test"],
    ["chujiani"]  = alladdress["ios"],
    ["chujianii"] = alladdress["ios"],
    ["muyoughqnxs"] = alladdress["android"],
    ["zuoyaojihdios"] = alladdress["ios"],
    ["zuoyaojihdios2"] = alladdress["ios"],
    ["zuoyaojiapple"] = alladdress["ios"],
    ["fzSSNYJ"] = alladdress["ios"],
    ["hangmeiYMDSG"] = alladdress["ios"],
    ["zuoyaojiapple2"] = alladdress["ios"],
    ["muyouzyj"] = alladdress["ios"],
    ["muyoufyj"] = alladdress["ios"],
    ["anfengn"] = alladdress["android"],
    ["huawein"] = alladdress["android"],
    ["oppo"] = alladdress["android"],
    ["baidu"] = alladdress["android"],
    ["vivon"] = alladdress["android"],
    ["x7syn"] = alladdress["android"],
    ["dangle"] = alladdress["android"],
    ["linnyou"] = alladdress["android"],
    ["360"] = alladdress["android"],
    ["uc"] = alladdress["android"],
    ["gionee"] = alladdress["android"],
    ["lenovo"] = alladdress["android"],
    ["x7sy"] = alladdress["ios_yueyu"],
    --["x7syn"] = alladdress["ios_yueyu"],
    ["xxi"] = alladdress["ios_yueyu"],
    ["fanzuozyj"] = alladdress["ios"],
    ["muyoutg"] = alladdress["android"],
    ["coolpad"] = alladdress["android"],
    ["zuoyaojitest"] = alladdress["muyou39test"],
    ["qq"] = alladdress["tencent"],
    ["weixin"] = alladdress["tencent"],
    ["muyoutg_baidu1"] = alladdress["android"],
    ["muyoutg_baidu2"] = alladdress["android"],
    ["muyoutg_baidu3"] = alladdress["android"],
    ["muyoutg_baidu4"] = alladdress["android"],
    ["muyoutg_baidu5"] = alladdress["android"],
    ["muyoutg_baidu6"] = alladdress["android"],
    ["muyoutg_baidu7"] = alladdress["android"],
    ["muyoutg_baidu8"] = alladdress["android"],
    ["muyoutg_baidu9"] = alladdress["android"],
    ["muyoutg_baidu10"] = alladdress["android"],
    ["muyoutg_baidu11"] = alladdress["android"],
    ["muyoutg_baidu12"] = alladdress["android"],
    ["muyoutg_baidu13"] = alladdress["android"],
    ["muyoutg_baidu14"] = alladdress["android"],
    ["muyoutg_baidu15"] = alladdress["android"],
    ["muyoutg_baidu16"] = alladdress["android"],
    ["muyoutg_baidu17"] = alladdress["android"],
    ["muyoutg_baidu18"] = alladdress["android"],
    ["muyoutg_baidu19"] = alladdress["android"],
    ["muyoutg_baidu20"] = alladdress["android"],
    ["muyoutg_baidu21"] = alladdress["android"],
    ["muyoutg_baidu22"] = alladdress["android"],
    ["muyoutg_baidu23"] = alladdress["android"],
    ["muyoutg_baidu24"] = alladdress["android"],
    ["muyoutg_baidu25"] = alladdress["android"],
    ["muyoutg_baidu26"] = alladdress["android"],
    ["muyoutg_baidu27"] = alladdress["android"],
    ["muyoutg_baidu28"] = alladdress["android"],
    ["muyoutg_baidu29"] = alladdress["android"],
    ["muyoutg_baidu30"] = alladdress["android"],
    ["mz"] = alladdress["android"],
    ["mi2"] = alladdress["android_xiaomi"],
    ["17qq"] = alladdress["17tencent"],
    ["17weixin"] = alladdress["17tencent"],
    ["qiyuXYGX"] = alladdress["qiyu"],
    ["qiyuDYJ"] = alladdress["qiyu"],
    ["qiyuXSGH"] = alladdress["qiyu"],
    ["qiyuSJYYQ"] = alladdress["qiyu"],
    ["qiyuiosDYZ"] = alladdress["qiyuios"],
    ["qiyuiosXYGX"] = alladdress["qiyuios"],
    ["qiyuiosPHSG"] = alladdress["qiyuios"],
    ["muyoutestios"] = alladdress["ios"],
}

function SDK.init(self)
    cclog("SDK.init")
    gamedata.gameconfig = config.config
    gamedata.isshowlog = config.config.isshowlog
    gamedata.isdebug = config.config.isdebug

    self.channelname = gamedata.gameconfig.channel
    self.channelid = gamedata.gameconfig.channelid
    self.address = addressconfig[self.channelname]
end
SDK:init()

function SDK.NetSyncChannel(uireq)
    cclog("SDK.NetSyncChannel")
    -- cclog(uireq)
    if uireq.channelname then
        deviceApi.channel = uireq.channelname
    end
    if uireq.channelid then
        deviceApi.channelid = uireq.channelid
    end

    gamedata.sdk.channelname = uireq.channelname
    gamedata.sdk.channelid = uireq.channelid
end

function SDK.SDKChannelName(self)
    cclog("SDK.SDKChannelName")
    self.running = false
    deviceApi.channel = gamedata.gameconfig.channel or ""
    deviceApi.channelid =  gamedata.gameconfig.channelid or ""

    if deviceApi.platform == "android" then
        local channel = gamedata.gameconfig.channel or ""
        if string.find(channel,"qq")~=nil or string.find(channel,"weixin")~=nil  or string.find(channel,"tencent")~=nil then
              channel = SDK.tencentchannel
        end   
        local result, channelid = self:AndroidChannelID()
        local result, channelname = self:AndroidChannelName()
        deviceApi.channel = channelname
        deviceApi.channelid = channelid
    else
        if ChannelSDK then
            gamedata.ios_channelsdk = ChannelSDK.Singleton()
            deviceApi.channelid = gamedata.ios_channelsdk:ChannelID()

            if deviceApi.channel =="hm" then
                if CCFileUtils:sharedFileUtils():fullPathForFilename("shield_hm.lua") ~= "shield_hm.lua" then
                    local hmConfig = require"shield_hm"
                    gameConfig.sensitiveWord = hmConfig
                end
            end
        end
    end

    print("SDK.SDKChannelName  Channel ",deviceApi.channel, deviceApi.channelid)

    if deviceApi.channel and deviceApi.channel ~= "" then
        self.running = true
        
        if deviceApi.platform == "android" then
            self.channel = require("AndroidSDK_common")
        -- elseif deviceApi.channel == "iiapple" then
        --     print("pp start sdk")
        --     self.channel = require(deviceApi.channel)
        else
            print("itools start sdk is ")
           self.channel = require("iosSDK_common")
        end
    end
    self.channelname = deviceApi.channel
    self.channelid = deviceApi.channelid

    -- UIRequest({type=95, channelname=deviceApi.channel, channelid=deviceApi.channelid})
end

-- function SDK.LoadEnv(self)
--     cclog("SDK.LoadEnv")
--     self.running = false
--     if deviceApi.platform == "android" then
--         --cclog("SDK.LoadEnv Android : %s",tencentchannel)
--         local result, channel = self:AndroidChannelName()
--         if (channel == "qq" or channel == "weixin" or channel == "tencent")then
--               channel = SDK.tencentchannel
--         end   
--         local result, channelid = self:AndroidChannelID()
--         deviceApi.channel = channel
--         deviceApi.channelid = channelid
--     else
--         if ChannelSDK then
--             gamedata.ios_channelsdk = ChannelSDK.Singleton()
--             deviceApi.channel = gamedata.ios_channelsdk:ChannelName()
--             deviceApi.channelid = gamedata.ios_channelsdk:ChannelID()
--         end
--     end
--     if deviceApi.channel and deviceApi.channel ~= "" then
--         cclog("SDK.LoadEnv  Channel %s %d", deviceApi.channel, deviceApi.channelid)
--         self.running = true
--         if deviceApi.platform == "android" then
--                 self.channel = require("AndroidSDK_common")
--         elseif deviceApi.channel == "iiapple" then
--             print("pp start sdk")
--             self.channel = require(deviceApi.channel)
--         else
--             print("itools start sdk is ")
--            self.channel = require("iosSDK_common")
--         end
--         UIRequest({type=95, channelname=deviceApi.channel, channelid=deviceApi.channelid})
--     end
--     return self.running
-- end

-- function SDK.EnvOK(self)
--     self.ok = true
--     self.channel:Login()
-- end

function SDK.AndroidChannelName(self)
    local luaj = require"luaj"
    --local javaClassName = "com/ldfs/sanguo/AndroidUtils"
    --local javaClassName = "com/ldfs/sanguo2/AndroidUtils"
    local javaClassName = gameConfig.AD_packageName.."/AndroidUtils"
    local javaMethodName = "ChannelName"
    local javaMethodSig = "()Ljava/lang/String;"
    -- return luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
    return luaj.callStaticMethod(javaClassName, javaMethodName, "", javaMethodSig)
end

function SDK.AndroidChannelID(self)
    local luaj = require"luaj"
    --local javaClassName = "com/ldfs/sanguo/AndroidUtils"
    --local javaClassName = "com/ldfs/sanguo2/AndroidUtils"
    local javaClassName = gameConfig.AD_packageName.."/AndroidUtils"
    local javaMethodName = "ChannelID"
    local javaMethodSig = "()I"
    return luaj.callStaticMethod(javaClassName, javaMethodName, "", javaMethodSig)
end

function SDK.isValid(self)
    return self.running and self.channelname ~= "muyoutest"
end

function SDK.isLogin(self)
    return self.channel:isLogin()
end


function SDK.Login(self)
    local updater = require"accServerInfoupdate"
    updater:checkifneedupdate(self.address.serverInfoAddress,function()
        if self.channelname == "muyoutest" then
            UIRequest({type=3,devicemodel = gamedata.device.model,systemVersion = gamedata.device:getsystemVersion()})
        else
            self.channel:Login()
        end
    end)
end

function SDK.CreateRole(self,name)


    if deviceApi.channel == "chujiana" or deviceApi.channel == "baiducmcj" or deviceApi.channel == "chujiani" or deviceApi.channel == "chujianii" or deviceApi.channel == "xmgame"  or deviceApi.channel == "linnyou" or  deviceApi.channel == "pps" or  deviceApi.channel == "lb" or deviceApi.channel == "papa" or deviceApi.channel == "19yx" or deviceApi.channel == "wdj" or deviceApi.channel == "yuewen" or deviceApi.channel == "kaopu" or deviceApi.channel == "xxa" 
        or deviceApi.channel == "jipings" or deviceApi.channel == "jipingm" or deviceApi.channel == "wanmiandroid"  or deviceApi.channel == "aishanga" or deviceApi.channel == "aishangi" or deviceApi.channel == "muyouzyj" or deviceApi.channel == "dangle" or deviceApi.channel == "beiyouaQM" or deviceApi.channel == "xiaomiyxf" or deviceApi.channel == "xiaomikm" or deviceApi.channel == "styj" or deviceApi.channel == "qphy666sdk" or deviceApi.channel == "zuoyaojiapple" 
        or deviceApi.channel == "zuoyaojiapple2" or deviceApi.channel == "zuoyaojihdios"  or deviceApi.channel == "zuoyaojihdios2" or deviceApi.channel == "qiyuXYGX" or deviceApi.channel == "qiyuDYJ" or deviceApi.channel == "qiyuXSGH"  or deviceApi.channel == "qiyuiosDYZ"  or deviceApi.channel == "qiyuiosXYGX" or deviceApi.channel == "qiyuSJYYQ" or deviceApi.channel == "qiyuiosPHSG" then
        return self.channel:CreateRole(name)
    end 
end

function SDK.BtnChannelLogin(self)
    return self.channel:BtnChannelLogin()
end

function SDK.EgameMoreGame(self)
    return self.channel:EgameMoreGame()
end

function SDK.LoginTC(self)
    cclog("SDK.LoginTC")
    local uiqueue = require("uiqueue")
    uiqueue.setresponsetoui({type=999912})
end

--腾讯登录
function SDK.LoginTencent(self,platform)
    cclog("SDK.LoadEnv  SDK.LoginTencent %s",platform)
     SDK.tencentchannel = platform
    -- if gamedata.sdk:LoadEnv() then
    -- else
    --     UIRequestEx({ type = 3,devicemodel = gamedata.device.model,systemVersion = gamedata.device:getsystemVersion() })
    -- end
    return self.channel:LoginTencent(platform)
end


function SDK.loginAccountSuc(self,uid)
    if deviceApi.platform == "android" then
         if self.channel.loginAccountSuc then
            self.channel:loginAccountSuc(uid)
         end
    else
        if self.channel.loginAccountSuc then
            self.channel:loginAccountSuc(uid)
        end
    end

end

function SDK.loginSuccess(self)
    if deviceApi.channel == "huawei" or self.channelname == "huawei" then
        local luaj = require"luaj"
        local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
        local javaMethodName = "loginSuccess"
        local javaMethodSig = "()V"
        return luaj.callStaticMethod(javaClassName, javaMethodName, "", javaMethodSig)
    elseif string.find(self.channelname,"qq")~=nil or string.find(self.channelname,"weixin")~=nil  or string.find(self.channelname,"tencent")~=nil then
        local luaj = require"luaj"
        local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
        local javaMethodName = "getTencent_pfkey"
        local javaMethodSig = "()Ljava/lang/String;"
        local result1,tencent_pfKey = luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig);

        local javaMethodName2 = "getTencent_pf"
        local javaMethodSig2 = "()Ljava/lang/String;"
        local result2,tencent_pf = luaj.callStaticMethod(javaClassName,javaMethodName2,"",javaMethodSig2);
        
        local javaMethodName3 = "getTencent_openID"
        local javaMethodSig3 = "()Ljava/lang/String;"
        local result3,tencent_openid = luaj.callStaticMethod(javaClassName,javaMethodName3,"",javaMethodSig3);
     

        local javaMethodName4 = "getTencent_openKey"
        local javaMethodSig4 = "()Ljava/lang/String;"
        local result4,tencent_openkey = luaj.callStaticMethod(javaClassName,javaMethodName4,"",javaMethodSig4);
     
        local javaMethodName5 = "getTencent_paytoken"
        local javaMethodSig5 = "()Ljava/lang/String;"
        local result5,tencent_paytoken = luaj.callStaticMethod(javaClassName,javaMethodName5,"",javaMethodSig5);
     

        cclog("SDK.loginSuccess openid:%s   openkey:%s  pf: %s   pfkey:%s paytoken:%s",tencent_openid,tencent_openkey,tencent_pf,tencent_pfKey,tencent_paytoken)
       -- UIRequest({type = 10000, openid = tencent_openid, openkey =tencent_openkey, pf = tencent_pf, pfkey = tencent_pfKey, paytoken =  tencent_paytoken})
        UIRequest({type = 10002, openid = tencent_openid, openkey =tencent_openkey, pf = tencent_pf, pfkey = tencent_pfKey, paytoken =  tencent_paytoken})

    else

    end
end

function SDK.changeChannel(self,channel)
     --  SDK.tencentchannel = channel
     -- if(deviceApi ~= nil)then
     --    deviceApi.channel = channel
     --     cclog("SDK.changechannel %s ,tencentchannel %s",channel, SDK.tencentchannel)
     -- end
    -- body
end

function SDK.checkTencentCoins(self,orderid)

        cclog("SDK.checkTencentCoins %s",orderid)
        
        UIResponse({type = 10001, orderid = orderid})
        
end

function SDK.checkTencentCoins2(self,orderid)
            cclog("SDK.checkTencentCoins2 %s",orderid)
        
        UIResponse({type = 10003, orderid = orderid})   
end


function SDK.reLogin(self)

    return self.channel:reLogin()
end

function SDK.changeUser(self)
    return self.channel:changeUser()
end

function SDK.Logout(self)
    cclog("SDK.Logout")
    local uiqueue = require("uiqueue")
    uiqueue.setresponsetoui({type=999911})
    -- if LoginScene.status then
    --     if not LoginScene.enterLayer  then
    --         LoginScene:clear()
    --         bRunWithScene = false
    --         LoginScene:init(loginScene)
    --         UIRequest({type =1})
    --     else
    --     end
    -- else
    --     guide:clear()
    --     gameWindows:closeAllWindowDirect()
    --     if battleScene.show then
    --         battleScene.callback = nil
    --         battleScene:clear()
    --     end
    --     GameScene:clear()

    --     gameTimer:UnrigistAll()
    --     bRunWithScene = false
    --     LoginScene:init(loginScene)
    --     UIRequest({type =1})
    -- end

end

function SDK.LogoutAndLogin(self,uid,uuid,ucid,systemVersion)

    cclog("SDK.LogoutAndLogin")
    cclog("SDK.LogoutAndLogin: "..uid.." "..uuid.." "..ucid)
    local uiqueue = require("uiqueue")
    uiqueue.setresponsetoui({type=999911,uid = uid,uuid = uuid,ucid = ucid,systemVersion=systemVersion})

end




function SDK.Recharge(self, rechargeTb)

    --商品订单号

    local order = rechargeTb.rechargeData["1"].i
    local rmb = rechargeTb.configData.rmb    --商品价钱
    local name = rechargeTb.configData.name  --商品名称
    local desc = rechargeTb.configData.desc  --商品描述
    local getGold = tostring(rechargeTb.configData.gold)  --得到的元宝数
    printT(rechargeTb)
    if deviceApi.channel == "uc" then
         --角色等级
         local parma1 = rechargeTb.rechargeData["2"].s
         local parma2 = rechargeTb.rechargeData["3"].s
         local parma3 = rechargeTb.rechargeData["4"].s
         local parma4 = rechargeTb.rechargeData["5"].s
         local parma5 = rechargeTb.rechargeData["6"].s
         local parma6 = rechargeTb.rechargeData["7"].s
         return self.channel:RechargeUC(order, rmb, name, rechargeTb.level,parma1,parma2,parma3,parma4,parma5,parma6)

    elseif deviceApi.channel == "lenovo" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.lenovo_number)

    elseif deviceApi.channel == "sogou" then
        return self.channel:Recharge(order, rmb, name, getGold)

    elseif deviceApi.channel == "mz" then
        local mzCreatT = rechargeTb.rechargeData["2"].i
        local times = tostring(mzCreatT)
        local mzSign = rechargeTb.rechargeData["3"].s
        return self.channel:RechargeMZ(order,times, mzSign, rmb, name, desc)

    elseif deviceApi.channel == "vivo" or deviceApi.channel == "vivon" then
        local vvAccesskey = rechargeTb.rechargeData["2"].s
        local vvOrderNumber = rechargeTb.rechargeData["3"].s
        return  self.channel:RechargeVV(order,vvOrderNumber, vvAccesskey, rmb, name, desc)

    elseif deviceApi.channel == "xsdk" then
        --serverData.name  --服务器名字  serverData.id   --服务器ID
        return self.channel:Recharge(order, rmb, name, rechargeTb.serverData.name)

    elseif deviceApi.channel == "pp" then
        --serverData.name  --服务器名字  serverData.id   --服务器ID
        return self.channel:Recharge(order, rmb, name, rechargeTb.paltformGuid)

    elseif deviceApi.channel == "coolpad" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.coolpad_number)

    elseif deviceApi.channel == "cc" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.cc_number)

    elseif deviceApi.channel == "dome" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.dome_id)
    elseif deviceApi.channel == "icejoy" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.icejoy_id)

    elseif deviceApi.channel == "pyw" or deviceApi.channel == "papa" or deviceApi.channel == "yyh" or deviceApi.channel == "xmgame" or deviceApi.channel == "linnyou" or deviceApi.channel == "yuewen" or deviceApi.channel == "qqreader" then
        --公共商品id
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.common_id)

    elseif deviceApi.channel == "gionee" then
        return self.channel:Recharge(order, rmb, name, desc)
    elseif deviceApi.channel == "xmw" then
        local xmwOrderId = rechargeTb.rechargeData["2"].s
        return self.channel:Recharge(order, rmb, name, xmwOrderId)

    elseif deviceApi.channel == "chujiani" or deviceApi.channel == "chujianii" or deviceApi.channel == "zuoyaojihdios"  or deviceApi.channel == "zuoyaojiapple" or deviceApi.channel == "zuoyaojihdios2" or deviceApi.channel == "zuoyaojiapple2" or deviceApi.channel =="muyoufyj" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.app_goodId)
    elseif deviceApi.channel == "changba"  then

        local cporder = rechargeTb.rechargeData["2"].s
        
        return self.channel:Recharge( order, rmb, cporder, rechargeTb.configData.common_id)
    elseif deviceApi.channel == "qingyuanmy" then   
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qingyuanmy) 
    elseif  deviceApi.channel == "qingyuanhy" then
        printT(rechargeTb)

        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qingyuanhy) 
    elseif deviceApi.channel == "anqusw" or deviceApi.channel == "tutufk" or deviceApi.channel == "anquxy" or deviceApi.channel == "anquyjl" 
        or deviceApi.channel == "anquyjd" or deviceApi.channel == "tuturx"  or deviceApi.channel == "tutukpx"  or deviceApi.channel == "tutumh"  
        or deviceApi.channel == "tutukps" or deviceApi.channel == "tutuhlw" or deviceApi.channel == "tutuhlx"  or deviceApi.channel == "anqunewfk"
        or deviceApi.channel == "anqurxn" or deviceApi.channel == "anqurnewmh" or deviceApi.channel == "anqunewhlx" or deviceApi.channel == "anqunewhlw" then    
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anqu_channel) 
    elseif deviceApi.channel =="hanfengbx" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengbx) 
    elseif deviceApi.channel =="hanfengqm" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengqm)    
    elseif deviceApi.channel =="hanfengfg" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengfg)    
    elseif deviceApi.channel =="hanfengdq" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengdq)    
    elseif deviceApi.channel =="hanfengmw" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengmw)    
    elseif deviceApi.channel =="hanfengbg" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengbg)   
    elseif deviceApi.channel =="hanfengsg" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengsg) 
    elseif deviceApi.channel =="hanfengls" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengls) 
    elseif deviceApi.channel =="hanfengzl" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengzl) 
    elseif deviceApi.channel =="hanfengfk" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengfk) 
    elseif deviceApi.channel =="hanfengyj" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengyj) 
    elseif deviceApi.channel =="hanfengsn" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengsn) 
    elseif deviceApi.channel =="hanfengsgk" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengsgk) 
    elseif deviceApi.channel =="hanfengld" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengld_channel) 
    elseif deviceApi.channel =="hanfengkp"  then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengkp) 
    elseif deviceApi.channel =="hanfengxy"  then    
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengxy) 
    elseif deviceApi.channel =="hanfengdqx" or deviceApi.channel =="hanfenglds" or deviceApi.channel =="hanfenghlx" or deviceApi.channel =="hanfengcq" or deviceApi.channel =="hanfengqms" or deviceApi.channel =="hanfengsj" then    
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengnew) 
    elseif deviceApi.channel =="jingxunmw" or deviceApi.channel =="jingxunmy" or deviceApi.channel =="jingxunlt" or deviceApi.channel =="jingxunfs" or deviceApi.channel =="jingxunyj" or deviceApi.channel =="jingxunltc" or deviceApi.channel =="jingxunlta"
       or  deviceApi.channel =="jingxundh" or  deviceApi.channel =="jingxuncy" or  deviceApi.channel =="jingxunyja" or  deviceApi.channel =="jingxunltca" or  deviceApi.channel =="jingxunyq" or  deviceApi.channel =="jingxunxyj" 
       or  deviceApi.channel =="jingxunsx" or  deviceApi.channel =="jingxunydmm" then
         cclog("SDK.recharge: "..order.." "..rmb.." "..name.." "..rechargeTb.configData.jingxun_channel)
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.jingxun_channel) 
    elseif  deviceApi.channel =="jingxunbz" then   
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.jingxun_channel2)  
    elseif deviceApi.channel =="9377" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377_channel)   
    elseif deviceApi.channel =="9377jj" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377jj_channel)
    elseif deviceApi.channel =="9377bym" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377bym_channel)
    elseif deviceApi.channel =="9377bys" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377bys_channel)
    elseif deviceApi.channel =="9377wd" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377wd_channel)
    elseif deviceApi.channel =="9377jmf" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377jmf_channel)
    elseif deviceApi.channel =="9377mfb" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377mfb_channel)
    elseif deviceApi.channel =="9377wsx" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377wsx_channel)
    elseif deviceApi.channel =="anfengbz" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_bz)
    elseif deviceApi.channel =="anfengsw" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_sw)
    elseif deviceApi.channel =="anfengfk" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_fk)
    elseif deviceApi.channel =="anfengjj" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_jj)
    elseif deviceApi.channel =="anfengwd" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_wd)
    elseif deviceApi.channel =="anfengswhd" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_swhd)
    elseif deviceApi.channel =="anfengygn" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_ygn)
    elseif deviceApi.channel =="anfengsgy" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_sgy)    
    elseif deviceApi.channel =="anfengswg" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_swg)   
    elseif deviceApi.channel =="asm8" or deviceApi.channel =="asm8my" or deviceApi.channel =="asm8yj" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.channel_asm8)
    elseif deviceApi.channel =="asm8ygd" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.channel_asm8ygd)
    elseif deviceApi.channel =="huanwen" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.huanwen_ioschannel)
    elseif deviceApi.channel =="cyxfs" or deviceApi.channel =="cyxxy" or deviceApi.channel =="cyxdn" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.cyx_channel)
    elseif deviceApi.channel =="muyouzyj" then 
       return self.channel:Recharge(order, rmb, name, rechargeTb.configData.muyouzyj_channel)
    elseif deviceApi.channel =="wanmiandroid" or deviceApi.channel =="wanmiios" or deviceApi.channel =="aishangi"  then    
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.common_id)
    elseif deviceApi.channel =="hanfenga" or deviceApi.channel =="beiyouaQM" or deviceApi.channel =="aishanga"then    
        return self.channel:Recharge2(order, rmb, name, desc, rechargeTb.configData.common_id)
    elseif deviceApi.channel =="jingqi" then    
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.jingqi_channel)
    elseif deviceApi.channel =="beiyouqm" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.beiyouqm_channel)
    elseif deviceApi.channel =="beiyoukp" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.beiyoukp_channel)
    elseif deviceApi.channel =="fanzuozyj" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.fanzuozyj_id)
    elseif deviceApi.channel =="cvSF" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.cvsf_channel)
    elseif deviceApi.channel =="kyYG" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.kyyg_channel)
    elseif deviceApi.channel =="hangmeiYMDSG" or deviceApi.channel =="hangmeiYJDLM" then
        return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hangmeiRecharge)
    elseif deviceApi.channel == "x7syn" then
        local gameSign = rechargeTb.rechargeData["2"].s
        return self.channel:Recharge(order, rmb, desc, gameSign)
    elseif deviceApi.channel == "tjLSJ" then
        
        if deviceApi.channelid == 100161001 then 
            return self.channel:Recharge(order, rmb, name, rechargeTb.configData.tjZYLJ)
        elseif deviceApi.channelid == 100161000 then 
            return self.channel:Recharge(order, rmb, name, rechargeTb.configData.tjLSJ)
        end
    elseif deviceApi.channel == "fzSSNYJ" then
        --凡卓更改新的流程，以后参数和渠道标识都用一个，只有channelid不同
        if deviceApi.channelid == 100161003 then 
            return self.channel:Recharge(order, rmb, name, rechargeTb.configData.fzYSJ)
        elseif deviceApi.channelid == 100161001 then 
            return self.channel:Recharge(order, rmb, name, rechargeTb.configData.fzYSCS)
        elseif deviceApi.channelid == 100161000 then 
            return self.channel:Recharge(order, rmb, name, rechargeTb.configData.fzSSNYJ)
        else
            return self.channel:Recharge(order, rmb, name, rechargeTb.configData.fzSSNYJ)
        end
    elseif deviceApi.channel == "qiyuiosDYZ" then
         return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosDYZ)
    elseif deviceApi.channel == "qiyuiosXYGX" then
         return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosXYGX)
    elseif deviceApi.channel == "qiyuiosPHSG" then
         return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosPHSG)
    else
        return self.channel:Recharge(order, rmb, name, desc)
    end
end

function SDK.checkIfNeedSendUserInformation( self,params )
    if not self.userinfo_params then
        self.userinfo_params = table.copy(params)
        return true
    else
        local need = false
        for k,v in pairs(params) do
            if not self.userinfo_params[k] or self.userinfo_params[k]~=v then
                need = true
                break
            end
        end
        return need
    end
end


function SDK.UserInformation(self,params)
    print("SDK.UserInformation")
    printT(params)
    if not self:checkIfNeedSendUserInformation(params) then return end 

    if deviceApi.channel == "360" then
        return self.channel:UserInformation2(params.roleId, params.platforName, params.roleLv, params.serverId,params.platformId,params.roleName,params.severName,params.vip,params.gold,"0")
        --return self.channel:UserInformation(params.roleId, params.platforName, params.roleLv, params.serverId,params.platformId)
    elseif  deviceApi.channel == "coolpad" then
         return self.channel:UserInformation(params.roleuid, params.platformId, params.roleLv, params.serverId,params.platforName)
    elseif deviceApi.channel == "mi" or deviceApi.channel == "mi2" then
        return self.channel:UserInformation2(params.roleId, params.roleName, params.roleLv, params.vip, params.severName, params.gold)
    elseif deviceApi.channel == "uc" or deviceApi.channel == "oppo" or deviceApi.channel == "huawei" or deviceApi.channel == "pptv" or deviceApi.channel == "dangle" or deviceApi.channel == "vivo" or deviceApi.channel == "vivon" or deviceApi.channel == "pps" or deviceApi.channel == "yumi" or deviceApi.channel == "jingxunmw" 
         or deviceApi.channel == "jingxunmy" or deviceApi.channel == "jingxunlt" or deviceApi.channel =="jingxunfs" or deviceApi.channel =="jingxunyj"or deviceApi.channel =="jingxunltc" or deviceApi.channel =="jingxunlta"  or deviceApi.channel =="jingxundh" or deviceApi.channel =="jingxuncy" or deviceApi.channel =="jingxunltca"
         or deviceApi.channel == "anfengbz" or deviceApi.channel == "anfengsw" or deviceApi.channel == "jingxunyja" or deviceApi.channel == "asm8" or deviceApi.channel == "jingxunyq" or deviceApi.channel == "jingxunbz" or deviceApi.channel == "anfengfk" or deviceApi.channel == "anfengjj" or deviceApi.channel == "hanfengsn" 
         or deviceApi.channel == "hanfengsgk" or deviceApi.channel == "jingxunxyj" or deviceApi.channel == "anfengswhd" or deviceApi.channel == "asm8my" or deviceApi.channel == "anfengsgy" or deviceApi.channel == "asm8yj" or deviceApi.channel == "anfengwd"  or deviceApi.channel =="jingxunsx" or deviceApi.channel =="jingxunydmm" 
          or deviceApi.channel == "anfengygn" or deviceApi.channel == "anfengswg" or deviceApi.channel == "asm8ygd" then 
        return self.channel:UserInformation(params.roleId, params.roleName, params.roleLv, params.serverId,params.severName)
    elseif deviceApi.channel == "hanfengbx"  or deviceApi.channel == "hanfengqm"  or deviceApi.channel == "hanfengfg"  or deviceApi.channel == "hanfengjg"  or deviceApi.channel == "hanfengjz"  or deviceApi.channel == "hanfengwy" or deviceApi.channel == "hanfengsg" or deviceApi.channel == "hanfengls"
         or deviceApi.channel == "hanfengyj" or deviceApi.channel == "hanfengfk" or deviceApi.channel == "hanfengzl" or deviceApi.channel == "hanfengkp" or deviceApi.channel == "hanfengxy" or  deviceApi.channel =="hanfengdqx" or deviceApi.channel =="hanfenglds" or deviceApi.channel =="hanfenghlx" 
         or deviceApi.channel =="hanfengcq" or deviceApi.channel =="hanfengqms" or deviceApi.channel =="hanfengsj" then  
        cclog("SDK.UserInformation sdklv:"..SDK.rolelv)
        local parmaslv = tonumber(params.roleLv)
        cclog("SDK.UserInformation rolelv:"..params.roleLv)
        if SDK.rolelv == 0 then
            SDK.rolelv = parmaslv 
            return self.channel:UserInformation(params.roleId, params.roleName, params.roleLv, params.serverId,params.severName)
        end 
    elseif  deviceApi.channel == "anzhi" or deviceApi.channel == "anfeng" or deviceApi.channel == "kugou" or deviceApi.channel == "chujiani" or deviceApi.channel == "chujianii" or deviceApi.channel == "kaopu" or deviceApi.channel == "anqu" or deviceApi.channel == "chujiana" or deviceApi.channel == "baiducmcj" 
         or deviceApi.channel == "zuoyaojiapple" or deviceApi.channel == "zuoyaojiapple2" or deviceApi.channel == "zuoyaojihdios" or deviceApi.channel == "zuoyaojihdios2"  then
        return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,params.severName)
    elseif deviceApi.channel == "papa" or deviceApi.channel == "tt" or deviceApi.channel == "xmw" or deviceApi.channel == "linnyou" or deviceApi.channel == "51iyx" or deviceApi.channel == "xxi" or deviceApi.channel == "i4" or deviceApi.channel == "bt" then
        return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,params.severName)
    elseif  deviceApi.channel == "xmgame" or  deviceApi.channel == "youmi" or  deviceApi.channel == "lb" then
        return self.channel:UserInformation3(params.roleuid, params.roleName, params.roleLv, params.serverId, params.severName, params.gold, params.vip)
    elseif  deviceApi.channel == "yuewen" or deviceApi.channel == "lhh" or deviceApi.channel == "wanke" or deviceApi.channel == "7k7k" or deviceApi.channel == "x7sy" or deviceApi.channel == "x7syn" or  deviceApi.channel == "aphy"  or  deviceApi.channel == "sw" 
        or deviceApi.channel == "qqreader" or deviceApi.channel == "wdj" or deviceApi.channel == "gavegame" then
        return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,params.severName)
    elseif  deviceApi.channel == "tiantian" or deviceApi.channel == "xxa" or deviceApi.channel == "qingyuanmy" or deviceApi.channel == "qingyuanhy" or deviceApi.channel == "anqusw" 
        or deviceApi.channel == "tutufk" or deviceApi.channel == "anquxy" or deviceApi.channel == "anquyjl" or deviceApi.channel == "anquyjd" or deviceApi.channel == "tuturx"  or deviceApi.channel == "yeshen" 
         or deviceApi.channel == "tutukpx"  or deviceApi.channel == "tutumh" or deviceApi.channel == "tutukps" or deviceApi.channel == "9377" or deviceApi.channel == "9377jj" or deviceApi.channel == "9377bym" 
          or deviceApi.channel == "9377bys" or deviceApi.channel == "9377wd" or deviceApi.channel == "yuxiang" or deviceApi.channel == "tutuhlw" or deviceApi.channel == "tutuhlx" or deviceApi.channel == "9377a" 
          or deviceApi.channel == "anqurxn"  or deviceApi.channel == "anqurnewmh" or deviceApi.channel == "anqunewhlx" or deviceApi.channel == "anqunewhlw"  
          or deviceApi.channel == "9377jmf" or deviceApi.channel == "9377mfb" or deviceApi.channel == "9377wsx" or deviceApi.channel == "hanfenga" or deviceApi.channel == "jingqi"  or deviceApi.channel =="beiyouqm" or deviceApi.channel =="beiyoukp"
          or deviceApi.channel == "beiyouaQM"  or deviceApi.channel == "xigu" or deviceApi.channel == "kyYG" then
        return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,params.severName)
    elseif  deviceApi.channel == "le8"then
        local le8Info = params.severName .. " | ".. params.roleName .. " | lv:" .. params.roleLv
        return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,le8Info)
    elseif  deviceApi.channel == "xsdk" then
        return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,params.paltformGuid)
    elseif deviceApi.channel == "19yx" or deviceApi.channel == "xiaomiyxf" or deviceApi.channel == "xiaomiwq" or deviceApi.channel == "xiaomikm" or deviceApi.channel == "styj" or deviceApi.channel == "fanzhuo" 
            or deviceApi.channel == "hangmeiYMDSG" or deviceApi.channel == "hangmeiYJDLM" then
         return self.channel:UserInformation19(params.roleuid, params.roleName, params.roleLv, params.serverId,params.severName, params.vip, params.gold)
    elseif deviceApi.channel == "jipings" or deviceApi.channel == "jipingm" or deviceApi.channel == "wanmiandroid" or deviceApi.channel == "wanmiios" or deviceApi.channel == "qphy" or deviceApi.channel == "aishanga" or deviceApi.channel == "aishangi" or deviceApi.channel == "qphy666sdk" 
         or deviceApi.channel == "qiyuXYGX" or deviceApi.channel == "qiyuDYJ" or deviceApi.channel == "qiyuXSGH" or deviceApi.channel == "qiyuSJYYQ" then
         return self.channel:UserInformation19(params.roleId, params.roleName, params.roleLv, params.serverId,params.severName, params.vip, params.gold)
    else
         return self.channel:UserInformation(params.roleId, params.roleName, params.roleLv, params.serverId,params.severName)
    end
    
end


--游戏兑换礼包接口（拇指玩的需要）
function SDK.PostGift(self,giftCode)
    return self.channel:PostGift(giftCode)
end


function SDK.LoginTokenIos(self,token) 

    self.channel:loginGuid(token)
end

--熊猫玩的登录token 和 麟游的登录uid
function SDK.LoginToken(token)
    if deviceApi.channel == "xmw" or deviceApi.channel == "linnyou" or deviceApi.channel == "hanfenga" or deviceApi.channel == "beiyouaQM" or deviceApi.channel == "x7syn" then
        local luaj = require "luaj"
        local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
        local javaMethodName = "LoginToken"
        local javaParams = {  token }
        local javaMethodSig = "(Ljava/lang/String;)V"
        luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
    end
    
end

--分享
function SDK.showShare(self)
    if deviceApi.platform == "android" then
        local luaj = require"luaj"
        local javaClassName1 = gameConfig.AD_packageName.."/AndroidUtils"
        local javaMethodName1 = "getShare"
        local javaMethodSig1 = "()Z"
        local result,isshare_ = luaj.callStaticMethod(javaClassName1,javaMethodName1,"",javaMethodSig1);
        if isshare_ then
            local javaClassName2 = gameConfig.AD_packageName.."/ShareSDKUtils"
            local javaMethodName2 = "showShare"
            local javaMethodSig2 = "()V"
            luaj.callStaticMethod(javaClassName2, javaMethodName2, "", javaMethodSig2)
        end
    else
        MyShareSDK:showShare()
    end
end

--local config = require"config"

function SDK.UserSessionValid(uireq)
    cclog("SDK.UserSessionValid")
    local userTBlogin_pb = require("user91login_pb")
    -- cclog(uireq)
    local messageNum = SDK.messageNum
    if uireq.messageNum then
        messageNum = uireq.messageNum
    end
    if uireq.uin == nil then
        return 0
    end
    local userTBSessionRequest = userTBlogin_pb.User91LoginRequest()
    userTBSessionRequest.uin = uireq.uin
    userTBSessionRequest.sessionid = uireq.sessionId
    userTBSessionRequest.nickname = uireq.nickname

    local uuid, device, os, version = deviceApi.getOpenUDID(), uireq.devicemodel, deviceApi.platform, uireq.systemVersion
    userTBSessionRequest.uuid = uuid
    userTBSessionRequest.device = device
    userTBSessionRequest.os = os
    userTBSessionRequest.version = version


    cclog("SDK.UserSessionValid messageNum:"..messageNum)
    return 1,messageNum,userTBSessionRequest:SerializeToString()
end

function SDK.UserSessionValid2(uireq)
    cclog("SDK.UserSessionValid2")
    local userchanneloginl_pb = require("userchannellogin_pb")
    -- cclog(uireq)
    local messageNum = SDK.messageNum
    if uireq.messageNum then
        messageNum = uireq.messageNum
    end
    if uireq.uin == nil then
        return 0
    end
    local userChannelLoginRequest = userchanneloginl_pb.UserChannelLogin()
    userChannelLoginRequest.uin = uireq.uin
    userChannelLoginRequest.sessionid = uireq.sessionId
    userChannelLoginRequest.nickname = uireq.nickname
    userChannelLoginRequest.channelname = uireq.channel
    userChannelLoginRequest.channelid   = uireq.channelid

    if deviceApi.channel and uireq.channel then
        deviceApi.channel = uireq.channel
        deviceApi.channelid   = uireq.channelid
    end

    cclog("SDK.UserSessionValid2 channel3 is  %s",userChannelLoginRequest.channelname )

    local uuid, device, os, version = deviceApi.getOpenUDID(), uireq.devicemodel, deviceApi.platform, uireq.systemVersion
    userChannelLoginRequest.uuid = uuid
    userChannelLoginRequest.device = device
    userChannelLoginRequest.os = os
    userChannelLoginRequest.version = version


    cclog("SDK.UserSessionValid2 messageNum:"..messageNum)

    local userchannelname = userChannelLoginRequest.channelname 
    if string.find(userchannelname,"qq")~=nil or string.find(userchannelname,"weixin")~=nil  or string.find(userchannelname,"tencent")~=nil then
        return 1,900001,userChannelLoginRequest:SerializeToString()
    else
        return 1,messageNum,userChannelLoginRequest:SerializeToString()
    end
end

function SDK.AndroidSessionValid2(uireq)
    cclog("SDK.AndroidSessionValid2")

    local combmessages_pb = require("combmessages_pb")
    local userchanneloginl_pb = require("userchannellogin_pb")
    local params_pb = require("params_pb")

    -- cclog(uireq)
    local messageNum = SDK.messageNum
    if uireq.messageNum then
        messageNum = uireq.messageNum
    end
    if uireq.uin == nil then
        return 0
    end
    local userChannelLoginRequest = userchanneloginl_pb.UserChannelLogin()
    userChannelLoginRequest.uin = uireq.uin
    userChannelLoginRequest.sessionid = uireq.sessionId
    userChannelLoginRequest.nickname = uireq.nickname

   cclog("SDK.AndroidSessionValid3")
    if deviceApi.channel then
        userChannelLoginRequest.channelname = deviceApi.channel
        userChannelLoginRequest.channelid   = deviceApi.channelid
    end

    cclog("SDK.AndroidSessionValid3")
    cclog("SDK.UserSessionValid2 channelid:%s",uireq.channelid)
    cclog("SDK.UserSessionValid2 channelname:%s",uireq.channelname)

    if uireq.channelname then
      userChannelLoginRequest.channelname = uireq.channelname
    end

    if uireq.channelid then
      userChannelLoginRequest.channelid = uireq.channelid
    end

    cclog("SDK.UserSessionValid2 userChannelLoginRequest channelname:%s",userChannelLoginRequest.channelname)
    cclog("SDK.UserSessionValid2 userChannelLoginRequest channelid:%s",userChannelLoginRequest.channelid)

    local uuid, device, os, version = deviceApi.getOpenUDID(), uireq.devicemodel, deviceApi.platform, uireq.systemVersion
    userChannelLoginRequest.uuid = uuid
    userChannelLoginRequest.device = device
    userChannelLoginRequest.os = os
    userChannelLoginRequest.version = version

    cclog("SDK.UserSessionValid2 messageNum:"..messageNum)

     local userchannelname = userChannelLoginRequest.channelname
    if string.find(userchannelname,"qq")~=nil or string.find(userchannelname,"weixin")~=nil  or string.find(userchannelname,"tencent")~=nil  then
        return 1,900001,userChannelLoginRequest:SerializeToString()
    else
        local versiondata = params_pb.ParamS()
        local paramdata = versiondata.params:add()

        --安卓提审版本号
        paramdata.s = tostring(gamedata.gameconfig.submit)

        local reqs = combmessages_pb.CombMessages()

        local userreq = reqs.messages:add()
        userreq.id = 1
        userreq.data = userChannelLoginRequest:SerializeToString()

        local sysversion = reqs.messages:add()
        sysversion.id = 2
        sysversion.data = versiondata:SerializeToString()

        return 1,900002,reqs:SerializeToString()
    end
end

function SDK.appleUserSessionValid(uireq)
    cclog("SDK.appleUserSessionValid")

    local combmessages_pb = require("combmessages_pb")
    local userchanneloginl_pb = require("userchannellogin_pb")
    local params_pb = require("params_pb")
    

    -- cclog(uireq)
    local messageNum = SDK.messageNum
    if uireq.messageNum then
        messageNum = uireq.messageNum
    end
    if uireq.uin == nil then
        return 0
    end
    local userChannelLoginRequest = userchanneloginl_pb.UserChannelLogin()
    userChannelLoginRequest.uin = uireq.uin
    userChannelLoginRequest.sessionid = uireq.sessionId
    userChannelLoginRequest.nickname = uireq.nickname
    if deviceApi.channel then
        userChannelLoginRequest.channelname = deviceApi.channel
        userChannelLoginRequest.channelid   = deviceApi.channelid
    end

     if uireq.channelname then
      userChannelLoginRequest.channelname = uireq.channelname
    end

    if uireq.channelid then
      userChannelLoginRequest.channelid = uireq.channelid
    end

    
    cclog("SDK.UserSessionValid2 channel3 is  %s",userChannelLoginRequest.channelname )

    local uuid, device, os, version = deviceApi.getOpenUDID(), uireq.devicemodel, deviceApi.platform, uireq.systemVersion
    userChannelLoginRequest.uuid = uuid
    userChannelLoginRequest.device = device
    userChannelLoginRequest.os = os
    userChannelLoginRequest.version = version

    cclog("SDK.UserSessionValid2 messageNum:"..messageNum)

    local versiondata = params_pb.ParamS()
    local paramdata = versiondata.params:add()


    --苹果提审版本号
    paramdata.s = tostring(gamedata.gameconfig.submit)


    local reqs = combmessages_pb.CombMessages()

    local userreq = reqs.messages:add()
    userreq.id = 1
    userreq.data = userChannelLoginRequest:SerializeToString()

    local sysversion = reqs.messages:add()
    sysversion.id = 2
    sysversion.data = versiondata:SerializeToString()

    return 1,900000,reqs:SerializeToString()
end




function SDK.forceUpdate(self,url)
    cclog("SDK.NetSyncChannel")

    if deviceApi.platform == "android" and url and url ~="" then
        local luaj = require "luaj"
        local javaClassName = "org/cocos2dx/lib/Cocos2dxHelper"
        local javaMethodName = "openUrl"
        local javaParams = {  url }
        local javaMethodSig = "(Ljava/lang/String;)V"
        luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
    elseif deviceApi.platform == "ios" then
        if self.channel.forceUpdate then
            if url and url ~="" then
                return self.channel:forceUpdateWithUrl(url)
            else
                return self.channel:forceUpdate()
            end
        end
    end

end



function SDK.sendOrder(order,rmb)
    runGamePrompt({msg = "生成订单"..order})
end

function SDK.notifyCallBack(type,param)

    if type == "InitDidFinish" then

    elseif type == "LoginResult" then
        print("TBcallback   loginretult")
    elseif type == "Logout" then
        print("TBcallback   Logout")

        if not mainScene then return end
        mainScene:removeAllChildrenWithCleanup(true)
        setLocalViarsNil(getpresentgamestatus())
        mainScene:removeFromParentAndCleanup(true)
        mainScene = nil
        setMianNIl()

        --移除全部纹理
        CCTextureCache:sharedTextureCache():removeAllTextures()
        --移除全部精灵帧
        CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFrames()

        loginScene = CCScene:create()
        loginScene:addChild(createLoginLayer())
        if bRunWithScene then
            CCDirector:sharedDirector():replaceScene(loginScene)
        else
            CCDirector:sharedDirector():replaceScene(loginScene)
        end

        UIRequestEx({ type = 1})
        --UIRequest({type = 1})

    elseif type == "LeavedPlatformwithoutlogin" then
        local myfile = require"myfile"
        myfile.osexit()
    elseif type == "InitDidFinish" then

    end
end

function SDK.majiaBuy(self,productid)
      return self.channel:majiaBuy(productid)
end

function SDK.getMaJiaGold(self)
      return self.channel:getMaJiaGold()
end

function SDK.showHP(self,hpurl)
     cclog("SDK.showHP url:"..hpurl)
     gamedata.sdk.h5RechargeUrl = hpurl
    -- gamedata.h5RechargeUrl = hpurl
end


function SDK.openHP(self)
    cclog("SDK.showHP openHP:")
    return self.channel:openHP()
end


function SDK.closeHP(self)
    cclog("SDK.closeHP")
    UIResponse({type = 100011})
end

--跳入实名认证
function SDK.toIDCard(self)
    self.channel:toIDCard()
end


SDK.sensitiveWord = {"敏感词","毛宇新","毛泽东","色情","情色","习近平","李克强","张德江","俞正声","刘云山","李建国","李源潮","江泽民","胡锦涛","骚货",
    "一党专政","一夜情","三陪女","两个中国","一中一台","六四","六四运动","台湾独立","台独","台独万岁","台独分子","台湾国","吴邦国","妓女","天安门事件","小 姐",
    "小姐","打倒共产党","援交","摩门教","新疆分裂","新疆暴乱","新疆独立","新疆国","民主潮","民进党","中国民主","民主不能等待","递进民主","空中民主墙","西藏国家民主党",
    "法轮大法","法轮功","纳粹","贾庆林","造反","骚逼","钓鱼岛","尖阁列岛",
}


return SDK
   ��  