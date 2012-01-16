------------------------------------------------------------------------------
--                  GtkAda - Ada95 binding for Gtk+/Gnome                   --
--                                                                          --
--      Copyright (C) 1998-2000 E. Briot, J. Brobecker and A. Charlet       --
--                     Copyright (C) 1998-2012, AdaCore                     --
--                                                                          --
-- This library is free software;  you can redistribute it and/or modify it --
-- under terms of the  GNU General Public License  as published by the Free --
-- Software  Foundation;  either version 3,  or (at your  option) any later --
-- version. This library is distributed in the hope that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE.                            --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
------------------------------------------------------------------------------

--  <c_version>2.8.17</c_version>
--  <group>Obsolescent widgets</group>

with Gtk.Item;

package Gtk.List_Item is
   pragma Obsolescent;

   type Gtk_List_Item_Record is new Gtk.Item.Gtk_Item_Record with private;
   type Gtk_List_Item is access all Gtk_List_Item_Record'Class;

   procedure Gtk_New
     (List_Item : out Gtk_List_Item;
      Label     : UTF8_String := "");
   procedure Initialize
     (List_Item : access Gtk_List_Item_Record'Class;
      Label     : UTF8_String := "");
   --  Creates or initializes a new list item

   function Get_Type return Gtk.Gtk_Type;
   --  Return the internal value associated with a Gtk_List_Item.

   procedure Gtk_Select (List_Item : access Gtk_List_Item_Record);

   procedure Deselect (List_Item : access Gtk_List_Item_Record);

   -------------
   -- Signals --
   -------------

   --  <signals>
   --  The following new signals are defined for this widget:
   --
   --  </signals>

   Signal_End_Selection     : constant Glib.Signal_Name := "end_selection";
   Signal_Extend_Selection  : constant Glib.Signal_Name := "extend_selection";
   Signal_Scroll_Horizontal : constant Glib.Signal_Name := "scroll_horizontal";
   Signal_Scroll_Vertical   : constant Glib.Signal_Name := "scroll_vertical";
   Signal_Select_All        : constant Glib.Signal_Name := "select_all";
   Signal_Start_Selection   : constant Glib.Signal_Name := "start_selection";
   Signal_Toggle_Add_Mode   : constant Glib.Signal_Name := "toggle_add_mode";
   Signal_Toggle_Focus_Row  : constant Glib.Signal_Name := "toggle_focus_row";
   Signal_Undo_Selection    : constant Glib.Signal_Name := "undo_selection";
   Signal_Unselect_All      : constant Glib.Signal_Name := "unselect_all";

private
   type Gtk_List_Item_Record is new Gtk.Item.Gtk_Item_Record with null record;

   pragma Import (C, Get_Type, "gtk_list_item_get_type");
end Gtk.List_Item;

--  The following subprogram never had a binding, and is now obsolescent:
--  No binding: gtk_list_item_new
