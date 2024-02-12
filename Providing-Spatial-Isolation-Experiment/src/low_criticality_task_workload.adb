------------------------------------------------------------------------------
--                                                                          --
--                       LOW CRITICALITY TASK WORKLOAD                      --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Channels;
with Shared_Protected_Object;
with Workload_Utilities; use Workload_Utilities;
with Experiment_Parameters; use Experiment_Parameters;
with Ada.Real_Time; use Ada.Real_Time;

package body Low_Criticality_Task_Workload is

   procedure Workload_1_2 is
      Message_Reference   : Channels.CPSP.Reference_Type;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
   begin

      --  Acquire the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channels.High_to_Low_Channel.Receive
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

      --  The task allocates a new message object
      pragma Assert (Message_Reference.Is_Null = True);
      Timing_Event_1 := Ada.Real_Time.Clock;
      Message_Reference.Allocate;
      Timing_Event_2 := Ada.Real_Time.Clock;

      Print_Alloc (Timing_Event_1, Timing_Event_2);
      
      --  Send the message object over the channel
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channels.Low_to_High_Channel.Send (Message_Reference);
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = True);
      
      Print_Send (Timing_Event_1, Timing_Event_2);
      
   end Workload_1_2;
   
   procedure Workload_1_4 is
      Message_Reference   : Channels.CPSP.Reference_Type;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
   begin

      --  Acquire the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channels.High_to_Low_Channel.Receive
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
      
      Print_NewLine;
      
   end Workload_1_4;
   
   procedure Workload_2_2 is
      Message_Reference   : Channels.CPSP.Reference_Type;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
   begin
      
      --  Acquire the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channels.High_to_Low_Channel.Receive
        (Message_Reference);
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = False);
      
      Print_Receive (Timing_Event_1, Timing_Event_2);
      
      --  Alter the message object
      Channels.CPSP.Get (Message_Reference).Payload (1) := 10;
      pragma Assert (Channels.CPSP.Get (Message_Reference).Payload (1) = 10);
      
      --  Send the message object over the channel
      Timing_Event_1 := Ada.Real_Time.Clock;
      Channels.Low_to_High_Channel.Send (Message_Reference);
      Timing_Event_2 := Ada.Real_Time.Clock;
      pragma Assert (Message_Reference.Is_Null = True);
      
      Print_Send (Timing_Event_1, Timing_Event_2);
      
   end Workload_2_2;
  
   procedure Workload_2_4 is
   begin
      --  The behaviour is identical
      Workload_1_4;
   end Workload_2_4;
   
   procedure Workload_3_2 is
      Message             : Experiment_Parameters.Shared_Object;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
   begin
      
      --  Acquire the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      Shared_Protected_Object.Receive (Message);
      Timing_Event_2 := Ada.Real_Time.Clock;

      Print_Receive (Timing_Event_1, Timing_Event_2);
      
      --  Alter the message
      Timing_Event_1 := Ada.Real_Time.Clock;
      Message.Payload (1) := Integer_32_b (2);
      Timing_Event_2 := Ada.Real_Time.Clock;
      Print_Initialize (Timing_Event_1, Timing_Event_2);
      
      --  Send the message object over the PO
      Timing_Event_1 := Ada.Real_Time.Clock;
      Shared_Protected_Object.Send (Message);
      Timing_Event_2 := Ada.Real_Time.Clock;
      
      --  Compute and print the send time span
      Print_Send (Timing_Event_1, Timing_Event_2);

      Print_NewLine;
      
   end Workload_3_2;

   procedure Workload_3_4 is
      Message             : Experiment_Parameters.Shared_Object;
      Timing_Event_1      : Ada.Real_Time.Time;
      Timing_Event_2      : Ada.Real_Time.Time;
   begin

      --  Acquire the message object
      Timing_Event_1 := Ada.Real_Time.Clock;
      pragma Warnings (Off, """Message"" modified by call, but value might not be referenced");
      Shared_Protected_Object.Receive (Message);
      pragma Warnings (On, """Message"" modified by call, but value might not be referenced");
      Timing_Event_2 := Ada.Real_Time.Clock;

      Print_Receive (Timing_Event_1, Timing_Event_2);
      
      Print_NewLine;

   end Workload_3_4;
   
end Low_Criticality_Task_Workload;
