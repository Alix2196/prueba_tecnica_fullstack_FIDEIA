export function formatFecha(iso: string | null): string {
  if (!iso) {
    return '—';
  }
  return new Date(iso).toLocaleString('es-CO', {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}
