------------------------------------------------------------------------------
--                                                                          --
--                       LOW CRITICALITY TASK WORKLOAD                      --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Channel_High_to_Low;
with Shared_Protected_Object;
with Experiment_Parameters; use Experiment_Parameters;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;

package body Low_Criticality_Task_Workload is

   procedure Workload_1 is
      Message_Reference   : Channel_High_to_Low.CPSP.Reference_Type;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
      Time_Span_of_Action : Ada.Real_Time.Time_Span;
   begin
      --  The task acquires the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channel_High_to_Low.High_to_Low_Channel.Receive
        (Message_Reference);
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = False);
      
      --  Compute and print the receive time span
      Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
      Ada.Text_IO.Put 
        ("<receive>" &
           Duration'Image 
           (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
           "</receive>");
      
      --  Operation on the acquired object
      pragma Assert (Message_Reference.Element.Payload (1) = 0);
      Message_Reference.Element.Payload (1) := 1;
      pragma Assert (Message_Reference.Element.Payload (1) = 1);
      
      --  The task deletes the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Message_Reference.Free;
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = True);
      
      --  Compute and print the free time span
      Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
      Ada.Text_IO.Put_Line 
        ("<free>" &
           Duration'Image 
           (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
           "</free>");
   end Workload_1;
   
   procedure Workload_2 is
      Message             : Experiment_Parameters.Shared_Object;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
      Time_Span_of_Action : Ada.Real_Time.Time_Span;
   begin
      --  The task acquires the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Shared_Protected_Object.Receive (Message);
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message.Payload (1) = Integer_32_b (1));
      
      --  Compute and print the receive time span
      Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
      Ada.Text_IO.Put_Line 
        ("<receive>" &
           Duration'Image 
           (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
           "</receive>");
   end Workload_2;
   
end Low_Criticality_Task_Workload;
