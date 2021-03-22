-- These should be rewriten by ulx.lua, if ULX is enabled
MapPatcher.Groups.Register("everyone", function(ply) return true end, "#mappatcher.groups.general.everyone" )
MapPatcher.Groups.Register("admin", function(ply) return ply:IsAdmin() end, "#mappatcher.groups.general.admin" )
MapPatcher.Groups.Register("superadmin", function(ply) return ply:IsSuperAdmin() end, "mappatcher.groups.general.superadmin" )
