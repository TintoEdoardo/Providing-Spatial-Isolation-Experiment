------------------------------------------------------------------------------
--                                                                          --
--                       HIGH CRITICALITY TASK WORKLOAD                     --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Channel_High_to_Low;
with Shared_Protected_Object;
with Experiment_Parameters; use Experiment_Parameters;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;

package body High_Criticality_Task_Workload is

   procedure Workload_1 is
      Message_Reference   : Channel_High_to_Low.CPSP.Reference_Type;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
      Time_Span_of_Action : Ada.Real_Time.Time_Span;
   begin
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
   end Workload_1;
   
   procedure Workload_2 is
      Message             : Experiment_Parameters.Shared_Object;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
      Time_Span_of_Action : Ada.Real_Time.Time_Span;
   begin
      --  The task initializes the message
      Timing_Event_1 := Ada.Real_Time.Clock;
      Message.Payload (1) := Integer_32_b (1);
      Timing_Event_2 := Ada.Real_Time.Clock;
      
      --  Compute and print the initialization time span
      Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
      Ada.Text_IO.Put
        ("<init>" &
           Duration'Image 
           (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
           "</init>");
      
      --  Send the message through the protected object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Shared_Protected_Object.Send (Message);
      Timing_Event_2 := Ada.Real_Time.Clock;
      
      --  Compute and print the send time span
      Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
      Ada.Text_IO.Put 
        ("<send>" &
           Duration'Image 
           (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
           "</send>");
      
   end Workload_2;
end High_Criticality_Task_Workload;
