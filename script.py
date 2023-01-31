import shutil
import os
import serial
import re
import matplotlib.pyplot as plt
import statistics

"""
    WORKING DIRECTORY ORGANIZATION:
        Providing-Spatial-Isolation
        |- Providing-Spatial-Isolation-Experiment
        |- Graphs
        |- Experiments
        |  |- Experiments_ch
        |  |  |- Experiment_1
        |  |  |  |_ Providing-Spatial-Isolation-Experiment
        |  |  |  \_ Results
        |  |  |     |- Allocation.txt
        |  |  |     |- Send.txt
        |  |  |     |- Receive.txt
        |  |  |     \_ Free.txt
        |  |  |- Experiment_2
        |  |  |- . . . 
        |  |  \_ Experiment_n
        |  \_ Experiments_po
        |     |- Experiment_1
        |     |- . . . 
        |     \_ Experiment_n
        \_ script.py
"""


# Constants
location = os.getcwd()
path_to_experiment = os.path.join(location, "Experiments")
path_to_graphs = os.path.join(location, "Graphs")
path_to_src = os.path.join(location, "Providing-Spatial-Isolation-Experiment")
path_to_exper_ch = os.path.join(path_to_experiment, "Experiments_ch")
path_to_exper_po = os.path.join(path_to_experiment, "Experiments_po")


def clearExperimentsDirectory():
    shutil.rmtree(path_to_experiment, ignore_errors=True)
    os.mkdir(path_to_experiment)


def clearGraphDirectory():
    shutil.rmtree(path_to_graphs, ignore_errors=True)
    os.mkdir(path_to_graphs)


def populateExperimentsDirectory(payload_size):
    # Number of the experiments
    experiments_number = len(payload_size)

    # Directories
    src_folder = "Providing-Spatial-Isolation-Experiment"
    dest_prefix = "Experiment_"

    for i in range(experiments_number):
        # For each experiment we generate the executables for the
        # version with channel (ch) and the version with protected
        # object (po)

        # Path
        dest_path_ch = os.path.join(path_to_exper_ch, dest_prefix + str(i), src_folder)
        dest_path_po = os.path.join(path_to_exper_po, dest_prefix + str(i), src_folder)

        # Duplicate directory
        shutil.copytree(path_to_src, dest_path_ch)
        shutil.copytree(path_to_src, dest_path_po)

        # Change the payload size for the experiment with channels
        spec_file_path = "src/experiment_parameters.ads"
        file_path = os.path.join(dest_path_ch, spec_file_path)
        file = open(file_path, 'r')
        lines = file.readlines()
        lines[10] = "   Payload_Size    : Positive := " + str(payload_size[i]) + ";\n"
        lines[13] = "   Workload_Type   : Positive := 1;\n"
        file.close()
        file = open(file_path, 'w')
        file.writelines(lines)
        file.close()

        # Change the payload size for the experiment with protected objects
        spec_file_path = "src/experiment_parameters.ads"
        file_path = os.path.join(dest_path_po, spec_file_path)
        file = open(file_path, 'r')
        lines = file.readlines()
        lines[10] = "   Payload_Size    : Positive := " + str(payload_size[i]) + ";\n"
        lines[13] = "   Workload_Type   : Positive := 2;\n"
        file.close()
        file = open(file_path, 'w')
        file.writelines(lines)
        file.close()

        # Recompile each experiment
        project_file_path_ch = os.path.join(dest_path_ch, "providing_spatial_isolation_experiment.gpr")
        os.system("gprbuild -P " + project_file_path_ch)
        project_file_path_po = os.path.join(dest_path_po, "providing_spatial_isolation_experiment.gpr")
        os.system("gprbuild -P " + project_file_path_po)


