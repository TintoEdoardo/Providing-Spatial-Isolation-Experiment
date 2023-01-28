------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                        C H A N N E L _ L O G G E R                       --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
------------------------------------------------------------------------------
with System.IO;

package body Channel_Logger is

   procedure Print_Array_of (Array_Name : String)
   is
      Array_to_Print  : Array_Times;
   begin

      System.IO.Put_Line (Array_Name);

      if Array_Name = Array_Allocation_Times_Name then
         Array_to_Print := Array_Allocation_Times;
      elsif Array_Name = Array_Deallocation_Times_Name then
         Array_to_Print := Array_Deallocation_Times;
      elsif Array_Name = Array_Send_Ownership_Times_Name then
         Array_to_Print := Array_Send_Ownership_Times;
      elsif Array_Name = Array_Receive_Ownership_Times_Name then
         Array_to_Print := Array_Receive_Ownership_Times;
      end if;

      --  Print the matrix of results.
      System.IO.Put_Line ("[");
      for i in Positive range 1 .. 100 loop
         for j in Integer range 0 .. 10 loop
            System.IO.Put
              (Duration'Image
                 (System.BB.Time.To_Duration (Array_to_Print (i, j)))
               & " ");
         end loop;
         System.IO.Put (",");
         System.IO.New_Line;
      end loop;

   end Print_Array_of;

   procedure Print_Array_Allocation_Times
   is
   begin
      Print_Array_of (Array_Allocation_Times_Name);
   end Print_Array_Allocation_Times;

   procedure Print_Array_Deallocation_Times
   is
   begin
      Print_Array_of (Array_Deallocation_Times_Name);
   end Print_Array_Deallocation_Times;

   procedure Print_Array_Send_Ownership_Times
   is
   begin
      Print_Array_of (Array_Send_Ownership_Times_Name);
   end Print_Array_Send_Ownership_Times;

   procedure Print_Array_Receive_Ownership_Times
   is
   begin
      Print_Array_of (Array_Receive_Ownership_Times_Name);
   end Print_Array_Receive_Ownership_Times;

end Channel_Logger;
