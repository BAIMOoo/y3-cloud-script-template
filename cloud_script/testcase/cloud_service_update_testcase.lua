local function get_player(event_player_id, evalue)
	local data = cjson.decode(evalue)
	local player_index = data.player
	if event_player_id ~= player_index then
		return nil
	end
	return player_index
end

local function short_value(value)
	local text = safeString(value)
	if #text > 200 then
		return string.sub(text, 1, 200) .. "..."
	end
	return text
end

local function report(player_index, message)
	LogInfo("%s", message)
	if player_index and player_index >= 0 then
		LogClient(player_index, "%s", message)
	end
end

local function report_item_event(event_name, role_id, store_id, before_cnt, after_cnt)
	local message = string.format(
		"event=%s role=%s store=%s before=%s after=%s",
		event_name,
		safeString(role_id),
		safeString(store_id),
		safeString(before_cnt),
		safeString(after_cnt)
	)
	report(role_id, message)
end

local event_counts = {
	_obtain_item_notify = 0,
	_consume_item_notify = 0,
	_localmodeloaded = 0,
}

RegisterEvent("_obtain_item_notify", function(event_idx, role_id, event_name, store_id, before_cnt, after_cnt)
	event_counts._obtain_item_notify = event_counts._obtain_item_notify + 1
	report_item_event(event_name, role_id, store_id, before_cnt, after_cnt)
end)

RegisterEvent("_consume_item_notify", function(event_idx, role_id, event_name, store_id, before_cnt, after_cnt)
	event_counts._consume_item_notify = event_counts._consume_item_notify + 1
	report_item_event(event_name, role_id, store_id, before_cnt, after_cnt)
end)

RegisterEvent("_localmodeloaded", function(event_idx, role_id, event_name)
	event_counts._localmodeloaded = event_counts._localmodeloaded + 1
	LogInfo("event=%s role=%s", event_name, safeString(role_id))
end)

RegisterEvent("CloudEventStatus", function(event_id, player_id, event_name, evalue)
	local player_index = get_player(player_id, evalue)
	if not player_index then return end
	report(player_index, string.format(
		"cloud event counts: localmodeloaded=%d obtain=%d consume=%d",
		event_counts._localmodeloaded,
		event_counts._obtain_item_notify,
		event_counts._consume_item_notify
	))
end)

-- 可通过现有“OS接口调用”按钮运行，也可发送 MsIsProdEnv 事件。
-- 独立事件支持 expected_prod=true/false，按实际部署环境填写预期值。
local function test_prod_env(player_index, expected_prod)
	local prefix = "MsIsProdEnv: "
	if type(MsIsProdEnv) ~= "function" then
		report(player_index, prefix .. "FAIL 接口不存在，type=" .. type(MsIsProdEnv))
		return
	end
	local ok, result = pcall(MsIsProdEnv)
	if not ok then
		report(player_index, prefix .. "FAIL 调用异常=" .. short_value(result))
		return
	end
	report(player_index, prefix .. "result=" .. tostring(result) .. " type=" .. type(result))
	if type(result) ~= "boolean" then
		report(player_index, prefix .. "FAIL 预期返回 boolean")
		return
	end
	local repeat_ok, repeat_result = pcall(MsIsProdEnv)
	if not repeat_ok or repeat_result ~= result then
		report(player_index, prefix .. "FAIL 重复调用异常或结果不一致=" .. short_value(repeat_result))
		return
	end
	report(player_index, prefix .. "PASS 返回布尔值且重复调用一致；环境=" .. (result and "生产环境" or "非生产环境"))
	if expected_prod ~= nil then
		if type(expected_prod) ~= "boolean" then
			report(player_index, prefix .. "FAIL expected_prod 必须为 boolean")
			return
		end
		report(player_index, prefix .. (result == expected_prod and "PASS" or "FAIL") .. " 环境预期=" .. tostring(expected_prod) .. " 实际=" .. tostring(result))
	else
		report(player_index, prefix .. "未指定环境预期，请与实际部署环境核对")
	end
end

