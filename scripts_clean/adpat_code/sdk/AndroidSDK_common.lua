require"log"

local device = require"device"
local gamedata = require"gamedata"

local AndroidSDK_common = {
    messageNum = 99,
    uid = nil,
    uuid = nil,
    ucid = nil,
    relogtimer = nil,
    systemVersion = ""
}

--登录sdk
function AndroidSDK_common.Login(self)
	local isinited = false
	self.relogtimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
		local luaj = require"luaj"
	    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
	    local javaMethodName = "getIsinit"
	    local javaMethodSig = "()Z"
	    local result,isinited_ = luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig);
	    isinited = isinited_;

	    if isinited then
            UIResponse({type = 9998, log = "渠道登录..." })
	    	--local luaj = require"luaj"
		    --local javaClassName = "com/ldfs/sanguo2/CommonSDK_Utils"
		    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
		    local javaMethodName = "Login"
		    local javaMethodSig = "()V"
		    luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig);
		    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.relogtimer)
	    end
	end, 0.3, false)

end


function AndroidSDK_common.BtnChannelLogin(self)
    cclog("AndroidSDK_common.BtnChannelLogin %s ",platform)
    local luaj = require"luaj"
    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
    local javaMethodName = "BtnChannelLogin"
    local javaMethodSig = "()V"
    luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig);
end

-- egame 更多游戏
function AndroidSDK_common.EgameMoreGame(self)
    cclog("AndroidSDK_common.EgameMoreGame %s ",platform)
    local luaj = require"luaj"
    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
    local javaMethodName = "EgameMoreGame"
    local javaMethodSig = "()V"
    luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig);
end

--腾讯登录
function AndroidSDK_common.LoginTencent(self,platform)
   
	cclog("AndroidSDK_common.LoginTencent %s ",platform)
	local luaj = require"luaj"
	local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
	local javaMethodName = "LoginTencent"
	local javaParams = {platform}
	local javaMethodSig = "(Ljava/lang/String;)V"
	luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);

end


--登录游戏
function AndroidSDK_common.LoginCB(self, uid, uuid, ucid, systemVersion, isChageData)
     cclog("new AndroidSDK_common.LoginCB: "..uid.." "..uuid.." "..ucid)
    cclog("new AndroidSDK_common.LoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, uuid, ucid)
    
    self.uid = uid
   
    self.ucid = ucid

    --需要转换一下token
    if isChageData and isChageData == "1" then
        cclog("AndroidSDK_common.LoginCB0")
        local gionee_token1 = uuid
        if string.find(uuid,"_@@@_") or string.find(uuid,"_@@_") then
            local gionee_token2 = string.gsub(uuid,"_@@@_","\"");
            cclog("AndroidSDK_common.LinYouLoginCB:  gionee_token2===  %s", gionee_token2)
            gionee_token1 =  string.gsub(gionee_token2,"_@@_","\\");
            cclog("AndroidSDK_common.LinYouLoginCB:  gionee_token===  %s", gionee_token1)
        end   
        self.uuid  = gionee_token1
    else
       cclog("AndroidSDK_common.LoginCB1")
       self.uuid = uuid

    end    


    cclog("AndroidSDK_common.channelid:  uid=  %s  uuid: %s ucid:%s", self.uid, self.uuid,self. ucid)

    UIReponse({ type = 901,needlogin=true, nickname = self.uid, sessionId = self.uuid, uin = self.ucid })

     cclog("AndroidSDK_common.LoginCB2")

end


--判断是否登录
function AndroidSDK_common.isLogin(self)
    if not self.uid then
        return true
    else
        return false
    end
end

--重新登录
function AndroidSDK_common.reLogin(self)
    cclog("AndroidSDK_common.reLogin")
   
end

function AndroidSDK_common.CreateRole(self,name)
    cclog("AndroidSDK_common.CreateRole")
    local luaj = require"luaj"
    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
    local javaMethodName = "CreateRole"
    local javaParams = { name }
    local javaMethodSig = "(Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName,javaMethodName,javaParams,javaMethodSig);
end

--切换账号
function AndroidSDK_common.changeUser(self)
	local luaj = require"luaj"
	--local javaClassName = "com/ldfs/sanguo2/CommonSDK_Utils"
	local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
	local javaMethodName = "ChangeUser"
	local javaMethodSig = "()V"
	luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig)
end


