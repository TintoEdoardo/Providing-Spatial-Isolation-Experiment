------------------------------------------------------------------------------
--                                                                          --
--                            CHANNEL HIGH TO LOW                           --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

with Channel_Pool_Access;
with Experiment_Parameters;

package Channel_High_to_Low is
   
   --  Each message has a payload, used for altering its size.
   --  The payload is an array of 32 bit Integer of length Payload_Size. 
   type Integer_32_b is new Integer; for Integer_32_b'Size use 32;
   Payload_Size : Positive := Experiment_Parameters.Payload_Size;
   type Array_of_I32b is array (1..Payload_Size) of Integer_32_b;

   --  The type of the objects exchanged between task at different criticality 
   --  levels, in this experiment, is Message.
   type Message is tagged record
     Payload : Array_of_I32b;
   end record;
   
   --  Here a channel for communication from a high criticality task to 
   --  a low criticality task is defined. 
   package CPSP is new Channel_Pool_Access.Shared_Pointer (Message);
   
   package High_to_Low_Channel is
      procedure Send    (Reference : in out CPSP.Reference_Type);
      procedure Receive (Reference : in out CPSP.Reference_Type);
   end High_to_Low_Channel;

end Channel_High_to_Low;
