

local chat_manager = {
   
}


function chat_manager.cheackIsEmoji(self,destContent,destLen)
    if destLen > 3 then
        return 0
    else
        local fuhao = "#"
        local k = string.find(destContent, fuhao, 0)
        if k == nil or k ~= 1 then
            return 0
        else
            local fid = string.sub(destContent,k+1,destLen)
            local tmpNum = tonumber(fid)
            if tmpNum and tmpNum < 24 and tmpNum > 0 then
                return tmpNum
            else
                return 0
            end
        end
    end
end

function chat_manager.cheackIsShare(self,destContent,destLen)
    local str = destContent
    local sharecid = nil
    local fuhao = "&"
    local k = string.find(destContent, fuhao, 0)
    if k == nil then
        return str,sharecid
    else
        local fid = string.sub(destContent,k+1,destLen)
        sharecid = tonumber(fid)
        str = string.sub(destContent,0,k-1)
        return str,sharecid
    end
end

function chat_manager.cheackSystemType(self,destContent,destLen)
    local str = destContent
    local sharecid = nil
    local fuhao = "&"
    local k = string.find(destContent, fuhao, 0)
    if k == nil then
        return str,sharecid
    else
        local fid = string.sub(destContent,k+1,destLen)
        sharecid = tonumber(fid)
        str = string.sub(destContent,0,k-1)
        return str,sharecid
    end
end

function chat_manager.cheackIsBossfield(self,destContent,destLen)
    local str = destContent
    local bossid = nil
    local fuhao = "&&"
    local k = string.find(destContent, fuhao, 0)
    if k == nil then
        return str,bossid
    else
        local fid = string.sub(destContent,k+2,destLen)
        bossid = tonumber(fid)
        str = string.sub(destContent,0,k-1)
        return str,bossid
    end
end

function chat_manager.cheackIsGuildfeast(self,destContent,destLen)
    local str = destContent
    local feast = nil
    local fuhao = "&&&"
    local k = string.find(destContent, fuhao, 0)
    if k == nil then
        return str,feast
    else
        local fid = string.sub(destContent,k+3,destLen)
        feast = tonumber(fid)
        str = string.sub(destContent,0,k-1)
        return str,feast
    end
end

function chat_manager.cheackIsGuildboss(self,destContent,destLen)
    local str = destContent
    local guildboss = nil
    local fuhao = "&&&&"
    local k = string.find(destContent, fuhao, 0)
    if k == nil then
        return str,guildboss
    else
        local fid = string.sub(destContent,k+4,destLen)
        guildboss = tonumber(fid)
        str = string.sub(destContent,0,k-1)
        return str,guildboss
    end
end

function chat_manager.cheackIsGuildbath(self,destContent,destLen)
    local str = destContent
    local guildbath= nil
    local fuhao = "&&&&&"
    local k = string.find(destContent, fuhao, 0)
    if k == nil then
        return str,guildbath
    else
        local fid = string.sub(destContent,k+5,destLen)
        guildbath = tonumber(fid)
        str = string.sub(destContent,0,k-1)
        return str,guildbath
    end
end

function chat_manager.getSizeTable(self,chats)
    local label = ui.createLabel({
        fontsize = 46,
        font = "Helvetica-Bold",
    })

    local sizeTable = {}
    local totalheight = 0

    for i=1, table.getTableLength(chats) do
        label:setString(chats[tostring(i)].content)
        local height = label:getContentSize().height
        local width = label:getContentSize().width

        if width > 700 then
            sizeTable[tostring(i)] = {w = 730, h = math.ceil(width/700)*height+20}
        else
            local tmpContent = chats[tostring(i)].content
            local tmpLen = string.len(tmpContent)
            if self:cheackIsEmoji(tmpContent,tmpLen) ~= 0 then
                sizeTable[tostring(i)] = {w = width+10, h = 200}
            else
                sizeTable[tostring(i)] = {w = width+10, h = height+20}
            end
        end
        totalheight = totalheight + sizeTable[tostring(i)].h +120
    end

    return sizeTable,totalheight
end

function chat_manager.getSystemSizeTable(self,chats)
    local label = ui.createLabel({
        fontsize = 34,
        font = "Helvetica-Bold",
    })

    local sizeTable = {}
    local totalheight = 0

    for i=1, table.getTableLength(chats) do
        label:setString(chats[tostring(i)].content)
        local height = label:getContentSize().height
        local width = label:getContentSize().width

        if width > 760 then
            sizeTable[tostring(i)] = {w = 760, h = math.ceil(width/760)*height+20}
        else
            local tmpContent = chats[tostring(i)].content
            local tmpLen = string.len(tmpContent)
            sizeTable[tostring(i)] = {w = width+10, h = height+20}
        end
        totalheight = totalheight + sizeTable[tostring(i)].h +120
    end

    return sizeTable,totalheight
end

return chat_manager