import shutil
import os
import serial
import re
import matplotlib.pyplot as plt

"""
    WORKING DIRECTORY ORGANIZATION:
        Providing-Spatial-Isolation
        |- Providing-Spatial-Isolation-Experiment
        |- Experiments
        |  |- Experiment_1
        |  |  |_ Providing-Spatial-Isolation-Experiment
        |  |  \_ Results
        |  |     |- Allocation.txt
        |  |     |- Send.txt
        |  |     |- Receive.txt
        |  |     \_ Free.txt
        |  |- Experiment_2
        |  |- . . . 
        |  \_ Experiment_n
        \_ script.py
"""


def clearExperimentsDirectory(experiments_number):
    # Location
    location = os.getcwd()

    # Directory
    dir_folder = "Experiments"
    dir_prefix = "Experiment_"

    # Remove the content of all Experiments folder
    for i in range(experiments_number):
        # Path
        path = os.path.join(location, dir_folder, dir_prefix + str(i))

        # Removing folder
        shutil.rmtree(path, ignore_errors=True)


def clearGraphDirectory():
    # Location
    location = os.getcwd()

    path = os.path.join(location, "Graphs")
    shutil.rmtree(path, ignore_errors=True)
    os.mkdir(path)


def populateExperimentsDirectory(payload_size):
    # Number of the experiments
    experiments_number = len(payload_size)
    # Location
    location = os.getcwd()

    # Directories
    src_folder = "Providing-Spatial-Isolation-Experiment"
    dest_folder = "Experiments"
    dest_prefix = "Experiment_"

    for i in range(experiments_number):
        # Path
        src_path = os.path.join(location, src_folder)
        dest_path = os.path.join(location, dest_folder, dest_prefix + str(i), src_folder)

        # Duplicate directory
        shutil.copytree(src_path, dest_path)

        # Change the payload size
        spec_file_path = "src/experiment_parameters.ads"
        file_path = os.path.join(dest_path, spec_file_path)
        file = open(file_path, 'r')
        lines = file.readlines()
        lines[10] = "   Payload_Size    : Positive := " + str(payload_size[i]) + ";\n"
        file.close()
        file = open(file_path, 'w')
        file.writelines(lines)
        file.close()

        # Recompile each experiment
        project_file_path = os.path.join(dest_path, "providing_spatial_isolation_experiment.gpr")
        os.system("gprbuild -P " + project_file_path)


def performTheExperiments(payload_size):
    # Parameters for the serial connection
    experiments_number = len(payload_size)
    port = '/dev/ttyUSB1'
    boundrate = 115200

    # Path to the current experiment folder
    location = os.getcwd()
    dir_folder = "Experiments"
    dir_prefix = "Experiment_"

    # Open the serial connection to the UART interface of the unit
    uart_interface = serial.Serial(port, boundrate, timeout=None)

    # Experiments execution
    for i in range(experiments_number):
        # Initialize as empty the arrays for the measured metrics
        alloc_array = []
        send_array = []
        receive_array = []
        free_array = []

        # Create a folder for results
        path_to_current_experiment_folder = os.path.join(location, dir_folder, dir_prefix + str(i))
        path_of_result_folder = os.path.join(path_to_current_experiment_folder, "Results")
        os.mkdir(path_of_result_folder)

        # Clear the serial input buffer
        uart_interface.flushInput()
        is_eof_reached = False

        # Instantiate an intermediate buffer
        buffer = ""

        # Flash the application
        path_to_experiment = os.path.join(path_to_current_experiment_folder, "Providing-Spatial-Isolation-Experiment")
        os.chdir(path_to_experiment)
        os.system("xsdb cora_xsdb.ini")
        os.chdir(location)

        # Acquire the output of the application
        # inside the intermediate buffer
        while not is_eof_reached:
            if uart_interface.in_waiting > 0:
                input_byte = uart_interface.read()
                input_string = input_byte.decode()
                buffer += input_string

                # Check if the eof tag has been reached
                if buffer.find("<eof_tag/>") != -1:
                    is_eof_reached = True

        # Here the entire application output is inside the
        # intermediate buffer, which needs to be accessed
        # line by line
        input_lines = buffer.split('\n')

        for line in input_lines:

            # Process the input line
            metrics_tag = ["alloc", "send", "receive", "free"]
            for tag in metrics_tag:
                start = "<" + tag + ">"
                end = "</" + tag + ">"
                measured_time = re.search(
                    re.escape(start) + "(.*)" + re.escape(end), line)
                if measured_time is None:
                    # Then we have reach the eof tag
                    # we can break the inner for loop
                    break
                else:
                    measured_time = measured_time.group(1)
                    if tag == "alloc":
                        alloc_array.append(measured_time)
                    elif tag == "send":
                        send_array.append(measured_time)
                    elif tag == "receive":
                        receive_array.append(measured_time)
                    elif tag == "free":
                        free_array.append(measured_time)
                    else:
                        print("Unexpected tag acquired\n")

        # Write the results in the proper file, one line per measure

        # Allocation file
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
        free_file = open(path_of_result_folder + "/free.txt", 'w')
        for value in free_array:
            free_file.write(value + "\n")
        free_file.close()

    # Close the connection
    uart_interface.close()


def produceTheGraphs(payload_size):
    graph_title = ["Allocation times", "Free times", "Receive times", "Send times"]
    graph_name = ["allocation.jpeg", "free.jpeg", "receive.jpeg", "send.jpeg"]
    results_file = ["allocation.txt", "free.txt", "receive.txt", "send.txt"]
    experiments_number = len(payload_size)
    graphs_number = len(graph_title)

    # Path to the current experiment folder
    location = os.getcwd()
    dir_folder = "Experiments"
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
                # data_string.replace("\x00", "")
                if i == 2:
                    print(data_string)
                data_to_plot[number].append(float(data_string))

        # Graph drawings
        plt.clf()
        plt.boxplot(data_to_plot)
        plt.xlabel("Size of the message payload (bytes)")
        plt.xticks(x_values, x_label)
        plt.ylabel("Measured execution time (seconds)")
        plt.title(graph_title[i])
        plt.savefig("Graphs/" + graph_name[i])


def runTheExperiments():
    # Payload size contains the values of the length of the
    # message payload for each experiment
    payload_size = [10, 100]
    experiments_number = len(payload_size)

    # Remove previous experiments, if any
    clearExperimentsDirectory(experiments_number)

    # Build the experiments
    populateExperimentsDirectory(payload_size)

    # Clear the Graphs folder
    clearGraphDirectory()

    # Execute the experiments
    performTheExperiments(payload_size)

    # Produce the graphs
    produceTheGraphs(payload_size)


if __name__ == '__main__':
    # print('PyCharm')
    runTheExperiments()
