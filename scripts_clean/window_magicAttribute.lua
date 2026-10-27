--
-- Author: songyibo
-- Date: 2019-03-21 14:44:34
--
local magicAttribute = {
    rootNode = nil,
    rootItems = nil,
    bosstpye = 0,
  
}

function magicAttribute.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority

    self.rootNode,self.rootItems = CCBReaderLoad("magic/zongshuxingyulan", nil, true, "zongshuxingyulan")

    self.artifactConfig = gamedata.config.artifact --凡
    self.artifactConfigxian = gamedata.config.artifact_xian_config --仙

    self.unlock = data.data or {}

    printT(self.unlock)


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("magicAttribute")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    self:reload(self.unlock)
    self:initFixedString()
    return self.rootNode
end

function magicAttribute.reload(self,data)
    --凡（13
    self.fan_globalData = {}
    self.xian_globalData = {}
    for k,v in pairs(self.artifactConfig) do
        print(k,v)
        if self.unlock[k] then
             local atk_name = v["attr"..1]
             local def_name = v["attr"..2]
             local hp_name =  v["attr"..3]
             local xxx_name = v["attr"..4]
             print("atk_name:"..atk_name.." def_name:"..def_name.." hp_name:"..hp_name.." xxx_name:"..xxx_name)

             local atk_v = self.unlock[k]["attr"..1] 
             local def_v = self.unlock[k]["attr"..2] 
             local hp_v = self.unlock[k]["attr"..3] 
             local xxx_v = self.unlock[k]["attr"..4] 

             print("atk_v:"..atk_v.." def_v:"..def_v.." hp_v:"..hp_v.." xxx_v:"..xxx_v)

             self:tablenumAdd_fan(atk_name,atk_v,false,v["init"..1]<1)
             self:tablenumAdd_fan(def_name,def_v,false,v["init"..2]<1)
             self:tablenumAdd_fan(hp_name,hp_v,false,v["init"..3]<1)
             self:tablenumAdd_fan(xxx_name,xxx_v,false,v["init"..4]<1)
        end
    end

    for k,v in pairs(self.artifactConfigxian) do
        printT(self.artifactConfigxian)
        print(k,v)
        if self.unlock[k] then
             local atk_name = v[tostring(1)]["attr"..1]
             local def_name = v[tostring(1)]["attr"..2]
             local hp_name =  v[tostring(1)]["attr"..3]
             local xxx_name = v[tostring(1)]["attr"..4]
             print("g_atk_name:"..atk_name.." g_def_name:"..def_name.." g_hp_name:"..hp_name.." g_xxx_name:"..xxx_name)

             local atk_v = self.unlock[k]["attr"..5] 
             local def_v = self.unlock[k]["attr"..6] 
             local hp_v = self.unlock[k]["attr"..7] 
             local xxx_v = self.unlock[k]["attr"..8] 

             print("g_atk_v:"..atk_v.." g_def_v:"..def_v.." g_hp_v:"..hp_v.." g_xxx_v:"..xxx_v)

             self:tablenumAdd_fan(atk_name,atk_v,true,v[tostring(1)]["init"..1]<1)
             self:tablenumAdd_fan(def_name,def_v,true,v[tostring(1)]["init"..2]<1)
             self:tablenumAdd_fan(hp_name,hp_v,true,v[tostring(1)]["init"..3]<1)
             self:tablenumAdd_fan(xxx_name,xxx_v,true,v[tostring(1)]["init"..4]<1)
        end
    end


    for k,v in pairs(self.fan_globalData) do

        local textname = v.name
        local textvalue = v.num
        local ispersent = v.ispersent
        print("fan_globalData",textname,textvalue)
        if self.rootItems[textname] then
            if ispersent then
               self.rootItems[textname]:setString(tostring(textvalue).."%")
            else 
               self.rootItems[textname]:setString(tostring(textvalue))
            end    
        end    
    end   

     for k,v in pairs(self.xian_globalData) do
        local textname = v.name
        local textvalue = v.num
          local ispersent = v.ispersent
        print("xian_globalData",textname,textvalue)
        if self.rootItems[textname] then
            if ispersent then
               self.rootItems[textname]:setString(tostring(textvalue).."%")
            else 
               self.rootItems[textname]:setString(tostring(textvalue))
            end    
        end    
    end   


end


-- 相加的key 相加的value 凡或仙 是否显示百分比
function magicAttribute.tablenumAdd_fan(self,key,value,isxian,ispersent)
    if isxian then--仙
        if self.xian_globalData ~= nil then
            local isexit = false
            for i,v in ipairs(self.xian_globalData) do
                if v.name == key then
                    print("仙 相加：之前 key-value",key,value)
                    v.num = v.num + value
                    print("仙 相加：中",key,value)
                    print("仙 相加：之后 key-value",key,v.num)
                    isexit = true
                end    
            end
            if not isexit then
                print("仙 初次加入：key-value",key,value)
                table.insert(self.xian_globalData,{name = key,num = value, ispersent = ispersent})
            end    
        end    
    else--凡
        if self.fan_globalData ~= nil then
            local isexit = false
            for i,v in ipairs(self.fan_globalData) do
                if v.name == key then
                    print("凡 相加：之前 key-value",key,value)
                    v.num = v.num + value
                    print("凡 相加：中",key,value)
                    print("凡 相加：之后 key-value",key,v.num)
                    isexit = true
                end    
            end
            if not isexit then
                 print("凡 初次加入：key-value",key,value)
                table.insert(self.fan_globalData,{name = key,num = value, ispersent = ispersent})
            end    
        end    
    end
end



function magicAttribute.initFixedString(self)
	-- ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),19)
	-- ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),19)
end

function magicAttribute.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
   
    if self.callback then
        self.callback()
    end	
end
return magicAttribute