import { TicketEstado, TicketPrioridad } from '../models/ticket.model';

export function claseBadgeEstado(estado: TicketEstado): string {
  return `badge badge--estado-${estado.toLowerCase()}`;
}

export function claseBadgePrioridad(prioridad: TicketPrioridad): string {
  return `badge badge--prioridad-${prioridad.toLowerCase()}`;
}
