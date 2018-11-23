--[[ Copyright (C) Edgaras Fiodorovas - All Rights Reserved
   - Unauthorized copying of this file, via any medium is strictly prohibited
   - Proprietary and confidential
   - Written by Edgaras Fiodorovas <edgarasf123@gmail.com>, November 2017
   -]]
   
--------------------------------------------------------------------------------

local CATEGORY_NAME = "Map Patcher"

function MapPatcher.ulx_mappatcher( calling_ply )
    MapPatcher.StartEditMode( calling_ply )
end
local ulx_mappatcher = ulx.command( CATEGORY_NAME, "ulx mappatcher", MapPatcher.ulx_mappatcher )
ulx_mappatcher:defaultAccess( ULib.ACCESS_SUPERADMIN )
ulx_mappatcher:help( "Open map patcher editor." )