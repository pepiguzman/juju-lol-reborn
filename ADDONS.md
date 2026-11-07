# addons

an addon is a lua file in `workspace/juju.lol reborn/addons/`, saved as `name.luau`. load it from misc > addons. everything you need is in `getgenv().juju`.

connections made with `juju.create_connection` get cleaned up when the addon unloads, so use that instead of `:Connect`.

## example

```lua
local juju = getgenv().juju

juju.create_tab(function()
    juju.create_section("main", 1, 1, 0)

    local toggle = juju.create_element("main", {name = "say hi on kill"}, {
        toggle = {flag = "hi_on_kill"}
    })
end)

juju.create_connection(juju.get_signal("on_player_died"), function(data)
    if juju.get_flag("hi_on_kill") then
        print("got one")
    end
end)

juju.on_unload(function()
    print("bye")
end)
```

## menu

| function | what it does |
|---|---|
| `create_tab(func)` | makes your addon's tab, build the ui inside `func` |
| `set_tab_text(text)` | renames your tab |
| `create_section(name, side, size, offset)` | `side` 1 = left, 2 = right. `size` 0-1, `offset` 0-0.9 |
| `create_element(section, info, elements)` | `section` is the section name. `info` = `{name = "..."}`. `elements` = `{toggle = {...}}`, `{slider = {flag, min, max, default, suffix}}`, `{dropdown = {flag, options, default, multi}}`, `{button = {}}` etc |
| `find_element(parent, name)` | gets an element that already exists |
| `get_flag(flag)` / `set_flag(flag, value)` / `get_flags()` | read and write menu values |

elements fire their own signals: `on_toggle_change`, `on_slider_change`, `on_dropdown_change`, `on_clicked`, `on_color_change`, `on_key_press`.

## game

| function | returns |
|---|---|
| `get_ragebot_target()` | current target |
| `set_ragebot_target(player, message)` | sets it, `nil` clears it. needs ragebot on |
| `get_player_status(player)` / `set_player_status(player, status)` | 1 neutral, 2 friendly, 3 enemy |
| `get_server_cframe()` / `get_client_cframe()` | where the server sees you vs where you are |
| `is_in_void()` / `is_auto_stomping()` / `is_purchasing()` | true or false |
| `get_ping()` | ping in ms |
| `purchase_item(item, ammo)` | buys from the shop (games with a shop) |
| `on_unload(func)` | runs when the addon unloads |

## signals

use with `get_signal(name)`, or `get_signals()` for all of them.

`on_ragebot_target_changed` `on_local_bullet_confirmed` `on_local_bullet_fired` `on_local_bullet_failed` `on_player_died` `on_player_knocked` `on_player_health_changed` `on_player_armor_changed` `on_player_added` `on_player_character_added` `on_player_tool_equipped` `on_player_status_changed` `on_local_health_changed` `on_local_armor_changed` `on_local_ammo_changed` `on_local_knocked` `on_local_reload` `on_local_reloading` `on_local_tool_equipped` `on_local_character_added` `on_local_character_loaded` `on_shot_at` `on_stomp`

if an addon errors it unloads itself and the error shows in a notification.
