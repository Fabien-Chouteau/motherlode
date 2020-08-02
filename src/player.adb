--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with GESTE;
with GESTE.Maths_Types; use GESTE.Maths_Types;
with GESTE.Physics;

with World; use World;
with HUD;
with Sound;

package body Player is

   Empty_Mass    : constant Value := Value (90.0);
   Fuel_Per_Step : constant := 0.01;


   P : aliased Player_Type;

   Going_Up    : Boolean := False;
   Going_Down  : Boolean := False;
   Going_Left  : Boolean := False;
   Going_Right : Boolean := False;
   Facing_Left : Boolean := False with Unreferenced;
   Using_Drill : Boolean := False;

   type Drill_Anim_Rec is record
      In_Progress : Boolean := False;
      Steps       : Natural := 0; -- Total number of steps for the animation
      Rem_Steps   : Natural := 0; -- Remaining number of steps in the animation
      Target_CX   : Natural := 0; -- X coord of the cell that is being drilled
      Target_CY   : Natural := 0; -- Y coord of the cell that is being drilled

      Origin_PX   : Natural := 0; -- X coord of the player when starting anim
      Origin_PY   : Natural := 0; -- Y coord of the player when starting anim
   end record;

   --  Data for the drill animation
   Drill_Anim : Drill_Anim_Rec;

   type Collision_Points is array (Natural range <>) of GESTE.Pix_Point;

   --  Bounding Box points
   BB_Top : constant Collision_Points :=
     ((-5, -6), (5, -6));
   BB_Bottom : constant Collision_Points :=
     ((-5, 6), (5, 6));
   BB_Left : constant Collision_Points :=
     ((-7, 6), (-7, -6));
   BB_Right : constant Collision_Points :=
     ((7, 6), (7, -6));


   --  Drill points
   Drill_Bottom : constant Collision_Points :=
     (0 => (0, 8));
   Drill_Left : constant Collision_Points :=
     (0 => (-8, 0));
   Drill_Right : constant Collision_Points :=
     (0 => (8, 0));

   Grounded : Boolean := False;

   function Collides (Points : Collision_Points) return Boolean;

   --------------
   -- Collides --
   --------------

   function Collides (Points : Collision_Points) return Boolean is
      X : constant Integer := Integer (P.Position.X);
      Y : constant Integer := Integer (P.Position.Y);
   begin
      for Pt of Points loop

         if World.Collides (X + Pt.X, Y + Pt.Y) then
            return True;
         end if;
      end loop;

      return False;
   end Collides;

   -----------
   -- Spawn --
   -----------

   procedure Spawn is
   begin
      P.Alive := True;
      P.Set_Mass (Empty_Mass);
      P.Set_Speed ((0.0, 0.0));
      Move ((50, 20));
   end Spawn;

   ----------
   -- Move --
   ----------

   procedure Move (Pt : GESTE.Pix_Point) is
   begin
      P.Set_Position (GESTE.Maths_Types.Point'(Value (Pt.X), Value (Pt.Y)));
   end Move;

   --------------
   -- Position --
   --------------

   function Position return GESTE.Pix_Point
   is ((Integer (P.Position.X), Integer (P.Position.Y)));

   --------------
   -- Is_Alive --
   --------------

   function Is_Alive return Boolean
   is (P.Alive);

   ------------------
   -- Put_In_Cargo --
   ------------------

   procedure Put_In_Cargo (This : in out Player_Type; Kind : Valuable_Cell) is
   begin

      if P.Cargo_Sum < P.Cargo_Max then
         Sound.Play_Coin;
         P.Cargo (Kind) := P.Cargo (Kind) + 1;
         P.Cargo_Sum := P.Cargo_Sum + 1;

         P.Set_Mass (P.Mass + (case Kind is
                        when Coal    => 10.0,
                        when Iron    => 20.0,
                        when Gold    => 40.0,
                        when Diamond => 60.0));
      end if;
   end Put_In_Cargo;

   -----------------
   -- Empty_Cargo --
   -----------------

   procedure Empty_Cargo (This : in out Player_Type) is
   begin
      for Kind in Valuable_Cell loop
         P.Money := P.Money + P.Cargo (Kind) * (case Kind is
                                                   when Coal    => 30,
                                                   when Iron    => 100,
                                                   when Gold    => 250,
                                                   when Diamond => 750);
         P.Cargo (Kind) := 0;
      end loop;
      P.Cargo_Sum := 0;
      P.Set_Mass (Empty_Mass);
   end Empty_Cargo;

   ---------------
   -- Try_Drill --
   ---------------

   procedure Try_Drill is
      PX : constant Integer := Integer (P.Position.X);
      PY : constant Integer := Integer (P.Position.Y);
      CX :          Integer := PX / Cell_Size;
      CY :          Integer := PY / Cell_Size;
      Drill : Boolean := False;
   begin
      --  FIXME: drilling proto
      if Using_Drill and then Grounded then
         if Going_Down and Collides (Drill_Bottom) then
            CY := CY + 1;
            Drill := True;
         elsif Going_Left and Collides (Drill_Left) then
            CX := CX - 1;
            Drill := True;
         elsif Going_Right and Collides (Drill_Right) then
            CX := CX + 1;
            Drill := True;
         end if;


         if Drill
           and then
            CX in 0 .. Ground_Width - 1
           and then
            CY in 0 .. Ground_Depth - 1
         then
            declare
               Kind : constant Cell_Kind := Ground (CX + CY * Ground_Width);
            begin
               if Kind /= Rock then

                  Sound.Play_Drill;
                  if Kind in Valuable_Cell then
                     P.Put_In_Cargo (Kind);
                  end if;

                  Drill_Anim.Target_CX := CX;
                  Drill_Anim.Target_CY := CY;
                  Drill_Anim.Origin_PX := Position.X;
                  Drill_Anim.Origin_PY := Position.Y;
                  Drill_Anim.In_Progress := True;
                  Drill_Anim.Steps := (case Kind is
                                          when Dirt    => 15,
                                          when Coal    => 20,
                                          when Iron    => 30,
                                          when Gold    => 40,
                                          when Diamond => 50,
                                          when others  => raise Program_Error);

                  --  Faster drilling with a better drill...
                  Drill_Anim.Steps := Drill_Anim.Steps / P.Drill_Lvl;

                  Drill_Anim.Rem_Steps := Drill_Anim.Steps;
               end if;
            end;
         end if;
      end if;
   end Try_Drill;

   -----------------------
   -- Update_Drill_Anim --
   -----------------------

   procedure Update_Drill_Anim is
      D : Drill_Anim_Rec renames Drill_Anim;
      Target_PX : constant Natural := D.Target_CX * Cell_Size + Cell_Size / 2;
      Target_PY : constant Natural := D.Target_CY * Cell_Size + Cell_Size / 2;

      Shaking : constant array (0 .. 9) of Integer :=
        (1, 0, 0, 1, 0, 1, 1, 0, 1, 0);

   begin
      if D.Rem_Steps = 0 then
         D.In_Progress := False;
         Ground (D.Target_CX + D.Target_CY * Ground_Width) := Empty;
         Move ((Target_PX, Target_PY));
         Using_Drill := False;

         --  Kill speed
         P.Set_Speed ((Value (0.0), Value (0.0)));
      else

         --  Consume Fuel
         P.Fuel := P.Fuel - Fuel_Per_Step;

         declare
            Percent : constant Float :=
              Float (D.Rem_Steps) / Float (D.Steps);
            DX : Integer :=
              Integer (Percent * Float (Target_PX - D.Origin_PX));
            DY : Integer :=
              Integer (Percent * Float (Target_PY - D.Origin_PY));
         begin

            --  Add a little bit of shaking
            DX := DX + Shaking (D.Rem_Steps mod Shaking'Length);
            DY := DY + Shaking ((D.Rem_Steps + 2) mod Shaking'Length);

            Move ((Target_PX - DX, Target_PY - DY));
            D.Rem_Steps := D.Rem_Steps - 1;
         end;
      end if;
   end Update_Drill_Anim;

   -------------------
   -- Update_Motion --
   -------------------

   procedure Update_Motion is
      Old : constant Point := P.Position;
      Elapsed : constant Value := Value (1.0 / 60.0);

      Collision_To_Fix : Boolean;
   begin
      if Going_Right then
         Facing_Left := False;
      elsif Going_Left then
         Facing_Left := True;
      end if;

      if P.Fuel <= 0.0 then
         P.Fuel := 0.0;
         Going_Up := False;
         Going_Down := False;
         Going_Left := False;
         Going_Right := False;
      end if;


      --  Lateral movements
      if Grounded then
         if Going_Right then
            P.Apply_Force ((100_000.0, 0.0));
         elsif Going_Left then
            P.Apply_Force ((-100_000.0, 0.0));
         else
            --  Friction on the floor
            P.Apply_Force (
                           (Value (Value (-2000.0) * P.Speed.X),
                           0.0));
         end if;
      else
         if Going_Right then
            P.Apply_Force ((70_000.0, 0.0));

         elsif Going_Left then
            P.Apply_Force ((-70_000.0, 0.0));

         end if;
      end if;

      --  Gavity
      if not Grounded then
         P.Apply_Gravity (Value (-500.0));
      end if;

      if Going_Up then
         --  Thrust
         P.Apply_Force ((0.0, -140_000.0));
      end if;

      P.Step (Elapsed);

      Grounded := False;
      Collision_To_Fix := False;

      if P.Speed.Y < 0.0 then
         --  Going up
         if Collides (BB_Top) then
            Collision_To_Fix := True;

            --  Touching a roof, kill vertical speed
            P.Set_Speed ((P.Speed.X, Value (0.0)));

            --  Going back to previous Y coord
            P.Set_Position ((P.Position.X, Old.Y));
         end if;
      elsif P.Speed.Y > 0.0 then
         --  Going down
         if Collides (BB_Bottom) then
            Collision_To_Fix := True;

            Grounded := True;

            --  Touching the ground, kill vertical speed
            P.Set_Speed ((P.Speed.X, Value (0.0)));

            --  Going back to previous Y coord
            P.Set_Position ((P.Position.X, Old.Y));
         end if;
      end if;

      if P.Speed.X > 0.0 then
         --  Going right
         if Collides (BB_Right) then
            Collision_To_Fix := True;

            --  Touching a wall, kill horizontal speed
            P.Set_Speed ((Value (0.0), P.Speed.Y));

            --  Going back to previos X coord
            P.Set_Position ((Old.X, P.Position.Y));
         end if;
      elsif P.Speed.X < 0.0 then
         --  Going left
         if Collides (BB_Left) then
            Collision_To_Fix := True;

            --  Touching a wall, kill horizontal speed
            P.Set_Speed ((Value (0.0), P.Speed.Y));

            --  Going back to previous X coord
            P.Set_Position ((Old.X, P.Position.Y));
         end if;
      end if;

      --  Fix the collisions, one pixel at a time
      while Collision_To_Fix loop

         Collision_To_Fix := False;

         if Collides (BB_Top) then
            Collision_To_Fix := True;
            --  Try a new Y coord that do not collides
            P.Set_Position ((P.Position.X, P.Position.Y + 1.0));
         elsif Collides (BB_Bottom) then
            Collision_To_Fix := True;
            --  Try a new Y coord that do not collides
            P.Set_Position ((P.Position.X, P.Position.Y - 1.0));
         end if;

         if Collides (BB_Right) then
            Collision_To_Fix := True;
            --  Try to find X coord that do not collides
            P.Set_Position ((P.Position.X - 1.0, P.Position.Y));
         elsif Collides (BB_Left) then
            Collision_To_Fix := True;
            --  Try to find X coord that do not collides
            P.Set_Position ((P.Position.X + 1.0, P.Position.Y));
         end if;
      end loop;

      --  Consume Fuel
      if Going_Right or else Going_Left or else Going_Up or else Going_Down then
         P.Fuel := P.Fuel - Fuel_Per_Step;
      end if;

      Try_Drill;

      --  FIXME soil market
      if Integer (P.Position.Y) < 32 then
         P.Empty_Cargo;
         P.Fuel := Float (P.Fuel_Max);
      end if;
   end Update_Motion;

   ------------
   -- Update --
   ------------

   procedure Update is
   begin
      if Drill_Anim.In_Progress then
         Update_Drill_Anim;
      else
         Update_Motion;
      end if;

      Going_Up := False;
      Going_Down := False;
      Going_Left := False;
      Going_Right := False;
      Using_Drill := False;
   end Update;

   ----------
   -- Draw --
   ----------

   procedure Draw (FB : in out HAL.UInt16_Array) is
   begin
      Hud.Draw (FB,
                P.Money,
                Natural (P.Fuel),
                P.Fuel_Max,
                P.Cargo_Sum,
                P.Cargo_Max,
                P.Hull,
                P.Hull_Max);
   end Draw;

   -------------
   -- Move_Up --
   -------------

   procedure Move_Up is
   begin
      Going_Up := True;
   end Move_Up;

   ---------------
   -- Move_Down --
   ---------------

   procedure Move_Down is
   begin
      Going_Down := True;
   end Move_Down;

   ---------------
   -- Move_Left --
   ---------------

   procedure Move_Left is
   begin
      Going_Left := True;
   end Move_Left;

   ----------------
   -- Move_Right --
   ----------------

   procedure Move_Right is
   begin
      Going_Right := True;
   end Move_Right;

   ----------------
   -- Drill --
   ----------------

   procedure Drill is
   begin
      Using_Drill := True;
   end Drill;

end Player;
