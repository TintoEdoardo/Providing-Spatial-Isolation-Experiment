------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                   C H A N N E L _ P O O L _ A C C E S S                  --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
------------------------------------------------------------------------------

--  The following dependencies are used only in test applicaitons.
with Channel_Logger;
with System.BB.Time; use System.BB.Time;

package body Channel_Pool_Access is

   package body Shared_Pointer is

      ---------------------------------
      --  Operations on Reference_Type
      ---------------------------------

      function Get (Reference : Reference_Type)
                    return Element_Type_Reference
      is
      begin
         return Reference.Element;
      end Get;

      procedure Move (Left  : in out Reference_Type;
                      Right : in out Reference_Type)
      is
      begin
         Free (Left);
         Left.Element  := Right.Element;
         Right.Element := null;
      end Move;

      procedure Allocate (Reference : in out Reference_Type)
      is
      begin
         Reference.Element := new Element_Type;
      end Allocate;

      procedure Allocate (Reference    : in out Reference_Type;
                          From_Element : Element_Type)
      is
      begin
         Reference.Element     := new Element_Type;
         Reference.Element.all := From_Element;
      end Allocate;

      procedure Free (Reference : in out Reference_Type)
      is
      begin
         Free_Element (Reference.Element);
         Reference.Element := null;
      end Free;

      function Is_Null (Reference : Reference_Type)
                        return Boolean
      is
      begin
         return Reference.Element = null;
      end Is_Null;

      ---------------------------------
      --  Operations on Channel
      ---------------------------------
      protected body Shared_Reference is
         procedure Send (Reference : in out Reference_Type)
         is
         begin
            Move (Internal_Reference, Reference);
            Message_Available := True;
         end Send;

         entry Receive (Reference : in out Reference_Type)
           when Message_Available is
         begin
            Move (Reference, Internal_Reference);
            Message_Available := False;
         end Receive;
      end Shared_Reference;

      ---------------------------------
      --  Experiments
      ---------------------------------
      protected body Experiment_Shared_Reference is

         procedure Experiment_Send
           (Reference : in out Reference_Type;
            Iteration  : Positive;
            Experiment : Integer)
         is
            Time_Event_1 : System.BB.Time.Time;
            Time_Event_2 : System.BB.Time.Time;
            Send_Time    : System.BB.Time.Time_Span;
         begin
            Time_Event_1 := System.BB.Time.Clock;

            Move (Internal_Reference, Reference);
            Message_Available := True;

            Time_Event_2 := System.BB.Time.Clock;

            --  Logs generation.
            Send_Time := Time_Event_2 - Time_Event_1;
            Channel_Logger.
              Array_Send_Ownership_Times (Iteration, Experiment) :=
              Send_Time;
         end Experiment_Send;

         entry Experiment_Receive
           (Reference : in out Reference_Type;
            Iteration  : Positive;
            Experiment : Integer)
           when Message_Available
         is
            Time_Event_1 : System.BB.Time.Time;
            Time_Event_2 : System.BB.Time.Time;
            Receive_Time : System.BB.Time.Time_Span;
         begin
            Time_Event_1 := System.BB.Time.Clock;

            Move (Reference, Internal_Reference);
            Message_Available := False;

            Time_Event_2 := System.BB.Time.Clock;

            --  Logs generation.
            Receive_Time := Time_Event_2 - Time_Event_1;
            Channel_Logger.
              Array_Receive_Ownership_Times (Iteration, Experiment)
              := Receive_Time;
         end Experiment_Receive;
      end Experiment_Shared_Reference;

      procedure Experiment_Allocate
        (Reference : in out Reference_Type;
         Iteration  : Positive;
         Experiment : Integer)
      is
         Time_Event_1 : System.BB.Time.Time;
         Time_Event_2 : System.BB.Time.Time;
         Alloc_Time   : System.BB.Time.Time_Span;
      begin
         Time_Event_1 := System.BB.Time.Clock;

         Reference.Element := new Element_Type;

         Time_Event_2 := System.BB.Time.Clock;

         Alloc_Time := Time_Event_2 - Time_Event_1;
         Channel_Logger.
           Array_Allocation_Times (Iteration, Experiment) :=
           Alloc_Time;
      end Experiment_Allocate;

      procedure Experiment_Free
        (Reference : in out Reference_Type;
         Iteration  : Positive;
         Experiment : Integer)
      is
         Time_Event_1 : System.BB.Time.Time;
         Time_Event_2 : System.BB.Time.Time;
         Free_Time    : System.BB.Time.Time_Span;
      begin
         Time_Event_1 := System.BB.Time.Clock;

         Free_Element (Reference.Element);
         Reference.Element := null;

         Time_Event_2 := System.BB.Time.Clock;

         Free_Time := Time_Event_2 - Time_Event_1;
         Channel_Logger.
           Array_Deallocation_Times (Iteration, Experiment) :=
           Free_Time;
      end Experiment_Free;
   end Shared_Pointer;

end Channel_Pool_Access;
