import 'dart:async';
import 'package:googleapis_auth/auth_io.dart';

class PushNotificationService {
  static Future<String> getAccessToken() async {
    final serviceAccountJson =
    {
      "type": "service_account",
      "project_id": "hanon-notification-82381",
      "private_key_id": "42b121ada55f3c11190806f30622163cb16e8043",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCTZJNuRhPuQNyL\nJkGTz9tci2qINpPRTJLVgmy79/+7KkkkKnHEJYDRoDrOESL2z/uE5zwLB7n0gN1H\nTM+TxUXd81/dD5SZSVjr9yMGAvc0m4Xz7w0lSXBt5832OWU8SuxklfU+XHcMUtK2\nIjyo/O4LUur2mEfJnDSMNZV7J3oNL2umrxrMltIslQu6zaG5nyBbsaQVu2NQ1BkL\nxPfk2mJZ8Pd54YVFgl5O7f8npBSAG1WZkrvs5CFhjqRtdevKJabYgxeok/EMSdFW\naQQz4CwQs0oSiUaLWvkHEmbUq1j//TtGL2u3JI1SOjHe7IEtKNJPq8+Rm7xw/OvM\nBVWxra0BAgMBAAECggEAAKnfFwXjF6REpdIk5fJ1c1B9FlDJJPkf6GJmYBT2C6jC\nlnehDjvGkj/dd0IIEuS1mjgnQtapKMv2a5/q4OblXfnyxlPXO+lW7O+KzX9npCgt\nIlL1lYRX8ABn4UXUdVXAXXENEC4KzpsMGxr4fj50tLu9jW7LPK/wEHBSP5BpNoMj\nq842OjCi25E+U7bO2Qulo+xtlPHBhqeLHdN+y9PL6JKk6hAI4J+ocyC0mH1mWf+7\n6+J4UJT1IESFPBTnz10ezbLML6ns6gmETNZxQQZuroZHoKg0bGX6KkwVaK9M9+Jt\naYhiUyc4IKsauLPo0KnPWRy0NGa2gGfSvhR2kuL68QKBgQDChiF0TRY2G2KhNuO5\nsoxxjHJukC0SDBJBDGZoKJdlYL2U+5lBFzIJUZ4AHXESIX0OugZ9Ko5QdIJAbISk\nxs1lV5+yedF5xZPLmKo8eQ4kItNXPvBLWJDC5meAb/r6odxRcx7C7ODNadKDaXRg\ntNBKLtRdeFlHPiC/MT/NcnevPQKBgQDB+VPka00ssFriWYX7H0f2ogdm22IVGr8j\nBaN5gGx2JUEbYKopf8rpOOzhDA8//Zuz3QJBZdgyxrGeBJ1E16OJX7LD4cOO+kP3\nJcPTblW+8SL9VWhiDDRnfMRBram1S775PBuJsYnY0w6ZikAGtcpta2Ufvb4XxaLx\nD+3TY7JRFQKBgGlXwBg+gs/MZs5NbmerFLmNSI8tjureFKibcX3otYxWJnTfB/Cj\nAhrf00PWrdwWvKXUAh2YhTd20O7YlcCyVJsUJ8y8gb+DSvWP+GkFWa4iGfd+gx0a\nmlKh+d0pR26hZzHIuRjwtREoxLMb0cVpRf9WevUfbqHROGSx5A57des1AoGBAIMK\nXwRnAOH52cwkUoEN5t3VJE72UlKTmSCdxIxml99Q16UZLpuOe5QHIu/956eBOtjN\nq6JmnSHgXUm1MFG7o/1AK1JtiGFk7NlgJ+UEGuU9njeqpTPnrtdi0GrWWVni7AcP\n9kKVL9zM6IYNgaeG1FQLQ2uoEW2Z1LQp4K74IRTpAoGBAIKQUOj7tjQwDwXNFilv\nvam8JMDZZYBQohI10HtRBflxJJnhVKRBIu6WeWkEyV8EI16edZVeIpd+08vhySBe\n0vEk7PCnr9z21/r/T7FN8eMKmM5XUv8o6LhXvMHbKXaw6EOZd0qaXX2x8mWfiEZm\nn23bRu1xdWvkmkQ3haAQ9R03\n-----END PRIVATE KEY-----\n",
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
