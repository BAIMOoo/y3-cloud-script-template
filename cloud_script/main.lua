-- 使用cjson库来对数据进行序列化和反序列化
---@type cjson  
cjson = require("cjson")

-- 加载基础API
require('com_api')

-- 加载简单的工具函数
require('ms_api')

-- 常规的ECA演示
require("testcase.y3_testcase")
-- 使用lua时的演示
require("testcase.y3_lua_testcase")
-- 云服务更新后的事件、全局存档和运行环境能力测试
require("testcase.cloud_service_update_testcase")

