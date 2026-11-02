"use strict";

const $ = (id) => document.getElementById(id);
const resources = { gold: "元宝", coin: "银币", stamina: "体力", energy: "精力" };
const tabs = { summary: "角色概况", roster: "武将与装备", inventory: "背包", progress: "副本与引导", business: "充值与活动", maintenance: "账号与备份" };
const state = { token: "", accounts: [], account: 1, page: "overview", accountOffset: 0, configOffset: 0, catalogOffset: 0, operationsOffset: 0, mailOffset: 0, mailCatalogOffset: 0 };
let info, editing, management, gmTarget = null, cart = [], mailCart = [], pendingGrant = null, submitting = false;
let navigation = 0, accountRequest = 0, configRequest = 0, catalogRequest = 0, gmRequest = 0, logRequest = 0, mailRequest = 0, mailCatalogRequest = 0;
try { pendingGrant = JSON.parse(sessionStorage.getItem("gm-pending") || "null"); } catch { /* 浏览器存储不可用时仍保留本页回执。 */ }

function node(tag, text, className) {
  const element = document.createElement(tag);
  if (text !== undefined) element.textContent = text;
  if (className) element.className = className;
  return element;
}
function link(text, href, className) { const a = node("a", text, className); a.href = href; return a; }
function message(text, error = false) { $("notice").textContent = text; $("notice").className = error ? "notice error" : "notice"; $("notice").hidden = !text; }
async function api(path, data) {
  const response = await fetch(path, {
    method: data === undefined ? "GET" : "POST",
    headers: data === undefined ? {} : { "Content-Type": "application/json", "X-Admin-Token": state.token },
    body: data === undefined ? undefined : JSON.stringify(data), signal: AbortSignal.timeout(15000),
  });
  const result = await response.json();
  if (!response.ok) { const error = new Error(result.error || `请求失败 (${response.status})`); error.status = response.status; throw error; }
  return result;
}
async function run(action) { try { await action(); } catch (error) { message(error.message || "连接失败，请确认服务端仍在运行后刷新。", true); } }
function button(text, action, className) {
  const control = node("button", text, className); control.type = "button";
  control.addEventListener("click", () => run(action)); return control;
}
function date(value) { return value ? new Date(value * 1000).toLocaleString("zh-CN", { hour12: false }) : "—"; }
function number(value) { return value == null ? "—" : Number(value).toLocaleString("zh-CN"); }
function badge(text, kind = "") { return node("span", text, `badge ${kind}`); }
function fields(entries, className = "key-values") {
  const list = node("dl", undefined, className);
  for (const [name, value] of entries) {
    const entry = node("div"), content = node("dd"); content.append(value instanceof Node ? value : String(value ?? "—"));
    entry.append(node("dt", name), content); list.append(entry);
  }
  return list;
}
function table(rows, columns, empty = "暂无记录。") {
  if (!rows.length) return node("p", empty, "empty");
  const wrapper = node("div", undefined, "table-wrap"), grid = node("table"), head = node("thead"), header = node("tr"), body = node("tbody");
  columns.forEach(([label]) => { const cell = node("th", label); cell.scope = "col"; header.append(cell); });
  head.append(header);
  for (const row of rows) {
    const tr = node("tr");
    for (const [, get] of columns) { const cell = node("td"), value = get(row); cell.append(value instanceof Node ? value : String(value ?? "—")); tr.append(cell); }
    body.append(tr);
  }
  grid.append(head, body); wrapper.append(grid); return wrapper;
}
function section(title, content) { const block = node("section", undefined, "block"); block.append(node("h3", title), content); return block; }
function pager(prefix, offset, total, size = 50) {
  $(`${prefix}-count`).textContent = `${total} 条${total ? ` / ${offset + 1}–${Math.min(offset + size, total)}` : ""}`;
  $(`${prefix}-previous`).disabled = offset === 0;
  $(`${prefix}-next`).disabled = offset + size >= total;
}
function valueText(value) { return typeof value === "object" ? JSON.stringify(value) : String(value ?? "—"); }

async function status() {
  info = await api("/api/status"); state.token = info.token;
  $("pending").hidden = !info.config.restart_required;
  $("connection").textContent = `已连接 · 更新于 ${new Date().toLocaleTimeString("zh-CN", { hour12: false })}`;
  configNames();
  $("config-shortcuts").replaceChildren(...Object.entries(info.config.editable).map(([name, spec]) =>
    button(spec.label, () => { $("config-name").value = name; $("config-query").value = spec.ids[0]; return loadConfigs(0); })));
  const action = $("operations-action").value;
  $("operations-action").replaceChildren(node("option", "全部操作"), ...Object.entries(info.actions).map(([id, name]) => { const option = node("option", name); option.value = id; return option; }));
  $("operations-action").firstChild.value = ""; $("operations-action").value = action;
  $("common-items").replaceChildren(...info.common_items.map((item) => button(item.name, () => addItem(item))));
  grantLock();
}

async function loadAccounts() { state.accounts = (await api("/api/accounts")).accounts; renderAccounts(); }
function renderAccounts() {
  const search = $("account-search").value.trim().toLowerCase(), filter = $("account-filter").value, level = Number($("account-level").value);
  const rows = state.accounts.filter((row) => `${row.id} ${row.name}`.toLowerCase().includes(search)
    && (!level || row.level >= level) && (!filter || (filter === "online" ? row.online : filter === "offline" ? !row.online : filter === "error" ? row.error : !row.registered)));
  state.accountOffset = Math.min(state.accountOffset, Math.max(0, Math.ceil(rows.length / 25) - 1) * 25);
  $("account-count").textContent = `${state.accounts.length} 个账号 / ${state.accounts.filter((r) => r.online).length} 个在线`;
  $("account-list").replaceChildren(table(rows.slice(state.accountOffset, state.accountOffset + 25), [
    ["账号", (r) => link(r.id, `#account/${r.id}/summary`)], ["角色", (r) => r.name],
    ["状态", (r) => badge(r.error ? "存档异常" : r.online ? "在线" : "离线", r.error ? "failed" : r.online ? "online" : "")],
    ["等级", (r) => number(r.level)], ["VIP", (r) => number(r.vip)], ["元宝", (r) => number(r.gold)],
    ["登录", (r) => r.registered ? "已启用" : "待绑定"], ["最近保存", (r) => date(r.saved_at)],
    ["操作", (r) => link("打开档案", `#account/${r.id}/summary`)],
  ], "没有匹配玩家，可在上方输入账号编号打开或创建。"));
  $("account-page-count").textContent = `${rows.length} 条 / 第 ${Math.floor(state.accountOffset / 25) + 1} 页`;
  $("account-previous").disabled = state.accountOffset === 0; $("account-next").disabled = state.accountOffset + 25 >= rows.length;
}

