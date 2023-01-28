pragma Warnings (Off);
with Ada.Text_IO;

--  TODO: this should be safe.
with Guard_Experiment;
pragma Elaborate (Guard_Experiment);
pragma Warnings (On);

with System.BB.Board_Support;
with System.Multiprocessors.Fair_Locks;
with System.Multiprocessors.Spin_Locks;
use System.Multiprocessors.Fair_Locks;
use System.Multiprocessors.Spin_Locks;

package body Core_Execution_Modes is

   Change_Mode_Lock : Fair_Lock := (Spinning => (others => False),
                                    Lock     => (Flag   => Unlocked));

   procedure Set_Core_Mode (Core_Mode : Mode; CPU_Id : CPU) is
      use System.BB.Board_Support.Multiprocessors;
      CPU_Target : CPU := CPU'First;
   begin
      --  Interrupts must be disabled
      --  A CPU can only change its own criticality mode
      pragma Assert (CPU_Id = Current_CPU);

      if CPU_Target = CPU_Id then
         CPU_Target := CPU'Last;
      end if;

      --  Log change mode.
      if Mode_Cores (CPU_Id) /= Core_Mode then
         if Mode_Cores (CPU_Id) = LOW then
            CPU_Log_Table (CPU_Id).Low_To_High
                                    := CPU_Log_Table (CPU_Id).Low_To_High + 1;
         else
            CPU_Log_Table (CPU_Id).High_To_Low
                                    := CPU_Log_Table (CPU_Id).High_To_Low + 1;
         end if;
      end if;

      Lock (Change_Mode_Lock);
      if Core_Mode = HIGH and Get_Core_Mode (CPU_Target) = HIGH then
         --  Both CPU are in HI-crit mode. Dangerous situation.
         --  The safe boundary has been exceeded: the system is no longer
         --  schedulable, i.e. some tasks have to be dropped. MCS has failed.
         Safe_Boundary_Has_Been_Exceeded := True;
         Experiment_Is_Not_Valid := True;

         Guard_Experiment.Referee.Set_Parameters
                  (Safe_Boundary_Exceeded => Safe_Boundary_Has_Been_Exceeded,
                  Experiment_Not_Valid => Experiment_Is_Not_Valid,
                  Finish_Experiment => False);

         --  Ada.Text_IO.Put_Line
         --         ("-----------------------------------------------------");
         --  Ada.Text_IO.Put_Line
         --         ("--  BOTH CPU in HI-crit mode: DANGEROUS SITUATION  --");
         --  Ada.Text_IO.Put_Line
         --         ("--          !!!  INVALID EXPERIMENTS  !!!          --");
         --  Ada.Text_IO.Put_Line
         --         ("-----------------------------------------------------");
         --  loop
         --     null;
         --  end loop;
      else
         Mode_Cores (CPU_Id) := Core_Mode;
      end if;
      Unlock (Change_Mode_Lock);

   end Set_Core_Mode;

   function Get_Core_Mode (CPU_Id : CPU) return Mode is
   begin
      --  Interrupts must be disabled

      return Mode_Cores (CPU_Id);
   end Get_Core_Mode;

   procedure Print_CPUs_Log is
      use System.BB.Time;
   begin
      Ada.Text_IO.Put_Line ("<cores>");

      for CPU_Id in CPU_Log_Table'Range loop
         Ada.Text_IO.Put_Line ("<cpu>");
         Ada.Text_IO.Put_Line ("<id>" & CPU_Range'Image (CPU_Id) & "</id>");
         Ada.Text_IO.Put_Line ("<lowtohigh>"
            & Natural'Image (CPU_Log_Table (CPU_Id).Low_To_High) &
                                                               "</lowtohigh>");

         Ada.Text_IO.Put_Line ("<hightolow>"
            & Natural'Image (CPU_Log_Table (CPU_Id).High_To_Low)
                                                            & "</hightolow>");

         Ada.Text_IO.Put_Line ("<idletime>" &
            Duration'Image (To_Duration (CPU_Log_Table (CPU_Id).Idle_Time))
                                                            & "</idletime>");

         Ada.Text_IO.Put_Line ("<idletimehostingmigs>" &
            Duration'Image (To_Duration (CPU_Log_Table (CPU_Id).
                                                      Idle_Time_Hosting_Migs))
                                                & "</idletimehostingmigs>");

         Ada.Text_IO.Put_Line ("<totaltimehostingmigs>" &
            Duration'Image (To_Duration (CPU_Log_Table (CPU_Id).
                                                      Total_Time_Hosting_Migs))
                                                & "</totaltimehostingmigs>");

         Ada.Text_IO.Put_Line ("</cpu>");
      end loop;

      Ada.Text_IO.Put_Line ("</cores>");
   end Print_CPUs_Log;

   procedure Set_Parameters_Referee (Safe_Boundary_Exceeded : Boolean;
                                    Experiment_Not_Valid : Boolean;
                                    Finish_Experiment : Boolean) is
   begin
      Guard_Experiment.Referee.Set_Parameters
            (Safe_Boundary_Exceeded, Experiment_Not_Valid, Finish_Experiment);
   end Set_Parameters_Referee;

   procedure Wait_Experiment_Over is
   begin
      Guard_Experiment.Referee.Is_Experiment_Over;
   end Wait_Experiment_Over;

end Core_Execution_Modes;
