--
-- Texture manager , add or remove plist texture
-- User: liliang
-- Date: 13-5-21
-- Time: 上午11:22
--

local texture = {}

texture.bLoadPublic = false

--0:special 1:hot 2:nohot
texture.res = {
    GAME_PUBLIC = {
        name = "public",
        res = {
--            "public/general_s",
--            "public/equips_s",
--            "public/skill_s",
--            "public/props_s",
            "public/publicobject1",
            "public/publicobject_buya",
--            "public/publicsprite1",
--            "public/publicsprite2",
        }
    },

}

--初始化资源加载状态
--for i, j in pairs(texture.res) do
--    print(" i = ", i, type(i))
--    if (memoryWarning.status[i] == nil) then
--        memoryWarning.status[i] = false
--    end
--end
---printT(memoryWarning.status)


--[[
-- Add a table contains plist files.
--添加一组图片
 - @param pathTable table object-
 ]]
function texture.addSpriteFramesWithTable(pathTable)
    if pathTable ~= nil and next(pathTable) ~= nil then
        for i, j in ipairs(pathTable.res) do
            CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(j .. ".plist")
            if LoginScene.status then
                LoginScene:showDownloadProcess({type = "loadresource",total = #pathTable.res})
            end
        end
    end
end

--根据状态添加一组资源
function texture.addSpriteFramesByStatus(pathTable)
   -- print("memoryWarning.status[" .. pathTable .. "] = ", memoryWarning.status[pathTable])
    if texture.res[pathTable] ~= nil and next(texture.res[pathTable]) ~= nil then --and memoryWarning.status[pathTable] == false then
        for i, j in pairs(texture.res[pathTable].res) do
            CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(j .. ".plist")
        end
        --memoryWarning.status[pathTable] = true
    end
end

--添加单个图片
function texture.addOneSpriteFrameWithName(name)
    CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(name .. ".plist")
end

--移除纹理
function texture.removeSpriteFramesWithFile(file)
    --移除单个纹理
    --CCTextureCache:sharedTextureCache():removeTextureForKey(file .. ".plist")
    CCTextureCache:sharedTextureCache():removeTextureForKey(file .. ".pvr.ccz")
    CCTextureCache:sharedTextureCache():removeTextureForKey(file .. ".png")
    --移除单个精灵帧
    CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile(file .. ".plist")
end

--移除一组资源
function texture.removeSpriteFramesWithTable(pathTable)
    for i, j in pairs(pathTable) do
        for k, v in pairs(texture.res[j].res) do
            print("removeSpriteFramesWithTable v=", v)
            --移除单个纹理
            --CCTextureCache:sharedTextureCache():removeTextureForKey(v .. ".plist")
            CCTextureCache:sharedTextureCache():removeTextureForKey(v .. ".pvr.ccz")
            CCTextureCache:sharedTextureCache():removeTextureForKey(v .. ".png")
            --移除单个精灵帧
            CCSpriteFrameCache:sharedSpriteFrameCache():removeSpriteFramesFromFile(v .. ".plist")
        end
       -- removeUnusedLayer(j)
        --memoryWarning.status[j] = false
    end
end

--初始化公共资源
function texture.LoadPublic(self)
    cclog("texture:LoadPublic")
    texture.addSpriteFramesWithTable(self.res.GAME_PUBLIC)


    for k,v in ipairs(self.res.GAME_PUBLIC.res) do
        CCSpriteFrameCache:sharedSpriteFrameCache():retainSpriteFramesWithFile(v .. ".plist")
    end

--    for k,v in ipairs(self.res.GAME_PUBLIC.res) do
--        local textureTmp =  CCTextureCache:sharedTextureCache():textureForKey(v .. ".pvr.ccz")
--        if textureTmp then
--            textureTmp:retain()
--        end
--    end

--    print("-------------------------------texture:LoadPublic--------------")
--    CCTextureCache:sharedTextureCache():dumpCachedTextureInfo()
--    print("-------------------------------texture:LoadPublic--------------")
end

function texture.removeTexturebyState(gState)
    if texture.res[gState] ~= nil and next(texture.res[gState]) ~= nil  then
        for i, j in pairs(texture.res[gState].res) do
            CCTextureCache:sharedTextureCache():removeTextureForKey(j .. ".pvr.ccz")
            print(gState,j,"removeTexturebyState")
        end
    end
end

--接收内存警告
function receiveMemoreWarning()
    cclog("lua receiveMemoreWarning")
--    CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
--    CCTextureCache:sharedTextureCache():removeAllTextures()
    --清理缓存
    --memoryWarning.purgeCacheData(2)
end
--texture:LoadPublic()
return texture
