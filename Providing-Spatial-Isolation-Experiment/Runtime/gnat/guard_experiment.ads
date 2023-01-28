with System;

package Guard_Experiment is
   pragma Elaborate_Body;

   protected Referee is
      pragma Priority (System.Max_Interrupt_Priority);
      entry Is_Experiment_Over;
      procedure Set_Parameters (Safe_Boundary_Exceeded : Boolean;
                                Experiment_Not_Valid : Boolean;
                                Finish_Experiment : Boolean);
   private
      Safe_Boundary_Has_Been_Exceeded : Boolean := False;
      Experiment_Is_Not_Valid : Boolean := False;
      Time_Expired : Boolean := False;
   end Referee;

end Guard_Experiment;