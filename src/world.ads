--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

package World is

   Ground_Width : constant := 30;
   Ground_Depth : constant := 600;

   type Cell_Kind is (Empty, Dirt, Rock, Coal, Iron, Gold, Diamond)
     with Size => 4;

   subtype Valuable_Cell is Cell_Kind range Coal .. Diamond;

   Cell_Size : constant := 16;

   type Ground_Type is array (0 .. (Ground_Depth * Ground_Width) - 1) of Cell_Kind
     with Component_Size => Cell_Kind'Size,
     Size => Ground_Depth * Ground_Width * Cell_Kind'Size;

   Ground : Ground_Type := (others => Empty);

   function Get_Cell (CX, CY : Natural) return Cell_Kind;
   pragma Inline (Get_Cell);

   procedure Generate_Ground;

   function Collides (X, Y : Integer) return Boolean;

end World;
