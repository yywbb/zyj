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

    idCardStatus = -1,
    loading_time = nil
}

local deviceApi = require"device"
require("Prompts")
local config = require"a_config"

function SDK.init(self)
    cclog("SDK.init")
    gamedata.gameconfig = config.config
    gamedata.isshowlog = config.config.isshowlog
    gamedata.isdebug = config.config.isdebug

    self.channelname = gamedata.gameconfig.channel
    self.channelid = gamedata.gameconfig.channelid
    self.isShowUserAgreement = gamedata.gameconfig.isShowUserAgreement
    self.isHideLicense = gamedata.gameconfig.isHideLicense
    local addressconfig = require"adpat_code.sdk.addressConfig"
    self.address = addressconfig[self.channelname]
end
SDK:init()


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
        local  channelid = gamedata.gameconfig.channelid or "" 
        local  channelname = gamedata.gameconfig.channel or ""
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
            self.channel = require("adpat_code/sdk/AndroidSDK_common")
        -- elseif deviceApi.channel == "iiapple" then
        --     print("pp start sdk")
        --     self.channel = require(deviceApi.channel)
        else
            print("itools start sdk is ")
           self.channel = require("adpat_code/sdk/iosSDK_common")
        end
    end
    self.channelname = deviceApi.channel
    self.channelid = deviceApi.channelid
end


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

    if gamedata.gameconfig.isHttpLogin and gamedata.gameconfig.isHttpLogin == "true" then
        if self.channelname == "muyoutest" then
            local acctest = require"accbyhttp/http_acctest"
            acctest:autologin()
        else
            if gamedata.sdk.isShowUserAgreement then 
                if CCUserDefault:sharedUserDefault():getStringForKey("userAgreement") ~= "true" then
                    UIResponse({type = 9998, log = "渠道登录" })
                    gameWindowslogin:openWindow("userAgreement",{},function()end)
                else
                    self.channel:Login()
                end
            else
                self.channel:Login()
            end

        end        
    else
        local updater = require"accServerInfoupdate"
        updater:checkifneedupdate(self.address.serverInfoAddress,function()
            if self.channelname == "muyoutest" then
                UIRequest({type=3,devicemodel = gamedata.device.model,systemVersion = gamedata.device:getsystemVersion()})
            else
                self.channel:Login()
            end
        end)
    end
end

function SDK.CreateRole(self,name)

    return self.channel:CreateRole(name)
  
end

function SDK.BtnChannelLogin(self)
    return self.channel:BtnChannelLogin()
end

function SDK.sdkShengDu(self,types)
    return self.channel:sdkShengDu(types)

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

    return self.channel:LoginTencent(platform)
end


function SDK.loginAccountSuc(self,uid)

    if self.channel.loginAccountSuc then
        self.channel:loginAccountSuc(uid)
    end

end

function SDK.loginSuccess(self,t)
     print("SDK.loginSuccess")
    if deviceApi.channel == "huawei" or self.channelname == "huawei" then
        local luaj = require"luaj"
        local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
        local javaMethodName = "loginSuccess"
        local javaMethodSig = "()V"
        return luaj.callStaticMethod(javaClassName, javaMethodName, "", javaMethodSig)
    elseif string.find(self.channelname,"qq")~=nil or string.find(self.channelname,"weixin")~=nil  or string.find(self.channelname,"tencent")~=nil then
       gamedata.sdk.channel.loginId = 1
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
        UIRequest({type = 10002, openid = tencent_openid, openkey =tencent_openkey, pf = tencent_pf, pfkey = tencent_pfKey, paytoken =  tencent_paytoken})

    elseif gamedata.device.channel == "chujiani" or gamedata.device.channel == "chujianii" or gamedata.device.channel == "anfengbz" or gamedata.device.channel == "anfengsw" or gamedata.device.channel == "anfengfk" or gamedata.device.channel == "anfengjj"
          or gamedata.device.channel == "anfengswhd" or gamedata.device.channel == "anfengsgy" or gamedata.device.channel == "hanfengfg"or gamedata.device.channel == "hanfengdq" or gamedata.device.channel == "anfengwd" or gamedata.device.channel == "anfengygn" 
          or gamedata.device.channel == "anfengswg" or gamedata.device.channel == "fanzuozyj" or gamedata.device.channel == "muyouzyj" or gamedata.device.channel == "zuoyaojiapple" or gamedata.device.channel == "zuoyaojihdios" or gamedata.device.channel == "YYLAppStore" 
           or gamedata.device.channel == "zuoyaojihdios2" or gamedata.device.channel == "zuoyaojiapple2" or string.find(gamedata.device.channel,"muyou") then
            print("chujiani loginsuccess")
            if t.user == "0" then
                print("loginsuccess----")
                sdk:loginAccountSuc(tostring(t.uid));
            end
    else    
        print("loginsuccess else")
         gamedata.sdk.channel.loginId = 1

         if t.user and t.user == "0" and t.uid then
             print("loginsuccess----")
            sdk:loginAccountSuc(tostring(t.uid));
        end

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

