import { Component, OnInit } from '@angular/core';
import { QueryBuilderConfig, QueryBuilderClassNames } from 'angular2-query-builder';
import { FormBuilder, FormControl } from '@angular/forms';
import { QueryFieldType } from '../terra-dialog/model/QueryFieldType';

@Component({
  selector: 'ts-tarra-query-builder-2',
  templateUrl: './tarra-query-builder-2.component.html',
  styleUrls: ['./tarra-query-builder-2.component.scss']
})
export class TerraQueryBuilder2Component implements OnInit {

  public queryCtrl: FormControl;
  public currentConfig: QueryBuilderConfig;
  public allowRuleset: boolean = true;
  public allowCollapse: boolean = true;
  public persistValueOnFieldChange: boolean = false;
  
  constructor(    
    private formBuilder: FormBuilder
  ) { 
    this.queryCtrl = this.formBuilder.control(this.query);
    this.currentConfig = this.config;
  }

  ngOnInit() {
  }
 

  public query = {
    condition: 'and',
    rules: []
  };

  private config: QueryBuilderConfig = {
    fields: {
      'age': {name: 'Age', type: QueryFieldType[QueryFieldType.number] },
      'gender': {
        name: 'Gender',
        type: QueryFieldType[QueryFieldType.category],
        options: [
          {name: 'Male', value: 'm'},
          {name: 'Female', value: 'f'}
        ]
      },
      'name': {name: 'Name', type: QueryFieldType[QueryFieldType.string]},
      'location': {name: 'Location', type: QueryFieldType[QueryFieldType.object]},
      'location.title': {name: 'Title', type: QueryFieldType[QueryFieldType.string], entity: 'Location'},
      'location.datarelocatiom': {name: 'Date Relocatiom', type: QueryFieldType[QueryFieldType.date], entity: 'Location'},
      'location.someobject': {name: 'SomeObject', type: QueryFieldType[QueryFieldType.object], entity: 'Location'},
      'location.someobject.title': {name: 'Title', type: QueryFieldType[QueryFieldType.string], entity: 'SomeObject'},
      'location.someobject.someField': {name: 'SomeField', type: QueryFieldType[QueryFieldType.number], entity: 'SomeObject'},
      'notes': {name: 'Notes', type: QueryFieldType[QueryFieldType.textarea], operators: ['=', '!=']},
      'educated': {name: 'College Degree?', type: QueryFieldType[QueryFieldType.boolean]},
      'birthday': {name: 'Birthday', type: QueryFieldType[QueryFieldType.date], operators: ['=', '<=', '>'],
        defaultValue: (() => new Date())
      },
      'school': {name: 'School', type: QueryFieldType[QueryFieldType.string], nullable: true},
      'occupation': {
        name: 'Occupation',
        type: QueryFieldType[QueryFieldType.category],
        options: [
          {name: 'Student', value: 'student'},
          {name: 'Teacher', value: 'teacher'},
          {name: 'Unemployed', value: 'unemployed'},
          {name: 'Scientist', value: 'scientist'}
        ]
      }
    }
  };

  public bootstrapClassNames: QueryBuilderClassNames = {
    removeIcon: 'fa fa-minus',
    addIcon: 'fa fa-plus',
    arrowIcon: 'fa fa-chevron-right px-2',
    button: 'btn',
    buttonGroup: 'btn-group',
    rightAlign: 'order-12 ml-auto',
    switchRow: 'd-flex px-2',
    switchGroup: 'd-flex align-items-center',
    switchRadio: 'custom-control-input',
    switchLabel: 'custom-control-label',
    switchControl: 'custom-control custom-radio custom-control-inline',
    row: 'row p-2 m-1',
    rule: 'border',
    ruleSet: 'border',
    invalidRuleSet: 'alert alert-danger',
    emptyWarning: 'text-danger mx-auto',
    operatorControl: 'form-control',
    operatorControlSize: 'col-auto pr-0',
    fieldControl: 'form-control',
    fieldControlSize: 'col-auto pr-0',
    entityControl: 'form-control',
    entityControlSize: 'col-auto pr-0',
    inputControl: 'form-control',
    inputControlSize: 'col-auto'
  };

}
