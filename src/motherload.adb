--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with PyGamer; use PyGamer;
with PyGamer.Screen;
with HAL; use HAL;
with Sound;
with PyGamer.Controls;
with PyGamer.Time;

with World; use World;
with Player;

package body Motherload is

   FB1 : aliased HAL.UInt16_Array := (0 .. (Screen.Width * Screen.Height) - 1 => 0);
   FB2 : aliased HAL.UInt16_Array := (0 .. (Screen.Width * Screen.Height) - 1 => 0);

   type Tile_Pixel_Data is array (0 .. (16 * 144) - 1) of UInt16
     with Convention => C;

   Tiles : Tile_Pixel_Data;
   pragma Import (C, Tiles, "tiles_pixel_data");

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

   -----------------
   -- Draw_Screen --
   -----------------

   procedure Draw_Screen (FB : in out HAL.UInt16_Array) is

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

      -----------------
      -- Draw_Player --
      -----------------

      procedure Draw_Player (PX, PY : Integer) is
         Tile_Offset : constant Natural := Cell_Size * Cell_Size * 8;
         Left_On_Screen : constant Integer := PX - C_Left;
         Top_On_Screen  : constant Integer := PY - C_Top;
      begin
         for X in 0 .. Cell_Size - 1 loop
            for Y in 0 .. Cell_Size - 1 loop
               if Left_On_Screen + X in 0 .. Screen.Width - 1
                 and then
                  Top_On_Screen + Y in 0 .. Screen.Height - 1
               then
                  declare
                     Pix : constant UInt16 := Tiles (Tile_Offset + X + Y * Cell_Size);
                  begin
                     if Pix /= 0 then
                        FB ((Left_On_Screen + X) + (Top_On_Screen + Y) * Screen.Width)
                          := Pix;
                     end if;
                  end;
               end if;
            end loop;
         end loop;
      end Draw_Player;

      ---------------
      -- Draw_Cell --
      ---------------

      procedure Draw_Cell (CX, CY : Natural) is

         Tile_Offset : constant Natural :=
           Cell_Size * Cell_Size * (case Get_Cell (CX, CY) is
                                       when Empty   => 0,
                                       when Dirt    => (if CY = 3 then 1 else 2),
                                       when Coal    => 3,
                                       when Iron    => 4,
                                       when Gold    => 5,
                                       when Diamond => 6,
                                       when Rock   => 7);

         Left_On_Screen : constant Integer := (CX * Cell_Size) - C_Left;
         Top_On_Screen  : constant Integer := (CY * Cell_Size) - C_Top;
      begin
         for X in 0 .. Cell_Size - 1 loop
            for Y in 0 .. Cell_Size - 1 loop
               if Left_On_Screen + X in 0 .. Screen.Width - 1
                 and then
                  Top_On_Screen + Y in 0 .. Screen.Height - 1
               then
                  FB ((Left_On_Screen + X) + (Top_On_Screen + Y) * Screen.Width)
                    := Tiles (Tile_Offset + X + Y * Cell_Size);
               end if;
            end loop;
         end loop;
      end Draw_Cell;

   begin

      for X in 0 .. (Screen.Width / Cell_Size) loop
         if Left_Cell + X < Ground_Width then
            for Y in 0 .. (Screen.Height / Cell_Size) loop
               if Top_Cell + Y < Ground_Depth then
                  Draw_Cell (Left_Cell + X, Top_Cell + Y);
               end if;
            end loop;
         end if;
      end loop;

      Player.Draw (FB);
      Draw_Player (Player_X - Cell_Size / 2, Player_Y - Cell_Size / 2);
   end Draw_Screen;

   ---------
   -- Run --
   ---------

   procedure Run is
      Period : constant Time.Time_Ms := 1000 / 30;
      Next_Release : Time.Time_Ms;
      Flip : Boolean := True;

   begin
      Next_Release := Time.Clock;

      Sound.Play_Gameplay;

      Generate_Ground;
      Player.Spawn;

      loop
         Controls.Scan;

         if Controls.Pressed (Controls.Up) then
            Player.Move_Up;
         elsif Controls.Pressed (Controls.Down) then
            Player.Move_Down;
         end if;
         if Controls.Pressed (Controls.Left) then
            Player.Move_Left;
         elsif Controls.Pressed (Controls.Right) then
            Player.Move_Right;
         end if;
         if Controls.Pressed (Controls.A) then
            Player.Drill;
         end if;

         if Flip then
            Refresh_Screen (FB1'Access);
            Draw_Screen (FB2);
         else
            Refresh_Screen (FB2'Access);
            Draw_Screen (FB1);
         end if;
         Flip := not Flip;

         Player.Update;
         Sound.Tick;

         Time.Delay_Until (Next_Release);
         Next_Release := Next_Release + Period;
      end loop;
   end Run;

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
end Motherload;
