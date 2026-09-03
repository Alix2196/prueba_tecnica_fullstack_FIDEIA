package ai.fideia.tickets.service;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import ai.fideia.tickets.domain.TicketEstado;
import ai.fideia.tickets.exception.TransicionEstadoInvalidaException;
import java.time.OffsetDateTime;
import org.junit.jupiter.api.Test;

/**
 * Pruebas sobre la maquina de estados (enunciado seccion 3.4: "al menos dos
 * pruebas automatizadas ... una transicion valida y una invalida").
 */
class TicketEstadoMachineTest {

    @Test
    void permiteUnaTransicionValida() {
        assertThatCode(() -> TicketEstadoMachine.validarTransicion(TicketEstado.ABIERTO, TicketEstado.EN_PROCESO))
                .doesNotThrowAnyException();
    }

    @Test
    void rechazaUnaTransicionNoListada() {
        // El enunciado da este caso como ejemplo explicito de transicion invalida.
        assertThatThrownBy(() -> TicketEstadoMachine.validarTransicion(TicketEstado.ABIERTO, TicketEstado.RESUELTO))
                .isInstanceOf(TransicionEstadoInvalidaException.class);
    }

    @Test
    void rechazaCualquierTransicionDesdeCerrado() {
        assertThatThrownBy(() -> TicketEstadoMachine.validarTransicion(TicketEstado.CERRADO, TicketEstado.EN_PROCESO))
                .isInstanceOf(TransicionEstadoInvalidaException.class);
    }

    @Test
    void permiteReabrirSiResueltoHaceMenosDeTresDias() {
        OffsetDateTime ahora = OffsetDateTime.now();
        OffsetDateTime fechaResolucion = ahora.minusDays(2);

        assertThatCode(() -> TicketEstadoMachine.validarVentanaReapertura(
                TicketEstado.RESUELTO, TicketEstado.EN_PROCESO, fechaResolucion, ahora))
                .doesNotThrowAnyException();
    }

    @Test
    void rechazaReabrirSiResueltoHaceMasDeTresDias() {
        OffsetDateTime ahora = OffsetDateTime.now();
        OffsetDateTime fechaResolucion = ahora.minusDays(4);

        assertThatThrownBy(() -> TicketEstadoMachine.validarVentanaReapertura(
                TicketEstado.RESUELTO, TicketEstado.EN_PROCESO, fechaResolucion, ahora))
                .isInstanceOf(TransicionEstadoInvalidaException.class);
    }
}
