local CONFIG = {}

--------------------------------------------------------------------------------
-- CONFIG BEGIN ----------------------------------------------------------------
--------------------------------------------------------------------------------

-- If you have ULX or ServerGuard installed, you don't need to change any access 
-- configs bellow, you can modify command access directly through admin panel.

CONFIG.AccessSuperAdmin = true -- Change it to true to allow superadmins
CONFIG.AccessAdmin      = false -- Change it to true to allow admins
CONFIG.AccessSteamID = {        -- Add/replace steamid's to give access to individual players
    "STEAM_0:0:0",
    "STEAM_0:0:0",
}
CONFIG.AccessUserGroup = {
    --"owner",
    --"superadmin",
}

-- Advanced --------------------------------------------------------------------

-- Loads map clip brushes as single renderable object
CONFIG.MapClipBrushesAsSingleObject = true 

--------------------------------------------------------------------------------
-- CONFIG END ------------------------------------------------------------------
--------------------------------------------------------------------------------

return CONFIG
