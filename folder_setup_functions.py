import shutil
import os
import paths_and_constants as pc

"""
    SETUP FUNCTIONS USED BEFORE THE EXPERIMENTS EXECUTION 
"""


def clearExperimentsDirectory ():
    """
    Delete the Experiments directory and create a new one.
    """
    shutil.rmtree (pc.path_to_experiments, ignore_errors=True)
    os.mkdir (pc.path_to_experiments)


def clearGraphDirectory ():
    """
    Delete the Graphs directory and create a new one.
    """
    shutil.rmtree (pc.path_to_graphs, ignore_errors=True)
    os.mkdir (pc.path_to_graphs)


def populateExperimentsDirectory ():
    """
    Compile the test application for each configuration.
    """
    for e_id in pc.experiment_id:

        #  Create the Result folder
        result_folder = os.path.join (pc.path_to_exp [e_id], pc.results_folder_name)
        os.makedirs (result_folder)

        #  Create the Data folder
        data_folder = os.path.join (pc.path_to_exp[e_id], pc.data_folder_name)
        os.makedirs (data_folder)

        for p_size in pc.payload_size [e_id]:

            for t_period in pc.task_period:

                #  Compute the destination path of the experiment of
                #  type e_id and payload size p_size
                dest = os.path.join\
                    (pc.path_to_exp [e_id],
                     "Exp_Size_" + str (p_size) + "_Period_" + str (t_period),
                     pc.src_folder_name)

                #  Copy the Ada sources into dest
                shutil.copytree (pc.path_to_src, dest)

                #  Change the payload size and the workload type
                config_file      = "experiment_parameters.ads"
                config_file_path = os.path.join (dest, "src", config_file)

                file  = open (config_file_path, 'r')
                lines = file.readlines ()
                lines [10] = "   Payload_Size    : Positive := " + str (p_size) + ";\n"
                lines [11] = "   Workload_Type   : Positive := " + str (pc.experiment_workload [e_id]) + ";\n"
                lines [14] = "   Task_Period         : Positive := " + str (t_period) + ";\n"
                file.close ()

                file  = open (config_file_path, 'w')
                file.writelines (lines)
                file.close ()

                #  Compile the experiment
                project_file_path_ch = os.path.join (dest, pc.project_file)
                os.system ("gprbuild -P " + project_file_path_ch)
