import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { HeroesComponent } from './heroes.component';
import { ViewComponent } from './view/view.component';



const routes: Routes = [
  {
    path: "",
    component: HeroesComponent,
    children: [
      {
        path: "view/:id",
        component: ViewComponent
      } 
    ]
  }  
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class HeroesRoutingModule { }
