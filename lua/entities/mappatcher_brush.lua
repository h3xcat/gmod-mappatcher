--[[ Copyright (C) Edgaras Fiodorovas - All Rights Reserved
   - Unauthorized copying of this file, via any medium is strictly prohibited
   - Proprietary and confidential
   - Written by Edgaras Fiodorovas <edgarasf123@gmail.com>, November 2017
   -]]
   
--------------------------------------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

ENT.Type = "anim"
ENT.DisableDuplicator = true
ENT.MapPatcherObject = true
ENT.RenderGroup = RENDERGROUP_BOTH
function ENT:Initialize()
    self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
    self:SetAngles( Angle() )
    self:SetRenderMode( RENDERMODE_TRANSALPHA )
    self:SetModel( "models/props_phx/misc/gibs/egg_piece4.mdl" )
    self:SetMoveType( MOVETYPE_NONE )
    self:SetSolid( SOLID_VPHYSICS )

    self:SetCustomCollisionCheck( true )

    if CLIENT then
        timer.Simple(0.5, function()
            if not IsValid(self) then return end
            local object_id = self:GetObjectID()
            local creation_id = self:GetCreationID2()

            local object = MapPatcher.Objects[object_id]
            if object and object.entity_cid == creation_id then
                object:UpdateEntity()
            end
        end)
    end
    --self:UpdateBrush( )
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:ObjectUpdate( )

end

function ENT:DrawTranslucent( )
    if not self.object then return end
    self.object:EntDraw(self)
end
function ENT:Draw( )
end

function ENT:StartTouch( ent )
    self.object:EntStartTouch( ent )
end
function ENT:Touch( ent )
    self.object:EntTouch( ent )
end
function ENT:EndTouch( ent )
    self.object:EntEndTouch( ent )
end

function ENT:SetupDataTables()
    self:NetworkVar( "Int", 0, "CreationID2" )
    self:NetworkVar( "Int", 1, "ObjectID" )
    self:NetworkVar( "String", 0, "ObjectClass" )
    if SERVER then
        self:SetCreationID2( self:GetCreationID() )
        self:SetObjectID( 0 )
        self:SetObjectClass( "" )
    end
end

function ENT:OnRemove()
    if not self.object then return end
    self.object:EntRemove(self)
end

function ENT:Think()    
end

function ENT:ImpactTrace( trace, dmgtype, customimpactname )
    if not self.object then return end
    return self.object:EntImpactTrace(self, trace, dmgtype, customimpactname )
end