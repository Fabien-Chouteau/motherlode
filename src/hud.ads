--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with HAL;

package HUD is

   procedure Draw
     (FB : in out HAL.UInt16_Array;
      Money, Fuel, Fuel_Max, Cargo, Cargo_Max, Hull, Hull_Max : Natural);

   function RGB565 (R, G, B : HAL.UInt8) return HAL.UInt16;
end HUD;
