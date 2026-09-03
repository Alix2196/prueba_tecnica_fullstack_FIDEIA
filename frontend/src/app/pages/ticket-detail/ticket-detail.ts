import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { TicketService } from '../../core/services/ticket.service';
import { UsuarioActualService } from '../../core/services/usuario-actual.service';
import { mensajeDeError } from '../../core/services/error.util';
import { claseBadgeEstado, claseBadgePrioridad } from '../../core/services/badge.util';
import { formatFecha } from '../../core/services/fecha.util';
import { TRANSICIONES_VALIDAS, TicketDetalle, TicketEstado } from '../../core/models/ticket.model';

@Component({
  selector: 'app-ticket-detail',
  imports: [FormsModule, RouterLink],
  templateUrl: './ticket-detail.html',
  styleUrl: './ticket-detail.css',
})
export class TicketDetail implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly ticketService = inject(TicketService);
  protected readonly usuarioActual = inject(UsuarioActualService);

  protected readonly claseBadgeEstado = claseBadgeEstado;
  protected readonly claseBadgePrioridad = claseBadgePrioridad;
  protected readonly formatFecha = formatFecha;

  private readonly ticketId = Number(this.route.snapshot.paramMap.get('id'));

  protected readonly cargando = signal(true);
  protected readonly error = signal<string | null>(null);
  protected readonly detalle = signal<TicketDetalle | null>(null);

  protected readonly cambiandoEstado = signal(false);
  protected readonly errorCambiarEstado = signal<string | null>(null);
  protected readonly comentarioSolucion = signal('');
  protected readonly estadoObjetivo = signal<TicketEstado | null>(null);

  protected readonly nuevoComentario = signal('');
  protected readonly enviandoComentario = signal(false);
  protected readonly errorComentario = signal<string | null>(null);

  ngOnInit(): void {
    this.cargar();
  }

  protected cargar(): void {
    this.cargando.set(true);
    this.error.set(null);
    this.ticketService.obtenerDetalle(this.ticketId).subscribe({
      next: (detalle) => {
        this.detalle.set(detalle);
        this.cargando.set(false);
      },
      error: (err) => {
        this.error.set(mensajeDeError(err));
        this.cargando.set(false);
      },
    });
  }

  protected transicionesDisponibles(): TicketEstado[] {
    const estado = this.detalle()?.ticket.estado;
    return estado ? TRANSICIONES_VALIDAS[estado] : [];
  }

  protected seleccionarTransicion(estado: TicketEstado): void {
    this.estadoObjetivo.set(estado);
    this.errorCambiarEstado.set(null);
    this.comentarioSolucion.set('');
  }

  protected confirmarCambioEstado(): void {
    const estadoNuevo = this.estadoObjetivo();
    const autorId = this.usuarioActual.usuarioActualId();
    if (!estadoNuevo || !autorId) {
      return;
    }
    this.cambiandoEstado.set(true);
    this.errorCambiarEstado.set(null);
    this.ticketService
      .cambiarEstado(this.ticketId, {
        estadoNuevo,
        autorId,
        comentario: estadoNuevo === 'RESUELTO' ? this.comentarioSolucion() : null,
      })
      .subscribe({
        next: () => {
          this.cambiandoEstado.set(false);
          this.estadoObjetivo.set(null);
          this.cargar();
        },
        error: (err) => {
          this.errorCambiarEstado.set(mensajeDeError(err));
          this.cambiandoEstado.set(false);
        },
      });
  }

  protected enviarComentario(): void {
    const autorId = this.usuarioActual.usuarioActualId();
    const texto = this.nuevoComentario().trim();
    if (!autorId || !texto) {
      return;
    }
    this.enviandoComentario.set(true);
    this.errorComentario.set(null);
    this.ticketService.agregarComentario(this.ticketId, { autorId, texto }).subscribe({
      next: () => {
        this.enviandoComentario.set(false);
        this.nuevoComentario.set('');
        this.cargar();
      },
      error: (err) => {
        this.errorComentario.set(mensajeDeError(err));
        this.enviandoComentario.set(false);
      },
    });
  }
}
