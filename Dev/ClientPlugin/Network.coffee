_Game_Interpreter_pluginCommand = Game_Interpreter.prototype.pluginCommand
Game_Interpreter.prototype.pluginCommand = (command, args) ->
  if command == 'Network'
    switch args[0]
      when "Connect"
        $gameSystem.networkConnect()
      when "SendMove"
        $gameSystem.sendMove()
      when "SendEnter"
        $gameSystem.sendEnter(args[1])
      when "OpenURL"
        $gameSystem.openUrl(args[1])


Game_System.prototype.networkConnect = ->
  console.log("network connect start")
  $gameVariables.setValue(9, 0)
  socket = io.connect('http://kyubuns.net:3030', { transports:["websocket"], forceNew: true })
  $gamePlayer.socket = socket

  socket.on 'connect', ->
    console.log("connected!")
    $gameVariables.setValue(9, 1)

  socket.on 'join_player', (info) ->
    $gameSystem.joinPlayer(info)

  socket.on 'leave_player', (networkId) ->
    delete $gameSystem.networkPlayers[networkId] if $gameSystem.networkPlayers[networkId]

  socket.on 'move', (networkId, x, y) ->
    if $gameSystem.networkPlayers[networkId]
      $gameSystem.networkPlayers[networkId].x = x
      $gameSystem.networkPlayers[networkId].y = y

  socket.on 'tile', (index, tileId) ->
    $dataMap.data[index] = tileId

  console.log("network connect finish")


Game_System.prototype.joinPlayer = (info) ->
  $gameMap.getEventDataFrom 1, 1, (eventData) ->
    gameEvent = $gameMap.addEventAt(eventData, info['x'], info['y'], true)
    MVC.accessor(gameEvent, 'networkId')
    gameEvent.networkId = info['id']
    $gameSystem.networkPlayers[info['id']] = info


Game_System.prototype.getNetworkPlayerInfo = (networkId) ->
  info = $gameSystem.networkPlayers[networkId]
  if info
    $gameVariables.setValue(10, 1)
    $gameVariables.setValue(11, info['x'])
    $gameVariables.setValue(12, info['y'])
  else
    $gameVariables.setValue(10, 0)


Game_System.prototype.sendTile = (index, tileId) ->
  unless $gamePlayer.socket
    return

  $gamePlayer.socket.emit('tile', index, tileId)


Game_System.prototype.sendMove = ->
  unless $gamePlayer.socket
    return

  $gamePlayer.socket.emit('move', $gamePlayer.x, $gamePlayer.y)


Game_System.prototype.sendEnter = (mapId) ->
  unless $gamePlayer.socket
    return

  $gamePlayer.socket.emit('enter', 'dummy', mapId, $gamePlayer.x, $gamePlayer.y, (id, members, map) ->
    console.log("entered")
    $gamePlayer.networkId = id
    $gameSystem.networkPlayers = {}
    $gameSystem.joinPlayer(info) for info in members

    #$dataMap.data = map とすると参照が死ぬ
    if map
      for val,i in map
        $dataMap.data[i] = val
  )

Game_System.prototype.openUrl = (url) ->
  window.open(url, '_blank')



_Scene_Title_create = Scene_Title.prototype.create
Scene_Title.prototype.create = ->
  _Scene_Title_create.call(this)
  if $gamePlayer.socket
    console.log('release')
    $gamePlayer.socket.disconnect()
    $gamePlayer.socket = null


_Game_Temp_setDestination = Game_Temp.prototype.setDestination
Game_Temp.prototype.setDestination = (x, y) ->
  if $gameTemp.createMode
    width = $dataMap.width
    height = $dataMap.height
    z = $gameTemp.tileLayer
    index = [(z * height + y) * width + x]
    $gameSystem.sendTile(index, $gameTemp.tileId)
  else
    _Game_Temp_setDestination.call(this, x, y)

Scene_Menu.prototype.start = ->
    Scene_MenuBase.prototype.start.call(this)

Scene_Menu.prototype.createCommandWindow = ->
  this._commandWindow = new Window_MenuCommand(0, 0)
  this._commandWindow.setHandler('normal',    this.commandNormal.bind(this))
  this._commandWindow.setHandler('item1',     this.commandItem1.bind(this))
  this._commandWindow.setHandler('item2',     this.commandItem2.bind(this))
  this._commandWindow.setHandler('item3',     this.commandItem3.bind(this))
  this._commandWindow.setHandler('gameEnd',   this.commandGameEnd.bind(this))
  this._commandWindow.setHandler('options',   this.commandOptions.bind(this))
  this._commandWindow.setHandler('cancel',    this.popScene.bind(this))
  this.addWindow(this._commandWindow)

Scene_Menu.prototype.commandNormal = ->
  $gameTemp.createMode = false
  this.popScene()

Scene_Menu.prototype.commandItem1 = ->
  $gameTemp.createMode = true
  $gameTemp.tileId = 2816
  $gameTemp.tileLayer = 1
  this.popScene()

Scene_Menu.prototype.commandItem2 = ->
  $gameTemp.createMode = true
  $gameTemp.tileId = 2920
  $gameTemp.tileLayer = 1
  this.popScene()

Scene_Menu.prototype.commandItem3 = ->
  $gameTemp.createMode = true
  $gameTemp.tileId = 3200
  $gameTemp.tileLayer = 1
  this.popScene()

Scene_Menu.prototype.create = ->
  Scene_MenuBase.prototype.create.call(this)
  this.createCommandWindow()

Window_MenuCommand.prototype.makeCommandList = ->
  this.addOriginalCommands()
  this.addOptionsCommand()
  this.addSaveCommand()
  this.addGameEndCommand()

Window_MenuCommand.prototype.addOriginalCommands = ->
  this.addCommand('移動モード', 'normal', true)
  this.addCommand('設置1', 'item1', true)
  this.addCommand('設置2', 'item2', true)
  this.addCommand('設置3', 'item3', true)


Scene_Map.prototype.create = ->
    Scene_Base.prototype.create.call(this)
    this._transfer = $gamePlayer.isTransferring()
    if this._transfer
      DataManager.loadMapData($gamePlayer.newMapId())
