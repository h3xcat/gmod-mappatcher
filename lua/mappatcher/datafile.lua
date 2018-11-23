local BufferInterface = MapPatcher.Libs.BufferInterface

-- These are depecated, the types are stored as strings instead
local MAPPATCHER_MESH_PLAYERCLIP  = 0
local MAPPATCHER_MESH_KILL        = 1
local MAPPATCHER_MESH_BULLETCLIP  = 2
local MAPPATCHER_MESH_PROPCLIP    = 3
local MAPPATCHER_MESH_CLIP        = 4

--------------------------------------------------------------------------------

local datafile_header = "MPDF"
local datafile_version = 2

--[[
    file format: [header(4bytes)][version(1byte)][data_block][data_block][data_block]...
    data_block: [data_type(2bytes)][data_len(4bytes)][data(<data_len>bytes)]
]]

local DATABLOCK_TERMINATE = 0
local DATABLOCK_MESH_PLAYERCLIP = 1
local DATABLOCK_MESH_KILL = 2
local DATABLOCK_MESH_BULLETCLIP = 3
local DATABLOCK_MESH_PROPCLIP = 4
local DATABLOCK_MESH_CLIP = 5
local DATABLOCK_TOOL_OBJECT = 6

--------------------------------------------------------------------------------

local meshtype2blocktype = {
    [MAPPATCHER_MESH_PLAYERCLIP]    = DATABLOCK_MESH_PLAYERCLIP,
    [MAPPATCHER_MESH_KILL]          = DATABLOCK_MESH_KILL,
    [MAPPATCHER_MESH_BULLETCLIP]    = DATABLOCK_MESH_BULLETCLIP,
    [MAPPATCHER_MESH_PROPCLIP]      = DATABLOCK_MESH_PROPCLIP,
    [MAPPATCHER_MESH_CLIP]          = DATABLOCK_MESH_CLIP,
}


local function basic_mesh_reader( buffer, len, class_name )
    local object = MapPatcher.NewToolObject( class_name )
    if not object then return end
    local points = object.points
    local n_points = buffer:ReadUInt8()
    for i=1, n_points do
        local point = Vector()
        point.x = buffer:ReadFloat()
        point.y = buffer:ReadFloat()
        point.z = buffer:ReadFloat()

        points[i] = point
    end

    local object_id = #MapPatcher.Objects + 1
    object.ID = object_id
    MapPatcher.Objects[object_id] = object
    object:Initialize( )
end

local data_block_readers = {
    [DATABLOCK_MESH_PLAYERCLIP] = function(buffer, len) basic_mesh_reader(buffer, len, "playerclip") end,
    [DATABLOCK_MESH_KILL]       = function(buffer, len) basic_mesh_reader(buffer, len, "kill") end,
    [DATABLOCK_MESH_BULLETCLIP] = function(buffer, len) basic_mesh_reader(buffer, len, "bulletclip") end,
    [DATABLOCK_MESH_PROPCLIP]   = function(buffer, len) basic_mesh_reader(buffer, len, "propclip") end,
    [DATABLOCK_MESH_CLIP]       = function(buffer, len) basic_mesh_reader(buffer, len, "clip") end,
    [DATABLOCK_TOOL_OBJECT]      = function(buffer, len)
        -- Object type
        local class_name_len = buffer:ReadUInt8( )
        local class_name = buffer:ReadData( class_name_len )

        -- Object version
        local object_version = buffer:ReadUInt16( )

        -- Object data length
        local data_len = buffer:ReadUInt32( )
        
        -- Object data
        local data_start, data_end
        data_start = buffer:Tell()
        
        local object = MapPatcher.NewToolObject( class_name )
        
        if object and object:ReadFromBuffer( buffer, data_len, version ) ~= false then
            data_end = buffer:Tell()

            if data_len ~= (data_end - data_start) then
                ErrorNoHalt( "[MapPatcher] Object data read incorrectly (class:"..class_name..")(data_len:"..data_len..")(read:"..(data_end-data_start)..")\n" )
            else
                local object_id = #MapPatcher.Objects + 1
                object.ID = object_id
                MapPatcher.Objects[object_id] = object
                object:Initialize( )
            end
        elseif object then
            ErrorNoHalt( "[MapPatcher] Could not read object data (class:"..class_name..")(object_version:"..version..")(current_version:"..object.Version..")\n" )
        else
            ErrorNoHalt( "[MapPatcher] Unknown object class (class:"..class_name..")\n" )
        end

        buffer:Seek( data_start + data_len )
    end,
}

