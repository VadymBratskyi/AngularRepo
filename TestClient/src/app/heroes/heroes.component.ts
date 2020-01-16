import { Component, OnInit, OnDestroy } from '@angular/core';
import { Hero } from '../_modules/Hero';
import { HeroesService } from '../_services/heroes.service';
import { takeUntil, debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';
import { ReplaySubject, Observable, Subject } from 'rxjs';


@Component({
  selector: 'app-heroes',
  templateUrl: './heroes.component.html',
  styleUrls: ['./heroes.component.scss']
})
export class HeroesComponent implements OnInit, OnDestroy {
  
  $destroy: ReplaySubject<any> = new ReplaySubject<any>(1);

  $heroes: Observable<Hero[]>;
  private searchTerms = new Subject<string>();

  heroes: Hero[];
  selectedHero: Hero;
  
  constructor(
    private heroesServ: HeroesService 
  ) { }

  ngOnInit() {
    this.onLoadData();
  }

  onLoadData() {
    //this.$heroes = this.heroesServ.getHeroesFromDb();
  
    this.$heroes = this.searchTerms
    .pipe(
      debounceTime(300),
       // ignore new term if same as previous term
      distinctUntilChanged(),
      switchMap((searchName: string) => this.heroesServ.searchHeroes(searchName))
    );
  
    // this.heroesServ.getHeroesByIdFromDb(12)
    // this.heroesServ.getHeroesFromDb()   
    // .pipe(takeUntil(this.$destroy))
    // .subscribe(heroes => {
    //     this.heroes = heroes;
    // });
  }
  
  onSelect(hero: Hero): void {
    this.selectedHero = hero;
  }

  onSearch(name: string) {
    
    this.searchTerms.next(name);

    // if(name) {
    //   this.heroesServ.searchHeroes(name)
    //   .pipe(takeUntil(this.$destroy))
    //   .subscribe(heroes => {
    //     this.heroes = heroes;
    //   })
    // } else{
    //   this.onLoadData();
    // }    
  }

  onSave() {
    this.selectedHero = null;
  }

  onDelet() {
    this.selectedHero = null;
    this.onLoadData();
  }

  ngOnDestroy(): void {
      this.$destroy.next(null);
      this.$destroy.complete();
  }

}
