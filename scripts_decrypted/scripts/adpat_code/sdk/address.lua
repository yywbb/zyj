
local alladdress = {
    --59测试服
    ["59test"] = {   
        -- gameAddress =     {host = "182.92.161.59", port = 8000},
        -- resourceAddress = {host = "182.92.161.59", port = 8000},
        -- autologinAddress = "https://182.92.161.59:9102/userTestLogin",
        -- testrigistAddress = "",
        -- testloginAddress = "",

        -- postAddress = "https://182.92.161.59:9102/systemNotice",
        -- loginAddress = "https://182.92.161.59:9102/userChannelLogin",
        -- entergameAddress = "https://182.92.161.59:9102/userSelectGameServer",
        -- updateAddress =       "https://182.92.161.59:18888/getpginformation.php",
        -- configupdateAddress = "https://182.92.161.59:18888/getconfinfo",
        -- serverInfoAddress =   "https://182.92.161.59:18888/serverlist", 
        -- packageAddress = "https://valid.zyj.52muyou.com/checkPackage", 

        --新内部测试地址
        -- gameAddress =     {host = "39.96.117.45", port = 8000},
        -- resourceAddress = {host = "39.96.117.45", port = 8000},
        -- autologinAddress = "https://39.96.117.45:9102/userTestLogin",
        -- testrigistAddress = "",
        -- testloginAddress = "",

        -- postAddress = "https://39.96.117.45:9102/systemNotice",
        -- loginAddress = "https://39.96.117.45:9102/userChannelLogin",
        -- entergameAddress = "https://39.96.117.45:9102/userSelectGameServer",
        -- updateAddress =       "https://39.96.117.45:18888/getpginformation.php",
        -- configupdateAddress = "https://39.96.117.45:18888/getconfinfo",
        -- serverInfoAddress =   "https://39.96.117.45:18888/serverlist", 
        -- packageAddress = "https://valid.zyj.52muyou.com/checkPackage", 


        --vpc测试地址
        -- gameAddress =     {host = "59.110.218.239", port = 8000},
        -- resourceAddress = {host = "59.110.218.239", port = 8000},
        -- autologinAddress = "https://59.110.218.239/vpc_login/userTestLogin",
        -- testrigistAddress = "",
        -- testloginAddress = "",

        -- updateAddress =   "https://59.110.218.239/vpc_compress/getpginformation.php",
        -- configupdateAddress = "https://59.110.218.239/vpc_compress/getconfinfo",
        -- serverInfoAddress =   "https://59.110.218.239/vpc_compress/serverlist", 

        --  --新增
        -- postAddress = "https://59.110.218.239/vpc_login/systemNotice",
        -- loginAddress = "https://59.110.218.239/vpc_login/userChannelLogin",
        -- entergameAddress = "https://59.110.218.239/vpc_login/userSelectGameServer",   
        -- packageAddress = "",



        --跨服战测试地址
        -- gameAddress =     {host = "39.107.50.75", port = 8000},
        -- resourceAddress = {host = "39.107.50.75", port = 8000},
        -- autologinAddress = "https://39.107.50.75:83/userTestLogin",
        -- testrigistAddress = "",
        -- testloginAddress = "",

        -- updateAddress =   "https://39.107.50.75:18888/getpginformation.php",
        -- configupdateAddress = "https://39.107.50.75:18888/getconfinfo",
        -- serverInfoAddress =   "https://39.107.50.75:18888/serverlist", 

        --  --新增
        -- postAddress = "https://39.107.50.75:83/systemNotice",
        -- loginAddress = "https://39.107.50.75:83/userChannelLogin",
        -- entergameAddress = "https://39.107.50.75:83/userSelectGameServer",   
        
        gameAddress =     {host = "39.105.173.228", port = 10011},
        resourceAddress = {host = "39.105.173.228", port = 10011},
        updateAddress =   "https://39.105.173.228:18888/getpginformation.php",
        configupdateAddress = "https://39.105.173.228:18888/getconfinfo",
        serverInfoAddress =   "https://39.105.173.228:18888/serverlist", 
    },

    ["muyou39test"] = {   
        gameAddress =     {host = "39.107.27.38", port = 10011},
        resourceAddress = {host = "39.107.27.38", port = 10011},
        updateAddress =       "https://39.107.27.38:3010/getpginformation.php",
        configupdateAddress = "https://39.107.27.38:3010/getconfinfo",
        serverInfoAddress =   "https://39.107.27.38:3010/serverlist",
    },

    --测试环境登android 新
    -- ["59test"] = {   
    --     gameAddress =     {host = "39.106.249.154", port = 10011},
    --     resourceAddress = {host = "39.106.249.154", port = 10011},
    --     updateAddress =       "https://res.zyj.52muyou.com:3010/getpginformation.php",
    --     configupdateAddress = "https://res.zyj.52muyou.com:3010/getconfinfo",
    --     serverInfoAddress =   "https://res.zyj.52muyou.com:3010/serverlist",    
    -- },

    --ios官方
    ["ios"] = {   
        gameAddress =     {host = "ios-acc.zyj.52muyou.com", port = 10011},
        resourceAddress = {host = "ios-acc.zyj.52muyou.com", port = 10011},
        updateAddress =       "https://res.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://res.zyj.52muyou.com/getconfinfo",
        serverInfoAddress =   "https://res.zyj.52muyou.com/serverlist",    

      --新增
        postAddress = "https://i.zyj.52muyou.com/systemNotice",
        loginAddress = "https://i.zyj.52muyou.com/userChannelLogin",
        entergameAddress = "https://i.zyj.52muyou.com/userSelectGameServer",   
        packageAddress = "https://i.zyj.52muyou.com/checkPackage",

    },

    --android混服
    ["android"] = {  
        gameAddress =     {host = "39.106.249.154", port = 10011},
        resourceAddress = {host = "39.106.249.154", port = 10016},
        updateAddress =       "https://res.zyj.52muyou.com/android/getpginformation.php",
        configupdateAddress = "https://res.zyj.52muyou.com/android/getconfinfo",
        serverInfoAddress =   "https://res.zyj.52muyou.com/android/serverlist",    

         --新增
        postAddress = "https://a.zyj.52muyou.com/systemNotice",
        loginAddress = "https://a.zyj.52muyou.com/userChannelLogin",
        entergameAddress = "https://a.zyj.52muyou.com/userSelectGameServer",    
        -- packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },

    --应用宝
    ["tencent"] = {  
        gameAddress =     {host = "115.159.106.82", port = 10011},
        resourceAddress = {host = "115.159.106.82", port = 10011},
        updateAddress =       "https://res.zyj.52muyou.com/msdk/getpginformation.php",
        configupdateAddress = "https://res.zyj.52muyou.com/msdk/getconfinfo",
        serverInfoAddress =   "https://res.zyj.52muyou.com/msdk/serverlist",    
    },

    --ios越狱
    ["ios_yueyu"] = {  
        gameAddress =     {host = "39.107.53.76", port = 10011},
        resourceAddress = {host = "39.107.53.76", port = 10011},
        updateAddress =       "https://res.zyj.52muyou.com/yueyu/getpginformation.php",
        configupdateAddress = "https://res.zyj.52muyou.com/yueyu/getconfinfo",
        serverInfoAddress =   "https://res.zyj.52muyou.com/yueyu/serverlist",    

        postAddress = "https://p.zyj.52muyou.com/yueyu_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/yueyu_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/yueyu_login/userSelectGameServer",   
        packageAddress = "https://i.zyj.52muyou.com/checkPackage", 
    },

    --安卓小米
    ["android_xiaomi"] = {  
        gameAddress =     {host = "47.93.76.48", port = 15011},
        resourceAddress = {host = "47.93.76.48", port = 15011},
        updateAddress = "https://lianyun.zyj.52muyou.com/xiaomi/getpginformation.php",
        configupdateAddress = "https://lianyun.zyj.52muyou.com/xiaomi/getconfinfo",
        serverInfoAddress = "https://lianyun.zyj.52muyou.com/xiaomi/serverlist",   


        postAddress = "https://p.zyj.52muyou.com/mi2_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/mi2_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/mi2_login/userSelectGameServer",   
        packageAddress = "",
    },

     --安卓小米游戏fan有包体限制
    ["android_xiaomiyxf"] = {  
        gameAddress =     {host = "47.93.76.48", port = 15011},
        resourceAddress = {host = "47.93.76.48", port = 15011},
        updateAddress = "https://lianyun.zyj.52muyou.com/xiaomi/getpginformation.php",
        configupdateAddress = "https://lianyun.zyj.52muyou.com/xiaomi/getconfinfo",
        serverInfoAddress = "https://lianyun.zyj.52muyou.com/xiaomi/serverlist",   


        postAddress = "https://p.zyj.52muyou.com/mi2_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/mi2_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/mi2_login/userSelectGameServer",   
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
    },

     --17应用宝
    ["17tencent"] = {  
        gameAddress =     {host = "115.159.69.180", port = 10011},
        resourceAddress = {host = "115.159.69.180", port = 10011},
        updateAddress =       "https://res.zyj.52muyou.com/msdk2/getpginformation.php",
        configupdateAddress = "https://res.zyj.52muyou.com/msdk2/getconfinfo",
        serverInfoAddress =   "https://res.zyj.52muyou.com/msdk2/serverlist",    
    },

    --奇遇
    ["qiyu"] = {  
        gameAddress =     {host = "47.93.76.48", port = 46017},
        resourceAddress = {host = "47.93.76.48", port = 46011},
        -- updateAddress = "https://lianyun.zyj.52muyou.com:3011/getpginformation.php",
        -- configupdateAddress = "https://lianyun.zyj.52muyou.com:3011/getconfinfo",
        -- serverInfoAddress = "https://lianyun.zyj.52muyou.com:3011/serverlist",   
        

        --旧
        updateAddress = "https://qiyu.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://qiyu.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://qiyu.zyj.52muyou.com/serverlist",   

        --新增
        postAddress = "https://qiyuaccount.zyj.52muyou.com/systemNotice",
        loginAddress = "https://qiyuaccount.zyj.52muyou.com/userChannelLogin",
        entergameAddress = "https://qiyuaccount.zyj.52muyou.com/userSelectGameServer",   
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
    },

     --奇遇ios
    ["qiyuios"] = {  
        gameAddress =     {host = "acc.zyjiosly.52muyou.com", port = 46017},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 46011},
        updateAddress = "https://qiyu.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://qiyu.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://qiyu.zyj.52muyou.com/serverlist",    

        --新增
        postAddress = "https://qiyuaccount.zyj.52muyou.com/systemNotice",
        loginAddress = "https://qiyuaccount.zyj.52muyou.com/userChannelLogin",
        entergameAddress = "https://qiyuaccount.zyj.52muyou.com/userSelectGameServer",   
    },

    --优点
    ["youdian"] = {  
        gameAddress =     {host = "acc2.lianyun.zyj.52muyou.com", port = 20016},
        resourceAddress = {host = "acc2.lianyun.zyj.52muyou.com", port = 20011},
        updateAddress = "https://youdian.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://youdian.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://youdian.zyj.52muyou.com/serverlist",    
    },

      --鲸旗
    ["jingqi"] = {  
        gameAddress =     {host = "acc2.lianyun.zyj.52muyou.com", port = 50016},
        resourceAddress = {host = "acc2.lianyun.zyj.52muyou.com", port = 50011},
        updateAddress = "https://jq.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://jq.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://jq.zyj.52muyou.com/serverlist",    

       --新增
        postAddress = "https://kingcheer.zyj.52muyou.com/systemNotice",
        loginAddress = "https://kingcheer.zyj.52muyou.com/userChannelLogin",
        entergameAddress = "https://kingcheer.zyj.52muyou.com/userSelectGameServer", 
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
    },
    
      --神游天下
    ["sytx"] = {  
        gameAddress =     {host = "39.106.139.34", port = 10016},
        resourceAddress = {host = "39.106.139.34", port = 10011},
        updateAddress = "https://p.z.52muyou.com/sytx_compress/getpginformation.php",
        configupdateAddress = "https://p.z.52muyou.com/sytx_compress/getconfinfo",
        serverInfoAddress = "https://p.z.52muyou.com/sytx_compress/serverlist",    

        --新增
        postAddress = "https://p.z.52muyou.com/sytx_login/systemNotice",
        loginAddress = "https://p.z.52muyou.com/sytx_login/userChannelLogin",
        entergameAddress = "https://p.z.52muyou.com/sytx_login/userSelectGameServer",  
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
    },


     --爱奇艺
    ["iqiyi"] = {  
        gameAddress =     {host = "47.93.205.244", port = 10016},
        resourceAddress = {host = "47.93.205.244", port = 10011},
        updateAddress = "https://p.z.52muyou.com/aqy_compress/getpginformation.php",
        configupdateAddress = "https://p.z.52muyou.com/aqy_compress/getconfinfo",
        serverInfoAddress = "https://p.z.52muyou.com/aqy_compress/serverlist",    

        --新增
        postAddress = "https://p.z.52muyou.com/iqiyi_login/systemNotice",
        loginAddress = "https://p.z.52muyou.com/iqiyi_login/userChannelLogin",
        entergameAddress = "https://p.z.52muyou.com/iqiyi_login/userSelectGameServer",  
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
    },

    --神游天下数果
    ["sytxsg"] = {  
        gameAddress =     {host = "39.106.139.34", port = 10016},
        resourceAddress = {host = "39.106.139.34", port = 10011},
        updateAddress = "https://p.z.52muyou.com/shenyou2_compress/getpginformation.php",
        configupdateAddress = "https://p.z.52muyou.com/shenyou2_compress/getconfinfo",
        serverInfoAddress = "https://p.z.52muyou.com/shenyou2_compress/serverlist",    

        --新增
        postAddress = "https://p.z.52muyou.com/shenyou2_login/systemNotice",
        loginAddress = "https://p.z.52muyou.com/shenyou2_login/userChannelLogin",
        entergameAddress = "https://p.z.52muyou.com/shenyou2_login/userSelectGameServer",  
        packageAddress = "https://p.z.52muyou.com/shenyou2_login/checkPackage",
    },
    --抢玩
    ["qiangwan"] = {  
        gameAddress =     {host = "zsy-acc.zyj.52muyou.com", port = 30011},
        resourceAddress = {host = "zsy-acc.zyj.52muyou.com", port = 30011},
        updateAddress = "https://qw.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://qw.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://qw.zyj.52muyou.com/serverlist",    

         --新增
        postAddress = "https://p.zyj.52muyou.com/qiangwan_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/qiangwan_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/qiangwan_login/userSelectGameServer",  
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
        serverUpdate = "https://p.zyj.52muyou.com/qiangwan_login/serverList",

    },
    -- 悦玩
    ["yuewan"] = {
        gameAddress = {host = "p.z.52muyou.com", port = 10016},
        resourceAddress = {host = "p.z.52muyou.com", port = 10011},
        --旧
        updateAddress = "https://p.z.52muyou.com/yuewan_compress/getpginformation.php",
        configupdateAddress = "https://p.z.52muyou.com/yuewan_compress/getconfinfo",
        serverInfoAddress = "https://p.z.52muyou.com/yuewan_compress/serverlist",
        --新增
        postAddress = "https://p.z.52muyou.com/yuewan_login/systemNotice",
        loginAddress = "https://p.z.52muyou.com/yuewan_login/userChannelLogin",
        entergameAddress = "https://p.z.52muyou.com/yuewan_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
    -- 意游
    ["yiyou"] = {  
        gameAddress =     {host = "yiyou-acc.zyj.52muyou.com", port = 20011},
        resourceAddress = {host = "yiyou-acc.zyj.52muyou.com", port = 20011},
        updateAddress = "https://yiyou.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://yiyou.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://yiyou.zyj.52muyou.com/serverlist",    
          
        --新增
        postAddress = "https://p.zyj.52muyou.com/yiyou_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/yiyou_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/yiyou_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
    --优点 新登陆
    ["youdian_new"] = {
        gameAddress = {host = "acc2.lianyun.zyj.52muyou.com", port = 20016},
        resourceAddress = {host = "acc2.lianyun.zyj.52muyou.com", port = 20011},
        updateAddress = "https://youdian.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://youdian.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://youdian.zyj.52muyou.com/serverlist",   
        --新增
        postAddress = "https://p.zyj.52muyou.com/youdian_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/youdian_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/youdian_login/userSelectGameServer",   
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
    --  65
    ["65"] = {
        gameAddress = {host = "p.z.52muyou.com", port = 10016},
        resourceAddress = {host = "p.z.52muyou.com", port = 10011},
        --旧
        updateAddress = "https://p.z.52muyou.com/65_compress/getpginformation.php",
        configupdateAddress = "https://p.z.52muyou.com/65_compress/getconfinfo", 
        serverInfoAddress = "https://p.z.52muyou.com/65_compress/serverlist",
        --新增
        postAddress = "https://p.z.52muyou.com/65_login/systemNotice",
        loginAddress = "https://p.z.52muyou.com/65_login/userChannelLogin",
        entergameAddress = "https://p.z.52muyou.com/65_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
    --play800
    ["play800"] = {  
        gameAddress =     {host = "acc.zyjiosly.52muyou.com", port = 47011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 47011},
        updateAddress = "https://play.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://play.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://play.zyj.52muyou.com/serverlist",    
    },
    --优点
    ["youdian"] = {
        gameAddress = {host = "acc2.lianyun.zyj.52muyou.com", port = 20016},
        resourceAddress = {host = "acc2.lianyun.zyj.52muyou.com", port = 20011},
        updateAddress = "https://youdian.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://youdian.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://youdian.zyj.52muyou.com/serverlist"
    },
     --快游
    ["kuaiyou"] = {  
        gameAddress =     {host = "acc.zyjiosly.52muyou.com", port = 40011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 40011},
        updateAddress = "https://kuaiyou.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://kuaiyou.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://kuaiyou.zyj.52muyou.com/serverlist",    

        postAddress = "https://p.zyj.52muyou.com/kuaiyou_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/kuaiyou_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/kuaiyou_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
     --寻趣
    ["xunqu"] = {  
        gameAddress =     {host = "p.z2.52muyou.com", port = 10016},
        resourceAddress = {host = "p.z2.52muyou.com", port = 10011},
        updateAddress = "https://p.z2.52muyou.com/xunqu_compress/getpginformation.php",
        configupdateAddress = "https://p.z2.52muyou.com/xunqu_compress/getconfinfo",
        serverInfoAddress = "https://p.z2.52muyou.com/xunqu_compress/serverlist",    
        packageAddress = "https://p.z2.52muyou.com/xunqu_compress/checkPackage",

           --新增
        postAddress = "https://p.z2.52muyou.com/xunqu_login/systemNotice",
        loginAddress = "https://p.z2.52muyou.com/xunqu_login/userChannelLogin",
        entergameAddress = "https://p.z2.52muyou.com/xunqu_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
     --安峰
    ["anfeng"] = {  
        gameAddress =     {host = "acc.zyjiosly.52muyou.com", port = 50011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 50011},
        updateAddress = "https://lianyun.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://lianyun.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://lianyun.zyj.52muyou.com/serverlist",   

        --新增
        postAddress = "https://p.zyj.52muyou.com/anfeng_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/anfeng_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/anfeng_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
    --汉风
    ["hanfeng"] = {  
        gameAddress =     {host = "acc.zyjiosly.52muyou.com", port = 20011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 20011},
        --旧
        updateAddress = "https://p2.z.52muyou.com/hf_compress/getpginformation.php",
        configupdateAddress = "https://p2.z.52muyou.com/hf_compress/getconfinfo",
        serverInfoAddress = "https://p2.z.52muyou.com/hf_compress/serverlist",    
        --新增
        postAddress = "https://p.zyj.52muyou.com/hanfeng_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/hanfeng_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/hanfeng_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
    --快玩
    ["kuaiwan"] = {  
        gameAddress =     {host = "acc.zyjiosly.52muyou.com", port = 60011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        updateAddress = "https://kuaiwan.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://kuaiwan.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://kuaiwan.zyj.52muyou.com/serverlist",
        
        postAddress = "https://p.zyj.52muyou.com/kuaiwan_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/kuaiwan_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/kuaiwan_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
        serverUpdate = "https://p.zyj.52muyou.com/kuaiwan_login/serverList"

    },
     --喜扑
    ["xipu"] = {
        gameAddress = {host = "acc2.lianyun.zyj.52muyou.com", port = 60016},
        resourceAddress = {host = "acc2.lianyun.zyj.52muyou.com", port = 60011},
        --旧
        updateAddress = "https://xipu.zyj.52muyou.com/getpginformation.php",
        configupdateAddress = "https://xipu.zyj.52muyou.com/getconfinfo",
        serverInfoAddress = "https://xipu.zyj.52muyou.com/serverlist",
        --新增
        postAddress = "https://p.zyj.52muyou.com/xipu_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/xipu_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/xipu_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },

    --游戏123
    ["youxi123"] = {  
        gameAddress =     {host = "acc.zyjiosly.52muyou.com", port = 60011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        updateAddress = "https://p.z2.52muyou.com/youxi123_compress/getpginformation.php",
        configupdateAddress = "https://p.z2.52muyou.com/youxi123_compress/getconfinfo", 
        serverInfoAddress = "https://p.z2.52muyou.com/youxi123_compress/serverlist",

        postAddress = "https://p.z2.52muyou.com/youxi123_login/systemNotice",
        loginAddress = "https://p.z2.52muyou.com/youxi123_login/userChannelLogin",
        entergameAddress = "https://p.z2.52muyou.com/youxi123_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },

     --小牛
    ["xiaoniu"] = {  
        gameAddress =     {host = "acc.zyjiosly.52muyou.com", port = 60011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        updateAddress = "https://p.z2.52muyou.com/xiaoniu_compress/getpginformation.php",
        configupdateAddress = "https://p.z2.52muyou.com/xiaoniu_compress/getconfinfo", 
        serverInfoAddress = "https://p.z2.52muyou.com/xiaoniu_compress/serverlist",

        postAddress = "https://p.z2.52muyou.com/xiaoniu_login/systemNotice",
        loginAddress = "https://p.z2.52muyou.com/xiaoniu_login/userChannelLogin",
        entergameAddress = "https://p.z2.52muyou.com/xiaoniu_login/userSelectGameServer",
        packageAddress = ""
    },
    --安趣
    ["anqu"] = {  
        gameAddress =     {host = "acc.zyjiosly.52muyou.com", port = 60011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        updateAddress = "https://p2.z.52muyou.com/anqu_compress/getpginformation.php",
        configupdateAddress = "https://p2.z.52muyou.com/anqu_compress/getconfinfo",     
        serverInfoAddress = "https://p2.z.52muyou.com/anqu_compress/serverlist",

        postAddress = "https://p.zyj.52muyou.com/anqu_login/systemNotice",
        loginAddress = "https://p.zyj.52muyou.com/anqu_login/userChannelLogin",
        entergameAddress = "https://p.zyj.52muyou.com/anqu_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
    --胖乐
    ["pangle"] = {  
        gameAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        updateAddress = "https://p.z2.52muyou.com/pangle_compress/getpginformation.php",
        configupdateAddress = "https://p.z2.52muyou.com/pangle_compress/getconfinfo", 
        serverInfoAddress = "https://p.z2.52muyou.com/pangle_compress/serverlist",
        
        postAddress = "https://p.z2.52muyou.com/pangle_login/systemNotice",
        loginAddress = "https://p.z2.52muyou.com/pangle_login/userChannelLogin",
        entergameAddress = "https://p.z2.52muyou.com/pangle_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
    --慧选
    ["huixuan"] = {  
        gameAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        updateAddress = "https://p.z2.52muyou.com/huixuan_compress/getpginformation.php",
        configupdateAddress = "https://p.z2.52muyou.com/huixuan_compress/getconfinfo", 
        serverInfoAddress = "https://p.z2.52muyou.com/huixuan_compress/serverlist",
        
        postAddress = "https://p.z2.52muyou.com/huixuan_login/systemNotice",
        loginAddress = "https://p.z2.52muyou.com/huixuan_login/userChannelLogin",
        entergameAddress = "https://p.z2.52muyou.com/huixuan_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
        serverUpdate = "https://p.z2.52muyou.com/huixuan_login/serverList"
    },
    --慧选 Android 19.4.30 新平台
    ["huixuanAnd"] = {  
        gameAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        updateAddress = "https://p.z2.52muyou.com/huixuanaz_compress/getpginformation.php",
        configupdateAddress = "https://p.z2.52muyou.com/huixuanaz_compress/getconfinfo", 
        serverInfoAddress = "https://p.z2.52muyou.com/huixuanaz_compress/serverlist",
        
        postAddress = "https://p.z2.52muyou.com/huixuanaz_login/systemNotice",
        loginAddress = "https://p.z2.52muyou.com/huixuanaz_login/userChannelLogin",
        entergameAddress = "https://p.z2.52muyou.com/huixuanaz_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
        serverUpdate = "https://p.z2.52muyou.com/huixuanaz_login/serverList"

    },
    --掌娱炫动 2019.4 新平台
    ["zhangyu"] = {  
        gameAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        updateAddress = "https://p.z2.52muyou.com/zhangyu_compress/getpginformation.php",
        configupdateAddress = "https://p.z2.52muyou.com/zhangyu_compress/getconfinfo",
        serverInfoAddress = "https://p.z2.52muyou.com/zhangyu_compress/serverlist",        
        
        postAddress = "https://p.z2.52muyou.com/zhangyu_login/systemNotice",
        loginAddress = "https://p.z2.52muyou.com/zhangyu_login/userChannelLogin",
        entergameAddress = "https://p.z2.52muyou.com/zhangyu_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
    --慧选 创世纪 19.8.9 新平台
    ["huixuanCSJ"] = {  
        gameAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        updateAddress = "https://p.z.52muyou.com/huixuanaz3_compress/getpginformation.php",
        configupdateAddress = "https://p.z.52muyou.com/huixuanaz3_compress/getconfinfo",
        serverInfoAddress = "https://p.z.52muyou.com/huixuanaz3_compress/serverlist",
        
        postAddress = "https://p.z.52muyou.com/huixuanaz3_login/systemNotice",
        loginAddress = "https://p.z.52muyou.com/huixuanaz3_login/userChannelLogin",
        entergameAddress = "https://p.z.52muyou.com/huixuanaz3_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
        serverUpdate = "https://p.z.52muyou.com/huixuanaz3_login/serverList"
    },
    --慧选 硬核正式
    ["huixuanAndroid"] = {  
        gameAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},
        resourceAddress = {host = "acc.zyjiosly.52muyou.com", port = 60011},

        updateAddress = "https://p.z.52muyou.com/huixuanaz2_compress/getpginformation.php",
        configupdateAddress = "https://p.z.52muyou.com/huixuanaz2_compress/getconfinfo",
        serverInfoAddress = "https://p.z.52muyou.com/huixuanaz2_compress/serverlist",

        postAddress = "https://p.z.52muyou.com/huixuanaz2_login/systemNotice",
        loginAddress = "https://p.z.52muyou.com/huixuanaz2_login/userChannelLogin",
        entergameAddress = "https://p.z.52muyou.com/huixuanaz2_login/userSelectGameServer",
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
        serverUpdate = "https://p.z.52muyou.com/huixuanaz2_login/serverList"
    },
    -- 17玩
    ["17android"] = {   
        gameAddress =     {host = "p.z.52muyou.com", port = 20011} ,
        resourceAddress = {host = "p.z.52muyou.com", port = 20011},
        updateAddress = "https://p.z.52muyou.com/yiqiwanaz_compress/getpginformation.php",
        configupdateAddress = "https://p.z.52muyou.com/yiqiwanaz_compress/getconfinfo",
        serverInfoAddress = "https://p.z.52muyou.com/yiqiwanaz_compress/serverlist",  

         --新增
        postAddress = "https://p.z.52muyou.com/yiqiwanaz_login/systemNotice",
        loginAddress = "https://p.z.52muyou.com/yiqiwanaz_login/userChannelLogin",
        entergameAddress = "https://p.z.52muyou.com/yiqiwanaz_login/userSelectGameServer",  
        packageAddress = "",

    },
    -- 17玩 安卓
    ["17androidnew"] = {   
        gameAddress =     {host = "p.z2.52muyou.com", port = 20011} ,
        resourceAddress = {host = "p.z2.52muyou.com", port = 20011},
        updateAddress = "https://p.z2.52muyou.com/yiqiwanaz_compress/getpginformation.php",
        configupdateAddress = "https://p.z2.52muyou.com/yiqiwanaz_compress/getconfinfo",
        serverInfoAddress = "https://p.z2.52muyou.com/yiqiwanaz_compress/serverlist",  

         --新增
        postAddress = "https://p.z2.52muyou.com/yiqiwanaz_login/systemNotice",
        loginAddress = "https://p.z2.52muyou.com/yiqiwanaz_login/userChannelLogin",
        entergameAddress = "https://p.z2.52muyou.com/yiqiwanaz_login/userSelectGameServer",  
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage",
    },
    --小七 新征程
    ["xioa7newStory"] = {  
        gameAddress =     {host = "39.106.249.154", port = 10011},
        resourceAddress = {host = "39.106.249.154", port = 10016},
        configupdateAddress = "https://319-res.sp.x7sy.cn/getconfinfo",
        serverInfoAddress = "https://319-res.sp.x7sy.cn/serverlist",
        audioPostURL = "https://319-res.sp.x7sy.cn//upload.php?action=21b360a2185daaa3a42b1f71185e69ef384f49da",
        updateAddress = "https://319-res.sp.x7sy.cn/getresource",

        postAddress = "https://319-login.sp.x7sy.cn/systemNotice",
        loginAddress = "https://319-login.sp.x7sy.cn/userChannelLogin",
        entergameAddress = "https://319-login.sp.x7sy.cn/userSelectGameServer",
        serverUpdate = "https://319-login.sp.x7sy.cn/serverList",   
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
    --泡酷
    ["paoku"] = {  
        gameAddress =     {host = "resource.paoku.52muyou.com", port = 10011},
        resourceAddress = {host = "resource.paoku.52muyou.com", port = 10016},
        configupdateAddress = "https://resource.paoku.52muyou.com/getconfinfo",
        serverInfoAddress = "https://resource.paoku.52muyou.com/serverlist",
        audioPostURL = "https://resource.paoku.52muyou.com/upload.php?action=21b360a2185daaa3a42b1f71185e69ef384f49da",
        updateAddress = "https://resource.paoku.52muyou.com/getpginformation.php",

        postAddress = "https://resource.paoku.52muyou.com/systemNotice",
        loginAddress = "https://resource.paoku.52muyou.com/userChannelLogin",
        entergameAddress = "https://resource.paoku.52muyou.com/userSelectGameServer",
        serverUpdate = "https://resource.paoku.52muyou.com/serverList",   
        packageAddress = "https://resource.paoku.52muyou.com/checkPackage"
    },

      --android混服验证包名
      ["androidpackage"] = {  
        gameAddress =     {host = "39.106.249.154", port = 10011},
        resourceAddress = {host = "39.106.249.154", port = 10016},
        updateAddress =       "https://res.zyj.52muyou.com/android/getpginformation.php",
        configupdateAddress = "https://res.zyj.52muyou.com/android/getconfinfo",
        serverInfoAddress =   "https://res.zyj.52muyou.com/android/serverlist",    

         --新增
        postAddress = "https://a.zyj.52muyou.com/systemNotice",
        loginAddress = "https://a.zyj.52muyou.com/userChannelLogin",
        entergameAddress = "https://a.zyj.52muyou.com/userSelectGameServer",    
        packageAddress = "https://valid.zyj.52muyou.com/checkPackage"
    },
}

return alladdress

��  