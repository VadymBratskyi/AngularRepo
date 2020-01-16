Terrasoft.ColorPalette = function(config) {
	Terrasoft.ColorPalette.superclass.constructor.call(this, config);
	this.addEvents(
		'select'
	);

	if (this.handler) {
		this.on("select", this.handler, this.scope, true);
	}
};

Ext.extend(Terrasoft.ColorPalette, Ext.Component, {
	itemCls: "x-color-palette",
	value: null,
	clickEvent: 'click',
	ctype: "Terrasoft.ColorPalette",
	allowReselect: false,
	results: {},

	colors: [
        "FFFFFF", "000000", "777777", "999999", "CCCCCC", "FFFFFF", "FF0000", "00FF00", "0000FF", "FFFF00", "00FFFF", "000099", "990000", "9900FF", "009900", "0099FF",
        "FEFF99", "FAFE09", "F9E009", "F6D20E", "F1B215", "EEA219", "E88422", "E57426", "DF552E", "DF552E", "D7273B", "D51840", "E51D1D", "E51D1D", "B30101", "9A0000",
        "270708", "330B0B", "43130F", "4E1714", "5F1F16", "6F2B20", "7B3324", "8B3E2A", "974B33", "A7573C", "B76744", "C2734C", "D38253", "DF8F5C", "EFA367", "FEB372",
        "003F3F", "004948", "005353", "005D5D", "006869", "007C7C", "008687", "009291", "00A6A6", "00A6A7", "00A6A8", "01AEB4", "00BAB9", "00C4C3", "00CECE", "00E3E2",
        "1F731E", "277F29", "1B841B", "188D1A", "189618", "13A713", "13A714", "10B010", "0FB910", "0EC10D", "0BCA0B", "09D409", "07DC06", "06E405", "03ED02", "00FF01",
        "011B00", "012700", "003700", "004300", "005301", "005F01", "016F00", "017F01", "0E8B0B", "239B1F", "38AB34", "54B74B", "6CC768", "8BD282", "ABE3A6", "CFF4CB",
        "4B2407", "572B08", "673707", "774707", "885208", "926307", "A37307", "B38808", "C39B06", "CFB307", "E0CB00", "EFE400", "FFF300", "FFFF43", "FFFF87", "FFFFCB",
        "3C0701", "4B0B01", "5F1700", "741F00", "872F01", "9B3B00", "AF5000", "C35700", "D75B01", "EB6300", "FB6801", "FF8023", "FF9746", "FDB173", "FFC293", "FFDBBB",
        "220000", "3B0001", "520100", "720000", "850005", "9A0000", "B30101", "CB0101", "E60000", "FE0000", "FF2323", "FF4B4C", "FF7372", "FF9796", "FFBFBF", "FFE7E7",
        "2F002F", "3B003B", "46084B", "570B56", "661961", "711D72", "7A2A7F", "8B378F", "96469B", "A257AA", "B268B7", "BF7BC8", "CE90D3", "DAA7E2", "EBBFF0", "FBDBFF",
        "07070F", "0E0F23", "171837", "24234B", "2B2B5F", "333373", "3A3B8B", "484793", "54539F", "6465A8", "7374B7", "8787C3", "9A9BCB", "B0AFD7", "C3C4E3", "DADBEF",
        "070F1A", "0B1B34", "122B4A", "1B3767", "23437E", "2B5398", "325FB2", "3B6CCB", "4377E7", "5788E7", "6A97EA", "7FA7EF", "97B8EE", "AEC5F9", "C3D8F7", "DBE8FB",
        "0A171F", "132732", "1B374C", "23475F", "2A5776", "336C8A", "3B7AA3", "428BB6", "4B9FCE", "53AEE3", "6FC3EF", "93D7FA", "ABDDF4", "BBE3FC", "CFEAFB", "E2F3FB",
        "6A0000", "720E0E", "7B1D1D", "822C2B", "8A3A39", "93494A", "9A5859", "A26666", "AB7575", "B28484", "BA9292", "C3A1A0", "CAB0AF", "D2BEBD", "DBCDCD", "EBEBEB",
        "000000", "0F0F0F", "1F1F1F", "333333", "434343", "535353", "636363", "777777", "878787", "979797", "A7A7A7", "BBBBBB", "CCCCCC", "DBDBDB", "EAEAEA", "FFFFFF"
    ],

	onRender: function(container, position) {
		var t = this.tpl || new Ext.XTemplate(
            '<table class="x-colors"><tbody><tpl for=".">{[(xindex - 1) % 16 === 0 ? "<tr>" : ""]}<td style="background:#{.};"><div class="color-{.}" /></td><tpl if="this.newRow(xindex)"></tr></tpl></tpl></tbody></table>',
			{
				compiled: true,
				disableFormats: true,
				index: 16,
				newRow: function(ind) {
					var res = false;
					if	(this.index === ind) {
						this.index += 16;
						res = true;
					} 
					return res;
				}
			}
        );
		var el = document.createElement("div");
		el.className = this.itemCls;
		var colors = t.overwrite(el, this.colors, true);
		container.dom.insertBefore(el, position);
		this.el = Ext.get(el);
		this.el.colors = colors;
		this.el.colors.on(this.clickEvent, this.handleClick, this);
		var formEl = Ext.get(document.forms[0]);
		this.hiddenFieldName = this.id + '_Color';
		this.hiddenFieldColorEl = Ext.get(formEl.createChild({
			tag: 'input',
			type: 'hidden',
			name: this.hiddenFieldName,
			id: this.hiddenFieldName
		}, undefined, true));
	},

	afterRender: function() {
		Terrasoft.ColorPalette.superclass.afterRender.call(this);
		if (this.value) {
			var s = this.value;
			this.value = null;
			this.select(s);
		}
	},
	
	extractColor: function(s) {
		return this.results[s] = this.results[s] || "#" + s.match(/(?:^|\s)color-(.{6})(?:\s|$)/)[1];
	},

	highlight: function(t, color) {
		t.dom.style["borderColor"] = color || "#FFFFFF";
	},

	handleClick: function(e, t) {
		e.preventDefault();
		if (t.nodeName.toLowerCase() != "div") return;
		if (!this.disabled) {
			var c = this.extractColor(t.className);
			this.select(c.toUpperCase());
		}
	},

	select: function(color) {
		color = color.replace("#", "");
		if (color != this.value || this.allowReselect) {
			var el = this.el;
			var obj;
			if (this.value) {
				obj = el.child("div.color-" + this.value);
				this.highlight(obj, "#" + this.value);
				obj.removeClass("x-color-palette-sel");
			}
			obj = el.child("div.color-" + color);
			this.highlight(obj);
			obj.addClass("x-color-palette-sel");
			this.value = color;
			if (this.hiddenFieldColorEl) {
				this.hiddenFieldColorEl.dom.value = color;
			}
			this.fireEvent("select", this, '#' + color);
		}
	},

	silentSelect: function(color) {
		color = color.replace("#", "");
		if (color != this.value || this.allowReselect) {
			var el = this.el;
			if (this.value) {
				this.highlight(el.child("div.color-" + this.value), "#" + this.value);
			}
			this.highlight(el.child("div.color-" + color));
			this.value = color;
		}
	}

});

Ext.reg('colorpalette', Terrasoft.ColorPalette);