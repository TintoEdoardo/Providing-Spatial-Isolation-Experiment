------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                         S Y S T E M . B B . T I M E                      --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
--                     Copyright (C) 2003-2018, AdaCore                     --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
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
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
-- The port of GNARL to bare board targets was initially developed by the   --
-- Real-Time Systems Group at the Technical University of Madrid.           --
--                                                                          --
------------------------------------------------------------------------------

pragma Restrictions (No_Elaboration_Code);

with System.BB.Interrupts;
with System.BB.Board_Support;
with System.BB.Protection;
with System.BB.Threads.Queues;
with System.BB.Timing_Events;
with Ada.Unchecked_Conversion;
with System.OS_Interface;

with CPU_Budget_Monitor;
with Core_Execution_Modes;

--  with MBTA;

pragma Warnings (Off);
with Ada.Text_IO;
pragma Warnings (On);

package body System.BB.Time is

   use System.Multiprocessors;
   use System.BB.Board_Support.Multiprocessors;

   package OSI renames System.OS_Interface;

   --  We use two timers with the same frequency:
   --     A Periodic Timer for the clock
   --     An Alarm Timer for delays

   -----------------------
   -- Local Subprograms --
   -----------------------

   procedure Alarm_Handler (Interrupt : Interrupts.Interrupt_ID);
   --  Handler for the alarm interrupt

   -------------------
   -- Alarm_Handler --
   -------------------

   procedure Alarm_Handler (Interrupt : Interrupts.Interrupt_ID) is
      pragma Unreferenced (Interrupt);
      Now        : constant Time := Clock;
      --  Start_Time : Time          := Now;
      CPU_Id     : constant CPU  := Current_CPU;
   begin
      Board_Support.Time.Clear_Alarm_Interrupt;

      --  A context switch may happen due to an awaken task. Charge the
      --  current task.

      if Scheduling_Event_Hook /= null then
         Scheduling_Event_Hook.all;
      end if;

      --  MBTA.Log_RTE_Primitive_Duration
      --    (MBTA.AH, To_Duration (Clock - Start_Time), CPU_Id);

      --  Note that the code is executed with interruptions disabled, so there
      --  is no need to call Enter_Kernel/Leave_Kernel.

      --  Execute expired events of the current CPU

      Timing_Events.Execute_Expired_Timing_Events (Now);

      --  Wake up our alarms
      --  Start_Time := Clock;

      Threads.Queues.Wakeup_Expired_Alarms (Now);

      --  Set the timer for the next alarm on this CPU

      Update_Alarm (Get_Next_Timeout (CPU_Id));

      --  MBTA.Log_RTE_Primitive_Duration
      --    (MBTA.WEA_UA, To_Duration (Clock - Start_Time), CPU_Id);

      --  The interrupt low-level handler will call context_switch if necessary

   end Alarm_Handler;

   -----------
   -- Clock --
   -----------

   function Clock return Time is (Board_Support.Time.Read_Clock);

   -----------
   -- Epoch --
   -----------

   function Epoch return Time is
   begin
      --  TBL and TBU cleared at start up

      return 0;
   end Epoch;

   -----------------
   -- Delay_Until --
   -----------------

   procedure Delay_Until (T : Time) is
      use Core_Execution_Modes;
      Now               : Time;
      Self              : Threads.Thread_Id;
      Inserted_As_First : Boolean;
      CPU_Id            : constant CPU := Current_CPU;
      Response_Jitter   : Time_Span;
      Temp1             : Time_Span;
      Temp2             : Time;
      Cancelled         : Boolean;
      --  Start_Time        : Time;
      pragma Unreferenced (Cancelled);
   begin
      --  First mask interrupts, this is necessary to handle thread queues

      Protection.Enter_Kernel;

      --  Stop budget monitoring.
      --  To be fair (aka: in a real system), budget monitoring
      --  should be stopped if:
      --    1. the alarm time is in the future.
      --    2. the Yield procedure re-inserts the running thread
      --       on top (head) of ready queue.

      --  CPU_Budget_Monitor.Clear_Monitor (Cancelled);

      --  Read the clock once the interrupts are masked to avoid being
      --  interrupted before the alarm is set.

      Now := Clock;
      --  Start_Time := Now;

      Self := Threads.Thread_Self;

      --  pragma Assert (Self.State = Runnable);
      if Self.First_Execution = True then

         Temp1 := Self.Active_Next_Period - Time_First;
         Temp2 := Self.Active_Release_Jitter + Temp1;
         Response_Jitter := Now - Temp2;
         if Self.Fake_Number_ID > -1 then
            System.BB.Threads.Queues.Update_Jitters (Self,
                  (Response_Jitter),
                  (Self.Active_Release_Jitter - Time_First));
         end if;
      else
         Self.First_Execution := True;
         Self.First_Time_On_Delay_Until := True;
      end if;

      --  add DM if necessary and add Regular_Completion
      System.BB.Threads.Queues.Add_Runs (Self.Fake_Number_ID);

      if Self.Active_Absolute_Deadline < Now
           and
         not Self.First_Time_On_Delay_Until
      then
         System.BB.Threads.Queues.Add_DM (Self.Data_Concerning_Migration.Id);
         --  Ada.Text_IO.Put_Line ("Del" & Integer'Image
         --                  (Self.Data_Concerning_Migration.Id));
      end if;

      --  Self.First_Time_On_Delay_Until := False;

      --  Test if the time is in the future

      if T + System.BB.Threads.Queues.Global_Interrupt_Delay > Now then
         --  Ada.Text_IO.Put_Line ("Delay_Until");
         Self.T_Clear := System.BB.Time.Clock;
         CPU_Budget_Monitor.Clear_Monitor (Cancelled);

         --  Restore its budget
         if Get_Core_Mode (CPU_Id) = LOW then
            Self.Active_Budget := Self.Low_Critical_Budget;
         else
            --  for LO-crit tasks, HI-crit budget is set to LO-crit budget.
            Self.Active_Budget := Self.High_Critical_Budget;
         end if;

         --  Ada.Text_IO.Put_Line (Integer'Image (Self.Base_Priority) &
         --   " restored budget to " & Duration'Image
         --         (System.BB.Time.To_Duration (Self.Active_Budget)));

         --  Extract the thread from the ready queue. When a thread wants to
         --  wait for an alarm it becomes blocked.

         Self.State := Threads.Delayed;

         Self.Preemption_Needed := False;
         Threads.Queues.Extract (Self);

         --  Insert Thread_Id in the alarm queue (ordered by time) and if it
         --  was inserted at head then check if Alarm Time is closer than the
         --  next clock interrupt.

         Threads.Queues.Insert_Alarm (T, Self, Inserted_As_First);

         --  This task's current job release is completed, so it is no longer
         --  suffering migration overhead (if it happened).
         System.BB.Threads.Queues.
                  Executions (Self.Data_Concerning_Migration.Id).
                              Migration_Happened_Current_Job_Release := False;

         if Inserted_As_First then
            Update_Alarm (Get_Next_Timeout (CPU_Id));
         end if;

      else
         --  If alarm time is not in the future, the thread must yield the CPU
         Threads.Queues.Change_Absolute_Deadline
            (Self, Self.Active_Absolute_Deadline + Self.Period);

         Threads.Queues.Yield (Self);
      end if;

      --  MBTA.Log_RTE_Primitive_Duration
      --    (MBTA.DU, To_Duration (Clock - Start_Time), CPU_Id);
      Protection.Leave_Kernel;
   end Delay_Until;

   ----------------------
   -- Get_Next_Timeout --
   ----------------------

   function Get_Next_Timeout (CPU_Id : CPU) return Time is
      Alarm_Time : constant Time :=
                     Threads.Queues.Get_Next_Alarm_Time (CPU_Id);
      Event_Time : constant Time := Timing_Events.Get_Next_Timeout (CPU_Id);

   begin
      return Time'Min (Alarm_Time, Event_Time);
   end Get_Next_Timeout;

   -----------------------
   -- Initialize_Timers --
   -----------------------

   procedure Initialize_Timers is
   begin
      --  Install alarm handler
      Board_Support.Time.Install_Alarm_Handler (Alarm_Handler'Access);
   end Initialize_Timers;

   ------------------
   -- Update_Alarm --
   ------------------

   procedure Update_Alarm (Alarm : Time) is
   begin
      Board_Support.Time.Set_Alarm (Alarm);
   end Update_Alarm;

   -----------------------
   -- Local definitions --
   -----------------------

   subtype LLI is Long_Long_Integer;
   type Uint_64 is mod 2 ** 64;
   --  subtype Uint_64 is System.BB.Time.Time;
   --  Type used to represent intermediate results of arithmetic
   --  operations
   Max_Pos_Time_Span : constant := Uint_64 (Time_Span_Last);
   Max_Neg_Time_Span : constant := Uint_64 (2 ** 63);

   function Mul_Div (V : LLI; M : Natural; D : Positive) return LLI;
   function Rounded_Div (L, R : LLI) return LLI;

   ---------
   -- "*" --
   ---------

   function "*" (Left : Time_Span; Right : Integer) return Time_Span is
      Is_Negative : constant Boolean :=
         (if Left > 0 then
            Right < 0
         elsif Left < 0
            then Right > 0
         else
            False);
      --  Sign of the result

      Max_Value : constant Uint_64 :=
         (if Is_Negative then
            Max_Neg_Time_Span
         else
            Max_Pos_Time_Span);
      --  Maximum absolute value that can be returned by the multiplication
      --  taking into account the sign of the operators.

      Abs_Left : constant Uint_64 :=
         (if Left = Time_Span_First then
            Max_Neg_Time_Span
         else
            Uint_64 (abs (Left)));
      --  Remove sign of left operator

      Abs_Right : constant Uint_64 := Uint_64 (abs (LLI (Right)));
      --  Remove sign of right operator

   begin
      --  Overflow check is performed by hand assuming that Time_Span is a
      --  64-bit signed integer. Otherwise these checks would need an
      --  intermediate type with more than 64-bit. The sign of the operators
      --  is removed to simplify the intermediate computation of the overflow
      --  check.

      if Abs_Right /= 0 and then Max_Value / Abs_Right < Abs_Left then
         raise Constraint_Error;
      else
         return Left * Time_Span (Right);
      end if;
   end "*";

   function "*" (Left : Integer; Right : Time_Span) return Time_Span is
   begin
      return Right * Left;
   end "*";

   ---------
   -- "+" --
   ---------

   function "+" (Left : Time; Right : Time_Span) return Time is
   begin
      --  Overflow checks are performed by hand assuming that Time and
      --  Time_Span are 64-bit unsigned and signed integers respectively.
      --  Otherwise these checks would need an intermediate type with more
      --  than 64 bits.

      if Right >= 0
         and then Uint_64 (Time_Last) - Uint_64 (Left) >= Uint_64 (Right)
      then
         return Time (Uint_64 (Left) + Uint_64 (Right));

      --  The case of Right = Time_Span'First needs to be treated differently
      --  because the absolute value of -2 ** 63 is not within the range of
      --  Time_Span.

      elsif Right = Time_Span'First and then Left >= Max_Neg_Time_Span then
         return Time (Uint_64 (Left) - Max_Neg_Time_Span);

      elsif Right < 0 and then Right > Time_Span'First
         and then Left >= Time (abs (Right))
      then
         return Time (Uint_64 (Left) - Uint_64 (abs (Right)));

      else
         raise Constraint_Error;
      end if;
   end "+";

   function "+" (Left : Time_Span; Right : Time) return Time is
   begin
      --  Overflow checks must be performed by hand assuming that Time and
      --  Time_Span are 64-bit unsigned and signed integers respectively.
      --  Otherwise these checks would need an intermediate type with more
      --  than 64-bit.

      if Left >= 0
         and then Uint_64 (Time_Last) - Uint_64 (Right) >= Uint_64 (Left)
      then
         return Time (Uint_64 (Left) + Uint_64 (Right));

      elsif Left = Time_Span'First and then Right >= Max_Neg_Time_Span then
         return Time (Uint_64 (Right) - Max_Neg_Time_Span);

      elsif Left < 0 and then Left > Time_Span'First
         and then Right >= Time (abs (Left))
      then
         return Time (Uint_64 (Right) - Uint_64 (abs (Left)));

      else
         raise Constraint_Error;
      end if;
   end "+";

   function "+" (Left, Right : Time_Span) return Time_Span is
      pragma Unsuppress (Overflow_Check);
   begin
      return Time_Span (LLI (Left) + LLI (Right));
   end "+";

   ---------
   -- "-" --
   ---------

   function "-" (Left : Time; Right : Time_Span) return Time is
   begin
      --  Overflow checks must be performed by hand assuming that Time and
      --  Time_Span are 64-bit unsigned and signed integers respectively.
      --  Otherwise these checks would need an intermediate type with more
      --  than 64-bit.

      if Right >= 0 and then Left >= Time (Right) then
         return Time (Uint_64 (Left) - Uint_64 (Right));

      --  The case of Right = Time_Span'First needs to be treated differently
      --  because the absolute value of -2 ** 63 is not within the range of
      --  Time_Span.

      elsif Right = Time_Span'First
         and then Uint_64 (Time_Last) - Uint_64 (Left) >= Max_Neg_Time_Span
      then
         return Left + Time (Max_Neg_Time_Span);

      elsif Right < 0 and then Right > Time_Span'First
         and then Uint_64 (Time_Last) - Uint_64 (Left) >= Uint_64 (abs (Right))
      then
         return Left + Time (abs (Right));

      else
         raise Constraint_Error;
      end if;
   end "-";

   function "-" (Left, Right : Time) return Time_Span is
   begin
      --  Overflow checks must be performed by hand assuming that Time and
      --  Time_Span are 64-bit unsigned and signed integers respectively.
      --  Otherwise these checks would need an intermediate type with more
      --  than 64-bit.

      if Left >= Right
         and then Uint_64 (Left) - Uint_64 (Right) <= Max_Pos_Time_Span
      then
         return Time_Span (Uint_64 (Left) - Uint_64 (Right));

      elsif Left < Right
         and then Uint_64 (Right) - Uint_64 (Left) <= Max_Neg_Time_Span
      then
         return -1 - Time_Span (Uint_64 (Right) - Uint_64 (Left) - 1);

      else
         raise Constraint_Error;
      end if;
   end "-";

   function "-" (Left, Right : Time_Span) return Time_Span is
      pragma Unsuppress (Overflow_Check);
   begin
      return Time_Span (LLI (Left) - LLI (Right));
   end "-";

   function "-" (Right : Time_Span) return Time_Span is
      pragma Unsuppress (Overflow_Check);
   begin
      return Time_Span (-LLI (Right));
   end "-";

   ---------
   -- "/" --
   ---------

   function "/" (Left, Right : Time_Span) return Integer is
      pragma Unsuppress (Overflow_Check);
      pragma Unsuppress (Division_Check);
   begin
      return Integer (LLI (Left) / LLI (Right));
   end "/";

   function "/" (Left : Time_Span; Right : Integer) return Time_Span is
      pragma Unsuppress (Overflow_Check);
      pragma Unsuppress (Division_Check);
   begin
      return Left / Time_Span (Right);
   end "/";

   ------------------
   -- Microseconds --
   ------------------

   function Microseconds (US : Integer) return Time_Span is
   begin
      --  Overflow can't happen (Ticks_Per_Second is Natural)

      return
         Time_Span (Rounded_Div (LLI (US) * LLI (OSI.Ticks_Per_Second), 1E6));
   end Microseconds;

   ------------------
   -- Milliseconds --
   ------------------

   function Milliseconds (MS : Integer) return Time_Span is
   begin
      --  Overflow can't happen (Ticks_Per_Second is Natural)

      return
         Time_Span (Rounded_Div (LLI (MS) * LLI (OSI.Ticks_Per_Second), 1E3));
   end Milliseconds;

   -------------
   -- Mul_Div --
   -------------

   function Mul_Div (V : LLI; M : Natural; D : Positive) return LLI is

      --  We first multiply V * M and then divide the result by D, while
      --  avoiding overflow in intermediate calculations and detecting it in
      --  the final result. To get the rounding to the nearest integer, away
      --  from zero if exactly halfway between two values, we add +/- D/2
      --  (depending on the sign on V) directly at the end of multiplication.
      --
      --  ----------------------------------------
      --  Multiplication (and rounding adjustment)
      --  ----------------------------------------
      --
      --  Since V is a signed 64-bit integer and M is signed (but non-negative)
      --  32-bit integer, their product may not fit in 64-bits. To avoid
      --  overflow we split V and into high and low parts
      --
      --    V_Hi = V  /  2 ** 32
      --    V_Lo = V rem 2 ** 32
      --
      --  where each part is either zero or has the sign of the dividend; thus
      --
      --    V = V_Hi * 2 ** 32 + V_Lo
      --
      --  In either case V_Hi and V_Lo are in range of 32-bit signed integer,
      --  yet stored in 64-bit signed variables. When multiplied by M, which is
      --  in range of 0 .. 2 ** 31 - 1, the results will still fit in 64-bit
      --  integer, even if we extend it by D/2 as required to implement
      --  rounding. We will get the value of V * M ± D/2 as low and high part:
      --
      --    (V * M ± D/2)_Lo = (V_Lo * M ± D/2) with carry zeroed
      --    (V * M ± D/2)_Hi = (V_Hi * M) with carry from (V_Lo * M ± D/2)
      --
      --  (carry flows only from low to high part), or mathematically speaking:
      --
      --    (V * M ± D/2)_Lo = (V * M ± D/2) rem 2 ** 32
      --    (V * M ± D/2)_Hi = (V * M ± D/2)  /  2 ** 32
      --
      --  and thus
      --
      --    V * M ± D/2 = (V * M ± D/2)_Hi * 2 ** 32 + (V * M ± D/2)_Lo
      --
      --  with signs just like described for V_Hi and V_Lo.
      --
      --  --------
      --  Division
      --  --------
      --
      --  The final result (V * M ± D/2) / D is computed as a high and low
      --  parts:
      --
      --    ((V * M ± D/2) / D)_Hi = (V * M ± D/2)_Hi / D
      --    ((V * M ± D/2) / D)_Lo =
      --        ((V * M ± D/2)_Lo + remainder from high part division) / D
      --
      --  (remainder flows only from high to low part, opposite to carry),
      --  or mathematically speaking:
      --
      --    ((V * M ± D/2) / D)_Hi = ((V * M ± D/2) / D)  /  2 ** 32
      --    ((V * M ± D/2) / D)_Lo = ((V * M ± D/2) / D) rem 2 ** 32
      --
      --  and thus
      --
      --    (V * M ± D/2) / D = ((V * M ± D/2) / D)_Hi * 2 ** 32
      --                      + ((V * M ± D/2) / D)_Lo
      --
      --  with signs just like described for V_Hi and V_Lo.
      --
      --  References: this calculation is partly inspired by Knuth's algorithm
      --  in TAoCP Vol.2, section 4.3.1, excercise 16. However, here it is
      --  adapted it for signed arithmetic; has no loop (since the input number
      --  has fixed width); and discard the remainder of the result.

      V_Hi : constant LLI := V  /  2 ** 32;
      V_Lo : constant LLI := V rem 2 ** 32;
      --  High and low parts of V

      V_M_Hi : LLI;
      V_M_Lo : LLI;
      --  High and low parts of V * M (+-) D / 2

      Result_Hi : LLI;
      --  High part of the result

      Result_Lo : LLI;
      --  Low part of the result

      Remainder : LLI;
      --  Remainder of the first division

   begin
      --  Multiply V * M and add/subtract D/2

      V_M_Lo := V_Lo * LLI (M) + (if V >= 0 then 1 else -1) * LLI (D / 2);
      V_M_Hi := V_Hi * LLI (M) + V_M_Lo / 2 ** 32;
      V_M_Lo := V_M_Lo rem 2 ** 32;

      --  First quotient

      Result_Hi := V_M_Hi / LLI (D);

      --  The final result would overflow

      if Result_Hi not in -(2 ** 31) .. 2 ** 31 - 1 then
         raise Constraint_Error;
      end if;

      Remainder := V_M_Hi rem LLI (D);
      Result_Hi := Result_Hi * 2 ** 32;

      --  Second quotient

      Result_Lo := (V_M_Lo + Remainder * 2 ** 32) / LLI (D);

      --  Combine low and high parts of the result

      return Result_Hi + Result_Lo;
   end Mul_Div;

   -----------------
   -- Nanoseconds --
   -----------------

   function Nanoseconds (NS : Integer) return Time_Span is
   begin
      --  Overflow can't happen (Ticks_Per_Second is Natural)

      return
         Time_Span (Rounded_Div (LLI (NS) * LLI (OSI.Ticks_Per_Second), 1E9));
   end Nanoseconds;

   -----------------
   -- Rounded_Div --
   -----------------

   function Rounded_Div (L, R : LLI) return LLI is
      Left : LLI;
   begin
      if L >= 0 then
         Left := L + R / 2;
      else
         Left := L - R / 2;
      end if;

      return Left / R;
   end Rounded_Div;

   -------------------------------------------------------------
   -------------------------------------------------------------
   --  DEBUG

   function To_Duration is
      new Ada.Unchecked_Conversion (Long_Long_Integer, Duration);

   function To_Integer is
      new Ada.Unchecked_Conversion (Duration, Long_Long_Integer);

   function To_Integer is
      new Ada.Unchecked_Conversion (Time_Span, LLI);

   Duration_Units : constant Positive := Positive (1.0 / Duration'Small);
   -----------------
   -- To_Duration --
   -----------------

   function To_Duration (TS : Time_Span) return Duration is
   begin
      return
         To_Duration
            (Mul_Div (To_Integer (TS), Duration_Units, OSI.Ticks_Per_Second));
   end To_Duration;

   function To_Time_Span (D : Duration) return Time_Span is
   begin
      return
         Time_Span
            (Mul_Div (To_Integer (D), OSI.Ticks_Per_Second, Duration_Units));
   end To_Time_Span;

   -------------------------------------------------------------
   -------------------------------------------------------------

end System.BB.Time;
