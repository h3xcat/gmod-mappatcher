local quickhull = MapPatcher.Libs.quickhull

TOOL.Base = "base"

--------------------------------------------------------------------------------
function TOOL:WriteToBuffer( buffer )
    local points = self.points
    local n_points = math.min( #points, 0xffff )
    buffer:WriteUInt16(n_points)
    for i=1, n_points do
        buffer:WriteVector( points[i] )
    end
end

function TOOL:ReadFromBuffer( buffer, len, version )
    if version and version ~= self.Version then return false end

    local points = {}
    local n_points = buffer:ReadUInt16()
    for i=1, n_points do
        points[i] = buffer:ReadVector( )
    end
    self.points = points
    self.cached_origin = nil
end

function TOOL:SessionWriteToBuffer( buffer )
    if IsValid(self.entity) then
        buffer:WriteUInt16( self.entity:EntIndex() )
        buffer:WriteUInt32( self.entity:GetCreationID() )
    else
        buffer:WriteUInt16( 0 )
        buffer:WriteUInt32( 0 )
    end
end

function TOOL:SessionReadFromBuffer( buffer, len )
    self.entity_id = buffer:ReadUInt16( )
    self.entity_cid = buffer:ReadUInt32( )
end

--------------------------------------------------------------------------------
function TOOL:PreviewPaint( panel, w, h )
    local x, y = panel:LocalToScreen( 0, 0 )
    cam.Start3D(Vector(-1.7,-1.7,1.2), Angle(30,45,0), 90, x, y, w, h, 0, 1000)
        render.SetMaterial(MapPatcher.GetToolMaterial(self.ClassName))
        render.DrawBox( Vector(), Angle(0,RealTime()*40,0), Vector(-1,-1,-1), Vector(1,1,1), Color(255,255,255), true )

        render.DrawWireframeBox( Vector(), Angle(0,RealTime()*40,0), Vector(-1,-1,-1), Vector(1,1,1), Color(255,255,255), true )
    cam.End3D()
end

function TOOL:ObjectCreated()
    self.points = {}
end

function TOOL:LeftClick( pos )
    local points = self.points
    
    if #points >= 255 then return end
    points[#points + 1] = pos
    self.cached_origin = nil

    self:BuildMesh( true )
end

local material_wireframe = Material( "models/wireframe" )
function TOOL:EditorRender( selected )
    self:BuildMesh()

    if self.render_mesh then
        render.SetMaterial( MapPatcher.GetToolMaterial(self.ClassName) )
        self.render_mesh:Draw()

        if selected then
            render.SetMaterial( material_wireframe )
            self.render_mesh:Draw()
        end
    end
end

function TOOL:BuildMesh( force )
    if not force and self.render_mesh then return end

    if self.render_mesh then
        self.render_mesh:Destroy()
        self.render_mesh = nil
    end

    local points = self.points
    if #points >= 3 then
        local succ, new_points, new_mesh = quickhull.BuildMeshFromPoints( points )
        if succ then
            self.render_mesh = new_mesh
        end
    end
end

function TOOL:ToolSwitchFrom( old_object )
    if old_object:IsDerivedFrom( "base_brush" ) then
        self.ID = old_object.ID
        self.points = old_object.points
        self.cached_origin = nil
    end
end

function TOOL:ShouldSave( )
    return self:IsObject() and #self.points >= 4
end
--------------------------------------------------------------------------------
function TOOL:Initialize( )
    if not self:IsObject() then return end

    self:UpdateEntity( )
end

function TOOL:UpdateEntity( )
    local entity = self.entity
    
    if SERVER then
        if IsValid(entity) then entity:Remove() end
        entity = ents.Create( "mappatcher_brush" )
        entity:Spawn()
        entity:SetObjectID(self.ID)
        entity:SetObjectClass(self.ClassName)
    elseif CLIENT then
        entity = Entity( self.entity_id )
        if not IsValid(entity) then return end
        if not entity.MapPatcherObject then return end
        if entity:GetCreationID2() ~= self.entity_cid then return end
    end

    self.entity = entity
    entity.object = self


    local points = self.points

    local origin = self:GetOrigin()
    local points_local = {}
    for i=1, #points do
        points_local[i] = points[i] - origin
    end

    entity:SetPos( origin )

    entity:PhysicsInitConvex( points_local )
    local physobj = entity:GetPhysicsObject()
    if IsValid(physobj) then
        physobj:EnableMotion( false )
    else
        ErrorNoHalt("[MapPatcher] Invalid physics object was created for object("..(self.ID)..")\n")
        ErrorNoHalt("[MapPatcher] Marking object("..(self.ID)..") as invalid.\n")
        self.points = {}
    end

    entity:SetMoveType( MOVETYPE_NONE )
    entity:SetSolid( SOLID_VPHYSICS )

    self:EntSetup( entity )

    entity:CollisionRulesChanged()
    
    if CLIENT then entity:DestroyShadow() end
end

function TOOL:Terminate( )
    if not SERVER then return end

    if IsValid(self.entity) then
        self.entity:Remove()
    end
end
--------------------------------------------------------------------------------
function TOOL:GetOrigin()
    if self.cached_origin then return self.cached_origin end

    local n_points = #self.points
    local origin = Vector()
    for k, point in pairs(self.points) do
        origin = origin + point
    end

    self.cached_origin = origin*(1/n_points)
    return self.cached_origin
end

function TOOL:EntImpactTrace( ent, trace, dmgtype, customimpactname )
    return true
end

--------------------------------------------------------------------------------
function TOOL:PostCleanupMap( )
    if SERVER then
        self:UpdateEntity( )
    end
end