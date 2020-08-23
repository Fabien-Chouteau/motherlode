--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with GESTE;
with GESTE.Maths_Types; use GESTE.Maths_Types;

with HUD;
with Sound;

package body Player is

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
     ((-3, -4), (3, -4));
   BB_Bottom : constant Collision_Points :=
     ((-3, 5), (3, 5));
   BB_Left : constant Collision_Points :=
     ((-5, 5), (-5, -2));
   BB_Right : constant Collision_Points :=
     ((5, 5), (5, -2));


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
      P.Set_Mass (Parameters.Empty_Mass);
      P.Set_Speed ((0.0, 0.0));
      P.Money := 0;
      P.Fuel := Parameters.Start_Fuel;
      P.Equip_Level := (others => 1);

      Move ((Parameters.Spawn_X, Parameters.Spawn_Y));
   end Spawn;

   ----------
   -- Move --
   ----------

   procedure Move (Pt : GESTE.Pix_Point) is
   begin
      P.Set_Position (GESTE.Maths_Types.Point'(Value (Pt.X), Value (Pt.Y)));
      P.Set_Speed ((0.0, 0.0));
   end Move;

   --------------
   -- Position --
   --------------

   function Position return GESTE.Pix_Point
   is ((Integer (P.Position.X), Integer (P.Position.Y)));

   --------------
   -- Quantity --
   --------------

   function Quantity (Kind : World.Valuable_Cell) return Natural
   is (P.Cargo (Kind));

   ----------
   -- Drop --
   ----------

   procedure Drop (Kind : World.Valuable_Cell) is
      Cnt : Natural renames P.Cargo (Kind);
   begin
      if Cnt > 0 then
         Cnt := Cnt - 1;
         P.Cargo_Sum := P.Cargo_Sum - 1;

         P.Set_Mass (P.Mass - Value (Parameters.Weight (Kind)));
      end if;
   end Drop;

   -----------
   -- Level --
   -----------

   function Level (Kind : Parameters.Equipment)
                   return Parameters.Equipment_Level
   is (P.Equip_Level (Kind));

   -------------
   -- Upgrade --
   -------------

   procedure Upgrade (Kind : Parameters.Equipment) is
      use Parameters;
   begin
      if P.Equip_Level (Kind) /= Equipment_Level'Last then
         declare
            Next_Lvl : constant Equipment_Level := P.Equip_Level (Kind) + 1;
            Cost : constant Natural := Parameters.Price (Kind, Next_Lvl);
         begin
            if Cost <= P.Money then
               P.Money := P.Money - Cost;
               P.Equip_Level (Kind) := Next_Lvl;
               P.Cash_In := P.Cash_In - Cost;
               P.Cash_In_TTL := 30 * 1;
            end if;
         end;
      end if;
   end Upgrade;

   -----------
   -- Money --
   -----------

   function Money return Natural
   is (P.Money);

   ------------------
   -- Put_In_Cargo --
   ------------------

   procedure Put_In_Cargo (This : in out Player_Type;
                           Kind : World.Valuable_Cell)
   is
      use Parameters;
   begin

      if P.Cargo_Sum <  Cargo_Capacity (This.Equip_Level (Cargo)) then
         P.Cargo (Kind) := P.Cargo (Kind) + 1;
         P.Cargo_Sum := P.Cargo_Sum + 1;

         P.Set_Mass (P.Mass + GESTE.Maths_Types.Value (Weight (Kind)));
      end if;
   end Put_In_Cargo;

   -----------------
   -- Empty_Cargo --
   -----------------

   procedure Empty_Cargo (This : in out Player_Type) is
   begin
      if This.Cash_In_TTL /= 0 then
         --  Do not empty cargo when still showing previous cash operation
         return;
      end if;

      This.Cash_In := 0;
      for Kind in World.Valuable_Cell loop
         P.Cash_In := P.Cash_In + P.Cargo (Kind) * Parameters.Value (Kind);
         P.Cargo (Kind) := 0;
      end loop;

      if This.Cash_In = 0 then
         return;
      end if;

      P.Money := P.Money + P.Cash_In;

      --  How many frames the cash in text will be displayed
      P.Cash_In_TTL := 30  * 1;

      P.Cargo_Sum := 0;
      P.Set_Mass (Parameters.Empty_Mass);

      Sound.Play_Coin;
   end Empty_Cargo;

   ------------
   -- Refuel --
   ------------

   procedure Refuel (This : in out Player_Type) is

      use Parameters;

      Tank_Capa : constant Float :=
        Float (Tank_Capacity (This.Equip_Level (Tank)));

      Amount : constant Float :=
        Float'Min (Tank_Capa - P.Fuel,
                   Float (P.Money) / Parameters.Fuel_Price);
      Cost   : constant Natural := Natural (Amount * Parameters.Fuel_Price);
   begin

      if This.Cash_In_TTL /= 0 or else Amount = 0.0 then
         --  Do not refuel when still showing previous cash operation
         return;
      end if;

      if Cost <= This.Money then
         P.Fuel := P.Fuel + Amount;
         P.Money := P.Money - Cost;
         P.Cash_In := -Cost;
         P.Cash_In_TTL := 30 * 1;
      end if;
   end Refuel;

   ---------------
   -- Try_Drill --
   ---------------

   procedure Try_Drill is
      use World;
      use Parameters;

      PX : constant Integer := Integer (P.Position.X);
      PY : constant Integer := Integer (P.Position.Y);
      CX :          Integer := PX / Cell_Size;
      CY :          Integer := PY / Cell_Size;
      Drill : Boolean := False;
   begin
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
            CX in 0 .. World.Ground_Width - 1
           and then
            CY in 0 .. World.Ground_Depth - 1
         then
            declare
               Kind : constant Cell_Kind := Ground (CX + CY * Ground_Width);
            begin
               if (Kind /= Gold or else P.Equip_Level (Parameters.Drill) > 1)
                 and then
                   (Kind /= Diamond or else P.Equip_Level (Parameters.Drill) > 2)
                 and then
                   (Kind /= Rock or else P.Equip_Level (Parameters.Drill) = 7)
               then

                  Sound.Play_Drill;
                  if Kind in World.Valuable_Cell then
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
                                          when Rock    => 80,
                                          when others  => raise Program_Error);

                  --  Faster drilling with a better drill...
                  Drill_Anim.Steps :=
                    Drill_Anim.Steps / Natural (P.Equip_Level (Parameters.Drill));

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
      use World;

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
         P.Set_Speed ((GESTE.Maths_Types.Value (0.0),
                      GESTE.Maths_Types.Value (0.0)));
      else

         --  Consume Fuel
         P.Fuel := P.Fuel - Parameters.Fuel_Per_Step;

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
         P.Apply_Gravity (-Parameters.Gravity);
      end if;

      if Going_Up then
         --  Thrust
         P.Apply_Force ((0.0,
                        -Value (Parameters.Engine_Thrust
                          (P.Equip_Level (Parameters.Engine)))));
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
      if Going_Right or else Going_Left or else Going_Up then
         P.Fuel := P.Fuel - Parameters.Fuel_Per_Step;
      end if;

      Try_Drill;

      --  Market
      if Integer (P.Position.Y) in 16 * 2 .. 16 * 3
        and then
         Integer (P.Position.X) in 16 * 15 .. 16 * 16
      then
         P.Empty_Cargo;
      end if;

      --  Fuel pump
      if Integer (P.Position.Y) in 16 * 2 .. 16 * 3
        and then
         Integer (P.Position.X) in 16 * 5 .. 16 * 6
      then
         P.Refuel;
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

   procedure Draw_Hud (FB : in out HAL.UInt16_Array) is
      use Parameters;

   begin
      Hud.Draw (FB,
                P.Money,
                Natural (P.Fuel),
                Tank_Capacity (P.Equip_Level (Tank)),
                P.Cargo_Sum,
                Cargo_Capacity (P.Equip_Level (Cargo)),
                (-Integer (P.Position.Y) / World.Cell_Size) + 2,
                P.Cash_In);

      if P.Cash_In_TTL > 0 then
         P.Cash_In_TTL := P.Cash_In_TTL - 1;
      else
         P.Cash_In := 0;
      end if;
   end Draw_Hud;

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
