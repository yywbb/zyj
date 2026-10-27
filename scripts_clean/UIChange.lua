function UIGeneralChange(t)
	print("武将转换 7025")
	-- printT(t)
	if GameScene.layers["change"].show then
        GameScene.layers["change"].module:generalChange(t)
    end

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
    UIRequest({type = 1001})

    if t.illusionGeneral then
        UIRequest({type = 8110,update = true})
    end
    
    if t.updateExclusiveArtifact then
        --专属
        UIRequest({type = 8101})
        UIRequest({type = 8105})
        UIRequest({type = 8109,update = true})
    end
    
end

function UISwapChange(t)
	print("武将互换 8095")
	-- printT(t)
	if GameScene.layers["change"].show then
        GameScene.layers["change"].module:generalChange(t)
    end
    GameScene:addUpdate(1200)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
    UIRequest({type = 1001})

    if gameConfig:checkBuildOpen(378) then
        UIRequest({type = 5511,update = true}) 
        UIRequest{type = 5512,iid = t.general.iid,update = true}
        UIRequest{type = 5512,iid = t.general2.iid,update = true}
    end

    if t.updateExclusiveArtifact then
        --专属
        UIRequest({type = 8101})
        UIRequest({type = 8105})
        UIRequest({type = 8109,update = true})
    end
    
end