--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with HAL; use HAL;

with Pygamer; use Pygamer;
with Pygamer.Screen;

with Render; use Render;

package body HUD is

   ----------------
   -- Draw_Gauge --
   ----------------

   procedure Draw_Gauge (FB         : in out HAL.UInt16_Array;
                         Y          : Natural;
                         C          : Character;
                         Color      : UInt16;
                         Value, Max : Natural)
   is
   begin
      Draw_Char (FB, C, 0, Y);

      Draw_H_Line(FB, 9, Y + 1, Max + 1, Color); -- Top
      Draw_H_Line(FB, 9, Y + 6, Max + 1, Color); -- Bottom

      for H in Y + 2 .. Y + 5 loop
         Draw_H_Line(FB, 9, H, Value, Color); --  Content

         FB (9 + Max + 1 + H * Screen.Width) := Color; -- Right border of the box
      end loop;
   end Draw_Gauge;

   ----------
   -- Draw --
   ----------

   procedure Draw
     (FB : in out Render.Frame_Buffer;
      Money,
      Fuel, Fuel_Max,
      Cargo, Cargo_Max : Natural;
      Depth, Cash_In : Integer)
   is
      Fuel_Color : constant UInt16 := RGB565 (204, 102, 0);
      Cargo_Color : constant UInt16 := RGB565 (0, 102, 204);
   begin
      Draw_Gauge (FB, 0, 'F', Fuel_Color, Fuel, Fuel_Max);
      Draw_Gauge (FB, 9, 'C', Cargo_Color, Cargo, Cargo_Max);

      if Cargo = Cargo_Max then
         Draw_String_Center (FB, "CARGO FULL", Screen.Width / 2, 90);
      end if;

      if Fuel = 0 then
         Draw_String_Center (FB, "LOW FUEL", Screen.Width / 2, 100);
      end if;

      declare
         Str : String := Money'Img;
      begin
         Str (Str'First) := '$';
         Draw_String (FB, Str,
                      Screen.Width - Str'Length * 8,
                      1);
      end;

      if Cash_In /= 0 then
         declare
            Str : String := Cash_In'Img;
         begin
            if Cash_In > 0 then
               Str (Str'First) := '+';
            end if;
            Draw_String (FB, Str,
                         Screen.Width - Str'Length * 8,
                         9);
         end;
      end if;

      declare
         Str : constant String := Depth'Img;
      begin
         Draw_String (FB, Str,
                      Screen.Width - Str'Length * 8,
                      Screen.Height - 9);
      end;
   end Draw;

end HUD;
