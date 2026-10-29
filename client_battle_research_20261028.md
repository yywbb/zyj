# 客户端战斗资源核查：2026-10-28

后续更新：21:01/22:10实战抓包已补充真实“不过了”、眩晕、减伤、反击、吸血和二星证据，见 [新增13场分析](official_battle_capture_20261028_followup.md)。以下保留此次APK检查时的发现及待查项。

## 来源与检查范围

- 从目标手机已安装的官方包 `com.ldfs.zyjyg.muyou` 只读拉取 APK；版本为 **9.0.4 / versionCode 185**，大小 **474,009,112 字节**。
- APK SHA-256：`f8a5ae8d5e131f00aa38b2fa496f925e1b856365dc24532ad857fd1a5e3a9858`。
- 解密了 APK 的 `assets/scripts/` 和 `assets/common_lua/` 共 **1,269** 份 Lua，验证了末尾长度字及 UTF-8。`GameCopy`、`battleReportConvert`、`battleScene`、`battletest`、`ui` 与仓库参考脚本在统一换行后相同。
- 解析了 **795** 份 `assets/UI/public/skilljson/*.json`，均为有效 JSON；提取了雷公、电母、魔王憾地和“不过了”四份演示，以及“不过了”的动画时间配置。
- 检查了 ARM64 `libcocos2dlua.so` 的 **60,253** 条导出符号、可打印字符串，并反汇编 Lua 加载及模块注册入口；不是完整原生代码反编译，也未检查手机热更新目录。

本机原件保存在 `/private/var/folders/vq/z4hfymf179d93zqcl98fvt0c0000gn/T/opencode/`：APK 为 `zyj-official-client-20261028.apk`；提取目录为 `zyj-client-battle-evidence/`；脚本清单为 `zyj-client-lua-manifest.json`。临时文件清理后可按上述 APK 路径和校验值重新提取，不依赖它们启动服务。

## 1. 普通挑战由服务器下发完整结果

- `scripts_clean/GameCopy.lua:320`：1306 请求只编码 `[地图, 关卡]`，不发送玩家计算的行动或胜负。
- `scripts_clean/GameCopy.lua:342`：从回复直接读取 `result/star/exp/reward/generals/battlereport`。
- 2014 抓包的望乡台请求只有 **6 字节**；回复的 BattleResult 字段 5 已有 **4,244 字节** JSON 战报，包含出手者、目标、技能、伤害及怒气变化。
- `scripts_clean/battleReportConvert.lua:1247`：顺序遍历现成的 `report.battle.action` 并转换成动画。`battleScene.lua:2297` 读取星级，随后读取战报结果，并非动画播完再计算输赢。
- `battleReportConvert.lua:358–425` 确有计算：把已给定的总伤害分配到多个飘字，最后一段补齐余数；这不能代替服务器的攻击、防御和技能伤害公式。

## 2. 找到了“不过了”的本地演示，但不是实战计算器

入口为 `scripts_clean/ui.lua:5729`，读取 `public/skilljson/<技能ID>.json`。APK 对应文件为：

```text
assets/UI/public/skilljson/12622.json
SHA-256: c994dd36e26017bcc3c13b89779b91d19e46ae2531568a925728f6f3f64cbd15
```

文件只有入场和一次预写合体攻击，可确认客户端接受以下结构：

- `source = {direct: true, pos: [4, 6], skillid: 12622, type: "comb"}`；两名参与者分别为雷公 CID 10213、电母 CID 10214。
- 四个目标位置为 **8/10/12/14**，与配置的后排范围一致。
- 每个目标均预写 `damage=8888` 和 `status={status: "dizzy", switch: true}`。
- `assets/battle/buguole/buguole.json` 有四个伤害播放时点：0.5、0.6、0.7、0.87 秒，与配置 `count=4` 对应。

