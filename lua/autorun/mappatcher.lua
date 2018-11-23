MsgN( "[MapPatcher] Version 2.4.1" )
MsgN( "[MapPatcher] Written by H3xCat (STEAM_0:0:20178582)")

if SERVER then
    AddCSLuaFile( "skins/mappatcher.lua" )

    AddCSLuaFile( "mappatcher/libraries/luabsp.lua" )
    AddCSLuaFile( "mappatcher/libraries/quickhull.lua" )
    AddCSLuaFile( "mappatcher/libraries/bufferinterface.lua" )
    AddCSLuaFile( "mappatcher/libraries/stream.lua" )

    AddCSLuaFile( "mappatcher/editor/screen.lua" )
    AddCSLuaFile( "mappatcher/editor/menu.lua" )
    
    AddCSLuaFile( "mappatcher/config.lua" )
    AddCSLuaFile( "mappatcher/shared.lua" )
    AddCSLuaFile( "mappatcher/cl_init.lua" )
    AddCSLuaFile( "mappatcher/cl_editor.lua" )
    
    include( "mappatcher/shared.lua" )
    include( "mappatcher/datafile.lua" )
    include( "mappatcher/init.lua" )
elseif CLIENT then
    timer.Simple( 0, function() include( "skins/mappatcher.lua" ) end )

    include( "mappatcher/editor/screen.lua" )
    include( "mappatcher/editor/menu.lua" )

    include( "mappatcher/shared.lua" )
    include( "mappatcher/cl_init.lua" )
    include( "mappatcher/cl_editor.lua" )
end