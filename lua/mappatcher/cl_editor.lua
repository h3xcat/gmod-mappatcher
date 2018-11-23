--[[ Copyright (C) Edgaras Fiodorovas - All Rights Reserved
   - Unauthorized copying of this file, via any medium is strictly prohibited
   - Proprietary and confidential
   - Written by Edgaras Fiodorovas <edgarasf123@gmail.com>, November 2017
   -]]
   
--------------------------------------------------------------------------------

local luabsp = MapPatcher.Libs.luabsp
local quickhull = MapPatcher.Libs.quickhull
local BufferInterface = MapPatcher.Libs.BufferInterface

MapPatcher.Editor = MapPatcher.Editor or {}
local Editor = MapPatcher.Editor

Editor.Tools = {
    "playerclip",
    "propclip",
    "bulletclip",
    "clip",
    "forcefield",
    "hurt",
    "kill",
    "remove",
    "teleport",
    "tp_target",
}

function Editor.Start( )
    if xgui then xgui.hide() end -- Hide ULX XGUI
    if gui.IsGameUIVisible() then gui.HideGameUI() end
    Editor.Enabled = true
    Editor.StartUI()
    Editor.LoadMapClipBrushes()
    if not Editor.Object then
        Editor.SetTool(Editor.Tools[1])
    end
    Editor.UpdateMenu( )
end

function Editor.Stop( )
    Editor.Enabled = false 
    Editor.StopUI()
end

function Editor.LeftClick( pos, ang )
    Editor.Object:LeftClick( pos, ang )
end

function Editor.RightClick( tr )
    if IsValid( tr.Entity ) and tr.Entity.MapPatcherObject then
        Editor.SelectObject( tr.Entity.object )
    else
        for k, object in pairs(MapPatcher.Objects) do
            if not object:IsDerivedFrom( "base_point" ) then continue end
            if object:GetOrigin():DistToSqr( tr.HitPos ) < 1000 then
                Editor.SelectObject( object )
                return
            end
        end
        Editor.ResetTool( )
    end
end

function Editor.SubmitObject( )
    local object = Editor.Object

    net.Start( "mappatcher_submit" )
    net.WriteUInt( object.ID, 16 )
    net.WriteString( object.ClassName )
    Editor.Object:WriteToBuffer( BufferInterface("net") )
    net.SendToServer()
    
    Editor.ResetTool( )
end

function Editor.RemoveObject( )
    local object = Editor.Object
    local object_id = object.ID

    if object_id > 0 then
        net.Start( "mappatcher_submit" )
        net.WriteUInt( object_id, 16 )
        net.WriteString( "null" )
        net.SendToServer()
    end

    Editor.ResetTool( )
end

function Editor.ResetTool( )
    Editor.Object = nil
    Editor.SetTool()
end

function Editor.SetTool( tool, no_object )
    tool = tool or Editor.Tool
    Editor.Tool = tool

    if not no_object then
        local new_object = MapPatcher.NewToolObject( tool )

        local object = Editor.Object
        if IsValid(object) then
            new_object:ToolSwitchFrom( object )
        end

        Editor.Object = new_object
    end

    Editor.UpdateMenu( )
end

function Editor.SelectObject( object, look )
    Editor.Object = object:GetCopy()
    Editor.SetTool( object.ClassName, true)

    if look then
        Editor.Screen:LookAt( object:GetOrigin() )
    end
end

function Editor.UpdateMenu( )
    Editor.Screen:UpdateMenu( )
end

function Editor.LoadMapClipBrushes( force )
    if not force and Editor.MapClipBrushes then return end
    Editor.MapClipBrushes = nil

    local bsp = luabsp.LoadMap( game.GetMap() )
    if bsp then
        if MapPatcher.Config.MapClipBrushesAsSingleObject then
            Editor.MapClipBrushes = { bsp:GetClipBrushes( true ) }
        else
            Editor.MapClipBrushes = bsp:GetClipBrushes( false )
        end
    end
end

function MapPatcher.DeleteMesh( )
    if MapPatcher.EditMesh.id > 0 then
        MapPatcher.EditMesh.points = {}
        MapPatcher.SubmitMesh()
    end

    MapPatcher.CreateEditMesh( )
end

function MapPatcher.ReloadEntities( )
    net.Start("mappatcher_reload_entities")
    net.SendToServer()
end

