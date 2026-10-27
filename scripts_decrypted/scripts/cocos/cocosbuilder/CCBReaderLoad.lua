if nil == cc.CCBReader then
    return
end

ccb = ccb or {}

function CCBReaderLoad(strFilePath,proxy,owner,strOwnerName,timelineCallBacks)
    -- if nil == proxy then
    --     return nil
    -- end
    if nil == proxy then
        proxy = CCBProxy:create()
    end

    cclog("Load ccbi: %q , support owner: %q, strOwnername: %q", strFilePath, tostring(owner), tostring(strOwnerName))

    local documentControllerName, documentControler = nil, {}
    if nil == strOwnerName then
        documentControllerName = "aDocumentControler"
    end
    local ccbReader = proxy:createCCBReader()
    ccbReader:setFontNameForTTF(gamedata.gameconfig.sysFontName)
    local node      = ccbReader:load(strFilePath)

    local rootName  = "" 
    --owner set in readCCBFromFile is proxy
    if nil ~= owner then
        ccb[strOwnerName] = {}
        --Variables
        local ownerOutletNames = ccbReader:getOwnerOutletNames() 
        local ownerOutletNodes = ccbReader:getOwnerOutletNodes()
        local repeatNames = {}
        for i = 1, table.getn(ownerOutletNames) do
            local outletName = ownerOutletNames[i]
            local outletNode = tolua.cast(ownerOutletNodes[i],"cc.Node")
            -- owner[outletName] = outletNode
            -- 添加11
            if "" ~= strOwnerName and nil ~= ccb[strOwnerName] then
                -- CCNode type is not converted in the c++ method CCProxy::getNodeTypeName();
                -- patch No Support type to type CCNode.
                local nodeType = proxy:getNodeTypeName(outletNode)
                if "No Support" == nodeType then nodeType = "cc.Node" end
                -- local outletNameFix = outletName:getCString()
                if ccb[strOwnerName][outletName] then
                    repeatNames[outletName] = (repeatNames[outletName] or 0) + 1
                end
                ccb[strOwnerName][outletName..(repeatNames[outletName] and ("_"..repeatNames[outletName]) or "")] =   tolua.cast(outletNode, nodeType)
            end
        end
        --Callbacks
        local ownerCallbackNames = ccbReader:getOwnerCallbackNames() 
        local ownerCallbackNodes = ccbReader:getOwnerCallbackNodes()
        local ownerCallbackControlEvents = ccbReader:getOwnerCallbackControlEvents()
        local i = 1
        for i = 1,table.getn(ownerCallbackNames) do
            local callbackName =  ownerCallbackNames[i]
            local callbackNode =  tolua.cast(ownerCallbackNodes[i],"cc.Node")
            -- print(callbackName,"  callbackName   ")
            if "function" == type(owner[callbackName]) then
                proxy:setCallback(callbackNode, owner[callbackName], ownerCallbackControlEvents[i])
            else
                print("Warning: Cannot find owner's lua function:" .. ":" .. callbackName .. " for ownerVar selector")
            end
        end

    end

    local nodesWithAnimationManagers = ccbReader:getNodesWithAnimationManagers()
    local animationManagersForNodes  = ccbReader:getAnimationManagersForNodes()

    for i = 1 , table.getn(nodesWithAnimationManagers) do
        local innerNode = tolua.cast(nodesWithAnimationManagers[i], "cc.Node")
        local animationManager = tolua.cast(animationManagersForNodes[i], "cc.CCBAnimationManager")
        documentControllerName = animationManager:getDocumentControllerName()
        if "" == documentControllerName then
            -- 最后处理
            if nil ~= strOwnerName then
                documentControllerName = strOwnerName:gsub("%Owner", "");
            else
                documentControllerName = 'aDocumentControler'
                ccb[documentControllerName] = {}
            end
        end

        if nil ~=  ccb[documentControllerName] and innerNode == node then
            ccb[documentControllerName]["mAnimationManager"] = animationManager
        end
        
        --Callbacks
        local documentCallbackNames = animationManager:getDocumentCallbackNames()
        local documentCallbackNodes = animationManager:getDocumentCallbackNodes()
        local documentCallbackControlEvents = animationManager:getDocumentCallbackControlEvents()

        for i = 1,table.getn(documentCallbackNames) do
            local callbackName = documentCallbackNames[i]
            local callbackNode = tolua.cast(documentCallbackNodes[i],"cc.Node")
            if "" ~= documentControllerName and nil ~= ccb[documentControllerName] then
                if "function" == type(ccb[documentControllerName][callbackName]) then
                    proxy:setCallback(callbackNode, ccb[documentControllerName][callbackName], documentCallbackControlEvents[i])
                else
                    -- print("Warning: Cannot found lua function [" .. documentControllerName .. ":" .. callbackName .. "] for docRoot selector")
                end
            end
        end

        --Variables
        local documentOutletNames = animationManager:getDocumentOutletNames()
        local documentOutletNodes = animationManager:getDocumentOutletNodes()

        for i = 1, table.getn(documentOutletNames) do
            local outletName = documentOutletNames[i]
            local outletNode = tolua.cast(documentOutletNodes[i],"cc.Node")
            local nodeType = proxy:getNodeTypeName(outletNode)

            if "No Support" == nodeType then nodeType = "cc.Node" end
            if nil ~= ccb[documentControllerName] then
                -- 修改1
                ccb[documentControllerName][outletName] = tolua.cast(outletNode, nodeType)
            end 
        end
        --Setup timeline callbacks
        local keyframeCallbacks = animationManager:getKeyframeCallbacks()

        for i = 1 , table.getn(keyframeCallbacks) do
            local callbackCombine = keyframeCallbacks[i]
            local beignIndex,endIndex = string.find(callbackCombine,":")
            local callbackType    = tonumber(string.sub(callbackCombine,1,beignIndex - 1))
            local callbackName    = string.sub(callbackCombine,endIndex + 1, -1)
            --Document callback
            if 1 == callbackType and nil ~= ccb[documentControllerName] then
                -- local callfunc = cc.CallFunc:create(ccb[documentControllerName][callbackName])
                local callfunc = cc.CallFunc:create(timelineCallBacks[callbackName])
                animationManager:setCallFuncForLuaCallbackNamed(callfunc, callbackCombine);
            elseif 2 == callbackType and nil ~= owner then --Owner callback
                -- local callfunc = cc.CallFunc:create(owner[callbackName])--need check
                -- 修改1
                local callfunc = cc.CallFunc:create(timelineCallBacks[callbackName])
                animationManager:setCallFuncForLuaCallbackNamed(callfunc, callbackCombine)
            end
        end
        --start animation
        local autoPlaySeqId = animationManager:getAutoPlaySequenceId()
        if -1 ~= autoPlaySeqId then
            animationManager:runAnimationsForSequenceIdTweenDuration(autoPlaySeqId, 0)
        end
    end
    -- return node,ccb[strOwnerName] or ccb[documentControllerName]

    return node,ccb[documentControllerName]
