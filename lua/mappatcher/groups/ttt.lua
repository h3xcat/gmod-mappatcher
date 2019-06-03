if not GAMEMODE_NAME == "terrortown" then return end

MapPatcher.Groups.Register("ttt_traitor", function(ply) return ply:IsTraitor() end, "[TTT] Traitor" )
MapPatcher.Groups.Register("ttt_detective", function(ply) return ply:IsDetective() end, "[TTT] Detective" )
