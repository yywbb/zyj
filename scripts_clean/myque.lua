--[[
-- Lua queue
-- TODO remove the queue
 ]]

myque = myque or {}

function myque.new()
    log("您创建了一个队列")
    return { first = 0, last = -1 }
end

function myque.push(Q, value)
    log("您往队列插入数据")
    local last = Q.last + 1
    Q.last = last
    Q[last] = value
    log("插入成功")
end

function myque.empty(Q)
    if Q.first > Q.last then
        return true;
    else
        return false;
    end
end

function myque.front(Q)
    if myque.empty(Q) then
        return nil;
    end
    local first = Q.first
    return Q[first]
end

function myque.pop(Q)
    if myque.empty(Q) then
        return nil;
    end
    local first = Q.first
    local value = Q[first]
    Q[first] = nil
    Q.first = Q.first + 1

    return  value
end