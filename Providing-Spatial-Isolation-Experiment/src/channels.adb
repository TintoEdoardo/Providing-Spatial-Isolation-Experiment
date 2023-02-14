------------------------------------------------------------------------------
--                                                                          --
--                                 CHANNELS                                 --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

package body Channels is

   package body High_to_Low_Channel is
      Shared_Message : CPSP.Shared_Reference;
      
      procedure Send (Reference : in out CPSP.Reference_Type) is
      begin
         Shared_Message.Send (Reference => Reference);
      end Send;
      
      procedure Receive (Reference : in out CPSP.Reference_Type) is
      begin
         Shared_Message.Receive (Reference => Reference);
      end Receive;
   end High_to_Low_Channel;

   package body Low_to_High_Channel is
      Shared_Message : CPSP.Shared_Reference;
      
      procedure Send (Reference : in out CPSP.Reference_Type) is
      begin
         Shared_Message.Send (Reference => Reference);
      end Send;
      
      procedure Receive (Reference : in out CPSP.Reference_Type) is
      begin
         Shared_Message.Receive (Reference => Reference);
      end Receive;
   end Low_to_High_Channel;

end Channels;
