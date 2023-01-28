------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--               S Y S T E M . B B . T H R E A D S . Q U E U E S            --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
--                     Copyright (C) 2003-2018, AdaCore                     --
--                                                                          --
-- GNARL is free software; you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion. GNARL is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by Ada Core Technologies, Inc.     --
--                                                                          --
-- The port of GNARL to bare board targets was initially developed by the   --
-- Real-Time Systems Group at the Technical University of Madrid.           --
--                                                                          --
------------------------------------------------------------------------------

pragma Restrictions (No_Elaboration_Code);
with System.IO;
with System.BB.Time; use System.BB.Time;
with Core_Execution_Modes;
use Core_Execution_Modes;
with CPU_Budget_Monitor;
with Mixed_Criticality_System;
--  with MBTA;

pragma Warnings (Off);
with Ada.Text_IO;
with System.BB.Execution_Time;
pragma Warnings (On);
with System.Tasking;

package body System.BB.Threads.Queues is

   use System.Multiprocessors;
   use System.BB.Board_Support.Multiprocessors;
   use System.Multiprocessors.Fair_Locks;
   use System.Multiprocessors.Spin_Locks;
   --  package STPO renames System.Task_Primitives.Operations;

   ----------------
   -- Local data --
   ----------------

   Alarms_Table : array (CPU) of Thread_Id := (others => Null_Thread_Id);
   pragma Volatile_Components (Alarms_Table);
   --  Identifier of the thread that is in the first place of the alarm queue

   HI_Crit_Table : array (CPU) of Thread_Id := (others => Null_Thread_Id);
   --  for each CPU, it contains the whole set of HI-crit tasks.

   Discarded_Table_Lock : Fair_Lock := (Spinning => (others => False),
                                       Lock     => (Flag   => Unlocked));
   --  Protect access to Discarded_Thread_Table on multiprocessor systems

   type Action is (Migrate, Discard);

   type Log_Record is
      record
         ID : Integer;
         DM : Integer;
         Runs : Integer;
         Preemption : Integer;
         Min_Response_Jitter :  System.BB.Time.Time_Span;
         Max_Response_Jitter :  System.BB.Time.Time_Span;
         Min_Release_Jitter :  System.BB.Time.Time_Span;
         Max_Release_Jitter :  System.BB.Time.Time_Span;
         Average_Response_Jitter : System.BB.Time.Time_Span;
      end record;

   type Array_Log_Record is array (1 .. 90) of Log_Record;

   Log_Table : Array_Log_Record;
   Max_ID_Table : Integer := 0;

   procedure Initialize_Log_Table (ID : Integer) is
   begin
      if ID /= -1 then
         Log_Table (ID) := (ID, 0, -1, 0,
                             System.BB.Time.Time_Span_Last,
                             System.BB.Time.Time_Span_First,
                             System.BB.Time.Time_Span_Last,
                             System.BB.Time.Time_Span_First,
                             System.BB.Time.Time_Span_Zero);
         if Max_ID_Table < ID then
            Max_ID_Table := ID;
         end if;
      end if;
   end Initialize_Log_Table;

   procedure Add_DM (ID : Integer) is
   begin
      Executions (ID).Deadlines_Missed := Executions (ID).Deadlines_Missed + 1;

      --  Log DM on target core.
      --  This event should concerns only migrating tasks.
      if Running_Thread.Active_CPU /= Running_Thread.Base_CPU then
         Executions (ID).Deadlines_Missed_On_Target_Core :=
                       Executions (ID).Deadlines_Missed_On_Target_Core + 1;
      end if;

      --  Log that DM has been happened after migration(s).
      if Executions (ID).Migration_Happened_Current_Job_Release then
         Executions (ID).Deadlines_Missed_After_Migration :=
            Executions (ID).Deadlines_Missed_After_Migration + 1;
      end if;
      --  if ID /= 0 then
      --     Log_Table (ID).DM := Log_Table (ID).DM + 1;
      --  end if;
   end Add_DM;

   procedure Add_Runs (ID : Integer) is
   begin
      if ID /= 0 then
         Log_Table (ID).Runs :=
           Log_Table (ID).Runs + 1;
      end if;
   end Add_Runs;

   procedure Add_Preemption (ID : Integer) is
   begin
      if ID /= 0 then
         Log_Table (ID).Preemption := Log_Table (ID).Preemption + 1;
      end if;
   end Add_Preemption;

   procedure Print_Log (First_Index : Integer) is
      i : Integer := First_Index;
   begin
      while i <= Max_ID_Table loop
         System.IO.Put ("Tab;");
         System.IO.Put (Integer'Image (i));
         System.IO.Put (Integer'Image (Log_Table (i).DM));
         System.IO.Put (Integer'Image (Log_Table (i).Runs));
         System.IO.Put (Integer'Image (Log_Table (i).Preemption));
         System.IO.Put_Line ("");
         i := i + 1;
      end loop;

   end Print_Log;

   ---------------------
   -- Change_Priority --
   ---------------------

   procedure Change_Priority (Thread : Thread_Id; Priority : Integer)
   is
      CPU_Id       : constant CPU := BOSUMU.Current_CPU;
      Head         : Thread_Id;
      Prev_Pointer : Thread_Id;

   begin
      --  A CPU can only change the priority of its own tasks

      pragma Assert (CPU_Id = Get_CPU (Thread));

      --  Return now if there is no change. This is a rather common case, as
      --  it happens if user is not using priorities, or if the priority of
      --  an interrupt handler is the same as the priority of the interrupt.
      --  In any case, the check is quick enough.

      if Thread.Active_Priority = Priority then
         return;
      end if;

      --  Change the active priority. The base priority does not change

      Thread.Active_Priority := Priority;

      --  Outside of the executive kernel, the running thread is also the first
      --  thread in the First_Thread_Table list. This is also true in general
      --  within the kernel, except during transcient period when a task is
      --  extracted from the list (blocked by a delay until or on an entry),
      --  when a task is inserted (after a wakeup), after a yield or after
      --  this procedure. But then a context_switch put things in order.

      --  However, on ARM Cortex-M, context switches can be delayed by
      --  interrupts. They are performed via a special interrupt (Pend_SV),
      --  which is at the lowest priority. This has three consequences:
      --   A) it is not possible to have tasks in the Interrupt_Priority range
      --   B) the head of First_Thread_Table list may be different from the
      --      running thread within user interrupt handler
      --   C) the running thread may not be in the First_Thread_Table list.
      --  The following scenario shows case B: while a thread is running, an
      --  interrupt awakes a task at a higher priority; it is put in front of
      --  the First_Thread_Table queue, and a context switch is requested. But
      --  before the end of the interrupt, another interrupt triggers. It
      --  increases the priority of  the current thread, which is not the
      --  first in queue.
      --  The following scenario shows case C: a task is executing a delay
      --  until and therefore it is removed from the First_Thread_Table. But
      --  before the context switch, an interrupt triggers and change the
      --  priority of the running thread.

      --  First, find THREAD in the queue and remove it temporarly.

      Head := First_Thread_Table (CPU_Id);

      if Head = Thread then

         --  This is the very common case: THREAD is the first in the queue

         if Thread.Next = Null_Thread_Id
           or else Priority >= Thread.Next.Active_Priority
         then
            --  Already at the right place.
            return;
         end if;

         --  Remove THREAD from the queue

         Head := Thread.Next;
      else

         --  Uncommon case: less than 0.1% on a Cortex-M test.

         --  Search the thread before THREAD.

         Prev_Pointer := Head;
         loop
            if Prev_Pointer = null then
               --  THREAD is not in the queue. This corresponds to case B.
               return;
            end if;

            exit when Prev_Pointer.Next = Thread;

            Prev_Pointer := Prev_Pointer.Next;
         end loop;

         --  Remove THREAD from the queue.

         Prev_Pointer.Next := Thread.Next;
      end if;

      --  Now insert THREAD.

      --  FIFO_Within_Priorities dispatching policy. In ALRM D.2.2 it is
      --  said that when the active priority is lowered due to the loss of
      --  inherited priority (the only possible case within the Ravenscar
      --  profile) the task is added at the head of the ready queue for
      --  its new active priority.

      if Priority >= Head.Active_Priority then

         --  THREAD is the highest priority thread, so put it in the front of
         --  the queue.

         Thread.Next := Head;
         Head := Thread;
      else

         --  Search the right place in the queue.

         Prev_Pointer := Head;
         while Prev_Pointer.Next /= Null_Thread_Id
           and then Priority < Prev_Pointer.Next.Active_Priority
         loop
            Prev_Pointer := Prev_Pointer.Next;
         end loop;

         Thread.Next := Prev_Pointer.Next;
         Prev_Pointer.Next := Thread;
      end if;

      First_Thread_Table (CPU_Id) := Head;
   end Change_Priority;

   ---------------------------
   -- Change_Fake_Number_ID --
   ---------------------------

   procedure Change_Fake_Number_ID
     (Thread       : Thread_Id;
      Fake_Number_ID : Integer)
   is
   begin
      Thread.Fake_Number_ID := Fake_Number_ID;
   end Change_Fake_Number_ID;

   ------------------------
   -- Change_Is_Sporadic --
   ------------------------

   procedure Change_Is_Sporadic
     (Thread       : Thread_Id;
      Bool : Boolean)
   is
   begin
      Thread.Is_Sporadic := Bool;
   end Change_Is_Sporadic;

   ------------------------------
   -- Change_Relative_Deadline --
   ------------------------------

   procedure Change_Relative_Deadline
     (Thread       : Thread_Id;
      Rel_Deadline : System.BB.Deadlines.Relative_Deadline;
      Is_Floor     : Boolean)  --  useless for FPS, set what you want
   is
      pragma Unreferenced (Is_Floor);
      CPU_Id      : constant CPU := Get_CPU (Thread);
   begin
      --  A CPU can only change the relative deadline of its own tasks

      pragma Assert (CPU_Id = Current_CPU);

      --  We can only change the priority of the thread that is
      --  currently executing.

      pragma Assert (Thread = Running_Thread_Table (CPU_Id));

      --  Change the active relative deadline. The base relative deadline does
      --  not change
      Thread.Active_Relative_Deadline := Rel_Deadline;

      if Thread.Active_Relative_Deadline <= Thread.Active_Period then
         Change_Absolute_Deadline (Thread, System.BB.Time.Time_First +
                                   Thread.Active_Starting_Time -
                     (Thread.Active_Period - Thread.Active_Relative_Deadline)
                                  + Global_Interrupt_Delay);
      else
         Change_Absolute_Deadline (Thread, System.BB.Time.Time_First +
                                   Thread.Active_Starting_Time +
                     (Thread.Active_Relative_Deadline - Thread.Active_Period)
                                    + Global_Interrupt_Delay);

      end if;

   end Change_Relative_Deadline;

   -------------------
   -- Change_Period --
   -------------------

   procedure Change_Period
     (Thread       : Thread_Id;
      Period       : System.BB.Time.Time_Span)
   is
      CPU_Id      : constant CPU := Get_CPU (Thread);
   begin
      pragma Assert (CPU_Id = Current_CPU);
      pragma Assert (Thread = Running_Thread_Table (CPU_Id));
      Thread.Active_Period := Period;
   end Change_Period;

   --------------------------
   -- Change_Starting_Time --
   --------------------------

   procedure Change_Starting_Time
     (Thread        : Thread_Id;
      Starting_Time : System.BB.Time.Time_Span)
   is
      CPU_Id      : constant CPU := Get_CPU (Thread);
   begin
      pragma Assert (CPU_Id = Current_CPU);
      pragma Assert (Thread = Running_Thread_Table (CPU_Id));
      Thread.Active_Starting_Time := Starting_Time;
      Thread.Active_Next_Period := System.BB.Time.Time_First +
          (Starting_Time - Thread.Active_Period);
   end Change_Starting_Time;

   ---------------------------
   -- Change_Release_Jitter --
   ---------------------------

   procedure Change_Release_Jitter
     (Thread        : Thread_Id)
   is
      CPU_Id      : constant CPU := Get_CPU (Thread);
      Temp : System.BB.Time.Time_Span;
   begin
      pragma Assert (CPU_Id = Current_CPU);
      pragma Assert (Thread = Running_Thread_Table (CPU_Id));

      if Thread.Just_Wakeup = True then
         Temp := System.BB.Time.Clock - Thread.Active_Next_Period;
         Thread.Active_Release_Jitter := System.BB.Time.Time_First + (Temp);
         Thread.Just_Wakeup := False;
      end if;
   end Change_Release_Jitter;

   -----------------
   -- Set_Jitters --
   -----------------

   procedure Update_Jitters
     (Thread      : Thread_Id;
      Response_Jitter : System.BB.Time.Time_Span;
      Release_Jitter : System.BB.Time.Time_Span)
   is
      CPU_Id      : constant CPU := Get_CPU (Thread);
   begin
      pragma Assert (CPU_Id = Current_CPU);
      pragma Assert (Thread = Running_Thread_Table (CPU_Id));

      if Log_Table (Thread.Fake_Number_ID).Average_Response_Jitter
        = System.BB.Time.Time_Span_Zero
      then
         Log_Table (Thread.Fake_Number_ID).Average_Response_Jitter :=
           Response_Jitter;
      else
         Log_Table (Thread.Fake_Number_ID).Average_Response_Jitter :=
           ((Log_Table (Thread.Fake_Number_ID).Average_Response_Jitter *
              Log_Table (Thread.Fake_Number_ID).Runs) +
              Response_Jitter)
           / (Log_Table (Thread.Fake_Number_ID).Runs + 1);
      end if;

      if Response_Jitter <
        Log_Table (Thread.Fake_Number_ID).Min_Response_Jitter
      then
         Log_Table (Thread.Fake_Number_ID).Min_Response_Jitter :=
           Response_Jitter;
      end if;

      if Response_Jitter >
        Log_Table (Thread.Fake_Number_ID).Max_Response_Jitter
      then
         Log_Table (Thread.Fake_Number_ID).Max_Response_Jitter :=
           Response_Jitter;
      end if;

      if Release_Jitter <
        Log_Table (Thread.Fake_Number_ID).Min_Release_Jitter
      then
         Log_Table (Thread.Fake_Number_ID).Min_Release_Jitter :=
           Release_Jitter;
      end if;

      if Release_Jitter >
        Log_Table (Thread.Fake_Number_ID).Max_Release_Jitter
      then
         Log_Table (Thread.Fake_Number_ID).Max_Release_Jitter :=
           Release_Jitter;
      end if;

   end Update_Jitters;

   ------------------------------
   -- Change_Absolute_Deadline --
   ------------------------------

   procedure Change_Absolute_Deadline
     (Thread       : Thread_Id;
      Abs_Deadline : System.BB.Deadlines.Absolute_Deadline)
   is
      --  Previous_Thread, Next_Thread : Thread_Id;
      CPU_Id      : constant CPU := Get_CPU (Thread);

   begin
      --  A CPU can only change the absolute deadline of its own tasks
      pragma Assert (CPU_Id = Current_CPU);

      pragma Assert (Thread = Running_Thread_Table (CPU_Id));

      --  Ada.Text_IO.Put_Line (Integer'Image (Thread.Base_Priority) &
      --            Duration'Image (To_Duration (Thread.Period)) & " " &
      --                  Duration'Image (To_Duration (Thread.Active_Period)));

      --  Ada.Text_IO.Put_Line (Integer'Image (Thread.Base_Priority) & ": " &
      --             Duration'Image (To_Duration (Time_Span (Abs_Deadline))));
      --  Ada.Text_IO.Put_Line ("C:" & Integer'Image
      --                      (Thread.Data_Concerning_Migration.Id));
      Thread.First_Time_On_Delay_Until := False;
      Thread.Active_Absolute_Deadline := Abs_Deadline;
      Thread.Data_Concerning_Migration.Stored_Absolute_Deadline
                                                            := Abs_Deadline;

   end Change_Absolute_Deadline;

   ---------------------------
   -- Context_Switch_Needed --
   ---------------------------

   function Context_Switch_Needed return Boolean is
      --  Start_Time   : constant System.BB.Time.Time := Clock;
      Is_CS_Needed : Boolean;
      --  CPU_Id       : constant CPU := BOSUMU.Current_CPU;
   begin
      --  A context switch is needed when there is a higher priority task ready
      --  to execute. It means that First_Thread is not null and it is not
      --  equal to the task currently executing (Running_Thread).

      Is_CS_Needed := (First_Thread /= Running_Thread);

      if Is_CS_Needed and Running_Thread.Preemption_Needed
      then
         Add_Preemption (Running_Thread.Fake_Number_ID);
      end if;

      --  MBTA.Log_RTE_Primitive_Duration
      --    (MBTA.CSN, To_Duration (Clock - Start_Time), CPU_Id);
      return Is_CS_Needed;
   end Context_Switch_Needed;

   ----------------------
   -- Current_Priority --
   ----------------------

   function Current_Priority
     (CPU_Id : System.Multiprocessors.CPU) return Integer
   is
      Thread : constant Thread_Id := Running_Thread_Table (CPU_Id);
   begin
      if Thread = null or else Thread.State /= Threads.Runnable then
         return System.Any_Priority'First;
      else
         return Thread.Active_Priority;
      end if;
   end Current_Priority;

   -------------
   -- Extract --
   -------------

   procedure Extract (Thread : Thread_Id) is
      CPU_Id : constant CPU := Get_CPU (Thread);
   begin
      --  A CPU can only modify its own tasks queues

      pragma Assert (CPU_Id = Current_CPU);

      First_Thread_Table (CPU_Id) := Thread.Next;
      Thread.Next := Null_Thread_Id;
   end Extract;

   -------------------------
   -- Extract_First_Alarm --
   -------------------------

   function Extract_First_Alarm return Thread_Id is
      CPU_Id : constant CPU       := Current_CPU;
      Result : constant Thread_Id := Alarms_Table (CPU_Id);

   begin
      --  A CPU can only modify its own tasks queues

      pragma Assert (CPU_Id = Current_CPU);

      Alarms_Table (CPU_Id) := Result.Next_Alarm;
      Result.Alarm_Time := System.BB.Time.Time'Last;
      Result.Next_Alarm := Null_Thread_Id;
      return Result;
   end Extract_First_Alarm;

   ------------------
   -- First_Thread --
   ------------------

   function First_Thread return Thread_Id is
   begin
      return First_Thread_Table (Current_CPU);
   end First_Thread;

   -------------------------
   -- Get_Next_Alarm_Time --
   -------------------------

   function Get_Next_Alarm_Time (CPU_Id : CPU) return System.BB.Time.Time is
      Thread : Thread_Id;

   begin
      Thread := Alarms_Table (CPU_Id);

      if Thread = Null_Thread_Id then

         --  If alarm queue is empty then next alarm to raise will be Time'Last

         return System.BB.Time.Time'Last;

      else
         return Thread.Alarm_Time;
      end if;
   end Get_Next_Alarm_Time;

   ------------
   -- Insert --
   ------------

   procedure Insert (Thread : Thread_Id) is
      Aux_Pointer : Thread_Id;
      CPU_Id      : constant CPU := Get_CPU (Thread);

   begin
      --  ??? This pragma is disabled because the Tasks_Activated only
      --  represents the end of activation for one package not all the
      --  packages. We have to find a better milestone for the end of
      --  tasks activation.

      --  --  A CPU can only insert alarm in its own queue, except during
      --  --  initialization.

      --  pragma Assert (CPU_Id = Current_CPU or else not Tasks_Activated);

      --  It may be the case that we try to insert a task that is already in
      --  the queue. This can only happen if the task was not runnable and its
      --  context was being used for handling an interrupt. Hence, if the task
      --  is already in the queue and we try to insert it, we need to check
      --  whether it is in the correct place.

      --  No insertion if the task is already at the head of the queue
      if First_Thread_Table (CPU_Id) = Thread then
         null;
      --  Insert at the head of queue if there is no other thread with a higher
      --  priority.
      elsif First_Thread_Table (CPU_Id) = Null_Thread_Id
        or else
          Thread.Active_Priority > First_Thread_Table (CPU_Id).Active_Priority
      then
         Thread.Next := First_Thread_Table (CPU_Id);
         First_Thread_Table (CPU_Id) := Thread;
      --  Middle or tail insertion

      else
         --  Look for the Aux_Pointer to insert the thread just after it

         Aux_Pointer := First_Thread_Table (CPU_Id);
         while Aux_Pointer.Next /= Null_Thread_Id
           and then Aux_Pointer.Next /= Thread
           and then Aux_Pointer.Next.Active_Priority >= Thread.Active_Priority
         loop
            Aux_Pointer := Aux_Pointer.Next;
         end loop;

         --  If we found the thread already in the queue, then we need to move
         --  it to its right place.

         if Aux_Pointer.Next = Thread then

            --  Extract it from its current location

            Aux_Pointer.Next := Thread.Next;

            --  Look for the Aux_Pointer to insert the thread just after it

            while Aux_Pointer.Next /= Null_Thread_Id
              and then
                Aux_Pointer.Next.Active_Priority >= Thread.Active_Priority
            loop
               Aux_Pointer := Aux_Pointer.Next;
            end loop;
         end if;

         --  Insert the thread after the Aux_Pointer

         Thread.Next := Aux_Pointer.Next;
         Aux_Pointer.Next := Thread;
      end if;

   end Insert;

   ------------------
   -- Insert_Alarm --
   ------------------

   procedure Insert_Alarm
     (T        : System.BB.Time.Time;
      Thread   : Thread_Id;
      Is_First : out Boolean)
   is
      CPU_Id       : constant CPU := Get_CPU (Thread);
      Alarm_Id_Aux : Thread_Id;

   begin
      --  A CPU can only insert alarm in its own queue

      --  pragma Assert (CPU_Id = Current_CPU);

      --  Set the Alarm_Time within the thread descriptor

      Thread.Alarm_Time := T;

      --  Case of empty queue, or new alarm expires earlier, insert the thread
      --  as the first thread.

      if Alarms_Table (CPU_Id) = Null_Thread_Id
        or else T < Alarms_Table (CPU_Id).Alarm_Time
      then
         Thread.Next_Alarm := Alarms_Table (CPU_Id);
         Alarms_Table (CPU_Id) := Thread;
         Is_First := True;

      --  Otherwise, place in the middle

      else
         --  Find the minimum greater than T alarm within the alarm queue
         Alarm_Id_Aux := Alarms_Table (CPU_Id);
         while Alarm_Id_Aux.Next_Alarm /= Null_Thread_Id and then
           Alarm_Id_Aux.Next_Alarm.Alarm_Time < T
         loop
            Alarm_Id_Aux := Alarm_Id_Aux.Next_Alarm;
         end loop;

         Thread.Next_Alarm := Alarm_Id_Aux.Next_Alarm;
         Alarm_Id_Aux.Next_Alarm := Thread;

         Is_First := False;
      end if;
   end Insert_Alarm;

   --------------------
   -- Running_Thread --
   --------------------

   function Running_Thread return Thread_Id is
   begin
      return Running_Thread_Table (Current_CPU);
   end Running_Thread;

   ------------------------------------
   --  Wakeup_Thread_Has_To_Migrate  --
   ------------------------------------

   function Wakeup_Thread_Has_To_Migrate
      (Wakeup_Thread : Thread_Id)
      return Boolean;

   function Wakeup_Thread_Has_To_Migrate
      (Wakeup_Thread : Thread_Id)
      return Boolean
   is
   begin
      --  A Wakeup thread has to migrate to the other CPU iff:
      --    1. it is migrable;
      --    2. it is on its Base_CPU
      --    3. its CPU is in HI-crit mode
      --  In this way, a thread migrates iff it is actually Runnable.
      --  It wouldn't make much sense to migrate Sleeping threads.
      return
         Wakeup_Thread.Is_Migrable
            and
         Wakeup_Thread.Base_CPU = Wakeup_Thread.Active_CPU
            and
         Get_Core_Mode (Wakeup_Thread.Base_CPU) = HIGH;

   end Wakeup_Thread_Has_To_Migrate;

   ----------------------------------------
   --  Wakeup_Thread_Has_To_Be_Restored  --
   ----------------------------------------

   function Wakeup_Thread_Has_To_Be_Restored
      (Wakeup_Thread : Thread_Id)
      return Boolean;

   function Wakeup_Thread_Has_To_Be_Restored
      (Wakeup_Thread : Thread_Id)
      return Boolean
   is
   begin
      --  A Wakeup thread has to be restored on its Base_CPU iff:
      --    1. it is migrable;
      --    2. it is NOT on its Base_CPU
      --    3. its CPU is in LO-crit mode
      --  In this way, a thread migrates iff it is actually Runnable.
      --  It wouldn't make much sense to migrate Sleeping threads.
      return
         Wakeup_Thread.Is_Migrable
            and
         Wakeup_Thread.Base_CPU /= Wakeup_Thread.Active_CPU
            and
         Get_Core_Mode (Wakeup_Thread.Base_CPU) = LOW;

   end Wakeup_Thread_Has_To_Be_Restored;

   ------------------------------------------------
   --  Wakeup_Thread_Is_Hosting_Migrating_Tasks  --
   ------------------------------------------------

   function Wakeup_Thread_Is_Hosting_Migrating_Tasks
      (Wakeup_Thread : Thread_Id)
       return Boolean;

   function Wakeup_Thread_Is_Hosting_Migrating_Tasks
     (Wakeup_Thread : Thread_Id) return Boolean is
      Target_CPU : CPU := CPU'First;
   begin
      if Wakeup_Thread.Base_CPU = CPU'First then
         Target_CPU := CPU'Last;
      end if;
      --  A Wakeup_Thread, on a LO-crit mode CPU,
      --  has to change its current (active) priority iff
      --  it core is hosting the other core's migratings tasks, i.e.:
      --    1. it is on its Base_CPU
      --    2. its Base_CPU is executing in LO-crit mode
      --    3. the other CPU is executing in HI-crit mode
      return
        Wakeup_Thread.Active_CPU = Wakeup_Thread.Base_CPU
            and
        Get_Core_Mode (Wakeup_Thread.Base_CPU) = LOW
            and
        Get_Core_Mode (Target_CPU) = HIGH
            and
        Wakeup_Thread.Base_Priority < 238;
      --  We exclude final tasks (238 & 239) which stuck both CPUs
      --  in order to print log data
   end Wakeup_Thread_Is_Hosting_Migrating_Tasks;

   ---------------------------
   -- Wakeup_Expired_Alarms --
   ---------------------------

   procedure Wakeup_Expired_Alarms (Now : Time.Time) is
      CPU_Id        : constant CPU := Current_CPU;
      CPU_Target    : CPU          := CPU'Last;
      Wakeup_Thread : Thread_Id;
   begin
      --  Extract all the threads whose delay has expired
      if CPU_Id = CPU'Last then
         CPU_Target := CPU'First;
      end if;

      while Get_Next_Alarm_Time (CPU_Id) <= Now loop

         --  Extract the task(s) that was waiting in the alarm queue and insert
         --  it in the ready queue.

         Wakeup_Thread := Extract_First_Alarm;

         --  We can only awake tasks that are delay statement

         pragma Assert (Wakeup_Thread.State = Delayed);

         Wakeup_Thread.State := Runnable;

         Wakeup_Thread.Preemption_Needed := True;

         Change_Absolute_Deadline (Wakeup_Thread,
                                   (Wakeup_Thread.Period + Clock));

         --  Update reduced deadline value if current task is a migrating one.
         --  if Wakeup_Thread.Is_Migrable then
         --   Wakeup_Thread.Data_Concerning_Migration.Reduced_Absolute_Deadline
         --  := Wakeup_Thread.Data_Concerning_Migration.Reduced_Period + Clock;
         --  end if;

         Wakeup_Thread.Just_Wakeup := True;
         Wakeup_Thread.Active_Next_Period := Wakeup_Thread.Active_Next_Period
           + Wakeup_Thread.Active_Period;

         if Wakeup_Thread_Has_To_Migrate (Wakeup_Thread) then
            Wakeup_Thread.Active_CPU := CPU_Target;

            Wakeup_Thread.Active_Priority := Wakeup_Thread.
                Data_Concerning_Migration.On_Target_Core_Priority;

            Wakeup_Thread.Log_Table.Times_Migrated :=
                                    Wakeup_Thread.Log_Table.Times_Migrated + 1;

         elsif Wakeup_Thread_Has_To_Be_Restored (Wakeup_Thread) then
            Wakeup_Thread.Active_CPU := Wakeup_Thread.Base_CPU;

            Wakeup_Thread.Active_Priority := Wakeup_Thread.Base_Priority;

            Wakeup_Thread.Log_Table.Times_Restored :=
                                  Wakeup_Thread.Log_Table.Times_Restored + 1;

         elsif Wakeup_Thread_Is_Hosting_Migrating_Tasks (Wakeup_Thread) then

            Wakeup_Thread.Active_Priority :=
              Wakeup_Thread.Data_Concerning_Migration.
                Hosting_Migrating_Tasks_Priority;

            --  Ada.Text_IO.Put_Line(Integer'Image(Wakeup_Thread.Base_Priority)
            --                        & " on core " & CPU'Image (CPU_Target) &
            --                          " WAKING migrated priority to " &
         --                    Integer'Image (Wakeup_Thread.Active_Priority));
         else
            Wakeup_Thread.Active_Priority := Wakeup_Thread.Base_Priority;
         end if;

         --  Ada.Text_IO.Put_Line (Integer'Image (Wakeup_Thread.Base_Priority)
         --   & " released with " &
         --   Duration'Image (To_Duration (Wakeup_Thread.Active_Budget)));

         Lock (Ready_Tables_Locks (Wakeup_Thread.Active_CPU).all);
         Insert (Wakeup_Thread);
         Unlock (Ready_Tables_Locks (Wakeup_Thread.Active_CPU).all);

      end loop;

      --  Note: the caller (BB.Time.Alarm_Handler) must set the next alarm
   end Wakeup_Expired_Alarms;

   -----------
   -- Yield --
   -----------

   procedure Yield (Thread : Thread_Id) is
      CPU_Id      : constant CPU     := Get_CPU (Thread);
      Prio        : constant Integer := Thread.Active_Priority;
      Aux_Pointer : Thread_Id;
      Cancelled   : Boolean;
      pragma Unreferenced (Cancelled);
   --   Now         : System.BB.Time.Time;
   begin
      --  A CPU can only modify its own tasks queues

      pragma Assert (CPU_Id = Current_CPU);

      Thread.Just_Wakeup := True;
      Thread.Active_Next_Period := Thread.Active_Next_Period +
        Thread.Active_Period;

      if Thread.Next /= Null_Thread_Id
        and then Thread.Next.Active_Priority = Prio
      then
         --  Stop budget monitoring.
         Thread.T_Clear := System.BB.Time.Clock;
         CPU_Budget_Monitor.Clear_Monitor (Cancelled);

         First_Thread_Table (CPU_Id) := Thread.Next;

         --  Look for the Aux_Pointer to insert the thread just after it

         Aux_Pointer  := First_Thread_Table (CPU_Id);
         while Aux_Pointer.Next /= Null_Thread_Id
           and then Prio = Aux_Pointer.Next.Active_Priority
         loop
            Aux_Pointer := Aux_Pointer.Next;
         end loop;

         --  Insert the thread after the Aux_Pointer

         Thread.Next := Aux_Pointer.Next;
         Aux_Pointer.Next := Thread;
      end if;

   end Yield;

   ------------------
   -- Queue_Length --
   ------------------

   function Queue_Length return Natural is
      Res : Natural   := 0;
      T   : Thread_Id := First_Thread_Table (Current_CPU);

   begin
      while T /= null loop
         Res := Res + 1;
         T := T.Next;
      end loop;

      return Res;
   end Queue_Length;

   -------------------
   -- Queue_Ordered --
   -------------------

   function Queue_Ordered return Boolean is
      T : Thread_Id := First_Thread_Table (Current_CPU);
      N : Thread_Id;

   begin
      if T = Null_Thread_Id then
         --  True if the queue is empty
         return True;
      end if;

      loop
         N := T.Next;
         if N = Null_Thread_Id then
            --  True if at end of the queue
            return True;
         end if;

         if T.Active_Priority < N.Active_Priority then
            return False;
         end if;

         T := N;
      end loop;
   end Queue_Ordered;

   ------------------------
   --  Insert_Discarded  --
   ------------------------

   procedure Insert_Discarded (Thread : Thread_Id) is
   begin
      Lock (Discarded_Table_Lock);

      Thread.Next := Discarded_Thread_Table;
      Discarded_Thread_Table := Thread;

      Unlock (Discarded_Table_Lock);
      --  Print_Queues;
   end Insert_Discarded;

   -------------------------
   --  Extract_Discarded  --
   -------------------------

   function Extract_Discarded return Thread_Id is
      Aux_Pointer : constant Thread_Id := Discarded_Thread_Table;
   begin
      Lock (Discarded_Table_Lock);

      if Discarded_Thread_Table /= Null_Thread_Id then
         Discarded_Thread_Table := Discarded_Thread_Table.Next;
         Aux_Pointer.Next := Null_Thread_Id;
      end if;

      Unlock (Discarded_Table_Lock);

      return Aux_Pointer;
   end Extract_Discarded;

   ------------------------
   --  Insert_High_Crit  --
   ------------------------
   procedure Insert_High_Crit (Thread : Thread_Id);

   procedure Insert_High_Crit (Thread : Thread_Id) is
      CPU_Id : constant CPU := Current_CPU;
   begin
      Thread.Next_HI_Crit := HI_Crit_Table (CPU_Id);
      HI_Crit_Table (CPU_Id) := Thread;
   end Insert_High_Crit;

   --------------------
   --  Print_Queues  --
   --------------------

   procedure Print_Queues is
      Aux_Pointer : Thread_Id;
      T2 : Integer := -100;
   begin

      Aux_Pointer := First_Thread_Table (CPU'First);
      Ada.Text_IO.Put_Line ("--  PRINT QUEUES  --");

      Ada.Text_IO.Put_Line ("Queues on CPU 1");
      Ada.Text_IO.Put_Line ("Ready");
      while Aux_Pointer /= Null_Thread_Id
      loop
         T2 := Aux_Pointer.Data_Concerning_Migration.Id;
         Ada.Text_IO.Put ("[" & Integer'Image (T2) & "]");
         Aux_Pointer := Aux_Pointer.Next;
      end loop;

      Aux_Pointer := Alarms_Table (CPU'First);
      Ada.Text_IO.Put_Line ("");
      Ada.Text_IO.Put_Line ("Alarms");

      while Aux_Pointer /= Null_Thread_Id
      loop
         T2 := Aux_Pointer.Data_Concerning_Migration.Id;
         Ada.Text_IO.Put ("[" & Integer'Image (T2) & "]");
         Aux_Pointer := Aux_Pointer.Next_Alarm;
      end loop;

      Aux_Pointer := HI_Crit_Table (CPU'First);
      Ada.Text_IO.Put_Line ("");
      Ada.Text_IO.Put_Line ("HI-CRIT");

      while Aux_Pointer /= Null_Thread_Id
      loop
         T2 := Aux_Pointer.Data_Concerning_Migration.Id;
         Ada.Text_IO.Put ("[" & Integer'Image (T2) & "]");
         Aux_Pointer := Aux_Pointer.Next_HI_Crit;
      end loop;

      Aux_Pointer := First_Thread_Table (CPU'Last);
      Ada.Text_IO.Put_Line ("");
      Ada.Text_IO.Put_Line ("Queues on CPU 2");
      Ada.Text_IO.Put_Line ("Ready");

      while Aux_Pointer /= Null_Thread_Id
      loop
         T2 := Aux_Pointer.Data_Concerning_Migration.Id;
         Ada.Text_IO.Put ("[" & Integer'Image (T2) & "]");
         Aux_Pointer := Aux_Pointer.Next;
      end loop;

      Aux_Pointer := Alarms_Table (CPU'Last);
      Ada.Text_IO.Put_Line ("");
      Ada.Text_IO.Put_Line ("Alarms");

      while Aux_Pointer /= Null_Thread_Id
      loop
         T2 := Aux_Pointer.Data_Concerning_Migration.Id;
         Ada.Text_IO.Put ("[" & Integer'Image (T2) & "]");
         Aux_Pointer := Aux_Pointer.Next_Alarm;
      end loop;

      Aux_Pointer := HI_Crit_Table (CPU'Last);
      Ada.Text_IO.Put_Line ("");
      Ada.Text_IO.Put_Line ("HI-CRIT");

      while Aux_Pointer /= Null_Thread_Id
      loop
         T2 := Aux_Pointer.Data_Concerning_Migration.Id;
         Ada.Text_IO.Put ("[" & Integer'Image (T2) & "]");
         Aux_Pointer := Aux_Pointer.Next_HI_Crit;
      end loop;

      Lock (Discarded_Table_Lock);
      Aux_Pointer := Discarded_Thread_Table;
      Ada.Text_IO.Put_Line ("");
      Ada.Text_IO.Put_Line ("Discarded");

      while Aux_Pointer /= Null_Thread_Id
      loop
         T2 := Aux_Pointer.Base_Priority;
         Ada.Text_IO.Put ("[" & Integer'Image (T2) & "]");
         Aux_Pointer := Aux_Pointer.Next;
      end loop;

      Unlock (Discarded_Table_Lock);
      Ada.Text_IO.Put_Line ("");
      Ada.Text_IO.Put_Line ("--  END QUEUES  --");

   end Print_Queues;

   -------------------------------
   --  Initialize_LO_Crit_Task  --
   -------------------------------

   procedure Initialize_LO_Crit_Task
     (Thread : Thread_Id;
       Task_Id : Natural;
       LO_Crit_Budget : System.BB.Time.Time_Span;
        Hosting_Migrating_Tasks_Priority : Integer;
        On_Target_Core_Priority : Integer;
      Period : Natural;
      Reduced_Deadline : Natural;
      Is_Migrable : Boolean) is
      use Mixed_Criticality_System;
   begin
      Change_Fake_Number_ID (Thread, Task_Id);

      Thread.Data_Concerning_Migration.Id := Task_Id;

      Thread.Low_Critical_Budget := LO_Crit_Budget;
      Thread.High_Critical_Budget := LO_Crit_Budget;
      Thread.Active_Budget := Thread.Low_Critical_Budget;
      Thread.Is_Monitored := True;

      Thread.Data_Concerning_Migration.
        Hosting_Migrating_Tasks_Priority := Hosting_Migrating_Tasks_Priority;

      Thread.Data_Concerning_Migration.On_Target_Core_Priority :=
        On_Target_Core_Priority;

      Thread.Data_Concerning_Migration.Reduced_Period :=
                      System.BB.Time.Microseconds (Reduced_Deadline);

      Thread.Period := System.BB.Time.Microseconds (Period);
      Thread.Criticality_Level := LOW;

      Thread.First_Time_On_Delay_Until := True;

      Thread.Is_Migrable := Is_Migrable;
   end Initialize_LO_Crit_Task;

   -------------------------------
   --  Initialize_HI_Crit_Task  --
   -------------------------------

   procedure Initialize_HI_Crit_Task
     (Thread : Thread_Id;
      Task_Id : Natural;
     LO_Crit_Budget : System.BB.Time.Time_Span;
      HI_Crit_Budget : System.BB.Time.Time_Span;
      Hosting_Migrating_Tasks_Priority : Integer;
     Period : Natural) is
      use Mixed_Criticality_System;
   begin
      Change_Fake_Number_ID (Thread, Task_Id);

      Thread.Data_Concerning_Migration.Id := Task_Id;

      Thread.Low_Critical_Budget := LO_Crit_Budget;
      Thread.High_Critical_Budget := HI_Crit_Budget;
      Thread.Active_Budget := Thread.Low_Critical_Budget;
      Thread.Is_Monitored := True;

      Thread.Data_Concerning_Migration.
        Hosting_Migrating_Tasks_Priority := Hosting_Migrating_Tasks_Priority;

      --  Thread.Hosting_Migrating_Tasks_Priority :=
      --                  Hosting_Migrating_Tasks_Priority;
      --  Thread.On_Target_Core_Priority := -1;

      Thread.Period := System.BB.Time.Microseconds (Period);
      Thread.Criticality_Level := HIGH;

      Thread.First_Time_On_Delay_Until := True;

      Insert_High_Crit (Thread);
   end Initialize_HI_Crit_Task;

   ---------------------
   --  Migrate_Tasks  --
   ---------------------

   procedure Migrate_Tasks (What_To_Do : Action);

   procedure Migrate_Tasks (What_To_Do : Action) is
      CPU_Id       : constant CPU := Current_CPU;
      CPU_Target   : CPU          := CPU'Last;
      Prev_Pointer : Thread_Id    := Null_Thread_Id;
      Aux_Pointer  : Thread_Id;
      Curr_Pointer : Thread_Id;
   begin
      if CPU_Id = CPU'Last then
         CPU_Target := CPU'First;
      end if;

      Lock (Ready_Tables_Locks (CPU'First).all);
      Lock (Ready_Tables_Locks (CPU'Last).all);

      Aux_Pointer  := First_Thread_Table (CPU_Id);
      Curr_Pointer := First_Thread_Table (CPU_Id);
      --  First extract from READY queue
      while Curr_Pointer /= Null_Thread_Id
      loop
            if Curr_Pointer.Is_Migrable then

               if Curr_Pointer = First_Thread_Table (CPU_Id) then
                  --  The first thread is migrable, so it must be removed.
                  --  This means that the second thread in the queue,
                  --  i.e. Curr_Pointer.Next, must be set
                  --  as the first thread in the queue.
                  First_Thread_Table (CPU_Id) := Curr_Pointer.Next;
               else
                  --  We have to remove a thread between two others
                  --  (the last one could be the Null thread).
                  --  This means that the previous thread in the queue
                  --  must be linked to the last one.
                  Prev_Pointer.Next := Curr_Pointer.Next;
               end if;

               --  Go ahead with the aux pointer.
               Aux_Pointer := Aux_Pointer.Next;

               --  Isolate the current thread.
               Curr_Pointer.Next := Null_Thread_Id;

               if What_To_Do = Migrate then
                  --  Log migration
                  Curr_Pointer.Log_Table.Times_Migrated
                                 := Curr_Pointer.Log_Table.Times_Migrated + 1;

                  --  Log that this task's current job release is suffering
                  --  migration overhead.
                  Executions (Curr_Pointer.Data_Concerning_Migration.Id).
                              Migration_Happened_Current_Job_Release := True;

                  --  Change Active CPU
                  Curr_Pointer.Active_CPU := CPU_Target;

                  --  Change Active priority
                  Curr_Pointer.Active_Priority := Curr_Pointer.
                       Data_Concerning_Migration.On_Target_Core_Priority;

                  --  Set deadline to the reduced one.
                  --  Curr_Pointer.Active_Absolute_Deadline := Curr_Pointer.
                  --      Data_Concerning_Migration.Reduced_Absolute_Deadline;

                  Insert (Curr_Pointer);
               elsif What_To_Do = Discard then

                  --  Log discarding and insert in the Discarded queue.
                  Curr_Pointer.State := Discarded;
                  Curr_Pointer.Log_Table.Times_Discarded
                                 := Curr_Pointer.Log_Table.Times_Discarded + 1;
                  Insert_Discarded (Curr_Pointer);
               end if;

               --  Go ahead with the current pointer.
               Curr_Pointer := Aux_Pointer;

            else --  Current thread is NOT migrable
               --  then go ahead normally
               Prev_Pointer := Curr_Pointer;
               Aux_Pointer := Aux_Pointer.Next;
               Curr_Pointer := Aux_Pointer;
            end if;
      end loop;

      CPU_Log_Table (CPU_Target).Start_Hosting_Mig := Clock;
      CPU_Log_Table (CPU_Target).Hosting_Mig_Tasks := True;

      Unlock (Ready_Tables_Locks (CPU'First).all);
      Unlock (Ready_Tables_Locks (CPU'Last).all);

   end Migrate_Tasks;

   ---------------------
   --  Restore_Tasks  --
   ---------------------

   procedure Restore_Tasks;

   procedure Restore_Tasks is
      CPU_Id       : constant CPU := Current_CPU;
      CPU_Target   : CPU          := CPU'Last;
      Prev_Pointer : Thread_Id    := Null_Thread_Id;
      Aux_Pointer  : Thread_Id;
      Curr_Pointer : Thread_Id;
   begin

      if CPU_Id = CPU_Target then
         CPU_Target := CPU'First;
      end if;

      Lock (Ready_Tables_Locks (CPU'First).all);
      Lock (Ready_Tables_Locks (CPU'Last).all);

      CPU_Log_Table (CPU_Target).End_Hosting_Mig := Clock;

      CPU_Log_Table (CPU_Target).Total_Time_Hosting_Migs :=
                  CPU_Log_Table (CPU_Target).Total_Time_Hosting_Migs +
                     (CPU_Log_Table (CPU_Target).End_Hosting_Mig -
                          CPU_Log_Table (CPU_Target).Start_Hosting_Mig);

--        if CPU_Log_Table (CPU_Target).Is_Idle then
--           CPU_Log_Table (CPU_Id).Idle_Time_Hosting_Migs :=
--                  CPU_Log_Table (CPU_Id).Idle_Time_Hosting_Migs +
--             (Clock - CPU_Log_Table (CPU_Id).Last_Time_Idle_Hosting_Migs);
--        end if;

      CPU_Log_Table (CPU_Target).Last_Time_Idle_Hosting_Migs := 0;
      CPU_Log_Table (CPU_Target).Hosting_Mig_Tasks := False;

      Aux_Pointer  := First_Thread_Table (CPU_Target);
      Curr_Pointer := First_Thread_Table (CPU_Target);
      --  First extract from READY queue
      while Curr_Pointer /= Null_Thread_Id
      loop
            if Curr_Pointer.Is_Migrable
                  and
               Curr_Pointer.Base_CPU = CPU_Id
            then
               --  Log that this task's current job release is suffering
               --  migration overhead.
               Executions (Curr_Pointer.Data_Concerning_Migration.Id).
                              Migration_Happened_Current_Job_Release := True;

               if Curr_Pointer = First_Thread_Table (CPU_Target) then
                  --  The first thread is migrable, so it must be removed.
                  --  This means that the second thread in the queue,
                  --  i.e. Curr_Pointer.Next, must be set
                  --  as the first thread in the queue.
                  First_Thread_Table (CPU_Target) := Curr_Pointer.Next;
               else
                  --  We have to remove a thread between two others
                  --  (the last one could be the Null thread).
                  --  This means that the previous thread in the queue
                  --  must be linked to the last one.
                  Prev_Pointer.Next := Curr_Pointer.Next;
               end if;

               --  Go ahead with the aux pointer.
               Aux_Pointer := Aux_Pointer.Next;

               --  Isolate the current thread.
               Curr_Pointer.Next := Null_Thread_Id;

               --  Restore it.
               Curr_Pointer.Log_Table.Times_Restored
                               := Curr_Pointer.Log_Table.Times_Restored + 1;

               Curr_Pointer.Active_CPU := Curr_Pointer.Base_CPU;

               Curr_Pointer.Active_Priority := Curr_Pointer.Base_Priority;

               --  Restore deadline value to the NON-reduced one.
               --  Curr_Pointer.Active_Absolute_Deadline := Curr_Pointer.
               --         Data_Concerning_Migration.Stored_Absolute_Deadline;

               Insert (Curr_Pointer);

               --  Go ahead with the current pointer.
               Curr_Pointer := Aux_Pointer;

            else --  Current thread is NOT migrable
               --  then go ahead normally
               Prev_Pointer := Curr_Pointer;
               Aux_Pointer := Aux_Pointer.Next;
               Curr_Pointer := Aux_Pointer;
            end if;
      end loop;

      Unlock (Ready_Tables_Locks (CPU'First).all);
      Unlock (Ready_Tables_Locks (CPU'Last).all);
   end Restore_Tasks;
   ----------------------------
   --  Back_To_LO_Crit_Mode  --
   ----------------------------

   procedure Back_To_LO_Crit_Mode is
      CPU_Id       : constant CPU := Current_CPU;
      CPU_Target   : CPU          := CPU'First;
      Curr_Pointer : Thread_Id    := HI_Crit_Table (CPU_Id);
   begin
      if CPU_Id = CPU'First then
         CPU_Target := CPU'Last;
      end if;
      --  Migrating tasks must be restored
      Restore_Tasks;

      --  For each HI-crit task, set its Active_Budget to the LO-crit one.
      Curr_Pointer := HI_Crit_Table (CPU_Id);
      while Curr_Pointer /= Null_Thread_Id
      loop
         Curr_Pointer.Active_Budget := Curr_Pointer.Low_Critical_Budget;
         Curr_Pointer := Curr_Pointer.Next_HI_Crit;
      end loop;

      --  For each tasks on CPU_Target, use its steady mode's priority.
      Curr_Pointer := First_Thread_Table (CPU_Target);
      while Curr_Pointer /= Null_Thread_Id
      loop
         Curr_Pointer.Active_Priority := Curr_Pointer.Base_Priority;

         Curr_Pointer := Curr_Pointer.Next;
      end loop;

   end Back_To_LO_Crit_Mode;

   -----------------------------
   --  Enter_In_HI_Crit_Mode  --
   -----------------------------

   procedure Enter_In_HI_Crit_Mode is
      CPU_Id       : constant CPU := Current_CPU;
      CPU_Target   : CPU          := CPU'First;
      Curr_Pointer : Thread_Id    := HI_Crit_Table (CPU_Id);
   begin
      if CPU_Id = CPU'First then
         CPU_Target := CPU'Last;
      end if;
      --  Ada.Text_IO.Put_Line (CPU'Image (CPU_Id)
      --         & " is ENTERING in HI-crit mode.");
      --  For each HI-crit task, set its Active_Budget to the HI-crit one.
      while Curr_Pointer /= Null_Thread_Id
      loop
         if Curr_Pointer.State = Runnable then
            Curr_Pointer.Active_Budget :=
               Curr_Pointer.Active_Budget +
                     (Curr_Pointer.High_Critical_Budget -
                        Curr_Pointer.Low_Critical_Budget);
         else
            Curr_Pointer.Active_Budget := Curr_Pointer.High_Critical_Budget;
         end if;

            --  Ada.Text_IO.Put_Line (Integer'Image(Curr_Pointer.Base_Priority)
            --   & " raised to " &
            --   Duration'Image (To_Duration (Curr_Pointer.Active_Budget)));

         Curr_Pointer := Curr_Pointer.Next_HI_Crit;
      end loop;

      --  For each task on CPU_Target, use its priority concerning the migratin
      --  tasks hosting.
      Curr_Pointer := First_Thread_Table (CPU_Target);
      while Curr_Pointer /= Null_Thread_Id
      loop
         if Curr_Pointer.Active_Priority /= System.Tasking.Idle_Priority
                and
            --  Avoid final tasks printing log data
            Curr_Pointer.Base_Priority < 238
         then
            Curr_Pointer.Active_Priority := Curr_Pointer.
              Data_Concerning_Migration.Hosting_Migrating_Tasks_Priority;

            --  Ada.Text_IO.Put_Line (Integer'Image(Curr_Pointer.Base_Priority)
            --                      & " on core " & CPU'Image (CPU_Target) &
            --                        " migrated priority to " &
         --                     Integer'Image (Curr_Pointer.Active_Priority));
         end if;

         Curr_Pointer := Curr_Pointer.Next;
      end loop;

      --  Perform migration.
      Migrate_Tasks (Migrate);
   end Enter_In_HI_Crit_Mode;

   -----------------------
   --  Print_Tasks_Log  --
   -----------------------

   procedure Print_Tasks_Log is
      Curr_Pointer : Thread_Id := Global_List;
      use Mixed_Criticality_System;
      Is_System_Schedulable : Boolean := True;
      Task_Id : Natural := 0;
   begin
      Ada.Text_IO.Put_Line ("<experimentisnotvalid>" &
               Boolean'Image (
                  Core_Execution_Modes.Experiment_Is_Not_Valid
                     or
                  CPU_Budget_Monitor.Experiment_Is_Not_Valid) &
            "</experimentisnotvalid>");

      Ada.Text_IO.Put_Line ("<safeboundaryexceeded>" &
         Boolean'Image (Core_Execution_Modes.Safe_Boundary_Has_Been_Exceeded)
            & "</safeboundaryexceeded>");

      Ada.Text_IO.Put_Line ("<guiltytask>"
         & Integer'Image (CPU_Budget_Monitor.Guilty_Task) & "</guiltytask>");

      Ada.Text_IO.Put_Line ("<tasks>");

      while Curr_Pointer /= Null_Thread_Id loop
         if Curr_Pointer.Base_Priority in
                              System.Priority'First .. System.Priority'Last - 2
         then
            Task_Id := Curr_Pointer.Data_Concerning_Migration.Id;
            Ada.Text_IO.Put_Line ("<task>");

            Ada.Text_IO.Put_Line ("<taskid>" &
                                       Natural'Image (Task_Id) & "</taskid>");

            Ada.Text_IO.Put ("<priority>" &
                  Integer'Image (Curr_Pointer.Base_Priority) & "</priority>");

            Ada.Text_IO.Put_Line ("<basecpu>" &
                           CPU'Image (Curr_Pointer.Base_CPU) & "</basecpu>");

            Ada.Text_IO.Put_Line ("<period>" &
                  Duration'Image (To_Duration (Curr_Pointer.Period))
                  & "</period>");

            Ada.Text_IO.Put_Line ("<locritbudget>" &
               Duration'Image (To_Duration (Curr_Pointer.Low_Critical_Budget))
               & "</locritbudget>");

            Ada.Text_IO.Put_Line ("<hicritbudget>" &
               Duration'Image (To_Duration (Curr_Pointer.High_Critical_Budget))
               & "</hicritbudget>");

            if Curr_Pointer.Criticality_Level = LOW then
               Ada.Text_IO.Put_Line ("<criticality>LOW</criticality>");
            else
               Ada.Text_IO.Put_Line ("<criticality>HIGH</criticality>");
            end if;

            if Curr_Pointer.Is_Migrable then
               Ada.Text_IO.Put_Line ("<migrable>True</migrable>");
            else
               Ada.Text_IO.Put_Line ("<migrable>False</migrable>");
            end if;

            Ada.Text_IO.Put_Line ("<completedruns>" &
               Integer'Image (Log_Table (Task_Id).Runs) & "</completedruns>");

            Ada.Text_IO.Put_Line ("<preemptions>" & Integer'Image (
                           Log_Table (Task_Id).Preemption) & "</preemptions>");

            Ada.Text_IO.Put_Line ("<minresponsejitter>" &
            Duration'Image (To_Duration (Log_Table
            (Task_Id).Min_Response_Jitter)) & "</minresponsejitter>");

            Ada.Text_IO.Put_Line ("<maxresponsejitter>" &
            Duration'Image (To_Duration (Log_Table
            (Task_Id).Max_Response_Jitter)) & "</maxresponsejitter>");

            Ada.Text_IO.Put_Line ("<minreleasejitter>" &
            Duration'Image (To_Duration (
            Log_Table (Task_Id).Min_Release_Jitter)) & "</minreleasejitter>");

            Ada.Text_IO.Put_Line ("<maxreleasejitter>" &
            Duration'Image (To_Duration (
            Log_Table (Task_Id).Max_Release_Jitter)) & "</maxreleasejitter>");

            Ada.Text_IO.Put_Line ("<avgresponsejitter>" &
            Duration'Image (To_Duration (
            Log_Table (Task_Id).Average_Response_Jitter))
                                                 & "</avgresponsejitter>");

            Ada.Text_IO.Put_Line ("<deadlinesmissed>" &
               Natural'Image (Executions (Task_Id).
                                    Deadlines_Missed) & "</deadlinesmissed>");

            Ada.Text_IO.Put_Line ("<deadlinemissedtargetcore>" &
            Natural'Image (Executions (Task_Id).
            Deadlines_Missed_On_Target_Core) & "</deadlinemissedtargetcore>");

            Ada.Text_IO.Put_Line ("<deadlinemissedaftermigration>" &
            Natural'Image (Executions (Task_Id).
            Deadlines_Missed_After_Migration) &
            "</deadlinemissedaftermigration>");

            if Executions (Task_Id).Deadlines_Missed > 0
            then
               Is_System_Schedulable := False;
            end if;

            Ada.Text_IO.Put_Line ("<budgetexceeded>" &
               Natural'Image (Curr_Pointer.Log_Table.Times_BE)
                                             & "</budgetexceeded>");

            Ada.Text_IO.Put_Line ("<budgetexceededtargetcore>" &
                        Natural'Image (Executions (Task_Id).
                        BE_On_Target_Core) & "</budgetexceededtargetcore>");

            Ada.Text_IO.Put_Line ("<budgetexceededaftermigration>" &
                     Natural'Image (Executions (Task_Id).
                     BE_After_Migration) & "</budgetexceededaftermigration>");

            Ada.Text_IO.Put_Line ("<timesdiscarded>" &
                     Natural'Image (Curr_Pointer.Log_Table.Times_Discarded)
                                                      & "</timesdiscarded>");

            Ada.Text_IO.Put_Line ("<timesmigrated>" &
                     Natural'Image (Curr_Pointer.Log_Table.Times_Migrated)
                                                      & "</timesmigrated>");

            Ada.Text_IO.Put_Line ("<timesrestored>" &
                      Natural'Image (Curr_Pointer.Log_Table.Times_Restored)
                                                         & "</timesrestored>");

            Ada.Text_IO.Put_Line ("<timesonc1>" &
               Natural'Image (Executions (Task_Id).
                                                         Times_On_First_CPU)
                                                            & "</timesonc1>");

            Ada.Text_IO.Put_Line ("<timesonc2>" &
               Natural'Image (Executions (Task_Id).
                                                         Times_On_Second_CPU)
                                                            & "</timesonc2>");

            Ada.Text_IO.Put_Line ("<lockedtime>" &
                              Duration'Image (To_Duration
                                       (Curr_Pointer.Log_Table.Locked_Time))
                                                         & "</lockedtime>");

            Ada.Text_IO.Put_Line ("</task>");
         end if;

         Curr_Pointer := Curr_Pointer.Global_List;
      end loop;

      Ada.Text_IO.Put_Line ("</tasks>");

      Ada.Text_IO.Put_Line ("<tasksetisschedulable>" &
         Boolean'Image (Is_System_Schedulable) & "</tasksetisschedulable>");
   end Print_Tasks_Log;

end System.BB.Threads.Queues;
