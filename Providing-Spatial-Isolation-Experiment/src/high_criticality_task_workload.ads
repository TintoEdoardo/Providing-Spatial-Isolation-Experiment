------------------------------------------------------------------------------
--                                                                          --
--                       HIGH CRITICALITY TASK WORKLOAD                     --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

package High_Criticality_Task_Workload is

   --  Workloads exploiting the Channel for
   --  cross-criticality interactions without
   --  message overwrite
   procedure Workload_1_1;
   procedure Workload_1_3;

   --  Workloads exploiting the Channel for
   --  cross-criticality interactions with
   --  message overwrite
   procedure Workload_2_1;
   procedure Workload_2_3;
   
   --  Workloads exploiting Shared Object for
   --  cross-criticality interactions
   procedure Workload_3_1;
   procedure Workload_3_3;

end High_Criticality_Task_Workload;
