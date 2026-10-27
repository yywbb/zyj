--
-- Author: songyibo
-- Date: 2020-02-28 17:02:23
--
local generalawakenfinish = {
    rootNode = nil,
    rootItems = nil,
}


function generalawakenfinish.open( self,touchPriority,data,callback )
    self.rootNode, self.rootItems = CCBReaderLoad("devil/juexingtisheng", nil, true, "juexingtisheng")
    self.touchPriority = touchPriority
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("protagonistawakenfinish")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)

    self.awakenConfig = gamedata.config.protagonist_awaken

    self:reload(data,callback)

    return self.rootNode,true
end

function generalawakenfinish.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function generalawakenfinish.reload(self,data,callback)
    self.data = data

    local currentConfig = {}
    local nextConfig = {}

    local awakenConfig =  self.awakenConfig[tostring(self.data.general.skilllevel)]
    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]

    if self.awakenConfig[tostring(self.data.general.skilllevel - 1)] then
        table.insert(currentConfig ,{"atk",self.awakenConfig[tostring(self.data.general.skilllevel-1)].atk})

        table.insert(currentConfig ,{"def",self.awakenConfig[tostring(self.data.general.skilllevel-1)].def})

        table.insert(currentConfig ,{"hp",self.awakenConfig[tostring(self.data.general.skilllevel-1)].hp})

        table.insert(currentConfig ,{"adddmgpct",self.awakenConfig[tostring(self.data.general.skilllevel-1)].adddmgpct})

        table.insert(currentConfig ,{"subdmgpct",self.awakenConfig[tostring(self.data.general.skilllevel-1)].subdmgpct})
    end
    
    if awakenConfig then
    	table.insert(nextConfig ,{"atk",awakenConfig.atk})

        table.insert(nextConfig ,{"def",awakenConfig.def})

        table.insert(nextConfig ,{"hp",awakenConfig.hp})

        table.insert(nextConfig ,{"adddmgpct",awakenConfig.adddmgpct})

        table.insert(nextConfig ,{"subdmgpct",awakenConfig.subdmgpct})
    end

	local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
    self.General = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    self.General:setAnimation("stand",true,0)
    self.General:setScale(2.6)
    self.rootItems.general:addChild(self.General)


    ui.setLabelString(self.rootItems.awakennamenext,self.awakenConfig[tostring(self.data.general.skilllevel)].name, 21)
    ui.setLabelString(self.rootItems.awakenname,self.awakenConfig[tostring(self.data.general.skilllevel-1)].name,21)

    
    for k,v in ipairs(currentConfig) do

        --ui.setLabelString( self.rootItems["attname"..k],gameConfig.strings:string_common("attr_type",v[1]),122)
        self.rootItems["attname"..k]:setString(gameConfig.strings:string_common("attr_type",v[1]))
        ui.setLabelString( self.rootItems["attr"..k],ui.getAttrValue(v[2]),14)            
    end
    for k,v in ipairs(nextConfig) do
        --ui.setLabelString( self.rootItems["attnextname"..k],gameConfig.strings:string_common("attr_type",v[1]),122)
        self.rootItems["attnextname"..k]:setString(gameConfig.strings:string_common("attr_type",v[1]))
        ui.setLabelString( self.rootItems["attrnext"..k],ui.getAttrValue(v[2]),14)
        if v[2] > currentConfig[k][2] then
            self.rootItems["attisup"..k]:setVisible(true)
        else
            self.rootItems["attisup"..k]:setVisible(false)
        end
    end

end


return generalawakenfinish