async function loadOverview() {
  const request = navigation;
  await loadAccounts();
  const recent = await api("/api/operations");
  if (request !== navigation) return;
  $("overview-stats").replaceChildren(...fields([
    ["已发现账号", state.accounts.length], ["在线玩家", state.accounts.filter((r) => r.online).length],
    ["已建角色", state.accounts.filter((r) => r.has_role).length], ["档案异常", state.accounts.filter((r) => r.error).length],
  ]).children);
  $("uptime").textContent = `启动于 ${date(info.started_at)}`;
  $("overview-online").replaceChildren(table(state.accounts.filter((r) => r.online), [
    ["玩家", (r) => link(`${r.id} · ${r.name}`, `#account/${r.id}/summary`)], ["等级", (r) => number(r.level)],
    ["连接地址", (r) => r.connection.address], ["连接时间", (r) => date(r.connection.connected_at)],
  ], "当前没有在线玩家。"));
  $("overview-config").replaceChildren(fields([
    ["配置状态", badge(info.config.restart_required ? "等待重启" : "已加载", info.config.restart_required ? "pending" : "success")],
    ["运行版本", info.config.active_revision.slice(0, 12)], ["保存版本", info.config.revision.slice(0, 12)], ["可查询表", info.config.tables.length],
  ]));
  $("overview-recent").replaceChildren(operationTable(recent.rows.slice(0, 6)));
}

async function loadAccount(id, tab = "summary") {
  state.account = id;
  const request = ++accountRequest;
  $("account-detail").replaceChildren(node("p", `正在读取账号 ${id}…`, "empty"));
  const row = await api(`/api/accounts/${id}`);
  if (request !== accountRequest || state.page !== "accounts") return;
  const detail = $("account-detail"), heading = node("div", undefined, "detail-heading"), identity = node("div"), actions = node("div", undefined, "actions");
  identity.append(node("small", `账号 ${row.id}`), node("h2", row.name), node("small", `最近保存 ${date(row.saved_at)}`));
  actions.append(badge(row.online ? "在线" : "离线", row.online ? "online" : ""), link("GM 调整与发放", `#gm/${row.id}`, "button primary"), link("操作记录", `#operations/${row.id}`, "button"));
  heading.append(identity, actions); detail.replaceChildren(heading);
  if (row.error) detail.append(node("p", row.error, "error"));
  if (!row.has_save) detail.append(node("p", "尚无存档。在“账号与备份”中设置密码后，可使用此账号登录游戏。", "notice"));
  const navigation = node("nav", undefined, "tabs"); navigation.setAttribute("aria-label", "玩家档案分类");
  for (const [key, name] of Object.entries(tabs)) { const a = link(name, `#account/${id}/${key}`); if (key === tab) a.setAttribute("aria-current", "page"); navigation.append(a); }
  detail.append(navigation);
  if (tab === "summary") {
    detail.append(fields([["等级", number(row.level)], ["VIP", number(row.vip)], ["元宝", number(row.gold)], ["银币", number(row.coin)],
      ["体力", `${number(row.stamina)} / ${number(row.maxstamina)}`], ["精力", `${number(row.energy)} / ${number(row.maxenergy)}`],
      ["战力", number(row.power)], ["武将数量", row.generals.length]], "resources"));
    detail.append(fields([["角色创建", date(row.created_at)], ["引导进度", row.guide], ["装备数量", row.equipment.length], ["背包种类", row.inventory.length]]));
    const battle = row.states.last_battle;
    if (battle?.map) detail.append(section("最近战斗", fields([["副本 / 关卡", `${battle.map} / ${battle.point}`], ["结果", battle.won ? `${battle.star} 星胜利` : "失败"], ["回合", battle.rounds], ["规则", battle.rules]])));
  } else if (tab === "roster") {
    renderPossessions(detail, row, true);
    detail.append(section("装备", table(row.equipment, [["装备", (r) => r.name], ["配置 ID", (r) => r.cid], ["等级", (r) => r.level], ["实例 ID", (r) => r.iid]])));
  } else if (tab === "inventory") {
    renderPossessions(detail, row, false);
  } else if (tab === "progress") {
    detail.append(section("副本", table(row.copies, [["地图", (r) => r.name], ["通关 / 星数", (r) => `${r.cleared} / ${r.stars}`],
      ["星级宝箱", (r) => r.boxes.map((v) => ({ 0: "未记录", 1: "未达标", 2: "可领取", 3: "已领取" }[v] || "未知")).join(" / ")],
      ["关卡", (r) => r.points.map((p) => `${p.id}关：${p.stars}星，胜${p.wins}次`).join("；")]])));
    detail.append(section("引导", table(Object.entries(row.states.guide?.sections || {}), [["章节", (r) => r[0]], ["状态", (r) => ({ 1: "进行中", 2: "已完成" }[r[1].status] || "未开始")], ["当前步骤", (r) => r[1].step], ["已确认步骤数", (r) => r[1].steps?.length || 0]])));
  } else if (tab === "business") renderBusiness(detail, row.business);
  else renderMaintenance(detail, row);
}

