package ai.fideia.tickets.repository;

import ai.fideia.tickets.domain.HistorialEstado;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HistorialEstadoRepository extends JpaRepository<HistorialEstado, Long> {

    List<HistorialEstado> findByTicketIdOrderByCreadoEnAsc(Long ticketId);
}
