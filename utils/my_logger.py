'''
    File name      : my_logger.py
    Author         : Jinwook Jung
    Created on     : Sat Aug 12 12:26:52 2017
    Last modified  : 2017-08-12 12:35:53
    Description    : 
'''

import logging
import logging.handlers

class Logger:
    def get_logger(name, filename=None):
        logger = logging.getLogger(name)

        # Set log format
        # formatter = logging.Formatter('%(asctime)s:%(filename)s:%(lineno)-4s %(levelname)-8s %(message)s', "%Y-%m-%d %H:%M:%S")
        formatter = logging.Formatter('%(filename)s:%(lineno)-4s %(levelname)-8s %(message)s')
        # Create stream handler
        stream_handler = logging.StreamHandler()
        stream_handler.setFormatter(formatter)
        logger.addHandler(stream_handler)

        # Create file handler
        if filename is not None:
            file_handler = logging.FileHandler('./{}.log'.format(logger.name))
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)

        return logger
