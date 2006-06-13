-----------------------------------------------------------------------
--              GtkAda - Ada95 binding for Gtk+/Gnome                --
--                                                                   --
--                Copyright (C) 2006 AdaCore                         --
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
--  This package provides an interface to the type system in Glib. These types
--  provide an object-oriented framework (through inheritance and interfaces),
--  as well as reference-counting, signals and properties on these types.
--
--  See the other glib packages for more subprograms to manipulate these types.
--  In particular, Glib.Properties describes the properties system, that
--  provide the base for dynamic introspection. See also Glib itself, which
--  contains several general subprograms, and Glib.Object that provides the
--  root object for any type hierarchy based on glib.
--  </description>
--  <group>Glib, the general-purpose library</group>

with Glib.Object;
with System;

package Glib.Types is

   ----------------
   -- Interfaces --
   ----------------
   --  Interfaces are similar, in concept, to those found in Ada 2005 or in
   --  Java. They define a set of subprograms that any type implementing the
   --  interface must also define. They are different from standard inheritance
   --  since no implementation of these subprograms can be provided in the
   --  interface itself.
   --
   --  Whereas an object can only derive from one other object, it can
   --  implement any number of interfaces.
   --
   --  Some of the standard gtk+ objects implement interfaces. In this case,
   --  their Ada package contains one or more functions to convert from the
   --  object itself to the interface, for instance:
   --
   --      package Implements_Cell_Layout is new Glib.Types.Implements (...);
   --      function "+" (...) renames Implements_Cell_Layout.To_Interface;
   --      function "-" (...) renames Implements_Cell_Layout.To_Object;
   --
   --  The two unary operators "+" and "-" can be used to convert to and from
   --  the interface, for instance calling:
   --        View : Gtk_Cell_View;
   --        Gtk.Cell_Layout.Pack_Start (+View, Cell, Expand);

   type GType_Interface is private;

   --  <doc_ignore>
   generic
      type Interface_Type is new GType_Interface;
      type Object_Type_Record is new Glib.Object.GObject_Record with private;
      type Object_Type is access all Object_Type_Record'Class;
   package Implements is
      function To_Object (Interf : Interface_Type) return Object_Type;
      function To_Interface
        (Object : access Object_Type_Record'Class) return Interface_Type;
      --  These subprograms can be used to convert from an object to one of
      --  the interfaces it implements, and from an interface to the object
      --  itself.
   end Implements;
   --  </doc_ignore>

   function To_Object
     (Interf : GType_Interface) return Glib.Object.GObject;
   --  Return the object that the interface represents. This is slightly
   --  different from using Implements.To_Object, in the case when the object
   --  wasn't created through Ada. In such a case, GtkAda needs to create an
   --  Ada wrapper around the object, and will choose a different tagged type:
   --     - Implements.To_Object creates a tagged type of type Object_Type.
   --     - This function creates a GObject, which you cannot cast easily
   --       to some other tagged type afterward.
   --  Both behave the same when the object was created from Ada.

private
   type GType_Interface is new System.Address;
end Glib.Types;