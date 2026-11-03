# 客户端自动诊断

## 启用

1. 在打包机保留原版`z7_7_4.apk`、JDK17、SDK34及NDK r27c。运行`python3 build_local_apk.py --server-ip 10.66.0.11 --accounts 2`。
2. 将打包机根目录的`client_reports.key`安全复制到服务端项目根目录，权限设为0600。此文件不入Git；已有密钥不会自动覆盖。不同密钥会返回403，手机保留报告而不删除。
3. 更新服务端源码并重启`python3 mock_server.py`。只在可信虚拟网放行TCP14602，游戏仍用14600。管理后台的进程写令牌绝不放入APK。
4. 更新APK；旧APK没有这个采集器。这里没有自动部署、重启、安装或触发真实账号崩溃。

服务端启动同进程内的独立HTTP监听，默认`0.0.0.0:14602`。`--client-log-port 0`仅用于临时端口测试；换生产端口还需同步APK构建端点，不能仅改服务端参数。

## 数据与边界

- 覆盖原包六个UI/net Lua traceback入口，直接调用Java bridge，不依赖游戏连接、UIRequest成功或UI全局变量。原有错误提示/返回流程保留。
- Lua只上传异常分类、文件/行号和函数名；不上传任意异常原文、局部变量、密码、请求包或日志全文。因此自定义动态错误的详细文字可能被省略。
- ARM64/ARMv7原生采集六类致命信号（SEGV/ABRT/BUS/ILL/FPE/TRAP）：预先打开私有文件；信号现场仅写信号/code、PC/LR、时间和可执行so的地址/偏移/文件名。保留既有SIG_IGN，恢复原处理器并重新触发真实崩溃，不在崩溃现场调用Java、分配堆内存、联网或读取栈内容。
- 原生记录是**轻量现场，不是完整tombstone/原生调用栈**。不捕获SIGKILL、系统强杀、ANR或采集器安装前的崩溃。主游戏进程启用；原包SDK后续信号处理器与真机兼容仍需实测。JNI入口为当前UI/net线程安装备用信号栈，保留已有备用栈。
- 同时记录未捕获Java异常的类名/调用位置，不记录异常message或线程名；已有默认异常处理仍执行。
- 报告只带随机报告ID、构建源码指纹、SDK/ABI、来源和时间；不收集账号、设备序列号、IMEI、内存或完整网络包。旧原生报告沿用崩溃时构建指纹，不冒用新版APK版本。

## 落盘、重试与限制

- App文件位于`getNoBackupFilesDir()/client_reports`，不会进入Android自动备份。一次写入先fsync临时文件再重命名；启动只清理未提交的`.tmp`及无崩溃信号的旧运行占位文件。
- 最多24份已提交/原生待传记录，每份至多64KiB；Lua/Java每进程每分钟最多10份，超限丢弃新事件，不覆盖已有待传报告。队列满时可能无法捕获新的原生崩溃。
- App进程存活时约60秒重试，进入前台也尝试；退出后没有后台服务。原生崩溃在下次启动转换后上传。只有服务器返回200且完整确认同一报告ID时才删除；超时、403/429/5xx、重定向或错误确认均保留，不跟随重定向，不发送到系统代理。
- 服务端只接受`POST /v1/reports`，严格字段/诊断行白名单、64KiB上限、3秒读超时、单独串行处理、每来源IP30次/分钟和总计120次/分钟；无查询、下载、账号或后台写操作。上传令牌可从APK提取，不能视为日志来源真实性证明；接口仍须仅放在可信虚拟网，HTTP未加密。
- 原子写入`logs/client_reports/<ID>.json`后确认。相同ID/内容重试不重写，不同内容返回409。最多1000文件/32MiB，满后返回507，不删除旧诊断；需管理员先归档清理，手机稍后重试。此目录及上传密钥均Git忽略，不属于游戏存档。

## 验证

定向执行：

```bash
uv run --no-project --with lupa python -B -m unittest -v test_client_reports \
  test_build_local_apk.LanBuildTests.test_lua_reports_capture_all_real_handlers_without_credentials_or_ui_dependencies \
  test_build_local_apk.LanBuildTests.test_private_report_provider_is_appended_without_changing_other_binary_manifest_nodes
```

包括实际Java队列→Python接收端、失败/重定向/确认校验、限流/磁盘上限/保存失败、Lua脱敏及桌面子进程内实际致命信号落盘并保持崩溃退出。Android两种ABI另由实际构建校验；不能把桌面信号测试或DEX编译等同于Mate40实机验收。接收测试仅用回环临时端口、临时文件，不触碰14600/14601/14602或真实账号。
