local processList = {}

local w, h = term.getSize()

local hiddenWin = window.create(term.native(), 1, 1, w, h, false)

local function startProcess(func)
    if func == nil then return end
    local out = {}
    out.co = coroutine.create(func)
    out.paused = false
    table.insert(processList, 0, out)
end

local function process(proc)
    if not proc.paused then
        term.redirect(hiddenWin)
        coroutine.resume(proc.co, nil)
        --
    end
end
local function cullProcesses()

    for n = #processList, 1, -1 do
        local proc = processList[n]
        if coroutine.status(proc.co) == "dead" then
            table.remove(processList, n)
        end
    end

end
local function cycle()
    cullProcesses()
    term.redirect(hiddenWin)
    for i, proc in ipairs(processList) do process(proc) end
    term.redirect(term.native())
end
return {cycle = cycle, startProcess = startProcess}
