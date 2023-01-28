package body Guard_Experiment is

   protected body Referee is
      entry Is_Experiment_Over
         when Safe_Boundary_Has_Been_Exceeded
               or
              Experiment_Is_Not_Valid
               or
              Time_Expired is
      begin
         null;
      end Is_Experiment_Over;

      procedure Set_Parameters (Safe_Boundary_Exceeded : Boolean;
                                Experiment_Not_Valid : Boolean;
                                Finish_Experiment : Boolean) is
      begin
         Safe_Boundary_Has_Been_Exceeded := Safe_Boundary_Exceeded;
         Experiment_Is_Not_Valid := Experiment_Not_Valid;
         Time_Expired := Finish_Experiment;
      end Set_Parameters;

   end Referee;

end Guard_Experiment;