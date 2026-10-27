--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-10-11
-- Time: 下午6:05
-- To change this template use File | Settings | File Templates.
--

function UISelectList(t)
    print("选择列表10029， 接受客户端数据")
    -- printT(t)
    if gameWindows.windows["selectlist"].show then
        gameWindows.windows["selectlist"].module:reloadSelectList(t)
    end

    if gameWindows.windows["mofuselect"].show then
        gameWindows.windows["mofuselect"].module:reload(t)
    end

    if gameWindows.windows["mofulevelup"].show then
        gameWindows.windows["mofulevelup"].module:selectdataReload(t)
    end

    if gameWindows.windows["mofuproperty"].show then
        gameWindows.windows["mofuproperty"].module:getSameMofuNum(t.data)
    end
    
    	

end