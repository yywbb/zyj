--
-- Created by IntelliJ IDEA.
-- User: yxf
-- Date: 19/5/13
-- Time: 10:57
-- To change this template use File | Settings | File Templates.
--
--考试 三届联考

local examination = {
    rootNode = nil,
    rootItems = nil,
    touchPriority = -104,
    animationManager = nil,
    copyTotal = 6,
    normalCellSize = {x=1040,y=208+14},

    contentType = 1,

    kaoshiType = {"lianxi","zhoushi", "pangshi"},

    --status状态0未开启 1开启但未答题 2开启并在答题中  3完成
    -- data = {
    --   { kstype =1, status = 1},
    --   { kstype =2,status = 2, num = 5},
    --   { kstype =3,status = 3, num = 5, rightnum = 0, currentTimu = 0, useAlltime = 0,jifen = 0},
    -- },

    currenntKaoshitype = 1,

    --状态查询 (包括成绩单信息) 一个接口

    --开始考试
    --1、确认考试、获取第一道题目 

    --结果提交
    
    --排行查询


   isShowcjd = false,
   data =  {},
   countdowntimes =0,
   userClickAnswerIndex = 0,
   isResultShowTime = 0,
   rightAnswerIndex = 1,
   isLastTimu = false,
   rolelv = 0,
   rolegender = 0,

   examination_requestId = 0,
   examination_requestTimuType = 0,
   examination_requestTimuid = 0,
   examination_requestAnswerid = 0,
   examination_requestTimes = 0,

   -- userClickAnswerIndex = 0,
}
--真正的答题时间、开始考试时间、答案确认delay时间和正确答案delay显示时间

function examination.timeUpdate( ... )
    -- body
end

