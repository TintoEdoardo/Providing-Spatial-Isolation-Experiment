------------------------------------------------------------------------------
--                                                                          --
--                           HIGH CRITICALITY TASK                          --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Synchronous_Task_Control;
with Activation_Manager;
with Experiment_Parameters;
with Channel_High_to_Low; use Channel_High_to_Low;
pragma Warnings (Off);
with System.BB.Time;
with System.Task_Primitives.Operations;
pragma Warnings (On);

--  The following dependencies are used for measuring the 
--  experimental metrics
with Ada.Text_IO;

package body High_Criticality_Task is

   task body High_Criticality_Task is
      Next_Activation     : Ada.Real_Time.Time;
      Task_Period         : constant Ada.Real_Time.Time_Span 
        := Ada.Real_Time.Microseconds (Period);
      Message_Reference   : Channel_High_to_Low.CPSP.Reference_Type;
      Iteration_Counter   : Positive;
      Iteration_Limit     : Positive;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
      Time_Span_of_Action : Ada.Real_Time.Time_Span;
   begin
      System.Task_Primitives.Operations.Initialize_HI_Crit_Task
        (System.Task_Primitives.Operations.Self,
         Id, 
         Hosting_Migrating_Tasks_Priority,
         System.BB.Time.Milliseconds (Low_Critical_Budget),
         System.BB.Time.Milliseconds (High_Critical_Budget),
         Period);
      
      Activation_Manager.Synchronize_Activation_Cyclic (Next_Activation);
      Iteration_Counter := 1;
      Iteration_Limit   := Experiment_Parameters.Iteration_Limit;
      loop
         --  Synchronization code
         Ada.Synchronous_Task_Control.Suspend_Until_True
           (Activation_Manager.Could_Send);
         Next_Activation := Next_Activation + Task_Period;
         
         --  Task workload
         if (Iteration_Counter <= Iteration_Limit) then
            --  The task allocates a new message object
            pragma Assert (Message_Reference.Is_Null = True);
            Timing_Event_1 := Ada.Real_Time.Clock;
            Message_Reference.Allocate;
            Timing_Event_2 := Ada.Real_Time.Clock;
            
            --  Compute and print the allocation time span
            Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
            Ada.Text_IO.Put
              ("<alloc>" &
                 Duration'Image 
                 (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
                 "</alloc>");
            
            --  Operation on the acquired object
            Message_Reference.Element.Payload (1) := 0;
            pragma Assert (Message_Reference.Element.Payload (1) = 0);
            
            --  The task send the message object over the channel
            Timing_Event_1 := Ada.Real_Time.Clock;
            Channel_High_to_Low.High_to_Low_Channel.Send (Message_Reference);
            Timing_Event_2 := Ada.Real_Time.Clock;
            pragma Assert (Message_Reference.Is_Null = True);
            
            --  Compute and print the send time span
            Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
            Ada.Text_IO.Put 
              ("<send>" &
                 Duration'Image 
                 (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
                 "</send>");
            
            Iteration_Counter := Iteration_Counter + 1;
         end if;
         
         delay until Next_Activation;
      end loop;
   end High_Criticality_Task;

end High_Criticality_Task;
