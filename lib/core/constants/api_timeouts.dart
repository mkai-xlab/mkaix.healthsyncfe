class ApiTimeouts {
  static const read = Duration(minutes: 2);
  static const write = Duration(minutes: 10);
  static const upload = Duration(minutes: 2);
  static const ai = Duration(minutes: 10);
  static const websocket = Duration(seconds: 20);
}
