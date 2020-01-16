import { Component, OnInit, OnDestroy } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { ReplaySubject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({
  selector: 'app-view',
  templateUrl: './view.component.html',
  styleUrls: ['./view.component.scss']
})
export class ViewComponent implements OnInit, OnDestroy {  

  $destroy: ReplaySubject<any> = new ReplaySubject<any>(1);

  selectedVew: string;
  
  constructor(
    private activRouter: ActivatedRoute
  ) { }

  ngOnInit() {
    this.activRouter.paramMap
      .pipe(takeUntil(this.$destroy))
      .subscribe(param => {
        let idHero = param.get("id");
        this.selectedVew = this.selectHeroe(idHero);
      });
  }

  ngOnDestroy() {
      this.$destroy.next(null);
      this.$destroy.complete();
  }

  selectHeroe(heroId: string) {
    switch(heroId) {
      case '11':
          return './assets/cs1.gif';
      case '12':
          return './assets/cs2.gif';
      case '13':
          return './assets/cs3.gif';
      case '14':
          return './assets/cs4.gif';
      case '15':
          return './assets/cs5.gif';
      case '16':
          return './assets/cs6.gif';
      case '17':
          return './assets/cs7.gif';
      case '18':
          return './assets/cs8.gif';
      case '19':  
        return  './assets/cs2.gif';
      case '20':  
        return  './assets/cs3.gif';
      default: return  './assets/cs1.gif';
    }
  }

}
