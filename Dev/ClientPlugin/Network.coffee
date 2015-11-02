_Game_Interpreter_pluginCommand = Game_Interpreter.prototype.pluginCommand
Game_Interpreter.prototype.pluginCommand = (command, args) ->
  if command == 'Network'
    switch args[0]
      when "Connect"
        $gameSystem.networkConnect()


Game_System.prototype.networkConnect = ->
  console.log("network connect start")
  socket = io.connect('http://localhost:3030', {transports:["websocket"]})
  socket.on 'connect', ->
    console.log("connected!")
  console.log("network connect finish")
