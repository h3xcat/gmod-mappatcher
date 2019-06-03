-- These should be rewriten by ulx.lua, if ULX is enabled
MapPatcher.Groups.Register("everyone", function(ply) return true end, "Everyone" )
MapPatcher.Groups.Register("admin", function(ply) return ply:IsAdmin() end, "admin" )
MapPatcher.Groups.Register("superadmin", function(ply) return ply:IsSuperAdmin() end, "superadmin" )