function examination.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("sanjieliankao/sanjieliankao", nil, true, "examination")

    self.rootNode:setPosition(-540,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos
    print(self.toppos,"toppos")
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.zhunkaoNode:setPosition(109,toppos-370)
    self.rootItems.bgBtn:setSwallowsTouch(true)
    self.rootItems.bgBtn:setTouchPriority(self.touchPriority)
    -- local height=  self.rootItems.contentNode:getContentSize().height
    -- print(height,"height")
    -- self.rootItems.contentNode:setPositionY((toppos-450-100-300-200)-750+160)
    local positony = 0
    local y = 1080
    if self.toppos>1900 then
       positony =   - (toppos - 1800)/2 + (self.toppos-1900)
    elseif self.toppos>= 1800 and  self.toppos<=1900 then 
         positony =   - (toppos - 1800)/2 + 20
    elseif toppos >y and self.toppos<1800 then
       positony =   - (toppos - y)/2 + 20
    else
       if (toppos - y) >320 then
            positony =   (toppos - y)/2
       else
            positony =  160
       end
    end       
    print(" positony:"..positony)
      
    self.rootItems.contentNode:setPositionY(positony)


    
    --准考证信息关闭按钮
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self:shiftNode(2)
    end,CCControlEventTouchUpInside)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.touchPriority)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

      --考试类型选择初始化
    local answer = gamedata.config.sanjie_answer
    for i,v in ipairs(self.kaoshiType) do
        print(i,v)
        print(answer[tostring(i)].name,"name")
        self.rootItems[v.."name"]:setString(answer[tostring(i)].name)
        self.rootItems[v.."sprite1"]:setVisible(false)
        self.rootItems[v.."Btn"]:setSwallowsTouch(true)
        self.rootItems[v.."Btn"]:setTouchPriority(self.touchPriority)
        self.rootItems[v.."Btn"]:addHandleOfControlEvent(function()
            if self.data  and self.data[tostring(i)] then

                local status = self.data[tostring(i)].status or 0

                if status == 1 and self.data[tostring(i)].endtime and gamedata:time() > self.data[tostring(i)].endtime then
                    runGamePrompt({msg = gameConfig.strings:string_common("examination", i+1)})
                    return
                end

                if status ==0 or status == 4 then
                   runGamePrompt({msg = gameConfig.strings:string_common("examination", i+1)})
                elseif status == 1 or status == 2 then
                    self.rootItems[v.."Showsprite"]:setVisible(false)
                    self:runKaoShiEffect(self.data[tostring(i)].kstype,i)
                    -- self:shiftNode(3)
                    -- self:reloadStartKaoshi(self.data[tostring(i)])
                    -- if status == 2 then
                    --     UIRequest( {type = 7003, timuType = self.currenntKaoshitype} )
                   -- end 
                else 
                   runGamePrompt({msg = gameConfig.strings:string_common("examination", 1)})
                end    
            end    
           
        end, CCControlEventTouchUpInside)
    end


    --取消考试
    self.rootItems.datiStartCancelBtn:setSwallowsTouch(true)
    self.rootItems.datiStartCancelBtn:setTouchPriority(self.touchPriority)
    self.rootItems.datiStartCancelBtn:addHandleOfControlEvent(function()
        self:shiftNode(2)
    end,CCControlEventTouchUpInside)
    --开始考试
    self.rootItems.datiStartSureBtn:setSwallowsTouch(true)
    self.rootItems.datiStartSureBtn:setTouchPriority(self.touchPriority)
    self.rootItems.datiStartSureBtn:addHandleOfControlEvent(function()

        if self.data[tostring(self.currenntKaoshitype)] and self.data[tostring(self.currenntKaoshitype)].endtime then
            if gamedata:time() > self.data[tostring(self.currenntKaoshitype)].endtime then
                runGamePrompt({msg = "答题时间已结束"})
                self:shiftNode(2)
                return
            end
        end
        UIRequest( {type = 7003, timuType = self.currenntKaoshitype} )
    end,CCControlEventTouchUpInside)
    --考试完成确认
    self.rootItems.datiEndBtn:setSwallowsTouch(true)
    self.rootItems.datiEndBtn:setTouchPriority(self.touchPriority)
    self.rootItems.datiEndBtn:addHandleOfControlEvent(function()

        UIRequest{ type = 7002}
         -- self:shiftNode(1)

    end,CCControlEventTouchUpInside)
    --周排行榜
    self.rootItems.paihangBtn:setSwallowsTouch(true)
    self.rootItems.paihangBtn:setTouchPriority(self.touchPriority)
    self.rootItems.paihangBtn:addHandleOfControlEvent(function()
         gameWindows:openWindow("examinationrank",{ roleid = self.roleid, phtype = 2 })
         UIRequest( {type = 7005, ranktype = 2 } )

    end,CCControlEventTouchUpInside)


    --月排行榜
    self.rootItems.yuepaihangBtn:setSwallowsTouch(true)
    self.rootItems.yuepaihangBtn:setTouchPriority(self.touchPriority)
    self.rootItems.yuepaihangBtn:addHandleOfControlEvent(function()
         gameWindows:openWindow("examinationrank",{ roleid = self.roleid, phtype = 3 })
         UIRequest( {type = 7005, ranktype = 3 } )

    end,CCControlEventTouchUpInside)
       
    --规则说明
    self.rootItems.btnRule:setSwallowsTouch(true)
    self.rootItems.btnRule:setTouchPriority(self.touchPriority)
    self.rootItems.btnRule:addHandleOfControlEvent(function()
         gameWindows:openWindow("examinationRule")
    end,CCControlEventTouchUpInside)


    local ccb,items = CCBReaderLoad("sanjieliankao/zhunkaozhenganniu", nil, true, "zhunkaozhenganniu")
    self.items = items
    self.rootItems.zhunkaozhengccb:addChild(ccb)
    self.animationManager2 = getAnimationManager(items)
    self.animationManager2:setAnimationCompletedCallback(function()
        
    end)

    --准考证按钮
    self.items.zhunkaozhengBtn:setSwallowsTouch(true)
    self.items.zhunkaozhengBtn:setTouchPriority(self.touchPriority)
    self.items.zhunkaozhengBtn:addHandleOfControlEvent(function()
        if self.contentType == 1 then
             self:shiftNode(2)
          return
        end    
         self:shiftNode(1)

    end, CCControlEventTouchUpInside)


    ui.setLabelString(self.rootItems.paihangText, gameConfig.strings:string_common("examination", 20),137)
    ui.setLabelString(self.rootItems.yuepaihangText, gameConfig.strings:string_common("examination", 21),137)

    -- self:shiftNode(2,self.data)

    UIRequest{ type = 7002}
    UIRequest{ type = 204}
    -- self:reload(self.data)

    gameTimer:rigistTime("examination_refresh", 9999999)
    gameTimer:rigistTimeFunc("examination_refresh",function()
        for i,v in ipairs(self.kaoshiType) do
            if self.data[tostring(i)] then
                local status = self.data[tostring(i)].status or 0
                local endtime = self.data[tostring(i)].endtime or 0
                if status == 1 and endtime and gamedata:time() > endtime then
                    self.rootItems[v.."Showsprite"]:setVisible(true)
                    self.rootItems[v.."sprite1"]:setVisible(false)
                    self.rootItems[v.."tiaofu1"]:setVisible(true)
                end
            end
        end  
    end)

end

function examination.requestByType(self,id,timuType,timuid,answerid,times)
    print("requestByType request:"..id)  
    if id == 7003 then
        UIRequest({type = 7003, timuType = timuType })
    elseif id == 7004 then
        UIRequest({type =7004, timuType = timuType, timuid = timuid, answerid = answerid,  timestap =times})
    end    
    self.examination_requestId = id
    self.examination_requestTimuType = timuType
    self.examination_requestTimuid = timuid or ""
    self.examination_requestAnswerid = answerid or ""
    self.examination_requestTimes = times or ""
end

function examination.resetRequest(self)
    self.examination_requestId = 0
    self.examination_requestTimuType = 0
    self.examination_requestTimuid = 0
    self.examination_requestAnswerid = 0
    self.examination_requestTimes = 0
end

