------------------------------------------------------------------------------
--                                                                          --
--                             WORKLOAD UTILITIES                           --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------
with Ada.Text_IO;

package body Workload_Utilities is
   
   procedure Print_NewLine is
   begin
      Ada.Text_IO.New_Line;
   end Print_NewLine;

   procedure Print_Alloc
     (Timing_Event_1 : Ada.Real_Time.Time; 
      Timing_Event_2 : Ada.Real_Time.Time)
   is
      Time_Span_of_Action : Ada.Real_Time.Time_Span;
   begin
      Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
      Ada.Text_IO.Put
        ("<alloc>" &
           Duration'Image 
           (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
           "</alloc>");
   end Print_Alloc;
   
   procedure Print_Free
     (Timing_Event_1 : Ada.Real_Time.Time; 
      Timing_Event_2 : Ada.Real_Time.Time)
   is
      Time_Span_of_Action : Ada.Real_Time.Time_Span;
   begin
      Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
      Ada.Text_IO.Put
        ("<free>" &
           Duration'Image 
           (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
           "</free>");
   end Print_Free;
   
   procedure Print_Send
     (Timing_Event_1 : Ada.Real_Time.Time; 
      Timing_Event_2 : Ada.Real_Time.Time)
   is
      Time_Span_of_Action : Ada.Real_Time.Time_Span;
   begin
      Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
      Ada.Text_IO.Put
        ("<send>" &
           Duration'Image 
           (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
           "</send>");
   end Print_Send;
   
   procedure Print_Receive
     (Timing_Event_1 : Ada.Real_Time.Time; 
      Timing_Event_2 : Ada.Real_Time.Time)
   is
      Time_Span_of_Action : Ada.Real_Time.Time_Span;
   begin
      Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
      Ada.Text_IO.Put
        ("<receive>" &
           Duration'Image 
           (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
           "</receive>");
   end Print_Receive;

   procedure Print_Initialize
     (Timing_Event_1 : Ada.Real_Time.Time; 
      Timing_Event_2 : Ada.Real_Time.Time)
   is
      Time_Span_of_Action : Ada.Real_Time.Time_Span;
   begin
      Time_Span_of_Action := Timing_Event_2 - Timing_Event_1;
      Ada.Text_IO.Put
        ("<init>" &
           Duration'Image 
           (Ada.Real_Time.To_Duration (Time_Span_of_Action)) &
           "</init>");
   end Print_Initialize;

end Workload_Utilities;
