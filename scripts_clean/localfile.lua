--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 13-4-28
-- Time: 下午6:22
-- To change this template use File | Settings | File Templates.
--



function getDirOfPath(path)
    ---log("prepare to parse dir from "..path)
    local pathlen = string.len(path)
    path = string.gsub(path,"\\","/");

    local idx1,idx2 = string.find(path,"compress")
    if not idx1 then return nil end

    local last = pathlen+1
    for i=idx2,pathlen do 
        if string.sub(path,i,i) == "/" then
            myfile.mkdir(string.sub(path,1,i-1));
            last=i
        end
    end

    return string.sub(path,1,last-1)
end



function WriteFile(filepath,content)
    local filehandle = io.open(filepath,"wb")
    if nil ~= filehandle then
        cclog("%s write success", filepath);
        filehandle:write(content)
        filehandle:close()
    else
        cclog("%s write fail", filepath);
    end
end