function examination.runKaoShiEffect(self,kaoshiType,i)
    self.rootItems["effectNode"]:removeAllChildrenWithCleanup(true)
    for i,v in ipairs(self.kaoshiType) do
        self.rootItems[v.."node"]:setVisible(false)
    end    
    local ccb,items = CCBReaderLoad("UIEffect/liankaojuanzhou/liankaojuanzhou"..kaoshiType, nil, true, "liankaojuanzhou"..kaoshiType)
    self.rootItems["effectNode"]:addChild(ccb)
    local animationManager2 = getAnimationManager(items)
    animationManager2:setAnimationCompletedCallback(function()
        local status = self.data[tostring(i)].status or 0  
        self:shiftNode(3)
        self:reloadStartKaoshi(self.data[tostring(i)])
        if status == 2 then
            self:requestByType(7003,self.currenntKaoshitype)
            -- UIRequest( {type = 7003, timuType = self.currenntKaoshitype} )
       end 
    end)
    animationManager2:runAnimationsForSequenceNamed("play")
    
end
--type 1准考证或成绩单 2考试类型展示 3答题
function examination.shiftNode(self,type,data)
    self.contentType = type
     print("shiftNode type:",type)
    if type == 1 then

        self.rootItems.typeNode:setVisible(false)
        self.rootItems.zhunkaoDetail:setVisible(true)
        self.rootItems.topicNode:setVisible(false)

        self.items.zhunkaozhengNode:setVisible(true)
        self.items.kaoshiTopDetailNode:setVisible(false)
        self.rootItems.timuTitle2:setVisible(false)
        if data then
           self:cjdreload(data)
        else
           self:cjdreload(self.data)
        end    

    elseif type == 2 then 
        self.rootItems.typeNode:setVisible(true)
        self.rootItems.zhunkaoDetail:setVisible(false)
        self.rootItems.topicNode:setVisible(false)

        print("---------")
        self.items.zhunkaozhengNode:setVisible(true)
        self.items.kaoshiTopDetailNode:setVisible(false)
        self.rootItems.timuTitle2:setVisible(false)

        self.rootItems["effectNode"]:removeAllChildrenWithCleanup(true)
        for i,v in ipairs(self.kaoshiType) do
            self.rootItems[v.."node"]:setVisible(true)
        end    

        if data then
            self:reloadStatus(data)
        end    

    elseif type == 3 then
        self.rootItems.typeNode:setVisible(false)
        self.rootItems.zhunkaoDetail:setVisible(false)
        self.rootItems.topicNode:setVisible(true)

        for i,v in ipairs(self.kaoshiType) do
            self.rootItems[v.."node"]:setVisible(false)
        end

        self.animationManager2:runAnimationsForSequenceNamed("play")

        self.items.zhunkaozhengNode:setVisible(false)
        self.items.kaoshiTopDetailNode:setVisible(true)
        self.rootItems.timuTitle2:setVisible(false)
    end    
end


--练习、周试、胖试三种考试状态信息
function examination.reloadStatus(self,data)
    local length = table.getTableLength(data)
    self.isShowcjd = false
    for i,v in ipairs(self.kaoshiType) do
        local status = 0
        local endtime = 0
        if data[tostring(i)] and data[tostring(i)].status then
             status = data[tostring(i)].status
        end

        if data[tostring(i)] and data[tostring(i)].endtime then
             endtime = data[tostring(i)].endtime
        end   

        if status ==0 then
            self.rootItems[v.."Showsprite"]:setVisible(true)
            -- ui.addGray("CCSprite",self.rootItems[v.."Showsprite"])
            -- ui.removeGray("CCSprite",self.rootItems.tabon2)
            self.rootItems[v.."sprite1"]:setVisible(false)
            self.rootItems[v.."tiaofu1"]:setVisible(true)

        elseif status == 1 or status == 2 then
            self.rootItems[v.."Showsprite"]:setVisible(true)
            self.rootItems[v.."sprite1"]:setVisible(false)
            self.rootItems[v.."tiaofu1"]:setVisible(false)
        elseif status == 3 then     
            self.isShowcjd = true
            self.rootItems[v.."Showsprite"]:setVisible(true)
            self.rootItems[v.."sprite1"]:setVisible(true)
            self.rootItems[v.."tiaofu1"]:setVisible(false)

        else 
            --活动后台倒计时
            self.rootItems[v.."sprite1"]:setVisible(false)
            print("后台倒计时!")
            -- runGamePrompt({msg = "后台倒计时!"})
            self:countDownOpen()
        end 

    end    
   
   if self.rootItems.typeNode:isVisible() then
        if self.isShowcjd then
            setSpriteFrameByName(self.items.zhunkaozhengsp, "sanjieliankao_chengjidan")--成绩单按钮图片
        else
            setSpriteFrameByName(self.items.zhunkaozhengsp, "sanjieliankao_zhunkaozheng")--准考证按钮图片
        end 
   end 


end

