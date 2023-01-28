------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                    S T A C K _ P O O L _ L O G G E R                     --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
------------------------------------------------------------------------------

with Ada;
with Ada.Text_IO;

package body Stack_Pool_Logger is

   protected body Stapoo_Logger is
      entry Write_Message (Message : String)
        when Is_Free is
      begin
         Is_Free := False;
         Ada.Text_IO.Put_Line (Message);
         Is_Free := True;
      end Write_Message;

   end Stapoo_Logger;

end Stack_Pool_Logger;
