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

--  <description>
--
--  This widget is the base of the tree for displayable objects.
--  (A displayable object is one which takes up some amount
--  of screen real estate). It provides a common base and interface
--  which actual widgets must adhere to.
--
--  This package provides some services which might have been more appropriate
--  in some other packages, but could not because of dependency circularities
--  (there are for instance some functions relating to colors and colormaps).
--  We have tried to reference these functions in the other packages as well.
--
--  </description>
--  <c_version>1.2.6</c_version>

with Gdk.Color;
with Gdk.Event;
with Gdk.Bitmap;
with Gdk.Rectangle;
with Gdk.Types;
with Gtk.Object;
with Gdk.Visual;
with Gdk.Window;
with Gtk.Accel_Group;
with Gtk.Adjustment;
with Gtk.Enums;
with Gtk.Object;
with Glib.Glist;
with Glib.GSlist;
with System;
pragma Elaborate_All (Glib.GSlist);

package Gtk.Widget is

   type Gtk_Widget_Record is new Object.Gtk_Object_Record with private;
   type Gtk_Widget is access all Gtk_Widget_Record'Class;

   type Gtk_Requisition is record
      Width  : Gint16;
      Height : Gint16;
   end record;
   pragma Pack (Gtk_Requisition);
   --  <description>
   --  Gtk_Requisition is the desired amount of screen real-estate a widget
   --  requests to the server. Its real allocated size might be different.
   --  See the section in the GtkAda user guide on how to create new widgets
   --  in Ada, and the examples/base_widget directory for an example on how to
   --  use this.
   --  </description>

   type Gtk_Allocation is record
      X      : Gint16;
      Y      : Gint16;
      Width  : Guint16;
      Height : Guint16;
   end record;
   pragma Pack (Gtk_Allocation);
   --  <description>
   --  Gtk_Allocation indicates a size and position a widget was allocated.
   --  See the section in the user guide on how to create new widgets for more
   --  information.
   --  </description>

   -------------------------
   -- Widgets' life cycle --
   -------------------------

   procedure Destroy_Cb (Widget : access Gtk_Widget_Record'Class);
   --  This function should be used as a callback to destroy a widget.
   --  All it does is call Destroy on its argument, but its profile is
   --  compatible with the handlers found in Gtk.Handlers.

   procedure Unparent (Widget : access Gtk_Widget_Record'Class);
   --  Detach the widget from its parent.
   --  As a side effect, the widget will be erased from the screen.

   procedure Show (Widget : access Gtk_Widget_Record);
   --  Schedule the widget to be displayed on the screen when its parent is
   --  also shown (emits the "show" signal).
   --  If its ancestors are already mapped to the screen, then the widget is
   --  immediatly displayed through a call to Map below.

   procedure Show_Now (Widget : access Gtk_Widget_Record);
   --  Show the widget.
   --  If it is an unmapped toplevel widget, wait for it to be mapped. This
   --  creates a recursive main_loop.

   procedure Hide (Widget : access Gtk_Widget_Record);
   --  Hide the widget from the screen (emits the "hide" signal).
   --  If Widget was visible, it is immediatly hidden.
   --  If one of its ancestor is later shown on the screen, Widget won't
   --  appear.

   procedure Show_All (Widget : access Gtk_Widget_Record);
   --  Show Widget and all its children recursively.

   procedure Hide_All (Widget : access Gtk_Widget_Record);
   --  Hide Widget and all its children.
   --  Note that if you simply want to delete Widget from the screen, you can
   --  simply call the Hide subprogram on it. This procedure Hide_All should
   --  only be used if you want to unschedule a widget to be displayed later,
   --  not to remove an actual widget from the screen.

   procedure Map (Widget : access Gtk_Widget_Record);
   --  Map a widget to the screen.
   --  A window is created for it on the screen (through a call to Realize) and
   --  Widget is then drawn on the screen (if its ancestors are also mapped).
   --  This function is recursive and will also map all the children of Widget.
   --
   --  It is recommended to use the higher-level Show instead.

   procedure Unmap (Widget : access Gtk_Widget_Record);
   --  Unmap a widget from the screen.
   --  This results in the widget being hidden, but not destroyed. It can be
   --  shown again any time through a call to Map (provided its ancestors are
   --  also mapped).
   --
   --  It is recommended to use the higher-level Hide instead.

   procedure Realize (Widget : access Gtk_Widget_Record);
   --  Create a window for Widget and its ancestors (emit the "realize" signal)
   --  This does not mean that the widget will appear on the screen, but
   --  ressources such as colormaps, etc. become available.
   --  Some routines require that the widget is realized before any call.
   --  You must set the Event_Mask before calling this routine if you want to
   --  change it from its default value.

   procedure Unrealize (Widget : access Gtk_Widget_Record);
   --  Hide the widget from the screen and deletes the associated window.
   --  This does not destroy the widget itself, only its server-side
   --  ressources.

   function Get_Type return Gtk.Gtk_Type;
   --  Return the internal value associated with a Gtk_Widget.

   ----------------------
   -- Drawing a widget --
   ----------------------

   procedure Queue_Draw (Widget : access Gtk_Widget_Record);
   --  Add a drawing request to the event queue for the whole widget.
   --  This is more efficient than calling Draw directly, since GtkAda groups
   --  drawing requests as much as possible to speed up the drawing process.
   --  The actualy drawing will take place as soon as GtkAda is not busy
   --  processing other events, but before idle events.

   procedure Queue_Draw_Area (Widget : access Gtk_Widget_Record;
                              X      : Gint;
                              Y      : Gint;
                              Width  : Gint;
                              Height : Gint);
   --  Add a drawing request to the event queue for part of the widget.
   --  This is more efficient that calling Draw directly (see Queue_Draw).

   procedure Queue_Clear (Widget : access Gtk_Widget_Record);
   --  Add a clear request to the event queue for the whole widget.
   --  This is added to the same list as for Queue_Draw, and thus is coalesced
   --  as much as possible with other drawing requests.

   procedure Queue_Clear_Area (Widget : access Gtk_Widget_Record;
                               X      : Gint;
                               Y      : Gint;
                               Width  : Gint;
                               Height : Gint);
   --  Add a clear request to the event queue for part of the widget.
   --  This is added to the same list as for Queue_Draw, and thus is coalesced
   --  as much as possible with other drawing requests.

   procedure Queue_Resize (Widget : access Gtk_Widget_Record);
   --  Queue drawing requests after a resizing of the widget.
   --  This clears the widget, and its parent if any, so that everything is
   --  correctly redrawn.
   --  You should not have to call this function directly.

   procedure Draw
     (Widget : access Gtk_Widget_Record;
      Area   : in Gdk.Rectangle.Gdk_Rectangle := Gdk.Rectangle.Full_Area);
   --  Emit a "draw" signal for a specific area of the widget.
   --  The visual aspect might be different whether the widget has the focus
   --  or not.

   procedure Draw_Focus (Widget : access Gtk_Widget_Record);
   --  Emit a "draw_focus" signal for the widget.
   --  The widget will be painted as it appears when it has the focus.

   procedure Draw_Default (Widget : access Gtk_Widget_Record);
   --  Emit a "draw_default" signal for the widget.
   --  The widget will be painted as it appears when it doesn't have the focus.

   -----------------------
   -- Size and position --
   -----------------------

   procedure Size_Request (Widget      : access Gtk_Widget_Record;
                           Requisition : Gtk_Requisition);
   --  Emit a "size_request" event for the widget

   procedure Size_Allocate (Widget     : access Gtk_Widget_Record;
                            Allocation : Gtk_Allocation);
   --  Emit a "size_allocate" event for the widget.
   --  Allocation'size is first constrained to a range between 1x1 and
   --  32767x32767.
   --  A clear and draw request is also queued if required.

   function Get_Child_Requisition (Widget : access Gtk_Widget_Record)
                                  return Gtk_Requisition;
   --  Return the size requests by the widget.
   --  This is the ideal size for the widget, not necessarily its actual size.
   --  See the user guide's section on how to create new widgets for more
   --  information on the size requisition and allocation.

   procedure Set_UPosition (Widget : access Gtk_Widget_Record;
                            X, Y   : in Gint);
   --  Modify the position of the widget.
   --  This should be used only for toplevel widgets (windows and dialogs),
   --  since other widgets' positions are handled by their parent.

   procedure Set_USize (Widget : access Gtk_Widget_Record;
                        Width, Height : in Gint);
   --  Modify the size of the widget.
   --  This sets an absolute size for the widget, no matter what its requested
   --  size would be. For Gtk_Windows, you should consider using
   --  Set_Default_Size instead, which sets a minimal size, but use the
   --  widget's requested size if it is bigger.
   --  If Width or Height is negative, they are ignored, and the widget's
   --  default width is kept.

   function Get_Allocation_Width (Widget : access Gtk_Widget_Record)
                                 return Guint;
   --  Return the current width of the widget.

   function Get_Allocation_Height (Widget : access Gtk_Widget_Record)
                                  return Guint;
   --  Return the current height of the widget.

   function Get_Allocation_X (Widget : access Gtk_Widget_Record) return Gint;
   --  Return the current position of the widget, relative to its parent.

   function Get_Allocation_Y (Widget : access Gtk_Widget_Record) return Gint;
   --  Return the current position of the widget, relative to its parent.

   ------------------
   -- Accelerators --
   ------------------

   procedure Add_Accelerator
     (Widget       : access Gtk_Widget_Record;
      Accel_Signal : in String;
      Accel_Group  : in Gtk.Accel_Group.Gtk_Accel_Group;
      Accel_Key    : in Gdk.Types.Gdk_Key_Type;
      Accel_Mods   : in Gdk.Types.Gdk_Modifier_Type;
      Accel_Flags  : in Gtk.Accel_Group.Gtk_Accel_Flags);
   --  Add a new accelerator for the widget.
   --  The signal Accel_Signal will be sent to Widget when the matching
   --  key is pressed and the widget has the focus.

   procedure Remove_Accelerator
     (Widget       : access Gtk_Widget_Record;
      Accel_Group  : in Gtk.Accel_Group.Gtk_Accel_Group;
      Accel_Key    : in Gdk.Types.Gdk_Key_Type;
      Accel_Mods   : in Gdk.Types.Gdk_Modifier_Type);
   --  Remove an accelerator for the widget.

   procedure Remove_Accelerators
     (Widget       : access Gtk_Widget_Record;
      Accel_Signal : in String;
      Visible_Only : in Boolean := True);
   --  Remove all the accelerators for the widget that emits the Accel_Signal
   --  signal when the key is pressed.
   --  Visible_Only is currently unused in the code of gtk+.

   function Accelerator_Signal
     (Widget       : access Gtk_Widget_Record;
      Accel_Group  : in Gtk.Accel_Group.Gtk_Accel_Group;
      Accel_Key    : in Gdk.Types.Gdk_Key_Type;
      Accel_Mods   : in Gdk.Types.Gdk_Modifier_Type)
     return Guint;
   --  Return the signal id of the signal emitted when Accel_Key is pressed
   --  inside the widget.

   procedure Lock_Accelerators (Widget : access Gtk_Widget_Record);
   --  Lock the accelerators for the widget.
   --  No new accelerator can be added to Widget (the default behavior is
   --  that the user can dynamically create new accelerators, for instance
   --  by pressing a not-yet assigned key on any menu item.
   --  If you call this function on the menu_item, this behavior will not
   --  longer be activated.

   procedure Unlock_Accelerators (Widget : access Gtk_Widget_Record);
   --  Unlock the accelerators for the widget.
   --  It is now possible to add new accelerators to the widget.

   -------------------------
   --  Events and signals --
   -------------------------

   function Event (Widget : access Gtk_Widget_Record'Class;
                   Event  : Gdk.Event.Gdk_Event)
                  return Gint;
   --  Emit a signal on the widget.
   --  The exact signal depends on the event type (i.e. if the type is
   --  Gdk_Button_Press, then a "button_press" signal is emitted).

   procedure Activate (Widget : access Gtk_Widget_Record);
   --  Emit an activate signal on the widget.
   --  The exact signal emitted depends on the widget type (i.e. for a
   --  Gtk_Button this emits a "clicked" signal, for a Gtk_Editable this emits
   --  the "activate" signal, ...).

   procedure Grab_Focus (Widget : access Gtk_Widget_Record);
   --  Emit the "grab_focus" signal for the widget.
   --  This is sent when the widget gets the focus. Its visual aspect might
   --  change.
   --  The "Can_Focus" flag must have been set first.

   procedure Set_Events (Widget : access Gtk_Widget_Record;
                         Events : in     Gdk.Types.Gdk_Event_Mask);
   --  Sets the event mask for the widget.
   --  Widget should not have been realized before, or nothing is done.
   --  This is the only way you can explictly get mouse or keyboards events on
   --  widgets that do not automatically get them, as for instance in a
   --  Gtk_Drawing_Area.

   function Get_Events (Widget : access Gtk_Widget_Record)
                       return Gdk.Types.Gdk_Event_Mask;
   --  Get the event mask for the widget.
   --  This indicates the list of events that the widget receives.

   procedure Add_Events (Widget : access Gtk_Widget_Record;
                         Events : in     Gdk.Types.Gdk_Event_Mask);
   --  Add some events to the current event mask of the widget.

   procedure Set_Extension_Events
     (Widget : access Gtk_Widget_Record;
      Mode   : in     Gdk.Types.Gdk_Extension_Mode);
   --  Set the extension event mask for the widget.
   --  This is used to activate some special input modes for other devices than
   --  keyboard and mouse.

   function Get_Extension_Events (Widget : access Gtk_Widget_Record)
                                 return Gdk.Types.Gdk_Extension_Mode;
   --  Return the current extension events mask.

   function Default_Motion_Notify_Event
     (Widget : access Gtk_Widget_Record'Class;
      Event  : Gdk.Event.Gdk_Event)
     return Gint;
   --  Access to the standard default callback for motion events:
   --  This is mainly used for rulers in Gtk.Ruler (See the example in
   --  testgtk, with create_rulers.adb)

   --------------------------
   -- Colors and colormaps --
   --------------------------

   function Get_Colormap (Widget : access Gtk_Widget_Record)
                         return Gdk.Color.Gdk_Colormap;
   --  Return the colormap used for the widget. This will generally be the
   --  same one for all widgets, but might be different if for instance a
   --  Gtk_Drawing_Area needs to display some different colors on a screen
   --  that only has a limited amount of colors.

   function Get_Visual (Widget : access Gtk_Widget_Record)
                       return Gdk.Visual.Gdk_Visual;
   --  Get the visual used for the widget.
   --  I.e. the structure that indicates the depth of the widget (number of
   --  bits per pixel), and some information used internally by GtkAda to
   --  handle colors and colormaps.

   procedure Set_Colormap (Widget : access Gtk_Widget_Record;
                           Cmap : Gdk.Color.Gdk_Colormap);
   --  Modify the colormap of the widget.
   --  The widget must not have been realized.

   procedure Set_Visual (Widget : access Gtk_Widget_Record;
                         Visual : Gdk.Visual.Gdk_Visual);
   --  Modify the visual of the widget.
   --  The widget must not have been realized.

   procedure Push_Colormap (Cmap : Gdk.Color.Gdk_Colormap);
   --  Modify temporarily the default colormap set for newly created widgets.
   --  You should use this in pair with Pop_Colormap below (Push the new value,
   --  create the widget, and pop the value).

   procedure Pop_Colormap;
   --  See Push_Colormap for more information.

   procedure Push_Visual   (Visual : Gdk.Visual.Gdk_Visual);
   --  Modify temporarily the default visual set for newly created widgets.
   --  You should use this in pair with Pop_Colormap below (Push the new value,
   --  create the widget, and pop the value).

   procedure Pop_Visual;
   --  See Push_Visual for more information.

   function Get_Default_Colormap return Gdk.Color.Gdk_Colormap;
   --  Return the default colormap used when a widget is created.

   procedure Set_Default_Colormap (Cmap : Gdk.Color.Gdk_Colormap);
   --  Modify permanently the default colormap used when a widget is created.
   --  If you only want to modify this colormap temporarily for a few widgets,
   --  you shoud consider using Push_Colormap and Pop_Colormap instead.

   function Get_Default_Visual return Gdk.Visual.Gdk_Visual;
   --  Return the default visual used when a new widget is created.

   procedure Set_Default_Visual (Visual : Gdk.Visual.Gdk_Visual);
   --  Modify permanently the default visual used when a widget is created.
   --  If you only want to modify this visual temporarily for a few widgets,
   --  you shoud consider using Push_Visual and Pop_Visual instead.

   ------------
   -- Styles --
   ------------
   --  Most functions related to modifying the style of a widget (i.e. its
   --  visual aspect) are found in the Gtk.Style package for circular
   --  dependency reasons.

   procedure Set_Rc_Style (Widget : access Gtk_Widget_Record);
   --  Restore the default style of a widget, as given by the configuration
   --  file initially parsed by GtkAda.

   procedure Ensure_Style (Widget : access Gtk_Widget_Record);
   --  Make sure that the widget has a style associated to it, either the
   --  default one as set by Set_Rc_Style above or one set by the user with
   --  Gtk.Style.Set_Style.

   procedure Restore_Default_Style (Widget : access Gtk_Widget_Record);
   --  Restore the default style that was set for the widget.
   --  The default style is the first one that was set either by a call
   --  to Set_Rc_Style or Gtk.Style.Set_Style.

   procedure Reset_Rc_Styles (Widget : access Gtk_Widget_Record);
   --  Restore the Rc style recursively for widget and its children.

   -------------------
   -- Widgets' tree --
   -------------------

   procedure Set_Name (Widget : access Gtk_Widget_Record;
                       Name   : in String);
   --  Set the name for the widget.
   --  This name is used purely internally to identify the widget, and does not
   --  give any visual clue.

   function Get_Name (Widget : access Gtk_Widget_Record)
                     return String;
   --  Return the name of the widget if it was set by Set_Name.
   --  Return the name of its class otherwise.

   procedure Set_Parent (Widget : access Gtk_Widget_Record;
                         Parent : in Gtk_Widget);
   --  Modify the parent for the widget.
   --  This is not the recommended way to do this, you should use
   --  Gtk.Container.Add or Gtk.Box.Pack_Start instead.

   function Get_Parent (Widget : access Gtk_Widget_Record)
                       return Gtk_Widget;
   --  Return the parent of the widget, or null if Widget is a toplevel
   --  widget.

   function Get_Toplevel (Widget : access Gtk_Widget_Record)
                          return Gtk_Widget;
   --  Return the toplevel ancestor of the widget.
   --  This is the window or dialog in which the widget is included.
   --  The widget returned does not have any parent.

   function Get_Ancestor (Widget        : access Gtk_Widget_Record;
                          Ancestor_Type : in Gtk_Type)
                         return Gtk_Widget;
   --  Return the closest ancestor of Widget which is of type Ancestor_Type.
   --  Return null if there is none.

   function Is_Ancestor (Widget   : access Gtk_Widget_Record;
                         Ancestor : access Gtk_Widget_Record'Class)
                        return Boolean;
   --  Return True if Ancestor is in the ancestor tree for Widget.
   --  I.e. if Widget is contained within Ancestor.

   procedure Reparent (Widget     : access Gtk_Widget_Record;
                       New_Parent : access Gtk_Widget_Record'Class);
   --  Change the parent of the widget dynamically.
   --  If both the new parent and the widget are shown, then the widget is
   --  visually redrawn in its new parent.

   --------------------
   -- Misc functions --
   --------------------

   procedure Set_Scroll_Adjustments
     (Widget : access Gtk_Widget_Record;
      Hadj   : Gtk.Adjustment.Gtk_Adjustment;
      Vadj   : Gtk.Adjustment.Gtk_Adjustment);
   --  Emit the "set_scroll_adjustments" signal.
   --  The exact signal emitted depends on the widget type.
   --  The handler creates the adjustments if null is passed as argument, and
   --  makes sure both adjustments are in the correct range.

   procedure Popup (Widget : access Gtk_Widget_Record;
                    X, Y   : in Gint);
   --  Realize the widget (see Realize above), moves it to the screen position
   --  (X, Y), and shows the widget.
   --  This should only be used for toplevel windows and dialogs, as you can
   --  no modify the position of a widget that has a parent (the parent is
   --  then responsible for its position).

   function Intersect (Widget       : access Gtk_Widget_Record;
                       Area         : Gdk.Rectangle.Gdk_Rectangle;
                       Intersection : access Gdk.Rectangle.Gdk_Rectangle)
                      return Boolean;
   --  Return True if the widget intersects the screen area Area.
   --  The intersection area is returned in Intersection.

   procedure Grab_Default (Widget : access Gtk_Widget_Record);
   --  The widget becomes the default widget for its parent window or dialog.
   --  All keyboard events will be sent to it if no other widget has the focus.
   --  Note that the "Can_Default" flag must have been set first on WIDGET.

   procedure Set_State (Widget : access Gtk_Widget_Record;
                        State : in Enums.Gtk_State_Type);
   --  Modify the state of the widget.
   --  This modifies its visual aspect, and thus should be used only if you
   --  change its behavior at the same time, so as not to confuse the user.

   procedure Set_Sensitive (Widget    : access Gtk_Widget_Record;
                            Sensitive : in Boolean := True);
   --  Modify the sensitivity of the widget.
   --  An insensitive widget is generally grayed out, and can not be activated.
   --  For instance, an insensitive menu item is grayed, and can never be
   --  selected.

   procedure Set_App_Paintable (Widget        : access Gtk_Widget_Record;
                                App_Paintable : Boolean);
   --  Modify the "App_Paintable" flag for the widget.

   procedure Get_Pointer (Widget : access Gtk_Widget_Record;
                          X      : out Gint;
                          Y      : out Gint);
   --  Return the coordinates of the pointer (i.e. mouse) relative to Widget.

   function Get_Window (Widget : access Gtk_Widget_Record)
                       return Gdk.Window.Gdk_Window;
   --  Get the Gdk window associated with the widget. You can use this window
   --  if you need to draw directly on the widget using the functions found in
   --  the Gdk hierarchy.

   procedure Shape_Combine_Mask
     (Widget     : access Gtk_Widget_Record;
      Shape_Mask : Gdk.Bitmap.Gdk_Bitmap'Class;
      Offset_X   : Gint;
      Offset_Y   : Gint);
   --  Modify the shape of the window that contains the widget.
   --  This allows for transparent windows, and requires the Xext library to be
   --  available on your system. If this library is not available, your program
   --  will still work.
   --  See the manual page for XShapeCombineMask(3x) for more information.

   -----------
   -- Flags --
   -----------
   --  Some additional flags are defined for all the visual objects (widgets).
   --  They are defined in addition to the ones defined in Gtk.Object.
   --  These flags are important in that they define exactly the different
   --  states a widget can be in.
   --
   --  - "Toplevel":
   --    Set if the widget is a toplevel widget, ie has no parent. This is
   --    mostly true for windows and dialogs.
   --
   --  - "No_Window":
   --    Set if the widget does not have an associated X11 window, ie can not
   --    receive events directly. For instance, a Gtk_Toolbar does not have
   --    an associated window. These objects are more lightweight, but require
   --    more work from GtkAda. This flag is only set if the widget will never
   --    have a window, even after it is realized.
   --
   --  - "Realized":
   --    Set if the widget has been realized, ie its associated X11 window has
   --    been created (providing the widget excepts a window, see the No_Window
   --    flag
   --
   --  - "Mapped":
   --    Set if the widget is visible on the screen. This is only possible if
   --    the Visible flag is also set.
   --
   --  - "Visible":
   --    Set if the widget will be displayed on the screen when mapped (see the
   --    functions Show and Hide in this package).
   --
   --  - "Sensitive":
   --    Set if the widget is listening to events. See the function
   --    Set_Sensitive in this package. An insensitive widget will generally
   --    have a different visual aspect to clue that it is unavailable (for
   --    instance an insensitive item menu will be grayed)
   --
   --  - "Parent_Sensitive":
   --    Set if the parent is sensitive. A widget is sensitive only if both
   --    the Sensitive and Parent_Sensitive are set.
   --
   --  - "Can_Focus":
   --    Set if the widget can have the focus, ie get keyboard events. Most
   --    widgets can not have the focus.
   --
   --  - "Has_Focus":
   --    Set if the widget currently has the focus. See the function Grab_Focus
   --    in this package.
   --
   --  - "Can_Default":
   --    Set if the widget can be the default widget in a window, ie the one
   --    that will get the keyboard events by default. For instance, the
   --    default button in a dialog is the one that gets clicked on when the
   --    user pressed Enter anywhere in the dialog.
   --
   --  - "Has_Default":
   --    Set if the widget is currently the default widget. See the function
   --    Grab_Default in this package.
   --
   --  - "Has_Grab":
   --    Set if the widget currently grabs all mouse and keyboard events in
   --    the application, even if it does not have the focus. There can be only
   --    such widget per application at any given time.
   --
   --  - "Rc_Style":
   --    Set if the widget's style is either the default style, or in a
   --    customization file. This is unset if the style has been modified by
   --    the user.
   --
   --  - "Composite_Child":
   --    ???
   --
   --  - "No_Reparent":
   --    This flags is never used in gtk+.
   --
   --  - "App_Paintable":
   --    For some containers (including Gtk_Window and Gtk_Layout), this is
   --    unset when the container itself has some special drawing routines.
   --
   --  - "Receives_Default":
   --    Set when the widget receives the default at the time it receives the
   --    focus. This is how the default button in a dialog is automatically
   --    changed when you press another button.

   Toplevel         : constant := 2 ** 4;
   No_Window        : constant := 2 ** 5;
   Realized         : constant := 2 ** 6;
   Mapped           : constant := 2 ** 7;
   Visible          : constant := 2 ** 8;
   Sensitive        : constant := 2 ** 9;
   Parent_Sensitive : constant := 2 ** 10;
   Can_Focus        : constant := 2 ** 11;
   Has_Focus        : constant := 2 ** 12;
   Can_Default      : constant := 2 ** 13;
   Has_Default      : constant := 2 ** 14;
   Has_Grab         : constant := 2 ** 15;
   Rc_Style         : constant := 2 ** 16;
   Composite_Child  : constant := 2 ** 17;
   No_Reparent      : constant := 2 ** 18;
   App_Paintable    : constant := 2 ** 19;
   Receives_Default : constant := 2 ** 20;

   function Toplevel_Is_Set (Widget : access Gtk_Widget_Record'Class)
                            return Boolean;
   --  Test whether the Toplevel flag is set.

   function No_Window_Is_Set (Widget : access Gtk_Widget_Record'Class)
                             return Boolean;
   --  Test whether the No_Window flag is set.

   function Realized_Is_Set (Widget : access Gtk_Widget_Record'Class)
                            return Boolean;
   --  Test whether the Realized flag is set.

   function Mapped_Is_Set (Widget : access Gtk_Widget_Record'Class)
                          return Boolean;
   --  Test whether the Mapped flag is set.

   function Visible_Is_Set (Widget : access Gtk_Widget_Record'Class)
                           return Boolean;
   --  Test whether the Visible flag is set.

   function Drawable_Is_Set (Widget : access Gtk_Widget_Record'Class)
                            return Boolean;
   --  True if the widget is both visible and mapped.
   --  In other words, if it does appear on the screen.

   function Is_Sensitive (Widget : access Gtk_Widget_Record'Class)
                             return Boolean;
   --  Test whether the widget is Sensitive.

   function Can_Focus_Is_Set (Widget : access Gtk_Widget_Record'Class)
                             return Boolean;
   --  Test whether the Can_Focus flag is set.

   function Has_Focus_Is_Set (Widget : access Gtk_Widget_Record'Class)
                             return Boolean;
   --  Test whether the Has_Focus flag is set.

   function Has_Default_Is_Set (Widget : access Gtk_Widget_Record'Class)
                               return Boolean;
   --  Test whether the Has_Default flag is set.

   function Has_Grab_Is_Set (Widget : access Gtk_Widget_Record'Class)
                            return Boolean;
   --  Test whether the Has_Grab flag is set.

   function Rc_Style_Is_Set (Widget : access Gtk_Widget_Record'Class)
                            return Boolean;
   --  Test whether the Rc_Style flag is set.

   ----------------------------
   -- Support for GATE/DGATE --
   ----------------------------

   procedure Generate (N      : in Node_Ptr;
                       File   : in File_Type);
   --  Gate internal function

   procedure Generate (Widget : in out Object.Gtk_Object; N : in Node_Ptr);
   --  Dgate internal function

   --------------------------------------
   -- Definitions for lists of widgets --
   --------------------------------------

   --  <doc_ignore>

   function Convert (W : in Gtk_Widget) return System.Address;
   function Convert (W : System.Address) return Gtk_Widget;
   package Widget_List is new Glib.Glist.Generic_List (Gtk_Widget);
   package Widget_SList is new Glib.GSlist.Generic_SList (Gtk_Widget);

   --  </doc_ignore>

   -------------
   -- Signals --
   -------------

   --  <signals>
   --  The following new signals are defined for this widget:
   --
   --  - "show"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class);
   --
   --    Emitted when a widget is to be shown (see explanation for the Show
   --    subprogam). This schedules the widget to be displayed on the screen,
   --    and if this is a toplevel widget it actually appears on the screen
   --    and all its children that have ben shown.
   --
   --  - "hide"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class);
   --
   --    Emitted when a widget is to be hidden (see explanation for the Hide
   --    subprogram). Hides the widget from the screen, and if its parent is
   --    shown, the widget will not appear on the screen again.
   --
   --  - "map"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class);
   --
   --    Emitted when a widget is mapped on the screen (the default handler
   --    simply emits the "show" signal).
   --
   --  - "unmap"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class);
   --
   --    Emitted when a widget needs to be unmapped on the screen (the default
   --    handler simply emits the "hide" signal).
   --
   --  - "realize"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class);
   --
   --    Emitted when a widget is realized. The default handler creates the
   --    Gdk window associated with the widget, and its ancestors.
   --
   --  - "unrealize"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class);
   --
   --    Emitted when a widget is unrealized. The default handler destroys the
   --    Gdk windows of the widget and all its children.
   --
   --  - "draw"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class;
   --                       Area   : Gdk.Rectangle.Gdk_Rectangle);
   --
   --    Emitted when a widget needs to be drawn. The default handler emits
   --    the "expose" event.
   --
   --  - "draw_focus"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class);
   --
   --    Emitted when a widget needs to be drawn and it has the focus. Some
   --    widgets might want to provide visual clues that they have the focus,
   --    like a black border. This is never called if the widget can not have
   --    the focus (ie the "Can_Focus" flag is unset).
   --
   --  - "draw_default"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class);
   --
   --    Emitted when a widget needs to be drawn and it does not have the
   --    focus. This is never called if the widget can not have the focus
   --    (ie the "Can_Focus" flag is unset).
   --
   --  - "size_request"
   --    procedure Handler (Widget      : access Gtk_Widget_Record'Class;
   --                       Requisition : access Gtk_Requisition);
   --
   --    Should return (in Requisition) the ideal size the widget would like to
   --    have. It is not sure this is the size that will be assigned to it,
   --    since it depends on the size of its parent).
   --
   --  - "size_allocate"
   --    procedure Handler (Widget     : access Gtk_Widget_Record'Class;
   --                       Allocation : Gtk_Allocation);
   --
   --    A size and position were assigned to the widget. This is called every
   --    time the size of the widget changes.
   --    The default handler takes care of resizing and moving the widget.
   --
   --  - "state_changed"
   --    procedure Handler (Widget         : access Gtk_Widget_Record'Class;
   --                       Previous_State : Gtk.Enums.Gtk_State_Type);
   --
   --    The state of the widget has changed.
   --
   --  - "parent_set"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class;
   --                       Previous_Parent : access Gtk_Widget_Record'Class);
   --
   --    A new parent has been set for the widget. The previous parent is
   --    given in arguments (if there was none,
   --    Gdk.Is_Created (Previous_Parent) returns False).
   --
   --  - "style_set"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class);
   --                       Previous_Style : Gtk.Style.Gtk_Style);
   --
   --    The widget's style has been changed (this is not call when some
   --    settings in the style are changed, only when the style itself is
   --    completly changed with a call to Set_Style or Set_Rc_Style).
   --
   --  - "add_accelerator"
   --
   --  ???
   --
   --  - "remove_accelerator"
   --
   --  ???
   --
   --  - "grab_focus"
   --    procedure Handler (Widget : access Gtk_Widget_Record'Class);
   --
   --    The widget has got the focus, ie will now get the keyboard events
   --    sent to a window. This is only called if the "Can_Focus" flag is
   --    set. The "Has_Focus" flag might not be set when this signal is
   --    emitted.
   --
   --  - "event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event)
   --                     return Boolean;
   --
   --    Some event was sent to the widget. This covers all the cases
   --    below, and acts as a general handler. This is called in addition to
   --    the relevant specific handler below.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "button_press_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Button)
   --                     return Boolean;
   --
   --    A button was pressed while the pointer was inside the widget.
   --    To get this signal, some widgets by have to use the Set_Events
   --    subprogram first to get this event.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "button_release_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Button)
   --                     return Boolean;
   --
   --    A button was released while the pointer was inside the widget.
   --    Note that in some cases (Gtk_Buttons for instance), another "clicked"
   --    signal could be emitted). This "button_release_event" should mainly
   --    be used for widgets that don't already have specific signals to cover
   --    that case (Gtk_Drawing_Area for instance).
   --
   --    To get this signal, some widgets by have to use the Set_Events
   --    subprogram first to get this event.
   --
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "motion_notify_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Motion)
   --                     return Boolean;
   --
   --    The pointer has moved while remaining inside the widget.
   --    The Set_Events subprogram has to be called first to get this event.
   --
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "delete_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event)
   --                     return Boolean;
   --
   --    The user has clicked on the "close" button in the window's frame
   --    (the button that is automatically set by the window manager). If the
   --    handler returns False, the widget will be destroyed (and the window
   --    closed), but if the handler returns True, nothing will be done.
   --    This is a good way to prevent the user from closing your application's
   --    window if there should be some clean ups first (like saving the
   --    document).
   --
   --  - "destroy_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event)
   --                     return Boolean;
   --
   --    ??? This signal is apparently never emitted by gtk+
   --
   --  - "expose_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Expose)
   --                     return Boolean;
   --
   --    The widget needs to be partly redrawn. The exact area to redraw is
   --    found in Event. For some widgets, you should rather connect to the
   --    "draw" signal. Howether, for instance for Gtk_Drawing_Area widgets,
   --    you have to use this, after setting the correct event mask with
   --    Set_Events.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "key_press_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Key)
   --                     return Boolean;
   --
   --    A key has been pressed while Widget had the focus. Note that some
   --    widgets like Gtk_Editable provide some higher-level signals to handle
   --    this.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "key_release_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Key)
   --                     return Boolean;
   --
   --    A key has been released while Widget had the focus.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "enter_notify_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Crossing)
   --                     return Boolean;
   --
   --    The pointer has just entered the widget. If the "Can_Focus" flag is
   --    set, Widget will gain the focus, and the widget might be drawn
   --    differently.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "leave_notify_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Crossing)
   --                     return Boolean;
   --
   --    The pointer has just leaved the widget. If the "Can_Focus" flag is
   --    set, Widget will gain the focus, and the widget might be drawn
   --    differently.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "configure_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Configure)
   --                     return Boolean;
   --
   --    Some configuration of the window has changed (it has been
   --    moved or resized).
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "focus_in_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Focus)
   --                     return Boolean;
   --
   --    The widget has just gained the focus.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "focus_out_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Focus)
   --                     return Boolean;
   --
   --    The widget has just lost the focus.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "map_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event)
   --                     return Boolean;
   --
   --    The widget has just been mapped. This is different from the "map"
   --    signal, which is called *before* the widget is actually mapped.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "unmap_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event)
   --                     return Boolean;
   --
   --    The widget has just been unmapped. This is different from the "unmap"
   --    signal, which is called *before* the widget is actually unmapped.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "property_notify_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Property)
   --                     return Boolean;
   --
   --    ???
   --
   --  - "selection_clear_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Selection)
   --                     return Boolean;
   --
   --    ???
   --
   --  - "selection_request_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Selection)
   --                     return Boolean;
   --
   --    ???
   --
   --  - "selection_notify_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Selection)
   --                     return Boolean;
   --
   --    ???
   --
   --  - "selection_received"
   --
   --    ???
   --
   --  - "selection_get"
   --
   --    ???
   --
   --  - "proximity_in_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Proximity)
   --                     return Boolean;
   --
   --    Used for special input devices. See the description of
   --    Gdk.Event.Gdk_Event_Proximity.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "proximity_out_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Proximity)
   --                     return Boolean;
   --
   --    Used for special input devices. See the description of
   --    Gdk.Event.Gdk_Event_Proximity.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "drag_leave"
   --  - "drag_begin"
   --  - "drag_end"
   --  - "drag_data_delete"
   --  - "drag_motion"
   --  - "drag_drop"
   --  - "drag_data_get"
   --  - "drag_data_received"
   --
   --  - "visibility_notify_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event_Visibility)
   --                     return Boolean;
   --
   --    The visibility state of the widget has changed (partially visible,
   --    fully visible, ...). You might want to use the "expose" signal
   --    instead.
   --    If the handler returns False, the event might be pass to the parent
   --    of widget (if no other handler of widget has returned True).
   --
   --  - "client_event"
   --
   --    ???
   --
   --  - "no_expose_event"
   --    function Handler (Widget : access Gtk_Widget_Record'Class;
   --                      Event  : Gdk.Event.Gdk_Event)
   --                     return Boolean;
   --
   --    ???
   --
   --  </signals>
private

   type Gtk_Widget_Record is new Object.Gtk_Object_Record with null record;

   pragma Import (C, Pop_Colormap, "gtk_widget_pop_colormap");
   pragma Import (C, Pop_Visual, "gtk_widget_pop_visual");
   pragma Import (C, Get_Type, "gtk_widget_get_type");
   pragma Inline (Toplevel_Is_Set);
   pragma Inline (No_Window_Is_Set);
   pragma Inline (Realized_Is_Set);
   pragma Inline (Mapped_Is_Set);
   pragma Inline (Visible_Is_Set);
   pragma Inline (Drawable_Is_Set);
   pragma Inline (Is_Sensitive);
   pragma Inline (Can_Focus_Is_Set);
   pragma Inline (Has_Focus_Is_Set);
   pragma Inline (Has_Default_Is_Set);
   pragma Inline (Has_Grab_Is_Set);
   pragma Inline (Rc_Style_Is_Set);
end Gtk.Widget;

--  Functions that have no Ada equivalent:
--  - gtk_widget_new
--  - gtk_widget_newv
--  - gtk_widget_get
--  - gtk_widget_getv
--  - gtk_widget_set
--  - gtk_widget_setv
--  - gtk_widget_set_parent_window  <= mainly internal
--  - gtk_widget_get_parent_window  <= mainly internal
--  - gtk_widget_hide_on_delete     <= used as callback
--  - gtk_widget_set_composite_name
--  - gtk_widget_get_composite_name
--  - gtk_widget_push_composite_child
--  - gtk_widget_pop_composite_child
--  - gtk_widget_path
--  - gtk_widget_class_path