--成绩单或者准考证信息
function examination.cjdreload(self,data)
    printT(data,"cjdreload")
    print("isShowcjd",self.isShowcjd)
    --角色信息
    self.rootItems.playerID:setString(tostring(self.roleid))
    self.rootItems.playername:setString(self.rolename)
    print("rolegender:"..self.rolegender)
    local str = gameConfig.strings:gender(self.rolegender)
    self.rootItems.playerxingbie:setString(str)   
    local config = ui.IDconfig(self.cid)
    
    setSpriteFrameByName(self.rootItems.selfIcon,config.icon or "alpha")

    ui.setLabelString(self.rootItems.lianxiTitle, "练习",19)
    ui.setLabelString(self.rootItems.zhoushiTitle, "周试",19)
    ui.setLabelString(self.rootItems.pangshiTitle, "月试",19)


    -- ui.setNewIcon(self.rootItems,{cid = self.cid,title = "",iconBox = self.iconBox})
    if self.isShowcjd then
       -- self.rootItems.cjdlianxiNode:setVisible(true)
       -- self.rootItems.cjdzhoushiNode:setVisible(true)
       -- self.rootItems.cjdpangshiNode:setVisible(true)
       -- self.rootItems.cjdlianxiwjx:setVisible(false)
       -- self.rootItems.cjdpangshiwjx:setVisible(false)
       -- self.rootItems.cjdzhoushiwjx:setVisible(false)
       self.rootItems.zhunkaoname:setString(gameConfig.strings:string_common("examination", 18))
       local answer = gamedata.config.sanjie_answer
       for i,v in pairs(data) do
            local _data = data[tostring(i)] 
            printT(_data,"_data")
            if tonumber(_data.status) == 3 then
                local _answer = answer[tostring(i)]
                self.rootItems["cjd"..self.kaoshiType[tonumber(i)].."wjx"]:setVisible(false)
                self.rootItems["cjd"..self.kaoshiType[tonumber(i)].."Node"]:setVisible(true)
                self.rootItems[self.kaoshiType[tonumber(i)].."jifen"]:setString(tostring(_data.jifen))
                self.rootItems[self.kaoshiType[tonumber(i)].."zhengqueshu"]:setString(tostring(_data.rightnum))
                self.rootItems[self.kaoshiType[tonumber(i)].."tizongshu"]:setString("/".._answer.num)
                self.rootItems[self.kaoshiType[tonumber(i)].."yongshi"]:setString(ui.makeTimeText(tonumber(_data.useAlltime),"minute"))
            -- elseif _data.status == 0 or _data.status == 4 then
            --     self.rootItems["cjd"..self.kaoshiType[i].."wjx":setString(gameConfig.strings:string_common("examination", i+1))]
            else
                self.rootItems["cjd"..self.kaoshiType[tonumber(i)].."Node"]:setVisible(false)
                self.rootItems["cjd"..self.kaoshiType[tonumber(i)].."wjx"]:setVisible(true)
                self.rootItems["cjd"..self.kaoshiType[tonumber(i)].."wjx"]:setString(gameConfig.strings:string_common("examination", tonumber(i)+1))
            end    
        end   
    


    else    
       self.rootItems.cjdlianxiNode:setVisible(false)
       self.rootItems.cjdzhoushiNode:setVisible(false)
       self.rootItems.cjdpangshiNode:setVisible(false)
       self.rootItems.cjdlianxiwjx:setVisible(true)
       self.rootItems.cjdpangshiwjx:setVisible(true)
       self.rootItems.cjdzhoushiwjx:setVisible(true)
       self.rootItems.zhunkaoname:setString(gameConfig.strings:string_common("examination", 19))
       self.rootItems.cjdzhoushiwjx:setString(gameConfig.strings:string_common("examination", 3))
       self.rootItems.cjdpangshiwjx:setString(gameConfig.strings:string_common("examination", 4))
       self.rootItems.cjdlianxiwjx:setString(gameConfig.strings:string_common("examination", 2))

    end    
       

end

function examination.checkRequestTimeOut(self)
    print("checkRequestTimeOut ")
    if self.examination_requestId ~=nil and self.examination_requestId == 7003  then
        if self.examination_requestTimuType ~= 0 then
           print("checkRequestTimeOut 7003")
           UIRequest({type = 7003, timuType = self.examination_requestTimuType })
        end    
    elseif self.examination_requestId ~=nil and self.examination_requestId == 7004  then
         if self.examination_requestTimuType ~= 0 then
            UIRequest({type =7004, timuType = self.examination_requestTimuType, timuid = self.examination_requestTimuid, answerid = self.examination_requestAnswerid,  timestap = self.examination_requestTimes})
            print("checkRequestTimeOut 7004")
        end    
    end    
end

