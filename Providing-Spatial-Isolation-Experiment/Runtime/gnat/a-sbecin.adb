------------------------------------------------------------------------------
--                                                                          --
--                         GNAT LIBRARY COMPONENTS                          --
--                                                                          --
--                ADA.STRINGS.BOUNDED.EQUAL_CASE_INSENSITIVE                --
--                                                                          --
--                                B o d y                                   --
--                                                                          --
--            Copyright (C) 2011-2018, Free Software Foundation, Inc.       --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- This unit was originally developed by Matthew J Heaney.                  --
------------------------------------------------------------------------------

with Ada.Strings.Equal_Case_Insensitive;

function Ada.Strings.Bounded.Equal_Case_Insensitive
  (Left, Right : Bounded.Bounded_String)
  return Boolean
is
begin
   return Ada.Strings.Equal_Case_Insensitive
     (Left  => Bounded.To_String (Left),
      Right => Bounded.To_String (Right));
end Ada.Strings.Bounded.Equal_Case_Insensitive;