RegisterEvent("MsIsProdEnv", function(event_id, player_id, event_name, evalue)
	local player_index = get_player(player_id, evalue)
	if not player_index then return end
	local ok, result = pcall(MsIsProdEnv)
	if not ok then
		report(player_index, "云脚本运行环境：调用失败，" .. short_value(result))
		return
	end
	report(player_index, "云脚本运行环境：" .. (result and "线上环境" or "本地环境"))
end)

local os_fields = {
	"clock",
	"date",
	"difftime",
	"execute",
	"exit",
	"getenv",
	"remove",
	"rename",
	"setlocale",
	"time",
	"tmpname",
}

local safe_os_calls = {
	clock = function(fn) return fn() end,
	date = function(fn) return fn("!%Y-%m-%dT%H:%M:%SZ") end,
	difftime = function(fn) return fn(2, 1) end,
	getenv = function(fn) return fn("PATH") end,
	time = function(fn) return fn() end,
	tmpname = function(fn) return fn() end,
}

RegisterEvent("OsCapabilityProbe", function(event_id, player_id, event_name, evalue)
	local player_index = get_player(player_id, evalue)
	if not player_index then return end
	test_prod_env(player_index)

	local os_library = os
	report(player_index, "os capability probe: os=" .. type(os_library))

	for _, field_name in ipairs(os_fields) do
		local field_value = type(os_library) == "table" and os_library[field_name] or nil
		local call = safe_os_calls[field_name]
		if type(field_value) == "function" and call then
			local ok, result = pcall(call, field_value)
			report(player_index, string.format(
				"os.%s exists=function called=true success=%s result_type=%s result=%s",
				field_name,
				tostring(ok),
				type(result),
				short_value(result)
			))
		else
			report(player_index, string.format(
				"os.%s exists=%s called=false",
				field_name,
				type(field_value)
			))
		end
	end
end)

local function get_redis_client(player_index)
	if type(redis) ~= "table" or type(redis.get_redis_client) ~= "function" then
		report(player_index, "redis unavailable")
		return nil
	end

	local ok, client = pcall(redis.get_redis_client)
	if not ok then
		report(player_index, "redis.get_redis_client failed: " .. short_value(client))
		return nil
	end
	return client
end

local function redis_key(player_index, suffix)
	return string.format("cloud_script_test:%s:%s", tostring(player_index), suffix)
end

local incrby_init_state = {}
local incrby_init_waiters = {}

local function finish_incrby_initialization(player_index, success, message)
	incrby_init_state[player_index] = success and true or nil
	if message then
		report(player_index, message)
	end

	local waiters = incrby_init_waiters[player_index]
	incrby_init_waiters[player_index] = nil
	if not waiters then return end
	for _, callback in ipairs(waiters) do
		local callback_ok, callback_error = pcall(callback, success)
		if not callback_ok then
			report(player_index, "redis IncrBy waiter failed: " .. short_value(callback_error))
		end
	end
end

