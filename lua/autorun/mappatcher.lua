
MsgN( "[MapPatcher] Written by H3xCat (STEAM_0:0:20178582)")



---------------------------------------------------------------------------
-- Check if git submodules exist
do
	local submodules = {
		"mappatcher/lib_luabsp/luabsp.lua",
		"mappatcher/lib_quickhull/quickhull.lua",
		"mappatcher/lib_bufferinterface/bufferinterface.lua",
		"mappatcher/lib_stream/stream.lua"
	}

	local ok = true
	for k, submodule in pairs(submodules) do
		if not file.Exists( submodule, "LUA") then 
			ErrorNoHalt( "[MapPatcher] Missing submodule: ",submodule,"\n" )
			ok = false
		end
	end

	if not ok then

		if CLIENT then
			hook.Add( "HUDPaint", "MapPatcher_SubmoduleWarning", function()
				surface.SetDrawColor( 255, 0, 0, 255 )
				surface.DrawRect( 100, 100, 405, 120 )

				surface.SetTextColor( 255, 255, 255 )
				
				surface.SetTextPos( 120, 107 )
				surface.SetFont( "DermaLarge" )
				surface.DrawText( "MapPatcher failed to load!" )
				
				surface.SetFont( "DermaDefault" )
				surface.SetTextPos( 120, 140 )
				surface.DrawText( "MapPatcher is missing required submodules.")
				
				surface.SetTextPos( 120, 165 )
				surface.DrawText( "This is most likely due to downloading the script using GitHub's \"Download ZIP\"" )
				surface.SetTextPos( 120, 180 )
				surface.DrawText( "button, which will give you incomplete script. Please follow the instructions on")
				surface.SetTextPos( 120, 195 )
				surface.DrawText( "GitHub, or use workshop version of the script." )
			end )
		end
		return nil -- Stop the rest of the addon from loading
	end
end
---------------------------------------------------------------------------



if SERVER then
    AddCSLuaFile( "skins/mappatcher.lua" )

    AddCSLuaFile( "mappatcher/lib_luabsp/luabsp.lua" )
    AddCSLuaFile( "mappatcher/lib_quickhull/quickhull.lua" )
    AddCSLuaFile( "mappatcher/lib_bufferinterface/bufferinterface.lua" )
    AddCSLuaFile( "mappatcher/lib_stream/stream.lua" )

    AddCSLuaFile( "mappatcher/editor/screen.lua" )
    AddCSLuaFile( "mappatcher/editor/menu.lua" )
    
    AddCSLuaFile( "mappatcher/config.lua" )
    AddCSLuaFile( "mappatcher/shared.lua" )
    AddCSLuaFile( "mappatcher/groups.lua" )
    AddCSLuaFile( "mappatcher/cl_init.lua" )
    AddCSLuaFile( "mappatcher/cl_editor.lua" )
    AddCSLuaFile( "mappatcher/groups.lua" )
    
    include( "mappatcher/shared.lua" )
    include( "mappatcher/groups.lua" )
    include( "mappatcher/datafile.lua" )
    include( "mappatcher/init.lua" )
elseif CLIENT then
    timer.Simple( 0, function() include( "skins/mappatcher.lua" ) end )

    include( "mappatcher/editor/screen.lua" )
    include( "mappatcher/editor/menu.lua" )

    include( "mappatcher/shared.lua" )
    include( "mappatcher/groups.lua" )
    include( "mappatcher/cl_init.lua" )
    include( "mappatcher/cl_editor.lua" )
end