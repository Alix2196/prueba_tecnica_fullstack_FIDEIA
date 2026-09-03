import { Injectable, signal } from '@angular/core';
import { UsuarioResumen } from '../models/ticket.model';

const CLAVE_STORAGE = 'ticketsApp.usuarioActualId';

/**
 * No hay autenticacion real (README seccion 8 / enunciado seccion 3.7): el
 * usuario actual se selecciona de una lista en la barra superior y se usa
 * como autor por defecto al comentar o cambiar el estado de un ticket.
 * Se recuerda en localStorage solo por comodidad entre recargas de pagina.
 */
@Injectable({ providedIn: 'root' })
export class UsuarioActualService {
  readonly usuarios = signal<UsuarioResumen[]>([]);
  readonly usuarioActualId = signal<number | null>(this.leerIdGuardado());

  establecerCatalogo(usuarios: UsuarioResumen[]): void {
    this.usuarios.set(usuarios);
    if (this.usuarioActualId() === null && usuarios.length > 0) {
      this.seleccionar(usuarios[0].id);
    }
  }

  seleccionar(id: number): void {
    this.usuarioActualId.set(id);
    localStorage.setItem(CLAVE_STORAGE, String(id));
  }

  private leerIdGuardado(): number | null {
    const valor = localStorage.getItem(CLAVE_STORAGE);
    return valor ? Number(valor) : null;
  }
}
