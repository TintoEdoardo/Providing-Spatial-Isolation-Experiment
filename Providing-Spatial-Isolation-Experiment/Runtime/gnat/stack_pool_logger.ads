------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                    S T A C K _ P O O L _ L O G G E R                     --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
------------------------------------------------------------------------------

with System;

package Stack_Pool_Logger is

   protected Stapoo_Logger is
      pragma Priority (System.Max_Interrupt_Priority);
      entry Write_Message (Message : String);
   private
      Is_Free : Boolean := True;
   end Stapoo_Logger;

end Stack_Pool_Logger;
