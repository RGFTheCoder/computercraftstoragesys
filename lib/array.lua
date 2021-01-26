function table.toSet(array)
    local set = {}
    for i, v in ipairs(array) do set[v] = true end
    return set
end

function table.keys(tab)
    local set = {}
    for i, v in pairs(tab) do table.insert(set, i) end
    return set
end
