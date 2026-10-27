--
-- Author: songyibo
-- Date: 2019-03-21 11:16:04
--



function UIBlessingCaveStatusQuery(t)
    printT(t,"6520 福祉天宫查询")
    if not GameScene.layers["blessingCave"].show then
        GameScene:shiftLayer("blessingCave","up",t)
    else
        GameScene.layers["blessingCave"].module:reload(t)
    end
    
end


function UIBlessingCaveAttack(t)
    printT(t,"6521 福祉天宫攻打")

    local cb = function()

        if GameScene.layers["blessingCave"].show then
              UIRequest({type = 6520})
        end
    end

    RunbattleCallBack("blessingCave", t, cb)
end


function UIBlessingCaveSweep(t)
    printT(t,"6522 福祉天宫扫荡")
    
    
    local cb = function()
        if GameScene.layers["blessingCave"].show then
               UIRequest({type = 6520})
        end
       
    end

    showRewardPopupWindow(t.reward,nil,cb)

end


