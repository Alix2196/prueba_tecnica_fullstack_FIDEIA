// Espejo de los DTOs del backend (backend/src/main/java/ai/fideia/tickets/dto).

export type TicketPrioridad = 'BAJA' | 'MEDIA' | 'ALTA';

export type TicketEstado = 'ABIERTO' | 'EN_PROCESO' | 'RESUELTO' | 'CERRADO';

export type UsuarioRol = 'SOLICITANTE' | 'AGENTE';

export interface UsuarioResumen {
  id: number;
  nombre: string;
  rol: UsuarioRol;
}

export interface Ticket {
  id: number;
  titulo: string;
  descripcion: string;
  prioridad: TicketPrioridad;
  estado: TicketEstado;
  solicitante: UsuarioResumen;
  agente: UsuarioResumen | null;
  fechaCreacion: string;
  fechaActualizacion: string;
  fechaResolucion: string | null;
}

export interface Comentario {
  id: number;
  texto: string;
  autor: UsuarioResumen;
  esSolucion: boolean;
  creadoEn: string;
}

export interface HistorialEstado {
  id: number;
  estadoAnterior: TicketEstado | null;
  estadoNuevo: TicketEstado;
  autor: UsuarioResumen;
  creadoEn: string;
}

export interface TicketDetalle {
  ticket: Ticket;
  comentarios: Comentario[];
  historial: HistorialEstado[];
}

export interface PaginaRespuesta<T> {
  contenido: T[];
  pagina: number;
  tamano: number;
  totalElementos: number;
  totalPaginas: number;
}

export interface TicketCreateRequest {
  titulo: string;
  descripcion: string;
  prioridad: TicketPrioridad;
  solicitanteId: number;
  agenteId: number | null;
}

export interface CambiarEstadoRequest {
  estadoNuevo: TicketEstado;
  autorId: number;
  comentario: string | null;
}

export interface ComentarioCreateRequest {
  autorId: number;
  texto: string;
}

export interface ErrorRespuesta {
  codigo: string;
  mensaje: string;
  detalles: string[];
  timestamp: string;
}

/**
 * Espejo de TicketEstadoMachine (backend): usado solo para no ofrecer en la
 * UI botones de transicion que el servidor va a rechazar de todas formas.
 * La validacion real vive unicamente en el backend (README seccion 5).
 */
export const TRANSICIONES_VALIDAS: Record<TicketEstado, TicketEstado[]> = {
  ABIERTO: ['EN_PROCESO'],
  EN_PROCESO: ['RESUELTO'],
  RESUELTO: ['CERRADO', 'EN_PROCESO'],
  CERRADO: [],
};
