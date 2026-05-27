/// Falhas representáveis na UI (clean architecture).
abstract class Failure {
  const Failure(this.message);

  final String message;
}

class GenericFailure extends Failure {
  const GenericFailure(super.message);
}
