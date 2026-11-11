# session-2026.10.16-16.26-新增SVIP测试按钮

## 目标

云脚本新增接口 `MsGetPlayerPlusVipLevel(role_id)`，在示例工程中新增一个测试按钮用于调用它。

## 结论

按现有「运行环境测试」按钮的同款链路实现：UI 按钮 → 全局触发器绑定点击 → 发送云脚本消息 → 云脚本 `RegisterEvent` 处理 → `LogClient` 回显。

## 改动文件

| 文件 | 改动 |
|------|------|
| `maps/EntryMap/ui/panel_1.json` | 新增按钮节点「获取玩家SVIP等级」（uid `ab410010-0910-4e46-9a10-202610160001`，pos `1728.5625, 351.6346`，size `300x50`） |
| `maps/EntryMap/global_trigger/trigger/测试用例/获取玩家SVIP等级.json` | 新增触发器，trigger_id `2026101601`，子触发器 `402610601`，UI 事件名 `云脚本-获取玩家SVIP等级` |
| `maps/EntryMap/global_trigger/trigger/测试用例/index.txt` | 追加 `"获取玩家SVIP等级.json": 22` |
| `cloud_script/testcase/y3_testcase.lua` | 新增 `RegisterEvent("MsGetPlayerPlusVipLevel", ...)` |
| `cloud_script/meta.lua` | 新增接口签名与 `---@mock_diff` 注释 |
| `cloud_script/云脚本教程.md` | 玩家查询表新增该接口 |
| `ui_tree/panel_1_Tree.json` | 重跑 `gen_ui_tree.py` 生成 |
| `cloud_script/meta.lua`（对齐上游） | `_playerjoin` 第 4 参 `reason`→`data`；错误码类名 `MlRoomErrorCode`→`MlLuaErrorCode` 并补全 15 个枚举值（来源 `src/mlroom/lua/vm_base.hpp:65`）；`_roomloaded` 补「player_guids 实为 userdata」注记 |
| `cloud_script/testcase/y3_testcase.lua` | 局部常量表同步更名为 `MlLuaErrorCode` |
| `cloud_script/云脚本教程.md`（对齐上游） | `MlRoomErrorCode` 段落更名为 `MlLuaErrorCode`，补枚举完整取值范围说明 |

## 验证

- `panel_1.json` / 触发器 JSON / `index.txt` 均为合法 JSON，按钮节点与索引项齐备
- `hotfix_ui_editor` → 等待 3s → `save_editor`，保存后按钮节点仍在（编辑器已接受）
- `import_eca` 返回 `{"success": true, "mode": "新建", "trigger_id": 2026101601}`；随后 `save_editor` 后触发器文件与 `index.txt` 条目均保留
- 编辑器日志无 UI/触发器报错

## 已知事项

- 按钮文案、触发器名称、`meta.lua` 签名注释与教程 API 表统一用 SVIP（不写「附加VIP」，该字段对应平台 `is_plus_vip`）

## 实测结果（2026-10-16 18:45 游戏 session）

环境：`helper.launch_game` 启动游戏（client `BAIM(1)`），本地 MockMls + MockRoomSim，玩家 `role_id=1`。

| 测试点 | 方法 | 结果 |
|--------|------|------|
| 按钮存在且 uid 正确 | `helper.execute_lua` → `y3.ui.get_ui(p,'panel_1.获取玩家SVIP等级')` | ✅ 返回 `{UI|获取玩家SVIP等级|ab410010-0910-4e46-9a10-202610160001}` |
| 真实点击链路 | `y3runtime.trigger_ui_touch_event_by_path('panel_1.获取玩家SVIP等级','左键')` | ✅ 返回 `{"success": true}`，客户端日志随即出现 `msg=MsGetPlayerPlusVipLevel->0` |
| 云脚本返回值 | 点击后客户端 `mslog` 回显 | ✅ 本地 mock 返回 `0`，与 `---@mock_diff` 及教程「本地模拟服务固定为 0」一致 |
| 错误码 `ItemNotExisted` | 发 `MsConsumeItem itemID=999999999` | ✅ `code=12 reason=ItemNotExisted`，与枚举表一致（`MlLuaErrorCode` 更名后 reason 串仍能解析） |
| `_playerjoin` 第 4 参 | 云脚本日志 | ✅ `[4]={"plat_aid":"1"}(string)` → 确为 `data`，不是 `reason` |
| `_roomloaded` 第 4 参 | 云脚本日志 | ✅ `sol.std::vector<unsigned __int64...>(userdata)` → 确为 userdata，不是 table |

未实测（本地条件不具备）：`PlayerNotExist=3`、`ItemNotEnough=13`、`ItemNotUse=14`（本地 mock 玩家无道具，且测试 handler 会过滤非本机 `player_id`）；枚举 `1`、`4`~`11` 仅在 C++ 源码确认存在，未跑出对应分支。

对上游的更正（源码核对 + 本次实测）：

1. 枚举真名 `MlLuaErrorCode`，定义在 `src/mlroom/lua/vm_base.hpp`（不是上游注释写的 `mlroom.hpp`），完整取值 `0`~`14`；上游与项目旧 meta 都只列了 6 个
2. `_playerjoin` 回调第 4 参是 JSON 字符串 `data`：上游正确，项目旧 meta 误写 `reason`
3. `_roomloaded` 回调第 4 参实际是 `userdata`：上游 `player_roleids: integer[]` 与项目 `player_guids: integer[]` 都只是近似

## 复用要点

1. 新增测试按钮 = UI 节点 + 触发器 JSON + 云脚本事件处理 + `meta.lua` 签名（+ 文档）
2. 触发器 JSON 必须经 `import_eca` 进入编辑器，否则后续 `save_editor` 会删除该文件并回写 `index.txt`
3. 按钮 uid 沿用「固定前缀 + 日期序号」命名（如 `ab410010-0910-4e46-9a10-<日期><序号>`），触发器 id 沿用日期编号（如 `2026101601`）
