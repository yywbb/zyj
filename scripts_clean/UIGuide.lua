--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/31
-- Time: 下午6:05
-- To change this template use File | Settings | File Templates.
--


function UIRoleSetProfile(t)
    print("设置形象102，接受客户端数据")
    if gameWindows.windows["roleinfo"].show then
        gameWindows.windows["roleinfo"].module:resetIcon(t.profile)
    end
end

function UIRandomName(t)
    print("随机起名100，接受客户端数据")
    guide.first:setFirstName(t.name)
end

function UISetName(t)
    print("起名101，接受客户端数据")
    --printT(t)
    if t.result == 1  then
        if t.isrename then
            UIRequest({type = 1001})
            runGamePrompt({msg = "改名成功！！"})
            gameWindows:closeWindow("useropt")
            UIRequest({type = 1200})
        else
            print("general init inedx  id ",guide.first.select,guide.first.selectconfig[guide.first.select].realid)

            UIRequest({type = 202, cid = guide.first.selectconfig[guide.first.select].realid, isfirst = true})
        end
    else
        runGamePrompt({msg = "名字已被占用，请重新输入"})
    end

end

function UIGuideQuery(t)
    print("引导查询200，接受客户端数据")
    printT(t)

    if t.param and t.param == "first" then
        if t.guide["1"] and (t.guide["1"].status == 2 or t.guide["1"].step >= 4) then
            LoginScene:initrequest("datainit")
        else
            LoginScene:enterToGame()
        end
    else
        if not guide.controller then
            guide.controller = require"guideControl"
        else
            guide.controller:reset()
        end
        guide.controller:Init(t.guide)
    end

end

function UIGuideExcute(t)
    print("引导201，接受客户端数据")

end

function UIInitGeneral(t)
    print("选择初始武将202，接受客户端数据")

    if t.isfirst then
        local sdk = require"SDKfunction"
        if sdk:isValid() then
            sdk:CreateRole(guide.first.name)
        end
        LoginScene:initrequest("afterselect")
    else

    end
end
