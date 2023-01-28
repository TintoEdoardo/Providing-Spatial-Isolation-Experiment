--  semi-partitioned model for dual-core mixed criticality system (MCS)
--  Xu & Burns
--  https://dl.acm.org/doi/10.1145/2834848.2834865

pragma Restrictions (No_Elaboration_Code);

package Mixed_Criticality_System is
   pragma Pure;

   --  It is the set values of task criticality level.
   type Criticality is (HIGH, LOW);

end Mixed_Criticality_System;
