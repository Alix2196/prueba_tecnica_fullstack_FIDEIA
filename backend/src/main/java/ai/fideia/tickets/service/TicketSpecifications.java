package ai.fideia.tickets.service;

import ai.fideia.tickets.domain.Ticket;
import ai.fideia.tickets.domain.TicketEstado;
import ai.fideia.tickets.domain.TicketPrioridad;
import org.springframework.data.jpa.domain.Specification;

/** Filtros combinables de GET /api/tickets por estado y prioridad (README seccion 6). */
final class TicketSpecifications {

    private TicketSpecifications() {
    }

    static Specification<Ticket> conFiltros(TicketEstado estado, TicketPrioridad prioridad) {
        return (root, query, cb) -> {
            var predicado = cb.conjunction();
            if (estado != null) {
                predicado = cb.and(predicado, cb.equal(root.get("estado"), estado));
            }
            if (prioridad != null) {
                predicado = cb.and(predicado, cb.equal(root.get("prioridad"), prioridad));
            }
            return predicado;
        };
    }
}