function examination.reloadStartKaoshi(self,data)
    local status = 3
    if data then status = data.status end 
    if status == 1 then
        --开始答题确认提示
        self.currenntKaoshitype = data.kstype
        self.rootItems.datiStartNode:setVisible(true)
        self.rootItems.datiContentNode:setVisible(false)
        self.rootItems.datiStartBtnNode:setVisible(true)
        self.rootItems.datiendBtnNode:setVisible(false)
        self.rootItems.datiStartLable:setString(gameConfig.strings:string_common("examination", 16))
        local answer = gamedata.config.sanjie_answer
        local names = answer[tostring(self.currenntKaoshitype)].name
        -- self.rootItems.datiStartTypeLable:setString(names)
        ui.setLabelString(self.rootItems.datiStartTypeLable, names,19)




        self.items.zhengqueshu:setString(gameConfig.strings:string_common("examination", 17))
        self.items.tizongshu:setString("")
        self.items.jfien:setString(gameConfig.strings:string_common("examination", 17))
        self.items.yongshi:setString(gameConfig.strings:string_common("examination", 17))
        self.rootItems.timuTitle2:setVisible(false)


    elseif status ==2  then
        --答题中      

        self.currenntKaoshitype = data.kstype
        self.rootItems.datiStartNode:setVisible(false)
        self.rootItems.datiContentNode:setVisible(true)
        self.rootItems.datiStartBtnNode:setVisible(false)
        self.rootItems.datiendBtnNode:setVisible(false)

        self.items.zhengqueshu:setString(tostring(data.rightnum))
        local answer = gamedata.config.sanjie_answer
        local totalnum = answer[tostring(self.currenntKaoshitype)].num
        
        -- self.items.tizongshu:setString("/"..answer[tostring(self.currenntKaoshitype)].num)
        self.items.tizongshu:setString("/"..data.currentnum)


        self.items.jfien:setString(tostring(data.jifen))
        -- self.rootItems.yongshi:setString(tostring(data.useAlltime))
        self.rootItems.timuTitle2:setVisible(true)
        self.rootItems.timuTitle2:setString(gameConfig.strings:string_common("examination", 14)..data.currentnum.."/"..totalnum..gameConfig.strings:string_common("examination", 15))
        self:totaltime(data.useAlltime)

        --重置所有的答题UI
        for i=1,4 do
            self.rootItems["answer"..i]:setVisible(true)
            self.rootItems["addAtxt"..i]:setString("")
            self.rootItems["xuanzhong"..i]:setVisible(false)
            self.rootItems["zhengque"..i]:setVisible(false)
            self.rootItems["cuowu"..i]:setVisible(false)
        end

        self.rootItems.jingyanjia:setVisible(false)
        self.rootItems.yinbijia:setVisible(false)
        self.isResultShowTime = 0
    elseif status == 3 then
        --开始答题结束答题 展示
        self.rootItems.datiStartNode:setVisible(true)
        self.rootItems.datiContentNode:setVisible(false)
        self.rootItems.datiStartBtnNode:setVisible(false)
        self.rootItems.datiStartLable:setString("恭喜您完成三界联考")
        self.rootItems.datiendBtnNode:setVisible(true)
        self.rootItems.timuTitle2:setVisible(false)

        local answer = gamedata.config:getConfigByName("sanjie_answer")
        local names = answer[tostring(self.currenntKaoshitype)].name
        ui.setLabelString(self.rootItems.datiStartTypeLable, names,19)
    end    
    
end

--开始考试
function examination.startKaoshi(self,t)
    self:resetRequest()
    printT(t,"startKaoshi")
    self.userClickAnswerIndex = 0
    self.isResultShowTime = 0
    self.rootItems.timuTitle2:setVisible(true)

    --首次答题 1变为2
    if self.data[tostring(self.currenntKaoshitype)] and self.data[tostring(self.currenntKaoshitype)].status == 1 then
          self.data[tostring(self.currenntKaoshitype)].status =2  
    elseif self.data[tostring(self.currenntKaoshitype)] and t and t.status and t.status == 3 then   
          self.data[tostring(self.currenntKaoshitype)].status = 3
    end

    if self.data[tostring(self.currenntKaoshitype)] then
          self.data[tostring(self.currenntKaoshitype)].currentTimuid = t.timuid
          self.data[tostring(self.currenntKaoshitype)].useAlltime = t.useAlltime
          self.data[tostring(self.currenntKaoshitype)].rightnum = t.rightnum
          self.data[tostring(self.currenntKaoshitype)].jifen = t.jifen
          self.data[tostring(self.currenntKaoshitype)].currentnum = t.currentnum
    end    

    printT(self.data,"self.data")
    print(self.currenntKaoshitype,"currenntKaoshitype")
    self:reloadStartKaoshi(self.data[tostring(self.currenntKaoshitype)])

    self.timuid = 0
    self.timuid = t.timuid
    local endtimes = t.endtimes or 0
    local coinnum =t.coinnum or 0
    local expnum = t.expnum or 0
    local status = t.status
    if status == 3 then
        return
    end    

 -- local data = {
 --      { kstype =1, status = 1,currentnum = 0, rightnum = 0, currentTimuid = 0, useAlltime = 0,jifen = 0},
 --      { kstype =2,status = 2, currentnum = 5, rightnum = 2, currentTimuid = 3, useAlltime = 0,jifen = 0},
 --      { kstype =3,status = 3, currentnum = 5, rightnum = 1, currentTimuid = 5, useAlltime = 0,jifen = 0},
 --    }
    --
    self:countdowntime(endtimes)

    self.rootItems.jingyan:setString(tostring(expnum))
    self.rootItems.yinbi:setString(tostring(coinnum))
  

    local timu_config = gamedata.config.sanjie_subject_config --题目id+答案id
    local timu_neirong = gamedata.config.sanjie_subject_text --题目内容+答案内容

    local timu_c  = timu_config[tostring(self.timuid)]
    local timuID = timu_c.subject
    local timutext = timu_neirong[tostring(timuID)].text or ""
    self.rootItems.timu:setString(timutext);
    
    local answerID = {}
    for i=1,4 do
        if timu_c and timu_c["answer"..i] then
           table.insert(answerID,timu_c["answer"..i])
        end
    end

    self.rightAnswerIndex = 0 
    printT(answerID,"answerID-------")
    self.result = self:shuffle(answerID)
    printT(self.result,"result-------")
    
    local resultLength = table.getTableLength(self.result)
    for i,v in ipairs(self.result) do
        if v == timu_c["answer1"] then
            self.rightAnswerIndex = i
        end    
        self.rootItems["answer"..i]:setVisible(true)
        self.rootItems["addAtxt"..i]:setString(timu_neirong[tostring(v)].text)
        self.rootItems["answerBtn"..i]:setSwallowsTouch(trues)
        self.rootItems["answerBtn"..i]:setTouchPriority(self.touchPriority)
        self.rootItems["answerBtn"..i]:addHandleOfControlEvent(function()
            -- if self.isResultShowTime == 1 then
            --     runGamePrompt({msg = "答案展示中"})
            --     return
            -- end    
            -- self.isResultShowTime = 1
            -- self.userClickAnswerIndex = i
            -- self:answerXuanZhe(i)
            -- UIRequest({type =7004, timuType = self.currenntKaoshitype, timuid = timuid, answerid = tostring(v)})
            self:selectAnswer(i,self.timuid,tostring(v))
        end,CCControlEventTouchUpInside)
    end

    --少于4个答案的，隐藏答案按钮
    if resultLength< 4 then
        for i=resultLength,4 do
            self.rootItems["answer"..i]:setVisible(false)
        end
    end    

