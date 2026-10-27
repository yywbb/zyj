--觉醒全屏动画
--zhangzhxin

local generalawakenfinish = {
    rootNode = nil,
    rootItems = nil,
}


function generalawakenfinish.open( self,touchPriority,data,callback )
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/juexingtisheng", nil, true, "juexingtisheng")
    self.touchPriority = touchPriority
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("generalawakenfinish")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)

    self.awakenConfig = gamedata.config:getConfigByName("general_awaken")
    self.generalConfig = gamedata.config:getConfigByName("general") 

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
    local b_skilllevel = data.b.skilllevel
    local e_skilllevel = data.e.general.skilllevel

    self.data = data.e.general

    local currentConfig = {}
    local nextConfig = {}
    local generalConfig = gamedata.config:getConfigByName("general")[tostring(self.data.cid)]
    local currentAwanken  = self.awakenConfig[tostring( self.data.skilllevel -1 )] or {}
    local nextAwanken  = self.awakenConfig[tostring( self.data.skilllevel )] or {}

    

    if generalConfig.awaken > 0 and gamedata.config.general_awakenattr[tostring(generalConfig.awaken)] and gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(b_skilllevel)] then
        table.insert(currentConfig ,{"atk",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(b_skilllevel)].awaken_atk})

        table.insert(currentConfig ,{"def",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(b_skilllevel)].awaken_def})

        table.insert(currentConfig ,{"hp",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(b_skilllevel)].awaken_hp})

        table.insert(currentConfig ,{"hit",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(b_skilllevel)].awaken_hit})
    else
    	table.insert(currentConfig ,{"atk",0})
        table.insert(currentConfig ,{"def",0})
        table.insert(currentConfig ,{"hp",0})
        table.insert(currentConfig ,{"hit",0})
    end
    
    if generalConfig.awaken > 0 and gamedata.config.general_awakenattr[tostring(generalConfig.awaken)] and gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.skilllevel)] then
        table.insert(nextConfig ,{"atk",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.skilllevel)].awaken_atk})

        table.insert(nextConfig ,{"def",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.skilllevel)].awaken_def})

        table.insert(nextConfig ,{"hp",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.skilllevel)].awaken_hp})

        table.insert(nextConfig ,{"hit",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.skilllevel)].awaken_hit})
    end

	local generalName = gamedata.config:getConfigByName("generalanimation")[tostring(generalConfig.animationid)].name
    self.General = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    self.General:setAnimation("stand",true,0)
    self.General:setScale(2.6)
    self.rootItems.general:addChild(self.General)

    ui.addAwakeEffect(self.rootItems.general,self.data.skilllevel,2.8)


    ui.setLabelString(self.rootItems.awakennamenext,self.awakenConfig[tostring(self.data.skilllevel)].name, 21)
    ui.setLabelString(self.rootItems.awakenname,self.awakenConfig[tostring(b_skilllevel)].name,21)

    if b_skilllevel == 0 and generalConfig.basic == 20 then
        local level = tonumber(gamedata.config:getConfigByName("global_kv").general_awaken20.value)
        ui.setLabelString(self.rootItems.awakenname,self.awakenConfig[tostring(level)].name,21)
    elseif b_skilllevel == 0 and generalConfig.basic == 23 then
        local level = tonumber(gamedata.config:getConfigByName("global_kv").general_awaken23.value)
        ui.setLabelString(self.rootItems.awakenname,self.awakenConfig[tostring(level)].name,21)
    else
        ui.setLabelString(self.rootItems.awakenname,self.awakenConfig[tostring(b_skilllevel)].name,21)
    end
    
    local fixbasic = "basic"
    if generalConfig.quality == 6 then
        fixbasic = "red_basic"
    elseif generalConfig.quality >= 7 then
        fixbasic = "gold_basic"    
    end
    if currentAwanken[fixbasic] < nextAwanken[fixbasic] and generalConfig.basic < nextAwanken[fixbasic]    then
        ui.setLabelString(self.rootItems.basicLable,gameConfig.strings:awakenUped(nextAwanken[fixbasic]),47)
        self.rootItems.awankennode:setVisible(true)            
    else
        self.rootItems.awankennode:setVisible(false)
    end
    
    for k,v in ipairs(currentConfig) do

        --ui.setLabelString( self.rootItems["attname"..k],gameConfig.strings:string_common("attr_type",v[1]),122)
        self.rootItems["attname"..k]:setString(gameConfig.strings:string_common("attr_type",v[1]))
        ui.setLabelString( self.rootItems["attr"..k],v[2],14)            
    end
    for k,v in ipairs(nextConfig) do
        --ui.setLabelString( self.rootItems["attnextname"..k],gameConfig.strings:string_common("attr_type",v[1]),122)
        self.rootItems["attnextname"..k]:setString(gameConfig.strings:string_common("attr_type",v[1]))
        ui.setLabelString( self.rootItems["attrnext"..k],v[2],14)
        if v[2] > currentConfig[k][2] then
            self.rootItems["attisup"..k]:setVisible(true)
        else
            self.rootItems["attisup"..k]:setVisible(false)
        end
    end

end


return generalawakenfinish
