------------------------------------------------------------------------------
--                                                                          --
--                       HIGH CRITICALITY TASK WORKLOAD                     --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

package High_Criticality_Task_Workload is

   --  Workload exploiting the Channel for
   --  cross-criticality interactions
   procedure Workload_1;
   
   --  Workload exploiting Shared Object for
   --  cross-criticality interactions
   procedure Workload_2;

end High_Criticality_Task_Workload;
