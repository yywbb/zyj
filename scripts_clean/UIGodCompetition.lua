--
-- Author: yuxiaofeng
-- Date: 2022-02-16 13:44:13
--

function UIGodCompetitionSlotsQuery(t)
	printT(t,"8252 封神赛阵容查询")

    t.slots = GameScene.layers["slotsInfo"].module.slotdata
	if GameScene.layers["godCompetitionSlotsInfo"].show then
        GameScene.layers["godCompetitionSlotsInfo"].module:reload(t)
    end

    if GameScene.layers["godCompetitionSlotsDetail"].show then
        GameScene.layers["godCompetitionSlotsDetail"].module:reloadSlotsDetail(t)
    end

end


function UICompetitionSlotsIndexSave(t)
	printT(t,"825200 封神赛阵容index")
	if GameScene.layers["godCompetitionSlotsInfo"].show then
        GameScene.layers["godCompetitionSlotsInfo"].module:reloadSlotsIndex(t)
    end
end

function UIGodCompetitionChangeSlots(t)
	printT(t,"8253 封神赛 换/上 武将或在阵容武将")

	if GameScene.layers["godCompetitionSlotsInfo"].show then
        GameScene.layers["godCompetitionSlotsInfo"].module:reload(t)
    end
end

function UIGodCompetitionChangePet(t)
	printT(t,"8254 封神赛上/换魔宠")

	if GameScene.layers["godCompetitionSlotsInfo"].show then
        GameScene.layers["godCompetitionSlotsInfo"].module:reload(t)
    end

end

function UIGodCompetitionSlotSpiritQuery(t)
    printT(t,"8255/6/7 封神赛 灵阵改变")
    if GameScene.layers["godCompetitiondeployment"].show then
        GameScene.layers["godCompetitiondeployment"].module:reloadSlotSpirit(t.slotSpirit)
    end
end    
