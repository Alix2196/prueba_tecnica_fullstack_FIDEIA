package ai.fideia.tickets.service;

import ai.fideia.tickets.domain.Comentario;
import ai.fideia.tickets.domain.HistorialEstado;
import ai.fideia.tickets.domain.Ticket;
import ai.fideia.tickets.domain.TicketEstado;
import ai.fideia.tickets.domain.TicketPrioridad;
import ai.fideia.tickets.domain.Usuario;
import ai.fideia.tickets.domain.UsuarioRol;
import ai.fideia.tickets.dto.CambiarEstadoRequest;
import ai.fideia.tickets.dto.ComentarioCreateRequest;
import ai.fideia.tickets.dto.ComentarioResponse;
import ai.fideia.tickets.dto.PageResponse;
import ai.fideia.tickets.dto.TicketCreateRequest;
import ai.fideia.tickets.dto.TicketDetailResponse;
import ai.fideia.tickets.dto.TicketResponse;
import ai.fideia.tickets.exception.ReglaNegocioException;
import ai.fideia.tickets.exception.RecursoNoEncontradoException;
import ai.fideia.tickets.mapper.TicketMapper;
import ai.fideia.tickets.repository.ComentarioRepository;
import ai.fideia.tickets.repository.HistorialEstadoRepository;
import ai.fideia.tickets.repository.TicketRepository;
import ai.fideia.tickets.repository.UsuarioRepository;
import java.time.OffsetDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Orquesta el ciclo de vida del ticket. Los cambios de estado se manejan en
 * una unica transaccion que valida la maquina de estados, guarda el
 * comentario de solucion si aplica, actualiza el ticket y registra el
 * historial de forma atomica (README seccion 5).
 */
@Service
@RequiredArgsConstructor
public class TicketService {

    private static final int TAMANO_PAGINA_MAXIMO = 100;

    private final TicketRepository ticketRepository;
    private final ComentarioRepository comentarioRepository;
    private final HistorialEstadoRepository historialEstadoRepository;
    private final UsuarioRepository usuarioRepository;

    @Transactional
    public TicketResponse crear(TicketCreateRequest request) {
        Usuario solicitante = obtenerUsuarioConRol(request.solicitanteId(), UsuarioRol.SOLICITANTE);
        Usuario agente = request.agenteId() != null
                ? obtenerUsuarioConRol(request.agenteId(), UsuarioRol.AGENTE)
                : null;

        OffsetDateTime ahora = OffsetDateTime.now();

        Ticket ticket = new Ticket();
        ticket.setTitulo(request.titulo());
        ticket.setDescripcion(request.descripcion());
        ticket.setPrioridad(request.prioridad());
        ticket.setEstado(TicketEstado.ABIERTO);
        ticket.setSolicitante(solicitante);
        ticket.setAgente(agente);
        ticket.setFechaCreacion(ahora);
        ticket.setFechaActualizacion(ahora);
        ticketRepository.save(ticket);

        registrarHistorial(ticket, null, TicketEstado.ABIERTO, solicitante, ahora);

        return TicketMapper.toResponse(ticket);
    }

    @Transactional(readOnly = true)
    public PageResponse<TicketResponse> listar(TicketEstado estado, TicketPrioridad prioridad, int page, int size) {
        int paginaSegura = Math.max(page, 0);
        int tamanoSeguro = Math.min(Math.max(size, 1), TAMANO_PAGINA_MAXIMO);
        Pageable pageable = PageRequest.of(paginaSegura, tamanoSeguro, Sort.by(Sort.Direction.DESC, "fechaCreacion"));

        Page<Ticket> pagina = ticketRepository.findAll(TicketSpecifications.conFiltros(estado, prioridad), pageable);
        return PageResponse.of(pagina.map(TicketMapper::toResponse));
    }

    @Transactional(readOnly = true)
    public TicketDetailResponse obtenerDetalle(Long id) {
        Ticket ticket = obtenerTicket(id);
        List<Comentario> comentarios = comentarioRepository.findByTicketIdOrderByCreadoEnAsc(id);
        List<HistorialEstado> historial = historialEstadoRepository.findByTicketIdOrderByCreadoEnAsc(id);
        return TicketMapper.toDetailResponse(ticket, comentarios, historial);
    }

    @Transactional
    public TicketResponse cambiarEstado(Long ticketId, CambiarEstadoRequest request) {
        Ticket ticket = obtenerTicket(ticketId);
        Usuario autor = obtenerUsuario(request.autorId());

        TicketEstado actual = ticket.getEstado();
        TicketEstado nuevo = request.estadoNuevo();
        OffsetDateTime ahora = OffsetDateTime.now();

        TicketEstadoMachine.validarTransicion(actual, nuevo);
        TicketEstadoMachine.validarVentanaReapertura(actual, nuevo, ticket.getFechaResolucion(), ahora);

        if (nuevo == TicketEstado.RESUELTO) {
            if (request.comentario() == null || request.comentario().isBlank()) {
                throw new ReglaNegocioException(
                        "Para pasar a RESUELTO es obligatorio un comentario de solucion no vacio");
            }
            guardarComentario(ticket, autor, request.comentario(), true, ahora);
            ticket.setFechaResolucion(ahora);
        }

        ticket.setEstado(nuevo);
        ticketRepository.save(ticket);

        registrarHistorial(ticket, actual, nuevo, autor, ahora);

        return TicketMapper.toResponse(ticket);
    }

    @Transactional
    public ComentarioResponse agregarComentario(Long ticketId, ComentarioCreateRequest request) {
        Ticket ticket = obtenerTicket(ticketId);
        if (ticket.getEstado() == TicketEstado.CERRADO) {
            throw new ReglaNegocioException("No se pueden agregar comentarios a un ticket CERRADO");
        }
        Usuario autor = obtenerUsuario(request.autorId());

        Comentario comentario = guardarComentario(ticket, autor, request.texto(), false, OffsetDateTime.now());
        return TicketMapper.toResponse(comentario);
    }

    private Ticket obtenerTicket(Long id) {
        return ticketRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("No existe el ticket " + id));
    }

    private Usuario obtenerUsuario(Long id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new RecursoNoEncontradoException("No existe el usuario " + id));
    }

    private Usuario obtenerUsuarioConRol(Long id, UsuarioRol rolEsperado) {
        Usuario usuario = obtenerUsuario(id);
        if (usuario.getRol() != rolEsperado) {
            throw new ReglaNegocioException("El usuario " + id + " no tiene rol " + rolEsperado);
        }
        return usuario;
    }

    private Comentario guardarComentario(
            Ticket ticket, Usuario autor, String texto, boolean esSolucion, OffsetDateTime fecha) {
        Comentario comentario = new Comentario();
        comentario.setTicket(ticket);
        comentario.setAutor(autor);
        comentario.setTexto(texto);
        comentario.setEsSolucion(esSolucion);
        comentario.setCreadoEn(fecha);
        return comentarioRepository.save(comentario);
    }

    private void registrarHistorial(
            Ticket ticket, TicketEstado anterior, TicketEstado nuevo, Usuario autor, OffsetDateTime fecha) {
        HistorialEstado historial = new HistorialEstado();
        historial.setTicket(ticket);
        historial.setEstadoAnterior(anterior);
        historial.setEstadoNuevo(nuevo);
        historial.setAutor(autor);
        historial.setCreadoEn(fecha);
        historialEstadoRepository.save(historial);
    }
}
