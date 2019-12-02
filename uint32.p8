pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- unsigned 32-bit integer arithmetic, formatting
-- supports comparison (==, <), formatting (.., to_string), and mutation (set, , add, multiply -- with _raw, _number variants)
uint32 = {}
uint32_mt = {
    __index = uint32,

    __concat = function (a, b)
        if getmetatable(a) == uint32_mt then a = a:to_string() end
        if getmetatable(b) == uint32_mt then b = b:to_string() end
        return a .. b
    end,

    __eq = function (x, y)
        return x.value == y.value
    end,

    __lt = function (x, y)
        return x.value < y.value
    end,
}

local function uint32_number_to_value(n)
    return lshr(n, 16)
end

function uint32.create()
    local instance = { value = 0 }
    setmetatable(instance, uint32_mt)
    return instance
end

function uint32:set_raw(x)
    if self.value ~= x then
        self.value = x
        self.formatted = false
    end
    return self
end

function uint32.create_raw(x)
    local instance = uint32.create()
    if instance.value ~= x then
        instance:set_raw(x)
    end
    return instance
end

function uint32.create_from_number(n)
    return uint32.create_raw(uint32_number_to_value(n))
end

function uint32:set_number(n)
    return self:set_raw(uint32_number_to_value(n))
end

function uint32:add_raw(y)
    self.value = self.value + y
    return self
end

function uint32:add(b)
    return self:add_raw(b.value)
end

function uint32:add_number(n)
    return self:add_raw(uint32_number_to_value(n))
end

function uint32:multiply_raw(y)
    local x = self.value
    if x < y then x, y = y, x end
    local acc = 0

    for i = y, 0x0000.0001, -0x0000.0001 do
        acc = acc + x
    end
    self.value = acc
    return self
end

function uint32:multiply(b)
    return self:multiply_raw(b.value)
end

function uint32:multiply_number(n)
    return self:multiply_raw(uint32_number_to_value(n))
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
function uint32:format_decimal()
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
        -- cache format_decimal result
        if self.formatted ~= true then
            self.str = self:format_decimal()
            self.formatted = true
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
equal("0x0000.0000", uint32.create_from_number(0):to_string(true))
equal("0x0000.3039", uint32.create_from_number(12345):to_string(true))
equal("0x0000.7530", uint32.create_raw(0x0000.7530):to_string(true))

equal("0x0000.7d00", (uint32.create_from_number(16000):add(uint32.create_from_number(16000))):to_string(true))
equal("0x0000.fa00", (uint32.create_from_number(32000):add(uint32.create_from_number(32000))):to_string(true))
equal("0x0000.fa00", (uint32.create_from_number(32000):multiply(uint32.create_from_number(2))):to_string(true))
equal("0x0001.7700", (uint32.create_from_number(32000):multiply_raw(0x0000.0003)):to_string(true))

equal(uint32.create_from_number(32000), uint32.create_from_number(32000))
equal(uint32.create_from_number(32000):multiply(uint32.create_from_number(2)), uint32.create_from_number(2):multiply(uint32.create_from_number(32000)))

less_than(uint32.create_from_number(32000), uint32.create_from_number(32001))
less_than(uint32.create_from_number(32768), uint32.create_from_number(32768):add(uint32.create_from_number(1)))
less_than(uint32.create_from_number(32000):multiply_raw(0x0000.0002), uint32.create_from_number(2):multiply(uint32.create_from_number(32000)):add(uint32.create_from_number(1)))

equal("0", uint32.create_from_number():to_string())
equal("65536", (uint32.create_from_number(2):multiply(uint32.create_from_number(1):add(uint32.create_from_number(32767)))):to_string())

local v = uint32.create_raw(0x000F.423F)
equal("999999", v:to_string())
equal("999999", v:to_string())
equal("1999998", (uint32.create_from_number(2):multiply(v)):to_string())

-- 157070 == 123456 + (14 + 1200 * 28)
equal("157070", uint32.create_raw(0x0001.e240):add(uint32.create_from_number(14):add(uint32.create_from_number(1200):multiply_raw(0x0000.001c))):to_string())
equal("157070", uint32.create_raw(0x0001.e240):add_number(14):add(uint32.create_from_number(1200):multiply_number(28)):to_string())

printh("Tests passed: " .. passed .. "/" .. total)

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
