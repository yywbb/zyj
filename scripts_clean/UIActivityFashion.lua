--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/6/17
-- Time: 16:04
-- To change this template use File | Settings | File Templates.
--

function UIFashionDressActQuery(t)
    print(" 1075 接收客户端返回数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[43] then
        GameScene.layers["activity"].module.pageTable[43].module:reloaddata(t)
    end

end

function UIFashionDressGet(t)
    print(" 1074 接收客户端返回数据")
    printT(t)

    local id = 0
    if t.reward then
        for k,v in pairs(t.reward) do
            if v.cid >= 80001 and v.cid <= 81000 then
                id = v.cid
            end
        end
    end

    if id > 0 then
        gameWindows:openWindow("fashionGet",{id = id})
        UIRequest({type = 1054, param = "update"})
    end

    UIRequest({type = 1001})
    UIRequest({type = 1070})
    UIRequest({type = 1075})
    UIRequest({type = 1076})

end

function UIFashionDressShopQuery(t)
    print(" 1076 接收客户端返回数据")
    printT(t)

    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:ReloadFashionData(t)
    end

end