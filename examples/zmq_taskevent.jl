load ("jl/zmq.jl")

ctx = zmq_init(1)
sender = zmq_socket(ctx, ZMQ_PUSH)
zmq_bind(sender, "tcp://*:5557")

sink = zmq_socket(ctx, ZMQ_PUSH);
zmq_connect(sink, "tcp://localhost:5558")

print (" Press Enter when the workers are ready \n")
readline(stdin_stream)

#First message is "0" and signals start of batch
zmq_send(sink, "0") 

total_msec = 0
for i=1:100
	global total_msec
	workload = randi(100)+1
	zmq_send(sender, string(workload))

	total_msec = total_msec + workload
end

print ("Total expected cost: $total_msec msec\n")
sleep(1)  #Give 0MQ time to deliver

zmq_close(sender)
zmq_close(sink)
zmq_term(ctx)