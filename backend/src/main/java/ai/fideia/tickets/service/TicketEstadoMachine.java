package ai.fideia.tickets.service;

import ai.fideia.tickets.domain.TicketEstado;
import ai.fideia.tickets.exception.TransicionEstadoInvalidaException;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.Map;
import java.util.Set;

/**
 * Maquina de estados del ticket (README seccion 5 / enunciado seccion 3.3).
 * Logica pura, sin dependencias de Spring ni de la base de datos, para que
 * sea verificable con pruebas unitarias simples.
 */
public final class TicketEstadoMachine {

    private static final Duration VENTANA_REAPERTURA = Duration.ofDays(3);

    private static final Map<TicketEstado, Set<TicketEstado>> TRANSICIONES_VALIDAS = Map.of(
            TicketEstado.ABIERTO, Set.of(TicketEstado.EN_PROCESO),
            TicketEstado.EN_PROCESO, Set.of(TicketEstado.RESUELTO),
            TicketEstado.RESUELTO, Set.of(TicketEstado.CERRADO, TicketEstado.EN_PROCESO),
            TicketEstado.CERRADO, Set.of()
    );

    private TicketEstadoMachine() {
    }

    /**
     * Valida que la transicion de {@code actual} a {@code nuevo} este permitida
     * por la maquina de estados. No valida la regla adicional de la ventana de
     * reapertura de 3 dias: eso lo hace {@link #validarVentanaReapertura}.
     */
    public static void validarTransicion(TicketEstado actual, TicketEstado nuevo) {
        if (!TRANSICIONES_VALIDAS.getOrDefault(actual, Set.of()).contains(nuevo)) {
            throw new TransicionEstadoInvalidaException(
                    "No se puede pasar de %s a %s".formatted(actual, nuevo));
        }
    }

    /**
     * Regla adicional para la reapertura (RESUELTO -> EN_PROCESO): solo es
     * valida si el ticket paso a RESUELTO hace menos de 3 dias. No aplica a
     * ninguna otra transicion.
     */
    public static void validarVentanaReapertura(
            TicketEstado actual, TicketEstado nuevo, OffsetDateTime fechaResolucion, OffsetDateTime ahora) {
        if (actual != TicketEstado.RESUELTO || nuevo != TicketEstado.EN_PROCESO) {
            return;
        }
        if (fechaResolucion == null || !ahora.isBefore(fechaResolucion.plus(VENTANA_REAPERTURA))) {
            throw new TransicionEstadoInvalidaException(
                    "La reapertura solo es valida si el ticket paso a RESUELTO hace menos de 3 dias");
        }
    }
}