end

--选择答案
function examination.selectAnswer(self,_index,timuid,answerid)
    if self.isResultShowTime == 1 then
        -- runGamePrompt({msg = "答案展示中"})
        return
    end    
    self.isResultShowTime = 1
    self.userClickAnswerIndex = _index
    self:answerXuanZhe(_index)
    self:requestByType(7004,self.currenntKaoshitype,timuid,answerid,gamedata:time())
    -- UIRequest({type =7004, timuType = self.currenntKaoshitype, timuid = timuid, answerid = answerid, timestap = gamedata:time()})
end


function examination.endKaoshi(self,t)
    self:resetRequest()
    printT(t,"endKaoshi")
    gameTimer:UnrigistTimeFunc("examination_countdown_flesh")

    local result = t.result or 0 --0答对、1答错
    local alltimes = t.useAlltime
    local jifen = t.jifen
    local rightnum = t.rightnum
    local coinnum =t.coinnum or 0
    local expnum = t.expnum or 0
    local currentnum = t.currentnum or 0

    if self.data[tostring(self.currenntKaoshitype)] then self.data[tostring(self.currenntKaoshitype)].useAlltime = alltimes end
    if self.data[tostring(self.currenntKaoshitype)] then self.data[tostring(self.currenntKaoshitype)].currentnum = currentnum end
    if self.data[tostring(self.currenntKaoshitype)] then self.data[tostring(self.currenntKaoshitype)].rightnum = rightnum end
    if self.data[tostring(self.currenntKaoshitype)] then self.data[tostring(self.currenntKaoshitype)].jifen = jifen end


    self.isLastTimu = false
    local reward
    local answer = gamedata.config.sanjie_answer
    local show_time = answer[tostring(self.currenntKaoshitype)].show_time or 2
    local delayed_1 = answer[tostring(self.currenntKaoshitype)].delayed_1 or 0.5
    local delayed_2 = answer[tostring(self.currenntKaoshitype)].delayed_2 or 0.5
    local delayed_r = tonumber(show_time) - tonumber(delayed_1)
    local delayed_w = tonumber(show_time) - tonumber(delayed_1)- tonumber(delayed_2)
    print("delayed_r",delayed_r,"delayed_w",delayed_w)
    local totaltimu = answer[tostring(self.currenntKaoshitype)].num or 0
    if tonumber(currentnum) == tonumber(totaltimu) then--当前是最后一题
       self.isLastTimu =  true
    end    
    if self.isLastTimu then
       gameTimer:UnrigistTimeFunc("examination_total_flesh")
       self.items.yongshi:setString(ui.makeTimeText(alltimes,"minute"))
    end  
    print("self.isLastTimu",self.isLastTimu,"totaltimu",totaltimu)

    if result == 1 then
          self.items.zhengqueshu:setString(tostring(rightnum))
          self.items.jfien:setString(tostring(jifen))
    
          reward =  self:getRewardByLevel(self.currenntKaoshitype,"answer_reward") 
          -- answer_reward[tostring(self.currenntKaoshitype)].answer_reward

         
          --正确答案展示延时
          local sequence4 = CCSequence:createWithTwoActions(CCDelayTime:create(show_time), CCCallFunc:create(function() 
                -- self.isResultShowTime = 0
                if not self.isLastTimu then
                    -- UIRequest( {type = 7003, timuType = self.currenntKaoshitype} )
                    self:requestByType(7003,self.currenntKaoshitype)

                else    
                    self:reloadStartKaoshi()
                    self.isResultShowTime = 0
                end    
                -- runGamePrompt({msg = "答案展示时间结束！"})
          end))

          local sequence3 = CCSequence:createWithTwoActions(CCDelayTime:create(delayed_1), CCCallFunc:create(function() 
                self.rootItems["zhengque"..self.userClickAnswerIndex]:setVisible(true)
                self:showReward(reward,coinnum,expnum)
          end))
          self.rootItems["zhengque"..self.userClickAnswerIndex]:runAction(sequence3)  
          self.rootItems["zhengque"..self.userClickAnswerIndex]:runAction(sequence4)  

    else
          -- reward = answer[tostring(self.currenntKaoshitype)].wrong_reward
          reward =  self:getRewardByLevel(self.currenntKaoshitype,"wrong_reward") 
          --错误答案展示 延时          
          local sequence3 = CCSequence:createWithTwoActions(CCDelayTime:create(delayed_1), CCCallFunc:create(function() 
                self.rootItems["cuowu"..self.userClickAnswerIndex]:setVisible(true)
                self:showReward(reward,coinnum,expnum)
          end))
          self.rootItems["cuowu"..self.userClickAnswerIndex]:runAction(sequence3)  

          --正确答案展示 延时     
          local sequence4 = CCSequence:createWithTwoActions(CCDelayTime:create(delayed_1+delayed_2), CCCallFunc:create(function() 
          self.rootItems["zhengque"..self.rightAnswerIndex]:setVisible(true)
          end))
          self.rootItems["zhengque"..self.rightAnswerIndex]:runAction(sequence4)  

           --正确答案展示延时
          local sequence5 = CCSequence:createWithTwoActions(CCDelayTime:create(show_time), CCCallFunc:create(function() 
                -- self.isResultShowTime = 0
                if not self.isLastTimu then
                    -- UIRequest( {type = 7003, timuType = self.currenntKaoshitype} )
                        self:requestByType(7003,self.currenntKaoshitype)

                else 
                    self:reloadStartKaoshi()
                    self.isResultShowTime = 0
                end    
                -- runGamePrompt({msg = "答案展示时间结束！"})
          end))
          self.rootItems["cuowu"..self.userClickAnswerIndex]:runAction(sequence5)  

    end    

      
    --更正时长
    self.times = alltimes
