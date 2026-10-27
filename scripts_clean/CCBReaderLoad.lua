--[[
-- CCB reader load module.
 ]]

--TODO remove global variable ccb
ccb = ccb or {}
cclog"create global ccb {} table object."

--- CCBReader Load function
-- @param strFilePath String file path in lua searching path
-- @param proxy Optinal. CCBProxy to load ccb file
-- @param bSetOwner Boolean value default is false, optional
-- @param strOwnerName owner name of the ccb[name] to contains owner exported ojects.
-- @return ccbLayer, ccbDocumentControler, proxy
function CCBReaderLoad(strFilePath, proxy, bSetOwner, strOwnerName,timelineCallBacks)
    if nil == proxy then
        proxy = CCBProxy:create()
    end

    if bSetOwner == nil then bSetOwner = false end

    local documentControllerName, documentControler = nil, {}
    if nil == strOwnerName then
        documentControllerName = "aDocumentControler"
    end

    cclog("Load ccbi: %q , support owner: %q, strOwnername: %q", strFilePath, tostring(bSetOwner), tostring(strOwnerName))

    local ccbReader = proxy:createCCBReader()
    cclog("ccbReader created:%p", ccbReader)

    local node = proxy:readCCBFromFile(strFilePath, ccbReader, bSetOwner)
    assert(node ~= nil, string.format("Assert: Read ccb from file %q result is nil.", strFilePath))

    local owner = ccbReader:getOwner()

    local rootName = ""

    --owner set in readCCBFromFile is proxy
    if nil ~= owner then
        ccb[strOwnerName] = {}
        --Variables
        local ownerOutletNames = tolua.cast(ccbReader:getOwnerOutletNames(), "CCArray")
        local ownerOutletNodes = tolua.cast(ccbReader:getOwnerOutletNodes(), "CCArray")

        --print("ownerOutletNames:count() = ", ownerOutletNames:count())
        --print("ownerOutletNodes:count() = ", ownerOutletNodes:count())


        local repeatNames = {}

        for i = 1, ownerOutletNodes:count() do
            local outletName = tolua.cast(ownerOutletNames:objectAtIndex(i - 1), "CCString")
            --print(outletName:getCString())
            			--cclog("Cast index: %i outletName: %q",i,outletName:getCString())

            local outletNode = tolua.cast(ownerOutletNodes:objectAtIndex(i - 1), "CCNode")

            if "" ~= strOwnerName and nil ~= ccb[strOwnerName] then
                -- CCNode type is not converted in the c++ method CCProxy::getNodeTypeName();
                -- patch No Support type to type CCNode.
                local nodeType = proxy:getNodeTypeName(outletNode)
                if "No Support" == nodeType then nodeType = "CCNode" end
                local outletNameFix = outletName:getCString()
