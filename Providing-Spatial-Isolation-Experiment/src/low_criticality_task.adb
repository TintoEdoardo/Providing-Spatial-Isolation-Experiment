------------------------------------------------------------------------------
--                                                                          --
--                            LOW CRITICALITY TASK                          --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Synchronous_Task_Control;
with Activation_Manager;
with Experiment_Parameters;
with Low_Criticality_Task_Workload;
pragma Warnings (Off);
with System.BB.Time;
with System.Task_Primitives.Operations;
pragma Warnings (On);

--  The following dependencies are used for measuring the 
--  experimental metrics
with Ada.Text_IO;

package body Low_Criticality_Task is

   task body Low_Criticality_Task is
      Next_Activation     : Ada.Real_Time.Time;
      Task_Period         : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds (Period);
      Iteration_Counter   : Positive;
      Iteration_Limit     : Positive;
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
      Iteration_Counter := 1;
      Iteration_Limit   := Experiment_Parameters.Iteration_Limit;
      loop
         --  Synchronization code
         Ada.Synchronous_Task_Control.Suspend_Until_True
           (Activation_Manager.Could_Receive);
         Next_Activation := Next_Activation + Task_Period;
         
         --  Task workload
         if (Iteration_Counter <= Iteration_Limit) then
            
            Low_Criticality_Task_Workload.Workload_1;
            
            Iteration_Counter := Iteration_Counter + 1;
            
            -- Insert eof and notify the end of the experiment
            if (Iteration_Counter = Iteration_Limit + 1) then
               
               --  Noticeably, the Put operation requires some
               --  time to complete successfully, hence before 
               --  setting the SO Experiment_Is_Completed, the
               --  task will suspend until next activation. 
               Ada.Text_IO.Put ("<eof_tag/>");
               delay until Next_Activation;
               
               --  Finally, the SO is set to True
               Ada.Synchronous_Task_Control.Set_True
                 (Activation_Manager.Experiment_Is_Completed);
            end if;
            
         end if;
         
         delay until Next_Activation;
      end loop;
   end Low_Criticality_Task;

end Low_Criticality_Task;
