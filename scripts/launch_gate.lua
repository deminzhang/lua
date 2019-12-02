--os.info.listen = '*:port'

assert(os.info.system=='linux','net:share unsupported in '..os.info.system)

if not os.info.subgate then --main gate listen
	local random = math.random
	local onListen = function(net, listener, ip, port, myip, myport, share)
		print('>>gate.onListen',net, ip, port)
		local pipe = "gate"..random( os.info.gaten )
		net:share(pipe, '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0')
		net:close('share to'..pipe)
	end
	--Net.listen( "0.0.0.0:80" )
	Net.listen( os.info.listen, onListen )
	
	--launch subgate
	for i = 1, os.info.gaten do
		os.launch( ".", "subgate=gate"..i )
	end
else --sub gate listen
	Net.listen(os.info.listen.."@"..os.info.subgate)
end

