local function localWorldBossPage(t)
    local layer=GameScene.layers.worldboss
    return not t.localSkip and layer and layer.show and layer.module.rootNode
        and t.view==layer.module.localWorldBossView and t.page==layer.module.selectpage and layer.module
end
function LocalWorldBossError(t)
    if not t.localWorldBossRejected and t.request_opcode~=3401 and t.request_opcode~=3411 then return end
    local layer=GameScene.layers.worldboss
    if layer and layer.show and layer.module.rootNode then
        layer.module.localWorldBossBusy=nil
        layer.module:setauto(false)
        layer.module:setAttackstatus((layer.module.localWorldBossReady or 0)<=gamedata:time())
    end
end
for kind=1,2 do
    local base=kind==1 and 3400 or 3410
    local prefix="UIWorldBoss"..kind
    _G[prefix.."Query"]=function(t)
        if t.localSkip then return end
        local main=GameScene.layers.main
        if main and main.module then main.module:setWorldBossStatus(t.mainStatus or t.worldboss.status) end
        local page=localWorldBossPage(t)
        if not page then return end
        local was=page.data[page.selectpage].statusdata.status
        page:reloadstatus(t.worldboss)
        if was==1 and t.worldboss.status==0 then
            page:setauto(false)
            page:localWorldBossRequest({type=base+4})
        end
    end
    _G[prefix.."Attack"]=function(t)
        local layer=GameScene.layers.worldboss
        if layer and layer.module.localWorldBossBusy==t.type then layer.module.localWorldBossBusy=nil end
        local page=localWorldBossPage(t)
        if not page then
            if t.reward and next(t.reward) then updateDataLife(t.reward) end
            return
        end
        page.localWorldBossPlaying=true
        page:stoptnotify()
        local function done()
            if not localWorldBossPage(t) then return end
            page.localWorldBossPlaying=false
            page:reloadstatus(t.worldboss)
            page:localWorldBossRequest({type=base})
            page:localWorldBossRequest({type=base+4})
            page:startnotify()
        end
        if t.isauto==1 then
            if t.reward and next(t.reward) then showRewardPopupWindow(t.reward,nil,done) else done() end
        elseif t.battlereport then RunbattleCallBack("worldboss",t,done)
        else done() end
    end
    _G[prefix.."Rank"]=function(t)
        local page=localWorldBossPage(t)
        if page then page:setrealrank(t.ranks) end
    end
    _G[prefix.."RealNotify"]=function(t)
        local page=localWorldBossPage(t)
        if page then page:setbosshp(t.bosshp);page:reloadnotify(t.infos) end
    end
    _G[prefix.."PreRank"]=function(t)
        local page=localWorldBossPage(t)
        if page then page:reloadprerank(t) end
    end
end
