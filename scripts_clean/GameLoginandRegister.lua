--
-- Created by IntelliJ IDEA.
-- User: WangTao
-- Date: 13-5-30
-- Time: 上午10:23
-- To change this template use File | Settings | File Templates.
--
--- 点击注册按钮:邮箱密码和手机号
local useraccount_pbb = require("useraccount_pb")
function UINetUserRegisterAndCallback(uireq)
	local loginorregister = useraccount_pbb.UserAccount()
	loginorregister.account = uireq.account
	loginorregister.password = uireq.password
	if uireq.phone ~= nil then
		loginorregister.phone = uireq.phone
	end
	local loginorregister2bit = loginorregister:SerializeToString()
	return 1, 10, loginorregister2bit
end

local userresult_pb_10 = require("userresult_pb")
function NetUserRegisterAndCallback(fd)
	local userresult = userresult_pb_10.UserResult()
	userresult:ParseFromString(fd.rbuf)
	--- 根据result判断显示的类型
	print("10result=", userresult.result)
	--- 根据result判断显示的类型
	local t = { type = 10, uid=userresult.id, result = userresult.result, rls = {} }
	if userresult.result == true then
		if next(userresult.rls) ~= nil then
			print("10显示所有服务器的编号:")
			for k, v in ipairs(userresult.rls) do
				print("10编号:", k, "=", v.id)
				table.insert(t.rls, v.id)
			end
		end
		return t
	else
		print("10error info:", userresult.error)
		return t
	end
end

------------------------------------------------------------------------------------------------------------------------
--- 点击登陆按钮:邮箱和密码
local useraccount_pb = require("useraccount_pb")
function UINetUserLoginAndCallback(uireq)
	local loginorregister = useraccount_pb.UserAccount()
	loginorregister.account = uireq.account
	loginorregister.password = uireq.password
	print("loginorregister.account = ", loginorregister.account)
	local loginorregister2bit = loginorregister:SerializeToString()
	return 1, 11, loginorregister2bit
end

local userresult_pb_11 = require("userresult_pb")
function NetUserLoginAndCallback(fd)
	local userresult = userresult_pb_11.UserResult()
	userresult:ParseFromString(fd.rbuf)
	--解析返回的结果
	print("账号登陆 result=", userresult.result, "error=", userresult.error, "rls=", userresult.rls)
	--根据result判断显示的类型
	local t = { type = 11, result = userresult.result, uid = userresult.id, rls = {}, error=userresult.error}
	if userresult.result == true then
		if next(userresult.rls) ~= nil then
			print("10显示所有服务器的编号:")
			for k, v in ipairs(userresult.rls) do
				print("10编号:", k, "=", v.id)
				table.insert(t.rls, v.id)
			end
		end
		return t
	else
		print("11error info:", userresult.error)
		return t
	end
end


--table.foreach(userresult.rls,
--    function(i, v)
--        print ("10测试:",i, v)
--    end)