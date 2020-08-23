--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with PyGamer; use PyGamer;
with HAL; use HAL;
with Sound;
with PyGamer.Controls;
with PyGamer.Time;

with Parameters;
with World; use World;
with Player;
with Cargo_Menu;
with Equipment_Menu;
with Render;

package body Motherload is

   -----------------
   -- Draw_Screen --
   -----------------

   procedure Draw_Screen (FB : in out HAL.UInt16_Array) is
   begin
      Render.Draw_World (FB);
   end Draw_Screen;

   ---------
   -- Run --
   ---------

   procedure Run is
      Period : constant Time.Time_Ms := Parameters.Frame_Period;
      Next_Release : Time.Time_Ms;

   begin
      Next_Release := Time.Clock;

      Sound.Stop_Music;

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

         if Controls.Falling (Controls.Sel) then
            Cargo_Menu.Run;
            Next_Release := Time.Clock;
         end if;

         --  Fuel pump
         if Player.Position.Y in 16 * 2 .. 16 * 3
           and then
             Player.Position.X in 16 * 25 .. 16 * 26
         then
            Equipment_Menu.Run;
            Next_Release := Time.Clock;
            Player.Move ((Parameters.Spawn_X, Parameters.Spawn_Y));
         end if;

         if Render.Flip then
            Render.Refresh_Screen (Render.FB1'Access);
            Draw_Screen (Render.FB2);
         else
            Render.Refresh_Screen (Render.FB2'Access);
            Draw_Screen (Render.FB1);
         end if;
         Render.Flip := not Render.Flip;

         Player.Update;
         Sound.Tick;

         Time.Delay_Until (Next_Release);
         Next_Release := Next_Release + Period;
      end loop;
   end Run;
end Motherload;
