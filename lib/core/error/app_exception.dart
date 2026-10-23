
import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;

  factory AppException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const AppException(
          'Превышено время ожидания. Попробуйте ещё раз.',
        );

      case DioExceptionType.connectionError:
        return const AppException(
          'Нет соединения с интернетом.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;

        if (statusCode != null && statusCode >= 500) {
          return const AppException(
            'Ошибка сервера. Попробуйте позже.',
          );
        }

        if (statusCode != null && statusCode >= 400) {
          return const AppException(
            'Не удалось выполнить запрос.',
          );
        }

        return const AppException(
          'Получен некорректный ответ сервера.',
        );

      case DioExceptionType.cancel:
        return const AppException(
          'Запрос был отменён.',
        );

      case DioExceptionType.badCertificate:
        return const AppException(
          'Не удалось безопасно подключиться к серверу.',
        );

      case DioExceptionType.unknown:
        return const AppException(
          'Произошла неизвестная ошибка.',
        );
    }
  }
}
