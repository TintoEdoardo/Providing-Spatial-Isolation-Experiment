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

--  DEBUG
with Ada.Text_IO; 

procedure Main is
   pragma Priority (System.Priority'Last);
   pragma CPU (1);
begin
   Ada.Synchronous_Task_Control.Suspend_Until_True
     (Activation_Manager.Experiment_Is_Completed);

   --  DEBUG
   Ada.Text_IO.Put_Line ("End of the experiment");
end Main;
