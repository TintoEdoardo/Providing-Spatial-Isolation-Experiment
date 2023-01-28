------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                          C H A N N E L _ P O O L                         --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
------------------------------------------------------------------------------

with System.Storage_Pools;
with System.Storage_Elements;

package Channel_Pool is

   pragma Elaborate_Body;
   --  Needed to ensure that library routines can execute allocators

   ------------------------
   -- Channel_Pool --
   ------------------------

   --  Allocation strategy:

   --    Pool dedicated to communication between
   --    tasks with different criticality levels.

   type Channel_Bounded_Pool
     (Pool_Size  : System.Storage_Elements.Storage_Count)
   is
     new System.Storage_Pools.Root_Storage_Pool with null record;

   overriding function Storage_Size
     (Pool : Channel_Bounded_Pool)
      return System.Storage_Elements.Storage_Count;

   overriding procedure Allocate
     (Pool         : in out Channel_Bounded_Pool;
      Address      : out System.Address;
      Storage_Size : System.Storage_Elements.Storage_Count;
      Alignment    : System.Storage_Elements.Storage_Count);

   overriding procedure Deallocate
     (Pool         : in out Channel_Bounded_Pool;
      Address      : System.Address;
      Storage_Size : System.Storage_Elements.Storage_Count;
      Alignment    : System.Storage_Elements.Storage_Count);

end Channel_Pool;