function SDK.changeUser(self)
    return self.channel:changeUser()
end

function SDK.Logout(self)
    cclog("SDK.Logout")
    local uiqueue = require("uiqueue")
    uiqueue.setresponsetoui({type=999911})
end

function SDK.LogoutAndLogin(self,uid,uuid,ucid,systemVersion)

    cclog("SDK.LogoutAndLogin")
    cclog("SDK.LogoutAndLogin: "..uid.." "..uuid.." "..ucid)
    local uiqueue = require("uiqueue")
    uiqueue.setresponsetoui({type=999911,uid = uid,uuid = uuid,ucid = ucid,systemVersion=systemVersion})

end




function SDK.Recharge(self, rechargeTb)

    printT(rechargeTb)
    --商品订单号
    local order = rechargeTb.rechargeData["1"].i--订单号
    local rmb = rechargeTb.configData.rmb    --商品价钱
    local name = rechargeTb.configData.name  --商品名称
    local desc = rechargeTb.configData.desc  --商品描述
    local getGold = tostring(rechargeTb.configData.gold)  --得到的元宝数

    local parma1 = ""
    local parma2 = ""
    local parma3 = ""
    local parma4 = ""
    local parma5 = ""
    local parma6 = ""
    if rechargeTb.rechargeData["2"] then
        if deviceApi.channel == "mz" then
            parma1 = tostring(rechargeTb.rechargeData["2"].i)
        else
            parma1 = rechargeTb.rechargeData["2"].s or ""
        end    
    end    
     if rechargeTb.rechargeData["3"] then
        parma2 = rechargeTb.rechargeData["3"].s or ""
    end  
     if rechargeTb.rechargeData["4"] then
        parma3 = rechargeTb.rechargeData["4"].s or ""
    end  
     if rechargeTb.rechargeData["5"] then
        parma4 = rechargeTb.rechargeData["5"].s or ""
    end  
     if rechargeTb.rechargeData["6"] then
        parma5 = rechargeTb.rechargeData["6"].s or ""
    end  
     if rechargeTb.rechargeData["7"] then
        parma6 = rechargeTb.rechargeData["7"].s or ""
    end  

    local goodsid = ""
    --如果配置了rechargeTag就用，没有配置就默认使用common_id 列
    if (gamedata.gameconfig.rechargeTag and gamedata.gameconfig.rechargeTag ~= "") then
         local rechargetag = gamedata.gameconfig.rechargeTag
         goodsid = rechargeTb.configData[rechargetag] or ""
    else
         goodsid = rechargeTb.configData.common_id or ""
    end    
    return self.channel:RechargeAllData(order,rmb,name,desc,getGold,goodsid,parma1,parma2,parma3,parma4,parma5,parma6)
   
    -- if deviceApi.channel == "uc" then
    --      --角色等级
    --      local parma1 = rechargeTb.rechargeData["2"].s
    --      local parma2 = rechargeTb.rechargeData["3"].s
    --      local parma3 = rechargeTb.rechargeData["4"].s
    --      local parma4 = rechargeTb.rechargeData["5"].s
    --      local parma5 = rechargeTb.rechargeData["6"].s
    --      local parma6 = rechargeTb.rechargeData["7"].s
    --      return self.channel:RechargeUC(order, rmb, name, rechargeTb.level,parma1,parma2,parma3,parma4,parma5,parma6)

    -- elseif deviceApi.channel == "lenovo" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.lenovo_number)

    -- elseif deviceApi.channel == "sogou" then
    --     return self.channel:Recharge(order, rmb, name, getGold)

    -- elseif deviceApi.channel == "mz" then
    --     local mzCreatT = rechargeTb.rechargeData["2"].i
    --     local times = tostring(mzCreatT)
    --     local mzSign = rechargeTb.rechargeData["3"].s
    --     return self.channel:RechargeMZ(order,times, mzSign, rmb, name, desc)

    -- elseif deviceApi.channel == "vivo" or deviceApi.channel == "vivon" then
    --     local vvAccesskey = rechargeTb.rechargeData["2"].s
    --     local vvOrderNumber = rechargeTb.rechargeData["3"].s
    --     return  self.channel:RechargeVV(order,vvOrderNumber, vvAccesskey, rmb, name, desc)

    -- elseif deviceApi.channel == "xsdk" then
    --     --serverData.name  --服务器名字  serverData.id   --服务器ID
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.serverData.name)

    -- elseif deviceApi.channel == "pp" then
    --     --serverData.name  --服务器名字  serverData.id   --服务器ID
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.paltformGuid)

    -- elseif deviceApi.channel == "coolpad" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.coolpad_number)

    -- elseif deviceApi.channel == "cc" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.cc_number)

    -- elseif deviceApi.channel == "dome" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.dome_id)
    -- elseif deviceApi.channel == "icejoy" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.icejoy_id)

    -- elseif deviceApi.channel == "pyw" or deviceApi.channel == "papa" or deviceApi.channel == "yyh" or deviceApi.channel == "xmgame" or deviceApi.channel == "linnyou" or deviceApi.channel == "yuewen" or deviceApi.channel == "qqreader" then
    --     --公共商品id
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.common_id)

    -- elseif deviceApi.channel == "gionee" then
    --     return self.channel:Recharge(order, rmb, name, desc)
    -- elseif deviceApi.channel == "xmw" then
    --     local xmwOrderId = rechargeTb.rechargeData["2"].s
    --     return self.channel:Recharge(order, rmb, name, xmwOrderId)

    -- elseif deviceApi.channel == "chujiani" or deviceApi.channel == "chujianii" or deviceApi.channel == "zuoyaojihdios"  or deviceApi.channel == "zuoyaojiapple" or deviceApi.channel == "zuoyaojihdios2" or deviceApi.channel == "zuoyaojiapple2" or deviceApi.channel =="muyoufyj" 
    --      or deviceApi.channel == "muyouygqn" or deviceApi.channel == "muyouygqn" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.app_goodId)
    -- elseif deviceApi.channel == "muyouldty"   then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.app_goodId2)
    -- elseif deviceApi.channel == "changba"  then

    --     local cporder = rechargeTb.rechargeData["2"].s
        
    --     return self.channel:Recharge( order, rmb, cporder, rechargeTb.configData.common_id)
    -- elseif deviceApi.channel == "qingyuanmy" then   
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qingyuanmy) 
    -- elseif  deviceApi.channel == "qingyuanhy" then
    --     printT(rechargeTb)

    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qingyuanhy) 
    -- elseif deviceApi.channel == "anqusw" or deviceApi.channel == "tutufk" or deviceApi.channel == "anquxy" or deviceApi.channel == "anquyjl" 
    --     or deviceApi.channel == "anquyjd" or deviceApi.channel == "tuturx"  or deviceApi.channel == "tutukpx"  or deviceApi.channel == "tutumh"  
    --     or deviceApi.channel == "tutukps" or deviceApi.channel == "tutuhlw" or deviceApi.channel == "tutuhlx"  or deviceApi.channel == "anqunewfk"
    --     or deviceApi.channel == "anqurxn" or deviceApi.channel == "anqurnewmh" or deviceApi.channel == "anqunewhlx" or deviceApi.channel == "anqunewhlw" then    
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anqu_channel) 
    -- elseif deviceApi.channel =="hanfengbx" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengbx) 
    -- elseif deviceApi.channel =="hanfengqm" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengqm)    
    -- elseif deviceApi.channel =="hanfengfg" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengfg)    
    -- elseif deviceApi.channel =="hanfengdq" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengdq)    
    -- elseif deviceApi.channel =="hanfengmw" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengmw)    
    -- elseif deviceApi.channel =="hanfengbg" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengbg)   
    -- elseif deviceApi.channel =="hanfengsg" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengsg) 
    -- elseif deviceApi.channel =="hanfengls" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengls) 
    -- elseif deviceApi.channel =="hanfengzl" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengzl) 
    -- elseif deviceApi.channel =="hanfengfk" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengfk) 
    -- elseif deviceApi.channel =="hanfengyj" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengyj) 
    -- elseif deviceApi.channel =="hanfengsn" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengsn) 
    -- elseif deviceApi.channel =="hanfengsgk" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengsgk) 
    -- elseif deviceApi.channel =="hanfengld" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengld_channel) 
    -- elseif deviceApi.channel =="hanfengkp"  then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengkp) 
    -- elseif deviceApi.channel =="hanfengxy"  then    
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengxy) 
    -- elseif deviceApi.channel =="hanfengdqx" or deviceApi.channel =="hanfenglds" or deviceApi.channel =="hanfenghlx" or deviceApi.channel =="hanfengcq" or deviceApi.channel =="hanfengqms" or deviceApi.channel =="hanfengsj" then    
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hanfengnew) 
    -- elseif deviceApi.channel =="jingxunmw" or deviceApi.channel =="jingxunmy" or deviceApi.channel =="jingxunlt" or deviceApi.channel =="jingxunfs" or deviceApi.channel =="jingxunyj" or deviceApi.channel =="jingxunltc" or deviceApi.channel =="jingxunlta"
    --    or  deviceApi.channel =="jingxundh" or  deviceApi.channel =="jingxuncy" or  deviceApi.channel =="jingxunyja" or  deviceApi.channel =="jingxunltca" or  deviceApi.channel =="jingxunyq" or  deviceApi.channel =="jingxunxyj" 
    --    or  deviceApi.channel =="jingxunsx" or  deviceApi.channel =="jingxunydmm" then
    --      cclog("SDK.recharge: "..order.." "..rmb.." "..name.." "..rechargeTb.configData.jingxun_channel)
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.jingxun_channel) 
    -- elseif  deviceApi.channel =="jingxunbz" then   
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.jingxun_channel2)  
    -- elseif deviceApi.channel =="9377" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377_channel)   
    -- elseif deviceApi.channel =="9377jj" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377jj_channel)
    -- elseif deviceApi.channel =="9377bym" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377bym_channel)
    -- elseif deviceApi.channel =="9377bys" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377bys_channel)
    -- elseif deviceApi.channel =="9377wd" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377wd_channel)
    -- elseif deviceApi.channel =="9377jmf" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377jmf_channel)
    -- elseif deviceApi.channel =="9377mfb" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377mfb_channel)
    -- elseif deviceApi.channel =="9377wsx" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ios9377wsx_channel)
    -- elseif deviceApi.channel =="anfengbz" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_bz)
    -- elseif deviceApi.channel =="anfengsw" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_sw)
    -- elseif deviceApi.channel =="anfengfk" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_fk)
    -- elseif deviceApi.channel =="anfengjj" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_jj)
    -- elseif deviceApi.channel =="anfengwd" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_wd)
    -- elseif deviceApi.channel =="anfengswhd" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_swhd)
    -- elseif deviceApi.channel =="anfengygn" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_ygn)
    -- elseif deviceApi.channel =="anfengsgy" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_sgy)    
    -- elseif deviceApi.channel =="anfengswg" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.anfeng_swg)   
    -- elseif deviceApi.channel =="asm8" or deviceApi.channel =="asm8my" or deviceApi.channel =="asm8yj" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.channel_asm8)
    -- elseif deviceApi.channel =="asm8ygd" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.channel_asm8ygd)
    -- elseif deviceApi.channel =="huanwen" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.huanwen_ioschannel)
    -- elseif deviceApi.channel =="cyxfs" or deviceApi.channel =="cyxxy" or deviceApi.channel =="cyxdn" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.cyx_channel)
    -- elseif deviceApi.channel =="muyouzyj" then 
    --    return self.channel:Recharge(order, rmb, name, rechargeTb.configData.muyouzyj_channel)
    -- elseif deviceApi.channel =="wanmiandroid" or deviceApi.channel =="wanmiios" or deviceApi.channel =="aishangi"  then    
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.common_id)
    -- elseif deviceApi.channel =="hanfenga" or deviceApi.channel =="beiyouaQM" or deviceApi.channel =="aishanga"then    
    --     return self.channel:Recharge2(order, rmb, name, desc, rechargeTb.configData.common_id)
    -- elseif deviceApi.channel =="jingqi" then    
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.jingqi_channel)
    -- elseif deviceApi.channel =="beiyouqm" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.beiyouqm_channel)
    -- elseif deviceApi.channel =="beiyoukp" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.beiyoukp_channel)
    -- elseif deviceApi.channel =="fanzuozyj" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.fanzuozyj_id)
    -- elseif deviceApi.channel =="cvSF" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.cvsf_channel)
    -- elseif deviceApi.channel =="kyYG" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.kyyg_channel)
    -- elseif deviceApi.channel =="hangmeiYMDSG" or deviceApi.channel =="hangmeiYJDLM" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.hangmeiRecharge)
    -- elseif deviceApi.channel == "x7syn" then
    --     local gameSign = rechargeTb.rechargeData["2"].s
    --     return self.channel:Recharge(order, rmb, desc, gameSign)
    -- elseif deviceApi.channel == "tjLSJ" then
        
    --     if deviceApi.channelid == 100161001 then 
    --         return self.channel:Recharge(order, rmb, name, rechargeTb.configData.tjZYLJ)
    --     elseif deviceApi.channelid == 100161000 then 
    --         return self.channel:Recharge(order, rmb, name, rechargeTb.configData.tjLSJ)
    --     end
    -- elseif deviceApi.channel == "fzSSNYJ" then
    --     --凡卓更改新的流程，以后参数和渠道标识都用一个，只有channelid不同
    --     if deviceApi.channelid == 100161003 then 
    --         return self.channel:Recharge(order, rmb, name, rechargeTb.configData.fzYSJ)
    --     elseif deviceApi.channelid == 100161001 then 
    --         return self.channel:Recharge(order, rmb, name, rechargeTb.configData.fzYSCS)
    --     elseif deviceApi.channelid == 100161000 then 
    --         return self.channel:Recharge(order, rmb, name, rechargeTb.configData.fzSSNYJ)
    --     else
    --         return self.channel:Recharge(order, rmb, name, rechargeTb.configData.fzSSNYJ)
    --     end
    -- elseif deviceApi.channel == "qiyuiosDYZ" then
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosDYZ)
    -- elseif deviceApi.channel == "qiyuiosXYGX" then
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosXYGX)
    -- elseif deviceApi.channel == "qiyuiosPHSG" then
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosPHSG) 
    -- elseif deviceApi.channel == "qiyuiosGMDCC" then
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosGMDCC) 
    -- elseif deviceApi.channel == "qiyuiosDDXYJ" then
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosDDXYJ)
    -- elseif deviceApi.channel == "qiyuiosJZSGWS" then     
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosJZSGWS)
    -- elseif deviceApi.channel == "ydiosXYJ" then
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ydiosXYJ) 
    -- elseif deviceApi.channel == "ydiosJYJ" then
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.ydiosJYJ) 
    -- elseif string.find(deviceApi.channel,"jingqiIos") then    
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.jingqiIosCASG)
    -- elseif deviceApi.channel == "qiyuiosWWYM" then     
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosWWYM)
    -- elseif deviceApi.channel == "qiyuiosXYSSN" then
    --     return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosXYSSN) 
    -- elseif deviceApi.channel == "qiyuiosSYMX" then     
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosSYMX)
    -- elseif deviceApi.channel == "qiyuiosSJYYQ" then     
    --      return self.channel:Recharge(order, rmb, name, rechargeTb.configData.qiyuiosSJYYQ)
    -- else
    --     return self.channel:Recharge(order, rmb, name, desc)
    -- end
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

    local roleId  = params.roleId or ""
    local roleLv = params.roleLv or 1
    local roleName = params.roleName or ""
    local serverId = params.serverId or 1
    local severName = params.severName or ""
    local vip = params.vip or 1
    local gold = params.gold or 1
    local  ext1 = params.platformId or ""
    local  ext2 = params.platforName or ""
    local  ext3 =  ""

    -- print(severName)
    -- print(roleId)
    -- print(roleName)

    return self.channel:UserInformationAllData(roleId, roleName, roleLv, serverId, severName, vip, gold, ext1, ext2, ext3)

    -- if deviceApi.channel == "360" then
    --     return self.channel:UserInformation2(params.roleId, params.platforName, params.roleLv, params.serverId,params.platformId,params.roleName,params.severName,params.vip,params.gold,"0")
    -- elseif  deviceApi.channel == "coolpad" then
    --      return self.channel:UserInformation(params.roleuid, params.platformId, params.roleLv, params.serverId,params.platforName)
    -- elseif deviceApi.channel == "mi" or deviceApi.channel == "mi2" then
    --     return self.channel:UserInformation2(params.roleId, params.roleName, params.roleLv, params.vip, params.severName, params.gold)
    -- elseif deviceApi.channel == "uc" or deviceApi.channel == "oppo" or deviceApi.channel == "huawei" or deviceApi.channel == "pptv" or deviceApi.channel == "dangle" or deviceApi.channel == "vivo" or deviceApi.channel == "vivon" or deviceApi.channel == "pps" or deviceApi.channel == "yumi" or deviceApi.channel == "jingxunmw" 
    --      or deviceApi.channel == "jingxunmy" or deviceApi.channel == "jingxunlt" or deviceApi.channel =="jingxunfs" or deviceApi.channel =="jingxunyj"or deviceApi.channel =="jingxunltc" or deviceApi.channel =="jingxunlta"  or deviceApi.channel =="jingxundh" or deviceApi.channel =="jingxuncy" or deviceApi.channel =="jingxunltca"
    --      or deviceApi.channel == "anfengbz" or deviceApi.channel == "anfengsw" or deviceApi.channel == "jingxunyja" or deviceApi.channel == "asm8" or deviceApi.channel == "jingxunyq" or deviceApi.channel == "jingxunbz" or deviceApi.channel == "anfengfk" or deviceApi.channel == "anfengjj" or deviceApi.channel == "hanfengsn" 
    --      or deviceApi.channel == "hanfengsgk" or deviceApi.channel == "jingxunxyj" or deviceApi.channel == "anfengswhd" or deviceApi.channel == "asm8my" or deviceApi.channel == "anfengsgy" or deviceApi.channel == "asm8yj" or deviceApi.channel == "anfengwd"  or deviceApi.channel =="jingxunsx" or deviceApi.channel =="jingxunydmm" 
    --       or deviceApi.channel == "anfengygn" or deviceApi.channel == "anfengswg" or deviceApi.channel == "asm8ygd" then 
    --     return self.channel:UserInformation(params.roleId, params.roleName, params.roleLv, params.serverId,params.severName)
    -- elseif deviceApi.channel == "hanfengbx"  or deviceApi.channel == "hanfengqm"  or deviceApi.channel == "hanfengfg"  or deviceApi.channel == "hanfengjg"  or deviceApi.channel == "hanfengjz"  or deviceApi.channel == "hanfengwy" or deviceApi.channel == "hanfengsg" or deviceApi.channel == "hanfengls"
    --      or deviceApi.channel == "hanfengyj" or deviceApi.channel == "hanfengfk" or deviceApi.channel == "hanfengzl" or deviceApi.channel == "hanfengkp" or deviceApi.channel == "hanfengxy" or  deviceApi.channel =="hanfengdqx" or deviceApi.channel =="hanfenglds" or deviceApi.channel =="hanfenghlx" 
    --      or deviceApi.channel =="hanfengcq" or deviceApi.channel =="hanfengqms" or deviceApi.channel =="hanfengsj" then  
    --     cclog("SDK.UserInformation sdklv:"..SDK.rolelv)
    --     local parmaslv = tonumber(params.roleLv)
    --     cclog("SDK.UserInformation rolelv:"..params.roleLv)
    --     if SDK.rolelv == 0 then
    --         SDK.rolelv = parmaslv 
    --         return self.channel:UserInformation(params.roleId, params.roleName, params.roleLv, params.serverId,params.severName)
    --     end 
    -- elseif  deviceApi.channel == "anzhi" or deviceApi.channel == "anfeng" or deviceApi.channel == "kugou" or deviceApi.channel == "chujiani" or deviceApi.channel == "chujianii" or deviceApi.channel == "kaopu" or deviceApi.channel == "anqu" or deviceApi.channel == "chujiana" or deviceApi.channel == "baiducmcj" 
    --      or deviceApi.channel == "zuoyaojiapple" or deviceApi.channel == "zuoyaojiapple2" or deviceApi.channel == "zuoyaojihdios" or deviceApi.channel == "zuoyaojihdios2"  then
    --     return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,params.severName)
    -- elseif deviceApi.channel == "papa" or deviceApi.channel == "tt" or deviceApi.channel == "xmw" or deviceApi.channel == "linnyou" or deviceApi.channel == "51iyx" or deviceApi.channel == "xxi" or deviceApi.channel == "i4" or deviceApi.channel == "bt" then
    --     return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,params.severName)
    -- elseif  deviceApi.channel == "xmgame" or  deviceApi.channel == "youmi" or  deviceApi.channel == "lb" then
    --     return self.channel:UserInformation3(params.roleuid, params.roleName, params.roleLv, params.serverId, params.severName, params.gold, params.vip)
    -- elseif  deviceApi.channel == "yuewen" or deviceApi.channel == "lhh" or deviceApi.channel == "wanke" or deviceApi.channel == "7k7k" or deviceApi.channel == "x7sy" or deviceApi.channel == "x7syn" or  deviceApi.channel == "aphy"  or  deviceApi.channel == "sw" 
    --     or deviceApi.channel == "qqreader" or deviceApi.channel == "wdj" or deviceApi.channel == "gavegame" then
    --     return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,params.severName)
    -- elseif  deviceApi.channel == "tiantian" or deviceApi.channel == "xxa" or deviceApi.channel == "qingyuanmy" or deviceApi.channel == "qingyuanhy" or deviceApi.channel == "anqusw" 
    --     or deviceApi.channel == "tutufk" or deviceApi.channel == "anquxy" or deviceApi.channel == "anquyjl" or deviceApi.channel == "anquyjd" or deviceApi.channel == "tuturx"  or deviceApi.channel == "yeshen" 
    --      or deviceApi.channel == "tutukpx"  or deviceApi.channel == "tutumh" or deviceApi.channel == "tutukps" or deviceApi.channel == "9377" or deviceApi.channel == "9377jj" or deviceApi.channel == "9377bym" 
    --       or deviceApi.channel == "9377bys" or deviceApi.channel == "9377wd" or deviceApi.channel == "yuxiang" or deviceApi.channel == "tutuhlw" or deviceApi.channel == "tutuhlx" or deviceApi.channel == "9377a" 
    --       or deviceApi.channel == "anqurxn"  or deviceApi.channel == "anqurnewmh" or deviceApi.channel == "anqunewhlx" or deviceApi.channel == "anqunewhlw"  
    --       or deviceApi.channel == "9377jmf" or deviceApi.channel == "9377mfb" or deviceApi.channel == "9377wsx" or deviceApi.channel == "hanfenga" or deviceApi.channel == "jingqi"  or deviceApi.channel =="beiyouqm" or deviceApi.channel =="beiyoukp"
    --       or deviceApi.channel == "beiyouaQM"  or deviceApi.channel == "xigu" or deviceApi.channel == "kyYG" then
    --     return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,params.severName)
    -- elseif  deviceApi.channel == "le8"then
    --     local le8Info = params.severName .. " | ".. params.roleName .. " | lv:" .. params.roleLv
    --     return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,le8Info)
    -- elseif  deviceApi.channel == "xsdk" then
    --     return self.channel:UserInformation(params.roleuid, params.roleName, params.roleLv, params.serverId,params.paltformGuid)
    -- elseif deviceApi.channel == "19yx" or deviceApi.channel == "xiaomiyxf" or deviceApi.channel == "xiaomiwq" or deviceApi.channel == "xiaomikm" or deviceApi.channel == "styj" or deviceApi.channel == "fanzhuo" 
    --         or deviceApi.channel == "hangmeiYMDSG" or deviceApi.channel == "hangmeiYJDLM" then
    --      return self.channel:UserInformation19(params.roleuid, params.roleName, params.roleLv, params.serverId,params.severName, params.vip, params.gold)
    -- elseif deviceApi.channel == "jipings" or deviceApi.channel == "jipingm" or deviceApi.channel == "wanmiandroid" or deviceApi.channel == "wanmiios" or deviceApi.channel == "qphy" or deviceApi.channel == "aishanga" or deviceApi.channel == "aishangi" or deviceApi.channel == "qphy666sdk" 
    --      or (deviceApi.platform == "android" and string.find(deviceApi.channel,"qiyu")) or string.find(deviceApi.channel,"jingqiA")  then
    --      return self.channel:UserInformation19(params.roleId, params.roleName, params.roleLv, params.serverId,params.severName, params.vip, params.gold)
    -- elseif string.find(deviceApi.channel,"qq")~=nil or string.find(deviceApi.channel,"weixin")~=nil  or string.find(deviceApi.channel,"tencent")~=nil then
        
    --     return self.channel:UserInformation(params.roleId, params.roleName, params.roleLv, params.serverId <= 2 and 1 or params.serverId ,params.severName)
    -- else
    --      return self.channel:UserInformation(params.roleId, params.roleName, params.roleLv, params.serverId,params.severName)
    -- end
