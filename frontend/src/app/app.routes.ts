import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/ticket-list/ticket-list').then((m) => m.TicketList),
  },
  {
    path: 'tickets/:id',
    loadComponent: () =>
      import('./pages/ticket-detail/ticket-detail').then((m) => m.TicketDetail),
  },
  { path: '**', redirectTo: '' },
];
