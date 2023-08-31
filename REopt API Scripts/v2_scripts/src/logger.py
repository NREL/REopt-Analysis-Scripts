"""
Custom logging set up, with handlers for writing to .log file and console.

The _handler.setLevel determines the logging level to write to file or console.
Logging levels are:

Level	Numeric value
CRITICAL	50
ERROR	    40
WARNING	    30
INFO	    20
DEBUG	    10
NOTSET	    0
"""
import logging

log = logging.getLogger('main')
log.setLevel(logging.DEBUG)

file_handler = logging.FileHandler(filename='main.log', mode='w')
file_formatter = logging.Formatter('%(asctime)s %(name)-12s %(levelname)-8s %(message)s')
file_handler.setFormatter(file_formatter)
file_handler.setLevel(logging.INFO)

console_handler = logging.StreamHandler()
console_formatter = logging.Formatter('%(name)-12s %(levelname)-8s %(message)s')
console_handler.setFormatter(console_formatter)
console_handler.setLevel(logging.INFO)

log.addHandler(file_handler)
log.addHandler(console_handler)
