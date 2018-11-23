local error = error
local isstring = isstring
local istable = istable
local setmetatable = setmetatable
local type = type
local unpack = unpack
local net_BytesWritten = net.BytesWritten
local net_ReadBool = net.ReadBool
local net_ReadData = net.ReadData
local net_ReadDouble = net.ReadDouble
local net_ReadFloat = net.ReadFloat
local net_ReadInt = net.ReadInt
local net_ReadString = net.ReadString
local net_ReadUInt = net.ReadUInt
local net_ReadVector = net.ReadVector
local net_WriteBool = net.WriteBool
local net_WriteData = net.WriteData
local net_WriteDouble = net.WriteDouble
local net_WriteFloat = net.WriteFloat
local net_WriteInt = net.WriteInt
local net_WriteString = net.WriteString
local net_WriteUInt = net.WriteUInt
local net_WriteVector = net.WriteVector
local string_char = string.char
local string_find = string.find
local string_sub = string.sub
local string_lower = string.lower
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Net Library Buffer
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local BufferInterfaceNet = {}
BufferInterfaceNet.__index = BufferInterfaceNet
--------------------------------------------------------------------------------
-- Double
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteDouble( double )
    net_WriteDouble( double )
end

function BufferInterfaceNet:ReadDouble()
    return net_ReadDouble()
end
--------------------------------------------------------------------------------
-- Float
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteFloat( float )
    net_WriteFloat( float )
end

function BufferInterfaceNet:ReadFloat()
    return net_ReadFloat()
end
--------------------------------------------------------------------------------
-- Int32
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteInt32( int32 )
    net_WriteInt( int32, 32 )
end

function BufferInterfaceNet:ReadInt32()
    return net_ReadInt( 32 )
end
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteUInt32( int32 )
    net_WriteUInt( int32, 32 )
end

function BufferInterfaceNet:ReadUInt32()
    return net_ReadUInt( 32 )
end
--------------------------------------------------------------------------------
-- Int16
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteInt16( int16 )
    net_WriteInt( int16, 16 )
end

function BufferInterfaceNet:ReadInt16()
    return net_ReadInt( 16 )
end
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteUInt16( int16 )
    net_WriteUInt( int16, 16 )
end

function BufferInterfaceNet:ReadUInt16()
    return net_ReadUInt( 16 )
end
--------------------------------------------------------------------------------
-- Int8
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteInt8( int8 )
    net_WriteInt( int8, 8 )
end

function BufferInterfaceNet:ReadInt8( )
    return net_ReadInt( 8 )
end
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteUInt8( int8 )
    net_WriteUInt( int8, 8 )
end

function BufferInterfaceNet:ReadUInt8()
    return net_ReadUInt( 8 )
end
--------------------------------------------------------------------------------
-- Bool
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteBool( bool )
    net_WriteBool( bool )
end

function BufferInterfaceNet:ReadBool()
    return net_ReadBool( )
end
--------------------------------------------------------------------------------
-- Vector
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteVector( vector )
    net_WriteVector( vector )
end

function BufferInterfaceNet:ReadVector()
    return net_ReadVector( )
end
--------------------------------------------------------------------------------
-- String
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteString( str )
    net_WriteString( str )
end

function BufferInterfaceNet:ReadString()
    return net_ReadString( )
end
--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------
function BufferInterfaceNet:WriteData( data, len )
    len = len or #data
    net_WriteData( data, len )
end

function BufferInterfaceNet:ReadData( len )
    return net_ReadData( len )
end
--------------------------------------------------------------------------------
function BufferInterfaceNet:Seek( pos )
    error( "Seek() is not supported by net library." )
end

function BufferInterfaceNet:Tell( )
    error( "Tell() is not supported by net library." )
end

function BufferInterfaceNet:Size( )
    return net_BytesWritten( )
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- File Buffer
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local BufferInterfaceFile = {}
BufferInterfaceFile.__index = BufferInterfaceFile
--------------------------------------------------------------------------------
-- Double
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteDouble( double )
    self.buffer_obj:WriteDouble( double )
end

function BufferInterfaceFile:ReadDouble()
    return self.buffer_obj:ReadDouble()
end
--------------------------------------------------------------------------------
-- Float
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteFloat( float )
    self.buffer_obj:WriteFloat( float )
end

function BufferInterfaceFile:ReadFloat()
    return self.buffer_obj:ReadFloat()
