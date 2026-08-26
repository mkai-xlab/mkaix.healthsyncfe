class ApiTimeouts {
  static const read = Duration(seconds: 15);
  static const write = Duration(seconds: 30);
  static const upload = Duration(minutes: 2);
  static const ai = Duration(minutes: 2);
  static const websocket = Duration(seconds: 20);
}
