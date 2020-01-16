import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { AddHeroeRoutingModule } from './add-heroe-routing.module';
import { AddHeroeComponent } from './add-heroe.component';


@NgModule({
  declarations: [AddHeroeComponent],
  imports: [
    CommonModule,
    AddHeroeRoutingModule
  ]
})
export class AddHeroeModule { }
