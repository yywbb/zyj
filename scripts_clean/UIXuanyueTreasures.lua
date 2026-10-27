--
-- Author: songyibo
-- Date: 2019-08-20 14:36:57
--

function UIXuanyueQuery(t)
	printT(t,"7060 玄月秘宝查询")

	if t.param and t.param == "main" then
		if t.data.day and t.data.day.isopen == 1 then
            gameWindows:openWindow("xuanyueTreasureTip",t,function()
                GameScene:runMainTip()
            end)
        else
            GameScene:runMainTip()        
        end
	end

	if GameScene.layers["xuanyueTreasures"].show then
        GameScene.layers["xuanyueTreasures"].module:reload(t.data)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setXuanyueTreasures(t.data)
    end

    if GameScene.layers["task"].show then
        GameScene.layers["task"].module:setXuanyueTreasures(t.data)
    end
end

function UIXuanyueAward(t)
	printT(t,"7061 玄月秘宝领奖")

	if t.reward then
        showRewardPopupWindow(t.reward,nil,function ()
            if t.awardId then
                if gamedata.config:getConfigByName("xuanyue_reward")[tostring(t.awardId)].to_buy == 1 and t.xuanyueData.data.isHight ~= 1 then

                    GameScene.layers["xuanyueTreasures"].module:setData(t.xuanyueData)
                    GameScene.layers["xuanyueTreasures"].module:openTreasuresBuy()

                end
            end
        end)
    end

    if t.awardId then
        if GameScene.layers["xuanyueTreasures"].show then
            GameScene.layers["xuanyueTreasures"].module:awardCallback(t)
        end
    else
        UIRequest({type=7060})
    end
    UIRequest({type = 1001})
    -- if GameScene.layers["xuanyueTreasures"].show then
    --     GameScene.layers["xuanyueTreasures"].module:awardCallback(t)
    -- end
end

function UIXuanyueActivate(t)
	printT(t,"7062 玄月秘宝激活")
    local config = gamedata.config:getConfigByName("xuanyue_reward")[tostring(t.id)]
    if config.to_push == 1 then
        GameScene.layers["xuanyueTreasures"].module.activeAction = t.id
    else
        runGamePrompt({msg = gameConfig.strings:string_common("xuanyueTreasures",13)})
    end
    UIRequest({type=7060})
end



-------------------------玄月秘宝复制----------------------------

function UIXuanyueQuery2(t)
    printT(t,"7063 玄月秘宝查询")

    if t.param and t.param == "main" then
        if t.data.day and t.data.day.isopen == 1 then
            gameWindows:openWindow("xuanyueTreasureTip2",t,function()
                GameScene:runMainTip()
            end)
        else
            GameScene:runMainTip()        
        end
    end

    if GameScene.layers["xuanyueTreasures2"].show then
        GameScene.layers["xuanyueTreasures2"].module:reload(t.data)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setXuanyueTreasures2(t.data)
    end

    if GameScene.layers["task"].show then
        GameScene.layers["task"].module:setXuanyueTreasures2(t.data)
    end
end

function UIXuanyueAward2(t)
    printT(t,"7064 玄月秘宝领奖")

    if t.reward then
        showRewardPopupWindow(t.reward,nil,function ()
            if t.awardId then
                if gamedata.config:getConfigByName("xuanyue2_reward")[tostring(t.awardId)].to_buy == 1 and t.xuanyueData.data.isHight ~= 1 then

                    GameScene.layers["xuanyueTreasures2"].module:setData(t.xuanyueData)
                    GameScene.layers["xuanyueTreasures2"].module:openTreasuresBuy()

                end
            end
        end)
    end

    if t.awardId then
        if GameScene.layers["xuanyueTreasures2"].show then
            GameScene.layers["xuanyueTreasures2"].module:awardCallback(t)
        end
    else
        UIRequest({type=7063})
    end
    UIRequest({type = 1001})
    -- if GameScene.layers["xuanyueTreasures"].show then
    --     GameScene.layers["xuanyueTreasures"].module:awardCallback(t)
    -- end
end

function UIXuanyueActivate2(t)
    printT(t,"7067 玄月秘宝激活")
    local config = gamedata.config:getConfigByName("xuanyue2_reward")[tostring(t.id)]
    if config.to_push == 1 then
        GameScene.layers["xuanyueTreasures2"].module.activeAction = t.id
    else
        runGamePrompt({msg = gameConfig.strings:string_common("xuanyueTreasures",13)})
    end
    UIRequest({type=7063})
end

-------------------------玄月秘宝3----------------------------
function UIXuanyueQuery3(t)
    printT(t,"7072 玄月秘宝查询")

    if t.param and t.param == "main" then
        if t.data.day and t.data.day.isopen == 1 then
            gameWindows:openWindow("xuanyueTreasureTip3",t,function()
                GameScene:runMainTip()
            end)
        else
            GameScene:runMainTip()        
        end
    end

    if GameScene.layers["xuanyueTreasures3"].show then
        GameScene.layers["xuanyueTreasures3"].module:reload(t.data)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:setXuanyueTreasures3(t.data)
    end

    if GameScene.layers["task"].show then
        GameScene.layers["task"].module:setXuanyueTreasures3(t.data)
    end
end

function UIXuanyueAward3(t)
    printT(t,"7073 玄月秘宝领奖")

    if t.reward then
        showRewardPopupWindow(t.reward,nil,function ()
            if t.awardId then
                if gamedata.config:getConfigByName("xuanyue3_reward")[tostring(t.awardId)].to_buy == 1 and t.xuanyueData.data.isHight ~= 1 then

                    GameScene.layers["xuanyueTreasures3"].module:setData(t.xuanyueData)
                    GameScene.layers["xuanyueTreasures3"].module:openTreasuresBuy()

                end
            end
        end)
    end

    if t.awardId then
        if GameScene.layers["xuanyueTreasures3"].show then
            GameScene.layers["xuanyueTreasures3"].module:awardCallback(t)
        end
    else
        UIRequest({type=7072})
    end
    UIRequest({type = 1001})
    -- if GameScene.layers["xuanyueTreasures"].show then
    --     GameScene.layers["xuanyueTreasures"].module:awardCallback(t)
    -- end
end

function UIXuanyueActivate3(t)
    printT(t,"7074 玄月秘宝激活")
    local config = gamedata.config:getConfigByName("xuanyue3_reward")[tostring(t.id)]
    if config.to_push == 1 then
        GameScene.layers["xuanyueTreasures3"].module.activeAction = t.id
    else
        runGamePrompt({msg = gameConfig.strings:string_common("xuanyueTreasures",13)})
    end
    UIRequest({type=7072})
end
