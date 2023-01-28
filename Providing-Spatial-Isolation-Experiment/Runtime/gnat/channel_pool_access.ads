------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                   C H A N N E L _ P O O L _ A C C E S S                  --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Finalization;
with Ada.Unchecked_Deallocation;
with Channel_Pool_Instances;
with Mixed_Criticality_System;

package Channel_Pool_Access is
   --  This package use generics.
   --  There is no limit on the number of
   --  channel pools that can be defined.

   type Channel_Levels is new Mixed_Criticality_System.Criticality;

   generic
      --  Element_Type is a generic element that
      --  can be allocatend as a message in a channel pool.
      type Element_Type is tagged private;

      --  Channel_First_Level  : Channel_Levels := HIGH;
      --  Channel_Second_Level : Channel_Levels := LOW;

   package Shared_Pointer is
      --  Instead of using standard access type,
      --  a shared pointer type is used.

      type Element_Type_Reference is access Element_Type;

      --  We assume that just two criticality levels exist.
      --  In order to support more criticality levels, it
      --  should be possible to chose the desired pool.
      for Element_Type_Reference'Storage_Pool use
        Channel_Pool_Instances.High_Low_Channel_Pool;

      --  Reference_Type encapsulate the access
      --  type for an element of Element_Type.
      type Reference_Type is new Ada.Finalization.Limited_Controlled
      with record
         Element : Element_Type_Reference;
      end record;

      ---------------------------------
      --  Channel type definition
      ---------------------------------

      protected type Shared_Reference is
         procedure Send (Reference : in out Reference_Type);
         entry Receive  (Reference : in out Reference_Type);
      private
         Message_Available  : Boolean := False;
         Internal_Reference : Reference_Type;
      end Shared_Reference;

      ---------------------------------
      --  Operations on Reference_Type
      ---------------------------------

      function Get (Reference : Reference_Type)
                    return Element_Type_Reference;

      procedure Move (Left  : in out Reference_Type;
                      Right : in out Reference_Type);

      --  Allocate an element of type Element_Type,
      --  referenced by Reference.
      procedure Allocate (Reference : in out Reference_Type);
      procedure Allocate (Reference    : in out Reference_Type;
                          From_Element : Element_Type);

      procedure Free (Reference : in out Reference_Type);

      function Is_Null (Reference : Reference_Type)
                        return Boolean;

      ---------------------------------
      --  Experiments operations
      ---------------------------------
      protected type Experiment_Shared_Reference is
         procedure Experiment_Send
           (Reference  : in out Reference_Type;
            Iteration  : Positive;
            Experiment : Integer);
         entry Experiment_Receive
           (Reference  : in out Reference_Type;
            Iteration  : Positive;
            Experiment : Integer);
      private
         Message_Available  : Boolean := False;
         Internal_Reference : Reference_Type;
      end Experiment_Shared_Reference;

      procedure Experiment_Allocate
        (Reference  : in out Reference_Type;
         Iteration  : Positive;
         Experiment : Integer);

      procedure Experiment_Free
        (Reference  : in out Reference_Type;
         Iteration  : Positive;
         Experiment : Integer);

   private

      procedure Free_Element is new
        Ada.Unchecked_Deallocation
          (Element_Type, Element_Type_Reference);

   end Shared_Pointer;

end Channel_Pool_Access;
