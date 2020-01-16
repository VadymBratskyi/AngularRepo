Terrasoft.DimensionEdit = Ext.extend(Terrasoft.CompositeLayoutControl, {
	width: 200,

	initComponent: function() {
		Terrasoft.DimensionEdit.superclass.initComponent.call(this);
	},

	initItems: function() {
		this.items = new Array(4);
		var itemConfig = {
			hidePrimaryToolButton: true,
			required: false,
			allowEmpty: this.allowEmpty,
			width: '25%'
		};
		itemConfig.id = this.id + '_firstValue';
		this.items[0] = new Terrasoft.IntegerEdit(itemConfig);
		itemConfig.id = this.id + '_secondValue';
		this.items[1] = new Terrasoft.IntegerEdit(itemConfig);
		itemConfig.id = this.id + '_thirdValue';
		this.items[2] = new Terrasoft.IntegerEdit(itemConfig);
		itemConfig.id = this.id + '_fourthValue';
		this.items[3] = new Terrasoft.IntegerEdit(itemConfig);
	},

	handleNameChanging: function(oldName, name) {
		Terrasoft.DimensionEdit.superclass.handleNameChanging.call(this, oldName, name, true);
		this.items[0].handleNameChanging(this.items[0].id, name + '_firstValue', true);
		this.items[1].handleNameChanging(this.items[1].id, name + '_secondValue', true);
		this.items[2].handleNameChanging(this.items[2].id, name + '_thirdValue', true);
		this.items[3].handleNameChanging(this.items[3].id, name + '_fourthValue', true);
		this.fireEvent("nameChanged", this, oldName, name);
	},

	setValue: function(value) {
		if (!value) {
			value = '';
		}
		this.value = value;
		if(!this.rendered) {
			return;
		}
		if(value !== '') {
			var values = value.split(' ');
		}
		var items = this.items;
		for (var i = 0; i < items.length; i++) {
			var itemValue = (values && i < values.length) ? values[i]: '';
			items[i].setValue(itemValue);
		}
	},
	
	getValue: function() {
		if(!this.rendered) {
			return this.value;
		}
		var items = this.items;
		var values = new Array(items.length);
		for (var i = 0; i < items.length; i++) {
			values[i] = items[i].getValue();
		}
		var value = this.parseValue(values);
		return value || '';
	},
	
	parseValue: function(values) {
		var resultValue = '';
		var lastNumPos = -1;
		for (var i = 0; i < values.length; i++) {
			if (values[i] !== '') {
				lastNumPos = i;
			}
		}
		if (lastNumPos != -1) {
			for (i = 0 ; i <= lastNumPos; i++) {
				resultValue = (values[i] == '') ? resultValue + '0' : resultValue + values[i];
				if(i < lastNumPos) {
					resultValue += ' ';
				}
			}
		}
		return resultValue;
	}
});

Ext.reg('dimensionedit', Terrasoft.DimensionEdit);
