--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/5/29
-- Time: 17:22
-- To change this template use File | Settings | File Templates.
--

function UIOldDriverQuery(t)
    print("1404，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[41] and GameScene.layers["activity"].module.pageTable[41].module.show then
        GameScene.layers["activity"].module.pageTable[41].module:reloaddata(t.data)
    end

end

function UIOldDriverOpt(t)
    print("1405，接受客户端数据")
    printT(t)

    if t.pos and t.pos == 0 then
        local gets = {}
        for k,v in pairs(t.reward) do
            if gamedata.IDconfig(v.cid).staffType == "general" or gamedata.IDconfig(v.cid).staffType == "general_fragment" then
                gets["1"] = v
            end
        end
        gameWindows:openWindow("recruit",{type = "one", data = {gets = gets, opt = 2,}},nil)
        GameScene:addUpdate(1012)
        GameScene:addUpdate(10023)
        GameScene:addUpdate(10024)
        GameScene:addUpdate(10211)
    else
        showRewardPopupWindow(t.reward, nil,nil)
    end

    UIRequest({type = 1404,update = true})
    UIRequest({type = 1001})
end


--

function UICPOldDriverQuery(t)
    print("5032，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[86] and GameScene.layers["activity"].module.pageTable[86].module.show then
        GameScene.layers["activity"].module.pageTable[86].module:reloaddata(t)
    end

end

function UICPOldDriverOpt(t)
    print("5033，接受客户端数据")
    printT(t)

    if t.pos and t.pos == 0 then
        local gets = {}
        for k,v in pairs(t.reward) do
            if gamedata.IDconfig(v.cid).staffType == "general" or gamedata.IDconfig(v.cid).staffType == "general_fragment" then
                gets["1"] = v
            end
        end
        gameWindows:openWindow("recruit",{type = "one", data = {gets = gets, opt = 2,}},nil)
        GameScene:addUpdate(1012)
        GameScene:addUpdate(10023)
        GameScene:addUpdate(10024)
        GameScene:addUpdate(10211)
    else
        showRewardPopupWindow(t.reward, nil,nil)
    end

    UIRequest({type = 5032,update = true})
    UIRequest({type = 1001})
end