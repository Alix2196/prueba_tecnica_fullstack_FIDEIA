package ai.fideia.tickets.dto;

import ai.fideia.tickets.domain.TicketPrioridad;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * El ticket nace en estado ABIERTO (enunciado seccion 3.4); por eso no se
 * recibe estado aqui. {@code agenteId} es opcional (README seccion 4).
 */
public record TicketCreateRequest(
        @NotBlank(message = "el titulo es obligatorio")
        @Size(max = 200, message = "el titulo no puede superar 200 caracteres")
        String titulo,

        @NotBlank(message = "la descripcion es obligatoria")
        String descripcion,

        @NotNull(message = "la prioridad es obligatoria")
        TicketPrioridad prioridad,

        @NotNull(message = "el solicitante es obligatorio")
        Long solicitanteId,

        Long agenteId
) {
}