local function ensure_incrby_initialized(player_index, callback)
	if incrby_init_state[player_index] == true then
		if callback then callback(true) end
		return
	end

	if callback then
		local waiters = incrby_init_waiters[player_index]
		if not waiters then
			waiters = {}
			incrby_init_waiters[player_index] = waiters
		end
		waiters[#waiters + 1] = callback
	end

	if incrby_init_state[player_index] == "pending" then return end
	incrby_init_state[player_index] = "pending"

	local client = get_redis_client(player_index)
	if not client then
		finish_incrby_initialization(player_index, false, "redis IncrBy init failed: redis unavailable")
		return
	end

	local key = redis_key(player_index, "incrby")
	local ok, err = pcall(function()
		client:Get(key, function(get_ok, current_value)
			if not get_ok then
				finish_incrby_initialization(
					player_index,
					false,
					"redis IncrBy init Get failed: " .. short_value(current_value)
				)
				return
			end

			if current_value ~= nil then
				finish_incrby_initialization(
					player_index,
					true,
					"redis IncrBy init existing value=" .. short_value(current_value)
				)
				return
			end

			client:Set(key, 100, function(set_ok, set_value)
				finish_incrby_initialization(
					player_index,
					set_ok,
					string.format(
						"redis IncrBy init missing key; Set=100 success=%s value=%s",
						tostring(set_ok),
						short_value(set_value)
					)
				)
			end)
		end)
	end)
	if not ok then
		finish_incrby_initialization(player_index, false, "redis IncrBy init invocation failed: " .. short_value(err))
	end
end

RegisterEvent("_playerjoin", function(_, player_index)
	if player_index and player_index >= 0 then
		ensure_incrby_initialized(player_index)
	end
end)

RegisterEvent("RedisCallbackTest", function(event_id, player_id, event_name, evalue)
	local player_index = get_player(player_id, evalue)
	if not player_index then return end

	local client = get_redis_client(player_index)
	if not client then return end
	local key = redis_key(player_index, "callback")
	report(player_index, "redis callback test start key=" .. key)

	local ok, err = pcall(function()
		client:Set(key, 100, function(set_ok, set_value)
			report(player_index, string.format("redis callback Set success=%s value=%s", tostring(set_ok), short_value(set_value)))
			client:Get(key, function(get_ok, get_value)
				report(player_index, string.format("redis callback Get success=%s value=%s", tostring(get_ok), short_value(get_value)))
				client:IncrBy(key, 2, function(incr_ok, incr_value)
					report(player_index, string.format("redis callback IncrBy success=%s value=%s", tostring(incr_ok), short_value(incr_value)))
					client:Get(key, function(final_ok, final_value)
						report(player_index, string.format("redis callback final Get success=%s value=%s expected=102", tostring(final_ok), short_value(final_value)))
					end)
				end)
			end)
		end)
	end)
	if not ok then
		report(player_index, "redis callback invocation failed: " .. short_value(err))
	end
end)

RegisterEvent("RedisCoroutineTest", function(event_id, player_id, event_name, evalue)
	local player_index = get_player(player_id, evalue)
	if not player_index then return end

	local client = get_redis_client(player_index)
	if not client then return end
	local key = redis_key(player_index, "coroutine")
	local co = coroutine.create(function()
		local set_ok, set_value = client:Set(key, 200)
		report(player_index, string.format("redis coroutine Set success=%s value=%s", tostring(set_ok), short_value(set_value)))
		local get_ok, get_value = client:Get(key)
		report(player_index, string.format("redis coroutine Get success=%s value=%s", tostring(get_ok), short_value(get_value)))
		local incr_ok, incr_value = client:IncrBy(key, 3)
		report(player_index, string.format("redis coroutine IncrBy success=%s value=%s expected=203", tostring(incr_ok), short_value(incr_value)))
	end)

	local resume_ok, resume_error = coroutine.resume(co)
	report(player_index, string.format("redis coroutine started=%s detail=%s", tostring(resume_ok), short_value(resume_error)))
end)

RegisterEvent("RedisIncrByTest", function(event_id, player_id, event_name, evalue)
	local player_index = get_player(player_id, evalue)
	if not player_index then return end

	local key = redis_key(player_index, "incrby")
	report(player_index, "redis IncrBy test start key=" .. key)

	ensure_incrby_initialized(player_index, function(initialized)
		if not initialized then
			report(player_index, "redis IncrBy test skipped: key initialization failed")
			return
		end

		local client = get_redis_client(player_index)
		if not client then return end
		local ok, err = pcall(function()
			client:IncrBy(key, 2, function(incr_ok, incr_value)
				report(player_index, string.format("redis IncrBy success=%s value=%s", tostring(incr_ok), short_value(incr_value)))
				if not incr_ok then return end

				client:Get(key, function(get_ok, get_value)
					report(player_index, string.format("redis IncrBy final Get success=%s value=%s", tostring(get_ok), short_value(get_value)))
				end)
			end)
		end)
		if not ok then
			report(player_index, "redis IncrBy invocation failed: " .. short_value(err))
		end
	end)
end)

LogInfo("========================@云服务更新测试用例已经注册")

RegisterEvent("OsCapabilityDemo", function(_, player_id, _, evalue)
    local player = get_player(player_id, evalue); if not player then return end
    report(player, "os.clock=" .. short_value(os.clock()))
    report(player, "os.date=" .. short_value(os.date("!%Y-%m-%dT%H:%M:%SZ")))
    report(player, "os.difftime(2, 1)=" .. short_value(os.difftime(2, 1)))
    report(player, "os.time=" .. short_value(os.time()))
end)

local function get_global_archive_request(player_id, evalue)
    local player = get_player(player_id, evalue)
    if not player then return nil end

    local data = cjson.decode(evalue) or {}
    local key = data.key
    if type(key) ~= "string" or key:match("^%s*$") then
        report(player, "全局存档操作失败 key cannot be empty")
        return nil
    end
    return player, key, data.value
end

RegisterEvent("GlobalArchiveWriteDemo", function(_, player_id, _, evalue)
    local player, key, value = get_global_archive_request(player_id, evalue)
    if not player then return end
    if value == nil then value = "" end

    local client = get_redis_client(player)
    if not client then return end

    local ok, err = pcall(function()
        client:Set(key, value, function(set_ok, set_value)
            report(player, string.format(
                "写入云脚本全局存档 key=%s success=%s value=%s",
                key,
                tostring(set_ok),
                short_value(set_value)
            ))
        end)
    end)
    if not ok then
        report(player, "写入云脚本全局存档 invocation failed: " .. short_value(err))
    end
end)
RegisterEvent("GlobalArchiveReadDemo", function(_, player_id, _, evalue)
    local player, key = get_global_archive_request(player_id, evalue)
    if not player then return end

    local client = get_redis_client(player)
    if not client then return end

    local ok, err = pcall(function()
        client:Get(key, function(get_ok, value)
            report(player, string.format(
                "读取云脚本全局存档 key=%s success=%s value=%s",
                key,
                tostring(get_ok),
                short_value(value)
            ))
        end)
    end)
    if not ok then
        report(player, "读取云脚本全局存档 invocation failed: " .. short_value(err))
    end
end)

-- 开发者自检（不绑定游戏内按钮）：完整校验接口契约；UI 按钮使用文件末尾的 *Demo 事件。

-- Base64 编解码测试：标准向量、二进制安全、严格模式拒绝非法输入
RegisterEvent("Base64Test", function(_, player_id, _, evalue)
    local player = get_player(player_id, evalue)
    if not player then return end

    if type(MsBase64Encode) ~= "function" or type(MsBase64Decode) ~= "function" then
        report(player, "Base64Test: FAIL MsBase64Encode/MsBase64Decode unavailable")
        return
    end

    local pass_count, fail_count, failures = 0, 0, {}
    local hello_encoded, hello_decoded
    local binary_ok, strict_pass, strict_total = false, 0, 0
    local function check(name, ok, detail)
        if ok then
            pass_count = pass_count + 1
        else
            fail_count = fail_count + 1
            failures[#failures + 1] = name .. (detail and ("(" .. detail .. ")") or "")
        end
    end

    local vectors = {
        { "", "" },
        { "f", "Zg==" },
        { "fo", "Zm8=" },
        { "foo", "Zm9v" },
        { "hello", "aGVsbG8=" },
    }
    for _, vector in ipairs(vectors) do
        local encoded = MsBase64Encode(vector[1])
        check("encode:" .. short_value(vector[1]), encoded == vector[2], short_value(encoded))
        local decoded, err = MsBase64Decode(vector[2])
        check(
            "decode:" .. vector[2],
            decoded == vector[1] and err == nil,
            short_value(decoded) .. "/" .. short_value(err)
        )
        if vector[1] == "hello" then
            hello_encoded = encoded
            hello_decoded = decoded
        end
    end

    local binary_sample = "hello\0world\255"
    local encoded = MsBase64Encode(binary_sample)
    local decoded, decode_err = MsBase64Decode(encoded)
    binary_ok = (decoded == binary_sample and decode_err == nil)
    check("binary_roundtrip", binary_ok, short_value(encoded))

    local invalid_inputs = {
        "not-valid-base64!",
        "Zm9vYg=",
        "Zm9vYg",
        "Zm9vY",
        "Zm9vYmF=Zm9v",
        "Zm9v YmFv",
        "Zm9v\nYmFv",
        "Zm9vYmFv_",
        "Zm9vYmFv-",
    }
    for _, input in ipairs(invalid_inputs) do
        strict_total = strict_total + 1
        local bad_decoded, bad_err = MsBase64Decode(input)
        local rejected = (bad_decoded == nil and bad_err == "invalid base64 input")
        if rejected then
            strict_pass = strict_pass + 1
        end
        check(
            "strict_reject:" .. short_value(input),
            rejected,
            short_value(bad_decoded) .. "/" .. short_value(bad_err)
        )
    end

    report(player, string.format(
        "Base64 编解码：编码 \"hello\" -> %s；解码回 %s；二进制回环%s；严格模式 %d/%d 拒绝非法输入；结果 %s",
        short_value(hello_encoded),
        short_value(hello_decoded),
        binary_ok and "成功" or "失败",
        strict_pass,
        strict_total,
        fail_count == 0 and "PASS" or "FAIL"
    ))
    if fail_count > 0 then
        report(player, "Base64 编解码失败项：" .. table.concat(failures, ", "))
    end
end)

-- 脚本运行统计信息测试：验证 MsGetScriptRunStat 返回字段与类型
RegisterEvent("ScriptRunStatTest", function(_, player_id, _, evalue)
    local player = get_player(player_id, evalue)
    if not player then return end

    if type(MsGetScriptRunStat) ~= "function" then
        report(player, "脚本运行统计：当前云脚本环境未提供 MsGetScriptRunStat（请更新本地 MockMls/游戏包）")
        return
    end

    local call_ok, stat = pcall(MsGetScriptRunStat)
    if not call_ok then
        report(player, "脚本运行统计：调用失败，" .. short_value(stat))
        return
    end
    if type(stat) ~= "table" then
        report(player, "脚本运行统计：返回值类型错误，期望 table，实际 " .. type(stat) .. "，值=" .. short_value(stat))
        return
    end

    local fields = {
        "room_cur_max_tick_ms",
        "room_max_tick_ms_limit",
        "room_cur_tick_expired_count",
        "room_tick_expired_limit",
        "room_limit_ms_per_tick",
        "room_cur_script_memory",
        "room_script_memory_limit",
    }
    local failures = {}
    for _, field in ipairs(fields) do
        local value = stat[field]
        if value == nil then
            failures[#failures + 1] = field .. "=missing"
        elseif math.type(value) ~= "integer" then
            failures[#failures + 1] = field .. "=not_integer(" .. type(value) .. ")"
        elseif value < 0 then
            failures[#failures + 1] = field .. "=negative(" .. tostring(value) .. ")"
        end
    end

    report(player, string.format(
        "脚本运行统计：单帧最大耗时=%sms（上限 %sms）；tick 超时=%s 次（上限 %s 次，判定阈值 %sms）；脚本内存=%sB（上限 %sB）；结果 %s",
        safeString(stat.room_cur_max_tick_ms),
        safeString(stat.room_max_tick_ms_limit),
        safeString(stat.room_cur_tick_expired_count),
        safeString(stat.room_tick_expired_limit),
        safeString(stat.room_limit_ms_per_tick),
        safeString(stat.room_cur_script_memory),
        safeString(stat.room_script_memory_limit),
        #failures == 0 and "PASS" or "FAIL"
    ))
    if #failures > 0 then
        report(player, "脚本运行统计异常：" .. table.concat(failures, "; "))
    end
end)

-- 平台下发玩家信息接口测试：验证 20 个 MsGetPlayer* 接口的类型与越界 role_id 返回 nil
RegisterEvent("PlayerPlatInfoTest", function(_, player_id, _, evalue)
    local player = get_player(player_id, evalue)
    if not player then return end

    local getters = {
        { "地图等级", MsGetPlayerMapLevel, "integer" },
        { "地图等级排名", MsGetPlayerMapLevelRank, "integer" },
        { "游玩时长(秒)", MsGetPlayedTime, "integer" },
        { "游玩次数", MsGetPlayedCount, "integer" },
        { "附加VIP等级", MsGetPlayerPlusVipLevel, "integer" },
        { "地图VIP等级", MsGetPlayerMapVipLevel, "integer" },
        { "荣誉VIP", MsGetPlayerIsHonorVip, "boolean" },
        { "社区版主", MsGetPlayerIsCommunityMaster, "boolean" },
        { "社区点赞数", MsGetPlayerCommunityLikeCount, "integer" },
        { "社区精华帖数", MsGetPlayerCommunityElitePostCount, "integer" },
        { "社区回复数", MsGetPlayerCommunityReplyCount, "integer" },
        { "社区欢乐数", MsGetPlayerCommunityJoyCount, "integer" },
        { "社区发帖", MsGetPlayerCommunityPosted, "boolean" },
        { "社区主题数", MsGetPlayerCommunitySubjectCount, "integer" },
        { "签到天数", MsGetPlayerSigninDays, "integer" },
        { "最大连续签到", MsGetPlayerSigninMaxConsecutiveDays, "integer" },
        { "当前连续签到", MsGetPlayerSigninCurConsecutiveDays, "integer" },
        { "地图作者", MsGetPlayerIsAuthor, "boolean" },
        { "回归玩家", MsGetPlayerIsReturningPlayer, "boolean" },
        { "收藏当前地图", MsGetPlayerIsBookmarkCurrentMap, "boolean" },
    }

    local parts, failures, missing = {}, {}, {}
    for _, entry in ipairs(getters) do
        local label, fn, expected_type = entry[1], entry[2], entry[3]
        local display
        if type(fn) ~= "function" then
            display = "未提供"
            missing[#missing + 1] = label
            failures[#failures + 1] = label .. "=未提供"
        else
            local ok, result = pcall(fn, player)
            if not ok then
                display = "调用错误"
                failures[#failures + 1] = label .. "=调用错误(" .. short_value(result) .. ")"
            elseif (expected_type == "integer" and math.type(result) or type(result)) ~= expected_type then
                display = "类型错误"
                failures[#failures + 1] = label .. "=类型错误(期望" .. expected_type
                    .. "，实际" .. (math.type(result) or type(result)) .. ")"
            elseif expected_type == "boolean" then
                display = result and "是" or "否"
            else
                display = tostring(result)
            end
        end
        parts[#parts + 1] = label .. "=" .. display
    end

    report(player, "玩家平台信息：" .. table.concat(parts, "；"))

    local invalid_failures = {}
    for _, invalid_id in ipairs({ -1, 4294967297 }) do
        for _, entry in ipairs(getters) do
            local label, fn = entry[1], entry[2]
            if type(fn) == "function" then
                local ok, result = pcall(fn, invalid_id)
                if not ok then
                    invalid_failures[#invalid_failures + 1] = label .. "@" .. tostring(invalid_id) .. "=调用错误"
                elseif result ~= nil then
                    invalid_failures[#invalid_failures + 1] = label .. "@" .. tostring(invalid_id) .. "=" .. tostring(result)
                end
            end
        end
    end

    local reasons = {}
    if #missing > 0 then
        reasons[#reasons + 1] = "未提供 " .. #missing .. " 个接口：" .. table.concat(missing, "、")
    end
    local abnormal = {}
    for _, failure in ipairs(failures) do
        if not failure:find("=未提供", 1, true) then
            abnormal[#abnormal + 1] = failure
        end
    end
    if #abnormal > 0 then
        reasons[#reasons + 1] = "异常：" .. table.concat(abnormal, "；")
    end
    if #invalid_failures > 0 then
        reasons[#reasons + 1] = "越界 role_id 未返回 nil：" .. table.concat(invalid_failures, "；")
    end

    if #reasons == 0 then
        report(player, "玩家平台信息：结果 PASS（含越界 role_id 返回 nil）")
    else
        report(player, "玩家平台信息：结果 FAIL（" .. table.concat(reasons, "；") .. "）")
    end
end)

-- 错误码全局表测试：验证 MlLuaErrorCode 已导出且数值与文档一致
RegisterEvent("MlLuaErrorCodeTest", function(_, player_id, _, evalue)
    local player = get_player(player_id, evalue)
    if not player then return end

    if type(MlLuaErrorCode) ~= "table" then
        report(player, "错误码常量：当前云脚本环境未提供 MlLuaErrorCode（请更新本地 MockMls/游戏包）")
        return
    end

    local expected = {
        OK = 0,
        Unknown = 1,
        RoomNotExist = 2,
        PlayerNotExist = 3,
        EventKeyLen = 4,
        EventValueLen = 6,
        ItemNotExisted = 12,
        ItemNotEnough = 13,
        ItemNotUse = 14,
    }
    local names, failures = {}, {}
    for name, value in pairs(expected) do
        names[#names + 1] = name
        if MlLuaErrorCode[name] ~= value then
            failures[#failures + 1] = string.format(
                "%s expected=%d actual=%s",
                name,
                value,
                tostring(MlLuaErrorCode[name])
            )
        end
    end
    table.sort(names)

    local parts = {}
    for _, name in ipairs(names) do
        parts[#parts + 1] = name .. "=" .. tostring(MlLuaErrorCode[name])
    end
    report(player, "错误码常量：" .. table.concat(parts, "，") .. "；结果 "
        .. (#failures == 0 and "PASS" or "FAIL"))
    if #failures > 0 then
        report(player, "错误码常量异常：" .. table.concat(failures, "；"))
    end
end)

-- 云存档语义测试：有效玩家始终返回字符串（无档为 ""），无效 role_id 返回 nil
RegisterEvent("ArchiveSemanticsTest", function(_, player_id, _, evalue)
    local player = get_player(player_id, evalue)
    if not player then return end

    if type(MsGetScriptArchive) ~= "function" then
        report(player, "云存档读取：当前云脚本环境未提供 MsGetScriptArchive（请更新本地 MockMls/游戏包）")
        return
    end

    local failures = {}
    local read_ok, raw = pcall(MsGetScriptArchive, player)
    local valid_text
    if not read_ok then
        failures[#failures + 1] = "读取有效玩家失败(" .. short_value(raw) .. ")"
        valid_text = "读取失败"
    elseif type(raw) ~= "string" then
        failures[#failures + 1] = "有效玩家返回值类型错误(期望string，实际" .. type(raw) .. ")"
        valid_text = "类型错误"
    elseif raw == "" then
        valid_text = "当前为空档（返回空字符串）"
    else
        valid_text = string.format(
            "当前长度 %d 字节，内容前 50 字节：%s",
            #raw,
            short_value(string.sub(raw, 1, 50))
        )
    end

    local invalid_ok_all = true
    for _, invalid_id in ipairs({ -1, 4294967297 }) do
        local invalid_ok, invalid_value = pcall(MsGetScriptArchive, invalid_id)
        if not invalid_ok then
            invalid_ok_all = false
            failures[#failures + 1] = "读取无效角色 " .. tostring(invalid_id) .. " 调用失败"
        elseif invalid_value ~= nil then
            invalid_ok_all = false
            failures[#failures + 1] = "无效角色 " .. tostring(invalid_id)
                .. " 未返回 nil（实际 " .. type(invalid_value) .. "）"
        end
    end

    local save_text
    if type(raw) == "string" then
        local save_ok, saved = pcall(MsSaveScriptArchive, player, raw)
        if not save_ok or saved ~= true then
            save_text = "保存失败"
            failures[#failures + 1] = "保存原内容失败(" .. short_value(saved) .. ")"
        else
            local verify_ok, verify_raw = pcall(MsGetScriptArchive, player)
            if not verify_ok or verify_raw ~= raw then
                save_text = "回读不一致"
                failures[#failures + 1] = "保存后回读内容不一致"
            else
                save_text = "保存/回读一致"
            end
        end
    else
        save_text = "跳过保存检查"
    end

    report(player, string.format(
        "云存档读取：%s；无效角色返回 nil：%s；%s；结果 %s",
        valid_text,
        invalid_ok_all and "是" or "否",
        save_text,
        #failures == 0 and "PASS" or "FAIL"
    ))
    if #failures > 0 then
        report(player, "云存档读取异常：" .. table.concat(failures, "；"))
    end
end)

-- 以下事件供游戏内按钮使用：只展示功能效果，不做 PASS/FAIL 判定。

RegisterEvent("Base64Demo", function(_, player_id, _, evalue)
    local player = get_player(player_id, evalue)
    if not player then return end

    if type(MsBase64Encode) ~= "function" or type(MsBase64Decode) ~= "function" then
        report(player, "Base64 演示：当前云脚本环境未开放该接口（请更新本地 MockMls/游戏包）")
        return
    end

    local text = "hello 云脚本"
    local encoded = MsBase64Encode(text)
    local decoded, err = MsBase64Decode(encoded)
    report(player, "Base64 演示：原文 = " .. text)
    report(player, "Base64 演示：编码 = " .. tostring(encoded))
    report(
        player,
        "Base64 演示：解码 = " .. tostring(decoded)
            .. (decoded == text and "（与原内容一致）" or ("（失败：" .. tostring(err) .. "）"))
    )
end)

RegisterEvent("ScriptRunStatDemo", function(_, player_id, _, evalue)
    local player = get_player(player_id, evalue)
    if not player then return end

    if type(MsGetScriptRunStat) ~= "function" then
        report(player, "脚本运行统计：当前云脚本环境未开放该接口（请更新本地 MockMls/游戏包）")
        return
    end

    local ok, stat = pcall(MsGetScriptRunStat)
    if not ok or type(stat) ~= "table" then
        report(player, "脚本运行统计：读取失败 " .. short_value(stat))
        return
    end

    report(player, string.format(
        "脚本运行统计：单帧最大耗时 %s ms（上限 %s ms）",
        safeString(stat.room_cur_max_tick_ms),
        safeString(stat.room_max_tick_ms_limit)
    ))
    report(player, string.format(
        "脚本运行统计：tick 超时 %s 次（上限 %s 次，判定阈值 %s ms）",
        safeString(stat.room_cur_tick_expired_count),
        safeString(stat.room_tick_expired_limit),
        safeString(stat.room_limit_ms_per_tick)
    ))

    local used = tonumber(stat.room_cur_script_memory)
    local limit = tonumber(stat.room_script_memory_limit)
    if used and limit then
        report(player, string.format(
            "脚本运行统计：脚本内存 %.2f MB（上限 %.2f MB）",
            used / 1024 / 1024,
            limit / 1024 / 1024
        ))
    else
        report(player, "脚本运行统计：脚本内存读取失败")
    end
end)

RegisterEvent("PlayerPlatInfoDemo", function(_, player_id, _, evalue)
    local player = get_player(player_id, evalue)
    if not player then return end

    local function read(fn)
        if type(fn) ~= "function" then
            return "未开放"
        end
        local ok, value = pcall(fn, player)
        if not ok then
            return "读取失败"
        end
        if value == nil then
            return "无数据"
        end
        if type(value) == "boolean" then
            return value and "是" or "否"
        end
        return tostring(value)
    end

    report(player, string.format(
        "我的平台信息：地图等级=%s，等级排名=%s，游玩时长=%s，游玩次数=%s",
        read(MsGetPlayerMapLevel),
        read(MsGetPlayerMapLevelRank),
        read(MsGetPlayedTime),
        read(MsGetPlayedCount)
    ))
    report(player, string.format(
        "我的平台信息：附加VIP=%s，地图VIP=%s，荣誉VIP=%s",
        read(MsGetPlayerPlusVipLevel),
        read(MsGetPlayerMapVipLevel),
        read(MsGetPlayerIsHonorVip)
    ))
    report(player, string.format(
        "我的平台信息：社区版主=%s，点赞=%s，精华帖=%s，回复=%s，欢乐=%s，发帖=%s，主题=%s",
        read(MsGetPlayerIsCommunityMaster),
        read(MsGetPlayerCommunityLikeCount),
        read(MsGetPlayerCommunityElitePostCount),
        read(MsGetPlayerCommunityReplyCount),
        read(MsGetPlayerCommunityJoyCount),
        read(MsGetPlayerCommunityPosted),
        read(MsGetPlayerCommunitySubjectCount)
    ))
    report(player, string.format(
        "我的平台信息：累计签到=%s，最大连续=%s，当前连续=%s，地图作者=%s，回归玩家=%s，收藏地图=%s",
        read(MsGetPlayerSigninDays),
        read(MsGetPlayerSigninMaxConsecutiveDays),
        read(MsGetPlayerSigninCurConsecutiveDays),
        read(MsGetPlayerIsAuthor),
        read(MsGetPlayerIsReturningPlayer),
        read(MsGetPlayerIsBookmarkCurrentMap)
    ))
end)
