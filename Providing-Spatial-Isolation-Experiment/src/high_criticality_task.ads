------------------------------------------------------------------------------
--                                                                          --
--                           HIGH CRITICALITY TASK                          --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

with System; use System;
with System.Multiprocessors; use System.Multiprocessors;

package High_Criticality_Task is

   task type High_Criticality_Task
     (Id                               : Natural;
      Priority                         : System.Priority;
      Hosting_Migrating_Tasks_Priority : Integer;
      Low_Critical_Budget              : Natural;
      High_Critical_Budget             : Natural;
      Workload                         : Positive;
      Period                           : Positive;
      Reduced_Deadline                 : Positive;
      Could_Exceed                     : Boolean;
      CPU_Id                           : CPU)
   is
      pragma Priority (Priority);
      pragma CPU (CPU_Id);
   end High_Criticality_Task;

end High_Criticality_Task;
