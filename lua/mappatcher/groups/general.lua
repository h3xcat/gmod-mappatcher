-- These should be rewriten by ulx.lua, if ULX is enabled
MapPatcher.Groups.Register("everyone", function(ply) return true end, "#mappatcher_groups_everyone" )
MapPatcher.Groups.Register("admin", function(ply) return ply:IsAdmin() end, "mappatcher_groups_admin" )
MapPatcher.Groups.Register("superadmin", function(ply) return ply:IsSuperAdmin() end, "mappatcher_groups_superadmin" )
