import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { QbComponent } from './qb.component';


const routes: Routes = [
  {
    path: "",
    component: QbComponent
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class QbRoutingModule { }
