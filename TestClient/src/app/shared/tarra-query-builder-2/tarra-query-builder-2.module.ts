import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { TerraQueryBuilder2Component } from './tarra-query-builder-2.component';
import { QueryBuilderModule } from "angular2-query-builder";
import { QueryDialogModule } from '../terra-dialog/query-dialog/query-dialog.module';
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
 } from "@angular/material";
import { InputDialogComponent } from './input-dialog/input-dialog.component'


@NgModule({
  declarations: [
    TerraQueryBuilder2Component,
    InputDialogComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    QueryBuilderModule,
    QueryDialogModule,

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
  exports: [TerraQueryBuilder2Component]
})
export class TerraQueryBuilderModule2 { }
