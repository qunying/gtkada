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
with Gtk.Enums; use Gtk.Enums;

package body Gtk.Scrolled_Window is

   -----------------------
   -- Add_With_Viewport --
   -----------------------

   procedure Add_With_Viewport
     (Scrolled_Window : access Gtk_Scrolled_Window_Record;
      Child           : access Gtk.Widget.Gtk_Widget_Record'Class)
   is
      procedure Internal
        (Scrolled_Window : System.Address;
         Child           : System.Address);
      pragma Import (C, Internal, "gtk_scrolled_window_add_with_viewport");

   begin
      Internal (Get_Object (Scrolled_Window), Get_Object (Child));
   end Add_With_Viewport;

   ----------------------
   -- Get_Hadjustement --
   ----------------------

   function Get_Hadjustment
     (Scrolled_Window : access Gtk_Scrolled_Window_Record)
      return Adjustment.Gtk_Adjustment
   is
      function Internal (Scrolled_Window : in System.Address)
        return System.Address;
      pragma Import (C, Internal, "gtk_scrolled_window_get_hadjustment");
      Stub : Adjustment.Gtk_Adjustment_Record;

   begin
      return Adjustment.Gtk_Adjustment
        (Get_User_Data (Internal (Get_Object (Scrolled_Window)), Stub));
   end Get_Hadjustment;

   ----------------------
   -- Get_Vadjustement --
   ----------------------

   function Get_Vadjustment
     (Scrolled_Window : access Gtk_Scrolled_Window_Record)
      return Adjustment.Gtk_Adjustment
   is
      function Internal (Scrolled_Window : in System.Address)
        return System.Address;
      pragma Import (C, Internal, "gtk_scrolled_window_get_vadjustment");
      Stub : Adjustment.Gtk_Adjustment_Record;

   begin
      return Adjustment.Gtk_Adjustment
        (Get_User_Data (Internal (Get_Object (Scrolled_Window)), Stub));
   end Get_Vadjustment;

   -------------
   -- Gtk_New --
   -------------

   procedure Gtk_New
     (Scrolled_Window : out Gtk_Scrolled_Window;
      Hadjustment     : Adjustment.Gtk_Adjustment :=
        Adjustment.Null_Adjustment;
      Vadjustment     : Adjustment.Gtk_Adjustment :=
        Adjustment.Null_Adjustment)
   is
   begin
      Scrolled_Window := new Gtk_Scrolled_Window_Record;
      Initialize (Scrolled_Window, Hadjustment, Vadjustment);
   end Gtk_New;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Scrolled_Window : access Gtk_Scrolled_Window_Record'Class;
      Hadjustment    : Adjustment.Gtk_Adjustment := Adjustment.Null_Adjustment;
      Vadjustment    : Adjustment.Gtk_Adjustment := Adjustment.Null_Adjustment)
   is
      function Internal (Hadjustment, Vadjustment : in System.Address)
                         return System.Address;
      pragma Import (C, Internal, "gtk_scrolled_window_new");

      Hadj, Vadj : System.Address;

      use type Gtk.Adjustment.Gtk_Adjustment;

   begin
      if Hadjustment = null then
         Hadj := System.Null_Address;
      else
         Hadj := Get_Object (Hadjustment);
      end if;

      if Vadjustment = null then
         Vadj := System.Null_Address;
      else
         Vadj := Get_Object (Vadjustment);
      end if;

      Set_Object (Scrolled_Window, Internal (Hadj, Vadj));
      Initialize_User_Data (Scrolled_Window);
   end Initialize;

   ---------------------
   -- Set_Hadjustment --
   ---------------------

   procedure Set_Hadjustment
     (Scrolled_Window : access Gtk_Scrolled_Window_Record;
      Hadjustment     : Gtk.Adjustment.Gtk_Adjustment)
   is
      procedure Internal (Scrolled_Window : in System.Address;
                          Hadjustment     : in System.Address);
      pragma Import (C, Internal, "gtk_scrolled_window_set_hadjustment");
      use type Gtk.Adjustment.Gtk_Adjustment;
   begin
      if Hadjustment = null then
         Internal (Get_Object (Scrolled_Window), System.Null_Address);
      else
         Internal (Get_Object (Scrolled_Window), Get_Object (Hadjustment));
      end if;
   end Set_Hadjustment;

   -------------------
   -- Set_Placement --
   -------------------

   procedure Set_Placement
     (Scrolled_Window  : access Gtk_Scrolled_Window_Record;
      Window_Placement : Gtk_Corner_Type)
   is
      procedure Internal (Scrolled_Window  : System.Address;
                          Window_Placement : Gint);
      pragma Import (C, Internal, "gtk_scrolled_window_set_placement");

   begin
      Internal
        (Get_Object (Scrolled_Window), Gtk_Corner_Type'Pos (Window_Placement));
   end Set_Placement;

   ----------------
   -- Set_Policy --
   ----------------

   procedure Set_Policy
     (Scrolled_Window    : access Gtk_Scrolled_Window_Record;
      H_Scrollbar_Policy : in     Enums.Gtk_Policy_Type;
      V_Scrollbar_Policy : in     Enums.Gtk_Policy_Type)
   is
      procedure Internal (Scrolled_Window    : in System.Address;
                          H_Scrollbar_Policy : in Gint;
                          V_Scrollbar_Policy : in Gint);
      pragma Import (C, Internal, "gtk_scrolled_window_set_policy");
   begin
      Internal (Get_Object (Scrolled_Window),
                Enums.Gtk_Policy_Type'Pos (H_Scrollbar_Policy),
                Enums.Gtk_Policy_Type'Pos (V_Scrollbar_Policy));
   end Set_Policy;

   ---------------------
   -- Set_Vadjustment --
   ---------------------

   procedure Set_Vadjustment
     (Scrolled_Window : access Gtk_Scrolled_Window_Record;
      Vadjustment     : Gtk.Adjustment.Gtk_Adjustment)
   is
      procedure Internal (Scrolled_Window : in System.Address;
                          Vadjustment     : in System.Address);
      pragma Import (C, Internal, "gtk_scrolled_window_set_vadjustment");
      use type Gtk.Adjustment.Gtk_Adjustment;
   begin
      if Vadjustment = null then
         Internal (Get_Object (Scrolled_Window), System.Null_Address);
      else
         Internal (Get_Object (Scrolled_Window), Get_Object (Vadjustment));
      end if;
   end Set_Vadjustment;

   --------------
   -- Generate --
   --------------

   procedure Generate (N : in Node_Ptr; File : in File_Type) is
      Id : constant Gtk_Type := Get_Type;
      pragma Warnings (Off, Id);

   begin
      Gen_New (N, "Scrolled_Window", File => File);
      Container.Generate (N, File);
      Gen_Set (N, "Scrolled_Window", "Policy", "hscrollbar_policy",
        "vscrollbar_policy", "", "", File);
   end Generate;

end Gtk.Scrolled_Window;
