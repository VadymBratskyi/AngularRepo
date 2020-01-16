Terrasoft.FloatEdit = Ext.extend(Terrasoft.NumberEdit, {
	initComponent: function() {
		Terrasoft.FloatEdit.superclass.initComponent.call(this);
		this.allowDecimals = true;
	}
});

Ext.reg('floatedit', Terrasoft.FloatEdit);