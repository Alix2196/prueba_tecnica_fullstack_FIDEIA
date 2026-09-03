import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api-config';
import { UsuarioResumen, UsuarioRol } from '../models/ticket.model';

/** Catalogo de usuarios precargado, de solo lectura (README seccion 4 y 8). */
@Injectable({ providedIn: 'root' })
export class UsuarioService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${API_BASE_URL}/usuarios`;

  listar(rol?: UsuarioRol): Observable<UsuarioResumen[]> {
    const params = rol ? new HttpParams().set('rol', rol) : undefined;
    return this.http.get<UsuarioResumen[]>(this.baseUrl, { params });
  }
}
