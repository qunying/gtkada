-----------------------------------------------------------------------
--          GtkAda - Ada95 binding for the Gimp Toolkit              --
--                                                                   --
--                     Copyright (C) 1998-2000                       --
--        Emmanuel Briot, Joel Brobecker and Arnaud Charlet          --
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

with System;

package body Gtk.Rc is

   ----------------------------
   -- Add_Widget_Class_Style --
   ----------------------------

   procedure Add_Widget_Class_Style
     (Style   : in Gtk_Rc_Style;
      Pattern : in String)
   is
      procedure Internal
        (Style : in Gtk_Rc_Style; Pattern : in String);
      pragma Import (C, Internal, "gtk_rc_add_widget_class_style");

   begin
      Internal (Style, Pattern & ASCII.NUL);
   end Add_Widget_Class_Style;

   ---------------------------
   -- Add_Widget_Name_Style --
   ---------------------------

   procedure Add_Widget_Name_Style
     (Style   : in Gtk_Rc_Style;
      Pattern : in String)
   is
      procedure Internal
        (Style : in Gtk_Rc_Style; Pattern : in String);
      pragma Import (C, Internal, "gtk_rc_add_widget_name_style");

   begin
      Internal (Style, Pattern & ASCII.NUL);
   end Add_Widget_Name_Style;

   ---------------
   -- Get_Style --
   ---------------

   function Get_Style
     (Widget : access Gtk.Widget.Gtk_Widget_Record'Class) return Gtk_Rc_Style
   is
      function Internal (Widget : in System.Address) return Gtk_Rc_Style;
      pragma Import (C, Internal, "gtk_rc_get_style");

   begin
      return Internal (Get_Object (Widget));
   end Get_Style;

   -----------
   -- Parse --
   -----------

   procedure Parse (Filename : in String) is
      procedure Internal (Filename : in String);
      pragma Import (C, Internal, "gtk_rc_parse");
   begin
      Internal (Filename & ASCII.NUL);
   end Parse;

   ------------------
   -- Parse_String --
   ------------------

   procedure Parse_String (Rc_String : in String) is
      procedure Internal (Rc_String : in String);
      pragma Import (C, Internal, "gtk_rc_parse_string");
   begin
      Internal (Rc_String & ASCII.NUL);
   end Parse_String;

end Gtk.Rc;
