MapPatcher.Groups = MapPatcher.Groups or {}
local Groups = MapPatcher.Groups
Groups.groups = Groups.groups or {}

function Groups.Register( group, check_func, name )
	Groups.groups[group] = {
		check_func = check_func,
		name = name or group
	}
end

function Groups.Unregister( group )
	Groups.groups[group] = nil
end


function Groups.Check( group, ply )
	if not Groups.groups[group] then return false end
	return Groups.groups[group]["check_func"](ply, group)
end


function Groups.GetGroups()
	return table.GetKeys(Groups.groups)
end

function Groups.GetName( group )
	if not Groups.groups[group] then return group end
	return Groups.groups[group]["name"]
end



function MapPatcher.LoadGroups()
    local files = file.Find( "mappatcher/groups/*.lua", "LUA" )
    for k, group_file in pairs(files) do
    	MsgN( "[MapPatcher] Loading mappatcher/groups/"..group_file)
        AddCSLuaFile( "mappatcher/groups/"..group_file )
        include( "mappatcher/groups/"..group_file )
    end
end
MapPatcher.LoadGroups()