end


--游戏兑换礼包接口（拇指玩的需要）
function SDK.PostGift(self,giftCode)
    return self.channel:PostGift(giftCode)
end


function SDK.LoginTokenIos(self,token) 

    return self:LoginToken(token)
end

--登录成功后的token 或者 uid ，服务器推送的
function SDK.LoginToken(self,token)
    
    return self.channel:LoginToken(token)
   
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

function SDK.forceUpdate(self,url)
    cclog("SDK.forceUpdate")

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
        self:Logout()
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

--登录相关状态重置
function SDK.loginOutStatusRest(self)
    cclog("SDK.loginOutStatusRest")
    if self.channel.loginOutStatusRest then
      self.channel:loginOutStatusRest()
    end    

end

--初次登陆用户
function SDK.newUerRegister(self)
    cclog("SDK.newUerRegister")
    if self.channel.newUerRegister then
        self.channel:newUerRegister()
    end
end

function SDK.sdkShengDu(self,sdtype)
    cclog("SDK.sdkShengDu")
    return self.channel:sdkShengDu(sdtype)
end

function SDK.reLogin(self)
    return self.channel:reLogin()
end

--[[
广告接口：
sysType:系统编号
1   聚宝盆
2   奇遇
3   免费好礼
params:回调参数table
]]--

