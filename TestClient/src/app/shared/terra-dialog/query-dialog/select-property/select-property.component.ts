import { Component, OnInit, Input } from '@angular/core';
import { EntityItem } from '../../model/EntityItem';

@Component({
  selector: 'ts-select-property',
  templateUrl: './select-property.component.html',
  styleUrls: ['./select-property.component.scss']
})
export class SelectPropertyComponent implements OnInit {

  @Input() inEntity: EntityItem;

  constructor() {}

  ngOnInit() {
  
  }

}
