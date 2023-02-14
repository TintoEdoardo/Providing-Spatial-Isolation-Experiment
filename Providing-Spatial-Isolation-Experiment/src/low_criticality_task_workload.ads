------------------------------------------------------------------------------
--                                                                          --
--                       LOW CRITICALITY TASK WORKLOAD                      --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

package Low_Criticality_Task_Workload is
   
   --  Workloads exploiting the Channel for
   --  cross-criticality interactions without
   --  message overwrite
   procedure Workload_1_2;
   procedure Workload_1_4;

   --  Workloads exploiting the Channel for
   --  cross-criticality interactions with
   --  message overwrite
   procedure Workload_2_2;
   procedure Workload_2_4;
   
   --  Workloads exploiting Shared Object for
   --  cross-criticality interactions
   procedure Workload_3_2;
   procedure Workload_3_4;

end Low_Criticality_Task_Workload;
