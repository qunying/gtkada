with Glib; use Glib;
with Gdk.Types; use Gdk.Types;
with Gtk.Adjustment; use Gtk.Adjustment;
with Gtk.Box; use Gtk.Box;
with Gtk.Button; use Gtk.Button;
with Gtk.Container; use Gtk.Container;
with Gtk.Dialog; use Gtk.Dialog;
with Gtk.Enums; use Gtk.Enums;
with Gtk.Frame; use Gtk.Frame;
with Gtk.Label; use Gtk.Label;
with Gtk.Object; use Gtk.Object;
with Gtk.Scrolled_Window; use Gtk.Scrolled_Window;
with Gtk.Signal; use Gtk.Signal;
with Gtk.Table; use Gtk.Table;
with Gtk.Toggle_Button; use Gtk.Toggle_Button;
with Gtk.Widget; use Gtk.Widget;
with Gtk; use Gtk;

package body Create_Scrolled is

   package Widget_Cb is new Signal.Object_Callback (Gtk_Widget);

   Window : Gtk.Dialog.Gtk_Dialog;

   procedure Run (Widget : in out Gtk.Button.Gtk_Button'Class) is
      Id        : Guint;
      Label     : Gtk_Label;
      Frame     : Gtk_Frame;
      Button    : Gtk_Button;
      Table     : Gtk_Table;
      Scrolled  : Gtk_Scrolled_Window;
      Toggle    : Gtk_Toggle_Button;
   begin

      if not Is_Created (Window) then
         Gtk_New (Window);
         Id := Widget_Cb.Connect (Window, "destroy", Destroy'Access, Window);
         Set_Title (Window, "Scrolled Window");
         Border_Width (Window, Border_Width => 0);

         Gtk_New (Scrolled);
         Border_Width (Scrolled, 10);
         Set_Policy (Scrolled, Policy_Automatic, Policy_Automatic);
         Pack_Start (Get_Vbox (Window), Scrolled, True, True, 0);
         Show (Scrolled);

         Gtk_New (Table, 20, 20, False);
         Set_Row_Spacings (Table, 10);
         Set_Col_Spacings (Table, 10);
         Add (Scrolled, Table);
         Set_Focus_Hadjustment (Table, Get_Hadjustment (Scrolled));
         Set_Focus_Vadjustment (Table, Get_Vadjustment (Scrolled));
         Show (Table);

         for I in 0 .. 19 loop
            for J in 0 .. 19 loop
               Gtk_New (Toggle, "button (" & Integer'Image (I)
                        & "," & Integer'Image (J) & ")");
               Attach_Defaults (Table, Toggle, Gint (I), Gint (I + 1),
                                Gint (J), Gint (J + 1));
               Show (Toggle);
            end loop;
         end loop;

         Gtk_New (Button, "close");
         Id := Widget_Cb.Connect (Button, "clicked", Destroy'Access, Window);
         Set_Flags (Button, Can_Default);
         Pack_Start (Get_Action_Area (Window), Button, True, True, 0);
         Grab_Default (Button);
         Show (Button);
      end if;

      if not Gtk.Widget.Visible_Is_Set (Window) then
         Gtk.Widget.Show (Window);
      else
         Gtk.Widget.Destroy (Window);
      end if;

   end Run;

end Create_Scrolled;

