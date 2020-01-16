import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { TerraQueryBuilder2Component } from './tarra-query-builder-2.component';

describe('TerraQueryBuilder2Component', () => {
  let component: TerraQueryBuilder2Component;
  let fixture: ComponentFixture<TerraQueryBuilder2Component>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ TerraQueryBuilder2Component ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(TerraQueryBuilder2Component);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
