------------------------------------------------------------------------------
--                                                                          --
--                                   MAIN                                   --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
------------------------------------------------------------------------------

with Taskset;
pragma Unreferenced(Taskset);
with System; 

with Ada.Synchronous_Task_Control;
with Activation_Manager;

procedure Main is
   pragma Priority (System.Priority'Last);
   pragma CPU (1);
begin
   Ada.Synchronous_Task_Control.Suspend_Until_True
     (Activation_Manager.Experiment_Is_Completed);
end Main;
