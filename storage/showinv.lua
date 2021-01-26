dofile("lib/string.lua")

local monitor = peripheral.wrap("right")
monitor.setTextScale(0.5)

function show()
    term.clear()
    term.setCursorPos(1, 2)
    for i, v in pairs(StorageIndex.index) do
        print(i:pad(60) .. tostring(v.total))
    end
end

while true do
    show()
    sleep(2)
end
