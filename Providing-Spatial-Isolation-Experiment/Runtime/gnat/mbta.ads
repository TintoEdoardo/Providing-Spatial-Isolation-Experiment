with System.Multiprocessors;
use System.Multiprocessors;

package MBTA is
   pragma Preelaborate;

   --  see the following link to know the runtime primitives we log.
   --  https://gitlab.com/thesisBottaroMattia/ada-ravenscar-runtime-for-
   --  zynq7000-dual-core-supporting-mixed-criticality-systems/-/issues
   --  /1#note_525338351

   --  DU is Delay_Until
   --  CSN is Context_Switch_Needed
   --  CSW is Context_Switch
   --  AH is Alarm_Handler
   --  WEA_UA are Wakeup_Expired_Alarms and Update_Alarm
   --  SM is Start_Monitor
   --  CM is Clear_Monitor
   --  BED is BE_Detected
   --  EEV is Execute_Expired_Events
   --  BI is the span between Disable_Interrupts and Enable_Interrupts
   type RTE_Primitive is (DU, CSN, CSW, AH, WEA_UA, SM, CM, BED, EEV, BI);

   procedure Log_RTE_Primitive_Duration
     (Primitive : RTE_Primitive; Primitive_Duration : Duration; CPU_Id : CPU);

   procedure Print_Log_RTE_Primitive_Duration;

end MBTA;
