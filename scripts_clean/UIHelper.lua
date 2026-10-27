--
-- Author: songyibo
-- Date: 2020-01-13 18:01:33
--

function UIGameHelperQuery(t)
    printT(t,"6211 游戏助手查询")
    if GameScene.layers["gameHelper"].show then
        GameScene.layers["gameHelper"].module:initData(t.data)
    end
end


function UIGameHelperExe(t)
    printT(t,"6212 游戏助手执行")
    UIRequest({type = 1001})
    


    if t.data.rewards and next(t.data.rewards) then
        for k,v in pairs(t.data.rewards) do
            if v.type == 2 and v.id == 7 then
                UIRequest({type = 1350})
            end
        end
    	gameWindows:openWindow("gameHelperLog",{data = t.data,method = "exc"},function ( )
            UIRequest({type = 6211})

            --是否金币元宝改变
            local changeCoin,changeGold = false,false

            for k,v in pairs(t.data.rewards) do
                if v.reward and next(v.reward) then
                    local c,g = updateDataLife(v.reward)
                    if c then
                        changeCoin = true
                    end

                    if g then
                        changeGold = true
                    end
                end

                if v.used and next(v.used) then
                    local c,g = updateDataLife(v.used)
                    if c then
                        changeCoin = true
                    end

                    if g then
                        changeGold = true
                    end
                end

                if v.type == 3 and v.id == 7 then
                    UIRequest({type = 2300,param = "update"})
                end


                if changeCoin then
                    GameScene:coin_effect(1,540,960,0.5)
                end

                if changeGold then
                    GameScene:coin_effect(2,540,960,0.5)
                end
            end

        end)

    else
    	runGamePrompt({msg = gameConfig.strings:string_common("gameHelper",27)})
    end

    if GameScene.layers["gameHelper"].show then
        GameScene.layers["gameHelper"].module:exeCallback()
    end

end
