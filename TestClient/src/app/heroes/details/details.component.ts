import { Component, OnInit, OnChanges, Input, Output, EventEmitter } from '@angular/core';
import { Router,ActivatedRoute } from '@angular/router';
import { Hero } from '../../_modules/Hero';
import { HeroesService } from 'src/app/_services/heroes.service';
import { takeUntil } from 'rxjs/operators';
import { ReplaySubject } from 'rxjs';

@Component({
  selector: 'app-details',
  templateUrl: './details.component.html',
  styleUrls: ['./details.component.scss']
})
export class DetailsComponent implements OnInit, OnChanges {
  
  $destroy: ReplaySubject<any> = new ReplaySubject<any>(1);

  @Output() onSaved = new EventEmitter();
  @Output() onDeleted = new EventEmitter();
  @Input() inHeroe: Hero;

  constructor(
    private router: Router,
    private heroesServ: HeroesService,
    private activRouter: ActivatedRoute
  ) { }

  ngOnInit() {
  }

  ngOnChanges() {
  }

  save() {
    this.heroesServ.updateHero(this.inHeroe)
    .pipe(takeUntil(this.$destroy))
    .subscribe(() => this.onSaved.emit());
  }

  delete() {
    this.heroesServ.deleteHero(this.inHeroe)
    .pipe(takeUntil(this.$destroy))
    .subscribe(() => this.onDeleted.emit());
  }

  onViewHero() {
    this.router.navigate(['view', this.inHeroe.id], {relativeTo: this.activRouter});
  }

  ngOnDestroy(): void {
    this.$destroy.next(null);
    this.$destroy.complete();
  }


}
