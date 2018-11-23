local assert = assert
local pairs = pairs
local unpack = unpack
local Vector = Vector
local bit_band   = bit.band
local bit_bor   = bit.bor
local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local math_floor = math.floor
local math_frexp = math.frexp
local math_huge  = math.huge
local math_ldexp = math.ldexp
local math_max = math.max
local string_byte = string.byte
local string_char = string.char
local string_len = string.len
--------------------------------------------------------------------------------
local function DoubleToInt32s( double )
    local high, low = 0,0
    -- Sign
    if double < 0 or 1/double < 0 then
        high = 0x80000000
        double = -double
    end

    -- Spcial cases
    if double == 0 then -- Zero
        return high, 0
    elseif double == 1/0 then -- Inf
        return high + 0x7FF00000, 0
    elseif double ~= double then -- NaN
        return 0x7FFFFFFF, 0xFFFFFFFF
    end

    local mantissa, exponent = math_frexp( double )
    if exponent > -1022 then
        -- Normalized numbers
        mantissa = mantissa*(2^53)
        low = mantissa % 0x100000000
        return high + bit_lshift(exponent+1022,20) + (mantissa-low)*2^-32 - 0x00100000, low
    else
        -- Denormalized numbers
        mantissa = mantissa*(2^(exponent+1074))
        low = mantissa % 0x100000000
        return high + (mantissa-low)*2^-32, low
    end
end

local function Int32sToDouble( high, low )
    local negative = bit_band(high,0x80000000) ~= 0
    local exponent = bit_rshift(bit_band(high,0x7FF00000),20)-1022
    high = bit_band(high,0x000FFFFF)

    -- Spcial cases
    if exponent == 1025 then
        if high == 0 and low == 0 then
            return negative and -1/0 or 1/0
        end
        return 0/0
    end

    if low < 0 then low = low + 0x100000000 end -- Fix sign for low bits

    if exponent ~= -1022 then
        -- Normalized
        return negative
            and -math_ldexp( (high*2^32+low)*(2^-53)+0.5, exponent ) 
            or   math_ldexp( (high*2^32+low)*(2^-53)+0.5, exponent )
    else 
        -- Denormalized
        return negative 
            and -math_ldexp( (high*2^32+low)*(2^-52), -1022 ) 
            or   math_ldexp( (high*2^32+low)*(2^-52), -1022 )
    end
end
--------------------------------------------------------------------------------
local function FloatToInt32( float )
    -- Sign
    local sign = 0
    if float < 0 or 1/float < 0 then
        sign = 0x80000000
        float = -float
    end

    -- Spcial cases
    if float == 0 then -- Zero
        return sign
    elseif float == 1/0 then -- Inf
        return sign + 0x7F800000
    elseif float ~= float then -- NaN
        return 0x7fffffff
    end

    local mantissa, exponent = math_frexp( float )
    if exponent > -126 then -- Normalized
        return sign + bit_lshift(exponent+126,23) + math_floor(mantissa*(2^24)+0.5)-0x800000      
    else -- Denormalized
        return sign + math_floor(mantissa*(2^(exponent+149))+0.5)
    end
end

local function Int32ToFloat( int )
    local negative = bit_band(int,0x80000000) ~= 0
    local exponent = bit_rshift(bit_band(int,0x7F800000),23)-126
    int = bit_band(int,0x007fffff)

    -- Spcial cases
    if exponent == 129 then
        if int == 0 then
            return negative and -1/0 or 1/0
        end
        return 0/0
    end

    if exponent ~= -126 then -- Normalized
        return negative and -math_ldexp( int*(2^-24)+0.5, exponent ) or math_ldexp( int*(2^-24)+0.5, exponent )
    else -- Denormalized
        return negative and -math_ldexp( int*(2^-23), exponent ) or math_ldexp( int*(2^-23), -126 )
    end
