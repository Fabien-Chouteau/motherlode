--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with HAL; use HAL;

with PyGamer; use PyGamer;
with PyGamer.Time;
with PyGamer.Controls;
with PyGamer.Screen;

with Parameters; use Parameters;
with Render;
with World;
with Player;
with Sound;

package body Equipment_Menu is

   use type Parameters.Equipment;

   Selected : Parameters.Equipment := Parameters.Equipment'First;

   ---------
   -- Img --
   ---------

   function Img (Kind : Parameters.Equipment) return String
   is (case Kind is
          when Engine => "Engine",
          when Cargo  => "Cargo",
          when Tank   => "Tank",
          when Drill  => "Drill");

   -----------------
   -- Draw_Screen --
   -----------------

   procedure Draw_Screen (FB : in out HAL.UInt16_Array) is

      Y_Offest :  Natural := 16;
   begin

      FB := (others => 0);

      declare
         Str : String := Player.Money'Img;
      begin
         Str (Str'First) := '$';
         Render.Draw_String_Left (FB, Str, Screen.Width - 1, 1);
      end;

      for Kind in Parameters.Equipment loop
         Render.Draw_String (FB, Img (Kind),
                             X => 0,
                             Y => Y_Offest + 4);

         if Selected = Kind then
            Render.Draw_H_Line (FB,
                                0, Y_Offest,
                                Len   => 50,
                                Color => UInt16'Last);

            Render.Draw_H_Line (FB,
                                0, Y_Offest + World.Cell_Size,
                                Len   => 50,
                                Color => UInt16'Last);

            Render.Draw_V_Line (FB,
                                50, 16,
                                Len  => Y_Offest - 16,
                                Color => UInt16'Last);
            Render.Draw_V_Line (FB,
                                50,
                                Y_Offest + 16,
                                Len   => Screen.Height - Y_Offest - 16 * 3,
                                Color => UInt16'Last);

            if Player.Level (Kind) = Equipment_Level'Last then
               Render.Draw_String_Center
                 (FB, "Max level",
                  X   => 55 + (Screen.Width - 55) / 2,
                  Y   => Screen.Height / 2 - 8);
            else
               Render.Draw_String_Left
                 (FB, "Next upgrade:",
                  X   => Screen.Width - 1,
                  Y   => 5 + 16 * 1);

               Render.Draw_String_Left
                 (FB, "level" & Equipment_Level'Image (Player.Level (Kind) + 1),
                  X   => Screen.Width - 1,
                  Y   => 5 + 16 * 2);

               Render.Draw_String_Left
                 (FB, "Cost:",
                  X   => Screen.Width - 1,
                  Y   => 5 + 16 * 3);

               Render.Draw_String_Left
                 (FB, "$" & Parameters.Price (Kind, Player.Level (Kind) + 1)'Img,
                  X   => Screen.Width - 1,
                  Y   => 5 + 16 * 4);
            end if;
         end if;

         Y_Offest := Y_Offest + 20;
      end loop;

      Render.Draw_H_Line (FB,
                          50, Y_Offest,
                          Len   => Screen.Width - 1 - 50,
                          Color => UInt16'Last);
      Render.Draw_H_Line (FB,
                          50, 16,
                          Len   => Screen.Width - 1 - 50,
                          Color => UInt16'Last);

      Render.Draw_String (FB, "Press A to upgrade",
                          X => 0,
                          Y => Y_Offest + 4);
      Render.Draw_String (FB, "Press B to exit",
                          X => 0,
                          Y => Y_Offest + 4 + 16);
   end Draw_Screen;

   ---------
   -- Run --
   ---------

   procedure Run is

      Period : constant Time.Time_Ms := Parameters.Frame_Period;
      Next_Release : Time.Time_Ms;

   begin
      Next_Release := Time.Clock;

      loop
         Controls.Scan;

         if Controls.Falling (Controls.Down) then
            if Selected = Parameters.Equipment'Last then
               Selected := Parameters.Equipment'First;
            else
               Selected := Parameters.Equipment'Succ (Selected);
            end if;
         elsif Controls.Falling (Controls.Up) then
            if Selected = Parameters.Equipment'First then
               Selected := Parameters.Equipment'Last;
            else
               Selected := Parameters.Equipment'Pred (Selected);
            end if;
         end if;

         if Controls.Falling (Controls.A) then
            Player.Upgrade (Selected);
         end if;

         if Controls.Falling (Controls.B) then
            return;
         end if;

         if Render.Flip then
            Render.Refresh_Screen (Render.FB1'Access);
            Draw_Screen (Render.FB2);
         else
            Render.Refresh_Screen (Render.FB2'Access);
            Draw_Screen (Render.FB1);
         end if;
         Render.Flip := not Render.Flip;

         Sound.Tick;

         Time.Delay_Until (Next_Release);
         Next_Release := Next_Release + Period;
      end loop;
   end Run;

end Equipment_Menu;