do
    local mappatcher_tool_font = "mappatcher_tool_font_"..os.time()
    surface.CreateFont( mappatcher_tool_font, {
        font = "Consolas",
        size = 40,
        weight = 800,
    } )

    local tool_mats_queue = {}
    hook.Add("DrawMonitors", "MapPatcher_MaterialGenerator", function()
        for k, data in pairs(tool_mats_queue) do
            local mat = data.mat
            local mat_name = data.mat_name
            local color = data.color
            local text = data.text
            local rt_tex = GetRenderTarget( mat_name, 256, 256, true )
            mat:SetTexture( "$basetexture", rt_tex )

            render.PushRenderTarget( rt_tex )

            render.SetViewPort(0, 0, 256, 256)
            render.OverrideAlphaWriteEnable( true, true )
            cam.Start2D()
                render.Clear( color.r, color.g, color.b, color.a )
                surface.SetFont( mappatcher_tool_font )
                surface.SetTextColor( 255, 255, 255, 255 )
                local txt_w, txt_h = surface.GetTextSize( text )
                surface.SetTextPos( 128-txt_w/2, 128-txt_h/2 )
                surface.DrawText( text )
                
                surface.SetDrawColor( 255,255,255 )
                surface.DrawOutlinedRect( 10, 10, 256-10, 256-10 )
            cam.End2D()

            render.OverrideAlphaWriteEnable( false )
            render.PopRenderTarget()
        end
        tool_mats_queue = {}
    end)

    function Editor.GenerateToolMaterial( mat_name, color, text )
        local mat = CreateMaterial( mat_name, "UnlitGeneric", {["$vertexalpha"] = 1} )
        tool_mats_queue[#tool_mats_queue + 1] = { mat_name=mat_name, color=color, text=text, mat=mat }
        return mat
    end
end
local dev_test = os.time()

local material_error = Editor.GenerateToolMaterial( "mappatcher_error", Color(255,0,0,255), "ERROR" )
function MapPatcher.GetToolMaterial( tool_type, noalpha )
    local tool_class = MapPatcher.Tools[tool_type]
    if not tool_class then print(tool_type) return material_error end
    if noalpha then
        if tool_class.EditorMaterial then return tool_class.EditorMaterial end
        local texture_color = table.Copy( tool_class.TextureColor )
        texture_color.a = 255
        tool_class.EditorMaterial = Editor.GenerateToolMaterial( "mappatcher_"..tool_type, texture_color, tool_class.TextureText )
        return tool_class.EditorMaterial
    else
        if tool_class.EditorMaterialAlpha then return tool_class.EditorMaterialAlpha end
        
        tool_class.EditorMaterialAlpha = Editor.GenerateToolMaterial( "mappatcher_"..tool_type.."_alpha", tool_class.TextureColor, tool_class.TextureText )
        return tool_class.EditorMaterialAlpha
    end
    return material_error
end

local function insert_pq( tbl, priority, element )
    local insert_pos = 1
    for k, v in ipairs(tbl) do
        if v[1] < priority then
            insert_pos = k
            table.insert(tbl, k, {priority, element})
            return
        end
    end
    tbl[#tbl + 1] = {priority, element}
end

local point_pos = Vector()
local material_hammer_playerclip = Editor.GenerateToolMaterial( "mappatcher_hammer_playerclip", Color(255,0,255,200), "Player Clip" )
hook.Add( "PostDrawOpaqueRenderables", "MapPatcherEditor", function( bDrawingDepth, bDrawingSkybox )
    if not MapPatcher.CVarDraw:GetBool() and not Editor.Enabled then return end
    render.OverrideDepthEnable( true, true )
    

    if Editor.Enabled then
        -- Draw point
        render.SetColorMaterial()
        render.DrawSphere( Editor.Screen:GetPointPos(), 4, 8, 8, Color(255,255,0,200) )
    end

    local render_pq = {}

    local view_pos = EyePos()
    local editor_object_id = 0
    if Editor.Object and IsValid(Editor.Object) then
        insert_pq( render_pq, Editor.Object:GetOrigin():DistToSqr( view_pos ), Editor.Object )
        editor_object_id = Editor.Object.ID
    end
    for object_id, object in pairs(MapPatcher.Objects) do
        if object_id == editor_object_id then
            continue
        end
        insert_pq( render_pq, object:GetOrigin():DistToSqr( view_pos ), object )
    end

    for k, v in pairs(render_pq) do
        local object = v[2]
        object:EditorRender( object.ID == editor_object_id )
    end

    if Editor.MapClipBrushes then
        render.SetMaterial( material_hammer_playerclip )
        for _, mesh in pairs(Editor.MapClipBrushes) do
            mesh:Draw() -- Draw the mesh
        end
    end

    render.OverrideDepthEnable( false )
end )


net.Receive( "mappatcher_editmode_start", function( len )
    Editor.Start( )
end )

function Editor.StartUI()
    if not Editor.Screen then
        Editor.Screen = vgui.Create( "MapPatcherEditorScreen" )
    end
    Editor.Screen:Open()
end

function Editor.StopUI()
    if not Editor.Screen then return end
    
    Editor.Screen:Remove()
    Editor.Screen = nil
end

local hud_allow = {
    CHudChat = true,
    CHudGMod = true,
    CHudMenu = true,
    NetGraph = true,
}

hook.Add( "HUDShouldDraw", "MapPatcherEditModeUI", function( name )
    if not Editor.Screen then return end
    if not Editor.Screen:IsVisible() then return end
    if hud_allow[ name ] then return end
    return false
end )

hook.Add( "CalcView", "MapPatcherEditor", function( ply, pos, angles, fov )
    if not Editor.Screen or not Editor.Screen:IsVisible() then return end

    local view = {}

    view.origin = Editor.Screen:GetViewPos()
    view.angles = Editor.Screen:GetViewAngles()
    view.fov = fov
    view.drawviewer = true

    return view
end )


