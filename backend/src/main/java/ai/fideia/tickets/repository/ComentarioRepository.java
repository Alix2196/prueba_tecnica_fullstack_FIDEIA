package ai.fideia.tickets.repository;

import ai.fideia.tickets.domain.Comentario;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ComentarioRepository extends JpaRepository<Comentario, Long> {

    List<Comentario> findByTicketIdOrderByCreadoEnAsc(Long ticketId);
}
