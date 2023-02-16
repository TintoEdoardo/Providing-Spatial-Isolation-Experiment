------------------------------------------------------------------------------
--                                                                          --
--                           HIGH CRITICALITY TASK                          --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;
with Activation_Manager;
with Experiment_Parameters;
with High_Criticality_Task_Workload;
pragma Warnings (Off);
with System.BB.Time;
with System.Task_Primitives.Operations;
pragma Warnings (On);

package body High_Criticality_Task is
   
   task body High_Criticality_Task_Starter is
      Next_Activation     : Ada.Real_Time.Time;
      Task_Period         : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds (Period);
   begin
      
      System.Task_Primitives.Operations.Initialize_HI_Crit_Task
        (System.Task_Primitives.Operations.Self,
         Id, 
         Hosting_Migrating_Tasks_Priority,
         System.BB.Time.Milliseconds (Low_Critical_Budget),
         System.BB.Time.Milliseconds (High_Critical_Budget),
         Period);

      Activation_Manager.Synchronize_Activation_Cyclic (Next_Activation);
      
      loop
         
         --  Synchronization code
         Next_Activation := Next_Activation + Task_Period;
         
         --  Task workload
         if (Experiment_Parameters.Workload_Type = 1) then
            High_Criticality_Task_Workload.Workload_1_1;
            
         elsif (Experiment_Parameters.Workload_Type = 2) then
            High_Criticality_Task_Workload.Workload_2_1;
         
         elsif (Experiment_Parameters.Workload_Type = 3) then
            High_Criticality_Task_Workload.Workload_3_1;
         
         else
            Ada.Text_IO.Put_Line ("Unexpected workload received");
         end if;
         
         delay until Next_Activation;

      end loop;

   end High_Criticality_Task_Starter;

   task body High_Criticality_Task is
      Next_Activation     : Ada.Real_Time.Time;
      Task_Period         : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds (Period);
      Task_Delay          : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds
          (Period / Experiment_Parameters.Taskset_Cardinality * Id);
   begin
      
      System.Task_Primitives.Operations.Initialize_HI_Crit_Task
        (System.Task_Primitives.Operations.Self,
         Id, 
         Hosting_Migrating_Tasks_Priority,
         System.BB.Time.Milliseconds (Low_Critical_Budget),
         System.BB.Time.Milliseconds (High_Critical_Budget),
         Period);
  
      Activation_Manager.Synchronize_Activation_Cyclic (Next_Activation);

      --  Initial delay, specific for each task
      Next_Activation := Next_Activation + Task_Delay;
      delay until Next_Activation;
      
      loop
         --  Synchronization code
         Next_Activation := Next_Activation + Task_Period;
         
         --  Task workload
         if (Experiment_Parameters.Workload_Type = 1) then
            High_Criticality_Task_Workload.Workload_1_3;
            
         elsif (Experiment_Parameters.Workload_Type = 2) then
            High_Criticality_Task_Workload.Workload_2_3;
         
         elsif (Experiment_Parameters.Workload_Type = 3) then
            High_Criticality_Task_Workload.Workload_3_3;
         
         else
            Ada.Text_IO.Put_Line ("Unexpected workload received");
         end if;
         
         delay until Next_Activation;

      end loop;

   end High_Criticality_Task;

end High_Criticality_Task;