演示缺少双方攻击/防御等计算输入，目标初始 HP 都为 11877；扣掉 8888 后仍约剩 25% HP，却全部预写眩晕。因此它可验证多参与者、目标及状态的**播放格式**，不能证明实战伤害、触发概率或“低于20%眩晕”的判断时点。其他演示也大量使用固定伤害：795 份文件中，8888 共出现 3678 次。

`configs_sec5.zip` 的 `5/combskill.json` 已有“不过了”的后排、倍率 `0.85;0.05`、4 段及效果说明；`combskillprobability.json` 有每回合 0.35 的配置值。尚未找到调用这些值生成实战行动的客户端代码，不能仅凭配置断言触发条件和调用顺序。

## 3. 原生库的初查结果

主库 `lib/arm64-v8a/libcocos2dlua.so` SHA-256：`c3460e897080e50873c0de6d3647e717c4217d8162705e07f13b53dccc661f6f`。

- 导出符号中未找到 battle/combat/skill 等战斗计算入口；字符串中未找到 `combskill`、`copy_monster`、`battle_def_param1`、`BattleReport` 等关联项。
- `AppDelegate::loadLua()`（0xacd488）注册 Lua 模块、线程数据交换、JSON、文件、SQLite、MD5 和 Protobuf。
- `lua_custom_module_register()`（0xbaed6c）注册表格视图、事件、HTTP、灰度精灵、设备、线程发包及自定义扩展；常规模块入口注册 Cocos 渲染、音频、网络、物理等模块。
- `battletest.lua` 也发送 999990 请求并接收服务器战报；并非本地模拟器。

结论是**这轮未发现可直接搬用的完整战斗引擎**，不是证明 APK 内绝不存在其他实现。已确认的正常挑战路径仍是服务器战报驱动。

## 4. 可以直接利用的规则与仍需验证的部分

| 内容 | 当前证据 | 后续用途 |
| --- | --- | --- |
| 体力与挑战上限 | `GameCopy.lua:332–337` 检查配置；373 在收到挑战结果后扣客户端体力 | 本地服务仍需独立校验并持久化；失败奖励另查 |
| 通关次数与星级保存 | `GameCopy.lua:397–438`：胜利时首次 kill=1，否则 kill+1，保存最高星级 | 连续重打抓包是补充验证，不是发现加一规则的前提 |
| 首次三星银币 | `GameCopy.lua:458`，以及三场实战对照 | 已用于 `battle.victory_role_reward()` |
| 技能目标/状态的报文格式 | 客户端演示和战报转换代码 | 双参与者合体、后排位置、眩晕开关可据此构造和检查 |
| 怒气变化 | 三场实战均初始 AP=2、普攻后 +2、放技能后清零；雷公天雷击另有 +1 | 可作为当前样本的回合状态验证；不外推全部技能 |
| 合体伤害与触发 | 配置有倍率/范围；演示固定8888 | 仍需核实两人攻击力如何参与、触发条件与消耗/行动规则 |
| 自动目标、行动顺序、眩晕解除 | 已有三场动作和配置 | 先对现有样本建立并检查规则，无法消除的歧义再定向补录 |
| 一/二星及失败奖励 | 回复字段由服务器给；三场样本均三星胜利 | 仍缺实战对照，不能预设任意死亡数/回合数阈值 |
| 升级后属性、战力与随机掉落 | 配置和战后快照已有部分证据 | 继续逐字段核对，不能只更新经验而留下旧属性 |

## 下一实施顺序

1. 利用配置、客户端可确认规则和现有教程/普通战报，继续实现与网络解耦的回合状态及战报生成；检查怒气、死亡、眩晕和目标有效性。演示数据只验证格式，不能作为实际伤害或自动胜利。
2. 对现有实战样本逐行动核对，并测试当前存档参与的结算与保存失败回滚。随机决策与数值计算分开验证，不能把录制动作硬编码为生产决策。
3. 仅针对剩余歧义补充“不过了”实战、失败/非三星样本等，再接入1306并实机验证。缺少连续重打样本不阻止实现已有明确代码证据的次数累计。

本轮只增加分析记录；未修改生产战斗路由或真实角色存档。
