with Real_Time_No_Elab;
--  pragma Elaborate_All (Real_Time_No_Elab);
pragma Elaborate (Real_Time_No_Elab);

with Real_Time_No_Elab.Timing_Events_No_Elab;
use Real_Time_No_Elab.Timing_Events_No_Elab;
pragma Elaborate (Real_Time_No_Elab.Timing_Events_No_Elab);

with System.Multiprocessors;
with System.BB.Threads;
with System.BB.Time;
with System;

package CPU_Budget_Monitor is
   pragma Preelaborate;

   type CPU_Budget_Exceeded is new Timing_Event with
        record
            Id : System.BB.Threads.Thread_Id; --  @todo it seems useless...
        end record;

   BE_Happened : array (System.Multiprocessors.CPU)
                            of CPU_Budget_Exceeded;
   --  A timing event for each CPU.

   --  CPU_Budget_Exceeded handler.
   procedure CPU_BE_Detected (E : in out Timing_Event);

   procedure Start_Monitor (For_Time : System.BB.Time.Time_Span);

   procedure Clear_Monitor (Cancelled : out Boolean);

   --  Log stuff
   Experiment_Is_Not_Valid : Boolean := False;
   Guilty_Task : Integer := -2;

end CPU_Budget_Monitor;
