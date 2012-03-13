load ("jl/zmq.jl")

ctx = zmq_init(1)
publisher = zmq_socket(ctx, ZMQ_PUB)
zmq_bind(publisher, "tcp://*:5556")
zmq_bind (publisher, "ipc://weather.ipc")

while true
	zipcode = int(rand(1) * 100000) [1]
	temperature = int(rand(1) * 215 - 80) [1]
	relhumidity = int(rand(1) * 50 +10) [1]
	update = "$zipcode $temperature $relhumidity"
	zmq_send(publisher, update)
end

zmq_close(publisher)
zmq_term(context)