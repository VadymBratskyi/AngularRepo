import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-qb',
  templateUrl: './qb.component.html',
  styleUrls: ['./qb.component.scss']
})
export class QbComponent implements OnInit {

  imgSrc: string;

  constructor() { }

  ngOnInit() {
    this.imgSrc = './assets/img/cs_hero.jpg';
  }

}
