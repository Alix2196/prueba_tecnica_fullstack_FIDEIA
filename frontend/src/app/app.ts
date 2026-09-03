import { Component, inject, OnInit } from '@angular/core';
import { RouterLink, RouterOutlet } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { UsuarioService } from './core/services/usuario.service';
import { UsuarioActualService } from './core/services/usuario-actual.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, FormsModule],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit {
  private readonly usuarioService = inject(UsuarioService);
  protected readonly usuarioActual = inject(UsuarioActualService);

  ngOnInit(): void {
    this.usuarioService.listar().subscribe((usuarios) => {
      this.usuarioActual.establecerCatalogo(usuarios);
    });
  }

  protected onCambiarUsuario(idTexto: string): void {
    this.usuarioActual.seleccionar(Number(idTexto));
  }
}
