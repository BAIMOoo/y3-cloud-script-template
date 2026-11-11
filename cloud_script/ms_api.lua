-- 这个文件对一些简单的函数做了基本的封装以便于使用

LogInfo = function(raw_string, ...)
	Log.info(string.format(tostring(raw_string), ...))
end

LogWarn = function(raw_string, ...)
	Log.warn(string.format(tostring(raw_string), ...))
end

LogError = function(raw_string, ...)
	Log.error(string.format(tostring(raw_string), ...))
end

LogDebug = function(raw_string, ...)
	Log.debug(string.format(tostring(raw_string), ...))
end

-- 发送一个mslog 事件到客户端
-- 便于测试，输入一些信息到客户端中
-- 地图正式上线后，需要注释掉
function LogClient(player_index, format, ...)
	local logMessage = string.format(format, ...)
	MsSendMlEvent(player_index, "mslog", cjson.encode({ msg = logMessage }))
end

function safeString(value)
	return value ~= nil and tostring(value) or "nil"
end

-- 发送一个事件到客户端, evalue 进行json序列化
-- 这是云脚本到客户端的下行消息，内容不得超过 MsSendMlEvent 的 10 KB（10,240 字节）限制。
function MsSendMlEventJson(player_index, eventName, evalue)
	local text = cjson.encode(evalue)
	LogDebug("同步脚本数据: player:%s event=%s evalue=%s", player_index, eventName, text)
	MsSendMlEvent(player_index, eventName, text)
end

-- 发送一个事件到客户端, evalue 为原始的字符串
-- 这是云脚本到客户端的下行消息，编码后的内容不得超过 10 KB（10,240 字节）。
function MsSendMlEventRaw(player_index, eventName, evalue)
	LogDebug("同步脚本数据: player:%s event=%s evalue=%s", player_index, eventName, evalue)
	MsSendMlEvent(player_index, eventName, cjson.encode({ msg = evalue }))
end
