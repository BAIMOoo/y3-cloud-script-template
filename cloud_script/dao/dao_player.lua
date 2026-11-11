-- 定义一个玩家
MLSPlayer = {}
MLSPlayer.meta = {
    __index = MLSPlayer
}
function MLSPlayer:new()
    -- 关联对象和表
    local o = setmetatable({}, self.meta)

    -- 初始化房间信息
    o:constructor()
    return o
end

function MLSPlayer:constructor()
    -- 初始化玩家数据

    -- 脚本存档数据
    self.ms_data = {} 

    -- 玩家信息
    self.player_index = 0
    self.player_name = ""

    -- 玩家对局信息
    self.gold = 0

    -- 测试相关数据
    self.testapi_timer = nil
    self.testapi_index = 0  -- 测试API的索引
    self.testapi_round = 0
    self.testapi_json = nil
end

function MLSPlayer:dump()
    LogInfo("mlsplayer player_index=%d name=%s", self.player_index, self.player_name)
end

-- 测试API:MsGetScriptArchive
-- 玩家数据初始化
function MLSPlayer:init()
    
    -- 读取玩家脚本存档数据
    local hvalue = MsGetScriptArchive(self.player_index)
    LogDebug("player:%s load  msdata=%s", self.player_name, safeString(hvalue))
    if hvalue ~= nil and hvalue ~= '' then
        self.ms_data = cjson.decode(hvalue)
    end
end

function MLSPlayer:get_msdata(mkey)
    return self.ms_data[mkey]
end

function MLSPlayer:set_msdata(mkey, mvalue)
    self.ms_data[mkey] = mvalue
end

-- 测试API:MsSaveScriptArchive
-- 保存脚本存档
function MLSPlayer:save_msdata()
    local text = cjson.encode(self.ms_data)
    local result = MsSaveScriptArchive(self.player_index, text)
    LogDebug("player:%s save msdata=%s result=%s", self.player_name, text, safeString(result))
    return result
end