function renderPossessions(detail, account, heroes) {
  const filters = node("div", undefined, "filters"), search = node("input"), select = node("select"), results = node("div", undefined, "possession-table");
  search.id = "possession-search"; search.type = "search"; search.placeholder = heroes ? "武将名称 / 配置 ID / 实例 ID" : "物品名称 / 配置 ID";
  select.id = "possession-filter";
  const options = heroes ? [["", "全部武将"], ["active", "已上阵"], ["idle", "闲置"], ["cheer", "助阵"]] : [["", "全部物品"], ["道具", "道具"], ["武将碎片", "武将碎片"]];
  for (const [value, text] of options) { const option = node("option", text); option.value = value; select.append(option); }
  for (const [control, text] of [[search, "搜索"], [select, "筛选"]]) {
    const wrapper = node("div", undefined, control === search ? "grow" : ""), label = node("label", text); label.htmlFor = control.id;
    wrapper.append(label, control); filters.append(wrapper);
  }
  filters.append(button(heroes ? "发放武将" : "发放物品", () => {
    $("catalog-kind").value = heroes ? "武将" : ""; $("catalog-query").value = ""; location.hash = `gm/${account.id}`;
  }));
  const locked = account.online || account.error || !account.has_role || (heroes && account.states.guide?.sections?.["1"]?.status !== 2);
  detail.append(node("p", account.online ? "玩家在线，退出游戏后可管理物品与武将。" : heroes
    ? `武将等级上限 ${account.general_level_cap}，已开放 ${account.slot_limit} 个阵位。管理需完成新手引导。` : "直接修正目标数量，填 0 清空该物品；所有变更自动备份并记录。", "help"), filters, results);
  function control(text, action, item, unavailable = false) {
    const b = button(text, () => openManagement(account, action, item));
    b.dataset.gmAction = ""; b.dataset.unavailable = locked || unavailable ? "true" : "false";
    b.disabled = b.dataset.unavailable === "true" || submitting || !!pendingGrant;
    return b;
  }
  function render() {
    const query = search.value.trim().toLowerCase();
    const rows = (heroes ? account.generals : account.inventory).filter((r) => `${r.name} ${r.cid} ${r.iid || r.item_id}`.toLowerCase().includes(query)
      && (!select.value || (heroes ? select.value === "active" ? r.position : select.value === "cheer" ? r.cheer_position : !r.position && !r.cheer_position : r.kind === select.value)));
    results.replaceChildren(table(rows, heroes ? [
      ["武将", (r) => { const d = node("details"); d.append(node("summary", `${r.name}${r.protagonist && r.name !== "主角" ? " · 主角" : ""}`), fields([
        ["配置 / 实例 ID", `${r.cid} / ${r.iid}`], ["品质", r.quality], ["经验", number(r.exp)], ["潜力", number(r.potential)],
        ["攻击", number(r.atk)], ["防御", number(r.defense)], ["生命", number(r.hp)], ["速度", number(r.speed)],
      ])); return d; }], ["等级", (r) => r.level], ["战力", (r) => number(r.power)],
      ["阵位", (r) => r.position ? `阵位 ${r.position}` : r.cheer_position ? `助阵 ${r.cheer_position}` : "闲置"],
      ["管理", (r) => { const a = node("div", undefined, "actions"); a.append(
        control("升级", "general-level", r, r.level >= account.general_level_cap || !!r.cheer_position),
        control("上阵 / 下阵", "formation", r, !!r.cheer_position),
        control("移除", "remove-general", r, r.protagonist || !!r.position || !!r.cheer_position)); return a; }],
    ] : [["物品", (r) => r.name], ["类型", (r) => r.kind], ["数量", (r) => number(r.count)], ["配置 ID", (r) => r.item_id || r.cid],
      ["管理", (r) => control("调整数量", "inventory", r, !r.item_id)]], "没有匹配条目。"));
  }
  search.oninput = select.onchange = render; render();
}

function openManagement(account, action, item) {
  if (submitting || pendingGrant) throw new Error("请先确认上一次 GM 操作的结果。");
  management = { account, action, item };
  $("manage-form").reset(); $("manager-fields").replaceChildren();
  $("manager-title").textContent = info.actions[action];
  $("manager-target").textContent = `账号 ${account.id} · ${account.name} / ${item.name} (${item.iid || item.item_id})`;
  $("manager-submit").textContent = action === "remove-general" ? "移除武将" : "保存变更";
  if (action !== "remove-general") {
    const input = node(action === "formation" ? "select" : "input"), label = node("label", action === "inventory" ? "目标数量" : action === "formation" ? "目标阵位" : "目标等级");
    input.id = "manager-value"; label.htmlFor = input.id;
    if (action === "formation") {
      for (let pos = 0; pos <= account.slot_limit; pos++) {
        const member = account.generals.find((r) => r.position === pos);
        const option = node("option", pos ? `阵位 ${pos} · ${member?.name || "空位"}` : "下阵"); option.value = pos;
        option.disabled = pos === 0 && item.protagonist; input.append(option);
      }
      input.value = item.position || 1;
    } else {
      input.type = "number"; input.step = "1"; input.required = true;
      input.min = action === "inventory" ? 0 : item.level + 1;
      input.max = action === "inventory" ? 2147483647 : account.general_level_cap;
      input.value = action === "inventory" ? item.count : item.level + 1;
    }
    $("manager-fields").append(label, input);
    if (action === "inventory") {
      const actions = node("div", undefined, "actions block");
      for (const delta of [-10, -1, 1, 10]) actions.append(button(`${delta > 0 ? "+" : ""}${delta}`, () => { input.value = Math.max(0, Math.min(2147483647, Number(input.value) + delta)); }));
      actions.append(button("清空", () => { input.value = 0; })); $("manager-fields").append(actions);
    }
  }
  $("manager-help").textContent = {
    inventory: `当前数量 ${number(item.count)}。保存的是目标总量，不会触发道具使用或奖励效果。`,
    "general-level": "GM 直接升级，不扣经验丹。按现有成长规则同步属性、潜力与战力，保留已有培养加成。",
    formation: "替换闲置武将继承阵位装备；移动已上阵武将会交换阵位及装备。主角必须留在阵中。",
    "remove-general": "移除此闲置武将及其培养进度，不返还材料或碎片。可通过本次操作的备份恢复。",
  }[action];
  $("manager").showModal();
}

async function submitManagement() {
  if (submitting || pendingGrant) throw new Error("请先确认上一次 GM 操作的结果。");
  const { account, action, item } = management, data = {
    action, operation_id: crypto.randomUUID().replaceAll("-", ""), revision: account.revision, reason: $("manager-reason").value.trim(),
    ...(action === "inventory" ? { cid: item.item_id, count: Number($("manager-value").value) } : { iid: item.iid }),
  };
  if (action === "general-level") data.level = Number($("manager-value").value);
  if (action === "formation") data.position = Number($("manager-value").value);
  if (!data.reason) { $("manager-reason").focus(); return; }
  rememberGrant({ account: account.id, data }); $("manager").close();
  await sendGmOperation();
}

