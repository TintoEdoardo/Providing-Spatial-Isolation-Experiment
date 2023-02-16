------------------------------------------------------------------------------
--                                                                          --
--                            LOW CRITICALITY TASK                          --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;
with Activation_Manager;
with Experiment_Parameters;
with Low_Criticality_Task_Workload;
pragma Warnings (Off);
with System.BB.Time;
with System.Task_Primitives.Operations;
pragma Warnings (On);

package body Low_Criticality_Task is

   task body Low_Criticality_Task is
      Next_Activation     : Ada.Real_Time.Time;
      Task_Period         : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds (Period);
      Task_Delay          : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds
          (Period / Experiment_Parameters.Taskset_Cardinality * Id);
   begin
      
      System.Task_Primitives.Operations.Initialize_LO_Crit_Task
        (System.Task_Primitives.Operations.Self,
         Id,
         Hosting_Migrating_Tasks_Priority,
         On_Target_Core_Priority,
         System.BB.Time.Milliseconds (Low_Critical_Budget),
         Period,
         Reduced_Deadline,
         Is_Migrable);
      
      Activation_Manager.Synchronize_Activation_Cyclic (Next_Activation);

      --  Initial delay, specific for each task
      Next_Activation := Next_Activation + Task_Delay;
      delay until Next_Activation;
      
      loop
         --  Synchronization code
         Next_Activation := Next_Activation + Task_Period;
         
         --  Task workload
         if (Experiment_Parameters.Workload_Type = 1) then
            Low_Criticality_Task_Workload.Workload_1_2;
            
         elsif (Experiment_Parameters.Workload_Type = 2) then
            Low_Criticality_Task_Workload.Workload_2_2;
         
         elsif (Experiment_Parameters.Workload_Type = 3) then
            Low_Criticality_Task_Workload.Workload_3_2;
         
         else
            Ada.Text_IO.Put_Line ("Unexpected workload received");
         end if;
         
         delay until Next_Activation;

      end loop;

   end Low_Criticality_Task;
   
   task body Low_Criticality_Task_Stopper is
      Next_Activation     : Ada.Real_Time.Time;
      Task_Period         : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds (Period);
      Task_Delay          : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds
          (Period / Experiment_Parameters.Taskset_Cardinality * Id);
   begin
      
      System.Task_Primitives.Operations.Initialize_LO_Crit_Task
        (System.Task_Primitives.Operations.Self,
         Id,
         Hosting_Migrating_Tasks_Priority,
         On_Target_Core_Priority,
         System.BB.Time.Milliseconds (Low_Critical_Budget),
         Period,
         Reduced_Deadline,
         Is_Migrable);
      
      Activation_Manager.Synchronize_Activation_Cyclic (Next_Activation);

      --  Initial delay, specific for each task
      Next_Activation := Next_Activation + Task_Delay;
      delay until Next_Activation;
      
      loop
         --  Synchronization code
         Next_Activation := Next_Activation + Task_Period;
         
         --  Task workload
         if (Experiment_Parameters.Workload_Type = 1) then
            Low_Criticality_Task_Workload.Workload_1_4;
            
         elsif (Experiment_Parameters.Workload_Type = 2) then
            Low_Criticality_Task_Workload.Workload_2_4;
         
         elsif (Experiment_Parameters.Workload_Type = 3) then
            Low_Criticality_Task_Workload.Workload_3_4;
         
         else
            Ada.Text_IO.Put_Line ("Unexpected workload received");
         end if;
         
         delay until Next_Activation;

      end loop;

   end Low_Criticality_Task_Stopper;

end Low_Criticality_Task;
