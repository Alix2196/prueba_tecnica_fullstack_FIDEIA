import { HttpErrorResponse } from '@angular/common/http';
import { ErrorRespuesta } from '../models/ticket.model';

/**
 * Extrae un mensaje entendible del error uniforme del backend
 * (ai.fideia.tickets.dto.ErrorResponse, ver README seccion 6). Si el error
 * no vino del backend (servidor caido, red, etc.) devuelve un mensaje generico.
 */
export function mensajeDeError(error: unknown): string {
  if (error instanceof HttpErrorResponse) {
    const cuerpo = error.error as ErrorRespuesta | undefined;
    if (cuerpo?.mensaje) {
      const detalles = cuerpo.detalles?.length ? ` (${cuerpo.detalles.join(', ')})` : '';
      return `${cuerpo.mensaje}${detalles}`;
    }
    if (error.status === 0) {
      return 'No se pudo conectar con el servidor. Verifica que el backend este corriendo.';
    }
    return `Error del servidor (HTTP ${error.status}).`;
  }
  return 'Ocurrio un error inesperado.';
}
