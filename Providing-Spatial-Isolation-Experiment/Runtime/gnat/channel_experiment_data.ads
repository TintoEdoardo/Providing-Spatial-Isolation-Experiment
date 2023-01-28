package Channel_Experiment_Data is

   --  In order to increase the size of the message, we
   --  include increasing longer array to each message
   --  type.

   Message_Filler_Size : array (1 .. 10) of Positive :=
     (1, 1139, 2276, 3414, 4552, 5689, 6827, 7965, 9102, 10240);

   type Filler is new Boolean;
   for Filler'Size use 8;

   type Array_of_Filler  is array (Positive range <>) of Filler;

   type Base_Message is tagged null record;

   type Derived_Message (i : Positive) is new Base_Message with record
      List : Array_of_Filler (1 .. i);
   end record;

   type Message_1 is new Derived_Message
     (Message_Filler_Size (1)) with null record;
   type Message_2 is new Derived_Message
     (Message_Filler_Size (2)) with null record;
   type Message_3 is new Derived_Message
     (Message_Filler_Size (3)) with null record;
   type Message_4 is new Derived_Message
     (Message_Filler_Size (4)) with null record;
   type Message_5 is new Derived_Message
     (Message_Filler_Size (5)) with null record;
   type Message_6 is new Derived_Message
     (Message_Filler_Size (6)) with null record;
   type Message_7 is new Derived_Message
     (Message_Filler_Size (7)) with null record;
   type Message_8 is new Derived_Message
     (Message_Filler_Size (8)) with null record;
   type Message_9 is new Derived_Message
     (Message_Filler_Size (9)) with null record;
   type Message_10 is new Derived_Message
     (Message_Filler_Size (10)) with null record;

end Channel_Experiment_Data;
