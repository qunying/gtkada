------------------------------------------------------------------------------
--               GtkAda - Ada95 binding for the Gimp Toolkit                --
--                                                                          --
--                     Copyright (C) 2014, AdaCore                          --
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

with Cairo;               use Cairo;
with Gdk.RGBA;            use Gdk.RGBA;
with Glib;                use Glib;
with Gtk.Enums;           use Gtk.Enums;
with Gtk.Scrolled_Window; use Gtk.Scrolled_Window;
with Gtkada.Canvas_View;  use Gtkada.Canvas_View;
with Gtkada.Style;        use Gtkada.Style;

package body Create_Canvas_View_Composite is

   ----------
   -- Help --
   ----------

   function Help return String is
   begin
      return "This demo illustrates various capabilities for compositing items"
        & " in the canvas_view widget."
        & ASCII.LF
        & "The first item (red background) shows that @bautomatic size@B"
        & " computation occurs for items, based on the size requested by"
        & " their children and their margin."
        & ASCII.LF
        & "The second item shows a toplevel item with three children."
        & " The first two of these children are @bfloating@B, so that the"
        & " third is laid out at the same vertical position, and thus on top"
        & " of them. In addition, the floating child are floated to the"
        & " left and to the right, and have margins."
        & ASCII.LF
        & "The third item illustrates @balignment@B. The first three children"
        & " specify an explicit width, and therefore the alignment property"
        & " has a visible effect. The next three children do not specify"
        & " a width, and therefore end up with their parent's width, and the"
        & " alignment has no effect. All children have extra @bmargins@B,"
        & " which explains why there is an empty space to their left and"
        & " right.";
   end Help;

   ---------
   -- Run --
   ---------

   procedure Run (Frame : access Gtk.Frame.Gtk_Frame_Record'Class) is
      Canvas       : Canvas_View;
      Model        : List_Canvas_Model;
      Scrolled     : Gtk_Scrolled_Window;
      Rect, Rect2  : Rect_Item;
      Red, Green, Blue : Drawing_Style;

      procedure Do_Example
        (Layout : Child_Layout_Strategy; X, Y : Model_Coordinate);

      procedure Do_Example
        (Layout : Child_Layout_Strategy; X, Y : Model_Coordinate)
      is
         M : Margins;
         W, H, W2, H2 : Model_Coordinate;
      begin
         --  rectangle 1

         Rect := Gtk_New_Rect (Red, Radius => 4.0);
         Rect.Set_Child_Layout (Layout);
         Rect.Set_Position ((X, Y));
         Model.Add (Rect);

         case Layout is
            when Vertical_Stack =>
               M := (Top => 10.0, Bottom => 20.0, others => 0.0);
            when Horizontal_Stack =>
               M := (Left => 10.0, Right => 20.0, others => 0.0);
         end case;

         Rect2 := Gtk_New_Rect (Blue, 10.0, 10.0);
         Rect.Add_Child (Rect2, Margin => M);
         Rect2 := Gtk_New_Rect (Green, 10.0, 10.0);
         Rect.Add_Child (Rect2, Margin => M);

         --  rectangle 2: testing floating items

         Rect := Gtk_New_Rect (Green);
         Model.Add (Rect);
         Rect.Set_Child_Layout (Layout);
         Rect.Set_Position ((X + 90.0, Y));

         Rect2 := Gtk_New_Rect (Red, 20.0, 20.0);
         Rect.Add_Child (Rect2, Float => Float_End,
                         Margin => (others => 10.0));

         Rect2 := Gtk_New_Rect (Red, 20.0, 20.0);
         Rect.Add_Child (Rect2, Float => Float_Start,
                         Margin => (others => 10.0));

         Rect2 := Gtk_New_Rect (Blue, Width => 60.0, Height => 60.0);
         Rect.Add_Child (Rect2, Margin => (others => 5.0));

         --  rectangle 3: testing alignments

         case Layout is
            when Horizontal_Stack =>
               M := (Top => 10.0, Bottom => 10.0, others => 0.0);
               W2 := -1.0;
               H2 := 100.0;
               W := 30.0;
               H := -1.0;
            when Vertical_Stack =>
               M := (Left => 10.0, Right => 10.0, others => 0.0);
               W2 := 100.0;
               H2 := -1.0;
               W := -1.0;
               H := 30.0;
         end case;

         Rect := Gtk_New_Rect (Blue, Width => W2, Height => H2);
         Model.Add (Rect);
         Rect.Set_Child_Layout (Layout);
         Rect.Set_Position ((X + 180.0, Y + 0.0));

         Rect2 := Gtk_New_Rect (Red, 30.0, 30.0);
         Rect.Add_Child (Rect2, Align  => Align_Start, Margin => M);

         Rect2 := Gtk_New_Rect (Red, 30.0, 30.0);
         Rect.Add_Child (Rect2, Align  => Align_Center, Margin => M);

         Rect2 := Gtk_New_Rect (Red, 30.0, 30.0);
         Rect.Add_Child (Rect2, Align  => Align_End, Margin => M);

         Rect2 := Gtk_New_Rect (Green, W, H);
         Rect.Add_Child (Rect2, Align  => Align_Start, Margin => M);

         Rect2 := Gtk_New_Rect (Green, W, H);
         Rect.Add_Child (Rect2, Align  => Align_Center, Margin => M);

         Rect2 := Gtk_New_Rect (Green, W, H);
         Rect.Add_Child (Rect2, Align  => Align_End, Margin => M);
      end Do_Example;

   begin
      Red := Gtk_New
        (Stroke => Black_RGBA,
         Fill   => Create_Rgba_Pattern ((1.0, 0.0, 0.0, 0.6)));
      Green := Gtk_New
        (Stroke => Black_RGBA,
         Fill   => Create_Rgba_Pattern ((0.0, 1.0, 0.0, 0.6)));
      Blue := Gtk_New
        (Stroke => Black_RGBA,
         Fill   => Create_Rgba_Pattern ((0.0, 0.0, 1.0, 0.6)));

      Gtk_New (Model);

      Do_Example (Vertical_Stack, 0.0, 0.0);
      Do_Example (Horizontal_Stack, 0.0, 250.0);

      --  Need to compute all coordinates

      Model.Refresh_Layout;

      --  Create the view once the model is populated, to avoid a refresh
      --  every time a new item is added.

      Gtk_New (Scrolled);
      Scrolled.Set_Policy (Policy_Automatic, Policy_Automatic);
      Frame.Add (Scrolled);

      Gtk_New (Canvas, Model);
      Unref (Model);
      Scrolled.Add (Canvas);

      Frame.Show_All;
   end Run;

end Create_Canvas_View_Composite;