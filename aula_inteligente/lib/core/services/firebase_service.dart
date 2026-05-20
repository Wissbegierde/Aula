/// Stub para integración futura con Firebase.
/// Reemplazar métodos mock por Firestore / Realtime Database / Auth.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool get isInitialized => false;

  Future<void> initialize() async {
    // TODO: Firebase.initializeApp() + configuración por plataforma
  }
}
