function LocalHelperContext()
    local layer=GameScene.layers.gameHelper or {}
    local page=layer.module or {}
    return {generation=page.localHelperGeneration,page=page.selectPage,status=page.status}
end

function LocalHelperActive(view)
    local layer=GameScene.layers.gameHelper
    return view and layer and layer.show and layer.module.rootNode
        and view.generation==layer.module.localHelperGeneration
        and view.page==layer.module.selectPage and view.status==layer.module.status
end

local helperSend=UIRequest
local helperSendEx=UIRequestEx
local function helperLocked(req)
    return localHelperExecuting and req.type~=999904 and req.type~=999905 and req.type~=999988
        and req.type~=777777 and req.type~=1000
end
function UIRequest(req,...)
    if helperLocked(req) then
        runGamePrompt({msg="助手执行结果未返回，请等待；未知超时请重进游戏"})
        return
    end
    if req.type==6211 or req.type==6212 then
        req.helperView=req.helperView or LocalHelperContext()
        if req.type==6212 and not LocalHelperActive(req.helperView) then return end
        localHelperAction=(localHelperAction or 0)+1
        req.helperAction=localHelperAction
        if req.helperToken then localHelperExecuting=req.helperAction end
    end
    return helperSend(req,...)
end

function UIRequestEx(req,...)
    if helperLocked(req) then
        runGamePrompt({msg="助手执行结果未返回，请等待；未知超时请重进游戏"})
        return
    end
    return helperSendEx(req,...)
end

function LocalHelperUIError(t)
    if not t.localHelperError then return false end
    if localHelperExecuting==t.helperAction then localHelperExecuting=nil end
    if LocalHelperActive(t.helperView) then
        runGamePrompt({msg=t.msg or "助手请求未执行，请重新打开助手获取当前状态和报价"})
    end
    return true
end

function UIGameHelperQuery(t)
    if t.localHelperIgnored or not LocalHelperActive(t.helperView) then return end
    GameScene.layers.gameHelper.module:initData(t.data)
end

function UIGameHelperExe(t)
    if t.localHelperIgnored then return end
    if localHelperExecuting==t.helperAction then localHelperExecuting=nil end
    if not LocalHelperActive(t.helperView) then return end
    if t.helperQuote then
        local view=t.helperView
        local submitted=false
        gameWindows:openWindow("gameHelperConfirm",{data={[1001]=t.helperCost},helper=true,
            helperInfo="本批接入"..t.helperCount.."项；仅扣实际费用。观星/蓬莱仅用免费次数。"},function()
            if submitted or not LocalHelperActive(view) then return end
            submitted=true
            UIRequest({type=6212,params=t.params,ext=t.ext,helperToken=t.helperToken,helperView=view})
        end)
    elseif t.helperAlreadyDone then
        runGamePrompt({msg="上次助手操作已结算，本次没有重复执行或收费"})
        UIRequest({type=6211})
    else
        -- 网络已更新真实奖励，后续绝对快照校准；关闭日志只读查询，不再应用奖励。
        GameScene:addUpdate(10021);GameScene:addUpdate(10023)
        gameWindows:openWindow("gameHelperLog",{data=t.data,method="exc"},function()
            if LocalHelperActive(t.helperView) then UIRequest({type=6211}) end
        end)
    end
end