function SDK.showAd(self,sysType,params)
    print("SDK.showAd")
    loading:startGameloadingRechage()
    local nowtime = 1;
    loading_time = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        print("nowtime ======     ", nowtime)
        nowtime = nowtime + 1
        if nowtime >= 3 then
            loading:stopGameloadingRechage()
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(loading_time)
            loading_time = nil
            nowtime = 1
            printT(params,"tableParams")
            UIRequest(params)
        end
    end, 1, false)
    local json = MakeJsonStringFromTable(params)
    local audio =  require"audio"
    audio.pauseMusic()
    self.channel:showAd(sysType,json)
end

--广告回调
function SDK.adCallBack(self,verify,params)
    print("SDK.adCallBack:",params)
    local audio =  require"audio"
    audio.resumeMusic() 
end

function SDK.runGamePrompt(self,dataTable)

    local promptLoaderLayer, ccbDocumentControler = CCBReaderLoad("Prompts/GamePrompt", nil, true, "GamePrompt")

    local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local frameSize = openGLView:getFrameSize()

    promptLoaderLayer:setPosition(ccp(frameSize.width/2, frameSize.height * 0.618))
    ccbDocumentControler.node:setScale(frameSize.width/1080)

    local nowScene = CCDirector:sharedDirector():getRunningScene()
    nowScene:addChild(promptLoaderLayer,10000)

    local promptLabel = tolua.cast(ccbDocumentControler.promptLabel, "CCLabelTTF") --提示信息label
    promptLabel:setString(dataTable["msg"] or "")

    -------------------------------------------------------------------------------------------------------------------
    local animationManager = getAnimationManager(ccbDocumentControler)
    --动画完成操作
    animationManager:setAnimationCompletedCallback(function()
    --移除
        promptLoaderLayer:removeFromParentAndCleanup(true)
    end)
    --先播放动画
    animationManager:runAnimationsForSequenceNamed("prompt")
end

return SDK
 W�  