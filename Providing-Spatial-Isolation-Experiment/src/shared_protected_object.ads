------------------------------------------------------------------------------
--                                                                          --
--                          SHARED PROTECTED OBJECT                         --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

with Experiment_Parameters;

package Shared_Protected_Object is

   protected type Protected_Object is
      procedure Send    (Message : in Experiment_Parameters.Shared_Object);
      entry Receive (Message : out Experiment_Parameters.Shared_Object);
   private
      Message_Available : Boolean := True;
      Internal_Message  : Experiment_Parameters.Shared_Object;
   end Protected_Object;
   
   Cross_Criticality_PO : Protected_Object;
   
   procedure Send    (Message : in Experiment_Parameters.Shared_Object);
   procedure Receive (Message : out Experiment_Parameters.Shared_Object);

end Shared_Protected_Object;
