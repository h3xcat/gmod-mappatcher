--[[ Copyright (C) Edgaras Fiodorovas - All Rights Reserved
   - Unauthorized copying of this file, via any medium is strictly prohibited
   - Proprietary and confidential
   - Written by Edgaras Fiodorovas <edgarasf123@gmail.com>, November 2017
   -]]
   
--------------------------------------------------------------------------------

local quickhull = MapPatcher.Libs.quickhull
local BufferInterface = MapPatcher.Libs.BufferInterface

util.AddNetworkString( "mappatcher_editmode_start" )
util.AddNetworkString( "mappatcher_submit" )
util.AddNetworkString( "mappatcher_update" )
util.AddNetworkString( "mappatcher_reload_entities" )

MapPatcher.Brushes = MapPatcher.Brushes or {}

function MapPatcher.StartEditMode( ply )
    if not MapPatcher.HasAccess(ply) then return end
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

    if object_id == 0 then
        -- Find slot in table to replace
        local new_object_id = #MapPatcher.Objects + 1
        for object_id, object in ipairs(MapPatcher.Objects) do
            if not IsValid(object) then
                object:Terminate()
                new_object_id = object_id
                break
            end
        end
        object_id = new_object_id
    else
        local old_object = MapPatcher.Objects[object_id]
        if not old_object then return end
        if IsValid( old_object ) then 
            old_object:Terminate()
        end
    end

    local object = MapPatcher.NewToolObject( object_class )
    object:ReadFromBuffer( BufferInterface("net") )
    object.ID = object_id

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