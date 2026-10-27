--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/27
-- Time: 下午4:11
-- To change this template use File | Settings | File Templates.
--

local first = {
    rootNode = nil,
    rootItems = nil,
    selectconfig = {
        [1] = {pos = ccp(284,276),id= 10101 },
        [2] = {pos = ccp(284,56),id= 10106 },
        [3] = {pos = ccp(284,-187),id= 10111},
    },

    select = 3,
    name = "",


}

function first.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("story/xuanren", nil, true, "xuanren")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function first.setFirstName(self,name_)
    self.name = name_
    self.rootItems.namelabel:setString(name_)
end

function first.reload(self,data,callback)
    self.callback = callback

    self.rootItems.confirm:addHandleOfControlEvent(function()
        if self.select == 0 then
            -- runGamePrompt({msg = "请选择形象"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","chosName")})
        elseif self.name == "" then
            -- runGamePrompt({msg = "请输入昵称"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","enterName")})
        else
            guide.first.name = self.name
            guide.first.profile = self.select
            guide.first.selectedgeneral = self.selectconfig[self.select].id

            UIRequest({type = 101,name =self.name} )
            if callback then callback() end
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.confirm:setSwallowsTouch(true)
    self.rootItems.confirm:setTouchPriority(self.touchPriority)


    self.rootItems.selectsprite:setPosition(self.selectconfig[self.select].pos)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.selectconfig[self.select].id)].animationid)].name
    local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    general:setAnimation("stand",true,0)
    general:setScale(1)
    self.rootItems.profile:addChild(general)

    for i=1, 3 do
        self.rootItems["select"..i]:addHandleOfControlEvent(function()
            if self.select == i then return end
            self.select = i

            self.rootItems.selectsprite:setPosition(self.selectconfig[self.select].pos)
            self.rootItems.profile:removeAllChildrenWithCleanup(true)
            local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.selectconfig[self.select].id)].animationid)].name
            general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            general:setAnimation("stand",true,0)
            general:setScale(1)
            self.rootItems.profile:addChild(general)

        end, CCControlEventTouchUpInside)
        self.rootItems["select"..i]:setSwallowsTouch(true)
        self.rootItems["select"..i]:setTouchPriority(self.touchPriority)
    end

    local beginfunc = function(label)
        self:setFirstName("")
    end

    local endfunc = function(label,text,box)
        self:setFirstName(text)
        box:setText("")
    end

    self.rootItems.nameInputBox = ui.creatInputEditBoxBylable(self.rootItems.namelabel,kEditBoxInputModeSingleLine,beginfunc,endfunc,
        {
            fontSize = 50,
            fontColor = ccc3(93,56,42),
            length = 12
        })
    self.rootItems.nameInputBox:setTouchPriority(self.touchPriority)

    self.rootItems.randomnameButton:addHandleOfControlEvent(function()
        UIRequest({type = 100,sex=self.select})
    end, CCControlEventTouchUpInside)
    self.rootItems.randomnameButton:setSwallowsTouch(true)
    self.rootItems.randomnameButton:setTouchPriority(self.touchPriority)

end


function first.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.select = 1
    self.name = ""

    if self.callback then
        self.callback()
    end
end

return first