local data_block_writers = {
    [DATABLOCK_MESH_PLAYERCLIP] = basic_mesh_writer,
    [DATABLOCK_MESH_KILL]       = basic_mesh_writer,
    [DATABLOCK_MESH_BULLETCLIP] = basic_mesh_writer,
    [DATABLOCK_MESH_PROPCLIP]   = basic_mesh_writer,
    [DATABLOCK_MESH_CLIP]       = basic_mesh_writer,
    [DATABLOCK_TOOL_OBJECT]      = function( buffer, object )
        local class_name = object:GetClassName()
        local class_name_len = #class_name

        -- Object type
        buffer:WriteUInt8( class_name_len )
        buffer:WriteData( class_name, class_name_len)

        -- Object version
        buffer:WriteUInt16( object.Version )

        -- Object data length
        buffer:WriteUInt32( 0 ) -- updated after data written
        
        -- Object data
        local data_start, data_end
        data_start = buffer:Tell()
        object:WriteToBuffer( buffer )
        data_end = buffer:Tell()

        -- Update data length
        local data_len = (data_end - data_start)
        buffer:Seek( data_start - 4 )
        buffer:WriteUInt32( data_len )
        buffer:Seek( data_end )        
    end,
}

function MapPatcher.SaveObjectsToFile()
    file.CreateDir( "mappatcher" )
    local filename = "mappatcher/" .. string.lower( game.GetMap() ) .. ".dat"
    local fl = file.Open( filename, "wb", "DATA" )

    local buffer = BufferInterface( fl )
    buffer:WriteData( datafile_header, 4 )
    buffer:WriteUInt8( datafile_version )
    
    -- Write objects
    for object_id, object in pairs(MapPatcher.Objects) do
        if not IsValid(object) then continue end

        local block_type = DATABLOCK_TOOL_OBJECT
        local block_len = 0
        local block_data_start 
        local block_data_end 

        buffer:WriteUInt16( block_type )
        buffer:WriteUInt32( block_len )
        
        block_data_start = buffer:Tell()
        data_block_writers[block_type]( buffer, object )
        block_data_end = buffer:Tell()

        -- Overwrite block_len
        block_len = (block_data_end - block_data_start)
        buffer:Seek( block_data_start - 4 )
        buffer:WriteUInt32( block_len )
        buffer:Seek( block_data_end )
    end

    -- Write termination block
    buffer:WriteUInt16(DATABLOCK_TERMINATE)
    buffer:WriteUInt32(0)

    fl:Close()
end


function MapPatcher.LoadObjectsFromFile()
    -- Clear old objects
    for object_id, object in pairs(MapPatcher.Objects) do
        object:Terminate()
    end
    MapPatcher.Objects = {}

    local filename = "mappatcher/" .. string.lower( game.GetMap() ) .. ".dat"
    if not file.Exists( filename, "DATA" ) then return end
    local fl = file.Open( filename, "rb", "DATA" )
    local buffer = BufferInterface( fl )

    local header = buffer:ReadData(4)
    -- Compare data file header
    if header ~= datafile_header then
        fl:Close()
        return ErrorNoHalt( "[MapPatcher] /data/", filename," - Invalid file header (", header, ")\n" )
    end

    local version = buffer:ReadUInt8()
    -- Compare data file version
    if version ~= datafile_version then
        fl:Close()
        return ErrorNoHalt( "[MapPatcher] /data/", filename," - Unsuported data file version (", version, ")\n" )
    end


    -- Read Blocks
    local block_type
    local block_len
    local block_data_start
    local block_data_end
    repeat
        if buffer:Tell() >= buffer:Size()-1 then break end

        block_type = buffer:ReadUInt16()
        block_len = buffer:ReadUInt32()

        block_start = buffer:Tell()
        if data_block_readers[block_type] then
            data_block_readers[block_type]( buffer, block_len )
        elseif block_type ~= DATABLOCK_TERMINATE then
            ErrorNoHalt( "[MapPatcher] /data/",filename," - Unknown block type (", block_type, ")\n" )
        end
        block_end = buffer:Tell()

        if block_len ~= (block_end-block_start) then
            ErrorNoHalt( "[MapPatcher] Block data read incorrectly (type:"..block_type..")(data_len:"..block_len..")(read:"..(block_end-block_start)..")\n" )
        end

        buffer:Seek( block_start + block_len )
    until block_type == DATABLOCK_TERMINATE

    if block_type ~= DATABLOCK_TERMINATE then
        ErrorNoHalt( "[MapPatcher] /data/",filename," - Missing termination block!\n" )
    end

    fl:Close()
end