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
   
   --  Here a channel for communication from a high criticality task to 
   --  a low criticality task is defined. 
   package CPSP is new Channel_Pool_Access.Shared_Pointer
     (Experiment_Parameters.Shared_Object);
   
   package High_to_Low_Channel is
      procedure Send    (Reference : in out CPSP.Reference_Type);
      procedure Receive (Reference : in out CPSP.Reference_Type);
   end High_to_Low_Channel;

end Channel_High_to_Low;
