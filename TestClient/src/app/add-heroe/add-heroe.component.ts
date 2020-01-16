import { Component, OnInit, OnDestroy } from '@angular/core';
import { Router } from '@angular/router';
import { HeroesService } from '../_services/heroes.service';
import { Hero } from '../_modules/Hero';
import { takeUntil } from 'rxjs/operators';
import { ReplaySubject } from 'rxjs';

@Component({
  selector: 'app-add-heroe',
  templateUrl: './add-heroe.component.html',
  styleUrls: ['./add-heroe.component.scss']
})
export class AddHeroeComponent implements OnInit, OnDestroy {
  
  $destroy: ReplaySubject<any> = new ReplaySubject<any>(1);

  constructor(
    private router: Router,
    private heroService: HeroesService
  ) { }

  ngOnInit() {
  }

  add(heroName: string) {
    heroName = heroName.trim();
    if (!heroName) { return; }
    let hero = new Hero();
    hero.name = heroName;
    this.heroService.addHero(hero)
      .pipe(takeUntil(this.$destroy))
      .subscribe(hero => {
        this.router.navigate(['/heroes']);
      });
  }

  ngOnDestroy(): void {
    this.$destroy.next(null);
    this.$destroy.complete();
}


}