def performWorkloadExperiment(payload_size, workload_type):
    # Parameters for the serial connection
    experiments_number = len(payload_size)
    port = '/dev/ttyUSB1'
    boundrate = 115200

    # Path to the current experiment folder
    experiments_folder = ["Experiments/Experiments_ch", "Experiments/Experiments_po"]
    if workload_type == 1:
        dir_folder = experiments_folder[0]
    elif workload_type == 2:
        dir_folder = experiments_folder[1]
    else:
        dir_folder = "Nonexistent_Folder"
    dir_prefix = "Experiment_"

    # Experiments execution
    for i in range(experiments_number):
        # Open the serial connection to the UART interface of the unit
        uart_interface = serial.Serial(port, boundrate, timeout=(40/1000))

        # Initialize as empty the arrays for the measured metrics
        alloc_array = []
        init_array = []
        send_array = []
        receive_array = []
        free_array = []

        # Create a folder for results
        path_to_current_experiment_folder = os.path.join(location, dir_folder, dir_prefix + str(i))
        path_of_result_folder = os.path.join(path_to_current_experiment_folder, "Results")
        os.mkdir(path_of_result_folder)

        # Clear the serial input buffer
        uart_interface.flushInput()

        # Flash the application
        path_to_application = os.path.join(path_to_current_experiment_folder, "Providing-Spatial-Isolation-Experiment")
        os.chdir(path_to_application)
        os.system("xsdb cora_xsdb.ini")
        os.chdir(location)

        buffer = uart_interface.readlines()

        # Here the entire application output is inside the
        # intermediate buffer, which needs to be accessed
        # line by line

        # Decode the buffer
        size_limit = 0
        if workload_type == 1:
            size_limit = 110
        else:
            size_limit = 83

        input_lines = []
        for j in range(len(buffer)):
            buffer_string = buffer[j]

            # We preserve only the line entirely parsed
            if len(buffer_string) != size_limit:
                print(len(buffer_string))
                print(buffer_string)
                continue
            input_lines.append(buffer[j].decode("utf-8"))

        for line in input_lines:

            # Process the input line
            metrics_tag = ["eof_tag", "alloc", "send", "receive", "free", "init"]
            for tag in metrics_tag:
                start = "<" + tag + "> "
                end = "</" + tag + ">"
                measured_time = re.search(
                    re.escape(start) + "(.*)" + re.escape(end), line)
                if measured_time is None:
                    pass
                else:
                    measured_time = measured_time.group(1)
                    if tag == "eof_tag":
                        # Then we have reach the eof tag
                        # we can break the inner for loop
                        break
                    if tag == "alloc":
                        alloc_array.append(measured_time)
                    elif tag == "send":
                        send_array.append(measured_time)
                    elif tag == "receive":
                        receive_array.append(measured_time)
                    elif tag == "free":
                        free_array.append(measured_time)
                    elif tag == "init":
                        init_array.append(measured_time)
                    else:
                        print("Unexpected tag acquired\n")

        # Write the results in the proper file, one line per measure

        # Allocation file
        if len(alloc_array) > 0:
            alloc_file = open(path_of_result_folder + "/allocation.txt", 'w')
            for value in alloc_array:
                alloc_file.write(value + "\n")
            alloc_file.close()

        # Send file
        send_file = open(path_of_result_folder + "/send.txt", 'w')
        for value in send_array:
            send_file.write(value + "\n")
        send_file.close()

        # Receive file
        receive_file = open(path_of_result_folder + "/receive.txt", 'w')
        for value in receive_array:
            receive_file.write(value + "\n")
        receive_file.close()

        # Free file
        if len(free_array) > 0:
            free_file = open(path_of_result_folder + "/free.txt", 'w')
            for value in free_array:
                free_file.write(value + "\n")
            free_file.close()

        # Init file
        if len(init_array) > 0:
            init_file = open(path_of_result_folder + "/init.txt", 'w')
            for value in init_array:
                init_file.write(value + "\n")
            init_file.close()

        # Close the connection
        uart_interface.close()


def performTheExperiments(payload_size):
    # Perform the experiments for the version
    # with channels and that with protected objects
    performWorkloadExperiment(payload_size, 1)
    performWorkloadExperiment(payload_size, 2)


def produceTheGraphs(payload_size):
    graph_title = ["Allocation times", "Free times", "Receive times", "Send times"]
    graph_name = ["allocation.jpeg", "free.jpeg", "receive.jpeg", "send.jpeg"]
    results_file = ["allocation.txt", "free.txt", "receive.txt", "send.txt"]
    experiments_number = len(payload_size)
    graphs_number = len(graph_title)

    # Path to the current experiment folder
    dir_folder = "Experiments/Experiments_ch"
    dir_prefix = "Experiment_"

    # Graph labels
    x_values = [*range(0, experiments_number + 1, 1)]
    x_label = [""]
    for size in payload_size:
        x_label.append(str(size))

    # Produce a graph for each metric
    for i in range(graphs_number):
        data_to_plot = []
        for number in range(experiments_number):
            data_to_plot.append([])

            # Read data from file
            path_to_result_file = os.path.join\
                (location, dir_folder, dir_prefix + str(number), "Results", results_file[i])
            with open(path_to_result_file, 'r') as file:
                data_as_array_of_string = file.readlines()

            # Turn the data string into float and populate
            # the data_to_plot array
            for data_string in data_as_array_of_string:
                data_string = data_string.replace("\x00", "").replace("\n", "")
                data_to_plot[number].append(float(data_string))

        # Graph drawings
        plt.clf()
        plt.boxplot(data_to_plot)
        plt.xlabel("Size of the message payload (bytes)")
        plt.xticks(x_values, x_label)
        plt.ylabel("Measured execution time (seconds)")
        plt.title(graph_title[i])
        plt.savefig("Graphs/" + graph_name[i])


