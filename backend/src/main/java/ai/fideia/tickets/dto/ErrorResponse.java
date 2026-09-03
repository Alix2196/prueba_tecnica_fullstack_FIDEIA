package ai.fideia.tickets.dto;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * Formato uniforme de error de la API (README seccion 6: "Formato de error").
 *
 * @param codigo    identificador corto y estable del tipo de error (p. ej. TRANSICION_INVALIDA)
 * @param mensaje   mensaje entendible para el cliente
 * @param detalles  detalle opcional (p. ej. errores de validacion por campo)
 * @param timestamp momento en que ocurrio el error
 */
public record ErrorResponse(
        String codigo,
        String mensaje,
        List<String> detalles,
        OffsetDateTime timestamp
) {
    public static ErrorResponse of(String codigo, String mensaje) {
        return new ErrorResponse(codigo, mensaje, List.of(), OffsetDateTime.now());
    }

    public static ErrorResponse of(String codigo, String mensaje, List<String> detalles) {
        return new ErrorResponse(codigo, mensaje, detalles, OffsetDateTime.now());
    }
}
