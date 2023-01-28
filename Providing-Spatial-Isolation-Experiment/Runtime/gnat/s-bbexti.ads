------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--              S Y S T E M . B B . E X E C U T I O N _ T I M E             --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                     Copyright (C) 2011-2018, AdaCore                     --
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
------------------------------------------------------------------------------

with System.BB.Threads;
with System.BB.Time;
with System.BB.Interrupts;

package System.BB.Execution_Time is
   function Global_Interrupt_Clock return System.BB.Time.Time;
   --  Sum of the interrupt clocks

   function Interrupt_Clock
     (Interrupt : System.BB.Interrupts.Interrupt_ID)
      return System.BB.Time.Time;
   pragma Inline (Interrupt_Clock);
   --  CPU Time spent to handle the given interrupt

   function Thread_Clock
     (Th : System.BB.Threads.Thread_Id) return System.BB.Time.Time;
   pragma Inline (Thread_Clock);
   --  CPU Time spent in the given thread

   function Elapsed_Time return System.BB.Time.Time;
   --  Function returning the time elapsed since the last scheduling event,
   --  i.e. the execution time of the currently executing entity (thread or
   --  interrupt) that has not yet been added to the global counters.

end System.BB.Execution_Time;
