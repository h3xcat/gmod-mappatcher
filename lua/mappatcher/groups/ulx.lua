
local check_user = function(ply, group)
	if not IsValid(ply) then return false end

	return ply:CheckGroup(group)
end

hook.Add("UCLChanged", "MapPatcher_Groups_ULX", function()
	for group, perms in pairs(ULib.ucl.groups) do
		MapPatcher.Groups.Register(group, check_user, "[ULX] "..group )
	end
end)