def produceTheComparisonGraphs(payload_size):

    results_file_ch = ["allocation.txt", "free.txt", "receive.txt", "send.txt"]
    results_file_po = ["init.txt", "receive.txt", "send.txt"]
    experiments_number = len(payload_size)

    median_alloc_array = []
    median_free_array = []
    median_send_ch_array = []
    median_receive_ch_array = []
    median_overall_ch = [0] * experiments_number
    median_init_array = []
    median_send_po_array = []
    median_receive_po_array = []
    median_overall_po = [0] * experiments_number

    # Populate arrays
    for exp_num in range(experiments_number):

        # Experiment with channels
        for res in results_file_ch:

            # Read the results file
            path_to_result_file = os.path.join \
                (path_to_exper_ch, "Experiment_" + str(exp_num), "Results", res)
            with open(path_to_result_file, 'r') as file:
                data_as_array_of_string = file.readlines()

            # Produce an array of the measured data
            values_array = []
            for data_string in data_as_array_of_string:
                data_string = data_string.replace("\x00", "").replace("\n", "")
                values_array.append(float(data_string))

            # Finally compute the median and update the respective array
            median_of_input_data = statistics.median(values_array)
            # Convert in milliseconds
            median_of_input_data = median_of_input_data * 1000
            median_overall_ch[exp_num] += median_of_input_data
            if res == results_file_ch[0]:
                median_alloc_array.append(median_of_input_data)
            elif res == results_file_ch[1]:
                median_free_array.append(median_of_input_data)
            elif res == results_file_ch[2]:
                median_receive_ch_array.append(median_of_input_data)
            elif res == results_file_ch[3]:
                median_send_ch_array.append(median_of_input_data)
            else:
                print("Unexpected error while computing the median - ch")

        # Experiment with protected objects
        for res in results_file_po:

            # Read the results file
            path_to_result_file = os.path.join \
                (path_to_exper_po, "Experiment_" + str(exp_num), "Results", res)
            with open(path_to_result_file, 'r') as file:
                data_as_array_of_string = file.readlines()

            # Produce an array of the measured data
            values_array = []
            for data_string in data_as_array_of_string:
                data_string = data_string.replace("\x00", "").replace("\n", "")
                values_array.append(float(data_string))

            # Finally compute the median and update the respective array
            median_of_input_data = statistics.median(values_array)
            # Convert in milliseconds
            median_of_input_data = median_of_input_data * 1000
            median_overall_po[exp_num] += median_of_input_data
            if res == results_file_po[0]:
                median_overall_po[exp_num] -= median_of_input_data
                median_init_array.append(median_of_input_data)
            elif res == results_file_po[1]:
                median_receive_po_array.append(median_of_input_data)
            elif res == results_file_po[2]:
                median_send_po_array.append(median_of_input_data)
            else:
                print("Unexpected error while computing the median - po")

    # Produce the graphs
    plt.clf()

    # Graph labels
    # x_values = [*range(0, experiments_number, 1)]
    x_values = payload_size
    # Convert x_values in kbytes
    for x_v in range(len(x_values)):
        x_values[x_v] = x_values[x_v] * 32 / 1000

    x_label = [""]
    for size in payload_size:
        x_label.append(str(size))
    plt.xlabel("Size of the message payload (kbytes)")
    plt.ylabel("Median of measured execution times (ms)")
    plt.title("Channels (ch) vs cross-criticality protected objects (po)")

    plt.plot(x_values, median_alloc_array, 'xkcd:light blue', label="Ch - Allocation")
    plt.plot(x_values, median_free_array, 'xkcd:blue', label="Ch - Free")
    plt.plot(x_values, median_send_ch_array, 'xkcd:cyan', label="Ch - Send")
    plt.plot(x_values, median_receive_ch_array, 'xkcd:pale blue', label="Ch - Receive")
    plt.plot(x_values, median_overall_ch, 'xkcd:royal blue', label="Ch - Overall")
    # plt.plot(x_values, median_init_array, 'xkcd:salmon', label="Po - Initialization")
    plt.plot(x_values, median_send_po_array, 'xkcd:light red', label="Po - Send")
    plt.plot(x_values, median_receive_po_array, 'xkcd:pinkish red', label="Po - Receive")
    plt.plot(x_values, median_overall_po, 'xkcd:red', label="Po - Overall")
    plt.legend()
    plt.savefig("Graphs/" + "ch_vs_po.jpeg")


def runTheExperiments():
    # Payload size contains the values of the length of the
    # message payload for each experiment

    payload_size = [1, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500]

    # Remove previous experiments, if any
    clearExperimentsDirectory()

    # Build the experiments
    populateExperimentsDirectory(payload_size)

    # Clear the Graphs folder
    clearGraphDirectory()

    # Execute the experiments
    performTheExperiments(payload_size)

    # Produce the graphs
    produceTheGraphs(payload_size)

    # Produce the comparison graph
    produceTheComparisonGraphs(payload_size)


if __name__ == '__main__':
    # print('PyCharm')
    runTheExperiments()
