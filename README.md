<p align="center"><img src="Assets/icon.png" width="160" alt="Snap icon"></p>

# Snap

A tiny, dependency-free macOS window snapper. One Swift file, ~150 lines.

| Shortcut | Action |
| --- | --- |
| `⌃⌥←` | Left half |
| `⌃⌥→` | Right half |
| `⌃⌥↑` | Maximize |

## Install

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
make run
```

That builds `Snap.app`, copies it to `/Applications`, and launches it. On first launch, grant it
**System Settings → Privacy & Security → Accessibility**. Turn on "Launch at Login" from the menu bar icon.

> Builds are ad-hoc signed, so after rebuilding you may need to remove and re-add Snap in the Accessibility list.

## License

MIT
