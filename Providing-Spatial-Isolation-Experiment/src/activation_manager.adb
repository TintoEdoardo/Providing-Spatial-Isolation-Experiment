------------------------------------------------------------------------------
--                                                                          --
--                            ACTIVATION MANAGER                            --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;

package body Activation_Manager is

   procedure Synchronize_Activation_Cyclic
     (Time : out Ada.Real_Time.Time) is
   begin
      Time := Activation_Time;
      delay until Activation_Time;
   end Synchronize_Activation_Cyclic;
   
   procedure Initialize is
   begin
      System_Start_Time := Ada.Real_Time.Clock;
      Task_Start_Time   := Ada.Real_Time.Milliseconds (Relative_Offset);
      Activation_Time   := System_Start_Time + Task_Start_Time;
   end Initialize;
begin
   Initialize;
end Activation_Manager;
