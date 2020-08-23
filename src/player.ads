--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with GESTE;
with GESTE.Physics;

with HAL;

with Parameters;
with World;

package Player is

   procedure Spawn;

   procedure Move (Pt : GESTE.Pix_Point);

   function Position return GESTE.Pix_Point;

   function Quantity (Kind : World.Valuable_Cell) return Natural;
   procedure Drop (Kind : World.Valuable_Cell);

   function Level (Kind : Parameters.Equipment)
                   return Parameters.Equipment_Level;
   procedure Upgrade (Kind : Parameters.Equipment);

   function Money return Natural;

   procedure Update;

   procedure Draw_Hud (FB : in out HAL.UInt16_Array);

   procedure Move_Up;
   procedure Move_Down;
   procedure Move_Left;
   procedure Move_Right;
   procedure Drill;

private

   type Cargo_Array is array (World.Valuable_Cell) of Natural;
   type Equip_Array is array (Parameters.Equipment) of Parameters.Equipment_Level;

   type Player_Type
   is limited new GESTE.Physics.Object with record
      Money     : Natural := 0;
      Fuel      : Float := 5.0;
      Cargo     : Cargo_Array := (others => 0);
      Cargo_Sum : Natural := 0;
      Equip_Level : Equip_Array := (others => 1);

      Cash_In     : Integer := 0;
      Cash_In_TTL : Natural := 0;
   end record;

   procedure Put_In_Cargo (This : in out Player_Type;
                           Kind : World.Valuable_Cell);

   procedure Empty_Cargo (This : in out Player_Type);

   procedure Refuel (This : in out Player_Type);

end Player;
