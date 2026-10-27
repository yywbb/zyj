require"log"

local device = require"device"

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
-- function AndroidSDK_common.LoginCB(self, uid, uuid, ucid, systemVersion)
--      cclog("AndroidSDK_common.LoginCB: "..uid.." "..uuid.." "..ucid)
--     cclog("AndroidSDK_common.LoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, uuid, ucid)
--     self.uid = uid
--     self.uuid = uuid
--     self.ucid = ucid

--     UIRequest({ type = 90, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, messageNum = self.messageNum, devicemodel = device.model, systemVersion = systemVersion })

--     UIReponse({ type = 901, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, })
-- end

--登录游戏
function AndroidSDK_common.LoginCB(self, uid, uuid, ucid, systemVersion,channelid,channelname)
     cclog("AndroidSDK_common.LoginCB: "..uid.." "..uuid.." "..ucid)
    cclog("AndroidSDK_common.LoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, uuid, ucid)
    
    self.uid = uid
    self.uuid = uuid
    self.ucid = ucid
    self.channelid = channelid 
    self.channelname = channelname
    
    if self.channelid ~= "" then 
        self.channelid = tonumber(self.channelid)
    end   
    cclog("AndroidSDK_common.channelid:  uid=  %i  channelame: %s", self.channelid, self.channelname)

    --UIRequest({ type = 90, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, messageNum = self.messageNum, devicemodel = device.model, systemVersion = systemVersion, channelid = self.channelid ,channelname = self.channelname })

    UIReponse({ type = 901,needlogin=true, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, channelid = self.channelid  ,channelname = self.channelname })
end

--tencent登录游戏
function AndroidSDK_common.LoginCBTencent(self, uid, uuid, ucid, systemVersion,channelid,channelname)
     cclog("AndroidSDK_common.LoginCB: "..uid.." "..uuid.." "..ucid)
    cclog("AndroidSDK_common.LoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, uuid, ucid)
    self.uid = uid
    self.uuid = uuid
    self.ucid = ucid


    self.channelid = channelid 
    self.channelname = channelname
    
    if self.channelid ~= "" then 
        self.channelid = tonumber(self.channelid)
    end   

    
    UIRequest({ type = 900001, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, messageNum = self.messageNum, devicemodel = device.model, systemVersion = systemVersion ,channelid = self.channelid  ,channelname = self.channelname })

    UIReponse({ type = 901, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, loginId= 0 ,channelid = self.channelid  ,channelname = self.channelname ,luntan = self.openluntan})
    
    
end

--金立的登录
function AndroidSDK_common.GioneeLoginCB(self,uid,uuid,ucid,systemVersion,channelid,channelname)
	cclog("AndroidSDK_common.GioneeLoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, uuid, ucid)
    
	-- local gionee_token = string.gsub(uuid,"*","\"");

    local gionee_token = uuid
    if string.find(uuid,"_@@@_") or string.find(uuid,"_@@_") then
        local gionee_token2 = string.gsub(uuid,"_@@@_","\"");
        cclog("AndroidSDK_common.GioneeLoginCB:  gionee_token2===  %s", gionee_token2)
        gionee_token =  string.gsub(gionee_token2,"_@@_","\\");
        cclog("AndroidSDK_common.GioneeLoginCB:  gionee_token===  %s", gionee_token)
    end

	print(gionee_token)
	self.uid = uid
	self.uuid = gionee_token
	self.ucid = ucid

    self.channelid = channelid
    self.channelname = channelname
    if self.channelid ~= "" then 
        self.channelid = tonumber(self.channelid)
    end   

	UIRequest({ type = 90, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, messageNum = self.messageNum, devicemodel = device.model, systemVersion = systemVersion, channelid = self.channelid  ,channelname = self.channelname })

    UIReponse({ type = 901, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, channelid = self.channelid  ,channelname = self.channelname })
end

--麟游的登录
function AndroidSDK_common.LinYouLoginCB(self,uid,uuids,ucid,systemVersion,channelid,channelname)
    cclog("AndroidSDK_common.LinYouLoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, uuids, ucid)
    
     local gionee_token1 = uuids
    if string.find(uuids,"_@@@_") or string.find(uuids,"_@@_") then
        local gionee_token2 = string.gsub(uuids,"_@@@_","\"");
        cclog("AndroidSDK_common.LinYouLoginCB:  gionee_token2===  %s", gionee_token2)
        gionee_token1 =  string.gsub(gionee_token2,"_@@_","\\");
        cclog("AndroidSDK_common.LinYouLoginCB:  gionee_token===  %s", gionee_token1)
    elseif string.find(uuids,"%-") then
        local gionee_token2 = string.gsub(uuids,"%+","\"");
        cclog("AndroidSDK_common.LinYouLoginCB:  gionee_token2===  %s", gionee_token2)
        gionee_token1 =  string.gsub(gionee_token2,"%-","\\");
        cclog("AndroidSDK_common.LinYouLoginCB:  gionee_token===  %s", gionee_token1)
    else
        local gionee_token2 = string.gsub(uuids,"@","\"");
        cclog("AndroidSDK_common.LinYouLoginCB:  gionee_token2===  %s", gionee_token2)
        gionee_token1 =  string.gsub(gionee_token2,"%+","\\");
        cclog("AndroidSDK_common.LinYouLoginCB:  gionee_token===  %s", gionee_token1)
    end   

    self.uuid = gionee_token1

     
    print(uids)
    self.uid = uid
    self.ucid = ucid

    self.channelid = channelid
    self.channelname = channelname
    if self.channelid ~= "" then 
        self.channelid = tonumber(self.channelid)
    end   
    cclog("AndroidSDK_common.LinYouLoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, self.uuid, ucid)
    UIRequest({ type = 90, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, messageNum = self.messageNum, devicemodel = device.model, systemVersion = systemVersion, channelid = self.channelid  ,channelname = self.channelname})

    UIReponse({ type = 901, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, channelid = self.channelid  ,channelname = self.channelname })
end

--易接的登录
function AndroidSDK_common.YIJIELoginCB(self,uid,uuids,ucid,systemVersion,channelid,channelname)
    cclog("AndroidSDK_common.YIJIELoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, uuids, ucid)
    local gionee_token = string.gsub(uuids,"@","\"");
     cclog("AndroidSDK_common.YIJIELoginCB:  uid=1===  %s", gionee_token)
     self.uuid = string.gsub(gionee_token,"+","\\");
     cclog("AndroidSDK_common.YIJIELoginCB:  uid=2===  %s", self.uuid)
    print(uids)
    self.uid = uid
    self.ucid = ucid

    self.channelid = channelid
    self.channelname = channelname
    if self.channelid ~= "" then 
        self.channelid = tonumber(self.channelid)
    end   
    cclog("AndroidSDK_common.YIJIELoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, self.uuid, ucid)
    UIRequest({ type = 90, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, messageNum = self.messageNum, devicemodel = device.model, systemVersion = systemVersion,channelid = self.channelid  ,channelname = self.channelname })

    UIReponse({ type = 901, nickname = self.uid, sessionId = self.uuid, uin = self.ucid,channelid = self.channelid  ,channelname = self.channelname })
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
    -- UIRequest({ type = 90, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, messageNum = self.messageNum, devicemodel = device.model, systemVersion = self.systemVersion })
     if  gamedata.sdk and gamedata.sdk.channel then
         cclog("AndroidSDK_common.reLogin:  uid=  %s   uuid= %s    ucid= %s", gamedata.sdk.channel.uid, gamedata.sdk.channel.uuid, gamedata.sdk.channel.ucid)
         if gamedata.sdk.channel.channelid ~="" and gamedata.sdk.channel.channelname~="" then
                UIRequest({ type = 90, nickname = gamedata.sdk.channel.uid, sessionId = gamedata.sdk.channel.uuid, uin = gamedata.sdk.channel.ucid, messageNum = self.messageNum, devicemodel = device.model, systemVersion = self.systemVersion, channelid = gamedata.sdk.channel.channelid ,channelname = gamedata.sdk.channel.channelname })
         else
                UIRequest({ type = 90, nickname = gamedata.sdk.channel.uid, sessionId = gamedata.sdk.channel.uuid, uin = gamedata.sdk.channel.ucid, messageNum = self.messageNum, devicemodel = device.model, systemVersion = self.systemVersion})
         end   
    end
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

--购买商品(商品id,价格，名字，描述)
function AndroidSDK_common.Recharge(self, orderId, payAmount, goodsName, goodsDesc)
    cclog("AndroidSDK_common.Recharge %d    %f    %s    %s ", orderId, payAmount, goodsName, goodsDesc)
    local luaj = require "luaj"
    --local javaClassName = "com/ldfs/sanguo2/CommonSDK_Utils"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "Pay"
    local javaParams = { string.format("%d", orderId), payAmount, goodsName, goodsDesc }
    local javaMethodSig = "(Ljava/lang/String;FLjava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end

--购买商品(商品id,价格，名字，描述)
function AndroidSDK_common.Recharge2(self, orderId, payAmount, goodsName, goodsDesc,goodsID)
    cclog("AndroidSDK_common.Recharge %d    %f    %s    %s ", orderId, payAmount, goodsName, goodsDesc,goodsID)
    local luaj = require "luaj"
    --local javaClassName = "com/ldfs/sanguo2/CommonSDK_Utils"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "Pay2"
    local javaParams = { string.format("%d", orderId), payAmount, goodsName, goodsDesc,goodsID }
    local javaMethodSig = "(Ljava/lang/String;FLjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end

--购买接口2
function AndroidSDK_common.RechargeMZ(self, orderId, createTime, sign, payAmount, goodsName, goodsDesc)
    cclog("AndroidSDK_common.RechargeMZ %d    %d    %s   %f    %s    %s ", orderId, createTime, sign, payAmount, goodsName, goodsDesc)
    local luaj = require "luaj"
    --local javaClassName = "com/ldfs/sanguo2/CommonSDK_Utils"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "Pay"
    local javaParams = { string.format("%d", orderId), createTime, sign, payAmount, goodsName, goodsDesc }
    local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;FLjava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end


--购买接口3
function AndroidSDK_common.RechargeVV(self, orderId, orderNum, acesskey, payAmount, goodsName, goodsDesc)
    cclog("AndroidSDK_common.RechargeMZ %d    %s    %s   %f    %s    %s ", orderId, orderNum, acesskey, payAmount, goodsName, goodsDesc)
    local luaj = require "luaj"
    --local javaClassName = "com/ldfs/sanguo2/CommonSDK_Utils"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "Pay"
    local javaParams = { string.format("%d", orderId), orderNum, acesskey, payAmount, goodsName, goodsDesc }
    local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;FLjava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end

--购买接口uc
function AndroidSDK_common.RechargeUC(self, orderId, payAmount, goodsName, goodsDesc, parma1, parma2, parma3, parma4, parma5, parma6)
    cclog("AndroidSDK_common.RechargeUC %d    %f    %s   %s    %s    %s     %s     %s     %s     %s", orderId, payAmount, goodsName, goodsDesc, parma1, parma2, parma3, parma4, parma5, parma6)
    local luaj = require "luaj"
    --local javaClassName = "com/ldfs/sanguo2/CommonSDK_Utils"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "PayUC"
    local javaParams = { string.format("%d", orderId), payAmount, goodsName, goodsDesc, parma1, parma2, parma3, parma4, parma5, parma6 }
    local javaMethodSig = "(Ljava/lang/String;FLjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end

--玩家的基本信息
function AndroidSDK_common.UserInformation(self, roleId, rolenName, roleLv, serverId, serverName)
    cclog("AndroidSDK_common.UserInformation %d    %s    %d    %d     %s", roleId, rolenName, roleLv, serverId, serverName)
    local luaj = require "luaj"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "UserInformation"
    local javaParams = { string.format("%d", roleId), rolenName, string.format("%d", roleLv), serverId, serverName }
    local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end

--19和极品游戏玩家的基本信息
function AndroidSDK_common.UserInformation19(self, roleId, rolenName, roleLv, serverId, serverName, vip, usergold )
    cclog("AndroidSDK_common.UserInformation19 %d    %s    %d    %d     %s   %d   %d", roleId, rolenName, roleLv, serverId, serverName, vip, usergold)
    local luaj = require "luaj"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "UserInformation19"
    local javaParams = { string.format("%d", roleId), rolenName, string.format("%d", roleLv),serverId, serverName, string.format("%d", vip), string.format("%d", usergold) }
    local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end

--玩家的基本信息2
function AndroidSDK_common.UserInformation2(self, roleId, platforName, roleLv, serverId, platformId, roleName,serverName,vip,gold,power)
    cclog("AndroidSDK_common.UserInformation2-------------")
    local luaj = require "luaj"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "UserInformation"
    local javaParams = { string.format("%d", roleId), platforName, string.format("%d", roleLv), string.format("%d", serverId), platformId, roleName ,serverName,vip,gold,power}
    printT(javaParams)
    local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig);
end

--玩家的基本信息3
function AndroidSDK_common.UserInformation3(self, roleId, roleName, roleLv, serverId, serverName, gold, vip)
    cclog("AndroidSDK_common.UserInformation3-------------")
    local luaj = require "luaj"
    local javaClassName = gameConfig.AD_packageName .. "/CommonSDK_Utils"
    local javaMethodName = "UserInformation"
    local javaParams = { string.format("%d", roleId), roleName, string.format("%d", roleLv), string.format("%d", serverId), serverName, string.format("%d", gold),string.format("%d", vip) }
    printT(javaParams)
    local javaMethodSig = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
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


function AndroidSDK_common.loginAccountSuc(self,uid)
    cclog("AndroidSDK_common.loginAccountSuc:  uid=  %s ", uid)
    local luaj = require"luaj"
    local javaClassName = gameConfig.AD_packageName.."/CommonSDK_Utils"
    local javaMethodName = "loginAccountSuc"
    local javaParams = { name }
    local javaMethodSig = "(Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName,javaMethodName,javaParams,javaMethodSig);
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

return AndroidSDK_common



