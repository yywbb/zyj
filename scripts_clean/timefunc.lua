
local MON1 = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};   --平年  
local MON2 = {31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};   --闰年  
local FOURYEARS = (366 + 365 +365 +365); --每个四年的总天数  
local DAYMS = 24*3600;   --每天的毫秒数  

  
function GetSeverDate(param,time)  
	local shiqu = gamedata.zone or 0 --得到时区

    if param ~= "*t" 
        and param ~= "%Y%m%d%H%M%S"
        and param ~= "(%Y-%m-%d %H:%M)" then
        return os.date_(param,time)
    end
    
	local nTime = time + shiqu*3600;--得到当前系统时间 
    local nDays = math.floor(nTime/DAYMS) + 1;    --time函数获取的是从1970年以来的毫秒数，因此需要先得到天数  
    local nSecond = math.mod(nTime,DAYMS) --得到不足一天的秒数
    local nYear4 = math.floor(nDays/FOURYEARS);   --得到从1970年以来的周期（4年）的次数  
    local nRemain = math.mod(nDays,FOURYEARS);  --得到不足一个周期的天数  
    local nDesYear = 1970 + nYear4*4;  
    local nDesMonth, nDesDay, nDesHour, nDesMin, nDesSec = 0,0,0,0,0;  
    local nDesWday = math.mod(nDays-3,7)
    if nDesWday == 0 then nDesWday = 7 end
    local bLeapYear = false;  
    if nRemain<365 then--一个周期内，第一年  
    	--平年             
    elseif nRemain<(365+365) then--一个周期内，第二年  
        --平年  
        nDesYear = nDesYear + 1;  
        nRemain = nRemain - 365;   
    elseif nRemain<(365+365+366) then --一个周期内，第三年       --润年
    	--平年 
        bLeapYear = true;  
        nDesYear = nDesYear + 2;  
        nRemain = nRemain - (365+365);   
    else--一个周期内，第四年 
        
        nDesYear = nDesYear + 3;  
        nRemain = nRemain - (365+365+366);   
    end

    local nDesyday = nRemain

    local pMonths = bLeapYear and MON2 or MON1;  
    --循环减去12个月中每个月的天数，直到剩余天数小于等于0，就找到了对应的月份  
    for i=1,12 do  
 
        local nTemp = nRemain - pMonths[i];  
        if nTemp<=0 then   
            nDesMonth = i;  
            if nTemp == 0 then --表示刚好是这个月的最后一天，那么天数就是这个月的总天数了  
                nDesDay = pMonths[i];  
            else  
                nDesDay = nRemain;  
            end
            break;   
        end
        nRemain = nTemp;  
    end 

    nDesHour = math.floor(nSecond/3600)
    nDesMin = math.floor( math.mod(nSecond,3600) /60)
    nDesSec = math.mod(nSecond,60)

    local t = {
        year = nDesYear,
        month = nDesMonth,
        day = nDesDay,
        hour = nDesHour,
        min = nDesMin,
        sec = nDesSec,
        wday = nDesWday,
        yday = nDesyday
    }

    if param == "%Y%m%d%H%M%S" then
        local month = t.month<10 and "0"..t.month  or t.month
        local day = t.day<10 and "0"..t.day  or t.day
        local hour = t.hour<10 and "0"..t.hour  or t.hour
        local min = t.min<10 and "0"..t.min  or t.min
        local sec = t.sec<10 and "0"..t.sec  or t.sec

        return t.year..month..day..hour..min..sec

    end

    if param == "(%Y-%m-%d %H:%M)" then
        local month = t.month<10 and "0"..t.month  or t.month
        local day = t.day<10 and "0"..t.day  or t.day
        local hour = t.hour<10 and "0"..t.hour  or t.hour
        local min = t.min<10 and "0"..t.min  or t.min
        local sec = t.sec<10 and "0"..t.sec  or t.sec

        return "("..t.year.."-"..month.."-"..day.." "..hour..":"..min..")"
    end


    return t
end

local sysOSdate = os.date
os.date_ = sysOSdate

os.date = GetSeverDate

function GetServerTime(dateT)
    if not dateT then 
        return os.time_()
    end

    printT(dateT)
    
    local year = tonumber(dateT.year or 0)
    local month = tonumber(dateT.month or 0)
    local day = tonumber(dateT.day or 0)
    local hour = tonumber(dateT.hour or 0)
    local min = tonumber(dateT.min or 0)
    local sec = tonumber(dateT.sec or 0)
    local isdst = not not dateT.sec 

    local days = 0
    days = days + math.floor((year-1970)/4)*FOURYEARS  --整周期的天数
    
    local restyear = math.mod(year-1970,4) --非整周期年数
    local bLeapYear = false 

    --非整周期整年的天数
    if restyear ==0 then
        --不足一年
    elseif restyear ==1 then
        days = days + 365   --大于1年
    elseif restyear ==2 then
        days = days + 365+365
        bLeapYear = true    --大于2年 本年（第三年）是闰年
    else
        days = days + 365+365+366 --大于3年
    end

    --非整年的天数
    local pMonths = bLeapYear and MON2 or MON1;  
    if month>1 then
        for i=1,month-1 do  
            days = days + pMonths[i]  --本年整月的天数
        end 
    end
    days = days + day-1   --本月天数

    
    local time = days*DAYMS + hour*3600 + min*60 + sec

    return time - (gamedata.zone or 0)*3600  
end

local sysOStime = os.time
os.time_ = sysOStime

os.time = GetServerTime
 
