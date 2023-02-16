------------------------------------------------------------------------------
--                                                                          --
--                           EXPERIMENT PARAMETERS                          --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

package Experiment_Parameters is

   --  Payload_Size    : Positive := 5068;
   Payload_Size    : Positive := 5070;
   --  Iteration_Limit : Positive := 1000;

   Workload_Type   : Positive := 3;

   --  Period is expressed in microseconds
   Task_Period         : Positive := 100000;
   Taskset_Cardinality : Positive := 10;

   --  The two tasks, at different criticality levels, exchange
   --  an object in form of a message through a channel, or a
   --  cross-criticality protected object.
   --  Each object has a payload, used for altering its size.
   --  The payload is an array of 32 bit Integer of length Payload_Size.
   type Integer_32_b is new Integer; for Integer_32_b'Size use 32;
   type Array_of_I32b is array (1..Payload_Size) of Integer_32_b;

   --  The type of the objects exchanged between task at different criticality
   --  levels, in this experiment, is Message.
   type Shared_Object is tagged record
     Payload : Array_of_I32b;
   end record;

end Experiment_Parameters;
