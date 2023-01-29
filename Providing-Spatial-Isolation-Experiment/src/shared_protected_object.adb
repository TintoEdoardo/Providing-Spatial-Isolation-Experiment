package body Shared_Protected_Object is

   protected body Protected_Object is
      procedure Send (Message  : in Experiment_Parameters.Shared_Object) is
      begin
         Internal_Message := Message;
      end Send;
      
      procedure Receive (Message : out Experiment_Parameters.Shared_Object) is
      begin
         Message := Internal_Message;
      end Receive;
   end Protected_Object;
   
   procedure Send (Message  : in Experiment_Parameters.Shared_Object) is
   begin
      Cross_Criticality_PO.Send (Message);
   end Send;
   
   procedure Receive (Message : out Experiment_Parameters.Shared_Object) is
   begin
      Cross_Criticality_PO.Receive (Message);
   end Receive;

end Shared_Protected_Object;
