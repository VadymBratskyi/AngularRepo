import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { TerraDialogComponent } from './terra-dialog.component';
import { 
  MatDialogModule, 
  MatFormFieldModule,
  MatButtonModule,
  MatInputModule,
} from '@angular/material';


@NgModule({
  declarations: [
    TerraDialogComponent
  ],
  imports: [
    CommonModule,
    FormsModule,

    /*material*/
    MatButtonModule,
    MatInputModule,
    MatDialogModule,
    MatFormFieldModule
  ],
  exports: [
    TerraDialogComponent
  ]
})
export class TerraDialogModule { }
