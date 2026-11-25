// [MODIFIKASI] Abstraksi pemanggil kamera perangkat langsung lintas platform
import 'web_camera_stub.dart'
    if (dart.library.html) 'web_camera_web.dart';

abstract class WebCameraHelper {
  /// Membuka kamera perangkat secara langsung dengan live viewfinder jika berjalan di platform Web.
  /// Mengembalikan Map berisi `name` dan `dataUrl` jika berhasil mengambil foto, atau null jika dibatalkan/gagal.
  static Future<Map<String, dynamic>?> openCamera() async {
    return openDeviceCameraWeb();
  }
}
