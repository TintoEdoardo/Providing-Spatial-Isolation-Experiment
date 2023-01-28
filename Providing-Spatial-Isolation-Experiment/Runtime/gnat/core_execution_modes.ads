--  This package is an interface in order to exploit the
--  semi-partitioned Model for dual-core mixed criticality system (MCS)
--  https://dl.acm.org/doi/10.1145/2834848.2834865

with Mixed_Criticality_System;
with System.Multiprocessors; use System.Multiprocessors;
with System.BB.Time;

package Core_Execution_Modes is
   pragma Preelaborate;

   type Mode is new Mixed_Criticality_System.Criticality;
    --  It is the set value of the processor Mode.
    --  If the value is set to HIGH => then:
    --  1) the high-critical tasks will execute with their
    --     high-critical budget;
    --  2) some low-critical tasks will migrate or they will be discarded.

   procedure Set_Core_Mode (Core_Mode : Mode; CPU_Id : CPU);

   function Get_Core_Mode (CPU_Id : CPU) return Mode;

   procedure Print_CPUs_Log;

   type CPU_Data_Log is record
      Low_To_High        : Natural      := 0;
      High_To_Low        : Natural      := 0;

      Idle_Time          : System.BB.Time.Time_Span    := 0;
      Last_Time_Idle     : System.BB.Time.Time := 0;
      Is_Idle            : Boolean := False;

      --  Absolute moment in time when the other core is entered in
      --  HI-crit mode, i.e. this core is hosting mig tasks. It is needed
      --  in order to compute real utilizations while hosting mig tasks.
      Start_Hosting_Mig           : System.BB.Time.Time := 0;
      End_Hosting_Mig             : System.BB.Time.Time := 0;
      Last_Time_Idle_Hosting_Migs : System.BB.Time.Time := 0;
      Idle_Time_Hosting_Migs      : System.BB.Time.Time_Span := 0;
      Total_Time_Hosting_Migs     : System.BB.Time.Time_Span := 0;
      Hosting_Mig_Tasks           : Boolean := False;

   end record;

   CPU_Log_Table : array (CPU) of CPU_Data_Log;

    --  Remember: high-critical tasks are statically allocated to the cores.
    --  Mode type objects must be modified by only high-critical tasks.
    --  So, Mode_Core_1 can be modified just by high-critical tasks on core 1,
    --  while Mode_Core_2 can be modified just by
    --  high-critical tasks on core 2.

    --  The main differences between "Criticality" and "Mode" are:
    --  1) Criticality is referred to tasks, while Mode to cores;
    --  2) Criticality level is a static and constant value, while the
    --     Mode level could dynamically change during execution.
    --     e.g. if an high-critical task exceeds its low-critical budget
    --     and its core is running in low-critical Mode, than the Mode
    --     level must be set to high.

   --  Log Stuff
   Safe_Boundary_Has_Been_Exceeded : Boolean := False;
   Experiment_Is_Not_Valid : Boolean := False;

   procedure Set_Parameters_Referee (Safe_Boundary_Exceeded : Boolean;
                                    Experiment_Not_Valid : Boolean;
                                    Finish_Experiment : Boolean);

   procedure Wait_Experiment_Over;

private

   Mode_Cores : array (CPU) of Mode := (others => LOW);

end Core_Execution_Modes;
