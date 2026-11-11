-- 与ECA的情景类似，云脚本端处理的逻辑对于请求的来源没有特殊区别
RegisterEvent("LuaMsgEvent", function(event_id, role_id, event_name, evalue)
	local data = cjson.decode(evalue)
	local player_index = data.player
	if role_id ~= player_index then return end

	LogInfo("LuaMsgEvent->" .. data.msg)
	MsSendMlEvent(player_index, "ClientLuaMsg", cjson.encode({ msg = "来自云脚本，发往客户端lua环境的消息" }))
end)
