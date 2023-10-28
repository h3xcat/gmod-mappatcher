local BufferInterface = MapPatcher.Libs.BufferInterface

MapPatcher.CVarDraw = CreateClientConVar( "mappatcher_draw", "0", false, false, "should map patcher draw")
cvars.AddChangeCallback( "mappatcher_draw", function( convar_name, value_old, value_new )
    if not MapPatcher.HasAccess( LocalPlayer() ) then return end

    if tobool(value_new) then
        MapPatcher.Editor.LoadMapClipBrushes()
    end
end, "mappatcher_draw" )

net.Receive( "mappatcher_update", function( len )
    local n_objects = net.ReadUInt( 16 )
    for i = 1, n_objects do
        local object_id = net.ReadUInt( 16 )
        local object_class = net.ReadString()
        
        local object = MapPatcher.NewToolObject( object_class )
        object.ID = object_id
        MapPatcher.Objects[object_id] = object

        local buffer = BufferInterface("net")
        object:ReadFromBuffer( buffer )
        object:SessionReadFromBuffer( buffer )

        object:Initialize()
        
        MsgN( "[MapPatcher] Object update: id("..object_id..") class("..object_class..")" )
    end
    if MapPatcher.Editor.Enabled then
        MapPatcher.Editor.UpdateMenu( )
    end
end )
