--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-18
-- Time: 下午3:47
-- To change this template use File | Settings | File Templates.
--

function UIGetStaffNum(t)
    print("12002 接受客户端数据")

    printT(t)

    if gameWindows.windows["dropTips"].show then
        gameWindows.windows["dropTips"].module:setOwnNum(t)
    end

    if gameWindows.windows["infoAndAccess"].show then
        gameWindows.windows["infoAndAccess"].module:setPropNum(t)
    end
end
