# Default Queue

A simple example of a server queue. When the server is full, new players wait on the loading screen and see their position in line. Whenever a slot frees up, the first player in line joins (first come, first served).

The whole package is one short file, Server/Index.lua, meant to be read and used as a starting point for your own queue (priorities, VIPs, wait limits and so on).

## Installation

Place the package in `Packages/default-queue/` and, in the server's `Config.toml`, add it to the package list and set how many extra connections may wait. For example, a 32-player server with room for 10 waiting players:

```toml
[game]
    packages = ["default-queue"]

[general]
    max_players = 32
    max_held_connections = 10
```

With the default `max_held_connections = 0`, a full server refuses new connections before the queue can see them.

## Settings

Optionally, set the loading screen text under `[custom_settings]`. `{position}` starts at 1 and `{size}` counts everyone waiting.

```toml
[custom_settings]
    queue_message = "waiting for a slot ({position}/{size})"
```

## How it works

- `PlayerConnect`: every player goes to the end of the line with `Server.HoldConnection()`, and is let in right away if there is a free slot and nobody ahead.
- `PlayerDisconnect` and a 3 second timer: players who gave up are removed, players at the front are let in with `Server.ReleaseConnection()` while there are free slots, and everyone else gets their updated position.

This package assumes it is the only one holding connections. It lets in every held player, so with another package that also holds them (a whitelist check, for example), that check would be skipped. In that case, merge the queue into your own script.