--                local outletNameEx = outletNameFix
--                for j = 0,1000 do
--                    if j == 0 then
--                        if ccb[strOwnerName][outletNameEx] == nil then
--                            ccb[strOwnerName][outletNameEx] =   tolua.cast(outletNode, nodeType)
--                            break
--                        end
--                    else
--                        outletNameEx = outletNameFix.."_"..j
--                        if ccb[strOwnerName][outletNameEx] == nil then
--                            ccb[strOwnerName][outletNameEx] =   tolua.cast(outletNode, nodeType)
--                            break
--                        end
--                    end
--                end
--
--
                if ccb[strOwnerName][outletNameFix] then
                    repeatNames[outletNameFix] = (repeatNames[outletNameFix] or 0) + 1
                end
                ccb[strOwnerName][outletNameFix..(repeatNames[outletNameFix] and ("_"..repeatNames[outletNameFix]) or "")] =   tolua.cast(outletNode, nodeType)
                --ccb[strOwnerName][outletName:getCString()] = tolua.cast(outletNode, nodeType)
                --cclog("Set ccb[%q][%q] = %s", strOwnerName, outletName:getCString(), nodeType)
            end
        end

        --Callbacks
        local ownerCallbackNames = tolua.cast(ccbReader:getOwnerCallbackNames(), "CCArray")
        --cclog("Owner callback names count : %i ", ownerCallbackNames:count())

        local ownerCallbackNodes = tolua.cast(ccbReader:getOwnerCallbackNodes(), "CCArray")
        local i = 1
        for i = 1, ownerCallbackNames:count() do
            local callbackName = tolua.cast(ownerCallbackNames:objectAtIndex(i - 1), "CCString")
            local callbackNode = tolua.cast(ownerCallbackNodes:objectAtIndex(i - 1), "CCNode")
            if "" ~= strOwnerName and nil ~= ccb[strOwnerName] then
                local cbName = callbackName:getCString()
                if "function" == type(ccb[strOwnerName][cbName]) then
                    proxy:setCallback(callbackNode, ccb[strOwnerName][cbName])
                else
                    cclog("WARNING: Cannot found lua function [" .. strOwnerName .. "." .. cbName .. "] for owner selector")
                end
            end
        end

    else
        --cclog"owner is nil skipping."
    end

    local nodesWithAnimationManagers = tolua.cast(ccbReader:getNodesWithAnimationManagers(), "CCArray")
    local animationManagersForNodes = tolua.cast(ccbReader:getAnimationManagersForNodes(), "CCArray")

    for i = 1, nodesWithAnimationManagers:count() do
        local innerNode = tolua.cast(nodesWithAnimationManagers:objectAtIndex(i - 1), "CCNode")
        local animationManager = tolua.cast(animationManagersForNodes:objectAtIndex(i - 1), "CCBAnimationManager")
        documentControllerName = animationManager:getDocumentControllerName()
        if "" == documentControllerName then
            --cclog("documentControllerName is %q", "")
            if nil ~= strOwnerName then
                documentControllerName = strOwnerName:gsub("%Owner", "");
            else
                documentControllerName = 'aDocumentControler'
                ccb[documentControllerName] = {}
            end
            --cclog("Try to set owner name to:%q with strOwnerName:%q", documentControllerName, strOwnerName)
        end
        if nil ~= ccb[documentControllerName] then
            ccb[documentControllerName]["mAnimationManager"] = animationManager
            --cclog("set ccb[%q][%q]= CCBAnimationManager:%p", documentControllerName, "mAnimationManager", animationManager)
        else
            --cclog("WARN: ccb[%q][%q]= CCBAnimationManager:%s", documentControllerName, "mAnimationManager", tostring(nil))
        end

        --Callbacks
        local documentCallbackNames = tolua.cast(animationManager:getDocumentCallbackNames(), "CCArray")
        local documentCallbackNodes = tolua.cast(animationManager:getDocumentCallbackNodes(), "CCArray")

        for i = 1, documentCallbackNames:count() do
            local callbackName = tolua.cast(documentCallbackNames:objectAtIndex(i - 1), "CCString")
            local callbackNode = tolua.cast(documentCallbackNodes:objectAtIndex(i - 1), "CCNode")
            if "" ~= documentControllerName and nil ~= ccb[documentControllerName] then
                --proxy:setCallback(callbackNode,ccb[documentControllerName][callbackName:getCString()])
                local cbName = callbackName:getCString()
                if "function" == type(ccb[documentControllerName][cbName]) then
                    proxy:setCallback(callbackNode, ccb[documentControllerName][cbName])
                else
                    cclog("WARNING: Cannot found lua function [" .. documentControllerName .. "." .. cbName .. "] for docRoot selector")
                end
            end
        end

        --Variables
        local documentOutletNames = tolua.cast(animationManager:getDocumentOutletNames(), "CCArray")
        local documentOutletNodes = tolua.cast(animationManager:getDocumentOutletNodes(), "CCArray")

        --print("documentOutletNames:count() = ", documentOutletNames:count())
        --print("documentOutletNodes:count() = ", documentOutletNodes:count())

        for i = 1, documentOutletNames:count() do
            local outletName = tolua.cast(documentOutletNames:objectAtIndex(i - 1), "CCString")
            local outletNode = tolua.cast(documentOutletNodes:objectAtIndex(i - 1), "CCNode")

            if nil ~= ccb[documentControllerName] then
                ccb[documentControllerName][outletName:getCString()] = tolua.cast(outletNode, proxy:getNodeTypeName(outletNode))
                --cclog("Set ccb[%q][%q] = %s", documentControllerName, outletName:getCString(), proxy:getNodeTypeName(outletNode))
            end
        end
        --[[
        if (typeof(controller.onDidLoadFromCCB) == "function")
            controller.onDidLoadFromCCB();
        ]] --
        --Setup timeline callbacks
        local keyframeCallbacks = animationManager:getKeyframeCallbacks()

        for i = 1, keyframeCallbacks:count() do
            local callbackCombine = tolua.cast(keyframeCallbacks:objectAtIndex(i - 1), "CCString"):getCString()
            --print(callbackCombine)
            local beignIndex, endIndex = string.find(callbackCombine, ":")
            local callbackType = tonumber(string.sub(callbackCombine, 1, beignIndex - 1))
            local callbackName = string.sub(callbackCombine, endIndex + 1, -1)
            cclog("key frame callback name: " .. callbackName .. ", call back type: " .. callbackType)
            --Document callback

            if 1 == callbackType and nil ~= ccb[documentControllerName] then
                --local callfunc = CCCallFunc:create(ccb[documentControllerName][callbackName])
                local callfunc = CCCallFunc:create(timelineCallBacks[callbackName])
                animationManager:setCallFuncForLuaCallbackNamed(callfunc, callbackCombine);
            elseif 2 == callbackType and nil ~= owner then --Owner callback
                --print("strOwnerName:" .. strOwnerName .. " type:" .. type(ccb[strOwnerName]))
                --local callfunc = CCCallFunc:create(ccb[strOwnerName][callbackName])
                local callfunc = CCCallFunc:create(timelineCallBacks[callbackName])
                animationManager:setCallFuncForLuaCallbackNamed(callfunc, callbackCombine)
            else
                cclog"WARN:: type 0 is not supported."
            end
        end
        --start animation
        local autoPlaySeqId = animationManager:getAutoPlaySequenceId()
        if -1 ~= autoPlaySeqId then
            animationManager:runAnimationsForSequenceIdTweenDuration(autoPlaySeqId, 0)
        end
    end

    return node, bSetOwner and ccb[strOwnerName] or ccb[documentControllerName], proxy
end

--- Get animation manager from ccbDocumentControler
-- @param ccbControler CCBDocumentControler
-- @return animationManager for controling animation.
function getAnimationManager(ccbControler)
    local animationMgr
    --	assert(ccbControler, "ccbConttroller must ~= nil.")
    if nil ~= ccbControler["mAnimationManager"] then
        animationMgr = tolua.cast(ccbControler["mAnimationManager"], "CCBAnimationManager")
    else
        cclog"WANG :: mAnimationManager is nil."
    end
    return animationMgr
end

--- Play timeline by name
-- @param ccbControler CCBDocumentControler
-- @param timeline timeline name
function playTimeline(ccbControler, timeline)
    --	assert(ccbControler, "ccbControler must ~= nil.")
    local animationMgr = getAnimationManager(ccbControler);
    if nil ~= animationMgr then
        animationMgr:runAnimationsForSequenceNamed(timeline)
    end
end

