--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/4
-- Time: 10:32
-- To change this template use File | Settings | File Templates.
--

function UIUserSystemMail(t)
    print("1030 SystemMail 接受客户端数据")

    --printT(t)

    if t.result and t.result == 1 then
       runGamePrompt({msg = "发送成功"})
    else
       runGamePrompt({msg = "发送失败"})
    end

end