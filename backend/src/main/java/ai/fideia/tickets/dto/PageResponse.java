package ai.fideia.tickets.dto;

import java.util.List;
import org.springframework.data.domain.Page;

/** Respuesta paginada con el total de registros (enunciado seccion 3.4: "Listar tickets"). */
public record PageResponse<T>(
        List<T> contenido,
        int pagina,
        int tamano,
        long totalElementos,
        int totalPaginas
) {
    public static <T> PageResponse<T> of(Page<T> page) {
        return new PageResponse<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages());
    }
}