end
--------------------------------------------------------------------------------
-- Int32
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteInt32( int32 )
    self.buffer_obj:WriteLong( int32 )
end

function BufferInterfaceFile:ReadInt32()
    return self.buffer_obj:ReadLong()
end
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteUInt32( int32 )
    if int32 >= 0x80000000 then
        int32 = int32 - 0x100000000
    end
    self.buffer_obj:WriteLong( int32 )
end

function BufferInterfaceFile:ReadUInt32()
    local int32 = self.buffer_obj:ReadLong()
    if int32 < 0 then
        int32 = int32 + 0x100000000
    end
    return int32
end
--------------------------------------------------------------------------------
-- Int16
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteInt16( int16 )
    self.buffer_obj:WriteShort( int16 )
end

function BufferInterfaceFile:ReadInt16()
    return self.buffer_obj:ReadShort( )
end
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteUInt16( int16 )
    if int16 >= 0x8000 then
        int16 = int16 - 0x10000
    end
    self.buffer_obj:WriteShort( int16 )
end

function BufferInterfaceFile:ReadUInt16()
    local int16 = self.buffer_obj:ReadShort()
    if int16 < 0 then
        int16 = int16 + 0x10000
    end
    return int16
end
--------------------------------------------------------------------------------
-- Int8
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteInt8( int8 )
    if int8 < 0 then
        int8 = int8 + 0x100
    end
    self:WriteUInt8( int8 )
end

function BufferInterfaceFile:ReadInt8( )
    local int8 = self:ReadUInt8()
    if int8 >= 0x80 then
        int8 = int8 - 0x100
    end
    return int8
end
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteUInt8( int8 )
    self.buffer_obj:WriteByte( int8 )
end

function BufferInterfaceFile:ReadUInt8()
    return self.buffer_obj:ReadByte( )
end
--------------------------------------------------------------------------------
-- Bool
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteBool( bool )
    self.buffer_obj:WriteBool( bool )
end

function BufferInterfaceFile:ReadBool()
    return self.buffer_obj:ReadBool( )
end
--------------------------------------------------------------------------------
-- Vector
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteVector( vector )
    self.buffer_obj:WriteFloat( vector.x )
    self.buffer_obj:WriteFloat( vector.y )
    self.buffer_obj:WriteFloat( vector.z )
end

function BufferInterfaceFile:ReadVector()
    return Vector( self.buffer_obj:ReadFloat( ), self.buffer_obj:ReadFloat( ), self.buffer_obj:ReadFloat( ) )
end
--------------------------------------------------------------------------------
-- String
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteString( str )
    local len = string_find( str, "\0" )
    if len then
        self.buffer_obj:Write( string_sub(str, 1, len) )
    else
        self.buffer_obj:Write( str )
        self.buffer_obj:Write( "\0" )
    end
end

function BufferInterfaceFile:ReadString()
    local str_t = {}

    local fl = self.buffer_obj
    for i = 1, 7999 do
        local b = fl:ReadByte()
        if b == 0 or b == nil then
            break
        end
        str_t[i] = b
    end

    return string_char( unpack(str_t) )
end
--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------
function BufferInterfaceFile:WriteData( data, len )
    local data_len = #data
    len = len or data_len
    local fl = self.buffer_obj
    
    if data_len == len then
        fl:Write( data )
    elseif data_len < len then
        fl:Write( string_sub( data, 1, len ) )
    else
        fl:Write( data )
        fl:Seek(fl:Tell()+(len-data_len))
    end
end

function BufferInterfaceFile:ReadData( len )
    return self.buffer_obj:Read( len ) or ""
end
--------------------------------------------------------------------------------
function BufferInterfaceFile:Seek( pos )
    self.buffer_obj:Seek( pos )
end

function BufferInterfaceFile:Tell( )
    return self.buffer_obj:Tell( )
end

function BufferInterfaceFile:Size( )
    return self.buffer_obj:Size( )
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function BufferInterface( obj, offset )
    local self = { BufferObj=true }

    if isstring(obj) and string_lower(obj) == "net" then
        setmetatable(self, BufferInterfaceNet)
        self.buffer_type = "net"
    elseif type(obj) == "File" then
        setmetatable(self, BufferInterfaceFile)
        self.buffer_type = "file"
        self.buffer_obj = obj
    else
        return nil
    end

    return self
end

return BufferInterface, BufferInterfaceNet, BufferInterfaceFile