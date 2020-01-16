import { Component, OnInit, Input } from '@angular/core';
import { MatDialogRef, MatDialogConfig } from '@angular/material/dialog';
import { TerraDialog } from './model/TerraDialog';

@Component({
  selector: 'ts-terra-dialog',
  templateUrl: './terra-dialog.component.html',
  styleUrls: ['./terra-dialog.component.scss']
})
export class TerraDialogComponent implements OnInit {

  @Input() terraDialogModel: TerraDialog;  
  @Input() responseValue: any;

  constructor(      
    public dialogRef: MatDialogRef<TerraDialogComponent>  
 ) { }

  ngOnInit() {      
  }

  onCancel(): void {
    this.dialogRef.close();
  }

}
