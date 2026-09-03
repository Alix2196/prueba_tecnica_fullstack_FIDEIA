package ai.fideia.tickets.controller;

import ai.fideia.tickets.domain.TicketEstado;
import ai.fideia.tickets.domain.TicketPrioridad;
import ai.fideia.tickets.dto.CambiarEstadoRequest;
import ai.fideia.tickets.dto.ComentarioCreateRequest;
import ai.fideia.tickets.dto.ComentarioResponse;
import ai.fideia.tickets.dto.PageResponse;
import ai.fideia.tickets.dto.TicketCreateRequest;
import ai.fideia.tickets.dto.TicketDetailResponse;
import ai.fideia.tickets.dto.TicketResponse;
import ai.fideia.tickets.service.TicketService;
import jakarta.validation.Valid;
import java.net.URI;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** API REST minima del sistema de tickets (enunciado seccion 3.4 / README seccion 6). */
@RestController
@RequestMapping("/api/tickets")
@RequiredArgsConstructor
public class TicketController {

    private final TicketService ticketService;

    @PostMapping
    public ResponseEntity<TicketResponse> crear(@Valid @RequestBody TicketCreateRequest request) {
        TicketResponse creado = ticketService.crear(request);
        return ResponseEntity.created(URI.create("/api/tickets/" + creado.id())).body(creado);
    }

    @GetMapping
    public ResponseEntity<PageResponse<TicketResponse>> listar(
            @RequestParam(required = false) TicketEstado estado,
            @RequestParam(required = false) TicketPrioridad prioridad,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ticketService.listar(estado, prioridad, page, size));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TicketDetailResponse> obtener(@PathVariable Long id) {
        return ResponseEntity.ok(ticketService.obtenerDetalle(id));
    }

    @PatchMapping("/{id}/estado")
    public ResponseEntity<TicketResponse> cambiarEstado(
            @PathVariable Long id, @Valid @RequestBody CambiarEstadoRequest request) {
        return ResponseEntity.ok(ticketService.cambiarEstado(id, request));
    }

    @PostMapping("/{id}/comentarios")
    public ResponseEntity<ComentarioResponse> agregarComentario(
            @PathVariable Long id, @Valid @RequestBody ComentarioCreateRequest request) {
        ComentarioResponse creado = ticketService.agregarComentario(id, request);
        return ResponseEntity.status(201).body(creado);
    }
}
