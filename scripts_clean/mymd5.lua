local md5 = require("md5")


--mdk check function
function md5sumhexa (k)

  cclog"md5 check start------"
  k = md5.sum(k)
  return (string.gsub(k, ".", function (c)
           return string.format("%02x", string.byte(c))
         end))
end

  
      