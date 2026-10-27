--
-- Created by IntelliJ IDEA.
-- User: liliang
-- Date: 13-8-1
-- Time: 上午10:20
-- To change this template use File | Settings | File Templates.
--

local Prompts = {}
local index=1
local lastScene = nil

function clearPrompt()
     for k,v in pairs(Prompts) do
         v:removeFromParentAndCleanup(true)
     end
     Prompts = {}
end

--游戏提示信息
function runGamePrompt(dataTable,callback)
    if not dataTable["msg"] then return end
    if dataTable["msg"] == "" then return end

    if gamedata.isdebug then
        print(debug.traceback())
    end

    local ccbName = "Prompts/GamePrompt"
    if dataTable.change_type and dataTable.change_type == "red" then
        ccbName = "Prompts/GamePrompt2"
    elseif dataTable["msg"].change_type then
        ccbName = "Prompts/GamePrompt_battle"
    end
    local promptLoaderLayer, ccbDocumentControler = CCBReaderLoad(ccbName, nil, true, "GamePrompt")

    local nowScene = CCDirector:sharedDirector():getRunningScene()
    if nowScene ~= lastScene then Prompts = {} end

    for k,v in pairs(Prompts) do
        v:runAction(CCMoveBy:create(0.3,ccp(0,164*(gamedata.device.SCREEN_WIDTH/gameConfig.originSize.width))))
    end

    index = index +1
    if index >10000 then index = 1 end
    local index_ = index
    Prompts[index_] = promptLoaderLayer

    promptLoaderLayer:setPosition(ccp(gamedata.device.SCREEN_WIDTH/2, gamedata.device.SCREEN_HEIGHT * 0.618))
    ccbDocumentControler.node:setScale(gamedata.device.SCREEN_WIDTH/gameConfig.originSize.width)

    lastScene= nowScene
    lastScene:addChild(promptLoaderLayer,10000)
    printT(dataTable,"runGamePrompt===dataTable")

    if dataTable["msg"].change_type then
        local width = 0
        local tonum = dataTable["msg"].topwer_num or GameScene.roleinfo.power

        ccbDocumentControler.num_now_power:setString(tonum)
        width = 215 + ccbDocumentControler.num_now_power:getContentSize().width + 10
        ccbDocumentControler.addNode:setPositionX(width)
        ccbDocumentControler.subNode:setPositionX(width)

        ccbDocumentControler.addnum:setString(dataTable["msg"].change_num)
        ccbDocumentControler.subnum:setString(dataTable["msg"].change_num)

        if dataTable["msg"].change_type == "sub" then
            ccbDocumentControler.addNode:setVisible(false)
            ccbDocumentControler.subNode:setVisible(true)
            width = width + 50 + ccbDocumentControler.subnum:getContentSize().width
        else
            ccbDocumentControler.addNode:setVisible(true)
            ccbDocumentControler.subNode:setVisible(false)
            width = width + 50 + ccbDocumentControler.addnum:getContentSize().width
        end
        ccbDocumentControler.node_power:setPositionX(- width / 2)

        ccbDocumentControler.addnum:setString("")
        ccbDocumentControler.subnum:setString("")
        --
        local shownum = {}
        for i = 1,10 do
            if math.ceil(i*dataTable["msg"].change_num/10) > dataTable["msg"].change_num then
                shownum[i] = dataTable["msg"].change_num
            else    
                shownum[i] = math.ceil(i*dataTable["msg"].change_num/10)
            end    
            ccbDocumentControler.node_power:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.1*i),CCCallFunc:create(function()
                ccbDocumentControler.addnum:setString(shownum[i])
                ccbDocumentControler.subnum:setString(shownum[i])
            end)))
        end


    elseif dataTable["msg"].color then
        local promptLabel = tolua.cast(ccbDocumentControler.promptLabel, "CCLabelTTF") --提示信息label
        promptLabel:setString(dataTable["msg"].str)
        promptLabel:setColor(dataTable["msg"].color)   
    else
        local promptLabel = tolua.cast(ccbDocumentControler.promptLabel, "CCLabelTTF") --提示信息label
        promptLabel:setString(dataTable["msg"])
        if dataTable["msg"] == gameConfig.strings:string_common("moreCommon","gongneng") then
            gamedata.music:PlayInvalid()
        end
        --	promptLabel:setColor(dataTable["color"])
        --	promptLabel:setFontSize(dataTable["size"])
    end
    -------------------------------------------------------------------------------------------------------------------
    local animationManager = getAnimationManager(ccbDocumentControler)
    --动画完成操作
    animationManager:setAnimationCompletedCallback(function()
    --移除
        Prompts[index_] = nil
        promptLoaderLayer:removeFromParentAndCleanup(true)

        if callback then
            callback()
        end
    end)
    --先播放动画
    animationManager:runAnimationsForSequenceNamed("prompt")
