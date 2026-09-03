package ai.fideia.tickets.repository;

import ai.fideia.tickets.domain.Usuario;
import ai.fideia.tickets.domain.UsuarioRol;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    List<Usuario> findByRol(UsuarioRol rol);
}
