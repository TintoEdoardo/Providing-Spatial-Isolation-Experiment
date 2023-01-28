------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                            S T A C K _ P O O L                           --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
------------------------------------------------------------------------------

with System.Storage_Pools;
with System.Storage_Elements;

package Stack_Pool is

   pragma Elaborate_Body;
   --  Needed to ensure that library routines can execute allocators

   type Address_Array is
     array (System.Storage_Elements.Storage_Count range <>)
       of aliased System.Address;

   ------------------------
   -- Stack_Bounded_Pool --
   ------------------------

   --  Allocation strategy:

   --    Pool is a regular stack array, no use of malloc
   --    user specified size
   --    Space of pool is globally reclaimed by normal stack management

   type Stack_Bounded_Pool
     (Pool_Size : System.Storage_Elements.Storage_Count;
      Elmt_Size : System.Storage_Elements.Storage_Count;
      Alignment : System.Storage_Elements.Storage_Count)
   is
      new System.Storage_Pools.Root_Storage_Pool with record
         First_Free        : System.Storage_Elements.Storage_Count;
         First_Empty       : System.Storage_Elements.Storage_Count;
         Aligned_Elmt_Size : System.Storage_Elements.Storage_Count;
         Next_Allocated    : System.Storage_Elements.Storage_Count;
         The_Pool          : System.Storage_Elements.Storage_Array
        (1 .. Pool_Size);
         Address_List      : Address_Array
           (0 .. Pool_Size);
      end record;

   overriding function Storage_Size
     (Pool : Stack_Bounded_Pool) return System.Storage_Elements.Storage_Count;

   overriding procedure Allocate
     (Pool         : in out Stack_Bounded_Pool;
      Address      : out System.Address;
      Storage_Size : System.Storage_Elements.Storage_Count;
      Alignment    : System.Storage_Elements.Storage_Count);

   overriding procedure Deallocate
     (Pool         : in out Stack_Bounded_Pool;
      Address      : System.Address;
      Storage_Size : System.Storage_Elements.Storage_Count;
      Alignment    : System.Storage_Elements.Storage_Count);

   overriding procedure Initialize (Pool : in out Stack_Bounded_Pool);

   procedure Free (Pool : in out Stack_Bounded_Pool);

end Stack_Pool;
