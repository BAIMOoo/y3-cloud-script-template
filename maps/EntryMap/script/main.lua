-- 游戏启动后会自动运行此文件

--在开发模式下，将日志打印到游戏中
if y3.game.is_debug_mode() then
	y3.config.log.toGame = true
	y3.config.log.level  = 'debug'
else
	y3.config.log.toGame = false
	y3.config.log.level  = 'info'
end


y3.game:event('键盘-按下', 'SPACE', function()
	-- 与ECA类似，lua环境发送和接收的信息都会被直接处理成table
	y3.game.send_mlscript_msg("LuaMsgEvent", {
		player = 1,
		msg = "这是一条来自lua的消息"
	})
end)



y3.game:event("玩家-收到云脚本消息", function (trg, data)
	local role_id = data.player
	local ename = data.mlscript_event_name
	local edata = data.mlscript_event_data

	if ename ~= "ClientLuaMsg" then return end

	print(edata.msg)
end)

-- 此文件内的代码可以被热重载
include '可重载的代码'
