--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/1/13
-- Time: 10:30
-- To change this template use File | Settings | File Templates.
--

function UIAuctionHouseQuery(t)
    print("4810，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[65] then
        GameScene.layers["activity"].module.pageTable[65].module:ReloadData(t.auction)
    end

end

function UIAuctionHouseAuction(t)
    print("4811，接受客户端数据")
    printT(t)

    if t.result and t.result == 1 then
        runGamePrompt({msg = gameConfig.strings:string_common("auction",4)})
    end
    UIRequest({type = 1001})
    UIRequest({type = 4810})

end

function UIAuctionHouseGet(t)
    print("4812，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})
    UIRequest({type = 4810})

end

function UIAuctionHouseLog(t)
    print("4813，接受客户端数据")
    printT(t)

    if gameWindows.windows["auctionLog"].show then
        gameWindows.windows["auctionLog"].module:reload(t)
    end
end

function UIAuctionHouseOpts(t)
    print("4814，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[65] then
        GameScene.layers["activity"].module.pageTable[65].module:ReloadMessage(t)
    end

end

function UIAuctionHouseChange(t)
    print("4815，接受客户端数据")

    UIRequest({type = 4810})

end