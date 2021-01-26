-- Will contain a list of container interfaces (peripheral.wrap) and the items they store.
_G.StorageIndex = {}
StorageIndex.chestTable = {}
StorageIndex.index = {}
dofile("lib/string.lua")
dofile("lib/functional.lua")
local storagePeriph = "minecraft:chest"
local periphs = peripheral.getNames()
periphs = table.filter(periphs,
                       function(v) return v:startsWith(storagePeriph) end)
periphs = table.map(periphs, function(id) return peripheral.wrap(id) end)
local index = StorageIndex.index

for i, v in ipairs(periphs) do --
    StorageIndex.chestTable[peripheral.getName(v)] = v
end

for i, v in pairs(StorageIndex.chestTable) do
    for j, item in pairs(v.list()) do
        item = v.getItemDetail(j)
        index[item.name] = (index[item.name] or
                               {
                total = 0,
                stackSize = item.maxCount,
                storedList = {}
            })
        index[item.name].total = index[item.name].total + item.count
        table.insert(index[item.name].storedList,
                     {inventory = i, slot = j, count = item.count})
    end
end
-- for i, v in pairs(index) do print(i .. "\t" .. v) end
