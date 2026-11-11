RegisterEvent(
	"MsGetPlayerName",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		LogClient(player_index, "MsGetPlayerName->" .. MsGetPlayerName(player_index))
	end
)

RegisterEvent(
	"MsGetPlayerMapLevel",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		LogClient(player_index, "MsGetPlayerMapLevel->" .. tostring(MsGetPlayerMapLevel(player_index)))
	end
)

RegisterEvent(
	"MsGetPlayedTime",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		LogClient(player_index, "MsGetPlayedTime->" .. tostring(MsGetPlayedTime(player_index)))
	end
)


RegisterEvent(
	"MsGetPlayedCount",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		LogClient(player_index, "MsGetPlayedCount->" .. tostring(MsGetPlayedCount(player_index)))
	end
)

-- 开发者自检（不绑定 UI）：逐个 API 注册事件；UI 聚合演示见 PlayerPlatInfoDemo。
local plat_info_getters = {
	{ "MsGetPlayerPlusVipLevel", MsGetPlayerPlusVipLevel },
	{ "MsGetPlayerMapVipLevel", MsGetPlayerMapVipLevel },
	{ "MsGetPlayerIsHonorVip", MsGetPlayerIsHonorVip },
	{ "MsGetPlayerMapLevelRank", MsGetPlayerMapLevelRank },
	{ "MsGetPlayerIsCommunityMaster", MsGetPlayerIsCommunityMaster },
	{ "MsGetPlayerCommunityLikeCount", MsGetPlayerCommunityLikeCount },
	{ "MsGetPlayerCommunityElitePostCount", MsGetPlayerCommunityElitePostCount },
	{ "MsGetPlayerCommunityReplyCount", MsGetPlayerCommunityReplyCount },
	{ "MsGetPlayerCommunityJoyCount", MsGetPlayerCommunityJoyCount },
	{ "MsGetPlayerCommunityPosted", MsGetPlayerCommunityPosted },
	{ "MsGetPlayerCommunitySubjectCount", MsGetPlayerCommunitySubjectCount },
	{ "MsGetPlayerSigninDays", MsGetPlayerSigninDays },
	{ "MsGetPlayerSigninMaxConsecutiveDays", MsGetPlayerSigninMaxConsecutiveDays },
	{ "MsGetPlayerSigninCurConsecutiveDays", MsGetPlayerSigninCurConsecutiveDays },
	{ "MsGetPlayerIsAuthor", MsGetPlayerIsAuthor },
	{ "MsGetPlayerIsReturningPlayer", MsGetPlayerIsReturningPlayer },
	{ "MsGetPlayerIsBookmarkCurrentMap", MsGetPlayerIsBookmarkCurrentMap },
}

for _, item in ipairs(plat_info_getters) do
	local api_name, api_fn = item[1], item[2]
	if type(api_fn) == "function" then
		RegisterEvent(
			api_name,
			function(event_id, player_id, ename, evalue)
				local data = cjson.decode(evalue)
				local player_index = (data.player)
				if player_id ~= player_index then return end

				LogClient(player_index, api_name .. "->" .. tostring(api_fn(player_index)))
			end
		)
	end
end


RegisterEvent(
	"MsGetRoomLoadedTs",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		LogClient(player_index, "MsGetRoomLoadedTs->" .. tostring(MsGetRoomLoadedTs()))
	end
)

RegisterEvent(
	"MsGetRoomGameTime",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		LogClient(player_index, "MsGetRoomGameTime->" .. tostring(MsGetRoomGameTime()))
	end
)

RegisterEvent(
	"MsGetRoomPlayerCount",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		LogClient(player_index, "MsGetRoomPlayerCount->" .. tostring(MsGetRoomPlayerCount()))
	end
)