function renderBusiness(detail, data) {
  if (!data.recharge) { detail.append(node("p", "角色尚无可查询的业务状态。", "empty")); return; }
  const r = data.recharge;
  detail.append(section("模拟充值", fields([["累计金额", `¥ ${number(r.rmb)}`], ["充值 VIP", r.vip], ["当前订单", r.order || "无"],
    ["订单档位 / 状态", `${r.tier == null ? "—" : `¥ ${r.tier}`} / ${r.order_status}`], ["首充奖励", r.first], ["月卡剩余天数", r.month_days],
    ["月卡今日奖励", r.month_claim], ["终身卡", r.forever ? "已开通" : "未开通"], ["终身卡今日奖励", r.forever_claim],
    ["月卡累计金额", `¥ ${r.card_rmb}`], ["已购档位 ID", r.bought.join("、") || "无"], ["已领月卡礼包 ID", r.card_gifts.join("、") || "无"]])));
  detail.append(section("活动领取", table(data.activities, [["活动", (r) => r.name], ["ID", (r) => r.id], ["状态", (r) => r.status], ["进度", (r) => r.target ? `${r.progress} / ${r.target}` : "—"]])));
  detail.append(fields([["消费活动累计元宝", number(data.consumption.gold_spent)], ["已领消费奖励 ID", data.consumption.claimed.join("、") || "无"]]));
  detail.append(section("折扣礼包购买", table(Object.entries(data.consumption.purchases), [["礼包 ID", (r) => r[0]], ["已购数量", (r) => r[1]]])));
  detail.append(section("招募", table(data.recruit, [["卡池", (r) => ({ 1: "普通", 2: "高级", 3: "神将", 4: "封神" }[r.pool])], ["免费次数", (r) => r.freetimes],
    ["付费单抽", (r) => r.consumtimes], ["十连计数", (r) => r.tentimes], ["累计消耗", (r) => r.consum], ["下次免费", (r) => r.pool === 2 || r.pool === 3 ? r.next_free_at * 1000 <= Date.now() ? "可用" : date(r.next_free_at) : "无免费抽取"]])));
  detail.append(section(`封神待领取（已刷新 ${data.refreshes} 次）`, table(data.pending, [["物品", (r) => r.name], ["配置 ID", (r) => r.cid], ["数量", (r) => r.count]])));
}

function renderMaintenance(detail, row) {
  const credentials = node("section", undefined, "credentials");
  credentials.append(node("h3", "登录账号"), node("p", row.registered ? "已启用密码登录。" : "设置密码后，使用账号编号登录游戏，已有进度将保留。"));
  if (!row.registered) {
    const form = node("form");
    for (const [id, labelText] of [["account-password", "密码"], ["account-password-confirm", "确认密码"]]) {
      const label = node("label", labelText), input = node("input"); label.htmlFor = id; input.id = id; input.type = "password"; input.autocomplete = "new-password";
      input.minLength = 8; input.maxLength = 64; input.pattern = "[\\x21-\\x7e]{8,64}"; input.required = true; input.disabled = row.online;
      input.title = "8–64 位英文字母、数字或符号，不含空格"; form.append(label, input);
    }
    const submit = node("button", row.has_save ? "绑定密码，保留进度" : "创建登录账号", "primary"); submit.disabled = row.online;
    form.append(node("p", "密码须为 8–64 位英文字母、数字或符号，不含空格。"), submit);
    form.onsubmit = (event) => { event.preventDefault(); run(async () => {
      const password = form.querySelector("#account-password").value;
      if (password !== form.querySelector("#account-password-confirm").value) throw new Error("两次密码不一致。");
      submit.disabled = true;
      try {
        const result = await api(`/api/accounts/${row.id}/credentials`, { password, revision: row.revision });
        form.reset(); message(result.audit_warning || `账号 ${row.id} 已启用密码登录。`);
        await loadAccounts(); if (state.account === row.id && state.page === "accounts") await loadAccount(row.id, "maintenance");
      } finally { submit.disabled = row.online; }
    }); };
    credentials.append(form);
  }
  detail.append(credentials);
  const maintenance = node("section", undefined, "maintenance"), actions = node("div", undefined, "actions");
  maintenance.append(node("h3", "离线维护"), node("p", row.online ? `当前连接 ${row.connection.address}，请先退出游戏后再维护。` : "重置或恢复前自动备份。重置引导保留角色、背包和奖励领取记录。"));
  for (const [label, action, css] of [["创建备份", "backup", ""], ["重置引导", "reset-guide", ""], ["重置账号", "reset", "danger"]]) {
    const control = button(label, () => maintain(row, action), css); control.disabled = row.online || !row.has_save; actions.append(control);
  }
  if (row.has_save) { const download = link("下载存档", `/api/accounts/${row.id}/download`, "button"); download.download = `account-${row.id}.json`; actions.append(download); }
  maintenance.append(actions);
  const restore = node("div", undefined, "restore"), label = node("label", "恢复已有备份"), select = node("select"), inline = node("div", undefined, "inline");
  label.htmlFor = "backup-id"; select.id = "backup-id";
  row.backups.forEach((backup) => { const option = node("option", `${date(backup.created_at)} · ${backup.id.slice(0, 8)}`); option.value = backup.id; select.append(option); });
  if (!row.backups.length) select.append(node("option", "暂无备份"));
  select.disabled = row.online || !row.backups.length;
  const control = button("恢复备份", () => maintain(row, "restore", select.value)); control.disabled = select.disabled;
  inline.append(select, control); restore.append(label, inline); maintenance.append(restore); detail.append(maintenance);
}
async function maintain(row, action, backupId) {
  const label = info.actions[action];
  if (action !== "backup" && !confirm(`对账号 ${row.id}「${row.name}」执行${label}？\n当前存档会先备份。${action === "reset" ? "全部游戏进度将清空。" : ""}`)) return;
  const controls = [...$("account-detail").querySelectorAll("button")]; controls.forEach((b) => { b.disabled = true; });
  try { const result = await api(`/api/accounts/${row.id}`, { action, revision: row.revision, backup_id: backupId }); message(result.audit_warning || `账号 ${row.id}：${label}完成。`); }
  finally { await loadAccounts(); if (state.account === row.id && state.page === "accounts") await loadAccount(row.id, "maintenance"); }
}

