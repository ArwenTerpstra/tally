#!/usr/bin/env lua

--- tally - A minimal CLI time tracker
---
--- Track time spent on tasks from the command line. Supports multiple
--- concurrently running tasks, with confirmation prompts when starting
--- a new task while others are still running.
---
--- Usage:
---   tally start <task_name>   Start tracking a task
---   tally stop [task_name]    Stop a specific task, or all running tasks
---   tally status              Show currently running tasks and elapsed time
---   tally report              Show total time spent per task, all-time
---
--- Data is stored in ~/.tally/ as plain pipe-separated text files.
---
--- Author: Arwen Terpstra
--- Version: 1.0.0
--- License: MIT

-- ================================================================
-- tally module
-- ================================================================
local tally = {}

local DATA_DIR = os.getenv("HOME") .. "/.tally/"
local RUNNING_FILE = DATA_DIR .. "running.txt"
local HISTORY_FILE = DATA_DIR .. "history.txt"

local function ensure_data_dir()
    os.execute("mkdir -p " .. DATA_DIR)
end

ensure_data_dir()

local function format_duration(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return string.format("%dh %dm", hours, minutes)
end

-- Pipe-separated, one running task per line: "<start_time>|<task_name>"
function tally.read_running()
    local list = {}

    local file = io.open(RUNNING_FILE, "r")
    if not file then return list end

    for line in file:lines() do
        local start_time, task_name = line:match("([^|]+)|(.+)")
        if start_time and task_name then
            table.insert(list, { start_time = tonumber(start_time), task_name = task_name })
        end
    end

    file:close()

    return list
end

function tally.write_running(tasks)
    local file = io.open(RUNNING_FILE, "w")
    if not file then return end

    for _, task in ipairs(tasks) do
        file:write(string.format("%d|%s\n", task.start_time, task.task_name))
    end

    file:close()
end

function tally.read_history()
    local list = {}

    local file = io.open(HISTORY_FILE, "r")
    if not file then return list end

    for line in file:lines() do
        local start_time, end_time, task_name = line:match("([^|]+)|([^|]+)|(.+)")
        if start_time and end_time and task_name then
            table.insert(list, { start_time = tonumber(start_time), end_time = tonumber(end_time), task_name = task_name })
        end
    end

    file:close()

    return list
end

function tally.append_history(task)
    local file = io.open(HISTORY_FILE, "a")
    if not file then return end

    file:write(string.format("%d|%d|%s\n", task.start_time, task.end_time, task.task_name))

    file:close()
end

function tally.start(task_name)
    if not task_name or task_name == "" then
        print("Usage: tally start <task_name>")
        return
    end

    -- Lowercased so "Programming" and "programming" are treated as the same task
    task_name = task_name:lower()

    local running_tasks = tally.read_running()

    for _, task in ipairs(running_tasks) do
        if task.task_name == task_name then
            print("Task '" .. task_name .. "' is already running.")
            return
        end
    end

    if #running_tasks > 0 then
        io.write("Stop all running tasks? (y/n) ")
        local answer = io.read()
        if answer:lower() == "y" then
            for _, task in ipairs(running_tasks) do
                task.end_time = os.time()
                tally.append_history(task)
            end
            running_tasks = {}
        end
    end
    table.insert(running_tasks, { start_time = os.time(), task_name = task_name })
    tally.write_running(running_tasks)
end

function tally.stop(task_name)
    local running_tasks = tally.read_running()
    local remaining = {}

    if not task_name or task_name == "" then
        for _, task in ipairs(running_tasks) do
            local elapsed = os.time() - task.start_time
            print(task.task_name .. " - running for " .. format_duration(elapsed))
        end
        io.write("Stop all running tasks? (y/n) ")
        local answer = io.read()
        if answer:lower() == "y" then
            for _, task in ipairs(running_tasks) do
                task.end_time = os.time()
                tally.append_history(task)
            end
        else
            remaining = running_tasks
        end
    else
        task_name = task_name:lower()
        local found = false
        for _, task in ipairs(running_tasks) do
            if task.task_name == task_name then
                task.end_time = os.time()
                tally.append_history(task)
                found = true
            else
                table.insert(remaining, task)
            end
        end
        if not found then
            print("No running task found matching '" .. task_name .. "'")
        end
    end

    tally.write_running(remaining)
end

function tally.status()
    local running_tasks = tally.read_running()
    if #running_tasks == 0 then
        print("No tasks are currently running.")
    else
        for _, task in ipairs(running_tasks) do
            local elapsed = os.time() - task.start_time
            print(task.task_name .. " - running for " .. format_duration(elapsed))
        end
    end
end

function tally.report()
    local history = tally.read_history()
    if #history == 0 then
        print("No tasks have been recorded.")
    else
        local totals = {}
        for _, task in ipairs(history) do
            local duration = task.end_time - task.start_time
            totals[task.task_name] = (totals[task.task_name] or 0) + duration
        end

        local sorted = {}
        for task_name, total in pairs(totals) do
            table.insert(sorted, { task_name = task_name, total = total })
        end

        table.sort(sorted, function(a, b) return a.total > b.total end)

        print("\nTotal time spent on each task:")
        for _, entry in ipairs(sorted) do
            print(string.format("%s: %s", entry.task_name, format_duration(entry.total)))
        end
    end
end

-- ================================================================
-- main / dispatch
-- ================================================================
local function join_args(start_index)
    local parts = {}
    for i = start_index, #arg do
        table.insert(parts, arg[i])
    end
    return table.concat(parts, " ")
end

local command = arg[1]

if command == "start" then
    tally.start(join_args(2))
elseif command == "stop" then
    tally.stop(join_args(2))
elseif command == "status" then
    tally.status()
elseif command == "report" then
    tally.report()
else
    print("Usage: tally <start|stop|status|report> [task_name]")
end