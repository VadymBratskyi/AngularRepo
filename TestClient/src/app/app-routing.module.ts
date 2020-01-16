import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { AddHeroeModule } from './add-heroe/add-heroe.module';


const routes: Routes = [
  {
    path: "heroes",
    loadChildren: "./heroes/heroes.module#HeroesModule"    
  },
  {
    path: "add_heroe",
    loadChildren: () => import('./add-heroe/add-heroe.module').then(a => a.AddHeroeModule)  
  },
  {
    path: "qb",
    loadChildren: () => import('./qb/qb.module').then(c => c.QbModule)
  }

];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
