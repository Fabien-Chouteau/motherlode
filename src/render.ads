--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with HAL; use HAL;

with PyGamer; use PyGamer;
with PyGamer.Screen;

with World;

package Render is

   subtype Frame_Buffer
     is HAL.UInt16_Array (0 .. (Screen.Width * Screen.Height) - 1);

   procedure Draw_Cell (FB   : in out Frame_Buffer;
                        X, Y : Integer;
                        Kind : World.Cell_Kind);

   procedure Draw_Tile (FB   : in out Frame_Buffer;
                        X, Y : Integer;
                        Id   : Natural);

   procedure Draw_World (FB : in out Frame_Buffer);

   procedure Draw_Player (FB   : in out Frame_Buffer;
                          X, Y : Integer);


   procedure Draw_Char (FB    : in out Frame_Buffer;
                        Char  : Character;
                        X, Y  : Natural);

   procedure Draw_String (FB    : in out Frame_Buffer;
                          Str   : String;
                          X, Y  : Natural);
   --  Draw a string with X, Y being at the top left

   procedure Draw_String_Left (FB    : in out Frame_Buffer;
                                 Str   : String;
                                 X, Y  : Natural);
   --  Draw a string with X, Y being at the top right

   procedure Draw_String_Center (FB    : in out Frame_Buffer;
                                 Str   : String;
                                 X, Y  : Natural);
   --  Draw a string with X, Y being at the center of the text

   procedure Draw_H_Line (FB        : in out Frame_Buffer;
                          X, Y, Len : Natural;
                          Color     : UInt16);

   procedure Draw_V_Line (FB        : in out Frame_Buffer;
                          X, Y, Len : Natural;
                          Color     : UInt16);

   function RGB565 (R, G, B : HAL.UInt8) return HAL.UInt16;

   FB1 : aliased HAL.UInt16_Array := (0 .. (Screen.Width * Screen.Height) - 1 => 0);
   FB2 : aliased HAL.UInt16_Array := (0 .. (Screen.Width * Screen.Height) - 1 => 0);
   Flip : Boolean := True;

   procedure Refresh_Screen (Acc : not null Screen.Framebuffer_Access);

end Render;
