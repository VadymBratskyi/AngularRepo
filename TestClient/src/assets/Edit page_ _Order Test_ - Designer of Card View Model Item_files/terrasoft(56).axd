Terrasoft.SyntaxMemoEdit = function (cfg) {
	cfg = cfg || {};
	Ext.apply(this, cfg);
	Terrasoft.SyntaxMemoEdit.superclass.constructor.call(this);
};

Ext.extend(Terrasoft.SyntaxMemoEdit, Terrasoft.SilverlightContainer, {
	xtype: 'syntaxmemoedit',
	text: '',
	width: 300,
	height: 300,
	source: "/ClientBin/Terrasoft.UI.WindowsControls.SyntaxMemo.xap",

	initComponent: function () {
		this.parameters = {};
		this.parameters.source = this.source;
		Terrasoft.SyntaxMemoEdit.superclass.initComponent.call(this);

		this.on("onpluginloaded", function() {
			if (!this.scriptableObject) {
				return;
			}
			this.scriptableObject.SetText(this.text);
		});

	},

	setText: function(text) {
		this.text = text;
		if (!this.scriptableObject) {
			return;
		}
		this.scriptableObject.SetText(text);
	},

	onRender: function (ct, position) {
		Terrasoft.SyntaxMemoEdit.superclass.onRender.call(this, ct, position);
	}
});

Ext.reg("syntaxmemoedit", Terrasoft.SyntaxMemoEdit);