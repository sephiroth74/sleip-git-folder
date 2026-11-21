--!strict
-- The plugin's tests, which `sleip test` runs on a host of the tests: each
-- function of the table a test, of a host of its own, which fails at its
-- first error, as `assert` raises it.

local place = require("../src/place")

local test = {}

-- The folder of the tests' pane, in a repository of the branch `main`.
local FOLDER = "/Users/me/work/lokyr"

-- The texts of the view's parts, by their keys, and the folder's tooltip.
local function parts(node: Node?): ({ [string]: string }, string?)
    local texts: { [string]: string } = {}
    local tooltip: string? = nil
    local children: { Node } = if node ~= nil and node.children ~= nil then node.children else {}
    for _, child in children do
        local key = child.key :: string
        local inners: { Node } = child.children or {}
        for _, inner in inners do
            if inner.kind == "text" then
                texts[key] = inner.text :: string
            end
        end
        if key == "folder" then
            tooltip = child.tooltip
        end
    end
    return texts, tooltip
end

-- The tests' window's view of the status bar.
local function bar(host: TestHost): Node?
    return host.render({ status_bar = host.window() })
end

-- Whether the plugin asked for a render of its view since the last look.
local function rendered(host: TestHost): boolean
    for _, write in host.done() do
        if write.request_render ~= nil then
            return true
        end
    end
    return false
end

-- Whether the plugin read a pane's folder or a folder's branch since the
-- last look.
local function looked(host: TestHost): boolean
    for _, read in host.reads() do
        if type(read) == "table" and (read.working_directory ~= nil or read.git_branch ~= nil) then
            return true
        end
    end
    return false
end

-- The key of the view's first part.
local function first_part(node: Node?): string?
    local children: { Node } = if node ~= nil and node.children ~= nil then node.children else {}
    return if children[1] ~= nil then children[1].key :: string else nil
end

function test.the_bar_shows_the_folder_s_name_and_its_branch(host: TestHost)
    host.set_directory(FOLDER)
    host.set_git_branch(FOLDER, "main")
    host.activate()
    local texts, tooltip = parts(bar(host))
    assert(texts.folder == "lokyr", texts.folder)
    assert(tooltip == FOLDER, tooltip)
    assert(texts.branch == "main", texts.branch)
    -- At the bar's start, as the manifest and the config's default say.
    assert(host.status_bar_side() == "start")
end

function test.a_folder_out_of_a_repository_shows_its_name_alone(host: TestHost)
    host.set_directory("/tmp")
    host.activate()
    local texts = parts(bar(host))
    assert(texts.folder == "tmp" and texts.branch == nil)
end

function test.a_pane_of_no_folder_keeps_an_empty_view_at_the_bar_s_height(host: TestHost)
    host.activate()
    local node = bar(host)
    local texts = parts(node)
    assert(texts.folder == nil and texts.branch == nil)
    assert(first_part(node) == "empty", first_part(node))
end

function test.the_config_takes_parts_away_and_moves_the_view(host: TestHost)
    host.set_directory(FOLDER)
    host.set_git_branch(FOLDER, "main")
    host.set_config({ folder = false, side = "end" })
    host.activate()
    local texts = parts(bar(host))
    assert(texts.folder == nil and texts.branch == "main")
    assert(host.status_bar_side() == "end")
    -- Of no part left, an empty view, so that the bar stays.
    host.set_config({ folder = false, branch = false })
    host.events({})
    assert(first_part(bar(host)) == "empty")
    assert(host.status_bar_side() == "start")
    -- Out of a repository, of no folder's part, likewise.
    host.set_config({ folder = false })
    host.set_directory("/tmp")
    host.events({ { kind = "pane-changed", pane = 1, tab = host.tab() } })
    assert(first_part(bar(host)) == "empty")
end

function test.the_view_is_drawn_again_only_as_its_folder_or_branch_changes(host: TestHost)
    host.set_directory(FOLDER)
    host.set_git_branch(FOLDER, "main")
    host.activate()
    bar(host)
    host.done()
    -- A tab's change of nothing that the bar shows draws nothing.
    host.events({ { kind = "tab-changed", tab = host.tab() } })
    assert(not rendered(host), "nothing changed")
    -- A checkout of another branch, as its program ends.
    host.set_git_branch(FOLDER, "feature/blocks")
    host.events({ { kind = "tab-changed", tab = host.tab() } })
    assert(rendered(host), "the branch changed")
    local texts = parts(bar(host))
    assert(texts.branch == "feature/blocks")
    -- Another folder, as the shell moves.
    host.set_directory("/Users/me/notes")
    host.events({ { kind = "pane-changed", pane = 1, tab = host.tab() } })
    assert(rendered(host), "the folder changed")
    texts = parts(bar(host))
    assert(texts.folder == "notes" and texts.branch == nil)
end

function test.a_command_s_end_looks_at_the_branch_again(host: TestHost)
    host.set_directory(FOLDER)
    host.set_git_branch(FOLDER, "main")
    host.activate()
    bar(host)
    host.done()
    -- A quick checkout, which ends before the tab's program changes.
    host.set_git_branch(FOLDER, "feature/blocks")
    host.events({ { kind = "command-ended", pane = 1, command = 1 } })
    assert(rendered(host), "the branch changed")
    assert(parts(bar(host)).branch == "feature/blocks")
end

function test.a_change_of_a_tab_behind_reads_nothing(host: TestHost)
    host.set_directory(FOLDER)
    host.set_git_branch(FOLDER, "main")
    host.activate()
    bar(host)
    -- Another tab, behind the one that shows, its events heard.
    local behind = host.open_tab()
    host.events({})
    host.reads()
    host.events({ { kind = "tab-changed", tab = behind } })
    assert(not looked(host), "a tab behind")
    host.events({ { kind = "tab-changed", tab = host.tab() } })
    assert(looked(host), "the tab that shows")
end

function test.a_batch_of_a_new_config_and_a_closed_window_is_taken_whole(host: TestHost)
    host.set_directory(FOLDER)
    host.set_git_branch(FOLDER, "main")
    host.activate()
    bar(host)
    host.set_config({ side = "end" })
    host.events({ { kind = "window-closed", window = host.window() } })
    assert(host.status_bar_side() == "end")
    host.done()
    -- The closed window's view is forgotten, of no render after.
    host.set_git_branch(FOLDER, "feature/blocks")
    host.events({ { kind = "tab-changed", tab = host.tab() } })
    assert(not rendered(host), "a closed window")
end

function test.a_folder_s_name_is_its_path_s_last_part()
    assert(place.name("/Users/me/work/lokyr") == "lokyr")
    assert(place.name("/Users/me/work/lokyr/") == "lokyr")
    assert(place.name("/") == "/")
end

return test
