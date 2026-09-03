package ai.fideia.tickets.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record ComentarioCreateRequest(
        @NotNull(message = "el autor es obligatorio")
        Long autorId,

        @NotBlank(message = "el texto del comentario es obligatorio")
        String texto
) {
}
