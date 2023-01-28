------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                     S T A C K _ P O O L _ A C C E S S                    --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
------------------------------------------------------------------------------

package body Stack_Pool_Access is

   package body Shared_Pointer is

      --  Last ID assigned to a reference.
      First_Free : System.Storage_Elements.Storage_Count := 0;

      ---------------------------------
      --  Operations on Reference_Type
      ---------------------------------

      function Get
        (Reference : Reference_Type) return Element_Type
      is
      begin
         return Reference.Element.all;
      end Get;

      procedure Assign (Left : in out Reference_Type; Right : Reference_Type)
      is
      begin
         Left.Element := Right.Element;

         --  Check if Right has been initialized.
         --  If so, after the assignment also Left
         --  is initialized.
         if Initialisation_List (Right.Id) = True then
            Initialisation_List (Left.Id) := True;
         else
            Initialisation_List (Left.Id) := False;
         end if;

      end Assign;

      procedure Allocate
        (Reference : in out Reference_Type)
      is
      begin
         Reference.Element := new Element_Type;
         Initialisation_List (Reference.Id) := True;
      end Allocate;

      ---------------------------------
      --  Operations on Shared_Pointer
      ---------------------------------

      procedure Free
      is
      begin
         Stack_Pool.Free (Pool);
         Initialize_Reference_List;
      end Free;

      procedure Initialize (Self : in out Reference_Type)
      is
         use System.Storage_Elements;
      begin
         Self.Id := First_Free;
         First_Free   := First_Free + 1;
         Initialisation_List (Self.Id) := False;
      end Initialize;

      procedure Initialize_Reference_List
      is
      begin
         for i in 0 .. Number_of_References loop
            Initialisation_List (i) := False;
         end loop;
      end Initialize_Reference_List;

      function Is_Initialized (Reference : Reference_Type)
                               return Boolean
      is
      begin
         return Initialisation_List (Reference.Id);
      end Is_Initialized;

   end Shared_Pointer;

end Stack_Pool_Access;
