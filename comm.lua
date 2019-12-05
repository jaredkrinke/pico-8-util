-- pico-8 to html host communication (synchronous)
local comm_gpio = {
    size = 0,
    base = 1,
}

local gpio_address = 0x5f80
function comm_gpio_write(index, byte)
    poke(gpio_address + index, byte)
end

function comm_gpio_read(index)
    return peek(gpio_address + index)
end

function comm_send(bytes)
    comm_gpio_write(comm_gpio.size, #bytes)
    local index = comm_gpio.base
    for i = 1, #bytes, 1 do
        comm_gpio_write(index, bytes[i])
        index = index + 1
    end
end

function comm_receive()
    -- todo: consider setting the top bit to indicate server response instead of client request
    local bytes = {}
    local size = comm_gpio_read(comm_gpio.size)
    local index = comm_gpio.base
    for i = 1, size, 1 do
        bytes[i] = comm_gpio_read(index)
        index = index + 1
    end
    return bytes
end

function comm_process(bytes)
    comm_send(bytes)
    return comm_receive()
end
