import os
import serial
import paths_and_constants as pc

"""
    FUNCTION USED FOR EXECUTING THE EXPERIMENTS
"""


def performTheExperiments ():
    # Parameters for the serial connection
    port      = '/dev/ttyUSB1'
    boundrate = 115200

    for e_id in pc.experiment_id:

        for p_size in pc.payload_size [e_id]:

            for t_period in pc.task_period:

                #  The output of the experiment is written in a file
                result_file_name     =\
                    str (p_size) + "_" + str (t_period) + "_results.txt"
                path_to_results_file = os.path.join\
                    (pc.path_to_exp [e_id], "Results", result_file_name)

                #  Open the serial connection to the UART interface of the unit
                uart_interface = serial.Serial (port, boundrate, timeout=0.1)

                # Clear the serial input buffer
                uart_interface.flushInput ()

                #  Flash the application
                path_to_app = os.path.join\
                    (pc.path_to_exp [e_id],
                     "Exp_Size_" + str (p_size) + "_Period_" + str (t_period),
                     pc.src_folder_name)
                os.chdir (path_to_app)
                os.system ("xsdb cora_xsdb.ini")
                os.chdir (pc.working_directory)

                #  Acquire the input from the application
                input_lines = []
                acquired_lines = 0
                while acquired_lines < pc.number_of_samples:
                    input_bytes = uart_interface.readline ()

                    if input_bytes.endswith (b'\n') :
                        # TODO perform more tests on the input bytes
                        # 'utf-8' codec can't decode byte 0xfe in position 22: invalid start byte
                        input_lines.append (input_bytes.decode ())
                        acquired_lines += 1

                #  Write the input int the result file
                result_file = open (path_to_results_file, 'w')
                for line in input_lines:
                    result_file.write (line + "\n")
                result_file.close ()

                #  Close the UART connection
                uart_interface.close()
