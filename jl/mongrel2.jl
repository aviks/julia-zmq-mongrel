load("jl/zmq.jl")
load("jl/json.jl")

type M2Request
	sender_id
	connection_id
	path
	headers
	body
	json_data

	function M2Request(s,c,p,h,b) 
		if get(h, "METHOD", "") == "JSON"
			new(s,c,p,h,b,parse_json(b))
		else
			new(s,c,p,h,b,HashTable())
		end
	end
end

type M2Connection
	ctx::ZMQ_Context
	reqs::ZMQ_Socket
	resp::ZMQ_Socket
	sub_addr::String
	pub_addr::String

end

function m2_parse_netstring (str::String)
	 i = strchr(str, ':')
	 s = str[i+1:end]
	 len = int(str[1:i-1])
	 if s[len+1] != ','; error ("Netstring does not end with comma : $str"); end
	 if len==0
	 	return "", ""
	 else 
		return s[1:len], s[len+2:end]
	end
end

function m2_parse_request(msg::String)
	#Uncomment for debug: print ("Recd message: $msg \n\n")
	flush(stdout_stream)
	r = split(msg, ' ')
	sender = r[1]
	connection_id = r[2]
	path = r[3]
	rest = r[4]
	if length(r) > 4
		re
		for i = r[5:end]
			rest = strcat(rest, " ", i)
		end
	end

	headers, head_rest = m2_parse_netstring(rest)

	(body, ) = m2_parse_netstring(head_rest)

	return M2Request(sender, connection_id, path, parse_json(headers), body)
end

function m2_is_disconnected(req::M2Request) 
	if get(req.headers, "METHOD", "") == "JSON"
		return get(req.json_data, "type", nothing) == "disconnect"
	else
		return false
	end

end

function m2_connect(sender_id::String, sub_addr::String, pub_addr::String)
	ctx = zmq_init(1)
	reqs = zmq_socket(ctx, ZMQ_UPSTREAM)
	zmq_connect(reqs, sub_addr)
	resp = zmq_socket(ctx, ZMQ_PUB)
	zmq_connect(resp, pub_addr)
	zmq_setsockopt(resp, ZMQ_IDENTITY, sender_id)
	return M2Connection(ctx, reqs, resp, sub_addr, pub_addr)
end

#internal function
function m2_send_resp(conn::M2Connection, uuid, conn_id, msg)
	str = "$uuid $(length(conn_id)):$(conn_id), $msg"
	zmq_send(conn.resp, str)
	#Uncomment for debug: print("Sent Reply : $str \n\n")
	flush(stdout_stream)
end

m2_recv(conn::M2Connection) = m2_parse_request(zmq_recv(conn.reqs))::M2Request

#This shouldnt be required  except for HTTP 1.0 clients, or websockets. 
#Normally, Let the browser manage keepalive. 
m2_disconnect_client(conn::M2Connection, req::M2Request) = m2_send_resp(conn, req.sender_id, req.connection_id, "")

m2_reply(conn::M2Connection, req::M2Request, msg::String) = m2_send_resp(conn, req.sender_id, req.connection_id, msg)
m2_reply_http (conn::M2Connection, req::M2Request, body, code, headers::HashTable{String, String}) = m2_reply(conn, req, _m2_http_response(body, code, headers))
m2_reply_http (conn::M2Connection, req::M2Request, body, headers) = m2_reply_http(conn, req, body, 200, headers)
m2_reply_http (conn::M2Connection, req::M2Request, body) = m2_reply_http(conn, req, body, 200, HashTable{String, String}())


function _m2_http_response(body, code, headers::HashTable{String, String})
	headers["Content-Length"] = string(length(body))
	headers_s = ""
	for (k, v) = headers
		headers_s = strcat(headers_s, "$(k): $(v)\r\n")
	end
	return "HTTP/1.1 $code $(StatusMessage[int(code)])\r\n$(headers_s)\r\n\r\n$(body)"
end

function m2_run_server(sender_id, sub_addr, pub_addr)
	conn = m2_connect(sender_id, sub_addr, pub_addr)

	function runner() 
		while true
			request = m2_recv(conn)
			produce((conn, request))
		end
	end
	print("Julia Mongrel2 hander started, connecting back on [$sub_addr] and [$pub_addr] \n")
	flush(stdout_stream)
	return Task(runner)
end

StatusMessage = HashTable{Int, String}()
StatusMessage[100] = "Continue"
StatusMessage[101] = "Switching Protocols"
StatusMessage[200] = "OK"
StatusMessage[201] = "Created"
StatusMessage[202] = "Accepted"
StatusMessage[203] = "Non-Authoritative Information"
StatusMessage[204] = "No Content"
StatusMessage[205] = "Reset Content"
StatusMessage[206] = "Partial Content"
StatusMessage[300] = "Multiple Choices"
StatusMessage[301] = "Moved Permanently"
StatusMessage[302] = "Found"
StatusMessage[303] = "See Other"
StatusMessage[304] = "Not Modified"
StatusMessage[305] = "Use Proxy"
StatusMessage[307] = "Temporary Redirect"
StatusMessage[400] = "Bad Request"
StatusMessage[401] = "Unauthorized"
StatusMessage[402] = "Payment Required"
StatusMessage[403] = "Forbidden"
StatusMessage[404] = "Not Found"
StatusMessage[405] = "Method Not Allowed"
StatusMessage[406] = "Not Acceptable"
StatusMessage[407] = "Proxy Authentication Required"
StatusMessage[408] = "Request Timeout"
StatusMessage[409] = "Conflict"
StatusMessage[410] = "Gone"
StatusMessage[411] = "Length Required"
StatusMessage[412] = "Precondition Failed"
StatusMessage[413] = "Request Entity Too Large"
StatusMessage[414] = "Request-URI Too Large"
StatusMessage[415] = "Unsupported Media Type"
StatusMessage[416] = "Request Range Not Satisfiable"
StatusMessage[417] = "Expectation Failed"
StatusMessage[500] = "Internal Server Error"
StatusMessage[501] = "Not Implemented"
StatusMessage[502] = "Bad Gateway"
StatusMessage[503] = "Service Unavailable"
StatusMessage[504] = "Gateway Timeout"
StatusMessage[505] = "HTTP Version Not Supported"