end
--------------------------------------------------------------------------------
local Base64Encode
local Base64Decode
do
    -- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
    -- licensed under the terms of the LGPL2
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

    -- encoding
    function Base64Encode(data)
        return ((data:gsub('.', function(x) 
            local r,b='',x:byte()
            for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c=0
            for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
            return b:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#data%3+1])
    end

    -- decoding
    function Base64Decode(data)
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local Stream = {}
Stream.__index = Stream
--------------------------------------------------------------------------------
-- Double
--------------------------------------------------------------------------------
function Stream:WriteDouble( double )
    local high, low = DoubleToInt32s( double )

    if self.big_endian then
        self:WriteUInt32(high)
        self:WriteUInt32(low)
    else
        self:WriteUInt32(low)
        self:WriteUInt32(high)
    end
end

function Stream:ReadDouble( )
    if self.buffer[self.pointer+7] == nil then return nil end
    local high, low
    
    if self.big_endian then
        high = self:ReadUInt32()
        low = self:ReadUInt32()
    else
        low = self:ReadUInt32()
        high = self:ReadUInt32()
    end
    return Int32sToDouble( high, low )
end
--------------------------------------------------------------------------------
-- Float
--------------------------------------------------------------------------------
function Stream:WriteFloat( float )
    self:WriteUInt32(FloatToInt32( float ))
end

function Stream:ReadFloat( )
    if self.buffer[self.pointer+3] == nil then return nil end
    return Int32ToFloat( self:ReadUInt32() )
end
--------------------------------------------------------------------------------
-- Int32
--------------------------------------------------------------------------------
function Stream:WriteUInt32( int32 )
    local b1, b2, b3, b4 =  
        bit_rshift(int32,24),
        bit_band(bit_rshift(int32,16),0xFF),
        bit_band(bit_rshift(int32,8),0xFF),
        bit_band(int32,0xFF)

    local buffer = self.buffer
    local pointer = self.pointer
    local big_endian = self.big_endian
    buffer[pointer]   = big_endian and b1 or b4
    buffer[pointer+1] = big_endian and b2 or b3
    buffer[pointer+2] = big_endian and b3 or b2
    buffer[pointer+3] = big_endian and b4 or b1
    self.pointer = pointer + 4
end
Stream.WriteInt32 = Stream.WriteUInt32

function Stream:ReadInt32( )
    if self.buffer[self.pointer+3] == nil then return nil end

    local buffer = self.buffer
    local pointer = self.pointer
    local big_endian = self.big_endian
    local b1 = big_endian and buffer[pointer]   or buffer[pointer+3]
    local b2 = big_endian and buffer[pointer+1] or buffer[pointer+2]
    local b3 = big_endian and buffer[pointer+2] or buffer[pointer+1]
    local b4 = big_endian and buffer[pointer+3] or buffer[pointer]
    self.pointer = pointer + 4

    return bit_lshift(b1, 24) + bit_lshift(b2, 16) + bit_lshift(b3, 8) + b4
end

function Stream:ReadUInt32()
    local r = self:ReadInt32()
    return r < 0 and r + 0x100000000 or r
end
--------------------------------------------------------------------------------
-- Int16
--------------------------------------------------------------------------------
function Stream:WriteInt16( int16 )
    local b1, b2 = 
        bit_band(bit_rshift(int16,8),0xFF),
        bit_band(int16,0xFF)

    if int16 < 0 then b1 = bit_bor(b1,0x80) end

    local buffer = self.buffer
    local pointer = self.pointer
    local big_endian = self.big_endian
    
    buffer[pointer] = big_endian and b1 or b2
    buffer[pointer+1] = big_endian and b2 or b1

    self.pointer = pointer + 2
end
Stream.WriteUInt16 = Stream.WriteInt16

function Stream:ReadUInt16( )
    if self.buffer[self.pointer+1] == nil then return nil end

    local buffer = self.buffer
    local pointer = self.pointer
    local big_endian = self.big_endian
    
    local b1 = big_endian and buffer[pointer] or buffer[pointer+1]
    local b2 = big_endian and buffer[pointer+1] or buffer[pointer]
    
    self.pointer = pointer + 2
    return bit_lshift(b1, 8) + b2
end

function Stream:ReadInt16()
    if self.buffer[self.pointer] == nil then return nil end

    local r = self:ReadUInt16()
    return bit_band(r,0x8000) ~= 0 and r - 0x10000 or r
end
--------------------------------------------------------------------------------
-- Int8
--------------------------------------------------------------------------------
function Stream:WriteInt8( int8 )
    local b1 = bit_band(int8,0xFF)
    if int8 < 0 then b1 = bit_bor(b1,0x80) end

    local pointer = self.pointer
    self.buffer[pointer] = b1
    self.pointer = pointer + 1
end
Stream.WriteUInt8 = Stream.WriteInt8

function Stream:ReadUInt8( )
    if self.buffer[self.pointer] == nil then return nil end

    local buffer = self.buffer
    local pointer = self.pointer
    local b1 = buffer[pointer]

    self.pointer = pointer + 1
    return b1
end

function Stream:ReadInt8()
    if self.buffer[self.pointer] == nil then return nil end

    local r = self:ReadUInt8()
    return bit_band(r,0x80) ~= 0 and r - 0x100 or r
end
--------------------------------------------------------------------------------
-- Bool
--------------------------------------------------------------------------------
function Stream:WriteBool( bool )
    self:WriteInt8( bool and 1 or 0 )
end

function Stream:ReadBool( )
    if self.buffer[self.pointer] == nil then return nil end
    return self:ReadInt8() ~= 0
end
--------------------------------------------------------------------------------
-- Vector
--------------------------------------------------------------------------------
function Stream:WriteVector( vector )
    self:WriteFloat( vector.x )
    self:WriteFloat( vector.y )
    self:WriteFloat( vector.z )
end

function Stream:ReadVector( )
    if self.buffer[self.pointer+11] == nil then return nil end
    return Vector(self:ReadFloat(), self:ReadFloat(), self:ReadFloat())
end
--------------------------------------------------------------------------------
-- String
--------------------------------------------------------------------------------
function Stream:WriteString( str )
    local len = string_len(str)
    assert(len<8000, "String length cannot exceed 7999 characters!")
    
    local pointer = self.pointer
    local buffer = self.buffer
    for k, b in pairs({string_byte(str, 1, len)}) do
        if b == 0 then 
            len = k-1
            break 
        end
        buffer[pointer + k - 1] = b
    end
    buffer[pointer + len] = 0

    self.pointer = pointer + len + 1
end

function Stream:ReadString()
    local r = {}
    for i=1, 7999 do
        local b = self:ReadUInt8()
        if b == 0 or b == nil then
            break
        end
        r[i] = b
    end
    return string_char(unpack(r))
end
--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------
function Stream:WriteData( str, len )
    len = len or string_len(str)
    assert(len<8000, "String length cannot exceed 7999 characters!")
    
    local pointer = self.pointer
    local buffer = self.buffer
    for k, b in pairs({string_byte(str, 1, len)}) do
        buffer[pointer + k - 1] = b
    end

    self.pointer = pointer + len
end

function Stream:ReadData( len )
    assert(len<8000, "String length cannot exceed 7999 characters!")
    local r = {}
    for i=1, len do
        local b = self:ReadUInt8()
        if b == nil then
            break
        end
        r[i] = b
    end
    return string_char(unpack(r))
end
--------------------------------------------------------------------------------
function Stream:Seek( pointer )
    while pointer > #self.buffer do
        self.buffer[#self.buffer+1] = 0
    end
    self.pointer = pointer + 1

end

function Stream:Tell( )
    return self.pointer - 1
end

function Stream:Size( )
    return #self.buffer
end
--------------------------------------------------------------------------------
function Stream:FromRawString( raw )
    self.buffer = {string_byte(raw)}
    self.pointer = 1
end

function Stream:ToRawString( )
    return string_char( unpack(self.buffer) )
end
--------------------------------------------------------------------------------
function Stream:FromBase64( base64 )
    self:FromRawString( Base64Decode( base64 ) )
end

function Stream:ToBase64( )
    return Base64Encode( self:ToRawString() )
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
setmetatable( Stream, {
    __call = function(class, ...) return class.new(...) end
} )

function Stream.new( big_endian )
    local self = setmetatable({}, Stream)
    self.StreamObj = true
    self.BufferObj = true
    self.buffer_type = "stream"
    self.buffer = {}
    self.pointer = 1
    self.big_endian = big_endian
    return self
end

return Stream