local out = {}

function out.requestItem(id, amount)
    amount = amount or 1
    local itemObj = StorageIndex.index[id]

    if not itemObj then return false end
    if amount > itemObj.total then return false end
    -- itemObj.total = itemObj.total - amount

    local ou = {}

    for i, v in ipairs(itemObj.storedList) do
        if amount > 0 then
            local diff = math.min(amount, v.count)
            amount = amount - diff
            table.insert(ou,
                         {inventory = v.inventory, slot = v.slot, count = diff})
        end
    end

    return ou
end

function out.removeItems(items)

    for i, fauxSlot in ipairs(items) do

        local id = StorageIndex.chestTable[fauxSlot.inventory].getItemDetail(
                       fauxSlot.slot).name

        local itemObj = StorageIndex.index[id]
        itemObj.total = itemObj.total - fauxSlot.count
        for j, realSlot in ipairs(itemObj.storedList) do
            if fauxSlot.slot == realSlot.slot and fauxSlot.inventory ==
                realSlot.inventory then
                realSlot.count = realSlot.count - fauxSlot.count
                if realSlot.count == 0 then
                    table.remove(itemObj.storedList, j)
                    table.insert(StorageIndex.freeSlots, {
                        inventory = realSlot.inventory,
                        slot = realSlot.slot
                    })

                end
            end
        end
    end

end

function out.getEmptySlots()
    local ou = {}

    for i, chest in pairs(StorageIndex.chestTable) do
        local items = chest.list()
        for j = 1, chest.size(), 1 do
            local item = items[j]
            if item == nil then
                table.insert(ou, {inventory = i, slot = j})
            end
        end
    end

    return ou
end

function out.getNonfullSlots(id)
    local ou = {}

    local itemObj = StorageIndex.index[id]

    if not itemObj then return ou end

    for i, slot in ipairs(itemObj.storedList) do
        if slot.count < itemObj.stackSize then
            table.insert(ou, {
                inventory = slot.inventory,
                slot = slot.slot,
                free = itemObj.stackSize - slot.count
            })
        end
    end

    return ou
end

function out.totalFree(ou)
    local runningTotal = 0
    for i, v in ipairs(ou) do runningTotal = runningTotal + v.free end
    return runningTotal
end

function out.findSpace(id, amount) --

    local itemObj = StorageIndex.index[id]
    if itemObj == nil then
        error(
            "Please make sure to initialize Record for items before calling findSpace")
    end

    local nonfull = out.getNonfullSlots(id)
    local total = out.totalFree(nonfull)
    local left = amount - total
    if left > 0 then
        local stacksToReserve = math.floor(left / itemObj.stackSize);
        if #StorageIndex.freeSlots < stacksToReserve + 1 then
            return false
        end
        for i = 1, stacksToReserve, 1 do
            local tslot = table.remove(StorageIndex.freeSlots, 1)
            tslot.free = itemObj.stackSize
            table.insert(nonfull, tslot)
        end
        local finalSlot = (left % itemObj.stackSize)
        if finalSlot > 0 then
            local tslot = table.remove(StorageIndex.freeSlots, 1)
            tslot.free = finalSlot
            table.insert(nonfull, tslot)
        end
        return nonfull
    else
        local amnt = amount
        local slots = {}
        for i, v in ipairs(nonfull) do
            if amnt - v.free > 0 then
                amnt = amnt - v.free
                table.insert(slots, v)
            else
                if amnt > 0 then
                    local tslot = v
                    tslot.free = amnt
                    table.insert(slots, tslot)
                end
                return slots
            end
        end
    end

    return false
end

StorageIndex.userInterface = ("minecraft:shulker_box_1")

function out.withdraw(id, amount, interf)
    local interface = peripheral.wrap(interf or StorageIndex.userInterface)
    local req = out.requestItem(id, amount)
    if not req then return false end
    out.removeItems(req)

    for i, v in ipairs(req) do
        interface.pullItems(v.inventory, v.slot, v.count)
    end
    return true
end

function out.deposit(interf)
    local interface = peripheral.wrap(interf or StorageIndex.userInterface)
    local items = interface.list()

    for i, item in pairs(items) do
        --
        item = interface.getItemDetail(i)

        StorageIndex.index[item.name] = (StorageIndex.index[item.name] or
                                            {
                total = 0,
                stackSize = item.maxCount,
                storedList = {}
            })

        local itemObj = StorageIndex.index[item.name]

        local space = out.findSpace(item.name, item.count)

        if not space then return false end
        for j, v in ipairs(space) do
            interface.pushItems(v.inventory, i, v.free, v.slot)
            itemObj.total = itemObj.total + v.free
            local flag = false
            for k, realSlot in ipairs(itemObj.storedList) do
                if v.slot == realSlot.slot and v.inventory == realSlot.inventory then
                    realSlot.count = realSlot.count + v.free
                    flag = true
                end
            end
            if not flag then
                table.insert(itemObj.storedList, {
                    inventory = v.inventory,
                    count = v.free,
                    slot = v.slot
                })
            end
        end

    end

    return true

end

return out
