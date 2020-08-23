--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with Interfaces;

with VirtAPU; use VirtAPU;

with PyGamer.Audio; use PyGamer.Audio;

package body Sound is

   C_16th     : constant Command := (Wait_Ticks, 1);
   C_8th     : constant Command := (Wait_Ticks, C_16th.Ticks * 2);
   C_Quarter : constant Command := (Wait_Ticks, C_8th.Ticks * 2);
   C_Half    : constant Command := (Wait_Ticks, C_Quarter.Ticks * 2);
   --  C_Whole   : constant Command := (Wait_Ticks, C_Half.Ticks * 2);

   Coin_Seq : aliased constant Command_Array :=
     ((Set_Decay, 10),
      (Set_Mode, Pulse),
      (Set_Width, 25),
      (Set_Sweep, None, 1, 0),
      B4,
      (Wait_Ticks, 3),
      E5,
      (Wait_Ticks, 5),
      Off
     );

   Gun_Seq : aliased constant Command_Array :=
     ((Set_Mode, Noise_1),
      (Set_Decay, 15),
      (Set_Sweep, Up, 13, 0),
      (Set_Mode, Noise_1),
      (Note_On, 200.0),
      Off
     );

   Kick : aliased constant Command_Array :=
     ((Set_Decay, 6),
      (Set_Sweep, Up, 7, 0),
      (Set_Mode, Noise_2),
      (Note_On, 150.0),
      Off
     );

   Snare : aliased constant Command_Array :=
     ((Set_Decay, 6),
      (Set_Mode, Noise_1),
      (Note_On, 2000.0),
      Off
     );

   Hi_Hat : aliased constant Command_Array :=
     ((Set_Decay, 2),
      (Set_Mode, Noise_1),
      (Note_On, 10000.0),
      Off
     );

   Beat_1 : constant Command_Array :=
     Kick & C_Half &
     Hi_Hat & C_Half &
     Snare & C_Half &
     Hi_Hat & C_Half &
     Kick & C_Half &
     Hi_Hat & C_Half &
     Snare & C_Half &
     Hi_Hat & C_Half;

   Beat_2 : constant Command_Array :=
     Kick & C_Half &
     Hi_Hat & C_Half &
     Snare & C_Half &
     Hi_Hat & C_Half &
     Kick & C_Half &
     Hi_Hat & C_Half &
     Snare & C_Half &
     Snare & C_Half;

   Beat_3 : constant Command_Array :=
     Kick & C_Half &
     Hi_Hat & C_Half &
     Snare & C_Half &
     Hi_Hat & C_Half &
     Kick & C_Half &
     Hi_Hat & C_Half &
     Snare & C_Half &
     Snare & C_Quarter &
     Snare & C_Quarter;

   Drums_Seq : aliased constant Command_Array :=
     Beat_1 & Beat_2 & Beat_3 & Beat_2;

   Bass_1 : constant Command_Array :=
     C2 & C_Half & Off &
     C_Half &
     C2 & C_Half & Off &
     C_Half &
     C2 & C_Half & Off &
     Ds2 & C_Half & Off &
     C_Half &
     Gs2 & C_Half & Off;

   Bass_2 : constant Command_Array :=
     C_Half &
     Ds2 & C_Half & Off &
     C_Half &
     Fs2 & C_Half & Off &
     C_Half &
     Ds2 & C_Half & Off &
     Fs2 & C_Half & Off &
     Ds2 & C_Half & Off;

   Bass_3 : constant Command_Array :=
     C_Half &
     Ds2 & C_Half & Off &
     C_Half &
     Fs2 & C_Half & Off &
     C_Half &
     Gs2 & C_Half & Off &
     Fs2 & C_Half & Off &
     C_Half;

   Bass_Seq : aliased constant Command_Array :=
     Bass_1 & Bass_2 & Bass_1 & Bass_3;

   Sample_Rate : constant Sample_Rate_Kind := SR_22050;
   APU : VirtAPU.Instance (3, 22_050);

   Player_FX : constant VirtAPU.Channel_ID := 1;
   Drums     : constant VirtAPU.Channel_ID := 2;
   Bass      : constant VirtAPU.Channel_ID := 3;

   procedure Next_Samples is new VirtAPU.Next_Samples_UInt
     (Interfaces.Unsigned_16, PyGamer.Audio.Data_Array);

   procedure Audio_Callback (Left, Right : out PyGamer.Audio.Data_Array);

   --------------------
   -- Audio_Callback --
   --------------------

   procedure Audio_Callback (Left, Right : out PyGamer.Audio.Data_Array) is
   begin
      Next_Samples (APU, Left);
      Right := Left;
   end Audio_Callback;

   ----------
   -- Tick --
   ----------

   procedure Tick is
   begin
      APU.Tick;
   end Tick;

   ---------------
   -- Play_Coin --
   ---------------

   procedure Play_Coin is
   begin
      APU.Set_Volume (Player_FX, 30);
      APU.Run (Player_FX, Coin_Seq'Access);
   end Play_Coin;

   ----------------
   -- Play_Drill --
   ----------------

   procedure Play_Drill is
   begin
      APU.Set_Volume (Player_FX, 60);
      APU.Run (Player_FX, Gun_Seq'Access);
   end Play_Drill;

   ----------------
   -- Play_Music --
   ----------------

   procedure Play_Music is
   begin
      APU.Run (Drums, Drums_Seq'Access, Looping => True);
      APU.Set_Volume (Drums, 10);

      APU.Set_Mode (Bass, Triangle);
      APU.Set_Decay (Bass, 7);
      APU.Set_Volume (Bass, 90);
      APU.Run (Bass, Bass_Seq'Access, Looping => True);
   end Play_Music;

   ----------------
   -- Stop_Music --
   ----------------

   procedure Stop_Music is
   begin
      APU.Run (Drums, VirtAPU.Empty_Seq);
      APU.Set_Volume (Drums, 0);
      APU.Note_Off (Drums);
      APU.Run (Bass, VirtAPU.Empty_Seq);
      APU.Set_Volume (Bass, 0);
      APU.Note_Off (Bass);
   end Stop_Music;

begin
   PyGamer.Audio.Set_Callback (Audio_Callback'Access, Sample_Rate);

   APU.Set_Rhythm (120, 30);
end Sound;