function grantLock() {
  const usable = gmTarget && !gmTarget.online && gmTarget.has_role && !gmTarget.error;
  $("gm-fields").disabled = submitting || !!pendingGrant || !usable;
  $("gm-account").disabled = submitting || !!pendingGrant;
  $("gm-target-form").querySelector("button").disabled = submitting || !!pendingGrant;
  $("gm-submit").disabled = submitting || (!pendingGrant && !usable);
  $("gm-submit").textContent = submitting ? "正在处理…" : pendingGrant ? "按原编号查询 / 重试" : "执行 GM 操作";
  $("gm-retry").hidden = !pendingGrant;
  $("gm-retry").textContent = pendingGrant ? `账号 ${pendingGrant.account} · ${info?.actions[pendingGrant.data.action || "grant"] || "GM 操作"} · ${pendingGrant.data.operation_id} 尚待确认。重试使用原编号，不会重复执行。` : "";
  $("operation-pending").hidden = !pendingGrant || state.page === "gm";
  $("operation-pending").replaceChildren(...(pendingGrant ? [document.createTextNode(`账号 ${pendingGrant.account} 有一项待确认操作。`), link("查看结果 / 重试", `#gm/${pendingGrant.account}`)] : []));
  document.querySelectorAll("[data-gm-action]").forEach((b) => { b.disabled = submitting || !!pendingGrant || b.dataset.unavailable === "true"; });
}
function rememberGrant(value) {
  pendingGrant = value;
  try { if (value) sessionStorage.setItem("gm-pending", JSON.stringify(value)); else sessionStorage.removeItem("gm-pending"); } catch { /* 回执仍保留在内存与服务端流水中。 */ }
  grantLock();
}
async function loadGmAccount(id) {
  const request = ++gmRequest; gmTarget = null; grantLock();
  $("gm-identity").textContent = `正在读取账号 ${id}…`;
  const row = await api(`/api/accounts/${id}`);
  if (request !== gmRequest || state.page !== "gm") return;
  gmTarget = row;
  $("gm-identity").replaceChildren(link(`账号 ${row.id} · ${row.name}`, `#account/${row.id}/summary`), document.createTextNode(`　等级 ${number(row.level)}　`), badge(row.online ? "在线" : "离线", row.online ? "online" : ""));
  if (row.error || row.online || !row.has_role) $("gm-identity").append(node("p", row.error || (row.online ? "请先退出游戏，再读取玩家。" : "请先在游戏内创建角色。"), "error"));
  for (const key of Object.keys(resources)) $(`current-${key}`).textContent = `当前 ${number(row[key])}`;
  grantLock(); renderPreview();
}
async function loadCatalog(offset = 0) {
  const request = ++catalogRequest;
  const result = await api(`/api/catalog?${new URLSearchParams({ q: $("catalog-query").value.trim(), kind: $("catalog-kind").value, offset })}`);
  if (request !== catalogRequest) return;
  state.catalogOffset = offset;
  $("catalog-rows").replaceChildren(table(result.rows, [["物品", (r) => { const span = node("span", r.name); span.title = r.description; return span; }], ["ID / 类型", (r) => `${r.cid} / ${r.kind}`],
    ["操作", (r) => button("添加", () => addItem(r))]], "未找到物品，请修改名称、ID 或类型。"));
  pager("catalog", offset, result.total);
}
function addItem(item) {
  if (!cart.some((r) => r.cid === item.cid)) cart.push({ ...item, count: 1 });
  renderCart();
}
function renderCart() {
  $("cart-count").textContent = `${cart.length} 种`;
  $("gm-cart").replaceChildren(table(cart, [["物品", (r) => r.name || String(r.cid)], ["数量", (r) => {
    const input = node("input"); input.type = "number"; input.min = "1"; input.max = r.max || 1000000; input.step = "1"; input.required = true; input.value = r.count;
    input.setAttribute("aria-label", `${r.name || r.cid}数量`); input.oninput = () => { r.count = Number(input.value); renderPreview(); }; return input;
  }], ["操作", (r) => button("移除", () => { cart = cart.filter((item) => item.cid !== r.cid); renderCart(); })]], "从左侧目录添加本次要发放的物品。"));
  renderPreview();
}
function renderPreview() {
  const rows = Object.entries(resources).filter(([key]) => Number($(`gm-${key}`).value)).map(([key, name]) => {
    const delta = Number($(`gm-${key}`).value); return { name, change: `${delta > 0 ? "+" : ""}${number(delta)}`, after: gmTarget ? number(gmTarget[key] + delta) : "—" };
  });
  $("gm-preview").replaceChildren(table(rows, [["资源", (r) => r.name], ["调整", (r) => r.change], ["预计余额（未计离线恢复）", (r) => r.after]], cart.length ? `将发放 ${cart.length} 种物品，实际入账见执行结果。` : "填写资源或选择物品后，在此核对调整。"));
}
async function submitGrant() {
  if (submitting) return;
  if (!pendingGrant) {
    if (!gmTarget || gmTarget.id !== Number($("gm-account").value)) throw new Error("请先读取目标玩家。");
    const deltas = Object.fromEntries(Object.keys(resources).map((key) => [key, Number($(`gm-${key}`).value)]).filter(([, value]) => value !== 0));
    if (!Object.keys(deltas).length && !cart.length) throw new Error("至少填写一项资源变更或添加一种物品。");
    rememberGrant({ account: gmTarget.id, cart: cart.map((item) => ({ ...item })), data: {
      operation_id: crypto.randomUUID().replaceAll("-", ""), revision: gmTarget.revision, reason: $("gm-reason").value.trim(),
      resources: deltas, items: cart.map(({ cid, count }) => ({ cid, count })),
    } });
  }
  await sendGmOperation();
}
async function sendGmOperation() {
  const request = pendingGrant, origin = location.hash; submitting = true; grantLock();
  try {
    const result = await api(`/api/accounts/${request.account}/gm`, request.data);
    if (result.status === "pending") {
      $("gm-result").hidden = false;
      $("gm-result").replaceChildren(node("h2", "操作结果待核对"), node("p", "服务在执行期间中断。请在操作记录中核对变更与备份；此编号不会再次执行。"), link("查看记录", `#operations/${request.account}`),
        button("结束本次查询", () => { rememberGrant(null); $("gm-form").reset(); cart = []; renderCart(); return loadGmAccount(request.account); }));
      return;
    }
    rememberGrant(null);
    if (result.status === "failed") throw new Error(result.error || "此操作已失败，请重新填写。");
    cart = []; $("gm-form").reset(); renderCart();
    $("gm-result").hidden = false;
    $("gm-result").replaceChildren(node("h2", `账号 ${request.account} 操作成功`), node("p", result.audit_warning || "已保存。重登游戏后可看到最新资源与物品。"),
      fields([["操作类型", info.actions[result.action]], ["操作编号", result.id], ["备份编号", result.backup_id]]), changeTable(result.changes),
      link("返回玩家档案", `#account/${request.account}/${request.data.action === "inventory" ? "inventory" : "roster"}`), document.createTextNode(" · "), link("查看此玩家记录", `#operations/${request.account}`));
    message(result.audit_warning || `账号 ${request.account}：GM 操作已完成。`);
    if (state.page === "gm") await loadGmAccount(request.account);
    if (state.page === "accounts" && location.hash === origin && state.account === request.account) await loadAccount(request.account, origin.split("/")[2] || "summary");
  } catch (error) {
    if (error.status === 400) rememberGrant(null);
    throw error;
  } finally { submitting = false; grantLock(); }
}

