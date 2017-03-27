--[[ *********************************************************
MAIN.lua
Programa principal. Coloque aqui o c�digo.
********************************************************* ]]--

print("MAIN: Programa principal iniciado.")

_MAX_TENTATIVAS_IP = 5

_server2 = nil

_funcao2 = 1
_tenta2 = 1
_timer2 = tmr.create()
_timer2:alarm(1000, tmr.ALARM_SEMI, function() start_webserver() end)

_hostname = "ESP_" .. node.chipid()
print("MAIN: Definindo nome do dispositivo na rede como " .. _hostname .. ".")
wifi.sta.sethostname(_hostname)

function start_webserver()

	if (_funcao2 == 1) then
		print("MAIN: Detectando IP e intensidade do sinal. Aguarde.")
		local _ip = wifi.sta.getip()
		local _rssi = wifi.sta.getrssi()

		if (_ip ~= nil) then
			print("MAIN: Conectado no wifi com o ip " .. _ip .. " e intensidade do sinal " .. _rssi .. ".")
			_tenta2 = 1
			_funcao2 = _funcao2 + 1

		else
			print("MAIN: Falhou na " .. _tenta2 .. "� tentativa. Aguarde 1 segundo.")
			_tenta2 = _tenta2 + 1
			if (_tenta2 >= _MAX_TENTATIVAS_IP) then
				print("MAIN: Falhou demais, mas vamos continuar assim mesmo.")
				_tenta2 = 1
				_funcao2 = _funcao2 + 1

			end
		end
		_timer2:start()


	elseif (_funcao2 == 2) then
		print("MAIN: Iniciando webserver.")

		if (_server2 == nil) then
			_server2 = net.createServer(net.TCP, 60)
		end

		_server2:listen(80, listen2)

		_timer2:unregister()
	end

end


function listen2(sck)
	print("MAIN: Webserver inicializado. Registrando callbacks.")
    sck:on("receive", receive2)
	sck:on("connection", connection2)
	sck:on("disconnection", disconnection2)
end

function connection2(sck, req)
	local _port, _ip = sck:getpeer()
	if (_ip ~= nil) then
		print("MAIN: Cliente " .. _ip .. " conectado (+) no webserver pela porta " .. _port .. ".")
	end
end

function disconnection2(sck, req)
	local _port, _ip = sck:getpeer()
	if (_ip ~= nil) then
		print("MAIN: Cliente " .. _ip .. " desconectado (-) do webserver.")
	end
end

function receive2(sck, req)
	local _port, _ip = sck:getpeer()
	if (_ip ~= nil) then
		print("MAIN: Cliente " .. _ip .. " enviando dados para o webserver.")
	end

    local ht = {}
    table.insert(ht, "<html>")
    table.insert(ht, "<head><title>Titulo</title></head>")
    table.insert(ht, "<body>")

	table.insert(ht, "<p>Corpo da p�gina</p>")

    table.insert(ht, "</body>")
    table.insert(ht, "</html>")

	local sht = 0
    for key, value in pairs(ht) do
        sht = sht + string.len(value) + 1
    end

    table.insert(ht, 1, "HTTP/1.0 200 OK")
    table.insert(ht, 2, "Server: " .. _hostname)
	table.insert(ht, 3, "Connection: close")
    table.insert(ht, 4, "Content-Type: text/html; charset=UTF-8")
	table.insert(ht, 5, "Cache-Control: no-cache")
	table.insert(ht, 6, "Content-Language: pt-BR, en-US")
    table.insert(ht, 7, "Content-Length: " .. sht .. "\n")

    local function sender(sck)
        if (#ht > 0) then
            sck:send(table.remove(ht, 1) .. "\n")
        else
            sck:close()
        end
    end

	if (_ip ~= nil) then
		print("MAIN: Webserver respondendo para o cliente " .. _ip .. ".")
	end
	sck:on("sent", sender)
    sender(sck)
end

function get_http_req(instr)
   local t = {}
   local first = nil
   local key, v, strt_ndx, end_ndx

   for str in string.gmatch (instr, "([^\n]+)") do
      -- First line in the method and path
      if (first == nil) then
         first = 1
         strt_ndx, end_ndx = string.find (str, "([^ ]+)")
         v = trim (string.sub (str, end_ndx + 2))
         key = trim (string.sub (str, strt_ndx, end_ndx))
         t["METHOD"] = key
         t["REQUEST"] = v
      else -- Process and reamaining ":" fields
         strt_ndx, end_ndx = string.find (str, "([^:]+)")
         if (end_ndx ~= nil) then
            v = trim (string.sub (str, end_ndx + 2))
            key = trim (string.sub (str, strt_ndx, end_ndx))
            t[key] = v
         end
      end
   end

   return t
end

-- String trim left and right
function trim(s)
  return (s:gsub ("^%s*(.-)%s*$", "%1"))
end
