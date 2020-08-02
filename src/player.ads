--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with GESTE_Config;
with GESTE;
with GESTE.Physics;
with GESTE.Sprite.Animated;
with GESTE.Tile_Bank;

with HAl;

with World;

package Player is

   procedure Spawn;

   procedure Move (Pt : GESTE.Pix_Point);

   function Position return GESTE.Pix_Point;

   function Is_Alive return Boolean;

   procedure Update;

   procedure Draw (FB : in out HAL.UInt16_Array);

   procedure Move_Up;
   procedure Move_Down;
   procedure Move_Left;
   procedure Move_Right;
   procedure Drill;

private

   type Cargo_Array is array (World.Valuable_Cell) of Natural;

   type Player_Type
   is limited new GESTE.Physics.Object with record
      Alive : Boolean := True;

      Drill_Lvl : Positive := 5;

      Money     : Natural := 0;
      Fuel      : Float := 5.0;
      Fuel_Max  : Natural := 10;
      Cargo     : Cargo_Array := (others => 0);
      Cargo_Sum : Natural := 0;
      Cargo_Max : Natural := 15;
      Hull      : Natural := 5;
      Hull_Max  : Natural := 5;
   end record;

   procedure Put_In_Cargo (This : in out Player_Type;
                           Kind : World.Valuable_Cell);

   procedure Empty_Cargo (This : in out Player_Type);

end Player;
