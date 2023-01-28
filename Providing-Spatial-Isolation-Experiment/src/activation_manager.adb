------------------------------------------------------------------------------
--                                                                          --
--                            ACTIVATION MANAGER                            --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
pragma Warnings (Off);
with System.BB.Time;
with System.Task_Primitives.Operations;
pragma Warnings (On);

package body Activation_Manager is

   task body Activator is
      Task_Period        : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds (Period);
      Minimum_Separation : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds (Period / 4);
      Step_One           : Ada.Real_Time.Time;
      Step_Two           : Ada.Real_Time.Time;
      Step_Three         : Ada.Real_Time.Time;
      Next_Activation    : Ada.Real_Time.Time;
   begin      
      System.Task_Primitives.Operations.Initialize_HI_Crit_Task
        (System.Task_Primitives.Operations.Self,
         Id, 
         Hosting_Migrating_Tasks_Priority,
         System.BB.Time.Milliseconds (Low_Critical_Budget),
         System.BB.Time.Milliseconds (High_Critical_Budget),
         Period);
      
      Activation_Manager.Synchronize_Activation_Cyclic (Next_Activation);
      Step_One   := Next_Activation;
      Step_Two   := Next_Activation;
      Step_Three := Next_Activation;
      
      loop
         --  Synchronization code
         Step_One        := Next_Activation   + Minimum_Separation;
         Step_Two        := Next_Activation   + 2 * Minimum_Separation;
         Step_Three      := Next_Activation   + 3 * Minimum_Separation;
         Next_Activation := Next_Activation + Task_Period;
         
         Ada.Synchronous_Task_Control.Set_False (Could_Receive);
         --  Here, the following properties hold: 
         --  Could_Send    = False
         --  Could_Receive = False
         
         delay until Step_One;
         Ada.Synchronous_Task_Control.Set_True (Could_Send);
         --  Here, the following properties hold: 
         --  Could_Send    = True
         --  Could_Receive = False
         
         delay until Step_Two;
         Ada.Synchronous_Task_Control.Set_False (Could_Send);
         --  Here, the following properties hold: 
         --  Could_Send    = False
         --  Could_Receive = False
         
         delay until Step_Three;
         Ada.Synchronous_Task_Control.Set_True (Could_Receive);
         --  Here, the following properties hold: 
         --  Could_Send    = False
         --  Could_Receive = True

         delay until Next_Activation;
      end loop;
   end Activator;
   
   procedure Synchronize_Activation_Cyclic
     (Time : in out Ada.Real_Time.Time) is
   begin
      Time := Ada.Real_Time.Time_First;
   end Synchronize_Activation_Cyclic;
   
end Activation_Manager;
