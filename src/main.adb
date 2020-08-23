--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with Motherload;
with Title_Screen;

with Arith_64;
pragma Unreferenced (Arith_64);

procedure Main is
begin

   loop
      Title_Screen.Run;
      Motherload.Run;
   end loop;
end Main;
