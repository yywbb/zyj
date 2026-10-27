--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/12
-- Time: 下午2:46
-- To change this template use File | Settings | File Templates.
--


function UIZhuxiantaiQuery(t)
    print("诛仙台3600，接受客户端数据")
    --printT(t)

    if not t.param or t.param == "update" then
        if GameScene.layers["bloodbattle"].show then
            GameScene.layers["bloodbattle"].module:reloadData(t.data)
        end
    elseif t.param == "shop" then
        if GameScene.layers["zhuxiantaiShop"].show then
            GameScene.layers["zhuxiantaiShop"].module:reloadData(t.data,t.status)
        end
    end
end

function UIZhuxiantaiBattle(t)
    print("诛仙台3601，接受客户端数据")
    --printT(t)

    local cb = function()
        if next(t.reward3)  then
            showRewardPopupWindow(t.reward3,nil,function()
                UIRequest({type = 3600,param = "update"})
            end)
        else
            UIRequest({type = 3600,param = "update"})
        end
    end

    RunbattleCallBack("blood", t, function()
        if t.result == 1 then
            if GameScene.layers["bloodbattle"].show then
                GameScene.layers["bloodbattle"].module:passOne(t,cb,true)
            end
        else
            cb()
        end
    end)
    UIRequest({type = 1001})
    GameScene:addUpdate(10021)
end

function UIZhuxiantaiWipe(t)
    print("诛仙台3602，接受客户端数据")
    --printT(t)


    local location = math.mod(t.floor,3)
    if location ==0 then location = 3 end

    local cb4 = function()
        if t.reward["0"] then
            showRewardPopupWindow(t.reward["0"],nil,function()
                UIRequest({type = 3600,param = "update"})
            end)
        else
            UIRequest({type = 3600,param = "update"})
        end
        GameScene.layers["bloodbattle"].module:coineffect(t)
    end

    local cb3 = function()
        if t.reward["3"] then
            GameScene.layers["bloodbattle"].module:passOne({floor = t.floor-location+3,reward = t.reward["3"]},cb4,false)
        else
            cb4()
        end
    end

    local cb2 = function()
        if t.reward["2"] then
            GameScene.layers["bloodbattle"].module:passOne({floor = t.floor-location+2,reward = t.reward["2"]},cb3,false)
        else
            cb3()
        end
    end

    local cb1 = function()
        if t.reward["1"] then
            GameScene.layers["bloodbattle"].module:passOne({floor = t.floor-location+1,reward = t.reward["1"]},cb2,false)
        else
            cb2()
        end
    end

    cb1()
    UIRequest({type = 1001})
    GameScene:addUpdate(10021)
end

function UIZhuxiantaiAttrQuery(t)
    print("诛仙台3603，接受客户端数据")
    --printT(t)
    gameWindows:openWindow("zhuxiantai",{type = "jiacheng", data =t},nil)
end

function UIZhuxiantaiAttrSelect(t)
    print("诛仙台3604，接受客户端数据")
    --printT(t)
    GameScene.layers["bloodbattle"].module.guai = {}
    if GameScene.layers["bloodbattle"].show then
        GameScene.layers["bloodbattle"].module:reloadData(t.data)
    end
end

function UIZhuxiantaiRank(t)
    print("诛仙台3605，接受客户端数据")
    --printT(t)

    gameWindows:openWindow("zhuxiantai",{type = "rank", players =t.players,star = t.star},nil)

end

function UIZhuxiantaiExchangeQuery(t)
    print("诛仙台36061，接受客户端数据")
    --printT(t)

    if GameScene.layers["zhuxiantaiShop"].show then
        GameScene.layers["zhuxiantaiShop"].module:reloadData(t.data,t.status)
    end
end