end

--yuan,skill
function runGamePromptSkill(dataTable,callback)
    if not (dataTable and dataTable.type) then return end

    local promptLoaderLayer, ccbDocumentControler = CCBReaderLoad(dataTable.type == "skill" and "Prompts/GamePrompt_skill" or "Prompts/GamePrompt_yuan", nil, true, "GamePrompt")

    local nowScene = CCDirector:sharedDirector():getRunningScene()
    if nowScene ~= lastScene then Prompts = {} end

    for k,v in pairs(Prompts) do
        v:runAction(CCMoveBy:create(0.3,ccp(0,164*(gamedata.device.SCREEN_WIDTH/gameConfig.originSize.width))))
    end

    index = index +1
    if index >10000 then index = 1 end
    local index_ = index
    Prompts[index_] = promptLoaderLayer

    promptLoaderLayer:setPosition(ccp(gamedata.device.SCREEN_WIDTH/2, gamedata.device.SCREEN_HEIGHT * 0.618))
    ccbDocumentControler.node:setScale(gamedata.device.SCREEN_WIDTH/gameConfig.originSize.width)

    lastScene= nowScene
    lastScene:addChild(promptLoaderLayer,10000)

    ui.setLabelString(ccbDocumentControler.lab,nil,14)
    ui.setLabelString(ccbDocumentControler.name,dataTable.name or "",21)

    -------------------------------------------------------------------------------------------------------------------
    local animationManager = getAnimationManager(ccbDocumentControler)
    --动画完成操作
    animationManager:setAnimationCompletedCallback(function()
    --移除
        Prompts[index_] = nil
        promptLoaderLayer:removeFromParentAndCleanup(true)

        if callback then
            callback()
        end
    end)
    --先播放动画
    animationManager:runAnimationsForSequenceNamed("prompt")
end


function runGamePromptTitle(dataTable,callback)
    if not (dataTable and dataTable.type) then return end

    local promptLoaderLayer, ccbDocumentControler = CCBReaderLoad(dataTable.type == "title" and "Prompts/GamePrompt_chenghao" or "Prompts/GamePrompt_chenghao", nil, true, "GamePrompt")

    local nowScene = CCDirector:sharedDirector():getRunningScene()
    if nowScene ~= lastScene then Prompts = {} end

    for k,v in pairs(Prompts) do
        v:runAction(CCMoveBy:create(0.3,ccp(0,164*(gamedata.device.SCREEN_WIDTH/gameConfig.originSize.width))))
    end

    index = index +1
    if index >10000 then index = 1 end
    local index_ = index
    Prompts[index_] = promptLoaderLayer

    promptLoaderLayer:setPosition(ccp(gamedata.device.SCREEN_WIDTH/2, gamedata.device.SCREEN_HEIGHT * 0.618))
    ccbDocumentControler.node:setScale(gamedata.device.SCREEN_WIDTH/gameConfig.originSize.width)

    lastScene= nowScene
    lastScene:addChild(promptLoaderLayer,100001)

    ui.setLabelString(ccbDocumentControler.lab,dataTable.type == "title" and gameConfig.strings:string_common("fixedString","mainscene",27) or gameConfig.strings:string_common("fixedString","mainscene",28),14)
    ui.setLabelString(ccbDocumentControler.name,dataTable.name or "",21)

    if dataTable.time then
        ccbDocumentControler.timenode:setVisible(true)
        ccbDocumentControler.time:setString(gameConfig.strings:titleEndTime(dataTable.time))
    else
        ccbDocumentControler.timenode:setVisible(false)
    end
    -------------------------------------------------------------------------------------------------------------------
    local animationManager = getAnimationManager(ccbDocumentControler)
    --动画完成操作
    animationManager:setAnimationCompletedCallback(function()
    --移除
        Prompts[index_] = nil
        promptLoaderLayer:removeFromParentAndCleanup(true)

        if callback then
            callback()
        end
    end)
    --先播放动画
    animationManager:runAnimationsForSequenceNamed("prompt")
end
   �   