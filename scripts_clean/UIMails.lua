--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/24
-- Time: 下午4:46
-- To change this template use File | Settings | File Templates.
--

function UIMailList(t)
    print("邮件3100 接受客户端数据")
    --printT(t)

    if GameScene.layers["mail"].show then
        GameScene.layers["mail"].module:reloaddata(t)
    end

end

function UIMailRead(t)
    print("邮件3101 接受客户端数据")
    --printT(t)

    if GameScene.layers["mail"].show then
        GameScene.layers["mail"].module:reloaddata(t)
    end

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
end

function UIMailDelete(t)
    print("邮件3102 接受客户端数据")
    --printT(t)
    if GameScene.layers["mail"].show then
        GameScene.layers["mail"].module:reloaddata(t)
    end

end

function UIMailSend(t)
    print("邮件3100 接受客户端数据")
    --printT()
    if t.result == 1 then
        runGamePrompt({msg = "留言成功"})
    end


end

function H5CallBack(t)
     print("邮件100011 接受客户端数据")
      UIRequest({type = 3100,update = true})
end