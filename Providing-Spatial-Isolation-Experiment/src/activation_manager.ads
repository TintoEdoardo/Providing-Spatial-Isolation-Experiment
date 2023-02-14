------------------------------------------------------------------------------
--                                                                          --
--                            ACTIVATION MANAGER                            --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Real_Time;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;

package Activation_Manager is
   pragma Elaborate_Body;

   Experiment_Is_Completed : Suspension_Object;

   System_Start_Time : Ada.Real_Time.Time;
   Task_Start_Time   : Ada.Real_Time.Time_Span;
   Relative_Offset   : constant Natural := 100;
   Activation_Time   : Ada.Real_Time.Time;

   procedure Synchronize_Activation_Cyclic (Time : out Ada.Real_Time.Time);

end Activation_Manager;
