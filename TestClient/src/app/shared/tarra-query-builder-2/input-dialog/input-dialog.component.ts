import { Component, Input, Output, EventEmitter, forwardRef, OnDestroy } from '@angular/core';
import { MatDialog, MatDialogConfig } from '@angular/material';
import { QueryDialogComponent } from '../../terra-dialog/query-dialog/query-dialog.component';
import { Option } from 'angular2-query-builder/dist/components';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { ReplaySubject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({
  selector: 'ts-input-dialog',
  templateUrl: './input-dialog.component.html',
  styleUrls: ['./input-dialog.component.scss'],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => InputDialogComponent),
      multi: true
    }
  ]
})
export class InputDialogComponent implements ControlValueAccessor, OnDestroy {
 
$destroy = new ReplaySubject<any>(1);

 @Input() inOptions: Option[];
 @Output() onSelected = new EventEmitter();

  constructor(
    public dialog: MatDialog,
  ) { }

  public disabled: boolean;
  public _value: string;

  onChanged: any = () => {}
  onTouched: any = () => {}

  writeValue(val: any): void {
    this._value = val;
  }
  registerOnChange(fn: any): void {
    this.onChanged = fn
  }
  registerOnTouched(fn: any): void {
    this.onTouched = fn
  }
  setDisabledState?(isDisabled: boolean): void {
    this.disabled = isDisabled;
  }

  openDialog(): void {

    const dialogRef = this.dialog.open(QueryDialogComponent, this.InitDialogConfig(this.inOptions));

    dialogRef.afterClosed()
    .pipe(takeUntil(this.$destroy))
    .subscribe(result => {
      if(result) {              
        this._value = result;
        this.onChanged(result);
        this.onSelected.emit(result);
      }     
    });
  }

  public InitDialogConfig(dataOptions: Option[]): MatDialogConfig {
    let config = new MatDialogConfig();
    config.width = '500px';
    config.data = { options: dataOptions }
    return config;
  }

  ngOnDestroy() {
    this.$destroy.next(null);
    this.$destroy.complete();
  }

}
