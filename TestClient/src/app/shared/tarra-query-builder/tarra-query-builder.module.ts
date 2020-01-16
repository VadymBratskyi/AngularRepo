import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { TerraQueryBuilderComponent } from './tarra-query-builder.component';
import { QueryBuilderModule } from "angular2-query-builder";
import { 
  MatButtonModule,
  MatIconModule,
  MatRadioModule,
  MatOptionModule,
  MatSelectModule,
  MatCheckboxModule,
  MatFormFieldModule,
  MatInputModule,
  MatDatepickerModule,
  MatNativeDateModule,
 } from "@angular/material"

@NgModule({
  declarations: [
    TerraQueryBuilderComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    QueryBuilderModule,

    /*material*/
    MatButtonModule,
    MatIconModule,
    MatRadioModule,
    MatOptionModule,
    MatSelectModule,
    MatCheckboxModule,
    MatFormFieldModule,
    MatInputModule,
    MatDatepickerModule,
    MatNativeDateModule
  ],
  exports: [TerraQueryBuilderComponent]
})
export class TerraQueryBuilderModule { }
