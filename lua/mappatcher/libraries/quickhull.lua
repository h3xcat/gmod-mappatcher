--[[ Copyright (C) Edgaras Fiodorovas - All Rights Reserved
   - Unauthorized copying of this file, via any medium is strictly prohibited
   - Proprietary and confidential
   - Written by Edgaras Fiodorovas <edgarasf123@gmail.com>, November 2017
   -]]
   
--------------------------------------------------------------------------------

local quickhull = {}

--------------------------------------------------------------------------------
-- New vector structure (GLua Vector components are not as precise as regular Lua numbers)
--------------------------------------------------------------------------------
local Vector2_mt 
Vector2_mt = {}
function Vector2_mt:__index( key )
    if key == "x" then
        return rawget(self, 1)
    elseif key == "y" then
        return rawget(self, 2)
    elseif key == "z" then
        return rawget(self, 3)
    end
    return rawget(self, key) or Vector2_mt[key]
end
function Vector2_mt:__tostring()
    local v1 = self
    return v1[1].." "..v1[2].." "..v1[3]
end
function Vector2_mt:__add( v2 )
    local v1 = self
    return setmetatable( {v1[1]+v2[1], v1[2]+v2[2], v1[3]+v2[3]}, Vector2_mt )
end
function Vector2_mt:__sub( v2 )
    local v1 = self
    return setmetatable( {v1[1]-v2[1], v1[2]-v2[2], v1[3]-v2[3]}, Vector2_mt )
end
function Vector2_mt:__unm()
    local v1 = self
    return setmetatable( {-v1[1],-v1[2],-v1[3]}, Vector2_mt )
end
function Vector2_mt:__mul( n )
    local v1 = self
    if type(v1) == "number" then
        v1 = n
        n = self
    end
    return setmetatable( {v1[1]*n, v1[2]*n, v1[3]*n}, Vector2_mt )
end
function Vector2_mt:__div( n )
    local v1 = self
    return setmetatable( {v1[1]/n, v1[2]/n, v1[3]/n}, Vector2_mt )
end
function Vector2_mt:Dot( v2 )
    local v1 = self
    return v1[1]*v2[1] + v1[2]*v2[2] + v1[3]*v2[3]
end
function Vector2_mt:Distance( v2 )
    local v1 = self
    return math.sqrt( (v2[1]-v1[1])^2 + (v2[2]-v1[2])^2 + (v2[3]-v1[3])^2 )
end
function Vector2_mt:DistToSqr( v2 )
    local v1 = self
    return ( (v2[1]-v1[1])^2 + (v2[2]-v1[2])^2 + (v2[3]-v1[3])^2 )
end
function Vector2_mt:Cross( v2 )
    local v1 = self
    return setmetatable( { v1[2]*v2[3] - v1[3]*v2[2], v1[3]*v2[1] - v1[1]*v2[3], v1[1]*v2[2] - v1[2]*v2[1] }, Vector2_mt )
end
function Vector2_mt:GetNormalized( )
    local v1 = self
    local l = 1/math.sqrt(v1[1]^2 + v1[2]^2 + v1[3]^2)
    return setmetatable( {v1[1]*l, v1[2]*l, v1[3]*l}, Vector2_mt )
end

function Vector2_mt:GetVector( )
    local v1 = self
    local l = 1/math.sqrt(v1[1]^2 + v1[2]^2 + v1[3]^2)
    return Vector(v1[1],v1[2],v1[3])
end

local function Vector2( x, y, z )
    if type(x) == "Vector" then
        return setmetatable( {x.x, x.y, x.z}, Vector2_mt )
    else
        return setmetatable( {x or 0, y or x or 0, z or x or 0}, Vector2_mt )
    end
end

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

local function dist_to_line( point, line_p1, line_p2 )
    local d = (line_p2.vec - line_p1.vec) / line_p2.vec:Distance(line_p1.vec)
    local v = point.vec - line_p1.vec
    local t = v:Dot(d)
    local p = line_p1.vec + t * d;
    return p:Distance(point.vec);
end

local function dist_to_plane( point, plane )
    local d = point.vec:Dot(plane.n) - plane.d
    if math.abs(d) < 4e-12 then return 0 end
    return d
end

local function find_plane( p1, p2, p3 )
    local normal = (p3.vec - p1.vec):Cross(p2.vec - p1.vec):GetNormalized()
    local dist = normal:Dot( p1.vec )
    return {a=normal.x,b=normal.y,c=normal.z,d=dist,n=normal}
