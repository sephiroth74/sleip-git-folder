# git-folder

A plugin of [Lokyr](https://lokyr.dev): the focused pane's folder and its
git branch, in the window's status bar.

## Use

- Each window's status bar shows the folder of the program in its focused
  pane, by its name, its whole path in a tooltip, and the branch of the git
  repository that holds it, or a detached head's short hash; out of a
  repository, the folder alone.
- It follows the pane: another pane or tab, a `cd`, or a checkout of
  another branch shows at once, as the pane's folder changes or a command
  ends, of a shell that marks its commands, as Lokyr's shell integration
  does.
- Where there is nothing to show, as a pane of no folder, its view stays,
  empty, so that the status bar keeps its height.
- It sits at the bar's start, beside the other plugins of the status bar,
  each at its own width; `side` moves it.
- Lokyr reads the branch from the repository's own files, of worktrees
  too, without running git: no git needs to be installed, and nothing runs
  while nothing changes.

## Install

Of Lokyr 1.4 or later, of the plugin API 0.1.6:

```sh
sleip add sephiroth74/git-folder
```

## Config

In Lokyr's `config.toml`, under `[plugins.git-folder]`:

| Key | Values | Default | What it does |
|---|---|---|---|
| `folder` | `true`, `false` | `true` | The folder's name, its whole path in a tooltip |
| `branch` | `true`, `false` | `true` | The branch of the folder's repository |
| `side` | `start`, `center`, `end` | `start` | The side of the status bar where it shows |

## Capabilities

- `process-read`, for the folder of the program in the pane's foreground,
  the branch of the repository that holds it, and the end of each command
  that the shell marked, of no command line nor exit status.

## How it works

An example for plugin authors, in two files:

- [`src/init.luau`](src/init.luau) reads each window's focused pane's
  folder, `cx.working_directory`, and its branch, `cx.git_branch`, as the
  `status-bar` slot renders its view; it subscribes to the focus's and the
  panes' changes and to the commands' ends, looks again at the windows whose
  shown tab or pane they name, and asks for a render, `cx.request_render`,
  only of a window whose folder or branch changed; `cx.set_status_bar_side`
  puts it on the config's side.
- [`src/place.luau`](src/place.luau) makes the view: an icon and a text of
  each part, of the theme's secondary text, or an unseen part of none.

## Develop

`sleip check` checks the plugin, `sleip test` runs its tests, and
`sleip dev` links it into Lokyr, which reloads it at each save.

## License

MIT, see [LICENSE](LICENSE).
