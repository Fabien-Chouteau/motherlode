--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with HAL; use HAL;

with PyGamer.Time;

package body World is

   Seed : UInt32 := 5323;

   ----------
   -- Rand --
   ----------

   function Rand return Float is
   begin
      Seed := 8253729 * Seed + 2396403;
      return Float (Seed mod 32767) / 32767.0;
   end Rand;

   --------------
   -- Get_Cell --
   --------------

   function Get_Cell (CX, CY : Natural) return Cell_Kind is
   begin
      return Ground (CX + CY * Ground_Width);
   end Get_Cell;

   -----------------
   -- Choose_Cell --
   -----------------

   function Choose_Cell (CX, CY : Natural) return Cell_Kind is
      Proba : array (Cell_Kind) of Natural;

      ----------------
      -- From_Proba --
      ----------------

      function From_Proba return Cell_Kind is
         Total : Natural := 0;
         Value : Natural := 0;
      begin
         for Elt of Proba loop
            Total := Total + Elt;
         end loop;

         Value := Natural (Float (Total) * Rand);

         Total := 0;
         for Kind in Cell_Kind loop
            if Value in Total .. Total + Proba (Kind) then
               return Kind;
            else
               Total := Total + Proba (Kind);
            end if;
         end loop;
         return Rock;
      end From_Proba;
   begin
      if CY < 3 then
         return Empty;
      elsif CY = 3 then
         return Dirt;
      else
         case CY is
            when 0 .. 10 =>
               Proba := (Empty   => 13,
                         Dirt    => 70,
                         Coal    => 15,
                         Iron    => 2,
                         Gold    => 0,
                         Diamond => 0,
                         Rock    => 0);
            when 11 .. 50 =>
               Proba := (Empty   => 8,
                         Dirt    => 67,
                         Coal    => 15,
                         Iron    => 7,
                         Gold    => 0,
                         Diamond => 0,
                         Rock    => 3);
            when 51 .. 100 =>
               Proba := (Empty   => 8,
                         Dirt    => 50,
                         Coal    => 15,
                         Iron    => 20,
                         Gold    => 10,
                         Diamond => 2,
                         Rock    => 5);
            when 101 .. 200 =>
               Proba := (Empty   => 15,
                         Dirt    => 40,
                         Coal    => 5,
                         Iron    => 10,
                         Gold    => 15,
                         Diamond => 5,
                         Rock    => 10);
            when 201 .. 350 =>
               Proba := (Empty   => 10,
                         Dirt    => 35,
                         Coal    => 0,
                         Iron    => 10,
                         Gold    => 15,
                         Diamond => 15,
                         Rock    => 15);
            when others =>
               Proba := (Empty   => 0,
                         Dirt    => 0,
                         Coal    => 0,
                         Iron    => 0,
                         Gold    => 25,
                         Diamond => 25,
                         Rock    => 50);
         end case;

         --  Neighboor Bonus
         if CX > 0 then
            Proba (Get_Cell (CX - 1, CY)) := Proba (Get_Cell (CX - 1, CY)) + 20;
         end if;
         if CY > 0 then
            Proba (Get_Cell (CX, CY - 1)) := Proba (Get_Cell (CX, CY - 1)) + 20;
         end if;
         if CX < Ground_Width - 1 then
            Proba (Get_Cell (CX + 1, CY)) := Proba (Get_Cell (CX + 1, CY)) + 20;
         end if;
         if CY < Ground_Depth - 1 then
            Proba (Get_Cell (CX, CY - 1)) := Proba (Get_Cell (CX, CY - 1)) + 20;
         end if;

         return From_Proba;
      end if;
   end Choose_Cell;

   ---------------------
   -- Generate_Ground --
   ---------------------

   procedure Generate_Ground is
   begin
      Seed := 5000 + UInt32 (PyGamer.Time.Clock mod 323);

      for X in 0 .. Ground_Width - 1 loop
         for Y in 0 .. Ground_Depth - 1 loop
            Ground (X + Y * Ground_Width) := Choose_Cell (X, Y);
         end loop;
      end loop;
   end Generate_Ground;

   --------------
   -- Collides --
   --------------

   function Collides (X, Y : Integer) return Boolean is
   begin
      if X < 0 or else X >= Cell_Size * Ground_Width
        or else
          Y < 0 or else Y >= Cell_Size * Ground_Depth
      then
         --  Collides when out of bounds
         return True;
      end if;

      return Ground ((X / Cell_Size) + (Y / Cell_Size) * Ground_Width) /= Empty;
   end Collides;

end World;
