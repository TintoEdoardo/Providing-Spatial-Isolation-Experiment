pragma Warnings (Off);
pragma Ada_95;
pragma Source_File_Name (ada_main, Spec_File_Name => "b__main.ads");
pragma Source_File_Name (ada_main, Body_File_Name => "b__main.adb");
pragma Suppress (Overflow_Check);

with System.Restrictions;

package body ada_main is

   E048 : Short_Integer; pragma Import (Ada, E048, "ada__text_io_E");
   E044 : Short_Integer; pragma Import (Ada, E044, "system__soft_links_E");
   E042 : Short_Integer; pragma Import (Ada, E042, "system__exception_table_E");
   E113 : Short_Integer; pragma Import (Ada, E113, "ada__strings__maps_E");
   E064 : Short_Integer; pragma Import (Ada, E064, "ada__tags_E");
   E050 : Short_Integer; pragma Import (Ada, E050, "core_execution_modes_E");
   E146 : Short_Integer; pragma Import (Ada, E146, "system__bb__timing_events_E");
   E099 : Short_Integer; pragma Import (Ada, E099, "ada__streams_E");
   E133 : Short_Integer; pragma Import (Ada, E133, "system__bb__execution_time_E");
   E102 : Short_Integer; pragma Import (Ada, E102, "system__finalization_root_E");
   E097 : Short_Integer; pragma Import (Ada, E097, "ada__finalization_E");
   E104 : Short_Integer; pragma Import (Ada, E104, "system__storage_pools_E");
   E148 : Short_Integer; pragma Import (Ada, E148, "real_time_no_elab__timing_events_no_elab_E");
   E094 : Short_Integer; pragma Import (Ada, E094, "system__finalization_masters_E");
   E090 : Short_Integer; pragma Import (Ada, E090, "system__storage_pools__subpools_E");
   E109 : Short_Integer; pragma Import (Ada, E109, "ada__strings__unbounded_E");
   E087 : Short_Integer; pragma Import (Ada, E087, "experiment_info_E");
   E054 : Short_Integer; pragma Import (Ada, E054, "system__tasking__protected_objects_E");
   E163 : Short_Integer; pragma Import (Ada, E163, "system__tasking__protected_objects__multiprocessors_E");
   E052 : Short_Integer; pragma Import (Ada, E052, "guard_experiment_E");
   E085 : Short_Integer; pragma Import (Ada, E085, "cpu_budget_monitor_E");
   E008 : Short_Integer; pragma Import (Ada, E008, "ada__real_time_E");
   E210 : Short_Integer; pragma Import (Ada, E210, "system__pool_global_E");
   E208 : Short_Integer; pragma Import (Ada, E208, "system__pool_size_E");
   E191 : Short_Integer; pragma Import (Ada, E191, "system__tasking__restricted__stages_E");
   E005 : Short_Integer; pragma Import (Ada, E005, "activation_manager_E");
   E204 : Short_Integer; pragma Import (Ada, E204, "channel_pool_E");
   E202 : Short_Integer; pragma Import (Ada, E202, "channel_pool_instances_E");
   E201 : Short_Integer; pragma Import (Ada, E201, "channel_pool_access_E");
   E193 : Short_Integer; pragma Import (Ada, E193, "experiment_parameters_E");
   E199 : Short_Integer; pragma Import (Ada, E199, "channels_E");
   E212 : Short_Integer; pragma Import (Ada, E212, "shared_protected_object_E");
   E214 : Short_Integer; pragma Import (Ada, E214, "workload_utilities_E");
   E197 : Short_Integer; pragma Import (Ada, E197, "high_criticality_task_workload_E");
   E195 : Short_Integer; pragma Import (Ada, E195, "high_criticality_task_E");
   E218 : Short_Integer; pragma Import (Ada, E218, "low_criticality_task_workload_E");
   E216 : Short_Integer; pragma Import (Ada, E216, "low_criticality_task_E");
   E192 : Short_Integer; pragma Import (Ada, E192, "taskset_E");

   Sec_Default_Sized_Stacks : array (1 .. 11) of aliased System.Secondary_Stack.SS_Stack (System.Parameters.Runtime_Default_Sec_Stack_Size);

   Local_Priority_Specific_Dispatching : constant String := "";
   Local_Interrupt_States : constant String := "";

   Is_Elaborated : Boolean := False;

   procedure adafinal is
      procedure s_stalib_adafinal;
      pragma Import (C, s_stalib_adafinal, "system__standard_library__adafinal");

      procedure Runtime_Finalize;
      pragma Import (C, Runtime_Finalize, "__gnat_runtime_finalize");

   begin
      if not Is_Elaborated then
         return;
      end if;
      Is_Elaborated := False;
      Runtime_Finalize;
      s_stalib_adafinal;
   end adafinal;

   procedure adainit is
      Main_Priority : Integer;
      pragma Import (C, Main_Priority, "__gl_main_priority");
      Time_Slice_Value : Integer;
      pragma Import (C, Time_Slice_Value, "__gl_time_slice_val");
      WC_Encoding : Character;
      pragma Import (C, WC_Encoding, "__gl_wc_encoding");
      Locking_Policy : Character;
      pragma Import (C, Locking_Policy, "__gl_locking_policy");
      Queuing_Policy : Character;
      pragma Import (C, Queuing_Policy, "__gl_queuing_policy");
      Task_Dispatching_Policy : Character;
      pragma Import (C, Task_Dispatching_Policy, "__gl_task_dispatching_policy");
      Priority_Specific_Dispatching : System.Address;
      pragma Import (C, Priority_Specific_Dispatching, "__gl_priority_specific_dispatching");
      Num_Specific_Dispatching : Integer;
      pragma Import (C, Num_Specific_Dispatching, "__gl_num_specific_dispatching");
      Main_CPU : Integer;
      pragma Import (C, Main_CPU, "__gl_main_cpu");
      Interrupt_States : System.Address;
      pragma Import (C, Interrupt_States, "__gl_interrupt_states");
      Num_Interrupt_States : Integer;
      pragma Import (C, Num_Interrupt_States, "__gl_num_interrupt_states");
      Unreserve_All_Interrupts : Integer;
      pragma Import (C, Unreserve_All_Interrupts, "__gl_unreserve_all_interrupts");
      Detect_Blocking : Integer;
      pragma Import (C, Detect_Blocking, "__gl_detect_blocking");
      Default_Stack_Size : Integer;
      pragma Import (C, Default_Stack_Size, "__gl_default_stack_size");
      Default_Secondary_Stack_Size : System.Parameters.Size_Type;
      pragma Import (C, Default_Secondary_Stack_Size, "__gnat_default_ss_size");
      Leap_Seconds_Support : Integer;
      pragma Import (C, Leap_Seconds_Support, "__gl_leap_seconds_support");
      Bind_Env_Addr : System.Address;
      pragma Import (C, Bind_Env_Addr, "__gl_bind_env_addr");

      procedure Runtime_Initialize (Install_Handler : Integer);
      pragma Import (C, Runtime_Initialize, "__gnat_runtime_initialize");
      procedure Start_Slave_CPUs;
      pragma Import (C, Start_Slave_CPUs, "__gnat_start_slave_cpus");
      Binder_Sec_Stacks_Count : Natural;
      pragma Import (Ada, Binder_Sec_Stacks_Count, "__gnat_binder_ss_count");
      Default_Sized_SS_Pool : System.Address;
      pragma Import (Ada, Default_Sized_SS_Pool, "__gnat_default_ss_pool");

   begin
      if Is_Elaborated then
         return;
      end if;
      Is_Elaborated := True;
      Main_Priority := 239;
      Time_Slice_Value := 0;
      WC_Encoding := 'b';
      Locking_Policy := 'C';
      Queuing_Policy := ' ';
      Task_Dispatching_Policy := 'F';
      System.Restrictions.Run_Time_Restrictions :=
        (Set =>
          (False, True, True, False, False, False, False, True, 
           False, False, False, False, False, False, False, True, 
           True, False, False, False, False, False, True, False, 
           False, False, False, False, False, False, False, False, 
           True, True, False, False, True, True, False, False, 
           False, True, False, False, False, False, True, False, 
           True, True, False, False, False, False, True, True, 
           False, True, True, False, True, False, False, False, 
           False, False, False, False, False, False, False, False, 
           False, False, False, False, False, True, False, False, 
           False, False, False, False, False, False, True, True, 
           False, True, False, False),
         Value => (0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
         Violated =>
          (True, False, False, False, True, True, False, False, 
           False, False, False, True, True, True, True, False, 
           False, False, False, False, True, True, False, True, 
           True, False, True, True, True, True, False, False, 
           False, False, False, True, False, False, True, False, 
           True, False, True, True, False, False, False, True, 
           False, False, False, True, False, False, False, False, 
           False, False, False, True, False, True, True, True, 
           True, False, True, False, True, True, True, False, 
           True, True, False, True, True, True, True, False, 
           False, True, False, False, False, True, False, False, 
           True, False, True, False),
         Count => (0, 0, 0, 1, 0, 0, 10, 0, 4, 0),
         Unknown => (False, False, False, False, False, False, False, False, True, False));
      Priority_Specific_Dispatching :=
        Local_Priority_Specific_Dispatching'Address;
      Num_Specific_Dispatching := 0;
      Main_CPU := 1;
      Interrupt_States := Local_Interrupt_States'Address;
      Num_Interrupt_States := 0;
      Unreserve_All_Interrupts := 0;
      Detect_Blocking := 1;
      Default_Stack_Size := -1;
      Leap_Seconds_Support := 0;

      ada_main'Elab_Body;
      Default_Secondary_Stack_Size := System.Parameters.Runtime_Default_Sec_Stack_Size;
      Binder_Sec_Stacks_Count := 11;
      Default_Sized_SS_Pool := Sec_Default_Sized_Stacks'Address;

      Runtime_Initialize (1);

      Ada.Text_Io'Elab_Body;
      E048 := E048 + 1;
      System.Soft_Links'Elab_Spec;
      System.Exception_Table'Elab_Body;
      E042 := E042 + 1;
      Ada.Strings.Maps'Elab_Spec;
      Core_Execution_Modes'Elab_Spec;
      System.Bb.Timing_Events'Elab_Spec;
      E113 := E113 + 1;
      Ada.Streams'Elab_Spec;
      Ada.Tags'Elab_Body;
      E064 := E064 + 1;
      System.Finalization_Root'Elab_Spec;
      E102 := E102 + 1;
      Ada.Finalization'Elab_Spec;
      E097 := E097 + 1;
      System.Storage_Pools'Elab_Spec;
      E104 := E104 + 1;
      E099 := E099 + 1;
      E146 := E146 + 1;
      Real_Time_No_Elab.Timing_Events_No_Elab'Elab_Spec;
      E148 := E148 + 1;
      System.Bb.Execution_Time'Elab_Body;
      E133 := E133 + 1;
      System.Finalization_Masters'Elab_Spec;
      System.Storage_Pools.Subpools'Elab_Spec;
      Ada.Strings.Unbounded'Elab_Spec;
      E109 := E109 + 1;
      Experiment_Info'Elab_Body;
      E087 := E087 + 1;
      System.Tasking.Protected_Objects'Elab_Body;
      E054 := E054 + 1;
      E044 := E044 + 1;
      System.Finalization_Masters'Elab_Body;
      E094 := E094 + 1;
      E090 := E090 + 1;
      Guard_Experiment'Elab_Spec;
      E052 := E052 + 1;
      E050 := E050 + 1;
      System.Tasking.Protected_Objects.Multiprocessors'Elab_Body;
      E163 := E163 + 1;
      Cpu_Budget_Monitor'Elab_Spec;
      E085 := E085 + 1;
      Ada.Real_Time'Elab_Body;
      E008 := E008 + 1;
      System.Pool_Global'Elab_Spec;
      E210 := E210 + 1;
      System.Pool_Size'Elab_Spec;
      E208 := E208 + 1;
      System.Tasking.Restricted.Stages'Elab_Body;
      E191 := E191 + 1;
      Activation_Manager'Elab_Spec;
      Activation_Manager'Elab_Body;
      E005 := E005 + 1;
      Channel_Pool'Elab_Spec;
      E204 := E204 + 1;
      Channel_Pool_Instances'Elab_Spec;
      E202 := E202 + 1;
      E201 := E201 + 1;
      Experiment_Parameters'Elab_Spec;
      E193 := E193 + 1;
      Channels'Elab_Spec;
      Channels'Elab_Body;
      E199 := E199 + 1;
      Shared_Protected_Object'Elab_Spec;
      E212 := E212 + 1;
      E214 := E214 + 1;
      E197 := E197 + 1;
      High_Criticality_Task'Elab_Body;
      E195 := E195 + 1;
      E218 := E218 + 1;
      Low_Criticality_Task'Elab_Body;
      E216 := E216 + 1;
      Taskset'Elab_Spec;
      E192 := E192 + 1;
      Start_Slave_CPUs;
   end adainit;

   procedure Ada_Main_Program;
   pragma Import (Ada, Ada_Main_Program, "_ada_main");

   procedure main is
      procedure Initialize (Addr : System.Address);
      pragma Import (C, Initialize, "__gnat_initialize");

      procedure Finalize;
      pragma Import (C, Finalize, "__gnat_finalize");
      SEH : aliased array (1 .. 2) of Integer;

      Ensure_Reference : aliased System.Address := Ada_Main_Program_Name'Address;
      pragma Volatile (Ensure_Reference);

   begin
      Initialize (SEH'Address);
      adainit;
      Ada_Main_Program;
      adafinal;
      Finalize;
   end;

--  BEGIN Object file/option list
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/activation_manager.o
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/experiment_parameters.o
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/channels.o
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/shared_protected_object.o
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/workload_utilities.o
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/high_criticality_task_workload.o
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/high_criticality_task.o
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/low_criticality_task_workload.o
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/low_criticality_task.o
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/taskset.o
   --   /home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/main.o
   --   -L/home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/
   --   -L/home/edoardo/proj/proj-releases/Providing-Spatial-Isolation-Experiment/Runtime_Cost_for_Message_Exchange_Copy/Providing-Spatial-Isolation-Experiment/obj/
   --   -L/home/edoardo/proj/Ada-RTE-supporting-semi-partitioned-model/runtime/arm-eabi/lib/gnat/ravenscar_full_zynq7000/adalib/
   --   -static
   --   -lgnarl
   --   -lgnat
--  END Object file/option list   

end ada_main;
