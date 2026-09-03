package ai.fideia.tickets.controller;

import ai.fideia.tickets.domain.UsuarioRol;
import ai.fideia.tickets.dto.UsuarioResumenResponse;
import ai.fideia.tickets.mapper.TicketMapper;
import ai.fideia.tickets.repository.UsuarioRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Catalogo de usuarios precargado (README seccion 4 y 8): sin registro ni
 * gestion via API, solo lectura para poblar el selector de "usuario actual"
 * y los formularios de creacion de ticket en el frontend.
 */
@RestController
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioRepository usuarioRepository;

    @GetMapping
    public List<UsuarioResumenResponse> listar(@RequestParam(required = false) UsuarioRol rol) {
        var usuarios = rol == null ? usuarioRepository.findAll() : usuarioRepository.findByRol(rol);
        return usuarios.stream().map(TicketMapper::toResumen).toList();
    }
}
