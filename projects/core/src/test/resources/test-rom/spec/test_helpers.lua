--- Run a program and capture its output
--
-- @tparam function(tbl:table, var:string, value:string) stub The active stub function.
-- @tparam string program The program name.
-- @tparam string ... Arguments to this program.
-- @treturn { ok = boolean, output = string, error = string, combined = string }
-- Whether this program terminated successfully, and the various output streams.
local function capture_program(stub, program, ...)
    local output, error, combined = {}, {}, {}

    local function out(stream, msg)
        table.insert(stream, msg)
        table.insert(combined, msg)
    end

    stub(_G, "print", function(...)
        for i = 1, select('#', ...) do
            if i > 1 then out(output, " ") end
            out(output, tostring(select(i, ...)))
        end
        out(output, "\n")
    end)

    stub(_G, "printError", function(...)
        for i = 1, select('#', ...) do
            if i > 1 then out(error, " ") end
            out(error, tostring(select(i, ...)))
        end
        out(error, "\n")
    end)

    stub(_G, "write", function(msg) out(output, tostring(msg)) end)

    local ok = shell.run(program, ...)

    return {
        output = table.concat(output),
        error = table.concat(error),
        combined = table.concat(combined),
        ok = ok,
    }
end

--- Run a function redirecting to a new window with the given dimensions
--
-- @tparam number width The window's width
-- @tparam number height The window's height
-- @tparam function() fn The action to run
-- @treturn window.Window The window, whose content can be queried.
local function with_window(width, height, fn)
    local current = term.current()
    local redirect = window.create(current, 1, 1, width, height, false)
    term.redirect(redirect)
    fn()
    term.redirect(current)
    return redirect
end

--- Run a function redirecting to a new window with the given dimensions,
-- returning the content of the window.
--
-- @tparam number width The window's width
-- @tparam number height The window's height
-- @tparam function() fn The action to run
-- @treturn {string...} The content of the window.
local function with_window_lines(width, height, fn)
    local window = with_window(width, height, fn)
    local out = {}
    for i = 1, height do out[i] = window.getLine(i) end
    return out
end

local function timeout(time, fn)
    local timer = os.startTimer(time)
    local co = coroutine.create(fn)
    local ok, result, event = true, nil, { n = 0 }
    while coroutine.status(co) ~= "dead" do
        if event[1] == "timer" and event[2] == timer then error("Timeout", 2) end

        if result == nil or event[1] == result or event[1] == "terminated" then
            ok, result = coroutine.resume(co, table.unpack(event, 1, event.n))
            if not ok then error(result, 0) end
        end

        event = table.pack(coroutine.yield())
    end
end

return {
    capture_program = capture_program,
    with_window = with_window,
    with_window_lines = with_window_lines,
    timeout = timeout,
}
