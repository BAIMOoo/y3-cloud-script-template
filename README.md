# Y3 云脚本参考模板

面向 Y3 作者的云脚本示例工程，包含云脚本服务端代码、游戏内功能体验按钮和开发者自检用例。

## 目录结构

- `cloud_script/`：云脚本服务端代码
  - `main.lua`：云脚本入口
  - `meta.lua`：接口类型提示，仅用于编辑器静态检查
  - `testcase/`：调用示例、开发者自检和游戏内 Demo 事件
  - `云脚本教程.md`：接口与使用说明
- `maps/EntryMap/`：示例地图工程
- `maps/EntryMap/script/可重载的代码.lua`：客户端 Lua 示例和游戏内 Demo 按钮绑定

## 使用方式

1. 使用 Y3 编辑器打开项目根目录。
2. 云脚本入口为 `cloud_script/main.lua`，按需修改或删除 `testcase` 下的示例模块。
3. 启动游戏后，可在游戏内使用以下功能体验按钮：
   - `Base64编解码演示`
   - `查看脚本运行统计`
   - `查看我的平台信息`

开发者自检事件（如 `Base64Test`、`PlayerPlatInfoTest`）不绑定游戏内按钮，供本地调试时手动发送。

## 注意事项

- `maps/EntryMap/script/y3/` 是编辑器提供的 Y3 Lua 框架目录，本仓库不包含，避免与上游框架版本耦合。
- `cloud_script/mls_log/`、`cloud_script/script_log/`、`cloud_script/mls_archive/` 是本地运行产物，不会提交。
- 如果本地 MockMls 或游戏包版本较旧，新接口可能提示“未开放”，请更新本地云脚本运行环境。
