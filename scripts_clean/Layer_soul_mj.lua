--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/10/24
-- Time: 上午10:13
-- To change this template use File | Settings | File Templates.
--

local soul_mj = {

   
}


function soul_mj.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("soul2/soul2", nil, true, "soul")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.toptitle:setPositionY(toppos)
    self.rootItems.listtopnode:setPositionY(toppos)
    self.rootItems.extopnode:setPositionY(toppos)

    self.rootItems.huntmid1:setPositionY((GameScene.topposY-1620)*0.3-200)
    self.rootItems.huntmid2:setPositionY((GameScene.topposY-1620)*0.3-200)
    self.rootItems.huntmid_top:setPositionY(toppos)
    self.rootItems.generalNode:setPositionY((GameScene.topposY-1620)*0.3-200+1140)
    self.rootItems.generalEffectNode:setPositionY((GameScene.topposY-1620)*0.3-200+1100)

    self.rootItems.huntlistScroll:setContentSize(CCSizeMake(980,320))

    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    self.General = CCSkeletonAnimation:create("houyi/houyi.json","houyi/houyi.atlas",1) -- houyi
    self.General:setAnimation("stand",true,0)
    self.General:setScale(1.2)
    self.General:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(self.General)

    self.rootItems.listscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-130))
    self.rootItems.exchangescroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))

    self.rootItems.huntstatusNode:removeAllChildrenWithCleanup(true)
    self.statusNode,self.statusItems = CCBReaderLoad("soul2/soul2_zhuan", nil, true, "soul_zhuan")
    self.statusNode:setPosition(0,0)
    self.rootItems.huntstatusNode:addChild(self.statusNode)

    self.rootItems.gotoEquipBtn:setSwallowsTouch(true)
    self.rootItems.gotoEquipBtn:setTouchPriority(-101)
    self.rootItems.gotoEquipBtn:addHandleOfControlEvent(function()
        print("去阵容猎命页面")
        GameScene:shiftLayerById(5)
    end, CCControlEventTouchUpInside)


    for i=1,5 do
        ui.setLabelString(self.statusItems["zhuanLab"..i],gameConfig.strings:string_common("soulName",i),2*i)
    end

    ui.setLabelString(self.rootItems.text1,nil,14)
    ui.setLabelString(self.rootItems.text2,nil,14)
    ui.setLabelString(self.rootItems.text3,nil,14)
    self.rootItems.goldhunteffectnode:setVisible(false)
    self.rootItems.coinhunteffectnode:setVisible(true)
    self:makeSoulCellData()

    for k,v in ipairs(self.listpageconfig) do
        self.rootItems[v.."Button"]:setTouchPriority(-110)
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            self:shiftListPage(v)
        end, CCControlEventTouchUpInside)
    end

    self.rootItems.to15:setTouchPriority(-101)
    self.rootItems.to15:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        self:shiftmainStatus(15)
    end, CCControlEventTouchUpInside)
    self.rootItems.to6:setTouchPriority(-101)
    self.rootItems.to6:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        self:shiftmainStatus(6)
    end, CCControlEventTouchUpInside)   
end

return soul_mj