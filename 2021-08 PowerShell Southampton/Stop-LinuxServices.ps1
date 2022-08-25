import os
import socket

params = str(sys.argv[1])
# create array of services
servicesList = params.split(";")

for serviceName in servicesList:
	# Stop the service
	run = os.system('sudo service ' + serviceName + ' stop > /dev/null')
	time.sleep(1)
	# Get the status of the service
	output = commands.getstatusoutput('sudo service ' + serviceName + ' status')
	print(output)