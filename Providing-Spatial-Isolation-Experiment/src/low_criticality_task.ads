------------------------------------------------------------------------------
--                                                                          --
--                            LOW CRITICALITY TASK                          --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

with System; use System;
with System.Multiprocessors; use System.Multiprocessors;

package Low_Criticality_Task is

   task type Low_Criticality_Task
     (Id                               : Natural;
      Priority                         : System.Priority;
      Hosting_Migrating_Tasks_Priority : Integer;
      On_Target_Core_Priority          : Integer;
      Low_Critical_Budget              : Natural;
      Is_Migrable                      : Boolean;
      Workload                         : Positive;
      Period                           : Positive;
      Reduced_Deadline                 : Positive;
      CPU_Id                           : CPU)
   is
      pragma Priority (Priority);
      pragma CPU (CPU_Id);
   end Low_Criticality_Task;

   task type Low_Criticality_Task_Stopper
     (Id                               : Natural;
      Priority                         : System.Priority;
      Hosting_Migrating_Tasks_Priority : Integer;
      On_Target_Core_Priority          : Integer;
      Low_Critical_Budget              : Natural;
      Is_Migrable                      : Boolean;
      Workload                         : Positive;
      Period                           : Positive;
      Reduced_Deadline                 : Positive;
      CPU_Id                           : CPU)
   is
      pragma Priority (Priority);
      pragma CPU (CPU_Id);
   end Low_Criticality_Task_Stopper;

end Low_Criticality_Task;
