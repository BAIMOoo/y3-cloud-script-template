-- F8：检查云脚本运行环境，结果通过现有 mslog 消息显示。
y3.game:event('键盘-按下', 'F8', function (_, data)
    y3.game.send_mlscript_msg('MsIsProdEnv', {
        player = data.player:get_id(),
    })
end)

y3.game:event('键盘-按下', 'R', function ()
    print('你按下了R键！试试修改这句话，然后运行重载！')
    print('你有多种方法进行重载')
    print('1. 在游戏中输入 .rd')
    print('2. 如果你用《Y3开发助手》启动游戏，可以点击VSCode中的“重载”按钮')
    print('3. 执行代码 `y3.reload.reload()`')
    -- y3.reload.reload()
end)

-- 云脚本新功能体验按钮：点击后调用云脚本 Demo 事件，结果通过 mslog 显示在游戏内。
local CLOUD_DEMO_BUTTONS = {
    { button = 'Base64编解码演示', ui_event = '云脚本Demo-Base64', event = 'Base64Demo' },
    { button = '查看脚本运行统计', ui_event = '云脚本Demo-运行统计', event = 'ScriptRunStatDemo' },
    { button = '查看我的平台信息', ui_event = '云脚本Demo-平台信息', event = 'PlayerPlatInfoDemo' },
}

_cloud_demo_state = _cloud_demo_state or { buttons = {}, listeners = {} }
local demo_state = _cloud_demo_state

local function bind_cloud_demo_buttons()
    local local_player = y3.player.get_local()
    if not local_player then return end

    local root = y3.ui.get_ui(local_player, 'panel_1')
    for _, item in ipairs(CLOUD_DEMO_BUTTONS) do
        if not demo_state.buttons[item.button] then
            local button = root:get_child(item.button)
            if not button then
                print('[云脚本Demo] 未找到按钮：' .. item.button)
            else
                local event_id = button:add_event('左键-点击', item.ui_event)
                if event_id and event_id ~= '' then
                    demo_state.buttons[item.button] = true
                else
                    print('[云脚本Demo] 事件绑定失败：' .. item.button)
                end
            end
        end
    end
end

y3.game:event('游戏-初始化', bind_cloud_demo_buttons)

-- 热重载时如果界面已经初始化，立即补绑一次。
local bind_ok, bind_err = pcall(function ()
    if y3.player.get_local() then
        bind_cloud_demo_buttons()
    end
end)
if not bind_ok then
    print('[云脚本Demo] 初始化绑定失败：' .. tostring(bind_err))
end

for _, item in ipairs(CLOUD_DEMO_BUTTONS) do
    if not demo_state.listeners[item.ui_event] then
        y3.game:event('界面-消息', item.ui_event, function (trg, data)
            local local_player = y3.player.get_local()
            local trigger_player = data.player or local_player
            if not local_player or not trigger_player then return end
            if trigger_player:get_id() ~= local_player:get_id() then return end

            y3.game.send_mlscript_msg(item.event, {
                player = trigger_player:get_id(),
            })
        end)
        demo_state.listeners[item.ui_event] = true
    end
end