RegisterEvent(
	"MsGetPlayerItem",
	function(event_id, player_id, ename, evalue)
		Log.info(evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		local itemID = data.itemID
		LogClient(player_index, "MsGetPlayerItem-> " .. cjson.encode(MsGetPlayerItem(player_index, itemID) or {}))
	end
)

local ErrorCodeTable = MlLuaErrorCode or {
	OK = 0,
	Unknown = 1,
	RoomNotExist = 2,
	PlayerNotExist = 3,
	EventKeyLen = 4,
	EventValueLen = 6,
	ItemNotExisted = 12,
	ItemNotEnough = 13,
	ItemNotUse = 14
}

RegisterEvent(
	"MsConsumeItem",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		local itemID = data.itemID
		local amount = data.amount
		local res = MsTryConsumeItem(player_index, itemID, amount)
		local reasonStr = ""
		for key, value in pairs(ErrorCodeTable) do
			if value == res then
				reasonStr = key
				break
			end
		end

		LogClient(player_index, "MsConsumeItem-> " .. tostring(res) .. " " .. reasonStr)
	end
)

RegisterEvent(
	"MsGetScriptArchive",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		LogClient(player_index, "MsGetScriptArchive->" .. tostring(MsGetScriptArchive(player_index)))
	end
)

RegisterEvent(
	"MsSaveScriptArchive",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		LogClient(player_index,
			"MsSaveScriptArchive->" .. tostring(MsSaveScriptArchive(player_index, tostring(math.random(0, 10000000)))))
	end
)

RegisterEvent(
	"GenerateTimer",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		local timeout = data.timeout
		local is_loop = data.is_loop
		local timer_id = Timer.new_timer(timeout, function(id)
			LogClient(player_index, "计时器消息->" .. tostring(id))
			return is_loop
		end)
		LogClient(player_index, "GenerateTimer->" .. tostring(timer_id))
	end
)

RegisterEvent(
	"CancelTimer",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		local timer_id = data.timer_id
		local canceled = Timer.cancel_timer(timer_id)
		LogClient(player_index, "CancelTimer->" .. tostring(timer_id) .. " result=" .. tostring(canceled))
	end
)


local unregister_count = 0
local reg_event_id = RegisterEvent(
	"UnregisterTest",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if player_id ~= player_index then return end

		unregister_count = unregister_count + 1
		LogClient(player_index, "UnregisterTest->" .. tostring(unregister_count))
		if unregister_count >= 5 then
			LogClient(player_index, "UnregisterTest->注销事件")
			--UnRegisterEvent(reg_event_id)
			-- 注意：使用上面这种注释的写法的情况下，由于闭包创建时reg_event_id的值尚未返回，所以reg_event_id的值虽然已经声明，但尚未赋值，因此是nil
			-- 如果像此处这样，将回调函数声明放在RegisterEvent的调用过程中而非外部，又想要获得外面的变量，建议考虑把RegisterEvent的返回值保存在一个表中
			UnRegisterEvent(event_id)
		end
	end
)

RegisterEvent(
	"ReadArchive",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if (player_id ~= player_index) then return end

		LogClient(player_index, "ReadArchive->" .. tostring(MsGetScriptArchive(player_index)))
	end
)

RegisterEvent(
	"WriteArchive",
	function(event_id, player_id, ename, evalue)
		local data = cjson.decode(evalue)
		local player_index = (data.player)
		if (player_id ~= player_index) then return end

		local content = data.content
		-- 注意：存档是字符串格式，并且有上限
		LogClient(player_index, "WriteArchive->" .. tostring(MsSaveScriptArchive(player_index, content)))
	end
)

-- 房间完成初始化加载时触发
RegisterEvent('_roomloaded', function(event_id, role_id, event_name, player_roleids)
	LogInfo("======================@ _roomloaded")

	-- 注意，player_roleids 是一个userdata，如果想要获取其中的数据，可以使用遍历的方式获取
	for key, value in ipairs(player_roleids) do
		LogInfo(key, value)
	end
	-- 也可以直接使用索引访问
	LogInfo("直接使用索引访问：%d", player_roleids[1])
end)

-- 房间结束时触发
RegisterEvent('_roomover', function(...)
	LogInfo("======================@ _roomover")
	LogInfo(cjson.encode({ ... }))
end)

-- 玩家退出房间时触发
RegisterEvent('_playerexit', function(...)
	LogInfo("======================@ _playerexit")
	LogInfo(cjson.encode({ ... }))
end)

-- 玩家断线一段时间后触发
RegisterEvent('_playerleave', function(...)
	LogInfo("======================@ _playerleave")
	LogInfo(cjson.encode({ ... }))
end)

-- 玩家存档加载完成时触发
RegisterEvent('_playerjoin', function(...)
	LogInfo("======================@ _playerjoin")
	LogInfo(cjson.encode({ ... }))
end)

-- 玩家断线重连时触发
RegisterEvent('_playerreconnect', function(...)
	LogInfo("======================@ _playerreconnect")
	LogInfo(cjson.encode({ ... }))
end)

-- 当有物品信息发生变化时，会触发此事件
RegisterEvent("_item_info_changed", function(event_idx, role_id, event_name, store_id, before_cnt, after_cnt)
	LogInfo("======================@ _item_info_changed")
	LogInfo(cjson.encode({ event_idx, role_id, event_name, store_id, before_cnt, after_cnt }))
end)


LogInfo("========================@测试用例已经注册")
