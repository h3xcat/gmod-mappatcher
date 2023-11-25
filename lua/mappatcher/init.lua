local quickhull = MapPatcher.Libs.quickhull
local BufferInterface = MapPatcher.Libs.BufferInterface

util.AddNetworkString( "mappatcher_editmode_start" )
util.AddNetworkString( "mappatcher_submit" )
util.AddNetworkString( "mappatcher_update" )
util.AddNetworkString( "mappatcher_reload_entities" )
util.AddNetworkString( "mappatcher_editor_pvs" )

MapPatcher.Brushes = MapPatcher.Brushes or {}

function MapPatcher.StartEditMode( ply )
    if not MapPatcher.HasAccess(ply) then return end
    MsgN( "[MapPatcher] " .. ply:Nick() .. "<" .. ply:SteamID() .. "> entered edit mode ")
    net.Start( "mappatcher_editmode_start" )
    net.Send( ply )
end

function MapPatcher.NetworkObjects( objects, ply )
    if not istable(objects) then error("First argument must be table of objects") return end
    if objects.object then objects = {objects} end

    net.Start( "mappatcher_update" )
    net.WriteUInt( #objects, 16 )

    for k, object in pairs(objects) do
        net.WriteUInt( object.ID, 16 )
        net.WriteString( object.ClassName )
        object:WriteToBuffer( BufferInterface("net") )
        object:SessionWriteToBuffer( BufferInterface("net") )
    end

    if ply == nil then
        net.Broadcast( )
    else
        net.Send( ply )
    end
end

function MapPatcher.ReloadEntities()
    for object_id, object in pairs( MapPatcher.Objects ) do
        object:UpdateEntity( )
    end
    MapPatcher.NetworkObjects( MapPatcher.Objects  )
end

hook.Add( "InitPostEntity", "MapPatcher", function()
    MapPatcher.LoadObjectsFromFile()
end)

net.Receive( "mappatcher_reload_entities", function( len, ply )
    if not MapPatcher.HasAccess( ply ) then return end
    MapPatcher.ReloadEntities()
    MsgN( "[MapPatcher] Reloaded entities!" )
end )

net.Receive( "mappatcher_submit", function( len, ply )
    if not MapPatcher.HasAccess( ply ) then return end
    local object_id = net.ReadUInt( 16 )
    local object_class = net.ReadString( )
    local prev_object_str = "[" .. object_id .. "] <unknown>"
    local new_object = false

    if object_id == 0 then
        -- Find slot in table to replace
        local new_object_id = #MapPatcher.Objects + 1
        new_object = true
        for object_id, object in ipairs(MapPatcher.Objects) do
            if not IsValid(object) then
                object:Terminate()
                new_object_id = object_id
                break
            end
        end
        object_id = new_object_id
    else
        local prev_object = MapPatcher.Objects[object_id]
        if not prev_object then return end
        if IsValid( prev_object ) then 
            prev_object_str = tostring(prev_object)
            prev_object:Terminate()
        end
    end

    local object = MapPatcher.NewToolObject( object_class )
    object:ReadFromBuffer( BufferInterface("net") )
    object.ID = object_id

    if object_class == 'null' then
        MsgN( "[MapPatcher] " .. ply:Nick() .. "<" .. ply:SteamID() .. "> removed object " .. prev_object_str )
    elseif new_object then
        MsgN( "[MapPatcher] " .. ply:Nick() .. "<" .. ply:SteamID() .. "> created object " .. tostring(object))
    elseif tostring(object) == prev_object_str then
        MsgN( "[MapPatcher] " .. ply:Nick() .. "<" .. ply:SteamID() .. "> updated object " .. tostring(object))
    else
        MsgN( "[MapPatcher] " .. ply:Nick() .. "<" .. ply:SteamID() .. "> replaced object " .. prev_object_str .. " with " .. tostring(object))
    end

    if object:ShouldSave() then
        MapPatcher.Objects[object_id] = object
        object:Initialize( )
        MapPatcher.NetworkObjects( {object} )
        MapPatcher.SaveObjectsToFile( )
    end
    
end )

hook.Add( "PlayerInitialSpawn", "MapPatcher", function( ply )
    if #MapPatcher.Objects == 0 then return end
    MapPatcher.NetworkObjects( MapPatcher.Objects, ply )
end )

hook.Add( "PostCleanupMap", "MapPatcher", function()
    for k, object in pairs( MapPatcher.Objects ) do
        object:PostCleanupMap( )
    end
    MapPatcher.NetworkObjects( MapPatcher.Objects  )
end)

MapPatcher.PVS = MapPatcher.PVS or {}

net.Receive( "mappatcher_editor_pvs", function( len, ply )
    if not MapPatcher.HasAccess( ply ) then return end
	MapPatcher.PVS[ply] = net.ReadBool() and net.ReadVector() or nil
end )

hook.Add("SetupPlayerVisibility", "MapPatcher", function(ply, pViewEntity)
	if IsValid(ply) and MapPatcher.PVS[ply] then
		AddOriginToPVS(MapPatcher.PVS[ply])
	end
end)