--数据提交
function AndroidSDK_common.UserInformationAllData(self, roleId, rolenName, roleLv, serverId, serverName, vip, gold, ext1, ext2, ext3)
    
    cclog("AndroidSDK_common.UserInformationAllData1 %d    %s ", roleId, rolenName)
    local luaj = require "luaj"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "UserInformationAllData"
    local javaParams = { string.format("%d", roleId), rolenName, string.format("%d", roleLv), serverId, serverName,string.format("%d", vip), string.format("%d", gold),ext1,ext2,ext3 }
    local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end


--充值
function AndroidSDK_common.RechargeAllData(self, orderId, payAmount, goodsName, goodsDesc, gold, goodsId, parma1, parma2, parma3, parma4, parma5, parma6)
    cclog("AndroidSDK_common.RechargeAllData %d    %f    %s    %s ", orderId, payAmount, goodsName, goodsDesc)
    local luaj = require "luaj"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "RechargeAllData"
    local javaParams = { string.format("%d", orderId), payAmount, goodsName, goodsDesc, gold, goodsId, parma1, parma2, parma3, parma4, parma5, parma6 }
    local javaMethodSig = "(Ljava/lang/String;FLjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end



--游戏兑换礼包接口（拇指玩的需要）
function AndroidSDK_common.PostGift(self, giftCode)
    cclog("AndroidSDK_common.PostGift")
    local luaj = require "luaj"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "PostGift"
    local javaParams = { giftCode }
    printT(javaParams)
    local javaMethodSig = "(Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end

--该账号 首次登录游戏成功之后，才会返回
function AndroidSDK_common.loginAccountSuc(self,uid)
    cclog("AndroidSDK_common.loginAccountSuc:  uid=  %s ", uid)
    local luaj = require"luaj"
    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
    local javaMethodName = "loginAccountSuc"
    local javaParams = { uid }
    local javaMethodSig = "(Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName,javaMethodName,javaParams,javaMethodSig);
end

--该账号 登录游戏成功之后 返回token
function AndroidSDK_common.LoginToken(self,token)
    cclog("AndroidSDK_common.LoginToken:  token=  %s ", token)
    local luaj = require "luaj"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "LoginToken"
    local javaParams = {  token }
    local javaMethodSig = "(Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end

--实名认证状态sdk登录成功会自动调用  -1未查询到信息   0 未实名  1 实名的成年  2 实名的未成年
function AndroidSDK_common.SaveIDCard(self, idcardstatus)
     cclog("AndroidSDK_common.saveIDCard:  idcardstatus=  %s ", idcardstatus)
    self.idCardStatus  = idcardstatus
     UIReponse({ type = 902, idCardStatus = self.idCardStatus })
end

--实名认证成功通知 1 实名的成年  2 实名的未成年
function AndroidSDK_common.idCardSuccess(self,updateIdcardStatus)
    cclog("SDK idCardSuccess 实名认证成功回调 %s",updateIdcardStatus)
    self.idCardStatus  = updateIdcardStatus
    UIReponse({ type = 902, idCardStatus = self.idCardStatus })
    --其他更新操作
end

--跳入实名认证
function AndroidSDK_common.toIDCard(self)
     cclog("AndroidSDK_common.toIDCard")
    local luaj = require"luaj"
    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
    local javaMethodName = "toIDCard"
    local javaMethodSig = "()V"
    luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig)
end

--腾讯论坛
function AndroidSDK_common.openLuntan(self)
     cclog("AndroidSDK_common.openLuntan")
    local luaj = require"luaj"
    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
    local javaMethodName = "openLuntan"
    local javaMethodSig = "()V"
    luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig)
end


--登录相关状态重置
function AndroidSDK_common.loginOutStatusRest(self)
      cclog("AndroidSDK_common.loginOutStatusRest")
    local luaj = require"luaj"
    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
    local javaMethodName = "loginOutStatusRest"
    local javaMethodSig = "()V"
    luaj.callStaticMethod(javaClassName,javaMethodName,"",javaMethodSig)
end


--登录相关状态重置
function AndroidSDK_common.sdkShengDu(self,types)
     cclog("AndroidSDK_common.sdkShengDu")
    local luaj = require"luaj"
    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
    local javaMethodName = "sdkShengDu"
    local javaParams = { types }
    local javaMethodSig = "(Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName,javaMethodName,javaParams,javaMethodSig);
end

--广告接口
function AndroidSDK_common.showAd(self,sysType,params)
    cclog("AndroidSDK_common.showAd:  sysType = %d params = %s", sysType,params)
    local luaj = require "luaj"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "showAd"
    local javaParams = {string.format("%d", sysType),params}
    local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end

function AndroidSDK_common.adCallBack(self,verify,params)
    cclog("AndroidSDK_common.adCallBack:  verify = %s params = %s", verify,params)
    gamedata.sdk:adCallBack(verify,params)
end

return AndroidSDK_common