end

local function face_vertices( face )
    local first_edge = face.edge
    local cur_edge = first_edge
    
    local vertices = {}
    repeat
        vertices[#vertices + 1] = cur_edge.vert
        cur_edge = cur_edge.next    
    until cur_edge == first_edge
    
    return unpack(vertices)
end

local function create_initial_simplex3( points )
    -- Find base line
    local base_line_dist = 0
    local point1 = nil
    local point2 = nil
    for i=1,#points do
        local p1 = points[i]
        for j=i+1,#points do
            local p2 = points[j]
            local tmp_dist = p1.vec:DistToSqr(p2.vec)
            if tmp_dist > base_line_dist then
                base_line_dist = tmp_dist
                point1 = p1
                point2 = p2
            end
        end
    end
    
    if not point2 then error( "Points doesn't create a line" ) end

    -- Find 3rd point of base triangle
    local point3_dist = 0
    local point3 = nil
    for i=1,#points do
        local p = points[i]
        if p == point1 or p == point2 then continue end
        
        local tmp_dist = dist_to_line(p, point1, point2)
        if tmp_dist > point3_dist then
            point3_dist = tmp_dist
            point3 = p
        end
    end
    
    if not point3 then error( "Points doesn't create a triangle" ) end

    -- First face
    local he_face1 = {plane = find_plane( point1, point2, point3 ), points = {}}
    local he_f1_edge1 = {face = he_face1}
    local he_f1_edge2 = {face = he_face1}
    local he_f1_edge3 = {face = he_face1}
    he_f1_edge1.vert = {vec=point1.vec, point=point1}
    he_f1_edge2.vert = {vec=point2.vec, point=point2}
    he_f1_edge3.vert = {vec=point3.vec, point=point3}
    he_f1_edge1.next = he_f1_edge2
    he_f1_edge2.next = he_f1_edge3
    he_f1_edge3.next = he_f1_edge1
    he_f1_edge1.vert.edge = he_f1_edge1
    he_f1_edge2.vert.edge = he_f1_edge2
    he_f1_edge3.vert.edge = he_f1_edge3
    he_face1.edge = he_f1_edge1
    
    -- Second face
    local he_face2 = {plane = find_plane( point2, point1, point3 ), points = {}}
    local he_f2_edge1 = {face = he_face2}
    local he_f2_edge2 = {face = he_face2}
    local he_f2_edge3 = {face = he_face2}
    he_f2_edge1.vert = {vec=point2.vec, point=point2}
    he_f2_edge2.vert = {vec=point1.vec, point=point1}
    he_f2_edge3.vert = {vec=point3.vec, point=point3}
    he_f2_edge1.next = he_f2_edge2
    he_f2_edge2.next = he_f2_edge3
    he_f2_edge3.next = he_f2_edge1
    he_f2_edge1.vert.edge = he_f2_edge1
    he_f2_edge2.vert.edge = he_f2_edge2
    he_f2_edge3.vert.edge = he_f2_edge3
    he_face2.edge = he_f2_edge1
    
    -- Join faces
    he_f1_edge1.twin = he_f2_edge1
    he_f1_edge2.twin = he_f2_edge3
    he_f1_edge3.twin = he_f2_edge2
    he_f2_edge1.twin = he_f1_edge1
    he_f2_edge2.twin = he_f1_edge3
    he_f2_edge3.twin = he_f1_edge2
    
    point1.ignore = true
    point2.ignore = true
    point3.ignore = true
    return {he_face1,he_face2}
end

local function wrap_points( points, offset ) -- Prepares the points to be used with quickhull
    local ret = {}
    for k, p in pairs( points ) do
        ret[#ret + 1] = {
            vec = Vector2(p + offset),
            face = nil
        }
    end
    return ret
end

local function unwrap_points( points, offset )
    local ret = {}
    for k, p in pairs( points ) do
        ret[#ret + 1] = p.vec:GetVector() - offset
    end
    return ret
end

local function find_lightfaces( point, face, ret )
    if not ret then ret = {} end
    
    if face.lightface or dist_to_plane( point, face.plane ) <= 0 then
        return ret
    end

    face.lightface = true
    ret[#ret + 1] = face

    find_lightfaces( point, face.edge.twin.face, ret )
    find_lightfaces( point, face.edge.next.twin.face, ret )
    find_lightfaces( point, face.edge.next.next.twin.face, ret )
    
    return ret
end

local function next_horizon_edge( horizon_edge )
    local cur_edge = horizon_edge.next
    while cur_edge.twin.face.lightface do
        cur_edge = cur_edge.twin.next    
    end
    return cur_edge
end

local function quick_hull( points )
    local faces = create_initial_simplex3( points )

    -- Assign points to faces
    for k, point in pairs(points) do
        if point.ignore then continue end
        for k1, face in pairs(faces) do
            face.points = face.points or {}
            if dist_to_plane( point, face.plane ) >= 0 then
                face.points[#face.points + 1] = point
                point.face = face
                break
            end
        end
    end

    local face_list = {}  -- (linked list) Faces that been processed (although they can still be removed from list)
    local face_stack = {} -- Faces to be processed
    
    -- Push faces onto stack
    for k1, face in pairs(faces) do
        face_stack[#face_stack + 1] = face
    end
    
    while #face_stack > 0 do
        -- Pop face from stack
        local curface = face_stack[#face_stack]
        face_stack[#face_stack] = nil
        
        -- Ignore previous lightfaces
        if curface.lightface then continue end
        
        -- If no points, the face is processed
        if #curface.points == 0 then
            curface.list_parent = face_list
            face_list = {next=face_list, value=curface}
            
            continue
        end
        
        -- Find distant point
        local point_dist = 0
        local point = nil

        for _, p in pairs(curface.points) do
            local tmp_dist = dist_to_plane(p, curface.plane)
            if tmp_dist > point_dist then
                point_dist = tmp_dist
                point = p
            end
        end
        

        -- Find all faces visible to point
        local light_faces = find_lightfaces( point, curface )
        
        -- Find first horizon edge
        local first_horizon_edge = nil
        for k, face in pairs(light_faces) do
            if not face.edge.twin.face.lightface then 
                first_horizon_edge = face.edge
            elseif not face.edge.next.twin.face.lightface then 
                first_horizon_edge = face.edge.next
            elseif not face.edge.next.next.twin.face.lightface then 
                first_horizon_edge = face.edge.next.next 
            else continue end
            break
        end
        
        -- Find all horizon edges
        local horizon_edges = {}
        local current_horizon_edge = first_horizon_edge
        repeat
            current_horizon_edge = next_horizon_edge( current_horizon_edge )
            horizon_edges[#horizon_edges + 1] = current_horizon_edge
        until current_horizon_edge == first_horizon_edge
        
        -- Assign new faces
        for i=1, #horizon_edges do
            local cur_edge = horizon_edges[i] 
            
            local he_face = {edge=cur_edge}
            
            local he_vert1 = {vec=cur_edge.vert.vec     , point=cur_edge.vert.point}
            local he_vert2 = {vec=cur_edge.next.vert.vec, point=cur_edge.next.vert.point}
            local he_vert3 = {vec=point.vec             , point=point}
            
            local he_edge1 = cur_edge
            local he_edge2 = {}
            local he_edge3 = {}
            
            he_edge1.next = he_edge2
            he_edge2.next = he_edge3
            he_edge3.next = he_edge1
            
            he_edge1.vert = he_vert1
            he_edge2.vert = he_vert2
            he_edge3.vert = he_vert3
            
            he_edge1.face = he_face
            he_edge2.face = he_face
            he_edge3.face = he_face
            
            he_vert1.edge = he_edge1
            he_vert2.edge = he_edge2
            he_vert3.edge = he_edge3
            
            he_face.plane = find_plane( he_vert1, he_vert2, he_vert3 )
            he_face.points = {}
            
            -- Assign points to new faces
            for k, lface in pairs(light_faces) do
                for k1, p in pairs(lface.points) do
                    if dist_to_plane( p, he_face.plane ) > 0 then
                        he_face.points[#he_face.points+1] = p
                        p.face = he_face
                        lface.points[k1] = nil -- This is ok since we are not adding new keys
                    end
                end
            end
        end
        
        -- Connect new faces
        for i=1, #horizon_edges do
            local prev_i = (i-1-1)%#horizon_edges + 1
            local next_i = (i-1+1)%#horizon_edges + 1
            local prev_edge1 = horizon_edges[prev_i]
            local cur_edge1 = horizon_edges[i]
            local next_edge1 = horizon_edges[next_i]
            
            local prev_edge2 = prev_edge1.next
            
            local cur_edge2 = cur_edge1.next
            local cur_edge3 = cur_edge2.next
            
            local next_edge3 = next_edge1.next.next
            
            cur_edge2.twin = next_edge3
            cur_edge3.twin = prev_edge2
            face_stack[#face_stack + 1] = cur_edge1.face
        end
    end
    
    -- Convert linked list into array
    local ret_points_added = {}
    local ret_points = {}
    local ret_faces = {}
    local l = face_list
    while l.value do
        local face = l.value
        l = l.next
        if face.lightface then continue end -- Filter out invalid faces
        
        for k,vert in pairs({face_vertices(face)}) do
            local point = vert.point
            if ret_points_added[point] then continue end
            ret_points_added[point] = true
            ret_points[#ret_points + 1] = vert.point
        end
        ret_faces[#ret_faces+1] = face
    end
    
    return ret_points, ret_faces
end

local function find_uv(point, textureVecs, texSizeX, texSizeY)
    local x,y,z = point.x, point.y, point.z
    local u = textureVecs[1].x * x + textureVecs[1].y * y + textureVecs[1].z * z + textureVecs[1].offset
    local v = textureVecs[2].x * x + textureVecs[2].y * y + textureVecs[2].z * z + textureVecs[2].offset
    return u/texSizeX, v/texSizeY
end

local COLOR_WHITE = Color(255,255,255)
local function face_to_mesh_vertex(face, color, offset)
    local norm = face.plane.n
    local ref = Vector2(0,0,-1)
    if math.abs( norm:Dot( Vector2(0,0,1) ) ) == 1 then
        ref = Vector2(0,1,0)
    end
    
    local tv1 = norm:Cross( ref ):Cross( norm ):GetNormalized()
    local tv2 = norm:Cross( tv1 )
    local textureVecs = {{x=tv2.x,y=tv2.y,z=tv2.z,offset=0},
                        {x=tv1.x,y=tv1.y,z=tv1.z,offset=0}}-- texinfo.textureVecs
                        
    local p1, p2, p3 = face_vertices(face)
    
    local u1,v1 = find_uv(p1.vec, textureVecs, 32, 32)
    local u2,v2 = find_uv(p2.vec, textureVecs, 32, 32)
    local u3,v3 = find_uv(p3.vec, textureVecs, 32, 32)
    
    return  {pos=(p1.vec-offset):GetVector(),color=color or COLOR_WHITE,normal=norm:GetVector(),u=u1,v=v1},
            {pos=(p2.vec-offset):GetVector(),color=color or COLOR_WHITE,normal=norm:GetVector(),u=u2,v=v2},
            {pos=(p3.vec-offset):GetVector(),color=color or COLOR_WHITE,normal=norm:GetVector(),u=u3,v=v3}
end
--------------------------------------------------------------------------------
-- Works similar to pcall, but with infinite loop protection
local protected_run
do
    local function protected_run_hook_check()
        error("Infinite loop detected!")
    end
    local function protected_run_pcall( func, ... )
        debug.sethook(protected_run_hook_check, "", 50000000)
        return func(...)
    end
    function protected_run( func, ... )
        local old_hook = {debug.gethook()}
        local ret = {pcall(protected_run_pcall, func, ...)}
        debug.sethook(unpack(old_hook))
        return unpack(ret)
    end
end
--------------------------------------------------------------------------------
function quickhull.BuildMeshFromPoints( points, convex_mesh )
    if #points < 3 then error("Must have at least 3 points to build convex hull mesh.") end
    local offset = -points[1]

    local points_v2 = wrap_points(points, offset)

    local convex_mesh = convex_mesh

    local succ, new_points_v2, faces = protected_run( quick_hull, points_v2 )

    if succ then
        local vertices = {}
        local offset_v2 = Vector2(offset)
        for k, face in pairs(faces) do
            for k, v in pairs( {face_to_mesh_vertex(face, COLOR_WHITE, offset_v2 )} ) do
                vertices[#vertices + 1] = v
            end
        end

        if CLIENT and #vertices >= 6 then -- No serverside meshes exist
            if not convex_mesh then convex_mesh = Mesh() end
            convex_mesh:BuildFromTriangles(vertices)
        end
        
        return (#vertices >= 6), unwrap_points( new_points_v2, offset ), convex_mesh
    else
        return false, {points[1]}
    end
end

return quickhull