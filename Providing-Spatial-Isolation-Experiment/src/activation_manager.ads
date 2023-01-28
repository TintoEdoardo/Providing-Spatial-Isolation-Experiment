------------------------------------------------------------------------------
--                                                                          --
--                            ACTIVATION MANAGER                            --
--                                                                          --
--                                  S p e c                                 --
--                                                                          --
------------------------------------------------------------------------------

with System; use System;
with System.Multiprocessors; use System.Multiprocessors;
with Ada.Synchronous_Task_Control;
with Ada.Real_Time;

package Activation_Manager is

	--  A reader task will wait on this suspension object before 
	--  acquiring the object on a channel.
	Could_Receive : Ada.Synchronous_Task_Control.Suspension_Object;

	--  A writer task will wait on this suspension object before
	--  sharing an object on a channel. 
   Could_Send    : Ada.Synchronous_Task_Control.Suspension_Object;
   
   --  The main procedure will suspend until the experiment is over
   Experiment_Is_Completed : Ada.Synchronous_Task_Control.Suspension_Object;

   task type Activator
	 (Id                              : Natural;
	 Priority                         : System.Priority;
	 Hosting_Migrating_Tasks_Priority : Integer;
	 Low_Critical_Budget              : Natural;
	 High_Critical_Budget             : Natural;
	 Workload                         : Positive;
	 Period                           : Positive;
	 Reduced_Deadline                 : Positive;
	 Could_Exceed                     : Boolean;
	 CPU_Id                           : CPU) 
   is
      pragma Priority (Priority);
      pragma CPU (CPU_Id);
   end Activator;
   
   procedure Synchronize_Activation_Cyclic (Time : in out Ada.Real_Time.Time);

end Activation_Manager;
