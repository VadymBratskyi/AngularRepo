import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { AddHeroeComponent } from './add-heroe.component';


const routes: Routes = [
  {
    path: "",
    component: AddHeroeComponent
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class AddHeroeRoutingModule { }
