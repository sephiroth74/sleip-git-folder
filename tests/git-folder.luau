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

function test.a_pane_of_no_folder_shows_nothing(host: TestHost)
    host.activate()
    assert(bar(host) == nil)
end

function test.the_config_takes_parts_away_and_moves_the_view(host: TestHost)
    host.set_directory(FOLDER)
    host.set_git_branch(FOLDER, "main")
    host.set_config({ folder = false, side = "end" })
    host.activate()
    local texts = parts(bar(host))
    assert(texts.folder == nil and texts.branch == "main")
    assert(host.status_bar_side() == "end")
    -- Of no part left, nothing.
    host.set_config({ folder = false, branch = false })
    host.events({})
    assert(bar(host) == nil)
    assert(host.status_bar_side() == "start")
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

function test.a_folder_s_name_is_its_path_s_last_part()
    assert(place.name("/Users/me/work/lokyr") == "lokyr")
    assert(place.name("/Users/me/work/lokyr/") == "lokyr")
    assert(place.name("/") == "/")
end

return test
