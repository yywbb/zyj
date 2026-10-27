--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/6
-- Time: 下午2:34
-- To change this template use File | Settings | File Templates.
--


function UIWuDaoHuiQuery(t)
    print("武道会4100，接受客户端数据")
    -- printT(t)

    if t.update then
        if GameScene.layers["wudaohui"].show then
            GameScene.layers["wudaohui"].module:ranklistUpdateSet(t.wudaohui)
        end
    else
        if GameScene.layers["wudaohui"].show then
            GameScene.layers["wudaohui"].module:reloaddata(t.wudaohui,t.part_point)
        end
    end 
end

function UIWuDaoHuiPiPei(t)
    print("武道会4101，接受客户端数据")
    -- printT(t)
    -- gameWindows:openWindow("wudaohuipipei",{index = "pipei",},nil)

    -- if gameWindows.windows["wudaohuipipei"].show then
    --     gameWindows.windows["wudaohuipipei"].module:reload(t.result)
    -- end

end

function UIWuDaoHuiPiPeiSuceccs(t)
    print("武道会4102，接受客户端数据")
    printT(t)

    gameWindows:closeWindowDirect("wudaohuipipei")

    gameWindows:openWindow("wudaohuipipei",{index = "pipei",data = t},nil)

    -- if gameWindows.windows["wudaohuipipei"].show then
    --     gameWindows.windows["wudaohuipipei"].module:setSuccessData(t)
    -- end
end

function UIWuDaoHuiBoxReward(t)
    print("武道会4103，接受客户端数据")
    -- printT(t)

    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,nil)
    end

    if GameScene.layers["wudaohui"].show then
        GameScene.layers["wudaohui"].module:setFirstStatus()
    end
    UIRequest({type = 4100})
    UIRequest({type = 1001})
end

function UIWuDaoHuiLotteryQuery(t)
    print("武道会4105，接受客户端数据")
    -- printT(t)

    if GameScene.layers["activity"].module.pageTable[42] then
        GameScene.layers["activity"].module.pageTable[42].module:reloaddata(t.shop)
    end

end

function UIWuDaoHuiLotteryReward(t)
    print("武道会4106，接受客户端数据")
    -- printT(t)

    if GameScene.layers["activity"].module.pageTable[42] then
        GameScene.layers["activity"].module.pageTable[42].module:actionShowSet(t)
    end

end

function UIWuDaoHuiReport(t)
    print("武道会4104，接受客户端数据")
    printT(t)

    if GameScene.layers["wudaohui"].show then
        GameScene.layers["wudaohui"].module:setReportData(t)
    end
    
end

function UIWuDaoHuiDuanWeiQuery(t)
    print("武道会4107，接受客户端数据")
    printT(t)
    if gameWindows.windows["wudaohuiduanwei"].show then
        gameWindows.windows["wudaohuiduanwei"].module:reloaddata(t.duanweidata)
    end
    
end

function UIWuDaoHuiDuanWeiReward(t)
    print("武道会4108，接受客户端数据")
    printT(t)
    if gameWindows.windows["wudaohuiduanwei"].show then
        gameWindows.windows["wudaohuiduanwei"].module:reloaddata(t.duanweidata,true)
    end
    if next(t.reward) then
        showRewardPopupWindow(t.reward,nil,nil)
    end

    UIRequest({type = 1001})
end


