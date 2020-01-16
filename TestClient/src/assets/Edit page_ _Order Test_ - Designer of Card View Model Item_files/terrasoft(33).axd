Terrasoft.FrameEdit = Ext.extend(Terrasoft.CompositeLayoutControl, {
	width: 200,

	initItems: function() {
		this.items = new Array(7);
		var itemConfig = {
			setForceFocus: true,
			hidePrimaryToolButton: true,
			required: false,
			allowEmpty: this.allowEmpty,
			width: 13
		};

		var spacer = new Ext.Spacer({width:'100%'});
		itemConfig.id = this.id + '_topValue';
		this.items[0] = new Terrasoft.CheckBox(itemConfig);
		this.items[1] = spacer;

		itemConfig.id = this.id + '_rightValue';
		this.items[2] = new Terrasoft.CheckBox(itemConfig);
		spacer = new Ext.Spacer({width:'100%'});
		this.items[3] = spacer;

		itemConfig.id = this.id + '_bottomValue';
		this.items[4] = new Terrasoft.CheckBox(itemConfig);
		spacer = new Ext.Spacer({width:'100%'});
		this.items[5] = spacer;

		itemConfig.id = this.id + '_leftValue';
		this.items[6] = new Terrasoft.CheckBox(itemConfig);
	},

	handleNameChanging: function(oldName, name) {
		Terrasoft.FrameEdit.superclass.handleNameChanging.call(this, oldName, name, true);
		this.items[0].handleNameChanging(this.items[0].id, name + '_topValue', true);
		this.items[2].handleNameChanging(this.items[2].id, name + '_rightValue', true);
		this.items[4].handleNameChanging(this.items[4].id, name + '_bottomValue', true);
		this.items[6].handleNameChanging(this.items[6].id, name + '_leftValue', true);
		this.fireEvent("nameChanged", this, oldName, name);
	},

	setValue: function(value) {
		if (!value) {
			return;
		}
		this.value = value;
		if(!this.rendered) {
			return;
		}
		if(value === '') {
			return;
		}
		var values = value.split(' ');
		var items = this.items;
		for (var i = 0; i < values.length; i++) {
			var itemValue = (values[i] == '1');
			items[i * 2].setValue(itemValue);
		}
	},

	getValue: function() {
		if(!this.rendered) {
			return this.value;
		}
		var items = this.items;
		var resultValue = '';
		for (var i = 0; i < items.length; i+=2) {
			resultValue += items[i].getValue() === true ? '1' : '0';
			if(i < items.length - 1) {
				resultValue += ' ';
			}
		}
		return resultValue;
	}
});

Ext.reg('frameedit', Terrasoft.FrameEdit);