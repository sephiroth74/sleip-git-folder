--!strict
-- What a window's status bar shows of its focused pane: the folder's name,
-- its whole path in a tooltip, and the branch of its git repository, each
-- after an icon, in the bar's secondary text.

local place = {}

-- What a window shows: its focused pane's folder and its branch, none of a
-- pane of no program or of a folder out of a repository.
export type Shown = {
    folder: string?,
    branch: string?,
}

-- The plugin's config, of its schema.
export type Config = {
    folder: boolean?,
    branch: boolean?,
    side: StatusBarSide?,
}

-- The name of the folder of the absolute path `path`: its last part, or
-- `/` of the root.
function place.name(path: string): string
    local trimmed = string.gsub(path, "/+$", "")
    if trimmed == "" then
        return "/"
    end
    return string.match(trimmed, "[^/]+$") or trimmed
end

-- Whether `a` and `b` show the same.
function place.same(a: Shown, b: Shown): boolean
    return a.folder == b.folder and a.branch == b.branch
end

-- An icon `icon` and a text `text`, side by side, of `key` and `tooltip`.
local function part(key: string, icon: string, text: string, tooltip: string?): Node
    local look: Style = { color = "text.secondary", text_size = "small" }
    local glyph: Node = { kind = "icon", key = key .. "-icon", icon = icon, style = look }
    local label: Node = { kind = "text", key = key .. "-text", text = text, style = look }
    return {
        kind = "container",
        key = key,
        tooltip = tooltip,
        layout = { direction = "row", gap = 4, align = "center" },
        children = { glyph, label },
    }
end

-- The view of `shown`, as `config` asks for its parts; of no part, a part
-- of no text, unseen, so that the bar keeps its height and the panes their
-- rows.
function place.node(shown: Shown, config: Config): Node
    local parts: { Node } = {}
    if config.folder ~= false and shown.folder ~= nil then
        table.insert(parts, part("folder", "folder", place.name(shown.folder), shown.folder))
    end
    if config.branch ~= false and shown.branch ~= nil then
        table.insert(parts, part("branch", "git-branch", shown.branch, nil))
    end
    if #parts == 0 then
        local empty = part("empty", "folder", " ", nil)
        empty.style = { opacity = 0 }
        table.insert(parts, empty)
    end
    return {
        kind = "container",
        key = "git-folder",
        role = "status",
        layout = {
            direction = "row",
            gap = 12,
            align = "center",
            padding = { top = 3, bottom = 3, left = 10, right = 10 },
        },
        children = parts,
    }
end

return place