function configNames() {
  if (!info) return;
  const patterns = { items: /prop|reward|liveness|begin7day/, units: /general|equip|skill|protagonist|formation/, business: /recruit|recharge|vip|card|firstpay/ };
  const pattern = patterns[$("config-category").value];
  $("config-names").replaceChildren(...info.config.tables.filter((name) => !pattern || pattern.test(name)).map((name) => node("option", name)));
}
async function loadConfigs(offset = 0) {
  const request = ++configRequest, name = $("config-name").value.trim();
  $("config-rows").replaceChildren(node("p", "正在读取配置…", "empty"));
  $("previous").disabled = $("next").disabled = true;
  const result = await api(`/api/configs/${encodeURIComponent(name)}?${new URLSearchParams({ q: $("config-query").value.trim(), offset })}`);
  if (request !== configRequest) return;
  state.configOffset = offset;
  $("config-rows").replaceChildren(...result.rows.map((row) => {
    const block = node("article", undefined, "config-row"), header = node("div", undefined, "inline"), actions = node("div", undefined, "actions");
    header.append(node("strong", `${row.id}　${row.value.name || row.value.desc || ""}`));
    actions.append(badge(row.changed ? "本地覆盖" : "原始配置", row.changed ? "pending" : ""));
    if (result.editor?.ids.includes(row.id)) actions.append(button("编辑", () => openEditor(result, row))); else actions.append(badge("只读"));
    header.append(actions);
    const details = node("details"); details.append(node("summary", "字段与原始值对比"));
    details.addEventListener("toggle", () => {
      if (!details.open || details.children.length > 1) return;
      details.append(table(Object.entries(row.value), [["字段", (r) => r[0]], ["原始值", (r) => node("span", valueText(row.original?.[r[0]]), "field-value")],
        ["当前值", (r) => node("span", valueText(r[1]), `field-value${JSON.stringify(row.original?.[r[0]]) !== JSON.stringify(r[1]) ? " changed" : ""}`)]]));
    });
    block.append(header, details); return block;
  }));
  if (!result.rows.length) $("config-rows").append(node("p", "未找到条目，请更换搜索条件。", "empty"));
  $("config-count").textContent = `${result.total} 条${result.total ? ` / ${offset + 1}–${offset + result.rows.length}` : ""}`;
  $("previous").disabled = offset === 0; $("next").disabled = offset + 50 >= result.total;
}
function openEditor(result, row) {
  editing = { result, row }; $("editor-title").textContent = `${result.editor.label} / ${row.id}`; $("edit-error").hidden = true;
  $("edit-fields").replaceChildren(...Object.entries(result.editor.fields).map(([field, rule]) => {
    const wrapper = node("div"), label = node("label", rule.label), input = node(["text", "reward"].includes(rule.type) ? "textarea" : "input");
    label.htmlFor = `field-${field}`; input.id = `field-${field}`; input.name = field; input.value = row.value[field] ?? ""; input.required = true;
    if (input.tagName === "INPUT") { input.type = "number"; input.min = "1"; input.max = rule.max; input.step = "1"; } else input.maxLength = rule.type === "reward" ? 2048 : 500;
    wrapper.append(label, input, node("small", `原始值：${row.original?.[field] ?? "—"}`)); return wrapper;
  }));
  $("revert-config").disabled = !row.changed; $("editor").showModal();
}
async function saveConfig(revert = false) {
  const { result, row } = editing;
  if (revert && !confirm(`恢复 ${result.name}/${row.id} 的原始配置？`)) return;
  const changes = {};
  for (const [field, rule] of Object.entries(result.editor.fields)) { const value = $(`field-${field}`).value; if (value !== String(row.value[field] ?? "")) changes[field] = rule.type === "int" ? Number(value) : value; }
  if (!revert && !Object.keys(changes).length) { $("editor").close(); return; }
  $("save-config").disabled = $("revert-config").disabled = true;
  try {
    const response = await api(`/api/configs/${result.name}`, { row_id: row.id, changes: revert ? null : changes, revision: result.revision });
    $("editor").close(); message(response.audit_warning || (revert ? "已恢复原配置。" : "配置已保存。")); await status(); await loadConfigs(state.configOffset);
  } catch (error) { $("edit-error").textContent = `${error.message} 配置变化时请关闭后重新查询。`; $("edit-error").hidden = false; }
  finally { $("save-config").disabled = false; $("revert-config").disabled = !row.changed; }
}

function changeTable(rows = []) { return table(rows, [["内容", (r) => r.name], ["变更前", (r) => valueText(r.before)], ["变更后", (r) => valueText(r.after)], ["实例 ID", (r) => r.iid || "—"]]); }
function operationTable(rows) {
  const result = table(rows, [["时间", (r) => node("time", date(r.at))], ["玩家", (r) => r.account == null ? "全局配置" : link(`账号 ${r.account}`, `#account/${r.account}/summary`)],
    ["操作", (r) => info.actions[r.action] || r.action], ["结果", (r) => badge({ success: "成功", failed: "失败", pending: "待核对" }[r.status] || r.status, r.status)],
    ["原因 / 详情", (r) => {
      const details = node("details", undefined, "log-details"); details.append(node("summary", r.reason));
      details.append(fields([["操作编号", r.id], ["操作者", "本机管理员"], ["备份编号", r.backup_id || r.result?.backup_id || "—"],
        ["原存档版本", r.before_revision || r.details?.revision || "—"], ["新版本", r.after_revision || r.result?.revision || "—"]]));
      if (r.details?.table) details.append(node("p", `配置 ${r.details.table} / ${r.details.row_id}`));
      if (r.details?.backup_id) details.append(node("p", `恢复来源 ${r.details.backup_id}`));
      if (r.error) details.append(node("p", r.error, "error"));
      if (r.status === "pending") details.append(node("p", "执行期间服务或日志写入中断，请结合当前状态和备份核对。", "pending"));
      const changes = r.changes || r.result?.changes; if (changes?.length) details.append(changeTable(changes));
      return details;
    }]], "暂无操作记录。GM 发放、账号维护及配置保存后会在这里留存结果。");
  result.classList.add("operation-table"); return result;
}
async function loadOperations(offset = 0) {
  const request = ++logRequest, since = $("operations-since").value, until = $("operations-until").value;
  const end = until ? new Date(`${until}T00:00:00`) : null; if (end) end.setDate(end.getDate() + 1);
  const result = await api(`/api/operations?${new URLSearchParams({ account: $("operations-account").value, action: $("operations-action").value,
    since: since ? new Date(`${since}T00:00:00`).getTime() / 1000 : 0, until: end ? end.getTime() / 1000 : 0, offset })}`);
  if (request !== logRequest) return;
  state.operationsOffset = offset; $("operations-rows").replaceChildren(operationTable(result.rows)); pager("operations", offset, result.total);
}

