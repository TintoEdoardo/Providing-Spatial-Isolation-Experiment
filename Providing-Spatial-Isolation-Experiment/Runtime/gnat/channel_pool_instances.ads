------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                C H A N N E L _ P O O L S _ I N S T A N C E S             --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
------------------------------------------------------------------------------
with Channel_Pool;

package Channel_Pool_Instances is

   --  This pool will be used for communication
   --  between tasks with high criticality and
   --  task with low criticality levels.
   High_Low_Channel_Pool : Channel_Pool.Channel_Bounded_Pool (10);

end Channel_Pool_Instances;
