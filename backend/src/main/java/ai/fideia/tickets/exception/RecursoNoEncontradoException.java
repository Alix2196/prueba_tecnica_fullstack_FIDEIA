package ai.fideia.tickets.exception;

/** Lanzada cuando se pide por id un recurso (ticket, usuario, etc.) que no existe. */
public class RecursoNoEncontradoException extends RuntimeException {

    public RecursoNoEncontradoException(String mensaje) {
        super(mensaje);
    }
}