end

function examination.getRewardByLevel(self,kaoshiType,isright)
  
    print("getRewardByLevel kaoshiType:"..kaoshiType)
    local answer_reward = gamedata.config.sanjie_answer_reward
    local answer_reward_fw = answer_reward[tostring(kaoshiType)]
    -- printT(answer_reward_fw,"answer_reward_fw")
    for i,v in pairs(answer_reward_fw) do
        -- print("getRewardByLevel level:"..v.level.." type:"..v.type)
        if answer_reward_fw[tostring(i+1)] then
             local maxlevel  = answer_reward_fw[tostring(i+1)].level or 0
                print("getRewardByLevel level:"..v.level.." maxlevel:"..maxlevel)
             if self.rolelv >= tonumber(v.level) and self.rolelv < tonumber(maxlevel) then
                return v[isright]
             end   
        else
            if self.rolelv >= tonumber(v.level) then
                return v[isright]
            end   
        end  
    end

    return "1000,1;1017,1;";
end


function examination.showReward(self,reward,coinnum,expnum)
    local xprops = {}
    local xprop = gamedata.getIDandNUMs(reward)
    printT(xprop,"xprop")
    for k,v in pairs(xprop) do
        if v.cid == 1000 then --银币
            self.rootItems.yinbi:setString(tostring(coinnum))
            self.rootItems.yinbijia:setVisible(true)
            self.rootItems.yinbijia:setString(tostring("+"..v.num))
        else--exp
            self.rootItems.jingyan:setString(tostring(expnum))
            self.rootItems.jingyanjia:setVisible(true)
            self.rootItems.jingyanjia:setString(tostring("+"..v.num))
        end   
    end  
end
--答案选择
function examination.answerXuanZhe(self,_index)
    for i=1,4 do
        if i ==_index then
            self.rootItems["xuanzhong"..i]:setVisible(true)
        else    
            self.rootItems["xuanzhong"..i]:setVisible(false)
        end   
    end
end

