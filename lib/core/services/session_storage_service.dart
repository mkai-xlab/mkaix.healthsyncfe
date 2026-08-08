import 'session_storage/session_storage_stub.dart'
    if (dart.library.html) 'session_storage/session_storage_web.dart'
    as storage;

class SessionStorageService {
  static const String userKey = 'healthsync.current_user';

  Future<String?> readUserJson() {
    return storage.read(userKey);
  }

  Future<void> saveUserJson(String value) {
    return storage.write(userKey, value);
  }

  Future<void> clearUser() {
    return storage.remove(userKey);
  }

  Future<void> clearAll() {
    return storage.clearAll();
  }
}
