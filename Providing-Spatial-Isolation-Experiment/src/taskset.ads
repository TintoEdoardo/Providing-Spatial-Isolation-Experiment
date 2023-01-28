------------------------------------------------------------------------------
--                                                                          --
--                                  TASKSET                                 --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

with High_Criticality_Task;
with Low_Criticality_Task;
with Activation_Manager;

package Taskset is

   --  High criticality tasks
   Activator : Activation_Manager.Activator
     (Id                               => 1, 
      Priority                         => 1, 
      Hosting_Migrating_Tasks_Priority => 1, 
      Low_Critical_Budget              => 20, 
      High_Critical_Budget             => 20, 
      Workload                         => 34000, 
      Period                           => 40000, 
      Reduced_Deadline                 => 40000, 
      Could_Exceed                     => False, 
      CPU_Id                           => 1);
   
   High_Crit_Task : High_Criticality_Task.High_Criticality_Task 
     (Id                               => 2, 
      Priority                         => 2, 
      Hosting_Migrating_Tasks_Priority => 2, 
      Low_Critical_Budget              => 10, 
      High_Critical_Budget             => 10, 
      Workload                         => 34000, 
      Period                           => 40000, 
      Reduced_Deadline                 => 40000, 
      Could_Exceed                     => False, 
      CPU_Id                           => 1);
   
   --  Low criticality tasks
   Low_Crit_Task : Low_Criticality_Task.Low_Criticality_Task 
     (Id                                => 3,
      Priority                          => 5, 
      Hosting_Migrating_Tasks_Priority  => 5, 
      On_Target_Core_Priority           => -1, 
      Low_Critical_Budget               => 10, 
      Is_Migrable                       => False, 
      Workload                          => 34000, 
      Period                            => 40000, 
      Reduced_Deadline                  => 40000, 
      CPU_Id                            => 2);

end Taskset;
