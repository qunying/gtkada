-----------------------------------------------------------------------
--               GtkAda - Ada95 binding for Gtk+/Gnome               --
--                                                                   --
--                   Copyright (C) 2002 ACT-Europe                   --
--                                                                   --
-- This library is free software; you can redistribute it and/or     --
-- modify it under the terms of the GNU General Public               --
-- License as published by the Free Software Foundation; either      --
-- version 2 of the License, or (at your option) any later version.  --
--                                                                   --
-- This library is distributed in the hope that it will be useful,   --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of    --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details.                          --
--                                                                   --
-- You should have received a copy of the GNU General Public         --
-- License along with this library; if not, write to the             --
-- Free Software Foundation, Inc., 59 Temple Place - Suite 330,      --
-- Boston, MA 02111-1307, USA.                                       --
--                                                                   --
-- As a special exception, if other files instantiate generics from  --
-- this unit, or you link this unit with other files to produce an   --
-- executable, this  unit  does not  by itself cause  the resulting  --
-- executable to be covered by the GNU General Public License. This  --
-- exception does not however invalidate any other reasons why the   --
-- executable file  might be covered by the  GNU Public License.     --
-----------------------------------------------------------------------

with Gdk.Types;       use Gdk.Types;
with Gtk.Accel_Group; use Gtk.Accel_Group;

package body Gtk.Accel_Map is

   ----------
   -- Save --
   ----------

   procedure Save (File_Name : String) is
      procedure Internal (File_Name : String);
      pragma Import (C, Internal, "gtk_accel_map_save");
   begin
      Internal (File_Name & ASCII.NUL);
   end Save;

   ----------
   -- Load --
   ----------

   procedure Load (File_Name : String) is
      procedure Internal (File_Name : String);
      pragma Import (C, Internal, "gtk_accel_map_load");
   begin
      Internal (File_Name & ASCII.NUL);
   end Load;

   ---------------
   -- Add_Entry --
   ---------------

   procedure Add_Entry
     (Accel_Path : String;
      Accel_Key  : Gdk.Types.Gdk_Key_Type;
      Accel_Mods : Gdk.Types.Gdk_Modifier_Type)
   is
      procedure Internal (P : String; K : Gdk_Key_Type; M : Gdk_Modifier_Type);
      pragma Import (C, Internal, "gtk_accel_map_add_entry");
   begin
      Internal (Accel_Path & ASCII.NUL, Accel_Key, Accel_Mods);
   end Add_Entry;

   ------------------
   -- Lookup_Entry --
   ------------------

   procedure Lookup_Entry
     (Accel_Path : String;
      Key        : out Gtk.Accel_Group.Gtk_Accel_Key;
      Found      : out Boolean)
   is
      type Gtk_Accel_Key_Access is access all Gtk_Accel_Key;
      function Internal
        (Path : String; Key : Gtk_Accel_Key_Access) return Integer;
      pragma Import (C, Internal, "gtk_accel_map_lookup_entry");

      K : aliased Gtk_Accel_Key;

   begin
      Found := Boolean'Val (Internal (Accel_Path & ASCII.NUL, K'Access));
      Key := K;
   end Lookup_Entry;

   ------------------
   -- Change_Entry --
   ------------------

   procedure Change_Entry
     (Accel_Path : String;
      Accel_Key  : Gdk.Types.Gdk_Key_Type;
      Accel_Mods : Gdk.Types.Gdk_Modifier_Type;
      Replace    : Boolean)
   is
      procedure Internal
        (P : String; K : Gdk_Key_Type; M : Gdk_Modifier_Type; R : Integer);
      pragma Import (C, Internal, "gtk_accel_map_change_entry");
   begin
      Internal (Accel_Path & ASCII.NUL, Accel_Key, Accel_Mods,
                Boolean'Pos (Replace));
   end Change_Entry;

end Gtk.Accel_Map;
