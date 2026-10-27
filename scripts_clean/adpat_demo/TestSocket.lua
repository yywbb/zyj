--
-- Author: songyibo
-- Date: 2018-07-12 17:02:30
--

local TestSocket = class("TestSocket", cc.load("mvc").ViewBase)

local socket = require("socket")

function TestSocket:onCreate()
    cc.Label:createWithSystemFont("Hello World", "Arial", 40)
        :move(display.cx, display.cy + 200)
        :addTo(self)

       dump(socket)
end

function TestSocket:smtp(self)
	-- smtp方法发送mail
	local smtp = require("socket.smtp")

	from = "<youmail@126.com>" -- 发件人

	-- 发送列表
	rcpt = {
	    "<youmail@126.com>",
	    "<youmail@qq.com>"
	}

	mesgt = {
	    headers = {
	        to = "youmail@gmail.com", -- 收件人
	        cc = '<youmail@gmail.com>', -- 抄送
	        subject = "This is Mail Title"
	    },
	    body = "This is  Mail Content."
	}

	r, e = smtp.send{
	    server="smtp.126.com",
	    user="youmail@126.com",
	    password="******",
	    from = from,
	    rcpt = rcpt,
	    source = smtp.message(mesgt)
	}

	if not r then
	   print(e)
	else
	   print("send ok!")
	end
end

return TestSocket