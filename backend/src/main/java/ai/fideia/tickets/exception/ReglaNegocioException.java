package ai.fideia.tickets.exception;

/**
 * Lanzada cuando una operacion viola una regla de negocio distinta a la
 * maquina de estados (p. ej. comentario de solucion vacio al resolver un
 * ticket, o comentario sobre un ticket CERRADO). README seccion 5.
 */
public class ReglaNegocioException extends RuntimeException {

    public ReglaNegocioException(String mensaje) {
        super(mensaje);
    }
}