end


--- Get animation manager from ccbDocumentControler
-- @param ccbControler CCBDocumentControler
-- @return animationManager for controling animation.
function getAnimationManager(ccbControler)
    local animationMgr
    --  assert(ccbControler, "ccbConttroller must ~= nil.")
    if nil ~= ccbControler["mAnimationManager"] then
        animationMgr = tolua.cast(ccbControler["mAnimationManager"], "cc.CCBAnimationManager")
    else
        cclog"WANG :: mAnimationManager is nil."
    end
    return animationMgr
end

--- Play timeline by name
-- @param ccbControler CCBDocumentControler
-- @param timeline timeline name
function playTimeline(ccbControler, timeline)
    --  assert(ccbControler, "ccbControler must ~= nil.")
    local animationMgr = getAnimationManager(ccbControler);
    if nil ~= animationMgr then
        animationMgr:runAnimationsForSequenceNamed(timeline)
    end
end


local function CCBuilderReaderLoad(strFilePath,proxy,owner,strOwnerName)
    print("\n********** \n".."CCBuilderReaderLoad(strFilePath,proxy,owner,strOwnerName)".." was deprecated please use ".. "CCBReaderLoad(strFilePath,proxy,owner,strOwnerName)" .. " instead.\n**********")
    return CCBReaderLoad(strFilePath,proxy,owner,strOwnerName)
end
rawset(_G,"CCBuilderReaderLoad",CCBuilderReaderLoad)  �   