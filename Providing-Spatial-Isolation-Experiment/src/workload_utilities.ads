------------------------------------------------------------------------------
--                                                                          --
--                             WORKLOAD UTILITIES                           --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------
with Ada.Real_Time; use Ada.Real_Time;

package Workload_Utilities is
   
   procedure Print_NewLine;

   procedure Print_Alloc
     (Timing_Event_1 : Ada.Real_Time.Time; 
      Timing_Event_2 : Ada.Real_Time.Time);
   
   procedure Print_Free
     (Timing_Event_1 : Ada.Real_Time.Time; 
      Timing_Event_2 : Ada.Real_Time.Time);
   
   procedure Print_Send
     (Timing_Event_1 : Ada.Real_Time.Time; 
      Timing_Event_2 : Ada.Real_Time.Time);
   
   procedure Print_Receive
     (Timing_Event_1 : Ada.Real_Time.Time; 
      Timing_Event_2 : Ada.Real_Time.Time);

   procedure Print_Initialize
     (Timing_Event_1 : Ada.Real_Time.Time; 
      Timing_Event_2 : Ada.Real_Time.Time);

end Workload_Utilities;
