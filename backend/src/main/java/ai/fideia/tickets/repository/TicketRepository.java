package ai.fideia.tickets.repository;

import ai.fideia.tickets.domain.Ticket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

/**
 * JpaSpecificationExecutor habilita construir el filtro combinable por
 * estado/prioridad de GET /tickets (README seccion 6) sin acoplar el
 * repositorio a cada combinacion de filtros.
 */
public interface TicketRepository extends JpaRepository<Ticket, Long>, JpaSpecificationExecutor<Ticket> {
}
