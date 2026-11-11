# session-2026.11.05-11.48-新增二进制存档测试按钮

## 目标

云脚本玩家存档已支持写入二进制字节串，在示例工程新增一个测试按钮，验证包含 `\0` 的二进制数据写入后能按原长度、原内容读回。

## 结论

按现有测试按钮链路实现：UI 按钮 → 全局触发器绑定点击 → 发送 `MsSaveScriptArchiveBinary` 云脚本消息 → 云脚本生成 4 KB 二进制负载 → `MsSaveScriptArchive` 写入 → `MsGetScriptArchive` 读回逐字节比对 → `LogClient` 回显。

二进制负载为 `"Y3BIN\0" .. 0x00~0xFF 重复 16 次 .. "\0END\xFF"`，共 4107 字节，覆盖 NUL、控制字符和高位字节。

## 改动文件

| 文件 | 改动 |
|------|------|
| `maps/EntryMap/ui/panel_1.json` | 新增按钮「写入二进制存档」（uid `ab410010-0910-4e46-9a10-202611050001`，pos `1380, 501.6`，放在 Redis IncrBy 按钮正下方，size `300x50`） |
| `maps/EntryMap/global_trigger/trigger/测试用例/写入二进制存档.json` | 新增触发器，trigger_id `2026110501`，子触发器 `4026110501`，UI 事件名 `云脚本-写入二进制存档`，发送事件 `MsSaveScriptArchiveBinary` |
| `maps/EntryMap/global_trigger/trigger/测试用例/index.txt` | 由编辑器写入 `"写入二进制存档.json": 23` |
| `cloud_script/testcase/y3_testcase.lua` | 新增 `MsSaveScriptArchiveBinary` 事件处理、4 KB 负载构造、首字节差异定位 |
| `cloud_script/meta.lua` | `MsSaveScriptArchive` 补充二进制安全说明 |
| `cloud_script/云脚本教程.md` | 补充存档按字节写入、不会在首个 `\0` 截断的说明 |
| `ui_tree/panel_1_Tree.json` | 重跑 `gen_ui_tree.py` 生成 |

## 验证

- `panel_1.json`、触发器 JSON、`index.txt` 均为合法 JSON
- `read_problems_lua`：`y3_testcase.lua` 无问题；`meta.lua` 仅剩既有的 `Redis.get_redis_client` 类型提示警告
- `hotfix_ui_editor` → 等待 3s → `save_editor` 后按钮节点保留
- `import_eca` 返回 `{"success": true, "mode": "新建", "trigger_id": 2026110501}`；`save_editor` 后触发器文件与 `index.txt` 条目均保留
- 游戏内 `ui:send_event('云脚本-写入二进制存档')` 触发后客户端回显：
  `MsSaveScriptArchiveBinary-> saved=true len=4107 read_len=4107 match=true diff=none`
- 落盘校验：`cloud_script/mls_archive/1.json` Base64 解码后 4107 字节，头部 `59-33-42-49-4E-00`（`Y3BIN\0`），尾部 `00-45-4E-44-FF`（`\0END\xFF`）

## 踩坑

1. 新增触发器 JSON 不能先落盘再 `save_editor`：编辑器会把未导入的触发器文件连同 `index.txt` 条目一起回写删除。必须 `import_eca` 成功后再 `save_editor`。
2. `import_eca` 的路径必须指向实际存在的文件；文件被编辑器回写删除后，报错“文件不存在”是结果而不是原因。
3. `gen_ui_tree.py` 在 GBK 控制台输出 emoji 会抛 `UnicodeEncodeError`，需设置 `PYTHONIOENCODING=utf-8`。

## 复用要点

1. 二进制存档测试用 `string.char(0..255)` + `string.rep` 构造负载，`#payload` 和逐字节比较即可证明未被 C 字符串截断。
2. 客户端下行 `mslog` 只回显长度、匹配结果和首个差异位置，避免把 4 KB 二进制塞进 900 字节消息限制。
