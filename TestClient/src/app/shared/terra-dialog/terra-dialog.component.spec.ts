import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { TerraDialogComponent } from './terra-dialog.component';

describe('TerraDialogComponent', () => {
  let component: TerraDialogComponent;
  let fixture: ComponentFixture<TerraDialogComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ TerraDialogComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(TerraDialogComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
