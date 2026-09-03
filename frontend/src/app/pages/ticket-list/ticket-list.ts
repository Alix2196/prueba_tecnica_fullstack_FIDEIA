import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TicketService } from '../../core/services/ticket.service';
import { UsuarioService } from '../../core/services/usuario.service';
import { UsuarioActualService } from '../../core/services/usuario-actual.service';
import { mensajeDeError } from '../../core/services/error.util';
import { claseBadgeEstado, claseBadgePrioridad } from '../../core/services/badge.util';
import { formatFecha } from '../../core/services/fecha.util';
import {
  PaginaRespuesta,
  Ticket,
  TicketCreateRequest,
  TicketEstado,
  TicketPrioridad,
  UsuarioResumen,
} from '../../core/models/ticket.model';

const TAMANO_PAGINA = 10;

@Component({
  selector: 'app-ticket-list',
  imports: [FormsModule],
  templateUrl: './ticket-list.html',
  styleUrl: './ticket-list.css',
})
export class TicketList implements OnInit {
  private readonly ticketService = inject(TicketService);
  private readonly usuarioService = inject(UsuarioService);
  protected readonly usuarioActual = inject(UsuarioActualService);
  private readonly router = inject(Router);

  protected readonly claseBadgeEstado = claseBadgeEstado;
  protected readonly claseBadgePrioridad = claseBadgePrioridad;
  protected readonly formatFecha = formatFecha;

  protected readonly estados: TicketEstado[] = ['ABIERTO', 'EN_PROCESO', 'RESUELTO', 'CERRADO'];
  protected readonly prioridades: TicketPrioridad[] = ['BAJA', 'MEDIA', 'ALTA'];

  protected readonly filtroEstado = signal<TicketEstado | ''>('');
  protected readonly filtroPrioridad = signal<TicketPrioridad | ''>('');
  protected readonly pagina = signal(0);

  protected readonly cargando = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly datos = signal<PaginaRespuesta<Ticket> | null>(null);

  protected readonly solicitantes = signal<UsuarioResumen[]>([]);
  protected readonly agentes = signal<UsuarioResumen[]>([]);
  protected readonly mostrarFormularioCrear = signal(false);
  protected readonly creando = signal(false);
  protected readonly errorCrear = signal<string | null>(null);

  protected readonly nuevoTicket: TicketCreateRequest = {
    titulo: '',
    descripcion: '',
    prioridad: 'MEDIA',
    solicitanteId: 0,
    agenteId: null,
  };

  ngOnInit(): void {
    this.cargar();
    this.usuarioService.listar('SOLICITANTE').subscribe((usuarios) => this.solicitantes.set(usuarios));
    this.usuarioService.listar('AGENTE').subscribe((usuarios) => this.agentes.set(usuarios));
  }

  protected cargar(): void {
    this.cargando.set(true);
    this.error.set(null);
    this.ticketService
      .listar({
        estado: this.filtroEstado() || null,
        prioridad: this.filtroPrioridad() || null,
        page: this.pagina(),
        size: TAMANO_PAGINA,
      })
      .subscribe({
        next: (respuesta) => {
          this.datos.set(respuesta);
          this.cargando.set(false);
        },
        error: (err) => {
          this.error.set(mensajeDeError(err));
          this.cargando.set(false);
        },
      });
  }

  protected onCambiarFiltro(): void {
    this.pagina.set(0);
    this.cargar();
  }

  protected irAPagina(n: number): void {
    this.pagina.set(n);
    this.cargar();
  }

  protected abrirTicket(id: number): void {
    this.router.navigate(['/tickets', id]);
  }

  protected toggleFormularioCrear(): void {
    this.mostrarFormularioCrear.set(!this.mostrarFormularioCrear());
    this.errorCrear.set(null);
    if (this.mostrarFormularioCrear() && !this.nuevoTicket.solicitanteId && this.solicitantes().length > 0) {
      this.nuevoTicket.solicitanteId = this.solicitantes()[0].id;
    }
  }

  protected enviarCrear(): void {
    this.creando.set(true);
    this.errorCrear.set(null);
    this.ticketService.crear(this.nuevoTicket).subscribe({
      next: () => {
        this.creando.set(false);
        this.mostrarFormularioCrear.set(false);
        this.nuevoTicket.titulo = '';
        this.nuevoTicket.descripcion = '';
        this.nuevoTicket.prioridad = 'MEDIA';
        this.nuevoTicket.agenteId = null;
        this.pagina.set(0);
        this.cargar();
      },
      error: (err) => {
        this.errorCrear.set(mensajeDeError(err));
        this.creando.set(false);
      },
    });
  }
}
