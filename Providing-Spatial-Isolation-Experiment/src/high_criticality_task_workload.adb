------------------------------------------------------------------------------
--                                                                          --
--                       HIGH CRITICALITY TASK WORKLOAD                     --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Channels;
with Shared_Protected_Object;
with Workload_Utilities; use Workload_Utilities;
with Experiment_Parameters; use Experiment_Parameters;
with Ada.Real_Time; use Ada.Real_Time;

package body High_Criticality_Task_Workload is

   procedure Workload_1_1 is
      Message_Reference   : Channels.CPSP.Reference_Type;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
   begin

      --  The task allocates a new message object
      pragma Assert (Message_Reference.Is_Null = True);
      Timing_Event_1 := Ada.Real_Time.Clock;
      Message_Reference.Allocate;
      Timing_Event_2 := Ada.Real_Time.Clock;

      Print_Alloc (Timing_Event_1, Timing_Event_2);
      
      --  Operation on the acquired object
      Message_Reference.Element.Payload (1) := 0;
      pragma Assert (Message_Reference.Element.Payload (1) = 0);
      
      --  Send the message object over the channel
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channels.High_to_Low_Channel.Send (Message_Reference);
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = True);

      Print_Send (Timing_Event_1, Timing_Event_2);

   end Workload_1_1;
   
   procedure Workload_1_3 is
      Message_Reference   : Channels.CPSP.Reference_Type;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
   begin
      
      --  Acquire the message message
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channels.Low_to_High_Channel.Receive
        (Message_Reference);
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = False);

      Print_Receive (Timing_Event_1, Timing_Event_2);

      --  Delete the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Message_Reference.Free;
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = True);
      
      Print_Free (Timing_Event_1, Timing_Event_2);
      
      --  Allocate a new message object
      pragma Assert (Message_Reference.Is_Null = True);
      Timing_Event_1 := Ada.Real_Time.Clock;
      Message_Reference.Allocate;
      Timing_Event_2 := Ada.Real_Time.Clock;

      Print_Alloc (Timing_Event_1, Timing_Event_2);
      
      --  Send the message object over the channel
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channels.High_to_Low_Channel.Send (Message_Reference);
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = True);
      
      --  Compute and print the send time span
      Print_Send (Timing_Event_1, Timing_Event_2);

   end Workload_1_3;
   
   procedure Workload_2_1 is
   begin
      --  The behaviour is identical
      Workload_1_1;
   end Workload_2_1;
   
   procedure Workload_2_3 is
      Message_Reference   : Channels.CPSP.Reference_Type;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
   begin

      --  Acquire the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channels.Low_to_High_Channel.Receive
        (Message_Reference);
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = False);

      Print_Receive (Timing_Event_1, Timing_Event_2);

      --  Alter the message object
      Message_Reference.Element.Payload (1) := 10;
      pragma Assert (Message_Reference.Element.Payload (1) = 10);
      
      --  Send the message object over the channel
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channels.High_to_Low_Channel.Send (Message_Reference);
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = True);
      
      --  Compute and print the send time span
      Print_Send (Timing_Event_1, Timing_Event_2);

   end Workload_2_3;
   
   procedure Workload_3_1 is
      Message             : Experiment_Parameters.Shared_Object;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
   begin
      
      --  Initialize the message
      Timing_Event_1 := Ada.Real_Time.Clock;
      Message.Payload (1) := Integer_32_b (1);
      Timing_Event_2 := Ada.Real_Time.Clock;
      
      Print_Initialize (Timing_Event_1, Timing_Event_2);
      
      --  Send the message through the protected object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Shared_Protected_Object.Send (Message);
      Timing_Event_2 := Ada.Real_Time.Clock;

      Print_Send (Timing_Event_1, Timing_Event_2);
      
      Print_NewLine;
      
   end Workload_3_1;

   procedure Workload_3_3 is
      Message             : Experiment_Parameters.Shared_Object;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
   begin
  
      --  Ada.Text_IO.Put_Line ("1");

      --  Acquire the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Shared_Protected_Object.Receive (Message);
      Timing_Event_2 := Ada.Real_Time.Clock;
      
      Print_Receive (Timing_Event_1, Timing_Event_2);
      
      --  Alter the message
      Timing_Event_1 := Ada.Real_Time.Clock;
      Message.Payload (1) := Integer_32_b (3);
      Timing_Event_2 := Ada.Real_Time.Clock;
      
      Print_Initialize (Timing_Event_1, Timing_Event_2);
      
      --  Send the message object over the PO
      Timing_Event_1 := Ada.Real_Time.Clock;
      Shared_Protected_Object.Send (Message);
      Timing_Event_2 := Ada.Real_Time.Clock;
      
      --  Compute and print the send time span
      Print_Send (Timing_Event_1, Timing_Event_2);
      
   end Workload_3_3;
   
end High_Criticality_Task_Workload;
