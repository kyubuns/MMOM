// Generated by CoffeeScript 1.9.1
(function() {
  var _Game_Interpreter_pluginCommand, _Game_Temp_setDestination, _Scene_Title_create;

  _Game_Interpreter_pluginCommand = Game_Interpreter.prototype.pluginCommand;

  Game_Interpreter.prototype.pluginCommand = function(command, args) {
    if (command === 'Network') {
      switch (args[0]) {
        case "Connect":
          return $gameSystem.networkConnect();
        case "SendMove":
          return $gameSystem.sendMove();
        case "SendEnter":
          return $gameSystem.sendEnter(args[1]);
        case "OpenURL":
          return $gameSystem.openUrl(args[1]);
      }
    }
  };

  Game_System.prototype.networkConnect = function() {
    var socket;
    console.log("network connect start");
    $gameVariables.setValue(9, 0);
    socket = io.connect('http://kyubuns.net:3030', {
      transports: ["websocket"],
      forceNew: true
    });
    $gamePlayer.socket = socket;
    socket.on('connect', function() {
      console.log("connected!");
      return $gameVariables.setValue(9, 1);
    });
    socket.on('join_player', function(info) {
      return $gameSystem.joinPlayer(info);
    });
    socket.on('leave_player', function(networkId) {
      if ($gameSystem.networkPlayers[networkId]) {
        return delete $gameSystem.networkPlayers[networkId];
      }
    });
    socket.on('move', function(networkId, x, y) {
      if ($gameSystem.networkPlayers[networkId]) {
        $gameSystem.networkPlayers[networkId].x = x;
        return $gameSystem.networkPlayers[networkId].y = y;
      }
    });
    socket.on('tile', function(index, tileId) {
      if ($dataMap && $dataMap.data && $dataMap.data.length > index) {
        return $dataMap.data[index] = tileId;
      }
    });
    return console.log("network connect finish");
  };

  Game_System.prototype.joinPlayer = function(info) {
    return $gameMap.getEventDataFrom(1, 1, function(eventData) {
      var gameEvent;
      gameEvent = $gameMap.addEventAt(eventData, info['x'], info['y'], true);
      MVC.accessor(gameEvent, 'networkId');
      gameEvent.networkId = info['id'];
      return $gameSystem.networkPlayers[info['id']] = info;
    });
  };

  Game_System.prototype.getNetworkPlayerInfo = function(networkId) {
    var info;
    info = $gameSystem.networkPlayers[networkId];
    if (info) {
      $gameVariables.setValue(10, 1);
      $gameVariables.setValue(11, info['x']);
      return $gameVariables.setValue(12, info['y']);
    } else {
      return $gameVariables.setValue(10, 0);
    }
  };

  Game_System.prototype.sendTile = function(index, tileId) {
    if (!$gamePlayer.socket) {
      return;
    }
    return $gamePlayer.socket.emit('tile', index, tileId);
  };

  Game_System.prototype.sendMove = function() {
    if (!$gamePlayer.socket) {
      return;
    }
    return $gamePlayer.socket.emit('move', $gamePlayer.x, $gamePlayer.y);
  };

  Game_System.prototype.sendEnter = function(mapId) {
    if (!$gamePlayer.socket) {
      return;
    }
    return $gamePlayer.socket.emit('enter', 'dummy', mapId, $gamePlayer.x, $gamePlayer.y, function(id, members, map) {
      var i, info, j, k, len, len1, results, val;
      console.log("entered");
      $gamePlayer.networkId = id;
      $gameSystem.networkPlayers = {};
      for (j = 0, len = members.length; j < len; j++) {
        info = members[j];
        $gameSystem.joinPlayer(info);
      }
      if (map && $dataMap) {
        results = [];
        for (i = k = 0, len1 = map.length; k < len1; i = ++k) {
          val = map[i];
          results.push($dataMap.data[i] = val);
        }
        return results;
      }
    });
  };

  Game_System.prototype.openUrl = function(url) {
    return window.open(url, '_blank');
  };

  _Scene_Title_create = Scene_Title.prototype.create;

  Scene_Title.prototype.create = function() {
    _Scene_Title_create.call(this);
    if ($gamePlayer.socket) {
      console.log('release');
      $gamePlayer.socket.disconnect();
      return $gamePlayer.socket = null;
    }
  };

  _Game_Temp_setDestination = Game_Temp.prototype.setDestination;

  Game_Temp.prototype.setDestination = function(x, y) {
    var height, index, width, z;
    if ($gameTemp.createMode) {
      width = $dataMap.width;
      height = $dataMap.height;
      z = $gameTemp.tileLayer;
      index = [(z * height + y) * width + x];
      return $gameSystem.sendTile(index, $gameTemp.tileId);
    } else {
      return _Game_Temp_setDestination.call(this, x, y);
    }
  };

  Scene_Menu.prototype.start = function() {
    return Scene_MenuBase.prototype.start.call(this);
  };

  Scene_Menu.prototype.createCommandWindow = function() {
    this._commandWindow = new Window_MenuCommand(0, 0);
    this._commandWindow.setHandler('normal', this.commandNormal.bind(this));
    this._commandWindow.setHandler('item1', this.commandItem1.bind(this));
    this._commandWindow.setHandler('item2', this.commandItem2.bind(this));
    this._commandWindow.setHandler('item3', this.commandItem3.bind(this));
    this._commandWindow.setHandler('gameEnd', this.commandGameEnd.bind(this));
    this._commandWindow.setHandler('options', this.commandOptions.bind(this));
    this._commandWindow.setHandler('cancel', this.popScene.bind(this));
    return this.addWindow(this._commandWindow);
  };

  Scene_Menu.prototype.commandNormal = function() {
    $gameTemp.createMode = false;
    return this.popScene();
  };

  Scene_Menu.prototype.commandItem1 = function() {
    $gameTemp.createMode = true;
    $gameTemp.tileId = 2816;
    $gameTemp.tileLayer = 1;
    return this.popScene();
  };

  Scene_Menu.prototype.commandItem2 = function() {
    $gameTemp.createMode = true;
    $gameTemp.tileId = 2920;
    $gameTemp.tileLayer = 1;
    return this.popScene();
  };

  Scene_Menu.prototype.commandItem3 = function() {
    $gameTemp.createMode = true;
    $gameTemp.tileId = 3200;
    $gameTemp.tileLayer = 1;
    return this.popScene();
  };

  Scene_Menu.prototype.create = function() {
    Scene_MenuBase.prototype.create.call(this);
    return this.createCommandWindow();
  };

  Window_MenuCommand.prototype.makeCommandList = function() {
    this.addOriginalCommands();
    this.addOptionsCommand();
    this.addSaveCommand();
    return this.addGameEndCommand();
  };

  Window_MenuCommand.prototype.addOriginalCommands = function() {
    this.addCommand('移動モード', 'normal', true);
    this.addCommand('設置1', 'item1', true);
    this.addCommand('設置2', 'item2', true);
    return this.addCommand('設置3', 'item3', true);
  };

  Scene_Map.prototype.create = function() {
    Scene_Base.prototype.create.call(this);
    this._transfer = $gamePlayer.isTransferring();
    if (this._transfer) {
      return DataManager.loadMapData($gamePlayer.newMapId());
    }
  };

}).call(this);
