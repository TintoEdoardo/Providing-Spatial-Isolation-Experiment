------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                        C H A N N E L _ L O G G E R                       --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
------------------------------------------------------------------------------

with System.BB.Time;

package Channel_Logger is

   Array_Allocation_Times_Name         : String := "Allocation_Times";
   Array_Deallocation_Times_Name       : String := "Deallocation_Times";
   Array_Send_Ownership_Times_Name     : String := "Send_Ownership_Times";
   Array_Receive_Ownership_Times_Name  : String := "Receive_Ownership_Times";

   type Array_Times is array (1 .. 100, 0 .. 10)
     of System.BB.Time.Time_Span;

   type Row_Times is array (1 .. 2) of System.BB.Time.Time;

   type Two_Column_Array_Times is array (1 .. 100)
     of Row_Times;

   Array_Allocation_Times        : Array_Times;  --  Before and after Alloc
   Array_Deallocation_Times      : Array_Times;  --  Before and after Free
   Array_Send_Ownership_Times    : Array_Times;  --  Before and after Send
   Array_Receive_Ownership_Times : Array_Times;  --  Defore and after Receive

   procedure Print_Array_Allocation_Times;

   procedure Print_Array_Deallocation_Times;

   procedure Print_Array_Send_Ownership_Times;

   procedure Print_Array_Receive_Ownership_Times;

   --  procedure Print_Matrix_Send_Ownership_Times;

   --  procedure Print_Matrix_Receive_Ownership_Times;

private

   procedure Print_Array_of (Array_Name : String);

   --  procedure Print_Matrix_of (Matrix_Name : String);

end Channel_Logger;
