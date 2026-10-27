--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/26
-- Time: 下午6:45
-- To change this template use File | Settings | File Templates.
--

function UIActivityEatChickenQuery(t)
    print("吃仙桃2010 接受客户端数据")
    --printT(t)

    if  GameScene.layers["activity"].module.pageTable[1] then
        GameScene.layers["activity"].module.pageTable[1].module:reloaddata(t)
    end


end

function UIEatChicken(t)
    print("吃仙桃2011 接受客户端数据")
    -- printT(t)

    if  GameScene.layers["activity"].module.pageTable[1] then
        GameScene.layers["activity"].module.pageTable[1].module:reloaddata(t)
    end
    if t.reward and next(t.reward) then
        for k,v in pairs(t.reward) do
            if v.cid == 1001 then
                runGamePrompt({msg = "获得元宝"..v.num})
            end
        end
    end
    local changeCoin,changeGold = updateDataLife(t.reward)
    if changeCoin then
        GameScene:coin_effect(1,540,960,0.5)
    end
    if changeGold then
        GameScene:coin_effect(2,540,960,0.5)
    end    
    UIRequest({type = 1001})
end