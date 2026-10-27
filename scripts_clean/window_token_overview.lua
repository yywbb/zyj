local tokenOverview = {
	rootNode = nil,
    rootItems = nil,

    allnum = {
        atk = 0,--攻击力
        speed = 0,--速度
        subdmg = 0,--减伤
        adddmg = 0,--增伤
    },
    method = {
        atk = "",--攻击力
        speed = "",--速度
        subdmg = "",--减伤
        adddmg = "",--增伤
    }

}

function tokenOverview.open(self,touchPriority,data,callback)
    self:initNode(touchPriority)
    self:initConfig()
    self:initEvent()
    
   
    self:reloadData(data)

    return self.rootNode
end

function tokenOverview.initNode(self, touchPriority)
    self.rootNode, self.rootItems = CCBReaderLoad("tianjiling/tc_shuxingzonglan", nil, true, "tc_shuxingzonglan")
    self.touchPriority = touchPriority
end

function tokenOverview.initConfig(self)
    self.tokensuitConfig = gamedata.config.token_suit
  
end

function tokenOverview.initEvent(self)
    local _cb = function()
        gameWindows:closeWindow("tokenOverview")
    end

    ui.commonBtn(self, self.rootItems, "closeButton", _cb)
end

function tokenOverview.reloadData(self, data)
    local _result = {}

    --筛选数据
    for i = 1, table.getTableLength(data) do
         local index = 0
         local _stage = data[i]
         printT(_stage)
         for k =1,table.getTableLength(_stage) do
            local point = _stage[k]
            print("point",point)
            if point>0 then
                index = index+1
            end    
            if k == 4 then
                table.insert(_result,index)
            end    
         end   
    end
    --添加属性
    printT(_result,"_result")
    for i =1,table.getTableLength(_result) do
          for k =1,_result[i] do
            if  self.tokensuitConfig[tostring(i)] and self.tokensuitConfig[tostring(i)][tostring(k)]  then
                printT(self.tokensuitConfig[tostring(i)][tostring(k)])
                local explain =  self.tokensuitConfig[tostring(i)][tostring(k)].attribute_explain	
                local method =  self.tokensuitConfig[tostring(i)][tostring(k)].method	
                local value =  self.tokensuitConfig[tostring(i)][tostring(k)].value	
                if value and self.allnum[explain] then
                    self.allnum[explain] =self.allnum[explain] + value
                end    
                if self.method[explain] then
                    self.method[explain] = method
                end   
            end 
          end  
    end

    printT(self.allnum,"allnum")
    for k,v in pairs(self.allnum) do
        print(k,v)
        if self.rootItems[k] then
            local methodStr = v
            if self.method[k] == "percent" then
                methodStr = v * 100 .. "%"
            end    
            self.rootItems[k]:setString(methodStr)
        end    
    end

end

function tokenOverview.close(self)
    print("close")
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.allnum = {
        atk = 0,
        speed = 0,
        subdmg = 0,
        adddmg = 0,
    }
    
    self.tokensuitConfig = nil
end

return tokenOverview