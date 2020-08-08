--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with HAL; use HAL;

with Pygamer; use Pygamer;
with Pygamer.Screen;

with BMP_Fonts; use BMP_Fonts;

package body HUD is

   ---------------
   -- Draw_Char --
   ---------------

   procedure Draw_Char (FB    : in out HAL.UInt16_Array;
                        Font  : BMP_Font;
                        Char  : Character;
                        X, Y  : Natural;
                        Color : UInt16)
   is
   begin
      for H in 0 .. Char_Height (Font) - 1 loop
         for W in 0 .. Char_Width (Font) - 1 loop
            if (Data (Font, Char, H) and Mask (Font, W)) /= 0 then
               FB ((X + W) + (Y + H) * Screen.Width) := Color;
            end if;
         end loop;
      end loop;
   end Draw_Char;

   procedure Draw_String (FB    : in out HAL.UInt16_Array;
                          Font  : BMP_Font;
                          Str   : String;
                          X, Y  : Natural;
                          Color : UInt16)
   is
      Count : Natural := 0;
   begin
      for C of Str loop
         exit when X + Count * Char_Width (Font) > Screen.Width;
         Draw_Char
           (FB,
            Font,
            C,
            X + Count * Char_Width (Font),
            Y,
            Color);
         Count := Count + 1;
      end loop;
   end Draw_String;

   -----------------
   -- Draw_H_Line --
   -----------------

   procedure Draw_H_Line (FB        : in out HAL.UInt16_Array;
                          X, Y, Len : Natural;
                          Color     : UInt16)
   is
      Start : constant Natural := X + Y * Screen.Width;
   begin
      FB (Start .. Start + Len) := (others => Color);
   end Draw_H_Line;

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
      Draw_Char (FB, Font8x8, C, 0, Y, Color);

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
     (FB : in out HAL.UInt16_Array;
      Money,
      Fuel, Fuel_Max,
      Cargo, Cargo_Max,
      Hull, Hull_Max : Natural;
      Depth : Integer)
   is
      Fuel_Color : constant UInt16 := RGB565 (204, 102, 0);
      Cargo_Color : constant UInt16 := RGB565 (0, 102, 204);
      Hull_Color : constant UInt16 := RGB565 (255, 51, 51);
      Money_Color : constant UInt16 := RGB565 (255, 204, 0);
   begin
      Draw_Gauge (FB, 0, 'f', Fuel_Color, Fuel, Fuel_Max);
      Draw_Gauge (FB, 9, 'c', Cargo_Color, Cargo, Cargo_Max);
      Draw_Gauge (FB, 18, 'h', Hull_Color, Hull, Hull_Max);

      if Fuel = 0 then
         Draw_String (FB, Font8x8, "NO FUEL", 52, 100, Fuel_Color);
      end if;

      declare
         Str : String := Money'Img;
      begin
         Str (Str'First) := '$';
         Draw_String (FB, Font8x8, Str,
                      Screen.Width - Str'Length * 8,
                      1,
                      Money_Color);
      end;

      declare
         Str : constant String := Depth'Img;
      begin
         Draw_String (FB, Font8x8, Str,
                      Screen.Width - Str'Length * 8,
                      Screen.Height - 9,
                      UInt16'Last);
      end;
   end Draw;

   ------------
   -- RGB565 --
   ------------

   function RGB565 (R, G, B : UInt8) return UInt16 is
      R16 : constant UInt16 :=
        Shift_Right (UInt16 (R), 3) and 16#1F#;
      G16 : constant UInt16 :=
        Shift_Right (UInt16 (G), 2) and 16#3F#;
      B16 : constant UInt16 :=
        Shift_Right (UInt16 (B), 3) and 16#1F#;
      RGB : constant UInt16 :=
        (Shift_Left (R16, 11) or Shift_Left (G16, 5) or B16);
   begin
      return Shift_Right (RGB and 16#FF00#, 8) or
        (Shift_Left (RGB, 8) and 16#FF00#);
   end RGB565;

end HUD;
