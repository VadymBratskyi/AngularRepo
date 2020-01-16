import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { QbRoutingModule } from './qb-routing.module';
import { QbComponent } from './qb.component';
import { TerraQueryBuilderModule2 } from '../shared/tarra-query-builder-2/tarra-query-builder-2.module';


@NgModule({
  declarations: [QbComponent],
  imports: [
    CommonModule,
    QbRoutingModule,
    TerraQueryBuilderModule2
  ]
})
export class QbModule { }
