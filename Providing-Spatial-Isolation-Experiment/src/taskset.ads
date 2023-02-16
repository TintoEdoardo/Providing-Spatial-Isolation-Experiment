------------------------------------------------------------------------------
--                                                                          --
--                                  TASKSET                                 --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

with High_Criticality_Task;
with Low_Criticality_Task;
with Experiment_Parameters; use Experiment_Parameters;

package Taskset is

   --  High criticality tasks
   High_Crit_Task_0 : High_Criticality_Task.High_Criticality_Task_Starter 
     (Id                               => 10, 
      Priority                         => 1, 
      Hosting_Migrating_Tasks_Priority => 1, 
      Low_Critical_Budget              => 10, 
      High_Critical_Budget             => 10, 
      Workload                         => Task_Period / Taskset_Cardinality, 
      Period                           => Task_Period, 
      Reduced_Deadline                 => Task_Period, 
      Could_Exceed                     => False, 
      CPU_Id                           => 1);
   
      High_Crit_Task_2 : High_Criticality_Task.High_Criticality_Task 
     (Id                               => 2, 
      Priority                         => 2, 
      Hosting_Migrating_Tasks_Priority => 2, 
      Low_Critical_Budget              => 10, 
      High_Critical_Budget             => 10, 
      Workload                         => Task_Period / Taskset_Cardinality, 
      Period                           => Task_Period, 
      Reduced_Deadline                 => Task_Period, 
      Could_Exceed                     => False, 
      CPU_Id                           => 1);
   
      High_Crit_Task_4 : High_Criticality_Task.High_Criticality_Task 
     (Id                               => 4, 
      Priority                         => 2, 
      Hosting_Migrating_Tasks_Priority => 2, 
      Low_Critical_Budget              => 10, 
      High_Critical_Budget             => 10, 
      Workload                         => Task_Period / Taskset_Cardinality, 
      Period                           => Task_Period, 
      Reduced_Deadline                 => Task_Period, 
      Could_Exceed                     => False, 
      CPU_Id                           => 1);
   
      High_Crit_Task_6 : High_Criticality_Task.High_Criticality_Task 
     (Id                               => 6, 
      Priority                         => 2, 
      Hosting_Migrating_Tasks_Priority => 2, 
      Low_Critical_Budget              => 10, 
      High_Critical_Budget             => 10, 
      Workload                         => Task_Period / Taskset_Cardinality, 
      Period                           => Task_Period, 
      Reduced_Deadline                 => Task_Period, 
      Could_Exceed                     => False, 
      CPU_Id                           => 1);
   
      High_Crit_Task_8 : High_Criticality_Task.High_Criticality_Task 
     (Id                               => 8, 
      Priority                         => 2, 
      Hosting_Migrating_Tasks_Priority => 2, 
      Low_Critical_Budget              => 10, 
      High_Critical_Budget             => 10, 
      Workload                         => Task_Period / Taskset_Cardinality, 
      Period                           => Task_Period, 
      Reduced_Deadline                 => Task_Period, 
      Could_Exceed                     => False, 
      CPU_Id                           => 1);
   
   --  Low criticality tasks
   Low_Crit_Task_1 : Low_Criticality_Task.Low_Criticality_Task 
     (Id                                => 1,
      Priority                          => 5, 
      Hosting_Migrating_Tasks_Priority  => 5, 
      On_Target_Core_Priority           => -1, 
      Low_Critical_Budget               => 10, 
      Is_Migrable                       => False, 
      Workload                          => Task_Period / Taskset_Cardinality, 
      Period                            => Task_Period, 
      Reduced_Deadline                  => Task_Period, 
      CPU_Id                            => 1);
   
   Low_Crit_Task_3 : Low_Criticality_Task.Low_Criticality_Task 
     (Id                                => 3,
      Priority                          => 5, 
      Hosting_Migrating_Tasks_Priority  => 5, 
      On_Target_Core_Priority           => -1, 
      Low_Critical_Budget               => 10, 
      Is_Migrable                       => False, 
      Workload                          => Task_Period / Taskset_Cardinality, 
      Period                            => Task_Period, 
      Reduced_Deadline                  => Task_Period, 
      CPU_Id                            => 1);

   Low_Crit_Task_5 : Low_Criticality_Task.Low_Criticality_Task 
     (Id                                => 5,
      Priority                          => 5, 
      Hosting_Migrating_Tasks_Priority  => 5, 
      On_Target_Core_Priority           => -1, 
      Low_Critical_Budget               => 10, 
      Is_Migrable                       => False, 
      Workload                          => Task_Period / Taskset_Cardinality, 
      Period                            => Task_Period, 
      Reduced_Deadline                  => Task_Period, 
      CPU_Id                            => 1);
   
   Low_Crit_Task_7 : Low_Criticality_Task.Low_Criticality_Task 
     (Id                                => 7,
      Priority                          => 5, 
      Hosting_Migrating_Tasks_Priority  => 5, 
      On_Target_Core_Priority           => -1, 
      Low_Critical_Budget               => 10, 
      Is_Migrable                       => False, 
      Workload                          => Task_Period / Taskset_Cardinality, 
      Period                            => Task_Period, 
      Reduced_Deadline                  => Task_Period, 
      CPU_Id                            => 1);
   
   Low_Crit_Task_9 : Low_Criticality_Task.Low_Criticality_Task_Stopper 
     (Id                                => 9,
      Priority                          => 5, 
      Hosting_Migrating_Tasks_Priority  => 5, 
      On_Target_Core_Priority           => -1, 
      Low_Critical_Budget               => 10,  
      Is_Migrable                       => False, 
      Workload                          => Task_Period / Taskset_Cardinality, 
      Period                            => Task_Period, 
      Reduced_Deadline                  => Task_Period, 
      CPU_Id                            => 1);

end Taskset;
