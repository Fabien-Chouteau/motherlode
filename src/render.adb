--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with World; use World;
with Player;

package body Render is

   type Tile_Pixel_Data is array (0 .. (16 * 272) - 1) of UInt16
     with Convention => C;

   Tiles : Tile_Pixel_Data;
   pragma Import (C, Tiles, "tiles_pixel_data");

   type Font_Tile_Pixel_Data is array (0 .. (760 * 8) - 1) of UInt16
     with Convention => C;

   Font_Tiles : Font_Tile_Pixel_Data;
   pragma Import (C, Font_Tiles, "font_tiles");

   First_TX : Boolean := True;

   --------------------
   -- Refresh_Screen --
   --------------------

   procedure Refresh_Screen (Acc : not null Screen.Framebuffer_Access) is
   begin
      if not First_TX then
         Screen.Wait_End_Of_DMA;
         Screen.End_Pixel_TX;
      else
         First_TX := False;
      end if;

      Screen.Set_Address (X_Start => 0,
                          X_End   => Screen.Width - 1,
                          Y_Start => 0,
                          Y_End   => Screen.Height - 1);

      Screen.Start_Pixel_TX;
      Screen.Start_DMA (Acc);
   end Refresh_Screen;

   ---------------
   -- Draw_Cell --
   ---------------

   procedure Draw_Tile
     (FB : in out Frame_Buffer; X, Y : Integer; Id : Natural)
   is
      Tile_Offset : constant Natural :=
        Cell_Size * Cell_Size * Id;
   begin
      for PX in 0 .. Cell_Size - 1 loop
         for PY in 0 .. Cell_Size - 1 loop
            if X + PX in 0 .. Screen.Width - 1
              and then
                Y + PY in 0 .. Screen.Height - 1
            then
               FB ((X + PX) + (Y + PY) * Screen.Width)
                 := Tiles (Tile_Offset + PX + PY * Cell_Size);
            end if;
         end loop;
      end loop;
   end Draw_Tile;

   ---------------
   -- Draw_Cell --
   ---------------

   procedure Draw_Cell
     (FB : in out Frame_Buffer; X, Y : Integer; Kind : World.Cell_Kind)
   is
      Id : constant Natural := (case Kind is
                                   when Empty   => 0,
                                   when Dirt    => 2,
                                   when Coal    => 3,
                                   when Iron    => 4,
                                   when Gold    => 5,
                                   when Diamond => 6,
                                   when Rock    => 7);
   begin
      Draw_Tile (FB, X, Y, Id);
   end Draw_Cell;

   ----------------
   -- Draw_World --
   ----------------

   procedure Draw_World (FB : in out Frame_Buffer) is

      Player_X : constant Integer := Player.Position.X;
      Player_Y : constant Integer := Player.Position.Y;

      --  Camera borders bounded by the ground borders
      C_Left   : constant Integer :=
        Integer'Max
          (Integer'Min (Player_X - Screen.Width / 2,
           Cell_Size * Ground_Width - Screen.Width),
           0);

      C_Top   : constant Integer :=
        Integer'Max
          (Integer'Min (Player_Y - Screen.Height / 2,
           Cell_Size * Ground_Depth - Screen.Height),
           0);
      --  C_Bottom : constant Integer :=
      --    Integer'Min (Player_Y + Screen.Width / 2, Cell_Size * Ground_Depth);

      Left_Cell : constant Natural := C_Left / Cell_Size;
      --  Right_Cell : constant Natural := C_Right / Cell_Size;
      Top_Cell : constant Natural := C_Top / Cell_Size;
      --  Bottom_Cell : constant Natural := C_Bottom / Cell_Size;

      --  X offsets of buildings
      B1 : constant Natural := 4;
      B2 : constant Natural := 14;
      B3 : constant Natural := 24;
   begin
      for X in 0 .. (Screen.Width / Cell_Size) loop
         if Left_Cell + X < Ground_Width then
            for Y in 0 .. (Screen.Height / Cell_Size) loop
               if Top_Cell + Y < Ground_Depth then
                  declare
                     CX : constant Natural := Left_Cell + X;
                     CY : constant Natural := Top_Cell + Y;
                     Left_On_Screen : constant Integer := (CX * Cell_Size) - C_Left;
                     Top_On_Screen  : constant Integer := (CY * Cell_Size) - C_Top;
                  begin

                     case CY is
                        when 1 =>
                           case CX is
                           when B1 | B2 | B3 =>
                              Draw_Tile (FB, Left_On_Screen, Top_On_Screen, 9);
                           when B1 + 1 =>
                              Draw_Tile (FB, Left_On_Screen, Top_On_Screen, 11);
                           when B2 + 1 =>
                              Draw_Tile (FB, Left_On_Screen, Top_On_Screen, 10);
                           when B3 + 1 =>
                              Draw_Tile (FB, Left_On_Screen, Top_On_Screen, 12);
                           when B1 + 2 | B2 + 2 | B3 + 2 =>
                              Draw_Tile (FB, Left_On_Screen, Top_On_Screen, 13);
                           when others =>
                              Draw_Cell (FB, Left_On_Screen, Top_On_Screen,
                                         World.Empty);
                           end case;
                        when 2 =>
                           case CX is
                           when B1 | B2 | B3 =>
                              Draw_Tile (FB, Left_On_Screen, Top_On_Screen, 14);
                           when B1 + 1 | B2 + 1 | B3 + 1 =>
                              Draw_Tile (FB, Left_On_Screen, Top_On_Screen, 15);
                           when B1 + 2 | B2 + 2 | B3 + 2 =>
                              Draw_Tile (FB, Left_On_Screen, Top_On_Screen, 16);
                           when others =>
                              Draw_Cell (FB, Left_On_Screen, Top_On_Screen,
                                         World.Empty);
                           end case;
                        when 3 =>
                           if Get_Cell (CX, CY) = World.Dirt then
                              --  Top layer of dirt has a tile with grass
                              Draw_Tile (FB, Left_On_Screen, Top_On_Screen, 1);
                           else
                              Draw_Cell (FB, Left_On_Screen,
                                         Top_On_Screen,
                                         Get_Cell (CX, CY));
                           end if;

                        when others =>
                           Draw_Cell (FB, Left_On_Screen,
                                      Top_On_Screen,
                                      Get_Cell (CX, CY));
                     end case;
                  end;
               end if;
            end loop;
         end if;
      end loop;

      Render.Draw_Player (FB,
                          Player_X - Cell_Size / 2 - C_Left,
                          Player_Y - Cell_Size / 2 - C_Top);
      Player.Draw_Hud (FB);

   end Draw_World;

   -----------------
   -- Draw_Player --
   -----------------

   procedure Draw_Player (FB : in out Frame_Buffer; X, Y : Integer) is
      Tile_Offset : constant Natural :=
        Cell_Size * Cell_Size * 8;
   begin
      for PX in 0 .. Cell_Size - 1 loop
         for PY in 0 .. Cell_Size - 1 loop
            if X + PX in 0 .. Screen.Width - 1
              and then
                Y + PY in 0 .. Screen.Height - 1
            then
               declare
                  Pix : constant UInt16 :=
                    Tiles (Tile_Offset + PX + PY * Cell_Size);
               begin
                  if Pix /= 0 then
                     FB ((X + PX) + (Y + PY) * Screen.Width)
                       := Pix;
                  end if;
               end;
            end if;
         end loop;
      end loop;
   end Draw_Player;

   ---------------
   -- Draw_Char --
   ---------------

   procedure Draw_Char (FB    : in out Frame_Buffer;
                        Char  : Character;
                        X, Y  : Natural)
   is

      Glyph_Width : constant := 8;
      Width       : constant := 760;
      C_Index     : constant Natural := Character'Pos (Char) - 32;

      Index : Natural;
      FB_Index : Natural;
   begin


      Index := C_Index * Glyph_Width;
      FB_Index := X + Y * Screen.Width;

      for H in 0 .. Glyph_Width - 1 loop
         for W in 0 .. Glyph_Width - 1 loop
            if Font_Tiles (Index) /= 0 then
               FB (FB_Index) := Font_Tiles (Index);
            end if;
            FB_Index := FB_Index + 1;
            Index := Index + 1;
         end loop;

         Index := Index + Width - Glyph_Width;
         FB_Index := FB_Index + Screen.Width - Glyph_Width;
      end loop;
   end Draw_Char;

   -----------------
   -- Draw_String --
   -----------------

   procedure Draw_String (FB    : in out Frame_Buffer;
                          Str   : String;
                          X, Y  : Natural)
   is
      Count : Natural := 0;
   begin
      for C of Str loop
         exit when X + Count * 8 > Screen.Width;
         Draw_Char
           (FB,
            C,
            X + Count * 8,
            Y);
         Count := Count + 1;
      end loop;
   end Draw_String;

   ----------------------
   -- Draw_String_Left --
   ----------------------

   procedure Draw_String_Left (FB    : in out Frame_Buffer;
                               Str   : String;
                               X, Y  : Natural)
   is
   begin
      Draw_String (FB, Str, X - 8 * Str'Length, Y);
   end Draw_String_Left;

   ------------------------
   -- Draw_String_Center --
   ------------------------

   procedure Draw_String_Center (FB    : in out Frame_Buffer;
                                 Str   : String;
                                 X, Y  : Natural)
   is
   begin
      Draw_String (FB, Str, X - 4 * Str'Length, Y - 4);
   end Draw_String_Center;

   -----------------
   -- Draw_H_Line --
   -----------------

   procedure Draw_H_Line (FB        : in out Frame_Buffer;
                          X, Y, Len : Natural;
                          Color     : UInt16)
   is
      Start : constant Natural := X + Y * Screen.Width;
   begin
      FB (Start .. Start + Len) := (others => Color);
   end Draw_H_Line;

   -----------------
   -- Draw_H_Line --
   -----------------

   procedure Draw_V_Line (FB        : in out Frame_Buffer;
                          X, Y, Len : Natural;
                          Color     : UInt16)
   is
      Index : Natural := X + Y * Screen.Width;
   begin
      for Cnt in 1 .. Len loop
         FB (Index) := Color;
         Index := Index + Screen.Width;
      end loop;
   end Draw_V_Line;

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

begin

   --  Byte swap the tile data
   for Index in Tiles'Range loop
      declare
         Pix : constant UInt16 := Tiles (Index);
      begin
         Tiles (Index) :=
           (Shift_Left (Pix, 8) and 16#FF00#) or Shift_Right (Pix, 8);
      end;
   end loop;

   --  Byte swap the font tile data
   for Index in Font_Tiles'Range loop
      declare
         Pix : constant UInt16 := Font_Tiles (Index);
      begin
         Font_Tiles (Index) :=
           (Shift_Left (Pix, 8) and 16#FF00#) or Shift_Right (Pix, 8);
      end;
   end loop;

end Render;
