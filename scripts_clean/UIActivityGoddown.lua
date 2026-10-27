--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/7/4
-- Time: 15:08
-- To change this template use File | Settings | File Templates.
--

function UIGodDownQuery(t)
    print(" 4300 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[48] then
        GameScene.layers["activity"].module.pageTable[48].module:reloaddata(t.goddownstatus)
    end

end

function UIGodDownTribute(t)
    print(" 4301 接收客户端返回数据")
    printT(t)

    if t.id and t.id > 0 then
        gameWindows:openWindow("goddownReward",{id = t.id})
    end

    if t.reward and next(t.reward) then
        local changeCoin,changeGold = updateDataLife(t.reward)
        if changeCoin then
            GameScene:coin_effect(1,540,960,0.5)
        end
        if changeGold then
            GameScene:coin_effect(2,540,960,0.5)
        end
    end
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[48] then
        GameScene.layers["activity"].module.pageTable[48].module:reloaddata(t.goddownstatus)
    end

end

function UIGodDownTributeReward(t)
    print(" 4302 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[48] then
        GameScene.layers["activity"].module.pageTable[48].module:reloaddata(t.goddownstatus)
    end

end

function UIGodDownTributeImmediate(t)
    print(" 4303 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[48] then
        GameScene.layers["activity"].module.pageTable[48].module:reloaddata(t.goddownstatus)
    end

end

function UIGodDownGift(t)
    print(" 4304 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[48] then
        GameScene.layers["activity"].module.pageTable[48].module:reloaddata(t.goddownstatus)
    end

end


function UIGodDownShopQuery(t)
    print("天神下凡4310，接受客户端数据")

    printT(t)

    -- if  GameScene.layers["activity"].module.pageTable[48] then
    --     GameScene.layers["activity"].module.pageTable[48].module:reloaddata(t.shopdata)
    -- end

    if gameWindows.windows["goddownShop"].show then
        gameWindows.windows["goddownShop"].module:reloaddata(t.shopdata)
    else
        gameWindows:openWindow("goddownShop",t.shopdata)
    end
    

end

function UIGodDownShopReward(t)
    print("天神下凡4311，接受客户端数据")

    printT(t)

    -- if  GameScene.layers["activity"].module.pageTable[48] then
    --     GameScene.layers["activity"].module.pageTable[48].module:reloaddata(t.shopdata)
    -- end

    if gameWindows.windows["goddownShop"].show then
        gameWindows.windows["goddownShop"].module:reloaddata(t.shopdata)
    end

    if t.reward then
        showRewardPopupWindow(t.reward, nil, nil)
    end 
    UIRequest({type = 1001})
    UIRequest({type = 4300})

end

function UIGodDownRankQuery(t)
    print("天神下凡4320，接受客户端数据")

    printT(t)

    -- if  GameScene.layers["activity"].module.pageTable[49] then
    --     GameScene.layers["activity"].module.pageTable[49].module:reloadData(t.rankdata,t.mydata)
    -- end

    if gameWindows.windows["goddownRank"].show then
        gameWindows.windows["goddownRank"].module:reloadData(t.rankdata,t.mydata)
    else
        gameWindows:openWindow("goddownRank",t)
    end
end



--
--K
function UIKGodDownQuery(t)
    print(" 4870 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[71] then
        GameScene.layers["activity"].module.pageTable[71].module:reloaddata(t.goddownstatus)
    end

end

function UIKGodDownTribute(t)
    print(" 4871 接收客户端返回数据")
    printT(t)

    if t.id and t.id > 0 then
        gameWindows:openWindow("k_goddownReward",{id = t.id})
    end

    if t.reward and next(t.reward) then
        local changeCoin,changeGold = updateDataLife(t.reward)
        if changeCoin then
            GameScene:coin_effect(1,540,960,0.5)
        end
        if changeGold then
            GameScene:coin_effect(2,540,960,0.5)
        end
    end
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[71] then
        GameScene.layers["activity"].module.pageTable[71].module:reloaddata(t.goddownstatus)
    end

end

function UIKGodDownTributeReward(t)
    print(" 4872 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[71] then
        GameScene.layers["activity"].module.pageTable[71].module:reloaddata(t.goddownstatus)
    end

end

function UIKGodDownTributeImmediate(t)
    print(" 4873 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[71] then
        GameScene.layers["activity"].module.pageTable[71].module:reloaddata(t.goddownstatus)
    end

end

function UIKGodDownGift(t)
    print(" 4874 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[71] then
        GameScene.layers["activity"].module.pageTable[71].module:reloaddata(t.goddownstatus)
    end

end


function UIKGodDownShopQuery(t)
    print("4875，接受客户端数据")

    printT(t)

    -- if  GameScene.layers["activity"].module.pageTable[71] then
    --     GameScene.layers["activity"].module.pageTable[71].module:reloaddata(t.shopdata)
    -- end


    if gameWindows.windows["kgoddownShop"].show then
        gameWindows.windows["kgoddownShop"].module:reloaddata(t.shopdata)
    else
        gameWindows:openWindow("kgoddownShop",t.shopdata)
    end

end

function UIKGodDownShopReward(t)
    print("4876，接受客户端数据")

    printT(t)

    -- if  GameScene.layers["activity"].module.pageTable[71] then
    --     GameScene.layers["activity"].module.pageTable[71].module:reloaddata(t.shopdata)
    -- end

    if gameWindows.windows["kgoddownShop"].show then
        gameWindows.windows["kgoddownShop"].module:reloaddata(t.shopdata)
    end
    
    if t.reward then
        showRewardPopupWindow(t.reward, nil, nil)
    end
    UIRequest({type = 1001})
    UIRequest({type = 4870})

end

function UIKGodDownRankQuery(t)
    print("4877，接受客户端数据")

    printT(t)

    -- if  GameScene.layers["activity"].module.pageTable[72] then
    --     GameScene.layers["activity"].module.pageTable[72].module:reloadData(t.rankdata,t.mydata)
    -- end

    if gameWindows.windows["kgoddownRank"].show then
        gameWindows.windows["kgoddownRank"].module:reloadData(t.rankdata,t.mydata)
    else
        gameWindows:openWindow("kgoddownRank",t)
    end

end


--cp todo
function UICPGodDownQuery(t)
    print(" 5010 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[82] then
        GameScene.layers["activity"].module.pageTable[82].module:reloaddata(t)
    end

end

function UICPGodDownTribute(t)
    print(" 5011 接收客户端返回数据")
    printT(t)

    if t.id and t.id > 0 then
        gameWindows:openWindow("goddownReward",{id = t.id})
    end

    if t.reward and next(t.reward) then
        local changeCoin,changeGold = updateDataLife(t.reward)
        if changeCoin then
            GameScene:coin_effect(1,540,960,0.5)
        end
        if changeGold then
            GameScene:coin_effect(2,540,960,0.5)
        end
    end
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[82] then
        GameScene.layers["activity"].module.pageTable[82].module:reloaddata(t)
    end

end

function UICPGodDownTributeReward(t)
    print(" 5012 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[82] then
        GameScene.layers["activity"].module.pageTable[82].module:reloaddata(t)
    end

end

function UICPGodDownTributeImmediate(t)
    print(" 5013 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[82] then
        GameScene.layers["activity"].module.pageTable[82].module:reloaddata(t)
    end

end

function UICPGodDownGift(t)
    print(" 5014 接收客户端返回数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil)
    UIRequest({type = 1001})

    if GameScene.layers["activity"].module.pageTable[82] then
        GameScene.layers["activity"].module.pageTable[82].module:reloaddata(t)
    end

end

--
function UICPGodDownShopQuery(t)
    print("5015，接受客户端数据")

    printT(t)
    -- if  GameScene.layers["activity"].module.pageTable[82] then
    --     GameScene.layers["activity"].module.pageTable[82].module:reloaddata(t)
    -- end

    if gameWindows.windows["cp_goddownShop"].show then
        gameWindows.windows["cp_goddownShop"].module:reloaddata(t)
    else
        gameWindows:openWindow("cp_goddownShop",t)
    end

   
end

function UICPGodDownShopReward(t)
    print("5016，接受客户端数据")

    printT(t)

    -- if  GameScene.layers["activity"].module.pageTable[82] then
    --     GameScene.layers["activity"].module.pageTable[82].module:reloaddata(t)
    -- end

    if gameWindows.windows["cp_goddownShop"].show then
        gameWindows.windows["cp_goddownShop"].module:reloaddata(t)
    end

    if t.reward then
        showRewardPopupWindow(t.reward, nil, nil)
    end
    UIRequest({type = 1001})
    UIRequest({type = 5010})
    
end

function UICPGodDownRankQuery(t)
    print("5017，接受客户端数据")

    printT(t)

    -- if  GameScene.layers["activity"].module.pageTable[83] then
    --     GameScene.layers["activity"].module.pageTable[83].module:reloadData(t)
    -- end
    if gameWindows.windows["cp_goddownRank"].show then
        gameWindows.windows["cp_goddownRank"].module:reloadData(t)
    else
        gameWindows:openWindow("cp_goddownRank",t)
    end
end


