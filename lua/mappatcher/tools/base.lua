TOOL.Version = 0

local Stream = MapPatcher.Libs.Stream

function TOOL:IsObject()
    return self.object
end

function TOOL:GetBase()
    local base = self.Base
    if base then
        return MapPatcher.Tools[base]
    end
end

function TOOL:GetClass()
    return getmetatable( self )
end

function TOOL:GetClassName()
    return self.ClassName
end

function TOOL:GetCopy()
    local object = MapPatcher.NewToolObject( self.ClassName )
    local tmp = Stream()
    self:WriteToBuffer( tmp )
    tmp:Seek(0)
    object:ReadFromBuffer( tmp )
    object.ID = self.ID
    object.entity = self.entity
    object.entity_id = self.entity_id
    return object
end

function TOOL:IsValid()
    return self:IsObject()
end

function TOOL:ShouldSave()
    return self:IsObject()
end

function TOOL:IsDerivedFrom( class_name )
    if self.ClassName == class_name then
        return true
    elseif not self:GetBase() then
        return false
    else
        return self:GetBase():IsDerivedFrom( class_name )
    end
end

function TOOL:ToString( )
    if getmetatable(self) == self then
        return "[class] " .. self.ClassName
    end
    return "["..self.ID.."] "..self.ClassName
end
--------------------------------------------------------------------------------
function TOOL:WriteToBuffer( buffer )
end

function TOOL:ReadFromBuffer( buffer, len )
end

function TOOL:SessionWriteToBuffer( buffer )
end

function TOOL:SessionReadFromBuffer( buffer, len )
end
--------------------------------------------------------------------------------
function TOOL:GetOrigin( )
    return Vector(0, 0, 0)
end
--------------------------------------------------------------------------------
function TOOL:PreviewPaint( panel, w, h )

end
--------------------------------------------------------------------------------
function TOOL:Initialize( )
end

function TOOL:Terminate( )
end

function TOOL:UpdateEntity( )
end

function TOOL:ObjectCreated( )
end

function TOOL:PostCleanupMap( )
end

function TOOL:ReloadEntity( )
end

function TOOL:LeftClick( pos )
end

function TOOL:EditorRender( selected )
end

function TOOL:ToolSwitchFrom( old_object )
end

function TOOL:SetupObjectPanel( panel )
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function TOOL:EntSetup( ent )
end
--------------------------------------------------------------------------------
function TOOL:EntStartTouch( ent )
end

function TOOL:EntTouch( ent )
end

function TOOL:EntEndTouch( ent )
end
--------------------------------------------------------------------------------
function TOOL:EntShouldCollide( ent )
end

function TOOL:EntDraw( ent )
end

function TOOL:EntImpactTrace( ent, trace, dmgtype, customimpactname )
end

function TOOL:EntRemove( ent )
end
