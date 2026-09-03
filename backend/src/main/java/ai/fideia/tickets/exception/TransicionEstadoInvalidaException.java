package ai.fideia.tickets.exception;

/**
 * Lanzada cuando se intenta una transicion de estado no permitida por la
 * maquina de estados de la mesa de ayuda (README seccion 5).
 */
public class TransicionEstadoInvalidaException extends RuntimeException {

    public TransicionEstadoInvalidaException(String mensaje) {
        super(mensaje);
    }
}
