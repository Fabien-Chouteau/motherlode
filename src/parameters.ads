--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with World;

package Parameters is

   FPS : constant := 30;
   Frame_Period : constant := 1000 / FPS;

   type Equipment is (Engine, Cargo, Tank, Drill);
   type Equipment_Level is range 1 .. 7;


   Price : constant array (Equipment, Equipment_Level) of Natural :=
     (Engine => (0, 2_000, 6_000, 15_000, 20_000, 45_000, 80_000),
      Cargo  => (0, 2_000, 6_000, 15_000, 20_000, 45_000, 80_000),
      Tank   => (0, 2_000, 6_000, 15_000, 20_000, 45_000, 80_000),
      Drill  => (0, 2_000, 6_000, 15_000, 20_000, 45_000, 80_000));

   Engine_Thrust : constant array (Equipment_Level) of Float :=
   (1 =>    75_000.0,
    2 =>   150_000.0,
    3 =>   250_000.0,
    4 =>   400_000.0,
    5 =>   550_000.0,
    6 =>   800_000.0,
    7 => 1_300_000.0);

   Cargo_Capacity : constant array (Equipment_Level) of Natural :=
   (1 => 10,
    2 => 20,
    3 => 30,
    4 => 40,
    5 => 50,
    6 => 60,
    7 => 70);

   Tank_Capacity : constant array (Equipment_Level) of Natural :=
   (1 => 15,
    2 => 20,
    3 => 25,
    4 => 30,
    5 => 35,
    6 => 45,
    7 => 70);

   Value : constant array (World.Valuable_Cell) of Natural :=
     (World.Coal    => 30,
      World.Iron    => 100,
      World.Gold    => 250,
      World.Diamond => 750);

   Weight : constant array (World.Valuable_Cell) of Natural :=
     (World.Coal    => 2,
      World.Iron    => 4,
      World.Gold    => 8,
      World.Diamond => 12);

   Empty_Mass    : constant := 90.0;
   Gravity       : constant := 500.0;

   Fuel_Per_Step : constant := 0.01;
   Fuel_Price    : constant := 10.0;
   Start_Fuel    : constant := 5.0;

   Spawn_X : constant := 20 * 17;
   Spawn_Y : constant := 8;
end Parameters;
