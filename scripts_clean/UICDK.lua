--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/3
-- Time: 15:54
-- To change this template use File | Settings | File Templates.
--

function UIUserCDKeyExchange(t)
    print("2089 CDK 接受客户端数据")

    printT(t.reward)

    if  t.reward == nil or next(t.reward) == nil then
        runGamePrompt({msg = "输入的兑换码无效"})
    else
        showRewardPopupWindow(t.reward,nil)
        UIRequest({type = 1001})
    end

    UIRequest({type = 1001})
end