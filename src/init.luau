--!strict
-- Git Folder: each window's focused pane's folder and its git branch, in
-- the window's status bar, looked at again as the window's pane, its folder
-- or its program changes, or a command ends there, and a window's view
-- drawn again only as what it shows changes.

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

-- The tab that `window` shows, as the host tells its tabs.
local function shown_tab(cx: Cx, window: WindowId): TabInfo?
    local tabs: { TabInfo } = cx.tabs(window) or {}
    for _, tab in tabs do
        if tab.active then
            return tab
        end
    end
    return nil
end

-- What `tab`, a window's shown tab, shows: its focused pane's folder, of
-- the program in its foreground, and the branch of the repository that
-- holds it.
local function look(cx: Cx, tab: TabInfo?): place.Shown
    if tab == nil then
        return {}
    end
    local folder = cx.working_directory(tab.focused)
    if folder == nil then
        return {}
    end
    local branch = if settings.branch ~= false then cx.git_branch(folder) else nil
    return { folder = folder, branch = branch }
end

function Plugin.activate(cx: Cx)
    configure(cx)
    -- The focus moving to another pane or tab, a pane's folder or title
    -- changing, a tab's program starting or ending, and a command's end,
    -- as a checkout of another branch, however quick.
    assert(cx.subscribe({
        "pane-focused",
        "tab-activated",
        "pane-changed",
        "tab-changed",
        "command-ended",
        "window-closed",
    }))
end

-- Takes a batch of events whole: the closed windows forgotten, the config
-- read again, then each window whose shown tab or pane the events name
-- looked at again, and drawn again if what it shows changed, or of a new
-- config.
function Plugin.on_event(cx: Cx, events: { Event })
    local configured = false
    local windows: { [WindowId]: boolean } = {}
    local tabs: { [TabId]: boolean } = {}
    local panes: { [PaneId]: boolean } = {}
    for _, event in events do
        if event.kind == "window-closed" then
            views[event.window] = nil
        elseif event.kind == "config-changed" then
            configured = true
        else
            local named = event :: any
            if named.window ~= nil then
                windows[named.window] = true
            end
            if named.tab ~= nil then
                tabs[named.tab] = true
            end
            if named.pane ~= nil then
                panes[named.pane] = true
            end
        end
    end
    if configured then
        configure(cx)
    end
    for window, shown in views do
        local tab = shown_tab(cx, window)
        local named = windows[window] or (tab ~= nil and (tabs[tab.id] or panes[tab.focused]))
        if configured or named then
            local now = look(cx, tab)
            if configured or not place.same(now, shown) then
                views[window] = now
                assert(cx.request_render({ status_bar = window }))
            end
        end
    end
end

function Plugin.render(cx: Cx, view: ViewId): Node?
    local window = (view :: any).status_bar
    if window == nil then
        return nil
    end
    local shown = look(cx, shown_tab(cx, window))
    views[window] = shown
    return place.node(shown, settings)
end

return Plugin
