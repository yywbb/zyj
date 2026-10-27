--
-- Author: songyibo
-- Date: 2018-08-03 11:55:09
--
local TestEditBox = class("TestEditBox", function ()
    return cc.Layer:create()
end)


function TestEditBox:ctor()
    self.rootNode,self.rootItems = CCBReaderLoad("ccb/test", nil, true, "test")
    self:addChild(self.rootNode)


    local beginfunc = function(label)
        label:setString("")
    end

    local endfunc = function(label,text,box)
        label:setString(text)
        box:setText("")
    end

    -- local l = tolua.cast(self.rootItems.helloLabel, "cc.LabelTTF")
    -- l:setFontSize(150)

    self.accountInputBox = ui.creatInputEditBoxBylable(self.rootItems.helloLabel,kEditBoxInputModeSingleLine,beginfunc,endfunc,
        {
            fontSize = 40,
            fontColor = ccc3(255, 255, 255),
            nochecksensitive = false
        })
    self.accountInputBox:setTouchPriority(-10)
    
end


function EditBoxTestMain()
    print("EditBoxTestMain")
    local scene = cc.Scene:create()
    scene:addChild(TestEditBox.new())
    scene:addChild(CreateBackMenuItem())
    return scene
end