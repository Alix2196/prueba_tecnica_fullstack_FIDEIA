package ai.fideia.tickets.dto;

import ai.fideia.tickets.domain.UsuarioRol;

public record UsuarioResumenResponse(
        Long id,
        String nombre,
        UsuarioRol rol
) {
}
