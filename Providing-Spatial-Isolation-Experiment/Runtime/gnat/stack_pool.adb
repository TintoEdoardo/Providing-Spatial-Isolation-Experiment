------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                            S T A C K _ P O O L                           --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Unchecked_Conversion;
with System; use System;

package body Stack_Pool is

   package SSE renames System.Storage_Elements;
   use type SSE.Storage_Offset;

   --  Targettig exclusively Ravenscar compilant tasks,
   --  there are no subtasks, hence no concurrent heap access.

   type Storage_Count_Access is access SSE.Storage_Count;
   function To_Storage_Count_Access is
     new Ada.Unchecked_Conversion (Address, Storage_Count_Access);

   SC_Size : constant := SSE.Storage_Count'Object_Size / System.Storage_Unit;

   package Variable_Size_Management is

      --  Embedded pool that manages allocation of variable-size data

      --  This pool is used as soon as the Elmt_Size of the pool object is 0

      --  Allocation is done on the first chunk long enough for the request.
      --  Deallocation just puts the freed chunk at the beginning of the list.

      procedure Initialize  (Pool : in out Stack_Bounded_Pool);
      procedure Allocate
        (Pool         : in out Stack_Bounded_Pool;
         Address      : out System.Address;
         Storage_Size : SSE.Storage_Count;
         Alignment    : SSE.Storage_Count);

      procedure Deallocate
        (Pool         : in out Stack_Bounded_Pool;
         Address      : System.Address;
         Storage_Size : SSE.Storage_Count;
         Alignment    : SSE.Storage_Count);
   end Variable_Size_Management;

   package Vsize renames Variable_Size_Management;

   --------------
   -- Allocate --
   --------------

   procedure Allocate
     (Pool         : in out Stack_Bounded_Pool;
      Address      : out System.Address;
      Storage_Size : SSE.Storage_Count;
      Alignment    : SSE.Storage_Count)
   is
   begin

      if Pool.Elmt_Size = 0 then
         Vsize.Allocate (Pool, Address, Storage_Size, Alignment);
         Pool.Address_List (Pool.Next_Allocated) := Address;
         Pool.Next_Allocated := Pool.Next_Allocated + 1;

      elsif Pool.First_Free /= 0 then
         Address := Pool.The_Pool (Pool.First_Free)'Address;
         Pool.First_Free := To_Storage_Count_Access (Address).all;
         Pool.Address_List (Pool.Next_Allocated) := Address;
         Pool.Next_Allocated := Pool.Next_Allocated + 1;

      elsif
        Pool.First_Empty <= (Pool.Pool_Size - Pool.Aligned_Elmt_Size + 1)
      then
         Address := Pool.The_Pool (Pool.First_Empty)'Address;
         Pool.First_Empty := Pool.First_Empty + Pool.Aligned_Elmt_Size;
         Pool.Address_List (Pool.Next_Allocated) := Address;
         Pool.Next_Allocated := Pool.Next_Allocated + 1;

      else
         raise Storage_Error;
      end if;

   end Allocate;

   ----------------
   -- Deallocate --
   ----------------

   procedure Deallocate
     (Pool         : in out Stack_Bounded_Pool;
      Address      : System.Address;
      Storage_Size : SSE.Storage_Count;
      Alignment    : SSE.Storage_Count)
   is
   begin
      if Pool.Elmt_Size = 0 then
         Vsize.Deallocate (Pool, Address, Storage_Size, Alignment);

      else
         To_Storage_Count_Access (Address).all := Pool.First_Free;
         Pool.First_Free := Address - Pool.The_Pool'Address + 1;
      end if;

   end Deallocate;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Pool : in out Stack_Bounded_Pool) is

      --  Define the appropriate alignment for allocations. This is the
      --  maximum of the requested alignment, and the alignment required
      --  for Storage_Count values. The latter test is to ensure that we
      --  can properly reference the linked list pointers for free lists.

      Align : constant SSE.Storage_Count :=
                SSE.Storage_Count'Max
                  (SSE.Storage_Count'Alignment, Pool.Alignment);

   begin
      if Pool.Elmt_Size = 0 then
         Vsize.Initialize (Pool);

      else
         Pool.First_Free     := 0;
         Pool.First_Empty    := 1;
         Pool.Next_Allocated := 0;

         --  Compute the size to allocate given the size of the element and
         --  the possible alignment requirement as defined above.

         Pool.Aligned_Elmt_Size :=
           SSE.Storage_Count'Max (SC_Size,
             ((Pool.Elmt_Size + Align - 1) / Align) * Align);
      end if;
   end Initialize;

   ----------
   -- Free --
   ----------

   procedure Free (Pool : in out Stack_Bounded_Pool)
   is
      --  Clear the entire pool.
   begin
      for Addr in 0 .. (Pool.Next_Allocated - 1) loop
         Deallocate
           (Pool, Pool.Address_List (Addr), Pool.Elmt_Size, Pool.Alignment);
      end loop;
      Pool.First_Free     := 0;
      Pool.First_Empty    := 1;
      Pool.Next_Allocated := 0;
   end Free;

   ------------------
   -- Storage_Size --
   ------------------

   function Storage_Size
     (Pool : Stack_Bounded_Pool) return SSE.Storage_Count
   is
   begin
      return Pool.Pool_Size;
   end Storage_Size;

   ------------------------------
   -- Variable_Size_Management --
   ------------------------------

   package body Variable_Size_Management is

      Minimum_Size : constant := 2 * SC_Size;

      procedure Set_Size
        (Pool        : Stack_Bounded_Pool;
         Chunk, Size : SSE.Storage_Count);
      --  Update the field 'size' of a chunk of available storage

      procedure Set_Next
        (Pool        : Stack_Bounded_Pool;
         Chunk, Next : SSE.Storage_Count);
      --  Update the field 'next' of a chunk of available storage

      function Size
        (Pool  : Stack_Bounded_Pool;
         Chunk : SSE.Storage_Count) return SSE.Storage_Count;
      --  Fetch the field 'size' of a chunk of available storage

      function Next
        (Pool  : Stack_Bounded_Pool;
         Chunk : SSE.Storage_Count) return SSE.Storage_Count;
      --  Fetch the field 'next' of a chunk of available storage

      function Chunk_Of
        (Pool : Stack_Bounded_Pool;
         Addr : System.Address) return SSE.Storage_Count;
      --  Give the chunk number in the pool from its Address

      --------------
      -- Allocate --
      --------------

      procedure Allocate
        (Pool         : in out Stack_Bounded_Pool;
         Address      : out System.Address;
         Storage_Size : SSE.Storage_Count;
         Alignment    : SSE.Storage_Count)
      is
         Chunk      : SSE.Storage_Count;
         New_Chunk  : SSE.Storage_Count;
         Prev_Chunk : SSE.Storage_Count;
         Our_Align  : constant SSE.Storage_Count :=
                        SSE.Storage_Count'Max (SSE.Storage_Count'Alignment,
                                               Alignment);
         Align_Size : constant SSE.Storage_Count :=
                        SSE.Storage_Count'Max (
                          Minimum_Size,
                          ((Storage_Size + Our_Align - 1) / Our_Align) *
                                                                  Our_Align);

      begin
         --  Look for the first big enough chunk

         Prev_Chunk := Pool.First_Free;
         Chunk := Next (Pool, Prev_Chunk);

         while Chunk /= 0 and then Size (Pool, Chunk) < Align_Size loop
            Prev_Chunk := Chunk;
            Chunk := Next (Pool, Chunk);
         end loop;

         --  Raise storage_error if no big enough chunk available

         if Chunk = 0 then
            raise Storage_Error;
         end if;

         --  When the chunk is bigger than what is needed, take appropriate
         --  amount and build a new shrinked chunk with the remainder.

         if Size (Pool, Chunk) - Align_Size  > Minimum_Size then
            New_Chunk := Chunk + Align_Size;
            Set_Size (Pool, New_Chunk, Size (Pool, Chunk) - Align_Size);
            Set_Next (Pool, New_Chunk, Next (Pool, Chunk));
            Set_Next (Pool, Prev_Chunk, New_Chunk);

         --  If the chunk is the right size, just delete it from the chain

         else
            Set_Next (Pool, Prev_Chunk, Next (Pool, Chunk));
         end if;

         Address := Pool.The_Pool (Chunk)'Address;
      end Allocate;

      --------------
      -- Chunk_Of --
      --------------

      function Chunk_Of
        (Pool : Stack_Bounded_Pool;
         Addr : System.Address) return SSE.Storage_Count
      is
      begin
         return 1 + abs (Addr - Pool.The_Pool (1)'Address);
      end Chunk_Of;

      ----------------
      -- Deallocate --
      ----------------

      procedure Deallocate
        (Pool         : in out Stack_Bounded_Pool;
         Address      : System.Address;
         Storage_Size : SSE.Storage_Count;
         Alignment    : SSE.Storage_Count)
      is
         pragma Warnings (Off, Pool);

         Align_Size : constant SSE.Storage_Count :=
                        ((Storage_Size + Alignment - 1) / Alignment) *
                                                                 Alignment;
         Chunk : constant SSE.Storage_Count := Chunk_Of (Pool, Address);

      begin
         --  Attach the freed chunk to the chain

         Set_Size (Pool, Chunk,
                         SSE.Storage_Count'Max (Align_Size, Minimum_Size));
         Set_Next (Pool, Chunk, Next (Pool, Pool.First_Free));
         Set_Next (Pool, Pool.First_Free,  Chunk);

      end Deallocate;

      ----------------
      -- Initialize --
      ----------------

      procedure Initialize  (Pool : in out Stack_Bounded_Pool) is
      begin
         Pool.First_Free := 1;

         if Pool.Pool_Size > Minimum_Size then
            Set_Next (Pool, Pool.First_Free, Pool.First_Free + Minimum_Size);
            Set_Size (Pool, Pool.First_Free, 0);
            Set_Size (Pool, Pool.First_Free + Minimum_Size,
                                              Pool.Pool_Size - Minimum_Size);
            Set_Next (Pool, Pool.First_Free + Minimum_Size, 0);
         end if;
      end Initialize;

      ----------
      -- Next --
      ----------

      function Next
        (Pool  : Stack_Bounded_Pool;
         Chunk : SSE.Storage_Count) return SSE.Storage_Count
      is
      begin
         pragma Warnings (Off);
         --  Kill alignment warnings, we are careful to make sure
         --  that the alignment is correct.

         return To_Storage_Count_Access
                  (Pool.The_Pool (Chunk + SC_Size)'Address).all;

         pragma Warnings (On);
      end Next;

      --------------
      -- Set_Next --
      --------------

      procedure Set_Next
        (Pool        : Stack_Bounded_Pool;
         Chunk, Next : SSE.Storage_Count)
      is
      begin
         pragma Warnings (Off);
         --  Kill alignment warnings, we are careful to make sure
         --  that the alignment is correct.

         To_Storage_Count_Access
           (Pool.The_Pool (Chunk + SC_Size)'Address).all := Next;

         pragma Warnings (On);
      end Set_Next;

      --------------
      -- Set_Size --
      --------------

      procedure Set_Size
        (Pool        : Stack_Bounded_Pool;
         Chunk, Size : SSE.Storage_Count)
      is
      begin
         pragma Warnings (Off);
         --  Kill alignment warnings, we are careful to make sure
         --  that the alignment is correct.

         To_Storage_Count_Access
           (Pool.The_Pool (Chunk)'Address).all := Size;

         pragma Warnings (On);
      end Set_Size;

      ----------
      -- Size --
      ----------

      function Size
        (Pool  : Stack_Bounded_Pool;
         Chunk : SSE.Storage_Count) return SSE.Storage_Count
      is
      begin
         pragma Warnings (Off);
         --  Kill alignment warnings, we are careful to make sure
         --  that the alignment is correct.

         return To_Storage_Count_Access (Pool.The_Pool (Chunk)'Address).all;

         pragma Warnings (On);
      end Size;

   end  Variable_Size_Management;

end Stack_Pool;
