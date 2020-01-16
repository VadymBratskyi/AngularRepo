Terrasoft.IntegerEdit = Ext.extend(Terrasoft.NumberEdit, {
	minValue: -2147483648,
	maxValue: 2147483647,

	initComponent: function() {
		Terrasoft.IntegerEdit.superclass.initComponent.call(this);
		this.allowDecimals = false;
	},

	initValue: function () {
		try {
			this.valueInit = false;
			var column = this.getColumn();
			if (column) {
				var value = this.getColumnValue();
				var intValue = parseInt(String(value));
				this.setValue(isNaN(intValue) ? '' : intValue);
				return;
			}
			if (this.el.dom.value.length > 0 && this.el.dom.value != this.emptyText) {
				this.setValue(this.el.dom.value);
			} else {
				this.setValue(this.value);
			}
		} finally {
			this.originalValue = this.getValue();
			this.valueInit = true;
		}
	}
});

Ext.reg('integeredit', Terrasoft.IntegerEdit);