#! /usr/bin/python3
# -*- coding: utf-8 -*-
"""
    Copyright (C) 2021-2022 e1z0 https://github.com/e1z0
    NBE Protocol reverse engineering and python adaptation - Copyright (C) 2013 Anders Nylund

    Redistribution and use in source and binary forms,
    with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the 
       above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors
       may be used to endorse or promote products derived from this software
       without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
      OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
      AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
      CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
      DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
      IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
      OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""

import time
import paho.mqtt.client as paho
import ha_classes
import subprocess
import json
import settings
import random
import csv
import os
import traceback
from protocol import Proxy
import logging

settings.init()
lock = 0

# Create logger
logger = logging.getLogger("pellet_burner")
level = settings.config.get("log_level", "INFO").upper()
logger.setLevel(getattr(logging, level, logging.INFO))

# Create console handler
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.DEBUG)  # You can adjust this independently

# Create formatter and attach to handler
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
console_handler.setFormatter(formatter)

# Attach handler to logger
logger.addHandler(console_handler)

#make device name and ident unique by adding the serialnumber of the device from settings, and using ha_device_name from settings as name if present
device = ha_classes.Device(
    "8caab44d999f" + "-" + settings.config['nbe_serial'],
    settings.config['ha_device_name'] if settings.config['ha_device_name'] else "nbe-blackstar",
    "NBE BlackStar+ IOT Controller v1.0",
    "NBE Blackstar+",
    "2022 (c) e1z0"
)
DataEntries = []

# read nbe schema file with declared device resources, group by specific device type and populate them in home assistant mqtt prefix topics
def populate_resources(client):
    curr_path = os.path.dirname(os.path.realpath(__file__))
    fp = open(curr_path+'/nbe_schema')
    csv_reader = csv.reader(fp)
    for row in csv_reader:
        if row[0][0] != '#':  # skip comments
           # Column order for sensor
           # RESOURCE,METHOD,TYPE,NAME,ICON,STATE-CLASS,DEVICE-CLASS,UNIT-OF-MEASUREMENT
           if row[1] == "get" and row[2] == "sensor":
              item = ha_classes.Sensor(row[4],row[6],row[7],row[5],row[3],device)
              DataEntries.append(ha_classes.Resource(item,row[2],row[0]))
           # Column order for climate control
           # RESOURCE,METHOD,TYPE,NAME,ICON,CURRENT-TEMP-TOPIC,MAX-TEMP
           if row[1] == "set" and row[2] == "climate":
              item = ha_classes.Climate(row[3],row[4],row[5],row[6],device)
              DataEntries.append(ha_classes.Resource(item,row[2],row[0]))
              client.subscribe(item.temperature_command_topic,0)
           # Column order for switch control
           # RESOURCE,METHOD,TYPE,NAME,ICON,... TO be continued...
           if row[1] == "set" and row[2] == "switch":
              item = ha_classes.Switch(row[4],row[3],device)
              DataEntries.Append(ha_classes.Resource(item,row[2],row[0]))
              client.subscribe(item.command_topic,0)
    # cycle for entries and add them to mqtt
    for row in DataEntries:
        logger.debug("Publishing: "+row.getHaTopic())
        client.publish(row.getHaTopic(),row.component.toJSON(),0,True)

def nbe_query():
    logger.info("Making query to the pellet burner...")
    items = {}
    if lock == 1:
       logger.warning("Query collision, lock already set, skipping...")
       return items
    try:
       with Proxy(settings.config["nbe_pass"], settings.config["nbe_port"], settings.config["nbe_ip"], settings.config["nbe_serial"]) as proxy:
            for query in [ "operating_data", "settings/boiler", "consumption_data/counter" ]:
               response = proxy.get(query)
               logger.debug("Query: " + query)
               logger.debug("Response:\n\n" + str(response))
               for item in response:
                  val = item.split("=",1)
                  items[val[0]] = val[1]
    except Exception as e:
      logger.error("Unable to query NBE:")
      logger.error(f"Error type: {type(e).__name__}")
      logger.error(f"Error message: {e}")
      traceback.print_exc()
    return items

def nbe_update(command,value):
    lock = 1
    try:
        with Proxy(settings.config["nbe_pass"], settings.config["nbe_port"], settings.config["nbe_ip"], settings.config["nbe_serial"]) as proxy:
           res = proxy.set(command,value)
           logger.debug("NBE SET DEBUG RETURN: " + str(res))
           if str(res) == "('OK',)":
              return True
    except Exception as e:
      logger.error("Unable to send update to NBE Controller:")
      logger.error(f"Error type: {type(e).__name__}")
      logger.error(f"Error message: {e}")
      traceback.print_exc()
    lock = 0
    return False

def search_query(data,search):
    for Key,Value in data.items():
       if Key == search:
             return Key,Value
    return "none","none"

# refresh device's resources => values
def refresh_statuses(client):
    # make one big query to nbe to get all possible data
    raw_data = nbe_query()
    # parse and update only required data
    for row in DataEntries:
        if row.type == "climate":
           key,val = search_query(raw_data,row.resource)
           if key != "none" and val != "none":
              logger.debug("climate: "+row.component.temperature_state_topic+" with value: "+str(val))
              client.publish(row.component.temperature_state_topic,val,0,True)
        if row.type == "sensor":
           key,val = search_query(raw_data,row.resource)
           if key != "none" and val != "none":
              logger.debug("sensor: "+row.component.state_topic+" with value: "+str(val))
              client.publish(row.component.state_topic,val,0,True)

# mqtt callback when connection success
def on_connect(client, userdata, flags, rc):
    if rc==0:
        client.connected_flag=True
        logger.info("connected OK")
        # set availability when connected
        client.publish(device.getUid()+"/bridge/state","online",0,True)
        # a hacky trick to always show auto on thermostats (for now, just for eyes to be happy)
        client.publish(device.getUid()+"/bridge/static_auto_state","auto",0,True)
        # populate device resources
        populate_resources(client)
    else:
        logger.error("Bad connection Returned code=" + str(rc))
        client.bad_connection_flag=True


# mqtt callback for subscribed topics
def on_message(client, userdata, message):
    data = str(message.payload,'utf-8')
    logger.debug("got message payload: " + data)
    for row in DataEntries:
        if row.type == "climate" and message.topic == row.getTempCommandTopic():
           logger.debug("Climate command triggered: "+ row.resource + " set data to: "+data)
           stat = nbe_update(row.resource,data)
           if stat == True:
              client.publish(row.getTempStateTopic(),data,0,True)
        if row.type == "switch" and message.topic == row.getCommandTopic():
           logger.debug("Triggered topic: "+ row.getCommandTopic())
           # DO SOME WORK WIT TEH DEV
           # set the status to the requested one
           client.publish(row.getStateTopic(),data,0,True)

# main function
def start():
    # connection
    logger.info("Started up!")
    paho.Client.connected_flag=False
    paho.Client.bad_connection_flag=False
    client= paho.Client()
    client.username_pw_set(settings.config["mqtt_user"],settings.config["mqtt_pass"])
    client.on_connect=on_connect   #bind connect call back function
    client.on_message=on_message    #attach function to callback for subscriptions on the topics
    logger.info("Connecting to broker " + settings.config["mqtt_server"])
    client.connect(settings.config["mqtt_server"],settings.config["mqtt_port"])	#establish connection
    client.loop_start() #start network loop
    while not client.connected_flag and not client.bad_connection_flag: #wait in loop
        time.sleep(0.1)
    if client.bad_connection_flag:
        client.loop_stop()    #Stop loop
        sys.exit()
    #the main loop starts here
    while True:
        try:
            # refresh device's resources to assigned topics
            refresh_statuses(client)
            logger.info("still running")
            time.sleep(settings.config["refresh_rate"])
        except KeyboardInterrupt:
            logger.error("Received kill signal, stopping the processes...")
            # set availability to offline
            client.publish(device.getUid()+"/bridge/state","offline",0,True)
            client.publish(device.getUid()+"/bridge/static_auto_state","off",0,True)
            client.loop_stop()
            client.disconnect()
            client.connected_flag=False
            logger.info("Ending program")
            exit()

start()
