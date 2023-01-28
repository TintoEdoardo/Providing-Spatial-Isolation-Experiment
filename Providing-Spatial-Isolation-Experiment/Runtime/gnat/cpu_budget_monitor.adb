pragma Warnings (Off);
with Ada.Text_IO;
with System.BB.Execution_Time;
pragma Warnings (On);

with System.BB.Protection;
with System.BB.Board_Support;
with System.BB.Threads.Queues;
with System.Tasking;
with Mixed_Criticality_System;
with Core_Execution_Modes;
with Experiment_Info;

--  with MBTA;

package body CPU_Budget_Monitor is

   Hyperperiod_Passed_First_Time : array (System.Multiprocessors.CPU)
                                               of Boolean := (others => False);

   -----------------------------------
   --  Task_Is_The_Only_One_On_CPU  --
   -----------------------------------

   function Task_Is_The_Only_One_On_CPU
      (Self_Id : System.BB.Threads.Thread_Id) return Boolean;

   function Task_Is_The_Only_One_On_CPU
      (Self_Id : System.BB.Threads.Thread_Id) return Boolean is
      use System.BB.Threads;
      use System.BB.Threads.Queues;
   begin
      --  Self_Id is the only one in the ready queue iff
      --  no higher-priority tasks are ready AND its successor in the queue
      --  is the Idle_Task.
      return
         (not Context_Switch_Needed) and
            (Self_Id.Next /= Null_Thread_Id and
               Self_Id.Next.Active_Priority = System.Tasking.Idle_Priority);
   end Task_Is_The_Only_One_On_CPU;

   -----------------------
   --  CPU_BE_Detected  --
   -----------------------

   procedure CPU_BE_Detected (E : in out Timing_Event) is
      use System.BB.Threads;
      use System.BB.Threads.Queues;
      use Mixed_Criticality_System;
      use Core_Execution_Modes;
      use System.BB.Board_Support.Multiprocessors;
      use System.Multiprocessors;
      use System.BB.Time;
      pragma Unreferenced (E);
      CPU_Id : constant CPU := Current_CPU;
      Self_Id : constant Thread_Id := Running_Thread;
      Task_Id : Integer;
      Task_Exceeded : constant System.Priority :=
                    Self_Id.Data_Concerning_Migration.Id;
      Cancelled : Boolean;
      --  Start_Time : Time;
   begin
      System.BB.Protection.Enter_Kernel;
      --  Start_Time := Clock;

      --  Log CPU_Budget_Exceeded
      Self_Id.Log_Table.Times_BE := Self_Id.Log_Table.Times_BE + 1;
      --  Ada.Text_IO.Put ("CPU_" & System.Multiprocessors.CPU'Image (CPU_Id)
      --                          & ": task " & Integer'Image (Task_Exceeded));

      --  Log that CPU_Budget_Exceeded has been happened on target CPU
      if Self_Id.Active_CPU /= Self_Id.Base_CPU then
         Task_Id := Self_Id.Data_Concerning_Migration.Id;
         Executions (Task_Id).BE_On_Target_Core :=
           Executions (Task_Id).BE_On_Target_Core + 1;
      end if;

      --  Log that CPU_Budget_Exceeded has been happened after migration(s).
      if Executions (Task_Id).Migration_Happened_Current_Job_Release then
         Executions (Task_Id).BE_After_Migration :=
                              Executions (Task_Id).BE_After_Migration + 1;
      end if;

      if Get_Core_Mode (CPU_Id) = LOW then
         if Self_Id.Criticality_Level = HIGH then
            Self_Id.T_Clear := System.BB.Time.Clock;
            Clear_Monitor (Cancelled);  --  This call should be removed (?)
            Self_Id.Active_Budget := 0;
            --  Ada.Text_IO.Put_Line
            --   (" HI-CRIT CPU_Budget_Exceeded DETECTED.");
            Set_Core_Mode (HIGH, CPU_Id);
            Enter_In_HI_Crit_Mode;

            Start_Monitor (Self_Id.Active_Budget);
            Self_Id.T_Start := System.BB.Time.Clock;
         else  --  Job is LO-Crit
            if Self_Id.Log_Table.Last_Time_Locked /= 0 then
               Self_Id.Log_Table.Locked_Time :=
                              Self_Id.Log_Table.Locked_Time +
                              (Clock - Self_Id.Log_Table.Last_Time_Locked);
            end if;

            --  A LO-Crit job can exceed its budget iff it is the only one
            --  in the ready queue.

            if not Task_Is_The_Only_One_On_CPU (Self_Id) then
               Experiment_Is_Not_Valid := True;
               Guilty_Task := Task_Exceeded;

               Set_Parameters_Referee
                     (Safe_Boundary_Exceeded => False,
                     Experiment_Not_Valid => Experiment_Is_Not_Valid,
                     Finish_Experiment => False);
            else
               --  Ada.Text_IO.Put_Line ("CPU_"
               --   & System.Multiprocessors.CPU'Image (CPU_Id)
               --   & ": task allowed to exceed during LO-Crit mode: "
               --   & Integer'Image (Task_Exceeded));
               null;
            end if;
         end if;
      else  --  Get_Core_Mode (CPU_Id) is HIGH
         if Self_Id.Log_Table.Last_Time_Locked /= 0 then
            Self_Id.Log_Table.Locked_Time :=
                           Self_Id.Log_Table.Locked_Time +
                           (Clock - Self_Id.Log_Table.Last_Time_Locked);
         end if;

         if (Self_Id.Criticality_Level = HIGH) or
            (Self_Id.Criticality_Level = LOW and
               not Task_Is_The_Only_One_On_CPU (Self_Id))
         then
            Experiment_Is_Not_Valid := True;
            Guilty_Task := Task_Exceeded;

            Set_Parameters_Referee
                  (Safe_Boundary_Exceeded => False,
                  Experiment_Not_Valid => Experiment_Is_Not_Valid,
                  Finish_Experiment => False);
            --  Ada.Text_IO.Put_Line ("");
            --  Ada.Text_IO.Put_Line ("CPU_"
            --               & System.Multiprocessors.CPU'Image (CPU_Id)
            --             & ": GUILTY task " & Integer'Image (Task_Exceeded));
         else
            --  Ada.Text_IO.Put_Line ("CPU_"
            --   & System.Multiprocessors.CPU'Image (CPU_Id)
            --   & ": task allowed to exceed during HI-Crit mode: "
            --   & Integer'Image (Task_Exceeded));
            null;
         end if;
      end if;

      --  MBTA.Log_RTE_Primitive_Duration
      --   (MBTA.BED, To_Duration (Clock - Start_Time), CPU_Id);
      --    System.BB.Protection.Leave_Kernel;
      --  Ada.Text_IO.Put_Line ("BE HANDLED");
   end CPU_BE_Detected;

   --  return True iff we have detected the passage of the hyperperiod
   --  for at least once. It is useful in order to stop logging CPU's Idle_Time
   --  as soon as its hyperperiod expires.
   function Hyperperiod_Not_Yet_Passed
     (CPU_Id : System.Multiprocessors.CPU;
      Now : System.BB.Time.Time) return Boolean;
   pragma Unreferenced (Hyperperiod_Not_Yet_Passed);

   ---------------------
   --  Start_Monitor  --
   ---------------------

   procedure Start_Monitor (For_Time : System.BB.Time.Time_Span) is
      --  use Real_Time_No_Elab;
      --  use System.BB.Board_Support.Multiprocessors;
      use System.BB.Threads;
      use System.BB.Threads.Queues;
      use Core_Execution_Modes;
      use System.Multiprocessors;
      use System.BB.Time;
      Now : constant Time := Clock;
      --  Start_Time : constant Time := Now;
      Self_Id : constant Thread_Id := Running_Thread;
      CPU_Id : constant CPU := Self_Id.Active_CPU;
      Cancelled : Boolean;
      pragma Unreferenced (Cancelled);
      --  Task_Exceeded : constant System.Priority := Self_Id.Base_Priority;

   begin

      --  Log that CPU_Id is no longer idle.
      if CPU_Log_Table (CPU_Id).Is_Idle
         --  and Hyperperiod_Not_Yet_Passed (CPU_Id, Now)
      then
         CPU_Log_Table (CPU_Id).Is_Idle := False;

         CPU_Log_Table (CPU_Id).Idle_Time :=
                     CPU_Log_Table (CPU_Id).Idle_Time +
            (Now - CPU_Log_Table (CPU_Id).Last_Time_Idle);

         --  If this core is hosting migratings tasks.
         if CPU_Log_Table (CPU_Id).Hosting_Mig_Tasks then

            if CPU_Log_Table (CPU_Id).Last_Time_Idle_Hosting_Migs /= 0 then
               CPU_Log_Table (CPU_Id).Idle_Time_Hosting_Migs :=
                  CPU_Log_Table (CPU_Id).Idle_Time_Hosting_Migs +
                    (Now - CPU_Log_Table (CPU_Id).Last_Time_Idle_Hosting_Migs);
            else
               CPU_Log_Table (CPU_Id).Idle_Time_Hosting_Migs :=
                  CPU_Log_Table (CPU_Id).Idle_Time_Hosting_Migs +
                    (Now - CPU_Log_Table (CPU_Id).Start_Hosting_Mig);
            end if;

         end if;

      end if;

      --  Log that thread is (again) on this CPU
      if CPU_Id = CPU'First then
         Executions (Self_Id.Data_Concerning_Migration.Id).Times_On_First_CPU
           := Executions (Self_Id.Data_Concerning_Migration.Id).
                                                  Times_On_First_CPU + 1;
      else
         Executions (Self_Id.Data_Concerning_Migration.Id).Times_On_Second_CPU
           := Executions (Self_Id.Data_Concerning_Migration.Id).
                                                  Times_On_Second_CPU + 1;
      end if;

      Set_Handler
            (Event =>
                BE_Happened (CPU_Id),
            At_Time =>
                For_Time + Real_Time_No_Elab.Clock,
            Handler =>
                CPU_BE_Detected'Access);

      --  Self_Id.T_Start := System.BB.Time.Clock;
      --  MBTA.Log_RTE_Primitive_Duration
      --    (MBTA.SM, To_Duration (Clock - Start_Time), CPU_Id);

   end Start_Monitor;

   ---------------------
   --  Clear_Monitor  --
   ---------------------

   procedure Clear_Monitor (Cancelled : out Boolean) is
      --  use System.BB.Board_Support.Multiprocessors;
      use System.BB.Threads;
      use System.BB.Time;
      use System.BB.Threads.Queues;
      --  Start_Time : constant Time := Clock;
      Self_Id : constant Thread_Id := Running_Thread;
      CPU_Id : constant System.Multiprocessors.CPU :=
                                                      Self_Id.Active_CPU;
   begin
      --  Self_Id.T_Clear := System.BB.Time.Clock;

      Cancel_Handler (BE_Happened (CPU_Id), Cancelled);

      if Self_Id.Is_Monitored and Self_Id.State = Runnable then
         --  Ada.Text_IO.Put (Integer'Image (Self_Id.Base_Priority)
         --  & " consumed" & Duration'Image
         --  (System.BB.Time.To_Duration (Self_Id.Active_Budget)) & " => ");
         Self_Id.Active_Budget :=
           Self_Id.Active_Budget - (Self_Id.T_Clear - Self_Id.T_Start);

         --  Ada.Text_IO.Put_Line (Duration'Image (System.BB.Time.To_Duration
         --                                    (Self_Id.Active_Budget)));
      end if;
      --  MBTA.Log_RTE_Primitive_Duration
      --  (MBTA.CM, To_Duration (Clock - Start_Time), CPU_Id);
   end Clear_Monitor;

   ----------------------------------
   --  Hyperperiod_Not_Yet_Passed  --
   ----------------------------------

   --  return True iff we have detected the passage of the hyperperiod
   --  for at least once. It is useful in order to stop logging CPU's Idle_Time
   --  as soon as its hyperperiod expires.

   function Hyperperiod_Not_Yet_Passed
     (CPU_Id : System.Multiprocessors.CPU;
      Now : System.BB.Time.Time) return Boolean is
      use Real_Time_No_Elab;
      Absolute_Hyperperiod : constant Real_Time_No_Elab.Time :=
         Experiment_Info.Get_Parameters.Absolutes_Hyperperiods (CPU_Id);
   begin
      if (not Hyperperiod_Passed_First_Time (CPU_Id))
        and
         Real_Time_No_Elab.">=" (Now, Absolute_Hyperperiod)
      then
         Hyperperiod_Passed_First_Time (CPU_Id) := True;
         --  Ada.Text_IO.Put_Line
         --  ("Stop time log on: " & System.Multiprocessors.CPU'Image (CPU_Id))
      end if;

      return not Hyperperiod_Passed_First_Time (CPU_Id);
   end Hyperperiod_Not_Yet_Passed;

end CPU_Budget_Monitor;
