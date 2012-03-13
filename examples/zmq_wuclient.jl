load ("jl/zmq.jl")

ctx = zmq_init(1)
subscriber = zmq_socket(ctx, ZMQ_SUB)
zmq_connect(subscriber, "tcp://localhost:5556")

flt = ARGS[2]

print ("Processing subscribtion for $flt \n")
zmq_setsockopt(subscriber, ZMQ_SUBSCRIBE, flt)

total_temp=0

for i=1:100  #Process 100 updates
	reply = zmq_recv (subscriber)
	splat = split(reply, " ")
	total_temp  = total_temp + int(splat[2])

	print ("Recieved update for $flt : $(int(splat[2])) \n")

end	

print ("Averate temperature for zipcode $flt was $(total_temp/100) \n")