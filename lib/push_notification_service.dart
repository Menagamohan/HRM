import 'dart:async';
import 'package:googleapis_auth/auth_io.dart';

class PushNotificationService {
  static Future<String> getAccessToken() async {
    final serviceAccountJson =
    {
      "type": "service_account",
      "project_id": "hanon-notification-82381",
      "private_key_id": "8ebbaf17797720df63d7c8d9913ece9be80debc2",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDUj658XPP/cP0d\n3BBK7/xOmRIUdaKnpumsrh2/yqZq6RJXFmBWErhXF1nWI0/bG4B4mw/x1CF9Fmhv\nyfwCYF2twMFzXW1Eq88mfrJDsVazuS0rka1ZWybs7kYSKURrwEL3HcZv9vQxl99z\nB3HUsOWC1ozZsQeZ7n5KZs0U5b2gu32QaBBWdYzJw3R7xSPDvCUSOuRWlh/cynE2\n6f/xw8F6H9hIDM+tiy6ONkwTDYf+GEuom4Wq6zF7rSUjs7AqhwyNYC7Mz1Ag4kfA\niyYyBGuRYdVmo+dyEiWG3LHx1svlbKNYxc78kS3J+Cp/9fzekqbn8Hld8mUKjKF9\nl//JiTQpAgMBAAECggEAA4nugVFehOTEQLHCpK4Tpi8BYHf9O1YkTZ9qzTVfaWgU\nHyvhx9+7vsQbrFy9+Nt08K0WNMllEwB4lc8yo/XSQXEJgh/updtyvATqd1rgYxFv\naX+yojT0tDJFq4o718u64a3WzqjkHl+VVQSCoORJYeZWsHjJyVvcMZATadMRrIzC\nxouSmdvXWQD4wERJpARQkeOPklr49+aUSARotK5DanRxouKkAxX1JP/Xs0aj/Eye\nWJfirW0EcL64yewXxiYK/oGWF8/ISDm6z7W7ea7P05SJPdUvx/sju5sne5YNtscZ\nY3uNQuRLyWu0FsiXgHGsMFWai6fjst78SOp/TnHSAQKBgQDp89Seq+KIGj45e7Io\n66LvVSKjQNocvTwj9Gt02mbhwC0IJybO4T7gv47KJ4OpZ1ZUANi5Vyn51+rlaVqC\nCt5XqEjMTBtGhG0mduBhsa+mA/92dyhf9XDTuLC0JwlsYtHhWDQCMw4P/wZhhgCD\nkK1yOrEua86KaQ6NyW9HtquzAQKBgQDol8g4h9faZBcmLf5ksC7Qhs5a8+/8HTfM\nWPRaYniOnFwF1wrnMJvyE8t06NGpz7qF3n4WBoQbt0XtONJb9OHTK4oYXUOv0xWR\nkm5ToB1bn3uioyCpcv1mgyz3u7MBMJE3YDbm8SarcDk1M8CniZFLbyOEcoRcH8cM\nlxi7Sz6JKQKBgQDOzedJS4+319rhXWKjoYgqIAu6W/1yIiUjc0/5v4XqUMJ9zn4T\nqjC24x4JvNw5x0scfpMVYuOMIz1VBcgn5AufWPbhAPWrZCxIMBUwxq0KB8aupa5f\nBMtznHM3DLrbwI7er+VpfFAV+81cL+QMaLupmhA9hLbSywM+eq2Pqv4kAQKBgH4W\nIdT7VvktvxrUXg6pL4edPGozyMmr8R6Wrkf9D4uHmZ8U1vVC9ZbCQk3rFBVw5ZVC\naql3+M+ph3+0iNyOoIjAFolkrZe33v5eGe69YozTpMsikUcqbdHPlGXrW3tun5oc\nT0bcPXE8UdbUakCoI5p38hIPnk7ubxIVKrQFcy4ZAoGAVDzRmSZJotQR6/CbEep0\nofEgDEs4McQVyuFBawpxVriTNp4FobtanPrIfg0EsgTCeEYbJnaq8xoF9EBXmWQI\ntqdt6mEk9OXRrnuelIkpQom4CJFB7bECSslw+NAlALf77QNrWG4r/qFImdU9gM2G\nCFv77WG4DIN1CnuubAYPZww=\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@hanon-notification-82381.iam.gserviceaccount.com",
      "client_id": "111792362706834081394",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40hanon-notification-82381.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    final client = await clientViaServiceAccount(credentials, scopes);

    return client.credentials.accessToken.data;
  }
}
