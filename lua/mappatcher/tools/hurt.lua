local TOOL = TOOL

TOOL.Base = "base_brush"
TOOL.Description = "Damages entities overtime when they're inside the brush. There are 3 types of damage types. Generic damage type does basic damage. Poison damage type does damage similar to poison headcrab, the health will regenerate over time. Dissolve damage type works similarly to generic, except it will dissolve player bodies when they die."
--------------------------------------------------------------------------------
TOOL.TextureColor = Color(255,69,0,200)
TOOL.TextureText = "Hurt"
--------------------------------------------------------------------------------

function TOOL:ObjectCreated()
    TOOL:GetBase().ObjectCreated(self)

    self.time_before_hurt = 0
    self.hurt_interval = 0
    self.hurt_amount = 0
    self.damage_type = DMG_GENERIC
end

function TOOL:SetupObjectPanel( panel )
    local numTimeBeforeHurt = vgui.Create( "DNumSlider", panel )
    numTimeBeforeHurt:SetPos( 10, 10 )
    numTimeBeforeHurt:SetSize( 300, 20 )
    numTimeBeforeHurt:SetText( "Time before hurt (sec)" )
    numTimeBeforeHurt:SetMinMax( 0, 600 )
    numTimeBeforeHurt:SetDecimals( 0 )
    numTimeBeforeHurt:SetValue( self.time_before_hurt )
    numTimeBeforeHurt:SetSkin( "MapPatcher" )
    function numTimeBeforeHurt.OnValueChanged( pnl, val )
        self.time_before_hurt = math.Clamp( val, 0, 0xFFFF )
        numTimeBeforeHurt:SetValue( self.time_before_hurt )
    end

    local numHurtInterval = vgui.Create( "DNumSlider", panel )
    numHurtInterval:SetPos( 10, 35 )
    numHurtInterval:SetSize( 300, 20 )
    numHurtInterval:SetText( "Hurt interval (sec)" )
    numHurtInterval:SetMinMax( 0, 60 )
    numHurtInterval:SetDecimals( 0 )
    numHurtInterval:SetValue( self.hurt_interval )
    numHurtInterval:SetSkin( "MapPatcher" )
    function numHurtInterval.OnValueChanged( pnl, val )
        self.hurt_interval = math.Clamp( val, 0, 0xFFFF )
        numHurtInterval:SetValue( self.hurt_interval )
    end

    local numHurtAmount = vgui.Create( "DNumSlider", panel )
    numHurtAmount:SetPos( 10, 60 )
    numHurtAmount:SetSize( 300, 20 )
    numHurtAmount:SetText( "Hurt amount" )
    numHurtAmount:SetMinMax( 0, 100 )
    numHurtAmount:SetDecimals( 0 )
    numHurtAmount:SetValue( self.hurt_amount )
    numHurtAmount:SetSkin( "MapPatcher" )
    function numHurtAmount.OnValueChanged( pnl, val )
        self.hurt_amount = math.Clamp( val, -0x80000000, 0x7FFFFFFF )
        numHurtAmount:SetValue( self.hurt_amount )
    end


    local lblDamageType = vgui.Create( "DLabel", panel )
    lblDamageType:SetTextColor( Color( 255, 255, 255, 255 ) )
    lblDamageType:SetPos( 10, 85 )
    lblDamageType:SetText( "Damage type" )

    local cmbDamageType = vgui.Create( "DComboBox", panel )
    cmbDamageType:SetPos( 137, 85 )
    cmbDamageType:SetSize( 123, 20 )
    cmbDamageType:AddChoice( "Generic", DMG_GENERIC, self.damage_type == DMG_GENERIC )
    cmbDamageType:AddChoice( "Poison", DMG_POISON, self.damage_type == DMG_POISON )
    cmbDamageType:AddChoice( "Dissolve", DMG_DISSOLVE, self.damage_type == DMG_DISSOLVE )
    cmbDamageType.OnSelect = function( panel, index, value, data )
        self.damage_type = data
    end

end

--------------------------------------------------------------------------------
function TOOL:WriteToBuffer( buffer )
    TOOL:GetBase().WriteToBuffer( self, buffer )

    buffer:WriteUInt16( self.time_before_hurt )
    buffer:WriteUInt16( self.hurt_interval )
    buffer:WriteInt32( self.hurt_amount )
    buffer:WriteUInt32( self.damage_type )
end

function TOOL:ReadFromBuffer( buffer, len )
    TOOL:GetBase().ReadFromBuffer(self, buffer)
    
    self.time_before_hurt = buffer:ReadUInt16( )
    self.hurt_interval = buffer:ReadUInt16( )
    self.hurt_amount = buffer:ReadInt32( )
    self.damage_type = buffer:ReadUInt32( )
end
--------------------------------------------------------------------------------
function TOOL:EntSetup( ent )
    self.objects = {}
    ent:SetSolidFlags( FSOLID_CUSTOMBOXTEST )
    if SERVER then 
        ent:SetTrigger( true ) 
        self.ents_next_hurt = {}
    end
end

function TOOL:EntStartTouch( ent )
    if ent.MapPatcherObject then return end

    if ent:IsPlayer() then
        self.ents_next_hurt[ent] = CurTime()+self.time_before_hurt
    end
end

function TOOL:EntTouch( ent )
    if ent.MapPatcherObject then return end
    
    if self.ents_next_hurt[ent] and self.ents_next_hurt[ent] < CurTime() then
        self.ents_next_hurt[ent] = CurTime() + self.hurt_interval

        local d = DamageInfo()
        d:SetAttacker( ent )
        d:SetDamage( self.hurt_amount )
        d:SetDamageType( self.damage_type )

        ent:TakeDamageInfo( d )
    end
end

function TOOL:EntEndTouch( ent )
    self.ents_next_hurt[ent] = nil
end

function TOOL:EntShouldCollide( ent )
    return false
end
--------------------------------------------------------------------------------
