function string.startsWith(String, Start)
    return String:sub(1, Start:len()) == Start
end
function string.pad(String, amount, char)
    char = char or " "
    return String .. char:rep(amount - #String)
end

function _G.echo(param, indent)
    if indent == nil then indent = "" end

    if param == nil then return "nil" end

    local outString = ""

    if type(param) == "table" then
        if #param > 0 then
            outString = outString .. indent .. "[\n"
            for i, val in ipairs(param) do
                outString = outString .. echo(val, indent .. "\t") .. "\n"
            end
            outString = outString .. indent .. "]"

        else
            outString = outString .. indent .. "{\n"
            for key, val in pairs(param) do
                outString = outString .. echo(key, indent .. "\t") .. "\t" ..
                                echo(val) .. "\n"
            end
            outString = outString .. indent .. "}"

        end
    else
        if type(param) == "function" and indent == "" then
            return echo(param())
        else
            outString = outString .. indent .. tostring(param)
        end
    end

    return outString

end
