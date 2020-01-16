import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { QueryDialogComponent } from './query-dialog.component';
import { TerraDialogModule } from '../terra-dialog.module';
import { MatSelectModule, MatIconModule, MatButtonModule } from '@angular/material';
import { SelectPropertyComponent } from './select-property/select-property.component';

@NgModule({
  declarations: [QueryDialogComponent, SelectPropertyComponent],
  imports: [
    CommonModule,
    TerraDialogModule,
    FormsModule,
    
    /**material */
    MatSelectModule,
    MatIconModule,
    MatButtonModule
  ],
  entryComponents: [
    QueryDialogComponent 
  ],
})
export class QueryDialogModule { }
