# zio
Serial terminal with advanced log analysis and plotting capabilities written in Zig.

## Build & Run
- Run tui: `zig build run`
- Run gui: `zig build run-gui`

## Goals for the project
Create an application that can be used to log data from a serial port to a UI (tui and gui) and to log-files. Use the same tool to do post mortem analysis by replaying log files.


### Personal goals for the project
- Working with the zig build system (two builds, tui only and full fleged gui)
- Gain experience with dvui and libxev