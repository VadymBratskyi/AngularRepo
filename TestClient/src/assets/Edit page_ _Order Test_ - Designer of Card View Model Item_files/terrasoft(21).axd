Terrasoft.ImageListItem = function(uid, caption, name) {
	this.uid = uid;
	this.caption = caption;
	this.name = name;
}

Terrasoft.ImageListItem.prototype = {
	encode: function() {
		return Ext.util.JSON.encode(this);
	},
	decode: function(item) {
		return new Terrasoft.ImageListItem(item.uid, item.caption, item.name);
	}
};

Terrasoft.ImageList = function(cfg) {
	cfg = cfg || {};
	Ext.apply(this, cfg);
	this.items = [];
	if (this.imagesConfig) {
		this.decode(this.imagesConfig);
		delete this.imagesConfig;
	} else {
		this.items = [];
	}
	Terrasoft.ImageList.superclass.constructor.call(this);
	this.initComponent();
};

Ext.extend(Terrasoft.ImageList, Ext.util.Observable, {
	initComponent: function() {
	},

	add: function(item) {
		this.items.push(item);
	},

	decode: function(a) {
		if (!a || a.length == 0) {
			return [];
		}
		for (var i = 0; i < a.length; i++) {
			var item = a[i];
			var imageItem = new Terrasoft.ImageListItem();
			this.add(imageItem.decode(item));
			delete imageItem;
		}
	},

	encode: function() {
		var a = ["["], len = this.items.length, item;
		if (len == 0) {
			return "";
		}
		for (var i = 0; i < len; i++) {
			item = this.items[i];
			if (i > 0) {
				a.push(',');
			}
			a.push(item.encode());
		}
		a.push("]");
		return a.join("");
	}
});

Ext.reg('imagelist', Terrasoft.ImageList);