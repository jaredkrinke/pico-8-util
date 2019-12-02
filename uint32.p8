pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- unsigned 32-bit integer arithmetic
-- supports +, *, ==, <, and to_string
uint32 = {}
uint32_mt = {
    __index = uint32,

    __concat = function (a, b)
        if getmetatable(a) == uint32_mt then a = a:to_string() end
        if getmetatable(b) == uint32_mt then b = b:to_string() end
        return a .. b
    end,

    __add = function (x, y)
        return uint32.create_raw(x.value + y.value)
    end,

    __mul = function (x, y)
        -- note: this is not efficient
        if x < y then return uint32_mt.__mul(y, x) end

        local acc = uint32.create()
        local i = uint32.create()
        local one = uint32.create(1)
        while i < y do
            acc = acc + x
            i = i + one
        end
        return acc
    end,

    __eq = function (x, y)
        return x.value == y.value
    end,

    __lt = function (x, y)
        return x.value < y.value
    end,
}

function uint32.create_raw(x)
    local instance = {
        value = 0,
        dirty = false,
        str = "0",
    }

    if x ~= nil then
        instance.value = x
        instance.dirty = true
    end
    
    setmetatable(instance, uint32_mt)
    return instance
end

function uint32.create(x)
    return uint32.create_raw(lshr(x, 16))
end

local function decimal_digits_add_in_place(a, b)
    local carry = 0
    local i = 1
    local digits = max(#a, #b)
    while i <= digits or carry > 0 do
        local left = a[i]
        local right = b[i]
        if left == nil then left = 0 end
        if right == nil then right = 0 end
        local sum = left + right + carry
        a[i] = sum % 10
        carry = flr(sum / 10)
        i = i + 1
    end
end

local function decimal_digits_double(a)
    local result = {}
    for i = 1, #a, 1 do result[i] = a[i] end
    decimal_digits_add_in_place(result, a)
    return result
end

local uint32_binary_digits = { { 1 } }
function uint32:to_string_decimal()
    local result_digits = { 0 }
    local value = self.value

    -- find highest bit
    local max_index = 0
    local v = value
    while v ~= 0 do
        v = lshr(v, 1)
        max_index = max_index + 1
    end

    -- compute the value
    for i = 1, max_index, 1 do
        -- make sure decimal representation of this binary bit is cached
        local binary_digits = uint32_binary_digits[i]
        if binary_digits == nil then
            binary_digits = decimal_digits_double(uint32_binary_digits[i - 1])
            uint32_binary_digits[i] = binary_digits
        end

        -- find the bit
        local mask = 1
        if i <= 16 then
            mask = lshr(mask, 16 - (i - 1))
        elseif i > 17 then
            mask = shl(mask, (i - 1) - 16)
        end

        local bit = false
        if band(mask, value) ~= 0 then bit = true end

        -- add, if necessary
        if bit then
            decimal_digits_add_in_place(result_digits, binary_digits)
        end
    end

    -- concatenate the digits
    local str = ""
    for i = #result_digits, 1, -1 do
        str = str .. result_digits[i]
    end
    return str
end

function uint32:to_string(raw)
    if raw == true then
        return tostr(self.value, true)
    else
        -- cache to_string_decimal result
        if self.dirty then
            self.str = self:to_string_decimal()
            self.dirty = false
        end
        return self.str
    end
end

-- tests
local total = 0
local passed = 0
function test(a, label)
    total = total + 1
    if a == true then
        passed = passed + 1
    else
        printh("*** Failed test " .. total .. ": " .. label)
    end
end

function equal(a, b)
    test(a == b, "" .. a .. " == " .. b)
end

function less_than(a, b)
    test(a < b, "" .. a .. " < " .. b)
end

equal("0x0000.0000", uint32.create():to_string(true))
equal("0x0000.0000", uint32.create(0):to_string(true))
equal("0x0000.3039", uint32.create(12345):to_string(true))
equal("0x0000.7530", uint32.create_raw(0x0000.7530):to_string(true))

equal("0x0000.7d00", (uint32.create(16000) + uint32.create(16000)):to_string(true))
equal("0x0000.fa00", (uint32.create(32000) + uint32.create(32000)):to_string(true))
equal("0x0000.fa00", (uint32.create(32000) * uint32.create(2)):to_string(true))

equal(uint32.create(32000), uint32.create(32000))
equal(uint32.create(32000) * uint32.create(2), uint32.create(2) * uint32.create(32000))

less_than(uint32.create(32000), uint32.create(32001))
less_than(uint32.create(32768), uint32.create(32768) + uint32.create(1))
less_than(uint32.create(32000) * uint32.create(2), uint32.create(2) * uint32.create(32000) + uint32.create(1))

equal("0", uint32.create():to_string())
equal("65536", (uint32.create(2) * (uint32.create(1) + uint32.create(32767))):to_string())

local v = uint32.create_raw(0x000F.423F)
equal("999999", v:to_string())
equal("999999", v:to_string())
equal("1999998", (uint32.create(2) * v):to_string())

printh("Tests passed: " .. passed .. "/" .. total)

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
