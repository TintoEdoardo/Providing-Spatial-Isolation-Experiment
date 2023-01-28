with Initial_Delay;
use Initial_Delay;

package body Experiment_Info is

   Experiment_Parameters : Exp_Params;

   procedure Set_Parameters (Params : Exp_Params) is
   begin
      Experiment_Parameters.Experiment_Hyperperiods :=
        (CPU'First => Params.Experiment_Hyperperiods (CPU'First),
         CPU'Last => Params.Experiment_Hyperperiods (CPU'Last));

      Experiment_Parameters.Absolutes_Hyperperiods :=
        (CPU'First => Microseconds (Params.Experiment_Hyperperiods (CPU'First))
                     + Microseconds (Delay_Time) + Time_First,

         CPU'Last => Microseconds (Params.Experiment_Hyperperiods (CPU'Last))
                        + Microseconds (Delay_Time) + Time_First);

      Experiment_Parameters.Id_Experiment := Params.Id_Experiment;
      Experiment_Parameters.Approach := Params.Approach;
      Experiment_Parameters.Taskset_Id := Params.Taskset_Id;
      Experiment_Parameters.Id_Execution := Params.Id_Execution;
   end Set_Parameters;

   function Get_Parameters return Exp_Params is
   begin
      return Experiment_Parameters;
   end Get_Parameters;

end Experiment_Info;
