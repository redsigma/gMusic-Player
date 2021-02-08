if (SERVER) then
    AddCSLuaFile("vgui/seekbarclicklayer.lua")
    AddCSLuaFile("vgui/seekbar.lua")
    AddCSLuaFile("vgui/numslidernolabel.lua")
    AddCSLuaFile("vgui/doublelist.lua")
    AddCSLuaFile("vgui/doptions.lua")
    AddCSLuaFile("vgui/playerframe.lua")
    AddCSLuaFile("vgui/dsidemenu.lua")
    AddCSLuaFile("vgui/dbettercheckbox.lua")
    AddCSLuaFile("vgui/dbettercblabel.lua")
    AddCSLuaFile("vgui/dsimplescroll.lua")
    AddCSLuaFile("vgui/dbetterline.lua")
    AddCSLuaFile("vgui/dbettercolumn.lua")
    AddCSLuaFile("vgui/dbetterlist.lua")
    AddCSLuaFile("vgui/dmultibutton.lua")
    AddCSLuaFile("vgui/dbetterbutton.lua")

    AddCSLuaFile("includes/modules/musicplayerclass.lua")
    AddCSLuaFile("includes/modules/meth_base.lua")
    AddCSLuaFile("includes/modules/meth_paint.lua")
    AddCSLuaFile("includes/modules/meth_song.lua")
    AddCSLuaFile("includes/modules/coms.lua")

    AddCSLuaFile("includes/func/interface.lua")
    AddCSLuaFile("includes/func/audio.lua")
    AddCSLuaFile("includes/func/settings.lua")

    AddCSLuaFile("gmpl/cl_gmpl.lua")
    AddCSLuaFile("gmpl/cl_cvars.lua")

    include("gmpl/sv_gmpl.lua")
    include("gmpl/sv_cvars.lua")
else
    include("gmpl/cl_gmpl.lua")
end
