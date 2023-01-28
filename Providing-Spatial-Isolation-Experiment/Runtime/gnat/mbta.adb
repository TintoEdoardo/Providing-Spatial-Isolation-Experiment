pragma Warnings (Off);
with Ada.Text_IO;
pragma Warnings (On);

package body MBTA is

   type Indexes_Array is array (RTE_Primitive) of Natural;

   Overall_Indexes : array (CPU) of Indexes_Array := (others => (others => 0));

   Max_Observations : constant Positive := 50;
   type MBTA_Log_Array is
      array (RTE_Primitive, 0 .. Max_Observations - 1) of Duration;
   MBTA_Log : array (CPU) of MBTA_Log_Array;

   procedure Log_RTE_Primitive_Duration
      (Primitive : RTE_Primitive; Primitive_Duration : Duration; CPU_Id : CPU)
   is
      Index : constant Natural := Overall_Indexes (CPU_Id)(Primitive);
   begin
      --  Ada.Text_IO.Put_Line ("Logged " & RTE_Primitive'Image (Primitive)
      --     & " On CPU " & CPU'Image (CPU_Id));
      if Index < Max_Observations then
         MBTA_Log (CPU_Id)(Primitive, Index) := Primitive_Duration;
         Overall_Indexes (CPU_Id)(Primitive) := Index + 1;
      end if;
   end Log_RTE_Primitive_Duration;

   procedure Print_Log_RTE_Primitive_Duration is
   begin
      Ada.Text_IO.Put_Line ("Print_Log_RTE_Primitive_Duration");

      for Primitive in RTE_Primitive loop
         Ada.Text_IO.Put_Line (RTE_Primitive'Image (Primitive) & Natural'Image
                      (Overall_Indexes (CPU'First)(Primitive)) & " measures.");
         for CPU_Id in CPU loop
            for I in 0 .. Overall_Indexes (CPU_Id)(Primitive) - 1 loop
               Ada.Text_IO.Put_Line
                 (Duration'Image (MBTA_Log (CPU_Id)(Primitive, I)));
            end loop;
         end loop;
      end loop;

   end Print_Log_RTE_Primitive_Duration;

end MBTA;
