MapPatcher = MapPatcher or {}
MapPatcher.Config = include("mappatcher/config.lua")
MapPatcher.Libs = {
    luabsp          = include "libraries/luabsp.lua",
    quickhull       = include "libraries/quickhull.lua",
    BufferInterface = include "libraries/bufferinterface.lua",
    Stream          = include "libraries/stream.lua",
}

MapPatcher.Tools = {}
MapPatcher.Objects = {}

function MapPatcher.HasAccess( ply )
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    if ulx and ULib.ucl.query( ply, "ulx mappatcher" ) then return true end
    if serverguard and serverguard.player:HasPermission( ply , "MapPatcher Editor") then return true end

    if table.HasValue( MapPatcher.Config.AccessSteamID, ply:SteamID() ) then return true end
    if MapPatcher.Config.AccessSuperAdmin and ply:IsSuperAdmin() then return true end
    if MapPatcher.Config.AccessAdmin and ply:IsAdmin() then return true end
    if MapPatcher.Config.AccessUserGroup then
        for k, usergroup in pairs( MapPatcher.Config.AccessUserGroup ) do
            if ply:IsUserGroup( usergroup ) then
                return true
            end
        end
    end

    return false
end

function MapPatcher.LoadTools()
    local files = file.Find( "mappatcher/tools/*.lua", "LUA" )

    local _TOOL = TOOL
    for k, class_file in pairs(files) do
        AddCSLuaFile( "mappatcher/tools/"..class_file )
        local class_name = string.lower( string.StripExtension( class_file ) )
        TOOL = { ClassName = class_name }
        include( "mappatcher/tools/"..class_file )

        function TOOL:__index( key )
            local meta = getmetatable(self)

            local val = rawget(self, key) or (self ~= meta and meta[key])
            if val then return val end

            local base = rawget(self,"Base")
            if base then
                return MapPatcher.Tools[base][key]
            end
        end

        function TOOL:__tostring( )
            return self:ToString( )
        end

        MapPatcher.Tools[class_name] = setmetatable(TOOL, TOOL)
    end
    TOOL = _TOOL
end
MapPatcher.LoadTools()

function MapPatcher.NewToolObject( class_name, id )
    if not MapPatcher.Tools[class_name] then return end
    id = id or 0
    local new_object = setmetatable( {object=true, ID=id}, MapPatcher.Tools[class_name] )
    if id ~= 0 then
        MapPatcher.Objects[id] = new_object
    end
    new_object:ObjectCreated( )
    return new_object
end
MapPatcher.NULL = MapPatcher.NewToolObject( "null" )

hook.Add( "Initialize", "MapPatcher", function()
    if CLIENT then
        concommand.Add( "mappatcher", function( ply, cmd, args, argStr )
            RunConsoleCommand( "_mappatcher" )
        end )
    elseif SERVER then
        concommand.Add( "_mappatcher", function( ply, cmd, args, argStr )
            if not IsValid(ply) then return end
            if not MapPatcher.HasAccess( ply ) then 
                ply:PrintMessage( HUD_PRINTCONSOLE, "[MapPatcher] Access Denied!" )
                return
            end
            MapPatcher.StartEditMode( ply )
        end )
    end
end )

--------------------------------------------------------------------------------

hook.Add( "ShouldCollide", "MapPatcherObject", function(ent1, ent2)
    local b1, b2
    if ent1.MapPatcherObject and ent1.object then
        b1 = ent1.object:EntShouldCollide( ent2 )
    end
    if ent2.MapPatcherObject and ent2.object then
        b2 = ent2.object:EntShouldCollide( ent1 )
    end

    if b1 == false or b2 == false then
        return false
    elseif b1 == true or b2 == true then
        return true
    end
end, HOOK_HIGH )


hook.Add( "CanTool", "MapPatcherObject", function( ply, tr, tool )
    if IsValid(tr.Entity) and tr.Entity.MapPatcherObject then
        return false
    end
end, HOOK_HIGH )

hook.Add( "PhysgunPickup", "MapPatcherObject", function( ply, ent )
    if ent.MapPatcherObject then
        return false
    end
end, HOOK_HIGH )