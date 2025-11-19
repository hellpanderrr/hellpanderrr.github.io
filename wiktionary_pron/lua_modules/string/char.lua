local char = string.char

local concat = table.concat
local tonumber = tonumber

local function err(cp)
    error("Codepoint " .. cp .. " is out of range: codepoints must be between 0x0 and 0x10FFFF.", 2)
end

local function utf8_char(cp)
    cp = tonumber(cp)
    if cp < 0 then
        err("-0x" .. ("%X"):format(-cp + 1))
    elseif cp < 0x80 then
        return char(cp)
    elseif cp < 0x800 then
        return char(
                0xC0 + cp / 0x40,
                0x80 + cp % 0x40
        )
    elseif cp < 0x10000 then
        if cp >= 0xD800 and cp < 0xE000 then
            return "?" -- mw.ustring.char returns "?" for surrogates.
        end
        return char(
                0xE0 + cp / 0x1000,
                0x80 + cp / 0x40 % 0x40,
                0x80 + cp % 0x40
        )
    elseif cp < 0x110000 then
        return char(
                0xF0 + cp / 0x40000,
                0x80 + cp / 0x1000 % 0x40,
                0x80 + cp / 0x40 % 0x40,
                0x80 + cp % 0x40
        )
    end
    err("0x" .. ("%X"):format(cp))
end

return function(cp, ...)
    if ... == nil then
        return utf8_char(cp)
    end
    local ret = { cp, ... }
    for i = 1, #ret do
        ret[i] = utf8_char(ret[i])
    end
    return concat(ret)
end