function addMailItem(item) {
  if (!mailCart.some((r) => r.cid === item.cid)) mailCart.push({ ...item, count: 1 });
  renderMailCart();
}
function renderMailCart() {
  $("mail-cart-count").textContent = `${mailCart.length} 种物品`;
  $("mail-cart").replaceChildren(table(mailCart, [
    ["物品", (r) => r.name || String(r.cid)],
    ["数量", (r) => {
      const input = node("input"); input.type = "number"; input.min = "1"; input.max = r.max || 1000000; input.step = "1"; input.required = true; input.value = r.count;
      input.setAttribute("aria-label", `${r.name || r.cid}数量`); input.oninput = () => { r.count = Number(input.value); }; return input;
    }],
    ["操作", (r) => button("移除", () => { mailCart = mailCart.filter((item) => item.cid !== r.cid); renderMailCart(); })]
  ], "从左侧目录添加本次要发放的物品。"));
}
async function loadMailCatalog(offset = 0) {
  const request = ++mailCatalogRequest;
  const result = await api(`/api/catalog?${new URLSearchParams({ q: $("mail-catalog-query").value.trim(), kind: $("mail-catalog-kind").value, offset })}`);
  if (request !== mailCatalogRequest) return;
  state.mailCatalogOffset = offset;
  $("mail-catalog-rows").replaceChildren(table(result.rows, [
    ["物品", (r) => { const span = node("span", r.name); span.title = r.description; return span; }],
    ["ID / 类型", (r) => `${r.cid} / ${r.kind}`],
    ["操作", (r) => button("添加", () => addMailItem(r))]
  ], "未找到物品，请修改名称、ID 或类型。"));
  pager("mail-catalog", offset, result.total);
}
function renderMailCommonItems() {
  if (!info || !info.common_items || $("mail-common-items").children.length) return;
  for (const item of info.common_items) {
    $("mail-common-items").append(button(item.name, () => addMailItem(item)));
  }
}
async function loadMails(offset = 0) {
  const request = ++mailRequest;
  const result = await api(`/api/mails?offset=${offset}&limit=25`);
  if (request !== mailRequest) return;
  state.mailOffset = offset;
  const columns = [
    ["编号", (r) => String(r.id)],
    ["目标", (r) => r.target === 0 ? badge("全服所有玩家", "online") : link(`账号 ${r.target}`, `#account/${r.target}/summary`)],
    ["邮件标题", (r) => r.title],
    ["正文说明", (r) => {
      const p = node("span", r.content || "（无正文）");
      p.title = r.content || "";
      return p;
    }],
    ["附件物品与充值", (r) => {
      const parts = [];
      if (r.card === 1) parts.push("【25元月卡】");
      else if (r.card === 2) parts.push("【98元终身卡】");
      if (r.attachments) {
        for (const [cid, cnt] of Object.entries(r.attachments)) {
          const item = info?.common_items?.find((it) => it.cid === Number(cid)) || {
            name: cid === "1001" ? "元宝" : cid === "1000" ? "银币" : cid === "1002" ? "体力" : cid === "1003" ? "精力" : cid === "1008" ? "贵族经验" : `物品${cid}`
          };
          parts.push(`${item.name || cid} x${number(cnt)}`);
        }
      }
      return parts.length ? parts.join("，") : "无附件";
    }],
    ["发送时间", (r) => date(r.created_at)],
    ["操作", (r) => button("撤回/删除", async () => {
      if (confirm(`确认撤回/删除系统邮件 #${r.id} (${r.title})？`)) {
        await api(`/api/mails/${r.id}/delete`, { reason: "GM 撤回邮件" });
        message(`系统邮件 #${r.id} 已删除。`);
        await loadMails(state.mailOffset);
      }
    })]
  ];
  $("mail-list-rows").replaceChildren(table(result.rows, columns, "暂无已发送的系统邮件。"));
  pager("mail-list", offset, result.total, 25);
}
async function loadMailsPage() {
  renderMailCommonItems();
  renderMailCart();
  await Promise.all([loadMailCatalog(0), loadMails(0)]);
}
async function submitSendMail(event) {
  event.preventDefault();
  const targetType = $("mail-target-type").value;
  const target = targetType === "all" ? 0 : Number($("mail-target-account").value);
  if (targetType === "single" && (!target || target < 1 || target > 1000)) {
    throw new Error("请指定 1~1000 的目标账号编号");
  }
  const title = $("mail-title").value.trim();
  if (!title) throw new Error("请填写邮件标题");
  const content = $("mail-content").value.trim();

  const rechargePreset = $("mail-recharge-preset").value;
  let rechargeInfo = { rmb: 0, gold: 0, card: 0 };
  if (rechargePreset === "25_card1") {
    rechargeInfo = { rmb: 25, gold: 250, card: 1 };
  } else if (rechargePreset === "98_card2") {
    rechargeInfo = { rmb: 98, gold: 980, card: 2 };
  } else if (rechargePreset === "6") {
    rechargeInfo = { rmb: 6, gold: 66, card: 0 };
  } else if (rechargePreset === "30") {
    rechargeInfo = { rmb: 30, gold: 330, card: 0 };
  } else if (rechargePreset === "68") {
    rechargeInfo = { rmb: 68, gold: 750, card: 0 };
  } else if (rechargePreset === "128") {
    rechargeInfo = { rmb: 128, gold: 1280, card: 0 };
  } else if (rechargePreset === "198") {
    rechargeInfo = { rmb: 198, gold: 2280, card: 0 };
  } else if (rechargePreset === "328") {
    rechargeInfo = { rmb: 328, gold: 3780, card: 0 };
  } else if (rechargePreset === "648") {
    rechargeInfo = { rmb: 648, gold: 7780, card: 0 };
  } else if (rechargePreset === "custom") {
    rechargeInfo = {
      rmb: Number($("mail-recharge-rmb").value) || 0,
      gold: Number($("mail-recharge-gold").value) || 0,
      card: 0
    };
  }

  const resources = {
    gold: Number($("mail-res-gold").value) || 0,
    coin: Number($("mail-res-coin").value) || 0,
    stamina: Number($("mail-res-stamina").value) || 0,
    energy: Number($("mail-res-energy").value) || 0
  };

  const reason = $("mail-reason").value.trim() || "GM 发送邮件";

  const payload = {
    target,
    title,
    content,
    resources,
    items: mailCart.map(({ cid, count }) => ({ cid, count })),
    recharge: rechargeInfo,
    reason
  };

  const result = await api("/api/mails", payload);
  message(`系统邮件 #${result.id} 发送成功！`);
  $("mail-title").value = "";
  $("mail-content").value = "";
  $("mail-res-gold").value = "";
  $("mail-res-coin").value = "";
  $("mail-res-stamina").value = "";
  $("mail-res-energy").value = "";
  $("mail-recharge-preset").value = "0";
  $("mail-recharge-custom-box").hidden = true;
  $("mail-recharge-gold-box").hidden = true;
  mailCart = [];
  renderMailCart();
  await loadMails(0);
}

