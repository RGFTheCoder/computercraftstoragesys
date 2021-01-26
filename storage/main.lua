shell.run("storage/index.lua")

dofile("lib/string.lua")
dofile("lib/functional.lua")
dofile("lib/array.lua")
local input = dofile("lib/input.lua")

_G.inv = dofile("storage/api.lua")

StorageIndex.freeSlots = inv.getEmptySlots()

local history = {}
local function items(line)
    local temp = table.keys(StorageIndex.index)
    temp = table.filter(temp, function(s) return s:startsWith(line) end)
    temp = table.map(temp, function(x) return x:sub(#line + 1) end)
    return temp
end
local function numbers(line)
    local out = {}
    for i = 1, 63, 1 do table.insert(out, tostring(i)) end
    for i = 64, 1024, 64 do table.insert(out, tostring(i)) end
    return table.map(
               table.filter(out, function(s) return s:startsWith(line) end),
               function(x) return x:sub(#line + 1) end)
end

shell.run("bg monitor right storage/showinv.lua")
shell.run("bg shell")

local function cyc()
    term.clear()
    term.setCursorPos(1, 1)
    local start = ""
    local special = false
    local outer = true

    print("Press C for special")
    print("Press I for Item withdrawal")
    print("Press M for Minecraft Item withdrawal")
    print("Press D for deposit")
    print("Press R for reindex (Takes a long time)")

    while outer do
        local id, chr = os.pullEvent()

        if id == "key" then
            if chr == 73 then
                -- i
                start = ""
                outer = false
            end
            if chr == 77 then
                -- m
                start = "minecraft:"
                outer = false
            end
            if chr == 67 then
                -- c
                special = true
                outer = false
            end
            if chr == 68 then
                -- d
                inv.deposit()
                return
            end
            if chr == 82 then
                shell.run("storage/index.lua")
                _G.inv = dofile("storage/api.lua")
                StorageIndex.freeSlots = inv.getEmptySlots()
                return
            end
        end

    end
    os.pullEvent()
    term.clear()
    term.setCursorPos(1, 1)

    if special then

        io.write("Special: ")
        local ite = input(nil, {}, function() return {"deposit"} end)
        if ite == "deposit" then inv.deposit() end
    else
        io.write("Item: ")
        local ite = input(nil, history, items, start)
        table.insert(history, ite)
        io.write("Amount: ")
        local num = tonumber(input(nil, {}, numbers, ""))
        print(ite)
        inv.withdraw(ite, num)
    end
end

while true do cyc() end
