------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                          C H A N N E L _ P O O L                         --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
------------------------------------------------------------------------------

with System.Memory;
with System; use System;

package body Channel_Pool is

   package SSE renames System.Storage_Elements;

   --------------
   -- Allocate --
   --------------

   overriding procedure Allocate
     (Pool         : in out Channel_Bounded_Pool;
      Address      : out System.Address;
      Storage_Size : System.Storage_Elements.Storage_Count;
      Alignment    : System.Storage_Elements.Storage_Count)
   is
      use SSE;
      pragma Warnings (Off, Pool);

      Aligned_Size    : Storage_Count := Storage_Size;
      Aligned_Address : System.Address;
      Allocated       : System.Address;

   begin
      if Alignment > Standard'System_Allocator_Alignment then
         Aligned_Size := Aligned_Size + Alignment;
      end if;

      Allocated := System.Memory.Alloc (System.Memory.size_t (Aligned_Size));

      --  The call to Alloc returns an address whose alignment is compatible
      --  with the worst case alignment requirement for the machine; thus the
      --  Alignment argument can be safely ignored.

      if Allocated = Null_Address then
         raise Storage_Error;
      end if;

      --  Case where alignment requested is greater than the alignment that is
      --  guaranteed to be provided by the system allocator.

      if Alignment > Standard'System_Allocator_Alignment then

         --  Realign the returned address

         Aligned_Address := To_Address
           (To_Integer (Allocated) + Integer_Address (Alignment)
              - (To_Integer (Allocated) mod Integer_Address (Alignment)));

         --  Save the block address

         declare
            Saved_Address : System.Address;
            pragma Import (Ada, Saved_Address);
            for Saved_Address'Address use
               Aligned_Address
               - Storage_Offset (System.Address'Size / Storage_Unit);
         begin
            Saved_Address := Allocated;
         end;

         Address := Aligned_Address;

      else
         Address := Allocated;
      end if;
   end Allocate;

   ----------------
   -- Deallocate --
   ----------------

   overriding procedure Deallocate
     (Pool         : in out Channel_Bounded_Pool;
      Address      : System.Address;
      Storage_Size : SSE.Storage_Count;
      Alignment    : SSE.Storage_Count)
   is
      use System.Storage_Elements;
      pragma Warnings (Off, Pool);
      pragma Warnings (Off, Storage_Size);

   begin
      --  Case where the alignment of the block exceeds the guaranteed
      --  alignment required by the system storage allocator, meaning that
      --  this was specially wrapped at allocation time.

      if Alignment > Standard'System_Allocator_Alignment then

         --  Retrieve the block address

         declare
            Saved_Address : System.Address;
            pragma Import (Ada, Saved_Address);
            for Saved_Address'Address use
              Address - Storage_Offset (System.Address'Size / Storage_Unit);
         begin
            Memory.Free (Saved_Address);
         end;

      else
         Memory.Free (Address);
      end if;
   end Deallocate;

   ------------------
   -- Storage_Size --
   ------------------

   overriding function Storage_Size
     (Pool  : Channel_Bounded_Pool)
      return  SSE.Storage_Count
   is
      pragma Warnings (Off, Pool);

   begin
      --  Intuitively, should return System.Memory_Size. But on Sun/Alsys,
      --  System.Memory_Size > System.Max_Int, which means all you can do with
      --  it is raise CONSTRAINT_ERROR...

      return SSE.Storage_Count'Last;
   end Storage_Size;

end Channel_Pool;
