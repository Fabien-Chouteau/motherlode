--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with HAL; use HAL;

with PyGamer; use PyGamer;
with PyGamer.Time;
with PyGamer.Controls; use PyGamer.Controls;
with PyGamer.Screen;

with Parameters;
with Render; use Render;
with World; use World;
with Sound;

package body Title_Screen is

   Selected : Boolean := True;
   Credits : Boolean := False;
   -----------------
   -- Draw_Screen --
   -----------------

   procedure Draw_Screen (FB : in out HAL.UInt16_Array) is
   begin
      FB := (others => 0);

      if Credits then
         Draw_String_Center (FB, "- Credits -", Screen.Width / 2, 20);

         Draw_String (FB, "Original game:", 0, 30);
         Draw_String (FB, "   xgenstudios.com", 0, 40);
         Draw_String (FB, "Art:  kenney.nl", 0, 55);
         Draw_String (FB, "Font: nfggames.com", 0, 70);
         Draw_String (FB, "Code: Fabien.C", 0, 85);
      else

         Draw_String_Center (FB, "--------------", Screen.Width / 2, 25);
         Draw_String_Center (FB, "- Motherlode -", Screen.Width / 2, 25 + 8);
         Draw_String_Center (FB, "--------------", Screen.Width / 2, 25 + 16);

         Draw_String (FB, "New game", Screen.Width / 3, 25 + 48);
         Draw_String (FB, "Credits", Screen.Width / 3, 25 + 64);

         if Selected then
            Draw_Tile (FB, Screen.Width / 3 - 20, 25 + 48 - 4, 8);
         else
            Draw_Tile (FB, Screen.Width / 3 - 20, 25 + 64 - 4, 8);
         end if;

         for X in 0 .. (Screen.Width / Cell_Size) - 1 loop
            Draw_Tile (FB, X * Cell_Size, 7 * Cell_Size, 1);
         end loop;
      end if;
   end Draw_Screen;

   ---------
   -- Run --
   ---------

   procedure Run is

      Period : constant Time.Time_Ms := Parameters.Frame_Period;
      Next_Release : Time.Time_Ms;

   begin
      Next_Release := Time.Clock;

      Sound.Play_Music;

      --  First scan to avoid detectin a falling edge when a button is pressed
      --  during reset.
      Controls.Scan;

      loop
         Controls.Scan;

         if Falling (A)
           or else
            Falling (B)
           or else
            Falling (Start)
           or else
            Falling (Sel)
         then
            if Credits then
               Credits := False;
            elsif Selected then
               return;
            else
               Credits := True;
            end if;
         end if;

         if Falling (Down)
           or else
            Controls.Falling (Controls.Up)
         then
            Selected := not Selected;
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

end Title_Screen;
