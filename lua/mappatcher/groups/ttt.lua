if not GAMEMODE_NAME == "terrortown" then return end

MapPatcher.Groups.Register("ttt_traitor", function(ply) return ply:IsTraitor() end, CLIENT and "[TTT] "..language.GetPhrase("#mappatcher.groups.ttt.traitor") )
MapPatcher.Groups.Register("ttt_detective", function(ply) return ply:IsDetective() end, CLIENT and "[TTT] "..language.GetPhrase("#mappatcher.groups.ttt.detective") ) 
