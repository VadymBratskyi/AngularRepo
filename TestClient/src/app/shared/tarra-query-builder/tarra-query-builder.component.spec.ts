import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { TerraQueryBuilderComponent } from './tarra-query-builder.component';

describe('TerraQueryBuilderComponent', () => {
  let component: TerraQueryBuilderComponent;
  let fixture: ComponentFixture<TerraQueryBuilderComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ TerraQueryBuilderComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(TerraQueryBuilderComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
