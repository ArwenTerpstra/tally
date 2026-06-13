# tally

A minimal CLI time tracker for tracking how you spend your time on tasks,
right from the terminal.

## Features

* Start and stop named tasks from the command line
* Track multiple tasks running concurrently
* Multi-word task names — no quotes needed
* Confirmation prompt when starting a new task while others are running
* `status` shows currently running tasks and elapsed time
* `report` shows total time spent per task, all-time
* Case-insensitive task names
* Data stored as plain text in `~/.tally/`
* No dependencies, single file

## Installation

Requires [Lua](https://www.lua.org/) 5.1+.

```bash
curl -o ~/.local/bin/tally https://raw.githubusercontent.com/ArwenTerpstra/tally/main/tally.lua
chmod +x ~/.local/bin/tally
```

Make sure `~/.local/bin` is in your `PATH`.

Alternatively, if you've cloned the repo:

```bash
chmod +x tally.lua
cp tally.lua ~/.local/bin/tally
```

## Usage

### Start a task

```bash
tally start programming
```

If other tasks are currently running, you'll be asked whether to stop them:

```text
Stop all running tasks? (y/n)
```

### Stop a task

```bash
tally stop programming
```

Stop everything currently running:

```bash
tally stop
```

```text
programming - running for 1h 12m
drawing assets - running for 0h 34m
Stop all running tasks? (y/n)
```

### Check status

```bash
tally status
```

```text
programming - running for 0h 23m
```

### View totals

```bash
tally report
```

```text
Total time spent on each task:
programming: 4h 12m
drawing assets: 1h 50m
documenting: 0h 45m
```

## License

MIT
