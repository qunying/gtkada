------------------------------------------------------------------------------
--                                                                          --
--      Copyright (C) 1998-2000 E. Briot, J. Brobecker and A. Charlet       --
--                     Copyright (C) 2000-2012, AdaCore                     --
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

pragma Style_Checks (Off);
pragma Warnings (Off, "*is already use-visible*");
with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Glib.Type_Conversion_Hooks; use Glib.Type_Conversion_Hooks;
with Gtkada.Bindings;            use Gtkada.Bindings;

package body Gtk.Action_Group is

   function Convert (R : Gtk.Action.Gtk_Action) return System.Address is
   begin
      return Get_Object (R);
   end Convert;

   function Convert (R : System.Address) return Gtk.Action.Gtk_Action is
      Stub : Gtk.Action.Gtk_Action_Record;begin
         return Gtk.Action.Gtk_Action (Glib.Object.Get_User_Data (R, Stub));
      end Convert;

   procedure Local_Radio_Action_Callback
     (Group, Current, User_Data : System.Address);
   pragma Convention (C, Local_Radio_Action_Callback);
   --  Local proxy for Radio_Action_Callback

   procedure Local_Radio_Action_Destroy
     (Data : in out System.Address);
   pragma Convention (C, Local_Radio_Action_Destroy);
   --  Local proxy for the Destroy notify for Radio_Action

   type Local_Radio_Action_User_Data is record
      Callback  : Radio_Action_Callback;
      User_Data : System.Address;
      Destroy   : G_Destroy_Notify_Address;
   end record;
   type Local_Radio_Action_User_Data_Access is
      access Local_Radio_Action_User_Data;

      function Convert is new Ada.Unchecked_Conversion
        (System.Address, Local_Radio_Action_User_Data_Access);
      function Convert is new Ada.Unchecked_Conversion
        (Local_Radio_Action_User_Data_Access, System.Address);
      procedure Unchecked_Free is new Ada.Unchecked_Deallocation
        (Local_Radio_Action_User_Data, Local_Radio_Action_User_Data_Access);

      procedure Local_Radio_Action_Callback
        (Group, Current, User_Data : System.Address)
      is
         Data : constant Local_Radio_Action_User_Data_Access :=
         Convert (User_Data);
         Stub : Gtk_Action_Record;
         G : constant Gtk_Action := Gtk_Action (Get_User_Data (Group, Stub));
         C : constant Gtk_Action := Gtk_Action (Get_User_Data (Current, Stub));
      begin
         Data.Callback (G, C, Data.User_Data);
      end Local_Radio_Action_Callback;

      procedure Local_Radio_Action_Destroy
        (Data : in out System.Address)
      is
         D : Local_Radio_Action_User_Data_Access := Convert (Data);
      begin
         D.Destroy (D.User_Data);
         Unchecked_Free (D);
      end Local_Radio_Action_Destroy;

      function Create
        (Name        : String;
         Label       : String := "";
         Stock_Id    : String := "";
         Accelerator : String := "";
         Tooltip     : String := "";
         Callback    : Action_Callback := null) return Action_Entry is
      begin
         return (Name        => String_Or_Null (Name),
            Label       => String_Or_Null (Label),
            Stock_Id    => String_Or_Null (Stock_Id),
            Accelerator => String_Or_Null (Accelerator),
            Tooltip     => String_Or_Null (Tooltip),
            Callback    => Callback);
      end Create;

      function Create
        (Name        : String;
         Label       : String := "";
         Stock_Id    : String := "";
         Accelerator : String := "";
         Tooltip     : String := "";
         Callback    : Action_Callback := null;
         Is_Active   : Boolean := True) return Toggle_Action_Entry is
      begin
         return (Name        => String_Or_Null (Name),
            Label       => String_Or_Null (Label),
            Stock_Id    => String_Or_Null (Stock_Id),
            Accelerator => String_Or_Null (Accelerator),
            Tooltip     => String_Or_Null (Tooltip),
            Callback    => Callback,
            Is_Active   => Boolean'Pos (Is_Active));
      end Create;

      function Create
        (Name        : String;
         Label       : String;
         Stock_Id    : String := "";
         Accelerator : String := "";
         Tooltip     : String := "";
         Value       : Glib.Gint) return Radio_Action_Entry is
      begin
         return (Name        => String_Or_Null (Name),
            Label       => String_Or_Null (Label),
            Stock_Id    => String_Or_Null (Stock_Id),
            Accelerator => String_Or_Null (Accelerator),
            Tooltip     => String_Or_Null (Tooltip),
            Value       => Value);
      end Create;

      procedure Free (Action  : in out Action_Entry) is
      begin
         Free (Action.Name);
         Free (Action.Label);
         Free (Action.Stock_Id);
         Free (Action.Accelerator);
         Free (Action.Tooltip);
      end Free;

      procedure Free (Actions : in out Action_Entry_Array) is
      begin
         for A in Actions'Range loop
            Free (Actions (A));
         end loop;
      end Free;

      procedure Free (Action  : in out Radio_Action_Entry) is
      begin
         Free (Action.Name);
         Free (Action.Label);
         Free (Action.Stock_Id);
         Free (Action.Accelerator);
         Free (Action.Tooltip);
      end Free;

      procedure Free (Actions : in out Radio_Action_Entry_Array) is
      begin
         for A in Actions'Range loop
            Free (Actions (A));
         end loop;
      end Free;

      procedure Free (Action  : in out Toggle_Action_Entry) is
      begin
         Free (Action.Name);
         Free (Action.Label);
         Free (Action.Stock_Id);
         Free (Action.Accelerator);
         Free (Action.Tooltip);
      end Free;

      procedure Free (Actions : in out Toggle_Action_Entry_Array) is
      begin
         for A in Actions'Range loop
            Free (Actions (A));
         end loop;
      end Free;

      procedure Add_Actions
        (Action_Group : access Gtk_Action_Group_Record;
         Entries      : Action_Entry_Array;
         User_Data    : System.Address := System.Null_Address;
         Destroy      : Glib.G_Destroy_Notify_Address := null)
      is
         procedure Internal
           (Action_Group : System.Address;
            Entries      : System.Address;
            N_Entries    : Guint;
            User_Data    : System.Address;
            Destroy      : G_Destroy_Notify_Address);
         pragma Import (C, Internal, "gtk_action_group_add_actions_full");
      begin
         Internal (Get_Object (Action_Group),
            Entries (Entries'First)'Address,
            Entries'Length,
            User_Data, Destroy);
      end Add_Actions;

      procedure Add_Radio_Actions
        (Action_Group : access Gtk_Action_Group_Record;
         Entries      : Radio_Action_Entry_Array;
         Value        : Glib.Gint;
         On_Change    : Radio_Action_Callback;
         User_Data    : System.Address := System.Null_Address;
         Destroy      : Glib.G_Destroy_Notify_Address := null)
      is
         procedure Internal
           (Action_Group : System.Address;
            Entries      : System.Address;
            N_Entries    : Guint;
            Value        : Gint;
            On_Change    : System.Address;
            User_Data    : System.Address;
            Destroy      : System.Address);
         pragma Import (C, Internal, "gtk_action_group_add_radio_actions_full");
         Data : constant Local_Radio_Action_User_Data_Access :=
         new Local_Radio_Action_User_Data'
        (Callback  => On_Change,
         User_Data => User_Data,
         Destroy   => Destroy);
   begin
      Internal (Get_Object (Action_Group),
         Entries (Entries'First)'Address, Entries'Length,
         Value,
         Local_Radio_Action_Callback'Address,
         Convert (Data),
         Local_Radio_Action_Destroy'Address);
   end Add_Radio_Actions;

   procedure Add_Toggle_Actions
     (Action_Group : access Gtk_Action_Group_Record;
      Entries      : Toggle_Action_Entry_Array;
      User_Data    : System.Address := System.Null_Address;
      Destroy      : G_Destroy_Notify_Address := null)
   is
      procedure Internal
        (Action_Group : System.Address;
         Entries      : System.Address;
         N_Entries    : Guint;
         User_Data    : System.Address;
         Destroy      : G_Destroy_Notify_Address);
      pragma Import (C, Internal, "gtk_action_group_add_toggle_actions_full");
   begin
      Internal (Get_Object (Action_Group),
         Entries (Entries'First)'Address, Entries'Length, User_Data,
         Destroy);
   end Add_Toggle_Actions;

   function To_Gtk_Translate_Func is new Ada.Unchecked_Conversion
     (System.Address, Gtk_Translate_Func);

   function To_Address is new Ada.Unchecked_Conversion
     (Gtk_Translate_Func, System.Address);

   procedure C_Gtk_Action_Group_Set_Translate_Func
      (Action_Group : System.Address;
       Func         : System.Address;
       Data         : System.Address;
       Notify       : Glib.G_Destroy_Notify_Address);
   pragma Import (C, C_Gtk_Action_Group_Set_Translate_Func, "gtk_action_group_set_translate_func");
   --  Sets a function to be used for translating the Label and Tooltip of
   --  Gtk_Action_Group_Entry<!-- -->s added by gtk_action_group_add_actions.
   --  If you're using gettext, it is enough to set the translation domain
   --  with Gtk.Action_Group.Set_Translation_Domain.
   --  Since: gtk+ 2.4
   --  "func": a Gtk_Translate_Func
   --  "data": data to be passed to Func and Notify
   --  "notify": a Glib.G_Destroy_Notify_Address function to be called when
   --  Action_Group is destroyed and when the translation function is changed
   --  again

   function Internal_Gtk_Translate_Func
      (Path      : Interfaces.C.Strings.chars_ptr;
       Func_Data : System.Address) return Interfaces.C.Strings.chars_ptr;
   pragma Convention (C, Internal_Gtk_Translate_Func);

   ---------------------------------
   -- Internal_Gtk_Translate_Func --
   ---------------------------------

   function Internal_Gtk_Translate_Func
      (Path      : Interfaces.C.Strings.chars_ptr;
       Func_Data : System.Address) return Interfaces.C.Strings.chars_ptr
   is
      Func : constant Gtk_Translate_Func := To_Gtk_Translate_Func (Func_Data);
   begin
      return New_String (Func (Gtkada.Bindings.Value_Allowing_Null (Path)));
   end Internal_Gtk_Translate_Func;

   package Type_Conversion_Gtk_Action_Group is new Glib.Type_Conversion_Hooks.Hook_Registrator
     (Get_Type'Access, Gtk_Action_Group_Record);
   pragma Unreferenced (Type_Conversion_Gtk_Action_Group);

   -------------
   -- Gtk_New --
   -------------

   procedure Gtk_New
      (Action_Group : out Gtk_Action_Group;
       Name         : UTF8_String)
   is
   begin
      Action_Group := new Gtk_Action_Group_Record;
      Gtk.Action_Group.Initialize (Action_Group, Name);
   end Gtk_New;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
      (Action_Group : not null access Gtk_Action_Group_Record'Class;
       Name         : UTF8_String)
   is
      function Internal
         (Name : Interfaces.C.Strings.chars_ptr) return System.Address;
      pragma Import (C, Internal, "gtk_action_group_new");
      Tmp_Name   : Interfaces.C.Strings.chars_ptr := New_String (Name);
      Tmp_Return : System.Address;
   begin
      Tmp_Return := Internal (Tmp_Name);
      Free (Tmp_Name);
      Set_Object (Action_Group, Tmp_Return);
   end Initialize;

   ----------------
   -- Add_Action --
   ----------------

   procedure Add_Action
      (Action_Group : not null access Gtk_Action_Group_Record;
       Action       : not null access Gtk.Action.Gtk_Action_Record'Class)
   is
      procedure Internal
         (Action_Group : System.Address;
          Action       : System.Address);
      pragma Import (C, Internal, "gtk_action_group_add_action");
   begin
      Internal (Get_Object (Action_Group), Get_Object (Action));
   end Add_Action;

   ---------------------------
   -- Add_Action_With_Accel --
   ---------------------------

   procedure Add_Action_With_Accel
      (Action_Group : not null access Gtk_Action_Group_Record;
       Action       : not null access Gtk.Action.Gtk_Action_Record'Class;
       Accelerator  : UTF8_String := "")
   is
      procedure Internal
         (Action_Group : System.Address;
          Action       : System.Address;
          Accelerator  : Interfaces.C.Strings.chars_ptr);
      pragma Import (C, Internal, "gtk_action_group_add_action_with_accel");
      Tmp_Accelerator : Interfaces.C.Strings.chars_ptr;
   begin
      if Accelerator = "" then
         Tmp_Accelerator := Interfaces.C.Strings.Null_Ptr;
      else
         Tmp_Accelerator := New_String (Accelerator);
      end if;
      Internal (Get_Object (Action_Group), Get_Object (Action), Tmp_Accelerator);
      Free (Tmp_Accelerator);
   end Add_Action_With_Accel;

   ----------------
   -- Get_Action --
   ----------------

   function Get_Action
      (Action_Group : not null access Gtk_Action_Group_Record;
       Action_Name  : UTF8_String) return Gtk.Action.Gtk_Action
   is
      function Internal
         (Action_Group : System.Address;
          Action_Name  : Interfaces.C.Strings.chars_ptr)
          return System.Address;
      pragma Import (C, Internal, "gtk_action_group_get_action");
      Tmp_Action_Name : Interfaces.C.Strings.chars_ptr := New_String (Action_Name);
      Stub_Gtk_Action : Gtk.Action.Gtk_Action_Record;
      Tmp_Return      : System.Address;
   begin
      Tmp_Return := Internal (Get_Object (Action_Group), Tmp_Action_Name);
      Free (Tmp_Action_Name);
      return Gtk.Action.Gtk_Action (Get_User_Data (Tmp_Return, Stub_Gtk_Action));
   end Get_Action;

   --------------
   -- Get_Name --
   --------------

   function Get_Name
      (Action_Group : not null access Gtk_Action_Group_Record)
       return UTF8_String
   is
      function Internal
         (Action_Group : System.Address)
          return Interfaces.C.Strings.chars_ptr;
      pragma Import (C, Internal, "gtk_action_group_get_name");
   begin
      return Gtkada.Bindings.Value_Allowing_Null (Internal (Get_Object (Action_Group)));
   end Get_Name;

   -------------------
   -- Get_Sensitive --
   -------------------

   function Get_Sensitive
      (Action_Group : not null access Gtk_Action_Group_Record)
       return Boolean
   is
      function Internal (Action_Group : System.Address) return Integer;
      pragma Import (C, Internal, "gtk_action_group_get_sensitive");
   begin
      return Boolean'Val (Internal (Get_Object (Action_Group)));
   end Get_Sensitive;

   -----------------
   -- Get_Visible --
   -----------------

   function Get_Visible
      (Action_Group : not null access Gtk_Action_Group_Record)
       return Boolean
   is
      function Internal (Action_Group : System.Address) return Integer;
      pragma Import (C, Internal, "gtk_action_group_get_visible");
   begin
      return Boolean'Val (Internal (Get_Object (Action_Group)));
   end Get_Visible;

   ------------------
   -- List_Actions --
   ------------------

   function List_Actions
      (Action_Group : not null access Gtk_Action_Group_Record)
       return Action_List.Glist
   is
      function Internal
         (Action_Group : System.Address) return System.Address;
      pragma Import (C, Internal, "gtk_action_group_list_actions");
      Tmp_Return : Action_List.Glist;
   begin
      Gtk.Action_Group.Action_List.Set_Object (Tmp_Return, Internal (Get_Object (Action_Group)));
      return Tmp_Return;
   end List_Actions;

   -------------------
   -- Remove_Action --
   -------------------

   procedure Remove_Action
      (Action_Group : not null access Gtk_Action_Group_Record;
       Action       : not null access Gtk.Action.Gtk_Action_Record'Class)
   is
      procedure Internal
         (Action_Group : System.Address;
          Action       : System.Address);
      pragma Import (C, Internal, "gtk_action_group_remove_action");
   begin
      Internal (Get_Object (Action_Group), Get_Object (Action));
   end Remove_Action;

   -------------------
   -- Set_Sensitive --
   -------------------

   procedure Set_Sensitive
      (Action_Group : not null access Gtk_Action_Group_Record;
       Sensitive    : Boolean)
   is
      procedure Internal
         (Action_Group : System.Address;
          Sensitive    : Integer);
      pragma Import (C, Internal, "gtk_action_group_set_sensitive");
   begin
      Internal (Get_Object (Action_Group), Boolean'Pos (Sensitive));
   end Set_Sensitive;

   ------------------------
   -- Set_Translate_Func --
   ------------------------

   procedure Set_Translate_Func
      (Action_Group : not null access Gtk_Action_Group_Record;
       Func         : Gtk_Translate_Func;
       Notify       : Glib.G_Destroy_Notify_Address)
   is
   begin
      if Func = null then
         C_Gtk_Action_Group_Set_Translate_Func (Get_Object (Action_Group), System.Null_Address, System.Null_Address, Notify);
      else
         C_Gtk_Action_Group_Set_Translate_Func (Get_Object (Action_Group), Internal_Gtk_Translate_Func'Address, To_Address (Func), Notify);
      end if;
   end Set_Translate_Func;

   package body Set_Translate_Func_User_Data is

      package Users is new Glib.Object.User_Data_Closure
        (User_Data_Type, Destroy);

      function To_Gtk_Translate_Func is new Ada.Unchecked_Conversion
        (System.Address, Gtk_Translate_Func);

      function To_Address is new Ada.Unchecked_Conversion
        (Gtk_Translate_Func, System.Address);

      function Internal_Cb
         (Path      : Interfaces.C.Strings.chars_ptr;
          Func_Data : System.Address) return Interfaces.C.Strings.chars_ptr;
      pragma Convention (C, Internal_Cb);

      -----------------
      -- Internal_Cb --
      -----------------

      function Internal_Cb
         (Path      : Interfaces.C.Strings.chars_ptr;
          Func_Data : System.Address) return Interfaces.C.Strings.chars_ptr
      is
         D : constant Users.Internal_Data_Access := Users.Convert (Func_Data);
      begin
         return New_String (To_Gtk_Translate_Func (D.Func) (Gtkada.Bindings.Value_Allowing_Null (Path), D.Data.all));
      end Internal_Cb;

      ------------------------
      -- Set_Translate_Func --
      ------------------------

      procedure Set_Translate_Func
         (Action_Group : not null access Gtk.Action_Group.Gtk_Action_Group_Record'Class;
          Func         : Gtk_Translate_Func;
          Data         : User_Data_Type;
          Notify       : Glib.G_Destroy_Notify_Address)
      is
      begin
         if Func = null then
            C_Gtk_Action_Group_Set_Translate_Func (Get_Object (Action_Group), System.Null_Address, System.Null_Address, Notify);
         else
            C_Gtk_Action_Group_Set_Translate_Func (Get_Object (Action_Group), Internal_Cb'Address, Users.Build (To_Address (Func), Data), Notify);
         end if;
      end Set_Translate_Func;

   end Set_Translate_Func_User_Data;

   ----------------------------
   -- Set_Translation_Domain --
   ----------------------------

   procedure Set_Translation_Domain
      (Action_Group : not null access Gtk_Action_Group_Record;
       Domain       : UTF8_String)
   is
      procedure Internal
         (Action_Group : System.Address;
          Domain       : Interfaces.C.Strings.chars_ptr);
      pragma Import (C, Internal, "gtk_action_group_set_translation_domain");
      Tmp_Domain : Interfaces.C.Strings.chars_ptr := New_String (Domain);
   begin
      Internal (Get_Object (Action_Group), Tmp_Domain);
      Free (Tmp_Domain);
   end Set_Translation_Domain;

   -----------------
   -- Set_Visible --
   -----------------

   procedure Set_Visible
      (Action_Group : not null access Gtk_Action_Group_Record;
       Visible      : Boolean)
   is
      procedure Internal (Action_Group : System.Address; Visible : Integer);
      pragma Import (C, Internal, "gtk_action_group_set_visible");
   begin
      Internal (Get_Object (Action_Group), Boolean'Pos (Visible));
   end Set_Visible;

   ----------------------
   -- Translate_String --
   ----------------------

   function Translate_String
      (Action_Group : not null access Gtk_Action_Group_Record;
       String       : UTF8_String) return UTF8_String
   is
      function Internal
         (Action_Group : System.Address;
          String       : Interfaces.C.Strings.chars_ptr)
          return Interfaces.C.Strings.chars_ptr;
      pragma Import (C, Internal, "gtk_action_group_translate_string");
      Tmp_String : Interfaces.C.Strings.chars_ptr := New_String (String);
      Tmp_Return : Interfaces.C.Strings.chars_ptr;
   begin
      Tmp_Return := Internal (Get_Object (Action_Group), Tmp_String);
      Free (Tmp_String);
      return Gtkada.Bindings.Value_Allowing_Null (Tmp_Return);
   end Translate_String;

end Gtk.Action_Group;