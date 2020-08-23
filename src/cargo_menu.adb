--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with HAL; use HAL;

with PyGamer; use PyGamer;
with PyGamer.Time;
with PyGamer.Controls;
with PyGamer.Screen;

with Parameters;
with Render;
with World;
with Player;
with Sound;

package body Cargo_Menu is

   use type World.Valuable_Cell;

   Selected : World.Valuable_Cell := World.Valuable_Cell'First;

   -----------------
   -- Draw_Screen --
   -----------------

   procedure Draw_Screen (FB : in out HAL.UInt16_Array) is

      Cargo_X_Offset : constant Natural := 0;
      Cargo_Y_Offest :  Natural := 0;

      W_Column : constant Natural := Screen.Width - 1;
      V_Column : constant Natural := W_Column - 8 * 8;
      Q_Column : constant Natural := V_Column - 7 * 8;
   begin

      FB := (others => 0);

      Render.Draw_String_Left (FB, "Qty",
                               X     => Q_Column,
                               Y     => Cargo_Y_Offest + 4);
      Render.Draw_String_Left (FB, "Value",
                               X     => V_Column,
                               Y     => Cargo_Y_Offest + 4);
      Render.Draw_String_Left (FB, "Weight",
                               X     => W_Column,
                               Y     => Cargo_Y_Offest + 4);

      Cargo_Y_Offest := Cargo_Y_Offest + 20;


      for Kind in World.Valuable_Cell loop
         declare
            Qty : constant Natural := Player.Quantity (Kind);
            Value : constant Natural := Qty * Parameters.Value (Kind);
            Weight : constant Natural := Qty * Parameters.Weight (Kind);
         begin

            Render.Draw_Cell (FB, Cargo_X_Offset, Cargo_Y_Offest, Kind);
            Render.Draw_String_Left (FB    => FB,
                                     Str   => Integer'Image (Qty),
                                     X     => Q_Column,
                                     Y     => Cargo_Y_Offest + 4);
            Render.Draw_String_Left (FB    => FB,
                                     Str   => Integer'Image (Value),
                                     X     => V_Column,
                                     Y     => Cargo_Y_Offest + 4);
            Render.Draw_String_Left (FB    => FB,
                                     Str   => Integer'Image (Weight),
                                     X     => W_Column,
                                     Y     => Cargo_Y_Offest + 4);

         end;

         if Selected = Kind then
            Render.Draw_H_Line (FB,
                                Cargo_X_Offset, Cargo_Y_Offest,
                                Len   => Screen.Width - Cargo_X_Offset - 1,
                                Color => UInt16'Last);

            Render.Draw_H_Line (FB,
                                Cargo_X_Offset, Cargo_Y_Offest + World.Cell_Size,
                                Len   => Screen.Width - Cargo_X_Offset - 1,
                                Color => UInt16'Last);
         end if;


         Cargo_Y_Offest := Cargo_Y_Offest + 20;
      end loop;

      Render.Draw_String (FB    => FB,
                          Str   => "Press A to drop",
                          X     => 0,
                          Y     => Cargo_Y_Offest + 4);

      Render.Draw_String (FB    => FB,
                          Str   => "Press Select to exit",
                          X     => 0,
                          Y     => Cargo_Y_Offest + 4 + 16);

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

         if Controls.Falling (Controls.Sel) then
            return;
         end if;

         if Controls.Falling (Controls.A) then
            Player.Drop (Selected);
         end if;

         if Controls.Falling (Controls.Down) then
            if Selected = World.Valuable_Cell'Last then
               Selected := World.Valuable_Cell'First;
            else
               Selected := World.Valuable_Cell'Succ (Selected);
            end if;
         elsif Controls.Falling (Controls.Up) then
            if Selected = World.Valuable_Cell'First then
               Selected := World.Valuable_Cell'Last;
            else
               Selected := World.Valuable_Cell'Pred (Selected);
            end if;
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

end Cargo_Menu;