--答案顺序混淆
function examination.shuffle(self,_table)
    -- 判断如果不为table则直接返回 
    if type(_table)~="table" then
       return
    end
    local _result = {}
    local _index = 1
    while #_table ~= 0 do
        local ran = math.random(0,#_table)
        if _table[ran] ~= nil then
            _result[_index] = _table[ran]
            table.remove(_table,ran)
            _index = _index + 1
        end
    end
    return _result
end


function examination.reload(self,data)   
    printT(data,"reload")

    if data then 
        self.data =  data.data
        self.roleid = data.roleid
        self.rolename = data.rolename
        self.cid = data.cid
        self.iconBox = data.iconBox
        self.rolelv = data.rolelv
    end
    self:shiftNode(2,self.data)

end

--总计时间
function examination.totaltime(self,beforetimes)
    -- 总计时 （时长累加/从0开始/）
    -- 倒记时 （时间戳 倒计时）
    self.times = 0
    self.times = beforetimes
    gameTimer:rigistTime("examination_total_flesh", 2*24*3600)
    gameTimer:rigistTimeFunc("examination_total_flesh",function()
        self.times = self.times + 1
        self.items.yongshi:setString(ui.makeTimeText(self.times,"minute"))
    end)

end

--活动开启倒计时刷新
function examination.countDownOpen(self)
    printT(self.data,"self.countDownOpen")
    self.sanjieliankaoIsout =  false
    if next(self.data) == nil  then
        return
    end     
    local opentype = 0
    for i,v in pairs(self.data) do
       if v.kstype == 2 and v.status ==4 then
           opentype = 1
       elseif v.kstype == 3 and v.status ==4 then
           opentype = 2
       end 
    end
    print(opentype,"countDownOpen opentype")
    if opentype == 0 then return end

    local times = self:gettimes(opentype)
    printT(times,"countDownOpen times")
    local _remainTime = 0
    if not times then
       return
    elseif times.prompt <= times.now and times.now < times.open then
        print("countDownOpen 2")
        self.sanjieliankaoIsout = true
        _remainTime = times.open - times.now
        
        gameTimer:rigistTime("examination_reading", _remainTime)
        gameTimer:rigistTimeFunc("examination_reading", function()
            if gameTimer.times["examination_reading"] >= 0 then
                --待开启
            end
            if gameTimer.times["examination_reading"] == 0 then
                print("examination_reading====0000")
                 -- runGamePrompt({msg = "后台倒计时结束!"})
                gameTimer:UnrigistTimeFunc("examination_reading")
                UIRequest({type = 7002})
            end
        end)
    else

    end

end


--倒计时 传入时间戳
function examination.countdowntime(self,totimes)
    self.totimes = 0
    self.totimes = totimes
    self.countdowntimes = 0
    print("totimes",totimes)
    gameTimer:UnrigistTimeFunc("examination_countdown_flesh")
    gameTimer:rigistTime("examination_countdown_flesh", 2*24*3600)
    gameTimer:rigistTimeFunc("examination_countdown_flesh",function()
       
        local nowtime = gamedata:time()
        self.countdowntimes  =totimes - nowtime

        if tonumber(self.countdowntimes) > 40 then
             self.countdowntimes = 30
        elseif  tonumber(self.countdowntimes) < 0 then 
             self.countdowntimes = 30
        end    
        if tonumber(self.countdowntimes) > 5 then
            self.rootItems.daojishiTime:setColor(ccc3(155,112,50))
        else
            self.rootItems.daojishiTime:setColor(ccc3(255,8,8))
        end    
        self.rootItems.daojishiTime:setString(ui.makeTimeText(tonumber(self.countdowntimes),"minute"))

        print("nowtime",nowtime,"totimes",self.totimes," countdowntimes",self.countdowntimes)
        if  self.countdowntimes<= 0 then
            self.countdowntimes = 0
            gameTimer:UnrigistTimeFunc("examination_countdown_flesh")
            -- runGamePrompt({msg = "答题时间到！默认选择一个错误答案"})
            if self.userClickAnswerIndex == 0 then
                 --选择一个错误答案
                for i,v in ipairs(self.result) do
                    if i ~= self.rightAnswerIndex then
                        print("选择的答案是：",i)
                        self:selectAnswer(i,self.timuid,tostring(v))
                        break;
                    end    
                end
            end
        end     
    end)
end


function examination.gettimes( self,opentype)
    local _nowTime = self:getNowTime()
    local _dayNums = self:getDayNum(_nowTime)
    
    local _config 
    if opentype == 1 then
        _config= gamedata.config.sanjie_answer["2"]
    else    
        _config= gamedata.config.sanjie_answer["3"]
    end    

    local nowSec = _nowTime.hour*3600 + _nowTime.min*60 + _nowTime.sec

    if _config then
        if _config.entrance_time and _config.time_close and _config.time_open then
            local _hour1, _min1, _sec1 = ui.getGangBattleTime(_config.entrance_time)
            local _hour2, _min2, _sec2 = ui.getGangBattleTime(_config.time_close)
            local beginSec = _hour1*3600 + _min1*60 + _sec1
            local endSec = _hour2*3600 + _min2*60 + _sec2

            if nowSec >= beginSec and nowSec <= endSec then
                local _hour3, _min3, _sec3 = ui.getGangBattleTime(_config.time_open)
                local _hour4, _min4, _sec4 = ui.getGangBattleTime(_config.time_close)
                return {
                    prompt = beginSec,
                    open   = _hour3*3600 + _min3*60 + _sec3,
                    over   = _hour4*3600 + _min4*60 + _sec4,
                    finaly = endSec,
                    now    = nowSec,
                }
            end
        end
    end
    return nil   
end

function examination.getNowTime(self)
    return os.date("*t", gamedata:time())
end

function examination.getDayNum(self, nowTime)
    return nowTime.wday == 1 and 7 or (nowTime.wday - 1)
end

function examination.setGender(self,data)
    self.rolegender = data and data.gender or 1
    print("setGender:"..self.rolegender)
end

function examination.clear(self)
    -- body
    print("examination clear")
    gameTimer:UnrigistTimeFunc("examination_total_flesh")
    gameTimer:UnrigistTimeFunc("examination_countdown_flesh")
    gameTimer:UnrigistTimeFunc("examination_reading")
    gameTimer:UnrigistTimeFunc("examination_refresh")
    
    self:resetRequest()

    self.rootItems["effectNode"]:removeAllChildrenWithCleanup(true)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.isShowcjd = false
    self.data =  {}
    self.countdowntimes =0
    self.userClickAnswerIndex = 0
    self.isResultShowTime = 0
    self.rightAnswerIndex = 1
    self.times = 0
end

    

return examination