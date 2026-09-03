import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api-config';
import {
  CambiarEstadoRequest,
  Comentario,
  ComentarioCreateRequest,
  PaginaRespuesta,
  Ticket,
  TicketCreateRequest,
  TicketDetalle,
  TicketEstado,
  TicketPrioridad,
} from '../models/ticket.model';

export interface FiltrosListado {
  estado: TicketEstado | null;
  prioridad: TicketPrioridad | null;
  page: number;
  size: number;
}

/** Cliente HTTP para los 5 endpoints de /api/tickets (README seccion 6). */
@Injectable({ providedIn: 'root' })
export class TicketService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${API_BASE_URL}/tickets`;

  listar(filtros: FiltrosListado): Observable<PaginaRespuesta<Ticket>> {
    let params = new HttpParams().set('page', filtros.page).set('size', filtros.size);
    if (filtros.estado) {
      params = params.set('estado', filtros.estado);
    }
    if (filtros.prioridad) {
      params = params.set('prioridad', filtros.prioridad);
    }
    return this.http.get<PaginaRespuesta<Ticket>>(this.baseUrl, { params });
  }

  obtenerDetalle(id: number): Observable<TicketDetalle> {
    return this.http.get<TicketDetalle>(`${this.baseUrl}/${id}`);
  }

  crear(request: TicketCreateRequest): Observable<Ticket> {
    return this.http.post<Ticket>(this.baseUrl, request);
  }

  cambiarEstado(id: number, request: CambiarEstadoRequest): Observable<Ticket> {
    return this.http.patch<Ticket>(`${this.baseUrl}/${id}/estado`, request);
  }

  agregarComentario(id: number, request: ComentarioCreateRequest): Observable<Comentario> {
    return this.http.post<Comentario>(`${this.baseUrl}/${id}/comentarios`, request);
  }
}
