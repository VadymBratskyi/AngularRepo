import { Component, OnInit, Inject } from '@angular/core';
import { MAT_DIALOG_DATA } from '@angular/material/dialog';
import { TerraDialog } from '../model/TerraDialog';
import { EntityItem } from '../model/EntityItem';
import { DialogActionButton } from '../model/DialogActionButton';
import { QueryFieldType } from '../model/QueryFieldType';

@Component({
  selector: 'ts-query-dialog',
  templateUrl: './query-dialog.component.html',
  styleUrls: ['./query-dialog.component.scss']
})
export class QueryDialogComponent implements OnInit {

  qyeryDialogModel: TerraDialog;
  entityItems: EntityItem[];

  constructor(
    @Inject(MAT_DIALOG_DATA) public data: any
  ) {}

   get getProperties(): string {
    if(this.entityItems && this.entityItems.length) {
      let selected =  this.entityItems[this.entityItems.length -1].SelectedValue;
      this.qyeryDialogModel.ActionButton.DisableBtnOk = !selected || selected.type == QueryFieldType[QueryFieldType.object] ? true : false; 
      return selected ? selected.value : null;
    } 
    return null;
   }

  ngOnInit() {   
    this.initDialogModel();
    this.initEntityItems();
  }

  onAddEntity() {
    if(this.entityItems && this.entityItems.length > 0) {
     let lastItem = this.entityItems[this.entityItems.length - 1]; 
     let newItem = new EntityItem();
     newItem.IdComponent = lastItem.IdComponent + 1;
     newItem.Options = this.data.options.filter(d=>d.entity && d.entity == lastItem.SelectedValue.name);
     newItem.SelectedValue = null;
     this.entityItems.push(newItem);     
    }    
  }

  onRemoveEntity(idComponetn: number) {
    if(this.entityItems && this.entityItems.length > 1) {       
      let item = this.entityItems.find(e => e.IdComponent == idComponetn);   
      if(item.SelectedValue.type == QueryFieldType[QueryFieldType.object]) {
        // let arrIndexForRemove = this.entityItems.filter(o => o.SelectedValue.entity == item.SelectedValue.name || o.SelectedValue.name == item.SelectedValue.name);
        // arrIndexForRemove.forEach(i => {
        //   let index = this.entityItems.findIndex(e => e.IdComponent == i.IdComponent);            
        //   if(index >= 0) {
        //     this.entityItems.splice(index, 1);
        //   }
        // });
        // if(this.entityItems.length == 0) {
        //   this.initEntityItems();
        // } 
        this.initEntityItems();     
      }
      else {
        let index = this.entityItems.findIndex(e => e.IdComponent == idComponetn);            
        if(index >= 0) {
          this.entityItems.splice(index, 1);
        }
      }        
     }
  }

  initEntityItems() {
    this.entityItems = [];
    let item = new EntityItem();
    item.IdComponent = 1;
    item.Options = this.data.options.filter(i => !i.entity);
    item.SelectedValue = null;
    this.entityItems.push(item);
  }

  initDialogModel() {
    let dialogModel = new TerraDialog();
    dialogModel.Title = "Select property";
    dialogModel.ActionButton = new DialogActionButton();    
    this.qyeryDialogModel = dialogModel;
  }

}
