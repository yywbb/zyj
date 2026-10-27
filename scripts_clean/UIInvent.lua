--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/23
-- Time: 上午11:48
-- To change this template use File | Settings | File Templates.
--

function UIInviteCode(t)
    print("邀请2080,接受客户端数据")
    printT(t)
    if t.invent then
        if GameScene.layers["activity"].module.pageTable[9] then
            GameScene.layers["activity"].module.pageTable[9].module:reloaddata(t.invent)
        end
    else
    end
end

function UIInviteCodeSet(t)
    print("邀请2081,接受客户端数据")
    printT(t)
    if t.result == 0 then
        runGamePrompt({msg = "操作失败，请重新输入"})
    else
        UIRequest({type = 2080, update = true})
    end
    --UIRequest({type = 2080})
end

function UIInviteCodeReward(t)
    print("邀请2082,接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[9] then
        GameScene.layers["activity"].module.pageTable[9].module:reloaddata(t.invent)
    end
    showRewardPopupWindow(t.reward)
    UIRequest({type = 1001})
end

