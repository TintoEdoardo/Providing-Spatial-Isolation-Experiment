import os

"""
    PATH AND CONSTANTS USED WHILE RUNNING THE EXPERIMENTS
"""

"""
    Constants
"""
experiment_id       = ["1_1", "1_2", "2_1"]
experiments_number  = len (experiment_id)
experiment_name     = {
    experiment_id [0] : "Channels without message overwriting",
    experiment_id [1] : "Channels with message overwriting",
    experiment_id [2] : "Protected Objects"
}
experiment_workload = {
    experiment_id [0] : 1,
    experiment_id [1] : 2,
    experiment_id [2] : 3
}

payload_size        = [1, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500]
payload_len          = len (payload_size)
number_of_samples   = 1000
src_folder_name     = "Providing-Spatial-Isolation-Experiment"
project_file        = "providing_spatial_isolation_experiment.gpr"
results_folder_name = "Results"
data_folder_name    = "Data"

metrics      = ["alloc", "free", "send", "receive"]
metrics_name = {
    metrics [0] : "Allocation times",
    metrics [1] : "Deallocation times",
    metrics [2] : "Send times",
    metrics [3] : "Receive times"
}
metrics_len  = len (metrics)

"""
    Paths
"""
working_directory   = os.getcwd()
path_to_experiments = os.path.join(working_directory, "Experiments")
path_to_graphs      = os.path.join(working_directory, "Graphs")
path_to_src         = os.path.join(working_directory, "Providing-Spatial-Isolation-Experiment")
path_to_exp         = {
    experiment_id [0] : os.path.join(path_to_experiments, "Experiments_" + experiment_id [0]),
    experiment_id [1] : os.path.join(path_to_experiments, "Experiments_" + experiment_id [1]),
    experiment_id [2] : os.path.join(path_to_experiments, "Experiments_" + experiment_id [2])
}
