------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                     S T A C K _ P O O L _ A C C E S S                    --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Finalization;
with Stack_Pool;
with System.Storage_Elements;

package Stack_Pool_Access is
   --  This package use generics.
   --  There is no limit on the number of
   --  stack pools that can be defined.

   generic
      --  Element_Type is a generic element that
      --  can be allocatend in a stack pool.
      type Element_Type is private;

      Number_of_References : System.Storage_Elements.Storage_Count;

      --  Parameters specific for the creation of the pool.
      Pool_Size : System.Storage_Elements.Storage_Count;
      Elmt_Size : System.Storage_Elements.Storage_Count;
      Alignment : System.Storage_Elements.Storage_Count;

      --  Access type are not sufficient for granting the more
      --  predictable behaviour discussed in ???.
      --  For this reason a new type is defined to incapsulate
      --  standard access type.
   package Shared_Pointer is

      --  NOTE: the pool is specific for Element_Type.
      --  In this way we enforce the fact that pool are defined per-type.
      Pool : Stack_Pool.Stack_Bounded_Pool (Pool_Size, Elmt_Size, Alignment);

      type Element_Type_Reference is access Element_Type;
      for Element_Type_Reference'Storage_Pool use Pool;

      --  For all reference, specify if it has been initialised
      --  or if it should be consider null.
      --  NOTE: an uninitialised reference might not be null,
      --  for example after a deallocation, therefore instead
      --  of checking if Element is null, use the dedicated
      --  function Is_Initialized.
      Initialisation_List : array (0 .. Number_of_References) of Boolean;

      --  Reference_Type encapsulate the access
      --  type for an element of Element_Type.
      type Reference_Type is new Ada.Finalization.Limited_Controlled
        with record
         Id      : System.Storage_Elements.Storage_Count;
         Element : Element_Type_Reference;
      end record;

      ---------------------------------
      --  Operations on Reference_Type
      ---------------------------------

      function Get (Reference : Reference_Type)
                    return Element_Type;

      procedure Assign (Left : in out Reference_Type; Right : Reference_Type);

      --  Allocate an element of type Element_Type,
      --  referenced by Reference.
      procedure Allocate (Reference : in out Reference_Type);

      ---------------------------------
      --  Operations on Shared_Pointer
      ---------------------------------

      --  Clear the whole stack pool.
      procedure Free;

      --  Initialize the reference, and set the ID.
      procedure Initialize (Self : in out Reference_Type);

      --  Initialize the Number_of_References.
      procedure Initialize_Reference_List;

      --  Return the value of Initialization_List (reference.id).
      function Is_Initialized (Reference : Reference_Type)
        return Boolean;

   end Shared_Pointer;

end Stack_Pool_Access;
