class MessageBus {
  //DI as singleton
  static const String Channel_CurrentAudio_State = "CurrentAudio_State";

  var _channel = Map<String, Map<String, Future<void> Function(dynamic)>>();

  Future<void> Subscribe(String channelName, String subscriberName,
      Future<void> Function(dynamic) handle) async {
    if (_channel.containsKey(channelName) == false) {
      _channel[channelName] = Map<String, Future<void> Function(dynamic)>();
    }
    _channel[channelName]?[subscriberName] = handle;
  }

  Future<void> Unsubscribe(String channelName, String subscriberName) async {
    _channel[channelName]!.remove(subscriberName);
  }

  Future<void> ClearChannel(String channelName) async {
    _channel.remove(channelName);
  }

  Future<void> Publish(String channelName, dynamic data) async {
    if (_channel.containsKey(channelName) == false) {
      _channel[channelName] = Map<String, Future<void> Function(dynamic)>();
    }
    for (var h in _channel[channelName]!.values) {
      h(data);
      print(data);
    }
  }
}