async function route() {
  const [target = "overview", id, tab] = location.hash.slice(1).split("/");
  const page = target === "account" ? "accounts" : ["overview", "accounts", "gm", "mails", "configs", "operations"].includes(target) ? target : "overview";
  state.page = page; navigation++; accountRequest++; gmRequest++; mailRequest++; mailCatalogRequest++;
  grantLock();
  for (const name of ["overview", "accounts", "gm", "mails", "configs", "operations"]) {
    $(`${name}-page`).hidden = name !== page;
    if (name === page) $(`nav-${name}`).setAttribute("aria-current", "page"); else $(`nav-${name}`).removeAttribute("aria-current");
  }
  message("");
  if (page === "overview") return loadOverview();
  if (page === "accounts") {
    $("accounts-index").hidden = target === "account"; $("account-workspace").hidden = target !== "account";
    if (target === "account") return loadAccount(Number(id), tabs[tab] ? tab : "summary");
    return loadAccounts();
  }
  if (page === "gm") {
    const account = pendingGrant?.account || Number(id) || state.account;
    $("gm-account").value = account;
    if (pendingGrant) {
      cart = pendingGrant.cart || pendingGrant.data.items || [];
      for (const key of Object.keys(resources)) $(`gm-${key}`).value = pendingGrant.data.resources?.[key] || "";
      $("gm-reason").value = pendingGrant.data.reason; renderCart();
    }
    return Promise.all([loadGmAccount(account), loadCatalog(0)]);
  }
  if (page === "mails") return loadMailsPage();
  if (page === "configs") return loadConfigs(0);
  $("operations-account").value = id || ""; return loadOperations(0);
}

for (const [key, labelText] of Object.entries(resources)) {
  const wrapper = node("div"), label = node("label", labelText), input = node("input"), current = node("small", "请先读取玩家");
  label.htmlFor = `gm-${key}`; input.id = `gm-${key}`; input.type = "number"; input.step = "1"; input.min = "-2147483647"; input.max = "2147483647"; input.placeholder = "不变";
  current.id = `current-${key}`; input.oninput = renderPreview; wrapper.append(label, input, current); $("gm-resources").append(wrapper);
}
$("account-jump").onsubmit = (event) => { event.preventDefault(); location.hash = `account/${Number($("account-id").value)}/maintenance`; };
for (const id of ["account-search", "account-filter", "account-level"]) $(id).addEventListener("input", () => { state.accountOffset = 0; renderAccounts(); });
$("account-previous").onclick = () => { state.accountOffset = Math.max(0, state.accountOffset - 25); renderAccounts(); };
$("account-next").onclick = () => { state.accountOffset += 25; renderAccounts(); };
$("gm-account").oninput = () => { gmRequest++; gmTarget = null; $("gm-identity").textContent = "账号已改变，请重新读取玩家。"; grantLock(); };
$("gm-target-form").onsubmit = (event) => { event.preventDefault(); run(() => loadGmAccount(Number($("gm-account").value))); };
$("gm-form").onsubmit = (event) => { event.preventDefault(); run(submitGrant); };
$("close-manager").onclick = () => $("manager").close();
$("manage-form").onsubmit = (event) => { event.preventDefault(); run(submitManagement); };
$("catalog-search").onclick = () => run(() => loadCatalog(0));
$("catalog-query").onkeydown = (event) => { if (event.key === "Enter") { event.preventDefault(); run(() => loadCatalog(0)); } };
$("catalog-kind").onchange = () => run(() => loadCatalog(0));
$("catalog-previous").onclick = () => run(() => loadCatalog(Math.max(0, state.catalogOffset - 50)));
$("catalog-next").onclick = () => run(() => loadCatalog(state.catalogOffset + 50));
$("config-category").onchange = configNames;
$("config-search").onsubmit = (event) => { event.preventDefault(); run(() => loadConfigs(0)); };
$("previous").onclick = () => run(() => loadConfigs(Math.max(0, state.configOffset - 50)));
$("next").onclick = () => run(() => loadConfigs(state.configOffset + 50));
$("close-editor").onclick = () => $("editor").close();
$("edit-form").onsubmit = (event) => { event.preventDefault(); run(() => saveConfig()); };
$("revert-config").onclick = () => run(() => saveConfig(true));
$("operations-search").onsubmit = (event) => { event.preventDefault(); run(() => loadOperations(0)); };
$("operations-previous").onclick = () => run(() => loadOperations(Math.max(0, state.operationsOffset - 50)));
$("operations-next").onclick = () => run(() => loadOperations(state.operationsOffset + 50));
$("mail-target-type").onchange = () => { $("mail-target-account-box").hidden = $("mail-target-type").value !== "single"; };
$("mail-recharge-preset").onchange = () => {
  const isCustom = $("mail-recharge-preset").value === "custom";
  $("mail-recharge-custom-box").hidden = !isCustom;
  $("mail-recharge-gold-box").hidden = !isCustom;
};
$("mail-form").onsubmit = (event) => run(() => submitSendMail(event));
$("mail-catalog-search").onclick = () => run(() => loadMailCatalog(0));
$("mail-catalog-query").onkeydown = (event) => { if (event.key === "Enter") { event.preventDefault(); run(() => loadMailCatalog(0)); } };
$("mail-catalog-kind").onchange = () => run(() => loadMailCatalog(0));
$("mail-catalog-previous").onclick = () => run(() => loadMailCatalog(Math.max(0, state.mailCatalogOffset - 50)));
$("mail-catalog-next").onclick = () => run(() => loadMailCatalog(state.mailCatalogOffset + 50));
$("mail-refresh-list").onclick = () => run(() => loadMails(0));
$("mail-list-previous").onclick = () => run(() => loadMails(Math.max(0, state.mailOffset - 25)));
$("mail-list-next").onclick = () => run(() => loadMails(state.mailOffset + 25));
$("refresh").onclick = () => run(async () => { await status(); await route(); });
document.querySelector(".skip").onclick = (event) => { event.preventDefault(); $("main").focus(); };
window.addEventListener("hashchange", () => { if (info) run(route); });
renderCart();
run(async () => { await status(); await route(); });
