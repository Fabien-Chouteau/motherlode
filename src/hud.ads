--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with Render;

package HUD is

   procedure Draw
     (FB : in out Render.Frame_Buffer;
      Money,
      Fuel, Fuel_Max,
      Cargo, Cargo_Max : Natural;
      Depth, Cash_In : Integer);

end HUD;
