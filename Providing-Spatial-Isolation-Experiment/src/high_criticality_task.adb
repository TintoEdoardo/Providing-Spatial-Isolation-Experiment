------------------------------------------------------------------------------
--                                                                          --
--                           HIGH CRITICALITY TASK                          --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Synchronous_Task_Control;
with Activation_Manager;
with Experiment_Parameters;
with High_Criticality_Task_Workload;
pragma Warnings (Off);
with System.BB.Time;
with System.Task_Primitives.Operations;
pragma Warnings (On);


package body High_Criticality_Task is

   task body High_Criticality_Task is
      Next_Activation     : Ada.Real_Time.Time;
      Task_Period         : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds (Period);
      Iteration_Counter   : Positive;
      Iteration_Limit     : Positive;
   begin
      System.Task_Primitives.Operations.Initialize_HI_Crit_Task
        (System.Task_Primitives.Operations.Self,
         Id, 
         Hosting_Migrating_Tasks_Priority,
         System.BB.Time.Milliseconds (Low_Critical_Budget),
         System.BB.Time.Milliseconds (High_Critical_Budget),
         Period);
      
      Activation_Manager.Synchronize_Activation_Cyclic (Next_Activation);
      Iteration_Counter := 1;
      Iteration_Limit   := Experiment_Parameters.Iteration_Limit;
      loop
         --  Synchronization code
         Ada.Synchronous_Task_Control.Suspend_Until_True
           (Activation_Manager.Could_Send);
         Next_Activation := Next_Activation + Task_Period;
         
         --  Task workload
         if (Iteration_Counter <= Iteration_Limit) then
            
            High_Criticality_Task_Workload.Workload_1;
            
            Iteration_Counter := Iteration_Counter + 1;
         end if;
         
         delay until Next_Activation;
      end loop;
   end High_Criticality_Task;

end High_Criticality_Task;
