-----------------------------------------------------------------------
--              GtkAda - Ada95 binding for Gtk+/Gnome                --
--                                                                   --
--                     Copyright (C) 2001                            --
--                         ACT-Europe                                --
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

with Gtk.Enums; use Gtk.Enums;
with Gtk.Tree_Model;
with Gtk.Widget; use Gtk.Widget;
with Gtk; use Gtk;
with System;

package body Gtk.Tree_Selection is

   package body Selection_Foreach is

      ----------------------
      -- Selected_Foreach --
      ----------------------

      procedure Selected_Foreach
        (Selection : access Gtk_Tree_Selection_Record'Class;
         Func      : Foreach_Func;
         Data      : Data_Type)
      is
         procedure Internal
           (Selection : System.Address;
            Func      : Foreach_Func;
            Data      : System.Address);
         pragma Import (C, Internal, "gtk_tree_selection_selected_foreach");
      begin
         Internal (Get_Object (Selection),
		   Func,
                   Data'Address);
      end Selected_Foreach;

   end Selection_Foreach;

   --------------
   -- Set_Mode --
   --------------

   procedure Set_Mode
     (Selection : access Gtk_Tree_Selection_Record'Class;
      The_Type  : Gtk_Selection_Mode)
   is
      procedure Internal
        (Selection : System.Address;
         The_Type  : Gint);
      pragma Import (C, Internal, "gtk_tree_selection_set_mode");
   begin
      Internal (Get_Object (Selection),
                Gtk_Selection_Mode'Pos (The_Type));
   end Set_Mode;

   --------------
   -- Get_Mode --
   --------------

   function Get_Mode (Selection : access Gtk_Tree_Selection_Record'Class)
                      return Gtk_Selection_Mode
   is
      function Internal (Selection : System.Address)
                         return Gint;
      pragma Import (C, Internal, "gtk_tree_selection_get_mode");
   begin
      return Gtk_Selection_Mode'Val (Internal (Get_Object (Selection)));
   end Get_Mode;

--    -------------------------
--    -- Set_Select_Function --
--    -------------------------

--    procedure Set_Select_Function
--      (Selection : access Gtk_Tree_Selection_Record'Class;
--       Func      : Gtk_Tree_Selection_Func;
--       Data      : gpointer;
--       Destroy   : Gtk_Destroy_Notify)
--    is
--       procedure Internal
--         (Selection : System.Address;
--          Func      : Gint;
--          Data      : Integer;
--          Destroy   : Gint);
--       pragma Import (C, Internal, "gtk_tree_selection_set_select_function");
--    begin
--       Internal (Get_Object (Selection),
--                 Gtk_Tree_Selection_Func'Pos (Func),
--                 Data,
--                 Gtk_Destroy_Notify'Pos (Destroy));
--    end Set_Select_Function;

--    -------------------
--    -- Get_User_Data --
--    -------------------

--    function Get_User_Data (Selection : access Gtk_Tree_Selection_Record'Class)
--                            return gpointer
--    is
--       function Internal (Selection : System.Address)
--                          return Integer;
--       pragma Import (C, Internal, "gtk_tree_selection_get_user_data");
--    begin
--       return Internal (Get_Object (Selection));
--    end Get_User_Data;

   -------------------
   -- Get_Tree_View --
   -------------------

   function Get_Tree_View (Selection : access Gtk_Tree_Selection_Record'Class)
                           return Gtk.Widget.Gtk_Widget
   is
      function Internal (Selection : System.Address)
                         return System.Address;
      pragma Import (C, Internal, "gtk_tree_selection_get_tree_view");
   begin
      return (Widget.Convert (Internal (Get_Object (Selection))));
   end Get_Tree_View;

   ------------------
   -- Get_Selected --
   ------------------

   function Get_Selected
     (Selection : access Gtk_Tree_Selection_Record'Class;
      Model     : access Gtk.Tree_Model.Gtk_Tree_Model_Record'Class;
      Iter      : Gtk.Tree_Model.Gtk_Tree_Iter)
      return Boolean
   is
      function Internal
        (Selection : System.Address;
         Model     : System.Address;
         Iter      : System.Address)
         return Gint;
      pragma Import (C, Internal, "gtk_tree_selection_get_selected");
   begin
      return Boolean'Val (Internal (Get_Object (Selection),
                                    Get_Object (Model),
                                    Iter'Address));
   end Get_Selected;

   -----------------
   -- Select_Path --
   -----------------

   procedure Select_Path
     (Selection : access Gtk_Tree_Selection_Record'Class;
      Path      : Gtk.Tree_Model.Gtk_Tree_Path)
   is
      procedure Internal
        (Selection : System.Address;
         Path      : System.Address);
      pragma Import (C, Internal, "gtk_tree_selection_select_path");
   begin
      Internal (Get_Object (Selection),
                Path.all'Address);
   end Select_Path;

   -------------------
   -- Unselect_Path --
   -------------------

   procedure Unselect_Path
     (Selection : access Gtk_Tree_Selection_Record'Class;
      Path      : Gtk.Tree_Model.Gtk_Tree_Path)
   is
      procedure Internal
        (Selection : System.Address;
         Path      : System.Address);
      pragma Import (C, Internal, "gtk_tree_selection_unselect_path");
   begin
      Internal (Get_Object (Selection),
                Path.all'Address);
   end Unselect_Path;

   -----------------
   -- Select_Iter --
   -----------------

   procedure Select_Iter
     (Selection : access Gtk_Tree_Selection_Record'Class;
      Iter      : Gtk.Tree_Model.Gtk_Tree_Iter)
   is
      procedure Internal
        (Selection : System.Address;
         Iter      : System.Address);
      pragma Import (C, Internal, "gtk_tree_selection_select_iter");
   begin
      Internal (Get_Object (Selection),
                Iter'Address);
   end Select_Iter;

   -------------------
   -- Unselect_Iter --
   -------------------

   procedure Unselect_Iter
     (Selection : access Gtk_Tree_Selection_Record'Class;
      Iter      : Gtk.Tree_Model.Gtk_Tree_Iter)
   is
      procedure Internal
        (Selection : System.Address;
         Iter      : System.Address);
      pragma Import (C, Internal, "gtk_tree_selection_unselect_iter");
   begin
      Internal (Get_Object (Selection),
                Iter'Address);
   end Unselect_Iter;

   ----------------------
   -- Path_Is_Selected --
   ----------------------

   function Path_Is_Selected
     (Selection : access Gtk_Tree_Selection_Record'Class;
      Path      : Gtk.Tree_Model.Gtk_Tree_Path)
      return Boolean
   is
      function Internal
        (Selection : System.Address;
         Path      : System.Address)
         return Gint;
      pragma Import (C, Internal, "gtk_tree_selection_path_is_selected");
   begin
      return Boolean'Val (Internal (Get_Object (Selection),
                                    Path.all'Address));
   end Path_Is_Selected;

   ----------------------
   -- Iter_Is_Selected --
   ----------------------

   function Iter_Is_Selected
     (Selection : access Gtk_Tree_Selection_Record'Class;
      Iter      : Gtk.Tree_Model.Gtk_Tree_Iter)
      return Boolean
   is
      function Internal
        (Selection : System.Address;
         Iter      : System.Address)
         return Gint;
      pragma Import (C, Internal, "gtk_tree_selection_iter_is_selected");
   begin
      return Boolean'Val (Internal (Get_Object (Selection),
                                    Iter'Address));
   end Iter_Is_Selected;

   ----------------
   -- Select_All --
   ----------------

   procedure Select_All (Selection : access Gtk_Tree_Selection_Record'Class)
   is
      procedure Internal (Selection : System.Address);
      pragma Import (C, Internal, "gtk_tree_selection_select_all");
   begin
      Internal (Get_Object (Selection));
   end Select_All;

   ------------------
   -- Unselect_All --
   ------------------

   procedure Unselect_All (Selection : access Gtk_Tree_Selection_Record'Class)
   is
      procedure Internal (Selection : System.Address);
      pragma Import (C, Internal, "gtk_tree_selection_unselect_all");
   begin
      Internal (Get_Object (Selection));
   end Unselect_All;

   ------------------
   -- Select_Range --
   ------------------

   procedure Select_Range
     (Selection  : access Gtk_Tree_Selection_Record'Class;
      Start_Path : Gtk.Tree_Model.Gtk_Tree_Path;
      End_Path   : Gtk.Tree_Model.Gtk_Tree_Path)
   is
      procedure Internal
        (Selection  : System.Address;
         Start_Path : System.Address;
         End_Path   : System.Address);
      pragma Import (C, Internal, "gtk_tree_selection_select_range");
   begin
      Internal (Get_Object (Selection),
                Start_Path.all'Address,
                End_Path.all'Address);
   end Select_Range;

end Gtk.Tree_Selection;
