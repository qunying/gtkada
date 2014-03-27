------------------------------------------------------------------------------
--                  GtkAda - Ada95 binding for Gtk+/Gnome                   --
--                                                                          --
--      Copyright (C) 1998-2000 E. Briot, J. Brobecker and A. Charlet       --
--                     Copyright (C) 1998-2014, AdaCore                     --
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

with Ada.Numerics.Generic_Elementary_Functions; use Ada.Numerics;
with Ada.Unchecked_Deallocation;
with Gtkada.Canvas_View.Astar;      use Gtkada.Canvas_View.Astar;
with Gtkada.Canvas_View.Objects;    use Gtkada.Canvas_View.Objects;
with Gtkada.Style;                  use Gtkada.Style;

package body Gtkada.Canvas_View.Links is

   package Gdouble_Elementary_Functions is new
     Ada.Numerics.Generic_Elementary_Functions (Gdouble);
   use Gdouble_Elementary_Functions;

   type End_Info is record
      Box      : Model_Rectangle;
      --  The bounding box for the end element of the link

      Toplevel : Model_Rectangle;
      --  The bounding box for the toplevel element that contains the source
      --  element.

      P        : Model_Point;
      --  Anchor points for each end of the link, on the toplevel box
   end record;

   type Anchors is record
      From, To : End_Info;
   end record;
   --  Various dimensions computed for the layout of links.
   --  It contains the start and end points for the link, as well as the
   --  bounding boxes.

   procedure Unchecked_Free is new Ada.Unchecked_Deallocation
     (Item_Point_Array, Item_Point_Array_Access);

   procedure Sort (Arr : in out Gdouble_Array);
   --  Sort the array

   function Compute_Anchors
     (Self : not null access Canvas_Link_Record'Class) return Anchors;
   --  Compute the start and end point of the link, depending on the two
   --  objects it links. This makes sure that the link does not start in the
   --  middle of the box.

   procedure Compute_Labels
     (Self   : not null access Canvas_Link_Record'Class;
      Dim    : Anchors);
   --  Compute the position for the end labels and middle label for the link

   procedure Compute_Bounding_Box
     (Self : not null access Canvas_Link_Record'Class);
   --  Compute the bounding box for the link

   type Layout_Matrix is record
      X, Y : Gdouble_Array (1 .. 7);
      Dim  : Anchors;
   end record;
   --  Mapping from integer to double: the double values indicate positions
   --  in the canvas itself. The integer coordinates are used for the A*
   --  algorithm, since we are working on a non-uniform grid.

   function Manhattan_Dist
      (Self : Layout_Matrix; From, To : Coordinate) return Integer;
   function Manhattan_Cost
      (Self : Layout_Matrix; Parent, From, To : Coordinate) return Integer;
   function Next_Point is new Manhattan_Next_Point (Layout_Matrix);
   --  Functions for the A* algorithm.

   --------------------
   -- Manhattan_Dist --
   --------------------

   function Manhattan_Dist
      (Self : Layout_Matrix; From, To : Coordinate) return Integer is
   begin
      return Integer (abs (Self.X (From.X) - Self.X (To.X))
                      + abs (Self.Y (From.Y) - Self.Y (To.Y)));
   end Manhattan_Dist;

   --------------------
   -- Manhattan_Cost --
   --------------------

   function Manhattan_Cost
      (Self : Layout_Matrix; Parent, From, To : Coordinate)
      return Integer is
   begin
      if To.X not in Self.X'Range
        or else To.Y not in Self.Y'Range

        --  If the target is not a valid destination
        or else abs (Self.X (To.X) - Gdouble'Last) < 0.01
        or else abs (Self.Y (To.Y) - Gdouble'Last) < 0.01
      then
         return Not_Traversable;

      elsif Point_In_Rect
          (Self.Dim.From.Toplevel, (Self.X (To.X), Self.Y (To.Y)))
        or else Point_In_Rect
          (Self.Dim.To.Toplevel, (Self.X (To.X), Self.Y (To.Y)))
      then
         return 10_000;   --  very expensive, but not impossible if we have to

      else
         --  A bend is costly
         if abs (Parent.X - From.X) /= abs (From.X - To.X)
           or else abs (Parent.Y - From.Y) /= abs (From.Y - To.Y)
         then
            return 100;
         else
            return 1;
         end if;
      end if;
   end Manhattan_Cost;

   function Astar_Find is new Find_Path
     (User_Data      => Layout_Matrix,
      Heuristic_Cost => Manhattan_Cost,
      Next_Point     => Next_Point,
      Heuristic_Dist => Manhattan_Dist);
   --  An A* algorithm to find the shortest path between two points,
   --  while avoiding overlapping with two boxes specified in the
   --  Layout_Matrix.

   ---------------------
   -- Compute_Anchors --
   ---------------------

   function Compute_Anchors
     (Self : not null access Canvas_Link_Record'Class) return Anchors
   is
      S  : constant Abstract_Item := Self.From;
      ST : Abstract_Item := Gtkada.Canvas_View.Objects.Toplevel (S);
      D  : constant Abstract_Item := Self.To;
      DT : Abstract_Item := Gtkada.Canvas_View.Objects.Toplevel (D);
      P  : Model_Point;
      Result : Anchors;
   begin
      if ST = null then
         ST := S;
      end if;

      if DT = null then
         DT := D;
      end if;

      Result :=
        (From  =>
           (P        => S.Item_To_Model
              (S.Link_Anchor_Point (Self.Anchor_From)),
            Box      => S.Model_Bounding_Box,
            Toplevel => ST.Model_Bounding_Box),
         To    =>
           (P        => D.Item_To_Model
              (D.Link_Anchor_Point (Self.Anchor_To)),
            Box      => D.Model_Bounding_Box,
            Toplevel => DT.Model_Bounding_Box));

      --  Clip the line to the side of the toplevel boxes.

      if Self.Anchor_From.Toplevel_Side = Auto then
         if Self.Waypoints = null then
            P := Result.To.P;
         else
            P := Self.Item_To_Model (Self.Waypoints (Self.Waypoints'First));
         end if;
         Result.From.P := ST.Item_To_Model
           (ST.Clip_Line
              (ST.Model_To_Item (Result.From.P), ST.Model_To_Item (P)));
      end if;

      if Self.Anchor_To.Toplevel_Side = Auto then
         if Self.Waypoints = null then
            P := Result.From.P;
         else
            P := Self.Item_To_Model (Self.Waypoints (Self.Waypoints'Last));
         end if;
         Result.To.P := DT.Item_To_Model
           (DT.Clip_Line
              (DT.Model_To_Item (Result.To.P), DT.Model_To_Item (P)));
      end if;

      return Result;
   end Compute_Anchors;

   --------------------------
   -- Compute_Bounding_Box --
   --------------------------

   procedure Compute_Bounding_Box
     (Self : not null access Canvas_Link_Record'Class)
   is
      P     : constant Point_Array_Access := Self.Points;
      Max_X : Gdouble := P (P'First).X;
      Max_Y : Gdouble := P (P'First).Y;
      X     : Gdouble := Max_X;
      Y     : Gdouble := Max_Y;
   begin
      for P1 in P'First + 1 .. P'Last loop
         X := Gdouble'Min (X, P (P1).X);
         Y := Gdouble'Min (Y, P (P1).Y);
         Max_X := Gdouble'Max (Max_X, P (P1).X);
         Max_Y := Gdouble'Max (Max_Y, P (P1).Y);
      end loop;

      Self.Bounding_Box :=
        (X => X, Y => Y, Width => Max_X - X, Height => Max_Y - Y);
   end Compute_Bounding_Box;

   --------------------
   -- Compute_Labels --
   --------------------

   procedure Compute_Labels
     (Self   : not null access Canvas_Link_Record'Class;
      Dim    : Anchors)
   is
      pragma Unreferenced (Self, Dim);
   begin
      null;
   end Compute_Labels;

   ----------
   -- Sort --
   ----------

   procedure Sort (Arr : in out Gdouble_Array) is
      --  A simple bubble sort
      Switched : Boolean;
      Tmp      : Gdouble;
   begin
      loop
         Switched := False;

         for J in Arr'First .. Arr'Last - 1 loop
            if Arr (J + 1) < Arr (J) then
               Tmp := Arr (J);
               Arr (J) := Arr (J + 1);
               Arr (J + 1) := Tmp;
               Switched := True;
            end if;
         end loop;

         exit when not Switched;
      end loop;
   end Sort;

   ----------------------------------------
   -- Compute_Layout_For_Orthogonal_Link --
   ----------------------------------------

   procedure Compute_Layout_For_Orthogonal_Link
     (Link   : not null access Canvas_Link_Record'Class)
   is
      B : constant Gdouble := 4.0;
      --  Border around each box in which the links should not be displayed.

      Min_Space : constant Gdouble := Link.Style.Get_Line_Width * 3.0;
      --  Minimal space between two boxes to pass a link between them

      Dim : constant Anchors := Compute_Anchors (Link);

      FTX1 : constant Gdouble := Dim.From.Toplevel.X;  --  from-top-x1
      FTX2 : constant Gdouble := FTX1 + Dim.From.Toplevel.Width;
      FTY1 : constant Gdouble := Dim.From.Toplevel.Y;  --  from-top-y1
      FTY2 : constant Gdouble := FTY1 + Dim.From.Toplevel.Height;

      TTX1 : constant Gdouble := Dim.To.Toplevel.X;  --  from-top-x1
      TTX2 : constant Gdouble := TTX1 + Dim.To.Toplevel.Width;
      TTY1 : constant Gdouble := Dim.To.Toplevel.Y;  --  from-top-y1
      TTY2 : constant Gdouble := TTY1 + Dim.To.Toplevel.Height;

      procedure Compute_Sides
        (Anchor : Anchor_Attachment;
         Info   : End_Info;
         P, P2  : out Item_Point);
      --  Compute whether a link should start horizontal or vertical, and
      --  which side it should start on.
      --  (P, P2) is the first segment of an orthogonal link exiting from the
      --  box. P2 is aligned on a grid of size B, so that we can use Astar

      -------------------
      -- Compute_Sides --
      -------------------

      procedure Compute_Sides
        (Anchor : Anchor_Attachment;
         Info   : End_Info;
         P, P2  : out Item_Point)
      is
         Effective_Side : Side_Attachment;
      begin
         case Anchor.Toplevel_Side is
            when Top | Bottom | Right | Left =>
               Effective_Side := Anchor.Toplevel_Side;
            when Auto =>
               if Info.P.X = Info.Toplevel.X then
                  Effective_Side := Left;
               elsif Info.P.Y = Info.Toplevel.Y then
                  Effective_Side := Top;
               elsif Info.P.X = Info.Toplevel.X + Info.Toplevel.Width then
                  Effective_Side := Right;
               else
                  Effective_Side := Bottom;
               end if;
         end case;

         case Effective_Side is
            when Top =>
               P := (Info.Box.X + Info.Box.Width * Anchor.X, Info.Toplevel.Y);
               P2 := (P.X, P.Y - B);
            when Bottom =>
               P := (Info.Box.X + Info.Box.Width * Anchor.X,
                     Info.Toplevel.Y + Info.Toplevel.Height);
               P2 := (P.X, P.Y + B);
            when Right =>
               P := (Info.Toplevel.X + Info.Toplevel.Width,
                     Info.Box.Y + Info.Box.Height * Anchor.Y);
               P2 := (P.X + B, P.Y);
            when Left =>
               P := (Info.Toplevel.X, Info.Box.Y + Info.Box.Height * Anchor.Y);
               P2 := (P.X - B, P.Y);
            when others =>
               null;
         end case;
      end Compute_Sides;

      From, To : Item_Point;
      M      : Item_Point;
      P_From : Item_Point;   --  extending from the From box
      P_To   : Item_Point;   --  extending from the To box
      C1, C2 : Coordinate;
      Matrix : Layout_Matrix;

   begin
      Compute_Sides (Link.Anchor_From, Dim.From, From, P_From);
      Compute_Sides (Link.Anchor_To, Dim.To, To, P_To);

      Unchecked_Free (Link.Points);

      --  We want to find a line that joins P_From to P_To, with the minimum
      --  number of bends. For this, there are in fact three possible X
      --  coordinates for each box (and same for Y):
      --          FTX1 - B, F.X, FTX2 + B
      --                TTX1 - B, T.X, TTX2 + B
      --
      --  When there is enough space between the two boxes, we can replace
      --  the two lines between the items with a single one in the middle.
      --  This gives use 5 or 6 possible X coordinates for vertical segments.
      --  Some of these cannot be used to go all the way down because they
      --  cross one of the two boxes.
      --  Also, P_From and P_To are aligned on that grid, so basically we need
      --  to find a path between two vertices of the grid.

      if FTX2 + Min_Space <= TTX1 then
         M.X := (FTX2 + TTX1) / 2.0;
      elsif TTX2 + Min_Space <= FTX1 then
         M.X := (FTX1 + TTX2) / 2.0;
      else
         M.X := Gdouble'Last;  --  no valid vertical line in between
      end if;

      if FTY2 + Min_Space <= TTY1 then
         M.Y := (FTY2 + TTY1) / 2.0;
      elsif TTY2 + Min_Space <= FTY1 then
         M.Y := (FTY1 + TTY2) / 2.0;
      else
         M.Y := Gdouble'Last;  --  no valid horizontal line in between
      end if;

      Matrix :=
        (Dim => Dim,
         X => ((FTX1 - B, From.X, FTX2 + B, TTX1 - B, To.X, TTX2 + B, M.X)),
         Y => ((FTY1 - B, From.Y, FTY2 + B, TTY1 - B, To.Y, TTY2 + B, M.Y)));
      Sort (Matrix.X);
      Sort (Matrix.Y);

      for J in Matrix.X'Range loop
         if abs (Matrix.X (J) - P_From.X) < 0.01 then
            C1.X := J;
         end if;
         if abs (Matrix.X (J) - P_To.X) < 0.01 then
            C2.X := J;
         end if;
         if abs (Matrix.Y (J) - P_From.Y) < 0.01 then
            C1.Y := J;
         end if;
         if abs (Matrix.Y (J) - P_To.Y) < 0.01 then
            C2.Y := J;
         end if;
      end loop;

      --  Compute the shortest path between the two points C1 and C2. We also
      --  do some post-processing to limit the number of segments (which in
      --  turn speeds up drawing and click

      declare
         Path   : constant Coordinate_Array := Astar_Find (Matrix, C1, C2);
         Points : Item_Point_Array (1 .. 4 + Path'Length);
         P      : Integer;
         Along_X : Boolean;

         procedure Add_Point (New_P : Item_Point);
         --  Add a new point to the final path, or merge with the previous
         --  point if possible

         procedure Add_Point (New_P : Item_Point) is
            Tmp : Boolean;
         begin
            Tmp := abs (New_P.X - Points (P - 1).X) < 0.01;
            if Tmp = Along_X then
               --  both along the X axis => merge points
               Points (P - 1) := New_P;
            else
               --  Validate the new point
               Along_X := Tmp;
               Points (P) := New_P;
               P := P + 1;
            end if;
         end Add_Point;

      begin
         Points (Points'First) := From;
         P := Points'First + 1;
         Points (P) := P_From;
         Along_X := abs (Points (P).X - Points (P - 1).X) < 0.01;

         P := P + 1;

         for C in Path'First + 1 .. Path'Last loop
            Add_Point ((Matrix.X (Path (C).X), Matrix.Y (Path (C).Y)));
         end loop;

         Add_Point (To);

         Link.Points := new Item_Point_Array'(Points (Points'First .. P - 1));
      end;

      Compute_Bounding_Box (Link);
      Compute_Labels (Link, Dim);
   end Compute_Layout_For_Orthogonal_Link;

   --------------------------------------
   -- Compute_Layout_For_Straight_Link --
   --------------------------------------

   procedure Compute_Layout_For_Straight_Link
     (Link : not null access Canvas_Link_Record'Class)
   is
      P   : constant Item_Point_Array_Access := Link.Points;
      Dim : constant Anchors := Compute_Anchors (Link);

      function Get_Wp return Item_Point_Array;
      --  Return the waypoints to use

      function Get_Wp return Item_Point_Array is
      begin
         --  Support for self-referencing straight links

         if Link.From = Link.To then
            return No_Waypoints;
         elsif Link.Waypoints /= null then
            return Link.Waypoints.all;
         else
            return No_Waypoints;
         end if;
      end Get_Wp;

      Waypoints : Item_Point_Array := Get_Wp;
      Tmp       : Item_Point;
   begin
      if Link.From = Link.To then
         Tmp := (Dim.From.Toplevel.X + Dim.From.Toplevel.Width,
                 Dim.From.Toplevel.Y);
         Unchecked_Free (Link.Points);
         Link.Points := new Item_Point_Array'
           ((Tmp.X - 10.0, Tmp.Y),
            (Tmp.X - 10.0, Tmp.Y - 10.0),
            (Tmp.X + 10.0, Tmp.Y - 10.0),
            (Tmp.X + 10.0, Tmp.Y + 10.0),
            (Tmp.X, Tmp.Y + 10.0));

      --  If a link had waypoints so that the first outbound segment from a
      --  box is horizontal or vertical, we move the waypoint to keep the
      --  segment that way. This provides a more natural feel.

      elsif P /= null and then Waypoints'Length /= 0 then
         --  Is the first segment horizontal or vertical ?
         if abs (P (P'First).Y - Waypoints (Waypoints'First).Y) < 0.8 then
            Waypoints (Waypoints'First).Y := Dim.From.P.Y;
         elsif abs (P (P'First).X - Waypoints (Waypoints'First).Y) < 0.8 then
            Waypoints (Waypoints'First).X := Dim.From.P.X;
         end if;

         --  Is the last segment horizontal or vertical ?

         --  If this horizontal ?
         if abs (P (P'Last).Y - Waypoints (Waypoints'Last).Y) < 0.8 then
            Waypoints (Waypoints'Last).Y := Dim.To.P.Y;
            --  is this vertical ?
         elsif abs (P (P'Last).X - Waypoints (Waypoints'Last).Y) < 0.8 then
            Waypoints (Waypoints'Last).X := Dim.To.P.X;
         end if;

         Unchecked_Free (Link.Points);
         Link.Points := new Item_Point_Array'
           (Link.Model_To_Item (Dim.From.P)
            & Waypoints
            & Link.Model_To_Item (Dim.To.P));

      else
         Unchecked_Free (Link.Points);
         Link.Points := new Item_Point_Array'
           (Link.Model_To_Item (Dim.From.P)
            & Waypoints
            & Link.Model_To_Item (Dim.To.P));
      end if;

      Compute_Bounding_Box (Link);
      Compute_Labels (Link, Dim);
   end Compute_Layout_For_Straight_Link;

   ---------------------------------
   -- Compute_Layout_For_Arc_Link --
   ---------------------------------

   procedure Compute_Layout_For_Arc_Link
     (Link   : not null access Canvas_Link_Record'Class;
      Offset : Gint := 1)
   is
      Dim : constant Anchors := Compute_Anchors (Link);

      function Get_Wp return Item_Point_Array;
      --  Return the waypoints to use

      procedure Control_Points
        (From, To : Item_Point; Ctrl1, Ctrl2 : out Item_Point);
      --  Compute the control points on the curve from From to To

      function Get_Wp return Item_Point_Array is
      begin
         if Link.From = Link.To then
            return No_Waypoints;
         elsif Link.Waypoints /= null then
            return Link.Waypoints.all;
         else
            return No_Waypoints;
         end if;
      end Get_Wp;

      procedure Control_Points
        (From, To : Item_Point; Ctrl1, Ctrl2 : out Item_Point)
      is
         Dx : Gdouble := To.X - From.X;
         Dy : Gdouble := To.Y - From.Y;
         D : constant Gdouble := Sqrt (Dx * Dx + Dy * Dy);

         Pixels : constant Gdouble := 10.0;
         --  Height of the rectangle, i.e. maximum distance between the arc
         --  link and the straight link joining the same two ends.

         E : constant Gdouble := Pixels * Gdouble (abs (Offset)) / D;

      begin
         Dx := Dx * E;
         Dy := Dy * E;

         if Offset > 0 then
            Ctrl1 := (From.X - Dy, From.Y + Dx);
            Ctrl2 := (To.X - Dy,   To.Y + Dx);
         else
            Ctrl1 := (From.X + Dy, From.Y - Dx);
            Ctrl2 := (To.X + Dy,   To.Y - Dx);
         end if;
      end Control_Points;

      Waypoints : constant Item_Point_Array := Get_Wp;
      P1, P2, P3, P4 : Item_Point;
      FP, TP : Item_Point;
   begin
      Unchecked_Free (Link.Points);

      if Link.From = Link.To then
         Link.Points := new Item_Point_Array'
           (Circle_From_Bezier
              (Center => Link.Model_To_Item
                   ((Dim.From.Toplevel.X + Dim.From.Toplevel.Width,
                    Dim.From.Toplevel.Y)),
               Radius => 10.0 + 4.0 * Gdouble (abs (Offset) - 1)));

      elsif Waypoints'Length = 0 then
         FP := Link.Model_To_Item (Dim.From.P);
         TP := Link.Model_To_Item (Dim.To.P);

         Control_Points (FP, TP, P1, P2);
         Link.Points := new Item_Point_Array'((FP, P1, P2, TP));

      else
         FP := Link.Model_To_Item (Dim.From.P);
         TP := Link.Model_To_Item (Dim.To.P);

         Control_Points (FP, Waypoints (Waypoints'First), P1, P2);
         Control_Points (Waypoints (Waypoints'Last), TP, P3, P4);
         Link.Points := new Item_Point_Array'
           (Item_Point_Array'(FP, P1, P2)
            & Waypoints
            & Item_Point_Array'(P3, P4, TP));
      end if;

      Compute_Bounding_Box (Link);
      Compute_Labels (Link, Dim);
   end Compute_Layout_For_Arc_Link;

   ----------------------------------------
   -- Compute_Layout_For_Orthocurve_Link --
   ----------------------------------------

   procedure Compute_Layout_For_Orthocurve_Link
     (Link   : not null access Canvas_Link_Record'Class)
   is
      P : Item_Point_Array_Access;
      L : Integer;
   begin
      Compute_Layout_For_Orthogonal_Link (Link);
      P := Link.Points;

      if P'Length <= 2 then
         null;  --  degenerate case, handled in Draw_Link
      elsif P'Length = 3 then
         Link.Points := new Item_Point_Array'
           ((P (P'First), P (P'First + 1), P (P'First + 1), P (P'Last)));
         Unchecked_Free (P);
      elsif P'Length = 4 then
         null;
      else
         --  Create intermediate points in the middle of segments

         Link.Points := new Item_Point_Array (1 .. 3 * P'Length - 5);
         Link.Points (Link.Points'First) := P (P'First);
         L := Link.Points'First + 1;

         for P2 in P'First + 1 .. P'Last - 1 loop
            if P2 = P'Last - 1 then
               Link.Points (L + 2) := P (P2 + 1);
            else
               Link.Points (L + 2) :=          --  a new intermediate point
                 ((P (P2).X + P (P2 + 1).X) / 2.0,
                  (P (P2).Y + P (P2 + 1).Y) / 2.0);
            end if;

            --  The control points are 1/3 of the way.

            Link.Points (L) :=
              (P (P2).X * 2.0 / 3.0 + Link.Points (L - 1).X * 1.0 / 3.0,
               P (P2).Y * 2.0 / 3.0 + Link.Points (L - 1).Y * 1.0 / 3.0);
            Link.Points (L + 1) :=
              (P (P2).X * 1.0 / 3.0 + Link.Points (L + 2).X * 2.0 / 3.0,
               P (P2).Y * 1.0 / 3.0 + Link.Points (L + 2).Y * 2.0 / 3.0);

            L := L + 3;
         end loop;

         Unchecked_Free (P);
      end if;
   end Compute_Layout_For_Orthocurve_Link;

   ---------------
   -- Draw_Link --
   ---------------

   procedure Draw_Link
     (Link : not null access Canvas_Link_Record'Class;
      Cr   : Cairo.Cairo_Context)
   is
      P      : constant Item_Point_Array_Access := Link.Points;
   begin
      pragma Assert (P /= null, "waypoints must be computed first");
      pragma Assert (P'Length >= 2, "no enough waypoints");

      case Link.Routing is
         when Straight | Orthogonal =>
            Link.Style.Draw_Polyline (Cr, P.all);

         when Orthocurve =>
            if P'Length = 2 then
               Link.Style.Draw_Polyline (Cr, P.all);
            else
               Link.Style.Draw_Polycurve (Cr, P.all);
            end if;

         when Curve =>
            Link.Style.Draw_Polycurve (Cr, P.all);
      end case;
   end Draw_Link;

   ------------------------
   -- Circle_From_Bezier --
   ------------------------

   function Circle_From_Bezier
     (Center   : Item_Point;
      Radius   : Glib.Gdouble) return Item_Point_Array
   is
      --  Magic number comes from several articles on the web, including
      --    http://www.charlespetzold.com/blog/2012/12/
      --       Bezier-Circles-and-Bezier-Ellipses.html

      P : Item_Point_Array (1 .. 13);
      R : constant Gdouble := Radius * 0.55;
   begin
      P (P'First + 0)  := (Center.X,          Center.Y - Radius);

      P (P'First + 1)  := (Center.X + R,      Center.Y - Radius);
      P (P'First + 2)  := (Center.X + Radius, Center.Y - R);

      P (P'First + 3)  := (Center.X + Radius, Center.Y);

      P (P'First + 4)  := (Center.X + Radius, Center.Y + R);
      P (P'First + 5)  := (Center.X + R,      Center.Y + Radius);

      P (P'First + 6)  := (Center.X,          Center.Y + Radius);

      P (P'First + 7)  := (Center.X - R,      Center.Y + Radius);
      P (P'First + 8)  := (Center.X - Radius, Center.Y + R);

      P (P'First + 9)  := (Center.X - Radius, Center.Y);

      P (P'First + 10) := (Center.X - Radius, Center.Y - R);
      P (P'First + 11) := (Center.X - R,      Center.Y - Radius);

      P (P'First + 12) := (Center.X, Center.Y - Radius);

      return P;

      --  For quadratic bezier curves, we could have used:
      --  See http://texdoc.net/texmf-dist/doc/latex/lapdf/rcircle.pdf
   end Circle_From_Bezier;

end Gtkada.Canvas_View.Links;