function UIZhuxiantaiExchange(t)
    print("诛仙台3606，接受客户端数据")
    --printT(t)
    if GameScene.layers["zhuxiantaiShop"].show then
        GameScene.layers["zhuxiantaiShop"].module:reloadData(t.data,t.status)
    end
    showRewardPopupWindow(t.Reward,nil,nil)
    UIRequest({type = 1001})
end

function UIZhuxiantaiReset(t)
    print("诛仙台3607，接受客户端数据")
    --printT(t)

    GameScene.layers["bloodbattle"].module.guai = {}
    if GameScene.layers["bloodbattle"].show then
        GameScene.layers["bloodbattle"].module:reloadData(t.data)
    end
end


---------------------------------------------------------------------
function UIMieshendianQuery(t)
    print("灭神殿3620，接受客户端数据")
    printT(t)
    if t.data["cdtime"] and t.data["cdtime"] > 0 then
        gameTimer:rigistTime("MieshendianCD",t.data["cdtime"]+2)
    elseif t.data["cdtime"] then
        gameTimer:rigistTime("MieshendianCD",t.data["cdtime"])
    end

    if GameScene.layers["bloodbattle"].show then
       GameScene.layers["bloodbattle"].module:reloadData(t.data)
    end

end

function UIMieshendianBattle1(t)
    print("灭神殿3621，接受客户端数据")
    printT(t)

    RunbattleCallBack("blood", t, function()
        UIRequest({type = 3620})
    end)
    UIRequest({type = 1001})
end

function UIMieshendianBossQuery(t)
    print("灭神殿36201，接受客户端数据")
    printT(t)

    gameWindows:openWindow("zhuxiantaiboss",t,nil)

end

function UIMieshendianBattle2(t)
    print("灭神殿3622，接受客户端数据")
    printT(t)

    RunbattleCallBack("blood", t, function()
        UIRequest({type = 3620})
    end)
    UIRequest({type = 1001})
end

function UIMieshendianReset(t)
    print("灭神殿3626，接受客户端数据")
    printT(t)
    if t.data["cdtime"] and t.data["cdtime"] > 0 then
        gameTimer:rigistTime("MieshendianCD",t.data["cdtime"]+2)
    elseif t.data["cdtime"] then
        gameTimer:rigistTime("MieshendianCD",t.data["cdtime"])
    end

    if GameScene.layers["bloodbattle"].show then
        GameScene.layers["bloodbattle"].module:reloadData(t.data,t.gold)
    end
    UIRequest({type = 1001})
end

function UIMieshendianModup(t)
    print("灭神殿3623，接受客户端数据")
    printT(t)
    if t.data["cdtime"] and t.data["cdtime"] > 0 then
        gameTimer:rigistTime("MieshendianCD",t.data["cdtime"]+2)
    elseif t.data["cdtime"] then
        gameTimer:rigistTime("MieshendianCD",t.data["cdtime"])
    end

    if GameScene.layers["bloodbattle"].show then
        GameScene.layers["bloodbattle"].module:reloadData(t.data)
    end

end

function UIMieshendianModupCDClear(t)
    print("灭神殿3624，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.Reward,nil,nil)

    UIRequest({type = 1001})
    UIRequest({type = 3620})
end

function UIMieshendianRank(t)
    print("灭神殿3625，接受客户端数据")
    printT(t)

    gameWindows:openWindow("zhuxiantairank",t,nil)
end

--

function UIMieshendianShop(t)
    print("灭神殿3627，接受客户端数据")
    printT(t)

    -- if GameScene.layers["destroyTempleShop"].show then
    --     GameScene.layers["destroyTempleShop"].module:ReloadData(t.data)
    -- end
    
    if  GameScene.layers["activity"].module.pageTable[28] then
        print("gangshop==")
        GameScene.layers["activity"].module.pageTable[28].module:ReloadData(t.data)
    end
end


function UIMieshendianShopBuy(t)
    print("灭神殿3628，接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,nil)

    UIRequest({type = 1001})
    UIRequest({type = 3620})
    UIRequest({type = 3627})
end