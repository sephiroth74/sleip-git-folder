--!strict
-- Git Folder: each window's focused pane's folder and its git branch, in
-- the window's status bar, looked at again as the pane, its folder or its
-- program changes, and a window's view drawn again only as what it shows
-- changes.

local place = require("./place")

local Plugin: Plugin = {}

-- The windows whose views showed, by their ids, and what each shows.
local views: { [WindowId]: place.Shown } = {}

-- The plugin's config, as it was read last.
local settings: place.Config = {}

-- Reads the config, and puts the view on the side that it names.
local function configure(cx: Cx)
    local read = cx.config()
    settings = if type(read) == "table" then read :: any else {}
    assert(cx.set_status_bar_side(settings.side or "start"))
end

-- What `window` shows: its focused pane's folder, of the program in its
-- foreground, and the branch of the repository that holds it.
local function look(cx: Cx, window: WindowId): place.Shown
    local tabs: { TabInfo } = cx.tabs(window) or {}
    for _, tab in tabs do
        if tab.active then
            local folder = cx.working_directory(tab.focused)
            if folder == nil then
                return {}
            end
            local branch = if settings.branch ~= false then cx.git_branch(folder) else nil
            return { folder = folder, branch = branch }
        end
    end
    return {}
end

-- Looks at each window that shows a view again, and draws again those
-- whose folder or branch changed.
local function refresh(cx: Cx)
    for window, shown in views do
        local now = look(cx, window)
        if not place.same(now, shown) then
            views[window] = now
            assert(cx.request_render({ status_bar = window }))
        end
    end
end

function Plugin.activate(cx: Cx)
    configure(cx)
    -- The focus moving to another pane or tab, a pane's folder or title
    -- changing, and a tab's program starting or ending, as a checkout of
    -- another branch does.
    assert(cx.subscribe({ "pane-focused", "tab-activated", "pane-changed", "tab-changed", "window-closed" }))
end

function Plugin.on_event(cx: Cx, events: { Event })
    for _, event in events do
        if event.kind == "window-closed" then
            views[event.window] = nil
        elseif event.kind == "config-changed" then
            configure(cx)
            for window in views do
                views[window] = look(cx, window)
                assert(cx.request_render({ status_bar = window }))
            end
            return
        end
    end
    refresh(cx)
end

function Plugin.render(cx: Cx, view: ViewId): Node?
    local window = (view :: any).status_bar
    if window == nil then
        return nil
    end
    local shown = look(cx, window)
    views[window] = shown
    return place.node(shown, settings)
end

return Plugin
